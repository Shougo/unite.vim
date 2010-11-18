"=============================================================================
" FILE: jump_list.vim
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

" Variables  "{{{
if !exists('g:unite_kind_jump_list_search_range')
  let g:unite_kind_jump_list_search_range = 100
endif
"}}}

function! unite#kinds#jump_list#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'jump_list',
      \ 'default_action' : 'open',
      \ 'action_table': {},
      \}

" Actions"{{{
let s:kind.action_table = deepcopy(unite#kinds#file#define().action_table)

let s:kind.action_table.open = {
      \ 'description' : 'jump this position',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.open.func(candidates)"{{{
  for l:candidate in a:candidates
    let l:linenr = s:get_match_linenr(l:candidate)
    execute 'edit' (l:linenr > 0 ? '+'.l:linenr : '') '`=l:candidate.action__path`'

    " Open folds.
    normal! zv
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview this position',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate)"{{{
  let l:linenr = s:get_match_linenr(a:candidate)
  execute 'edit' (l:linenr > 0 ? '+'.l:linenr : '') '`=l:candidate.action__path`'
endfunction"}}}
"}}}

" Misc.
function! s:get_match_linenr(candidate)"{{{
  if !has_key(a:candidate, 'action__line') && !has_key(a:candidate, 'action__pattern')
    return 0
  endif

  if !has_key(a:candidate, 'action__pattern')
    return a:candidate.action__line
  endif

  let l:lines = readfile(a:candidate.action__path)
  let l:max = len(l:lines)
  let l:start = has_key(a:candidate, 'action__line') ?
        \ min([a:candidate.action__line - 1, l:max]) : l:max

  " Search pattern.
  for [l1, l2] in map(range(0, g:unite_kind_jump_list_search_range),
        \ '[l:start + v:val, l:start - v:val]')
    if l1 >= 0 && l:lines[l1] =~# a:candidate.action__pattern
      return l1+1
    elseif l2 <= l:max && l:lines[l2] =~# a:candidate.action__pattern
      return l2+1
    endif
  endfor

  return l:start
endfunction"}}}

" vim: foldmethod=marker
