"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 17 Sep 2010
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

function! unite#kinds#file#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'file',
      \ 'default_action' : 'open',
      \ 'action_table': {},
      \}

" Actions"{{{
let s:kind.action_table.open = {
      \ 'is_selectable' : 1, 
      \ }
function! s:kind.action_table.open.func(candidate)"{{{
  edit `=a:candidate.word`
endfunction"}}}

let s:kind.action_table.fopen = {
      \ 'is_selectable' : 1, 
      \ }
function! s:kind.action_table.fopen.func(candidate)"{{{
  edit! `=a:candidate.word`
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate)"{{{
  pedit `=a:candidate.word`
endfunction"}}}

let s:kind.action_table.tabopen = {
      \ 'is_selectable' : 1, 
      \ }
function! s:kind.action_table.tabopen.func(candidate)"{{{
  tabedit `=a:candidate.word`
endfunction"}}}

let s:kind.action_table.split = {
      \ 'is_selectable' : 1, 
      \ }
function! s:kind.action_table.split.func(candidate)"{{{
  split `=a:candidate.word`
endfunction"}}}

let s:kind.action_table.vsplit = {
      \ 'is_selectable' : 1, 
      \ }
function! s:kind.action_table.vsplit.func(candidate)"{{{
  vsplit `=a:candidate.word`
endfunction"}}}

let s:kind.action_table.left = {
      \ 'is_selectable' : 1, 
      \ }
function! s:kind.action_table.left.func(candidate)"{{{
  leftabove vsplit `=a:candidate.word`
endfunction"}}}

let s:kind.action_table.right = {
      \ 'is_selectable' : 1, 
      \ }
function! s:kind.action_table.right.func(candidate)"{{{
  rightbelow vsplit `=a:candidate.word`
endfunction"}}}

let s:kind.action_table.above = {
      \ 'is_selectable' : 1, 
      \ }
function! s:kind.action_table.above.func(candidate)"{{{
  leftabove split `=a:candidate.word`
endfunction"}}}

let s:kind.action_table.below = {
      \ 'is_selectable' : 1, 
      \ }
function! s:kind.action_table.below.func(candidate)"{{{
  rightbelow split `=a:candidate.word`
endfunction"}}}

let s:kind.action_table.cd = {
      \ }
function! s:kind.action_table.cd.func(candidate)"{{{
  let l:dir = isdirectory(a:candidate.word) ? a:candidate.word : fnamemodify(a:candidate.word, ':p:h')
  cd `=l:dir`
endfunction"}}}

let s:kind.action_table.lcd = {
      \ }
function! s:kind.action_table.lcd.func(candidate)"{{{
  let l:dir = isdirectory(a:candidate.word) ? a:candidate.word : fnamemodify(a:candidate.word, ':p:h')
  lcd `=l:dir`
endfunction"}}}

let s:kind.action_table.ex = {
      \ }
function! s:kind.action_table.ex.func(candidate)"{{{
  " Result is ':| {candidate}', here '|' means the cursor position.
  call feedkeys(printf(": %s\<C-b>", escape(a:candidate.word, " \t\n*?[{`$\\%#'\"|!<")), 'n')
endfunction"}}}
"}}}


" vim: foldmethod=marker
