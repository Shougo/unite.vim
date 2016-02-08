"=============================================================================
" FILE: script.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          hakobe <hakobe at gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

" see http://d.hatena.ne.jp/hakobe932

let s:source = {
      \ 'name': 'script',
      \ 'hooks': {},
      \ 'default_kind' : 'command',
      \ }

function! s:source.hooks.on_init(args, context) abort "{{{
  let a:context.source__path = expand('%')
endfunction"}}}
function! s:source.hooks.on_close(args, context) abort "{{{
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.kill()
  endif
endfunction "}}}

function! s:source.gather_candidates(args, context) abort "{{{
  if len(a:args) < 2
    call unite#print_source_error(
          \ ':Unite script:command:path', s:source.name)
    let a:context.is_async = 0
    return []
  endif

  let runner = a:args[0]
  let script = globpath(&runtimepath, a:args[1], 1)
  if script == ''
    let script = a:args[1]
  endif

  if !executable(runner)
    call unite#print_source_error(
          \ 'command is not executable: ' . runner, s:source.name)
    let a:context.is_async = 0
    return []
  elseif !filereadable(script)
    call unite#print_source_error(
          \ 'script file is not readable: ' . script, s:source.name)
    let a:context.is_async = 0
    return []
  endif

  let cmdline = printf('%s "%s" "%s"',
          \ runner, script, a:context.source__path)
  if !unite#util#has_vimproc()
    let a:context.is_async = 0
    let lines = split(unite#util#system(cmdline), "\n")
    return map(lines, 's:create_candidate(v:val)')
  end

  " Use vimproc
  let a:context.source__proc = vimproc#plineopen3(
        \ vimproc#util#iconv(cmdline, &encoding, 'char'))
  return []
endfunction"}}}

function! s:source.async_gather_candidates(args, context) abort "{{{
  if !has_key(a:context, 'source__proc')
    let a:context.is_async = 0
    return []
  endif

  let stderr = a:context.source__proc.stderr
  if !stderr.eof
    " Print error.
    let errors = filter(unite#util#read_lines(stderr, 200),
          \ "v:val !~ '^\\s*$'")
    if !empty(errors)
      call unite#print_source_error(errors, s:source.name)
    endif
  endif

  let stdout = a:context.source__proc.stdout
  if stdout.eof
    " Disable async.
    let a:context.is_async = 0
    call a:context.source__proc.waitpid()
  endif

  return map(unite#util#read_lines(stdout, 1000),
          \ "s:create_candidate(unite#util#iconv(
          \    v:val, 'char', &encoding))")
endfunction"}}}

function! s:source.complete(args, context, arglead, cmdline, cursorpos) abort "{{{
  if len(a:args) < 1
    let path = substitute($PATH,
          \ (unite#util#is_windows() ? ';' : ':'), ',', 'g')
    return filter(map(unite#sources#launcher#get_executables(path),
          \ "fnamemodify(v:val, ':t')"), "stridx(v:val, a:arglead) == 0")
  elseif len(a:args) == 2
    return unite#sources#file#complete_file(
          \ a:args, a:context, split(a:arglead, ':')[1], a:cmdline, a:cursorpos)
  else
    return []
  endif
endfunction"}}}

function! s:create_candidate(val) abort "{{{
  let matches = matchlist(a:val, '^\(.*\)\t\(.*\)$')

  if empty(matches)
    return { 'word' : 'none', 'is_dummy' : 1 }
  endif

  return {
        \ 'word' : matches[1],
        \ 'action__command' : matches[2]
        \ }
endfunction"}}}

function! unite#sources#script#define() abort
  return s:source
endfunction

" vim: foldmethod=marker
