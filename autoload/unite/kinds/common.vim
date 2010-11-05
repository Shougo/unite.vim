"=============================================================================
" FILE: common.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 05 Nov 2010
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

function! unite#kinds#common#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'common',
      \ 'default_action' : 'nop',
      \ 'action_table': {},
      \ 'parents': [],
      \}

" Actions"{{{
let s:kind.action_table.nop = {
      \ 'description' : 'no operation',
      \ }
function! s:kind.action_table.nop.func(candidate)"{{{
endfunction"}}}

let s:kind.action_table.yank = {
      \ 'description' : 'yank text',
      \ }
function! s:kind.action_table.yank.func(candidate)"{{{
  let @" = a:candidate.word
endfunction"}}}

let s:kind.action_table.ex = {
      \ 'description' : 'insert candidates into command line',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.ex.func(candidates)"{{{
  " Result is ':| {candidate}', here '|' means the cursor position.
  call feedkeys(printf(": %s\<C-b>", join(map(map(copy(a:candidates), 'v:val.word'), 'escape(v:val, " *?[{`$\\%#''|!<")'))), 'n')
endfunction"}}}
"}}}

" vim: foldmethod=marker
