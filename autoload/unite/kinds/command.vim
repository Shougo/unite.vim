"=============================================================================
" FILE: command.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 25 Jun 2011.
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

function! unite#kinds#command#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'command',
      \ 'default_action' : 'execute',
      \ 'action_table': {},
      \ 'alias_table' : { 'ex' : 'nop' },
      \}

" Actions"{{{
let s:kind.action_table.execute = {
      \ 'description' : 'execute command',
      \ }
function! s:kind.action_table.execute.func(candidate)"{{{
  " Add history.
  let l:type = has_key(a:candidate, 'action__type') ? a:candidate.action__type : ':'
  call histadd(l:type, a:candidate.action__command)
  if l:type ==# '/'
    let @/ = a:candidate.action__command
  endif

  execute l:type.a:candidate.action__command
endfunction"}}}
let s:kind.action_table.edit = {
      \ 'description' : 'edit command',
      \ }
function! s:kind.action_table.edit.func(candidate)"{{{
  call feedkeys(':' . a:candidate.action__command, 'n')
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
