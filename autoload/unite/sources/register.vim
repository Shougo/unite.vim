"=============================================================================
" FILE: register.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 18 Nov 2010
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

function! unite#sources#register#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'register',
      \}

function! s:source.gather_candidates(args, context)"{{{
  let l:candidates = []

  let l:max_width = winwidth(0) - 40
  for l:reg in ['"', '*', '+', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']

    let l:register = eval('@' . l:reg)
    call add(l:candidates, {
          \ 'word' : l:register,
          \ 'abbr' : printf('register%s - %s', l:reg, l:register[: l:max_width]),
          \ 'source' : 'register',
          \ 'kind' : 'word',
          \ })
  endfor

  return l:candidates
endfunction"}}}

" vim: foldmethod=marker
