"=============================================================================
" FILE: directory.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 31 Oct 2010
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

function! unite#kinds#directory#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'directory',
      \ 'default_action' : 'narrow',
      \ 'action_table': {},
      \ 'parents': ['file'],
      \}

if exists(':VimFiler')
  " Set alias.
  let s:kind.alias_table = { 'tabopen' : 'tabvimfiler' }
endif

" Actions"{{{
let s:kind.action_table.diff = {
      \ 'description' : 'diff with the other directories',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.diff.func(candidates)
  if !empty(filter(copy(a:candidates), '!isdirectory(v:val.action__path)'))
    echo 'Invalid directories.'
    return
  elseif len(a:candidates) < 1
    echo 'Too few candidates!'
  endif

  " Todo.
endfunction
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
