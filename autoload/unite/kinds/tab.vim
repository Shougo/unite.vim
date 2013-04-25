"=============================================================================
" FILE: tab.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 25 Apr 2013.
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

function! unite#kinds#tab#define() "{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'tab',
      \ 'default_action' : 'open',
      \ 'action_table': {},
      \ 'alias_table': { 'edit' : 'rename' },
      \}

" Actions "{{{
let s:kind.action_table.open = {
      \ 'description' : 'open this tab',
      \ }
function! s:kind.action_table.open.func(candidate) "{{{
  execute 'tabnext' a:candidate.action__tab_nr
endfunction"}}}

let s:kind.action_table.delete = {
      \ 'description' : 'delete tabs',
      \ 'is_selectable' : 1,
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.delete.func(candidates) "{{{
  for candidate in sort(a:candidates, 's:compare')
    execute 'tabclose' candidate.action__tab_nr
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview tab',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate) "{{{
  let tabnr = tabpagenr()
  execute 'tabnext' a:candidate.action__tab_nr
  redraw
  sleep 500m
  execute 'tabnext' tabnr
endfunction"}}}

let s:kind.action_table.unite__new_candidate = {
      \ 'description' : 'create new tab',
      \ 'is_invalidate_cache' : 1,
      \ }
function! s:kind.action_table.unite__new_candidate.func(candidate) "{{{
  let title = input('Please input tab title: ', '',
        \ 'customlist,' . s:SID_PREFIX() . 'history_complete')

  tabnew
  if title != ''
    let t:title = title
  endif
endfunction"}}}

" Anywhere SID.
function! s:SID_PREFIX()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSID_PREFIX$')
endfunction

function! s:history_complete(arglead, cmdline, cursorpos)
  return filter(map(reverse(range(1, histnr('input'))),
  \                     'histget("input", v:val)'),
  \                 'v:val != "" && stridx(v:val, a:arglead) == 0')
endfunction

if exists('*gettabvar')
  " Enable cd action.
  let s:kind.parents = ['cdable']

  let s:kind.action_table.rename = {
      \ 'description' : 'rename tabs',
      \ 'is_selectable' : 1,
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
        \ }
  function! s:kind.action_table.rename.func(candidates) "{{{
    for candidate in a:candidates
      let old_title = gettabvar(candidate.action__tab_nr, 'title')
      let title = input(printf('New title: %s -> ', old_title), old_title)
      if title != '' && title !=# old_title
        call settabvar(candidate.action__tab_nr, 'title', title)
      endif
    endfor
  endfunction"}}}
endif
"}}}

" Misc
function! s:compare(candidate_a, candidate_b) "{{{
  return a:candidate_b.action__tab_nr - a:candidate_a.action__tab_nr
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
