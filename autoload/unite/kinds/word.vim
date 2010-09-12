"=============================================================================
" FILE: word.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 12 Sep 2010
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

function! unite#kinds#word#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'word',
      \ 'default_action' : 'insert',
      \ 'action_table': {},
      \}

" Actions"{{{
let s:kind.action_table.insert = {
      \ }
function! s:kind.action_table.insert.func(candidate)"{{{
  let [l:old_col, l:old_max_col] = [col('.'), col('$')]
  
  " Paste.
  let l:old_reg = @"
  let @" = a:candidate.word
  normal! ""p
  let @" = l:old_reg
  
  if a:candidate.is_insert
    PP! [l:old_col+len(a:candidate.word), l:old_max_col]
    if l:old_col+1 >= l:old_max_col
      startinsert!
    else
      let l:pos = getpos('.')
      let l:pos[2] += len(a:candidate.word)
      call setpos('.', l:pos)
    endif
  endif
  
  return 0
endfunction"}}}
"}}}

" vim: foldmethod=marker
