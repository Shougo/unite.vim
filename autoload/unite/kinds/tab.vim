"=============================================================================
" FILE: tab.vim
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

function! unite#kinds#tab#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'tab',
      \ 'default_action' : 'open',
      \ 'action_table': {},
      \ 'alias_table': { 'edit' : 'rename' },
      \}

" Actions"{{{
let s:kind.action_table.open = {
      \ 'description' : 'open this tab',
      \ }
function! s:kind.action_table.open.func(candidate)"{{{
  execute 'tabnext' a:candidate.action__tab_nr
endfunction"}}}

let s:kind.action_table.delete = {
      \ 'description' : 'delete tabs',
      \ 'is_selectable' : 1,
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.delete.func(candidates)"{{{
  for l:candidate in sort(a:candidates, 's:compare')
    execute 'tabclose' l:candidate.action__tab_nr
  endfor
endfunction"}}}

if exists('*gettabvar')
  " Enable cd action.
  let s:kind.parents = ['cdable']

  let s:kind.action_table.rename = {
      \ 'description' : 'rename tabs',
      \ 'is_selectable' : 1,
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
        \ }
  function! s:kind.action_table.rename.func(candidates)"{{{
    for l:candidate in a:candidates
      let l:old_title = gettabvar(l:candidate.action__tab_nr, 'title')
      let l:title = input(printf('New title: %s -> ', l:old_title), l:old_title)
      if l:title != '' && l:title !=# l:old_title
        call settabvar(l:candidate.action__tab_nr, 'title', l:title)
      endif
    endfor
  endfunction"}}}
endif
"}}}

" Misc
function! s:compare(candidate_a, candidate_b)"{{{
  return a:candidate_b.action__tab_nr - a:candidate_a.action__tab_nr
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
