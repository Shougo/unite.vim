"=============================================================================
" FILE: window.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 17 Jul 2011.
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

function! unite#sources#window#define()"{{{
  return s:source
endfunction"}}}
function! unite#sources#window#_append()"{{{
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
      \}

function! s:source.hooks.on_init(args, context)"{{{
  let l:list = range(1, winnr('$'))
  for i in l:list
    " Set default value.
    if type(getwinvar(i, 'unite_window')) == type('')
      call setwinvar(i, 'unite_window', {
            \ 'time' : 0,
            \ 'cwd' : getcwd(),
            \ })
    endif
  endfor

  unlet l:list[winnr()-1]
  call sort(l:list, 's:compare')
  let l:arg = get(a:args, 0, '')
  if l:arg !=# 'no-current'
    " Add current window.
    call add(l:list, winnr())
  endif

  let a:context.source__candidates = []
  for i in l:list
    let l:window = getwinvar(i, 'unite_window')
    let l:bufname = bufname(winbufnr(i))
    if empty(l:bufname)
      let l:bufname = '[No Name]'
    endif

    call add(a:context.source__candidates, {
          \ 'word' : l:bufname,
          \ 'abbr' : printf('[%d/%d] %s %s(%s)', i, winnr('$'),
          \      (i == winnr() ? '%' : i == winnr('#') ? '#' : ' '),
          \      l:bufname, l:window.cwd),
          \ 'kind' : 'window',
          \ 'action__window_nr' : i,
          \ 'action__directory' : l:window.cwd,
          \ })
  endfor
endfunction"}}}
function! s:source.gather_candidates(args, context)"{{{
  return a:context.source__candidates
endfunction"}}}

" Misc
function! s:compare(candidate_a, candidate_b)"{{{
  return getwinvar(a:candidate_b, 'unite_window').time - getwinvar(a:candidate_a, 'unite_window').time
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
