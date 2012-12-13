"=============================================================================
" FILE: window.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 23 Jun 2012.
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

function! unite#kinds#window#define() "{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'window',
      \ 'default_action' : 'open',
      \ 'action_table': {},
      \ 'parents' : ['cdable'],
      \}

" Actions "{{{
let s:kind.action_table.open = {
      \ 'description' : 'move to this window',
      \ }
function! s:kind.action_table.open.func(candidate) "{{{
  execute a:candidate.action__window_nr.'wincmd w'
endfunction"}}}

let s:kind.action_table.only = {
      \ 'description' : 'only this window',
      \ }
function! s:kind.action_table.only.func(candidate) "{{{
  execute a:candidate.action__window_nr.'wincmd w'
  only
endfunction"}}}

let s:kind.action_table.delete = {
      \ 'description' : 'delete windows',
      \ 'is_selectable' : 1,
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.delete.func(candidates) "{{{
  for candidate in sort(a:candidates, 's:compare')
    close
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview window',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate) "{{{
  if !has_key(a:candidate, 'action__buffer_nr')
    return
  endif

  let winnr = winnr()
  execute bufwinnr(a:candidate.action__buffer_nr).'wincmd w'
  execute 'match Search /\%'.line('.').'l/'
  redraw
  sleep 500m
  match
  execute winnr.'wincmd w'
endfunction"}}}
"}}}

" Misc
function! s:compare(candidate_a, candidate_b) "{{{
  return a:candidate_b.action__window_nr - a:candidate_a.action__window_nr
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
