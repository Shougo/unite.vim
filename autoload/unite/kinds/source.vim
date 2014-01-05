"=============================================================================
" FILE: source.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 05 Jan 2014.
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

function! unite#kinds#source#define() "{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'source',
      \ 'default_action' : 'start',
      \ 'action_table': {},
      \}

" Actions "{{{
let s:kind.action_table.start = {
      \ 'description' : 'start source',
      \ 'is_selectable' : 1,
      \ 'is_quit' : 1,
      \ 'is_start' : 1,
      \ }
function! s:kind.action_table.start.func(candidates) "{{{
  call unite#start_temporary(map(copy(a:candidates),
        \ 'has_key(v:val, "action__source_args") ?'
        \  . 'insert(copy(v:val.action__source_args), v:val.action__source_name) :'
        \  . 'v:val.action__source_name'))
endfunction"}}}

let s:kind.action_table.edit = {
      \ 'description' : 'edit source args',
      \ 'is_quit' : 0,
      \ 'is_start' : 0,
      \ }
function! s:kind.action_table.edit.func(candidate) "{{{
  let default_args = get(a:candidate, 'action__source_args', '')
  if type(default_args) != type('')
        \ || type(default_args) != type(0)
    unlet default_args
    let default_args = ''
  endif

  let args = input(a:candidate.action__source_name . ' : ', default_args)
  call unite#start_temporary([[a:candidate.action__source_name, args]])
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
