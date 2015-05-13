"=============================================================================
" FILE: find.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
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

" Variables  "{{{
call unite#util#set_default('g:unite_source_find_command', 'find')
call unite#util#set_default('g:unite_source_find_default_opts', '')
call unite#util#set_default('g:unite_source_find_max_candidates', 100)
"}}}

function! unite#sources#find#define() "{{{
  return executable(g:unite_source_find_command) && unite#util#has_vimproc() ?
        \ s:source : []
endfunction "}}}

let s:source = {
      \ 'name': 'find',
      \ 'max_candidates': g:unite_source_find_max_candidates,
      \ 'hooks' : {},
      \ 'matchers' : ['matcher_regexp'],
      \ 'ignore_globs' : [
      \         '*~', '*.o', '*.exe', '*.bak',
      \         'DS_Store', '*.pyc', '*.sw[po]', '*.class',
      \         '.hg/**', '.git/**', '.bzr/**', '.svn/**',
      \ ],
      \ }

function! s:source.hooks.on_init(args, context) "{{{
  let target = get(a:args, 0, '')
  if target == ''
    let target = isdirectory(a:context.path) ?
      \ a:context.path :
      \ unite#helper#parse_source_path(
        \ unite#util#input('Target: ', '.', 'dir'))
  endif

  let a:context.source__targets = split(target, "\n")
  let a:context.source__input = get(a:args, 1, '')
  if a:context.source__input == ''
    redraw
    echo "Please input command-line(quote is needed) Ex: -name '*.vim'"
    let a:context.source__input = unite#util#input(
          \ printf('"%s" %s %s ',
          \   g:unite_source_find_command,
          \   g:unite_source_find_default_opts,
          \   unite#helper#join_targets(a:context.source__targets)), '-name ')
  endif
endfunction"}}}
function! s:source.hooks.on_close(args, context) "{{{
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.waitpid()
  endif
endfunction "}}}

function! s:source.gather_candidates(args, context) "{{{
  if empty(a:context.source__targets)
        \ || a:context.source__input == ''
    let a:context.is_async = 0
    return []
  endif

  if unite#util#is_windows() &&
        \ vimproc#get_command_name(g:unite_source_find_command)
        \     =~? '/Windows/system.*/find\.exe$'
    call unite#print_source_message(
          \ 'Detected windows find command.', s:source.name)
    let a:context.is_async = 0
    return []
  endif

  if a:context.is_redraw
    let a:context.is_async = 1
  endif

  let cmdline = printf('"%s" %s %s %s',
        \ g:unite_source_find_command, g:unite_source_find_default_opts,
        \ unite#helper#join_targets(a:context.source__targets),
        \ a:context.source__input)
  call unite#print_source_message('Command-line: ' . cmdline, s:source.name)
  let a:context.source__proc = vimproc#popen3(
        \ vimproc#util#iconv(cmdline, &encoding, 'char'))

  " Close handles.
  call a:context.source__proc.stdin.close()
  call a:context.source__proc.stderr.close()

  return []
endfunction "}}}

function! s:source.async_gather_candidates(args, context) "{{{
  let stdout = a:context.source__proc.stdout
  if stdout.eof
    " Disable async.
    let a:context.is_async = 0
  endif

  let candidates = map(filter(
        \ stdout.read_lines(-1, 1000), "v:val !~ '^\\s*$'"),
        \ "fnamemodify(unite#util#iconv(v:val, 'char', &encoding), ':p')")

  let cwd = getcwd()
  if isdirectory(a:context.source__targets[0])
    call unite#util#lcd(a:context.source__targets[0])
  endif

  call map(candidates, "{
    \   'word' : unite#util#substitute_path_separator(v:val),
    \   'kind' : (isdirectory(v:val) ? 'directory' : 'file'),
    \   'action__path' : unite#util#substitute_path_separator(v:val),
    \ }")

  call unite#util#lcd(cwd)

  return candidates
endfunction "}}}

function! s:source.complete(args, context, arglead, cmdline, cursorpos) "{{{
  return unite#sources#file#complete_directory(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}

" vim: foldmethod=marker
