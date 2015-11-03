"=============================================================================
" FILE: output_shellcmd.vim
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

let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#output_shellcmd#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'output/shellcmd',
      \ 'description' : 'candidates from shell command output',
      \ 'default_action' : 'yank',
      \ 'default_kind' : 'word',
      \ 'hooks' : {},
      \ }

function! s:source.hooks.on_init(args, context) "{{{
  if type(get(a:args, 0, '')) == type([])
    " Use args directly.
    let a:context.source__is_dummy = 0
    return
  endif

  let command = join(copy(a:args), "v:val !=# '!'")
  if command == ''
    let command = unite#util#input(
          \ 'Please input shell command: ', '', 'shellcmd')
    redraw
  endif
  let a:context.source__command = command
  let a:context.source__is_dummy =
        \ (get(a:args, -1, '') ==# '!')

  if !a:context.source__is_dummy
    call unite#print_source_message(
          \ 'command: ' . command, s:source.name)
  endif
endfunction"}}}
function! s:source.gather_candidates(args, context) "{{{
  if !unite#util#has_vimproc()
    call unite#print_source_message(
          \ 'vimproc plugin is not installed.', self.name)
    let a:context.is_async = 0
    return []
  endif

  if a:context.is_redraw
    let a:context.is_async = 1
  endif

  let save_term = $TERM
  try
    " Disable colors.
    let $TERM = 'dumb'

    let a:context.source__proc = vimproc#plineopen2(
          \ vimproc#util#iconv(
          \   a:context.source__command, &encoding, 'char'), 1)
  catch
    call unite#print_error(v:exception)
    let a:context.is_async = 0
    return []
  finally
    let $TERM = save_term
  endtry

  return self.async_gather_candidates(a:args, a:context)
endfunction"}}}
function! s:source.async_gather_candidates(args, context) "{{{
  let stdout = a:context.source__proc.stdout
  if stdout.eof
    " Disable async.
    let a:context.is_async = 0
    call a:context.source__proc.waitpid()
  endif

  let lines = map(unite#util#read_lines(stdout, 1000),
          \ "unite#util#iconv(v:val, 'char', &encoding)")

  return map(lines, "{
        \ 'word' : v:val,
        \ 'is_multiline' : 1,
        \ 'is_dummy' : a:context.source__is_dummy,
        \ }")
endfunction"}}}
function! s:source.hooks.on_close(args, context) "{{{
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.kill()
  endif
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
