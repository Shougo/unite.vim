"=============================================================================
" FILE: window.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 02 Oct 2012.
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

function! unite#sources#window#define() "{{{
  return s:source
endfunction"}}}
function! unite#sources#window#_append() "{{{
  if &filetype == 'unite'
    " Ignore unite window.
    return
  endif

  " Save unite window information.
  let w:unite_window = {
        \ 'time' : localtime(),
        \ 'cwd' : getcwd(),
        \}
endfunction"}}}

let s:source = {
      \ 'name' : 'window',
      \ 'description' : 'candidates from window list',
      \ 'hooks' : {},
      \ 'default_kind' : 'window',
      \}

function! s:source.hooks.on_init(args, context) "{{{
  let list = range(1, winnr('$'))
  for i in list
    " Set default value.
    if type(getwinvar(i, 'unite_window')) == type('')
      call setwinvar(i, 'unite_window', {
            \ 'time' : 0,
            \ 'cwd' : getcwd(),
            \ })
    endif
  endfor

  unlet list[winnr()-1]
  call sort(list, 's:compare')
  let arg = get(a:args, 0, '')
  if arg !=# 'no-current'
    " Add current window.
    call add(list, winnr())
  endif

  let a:context.source__candidates = []
  for i in list
    let window = getwinvar(i, 'unite_window')
    let bufname = bufname(winbufnr(i))
    if empty(bufname)
      let bufname = '[No Name]'
    endif

    call add(a:context.source__candidates, {
          \ 'word' : bufname,
          \ 'abbr' : printf('[%d/%d] %s %s(%s)', i, winnr('$'),
          \      (i == winnr() ? '%' : i == winnr('#') ? '#' : ' '),
          \      bufname, window.cwd),
          \ 'action__window_nr' : i,
          \ 'action__buffer_nr' : winbufnr(i),
          \ 'action__directory' : window.cwd,
          \ })
  endfor
endfunction"}}}
function! s:source.gather_candidates(args, context) "{{{
  return a:context.source__candidates
endfunction"}}}
function! s:source.complete(args, context, arglead, cmdline, cursorpos) "{{{
  return ['no-current']
endfunction"}}}

" Misc
function! s:compare(candidate_a, candidate_b) "{{{
  return getwinvar(a:candidate_b, 'unite_window').time - getwinvar(a:candidate_a, 'unite_window').time
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
