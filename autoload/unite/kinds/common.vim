"=============================================================================
" FILE: common.vim
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

let s:kind.action_table.insert = {
      \ 'description' : 'insert word',
      \ }
function! s:kind.action_table.insert.func(candidate)"{{{
  let [l:old_col, l:old_max_col] = [col('.'), col('$')]

  " Paste.
  let l:old_reg = @"
  let @" = a:candidate.word
  normal! ""p
  let @" = l:old_reg

  if unite#get_context().is_insert
    PP! [l:old_col+len(a:candidate.word), l:old_max_col]
    if l:old_col+1 >= l:old_max_col
      startinsert!
    else
      let l:pos = getpos('.')
      let l:pos[2] += len(a:candidate.word)
      call setpos('.', l:pos)
    endif
  endif
endfunction"}}}
"}}}

" vim: foldmethod=marker
