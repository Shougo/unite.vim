"=============================================================================
" FILE: jump_list.vim
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
      \ 'is_selectable' : 1, 
      \ }
function! s:kind.action_table.open.func(candidates)"{{{
  for l:candidate in a:candidates
    edit `=l:candidate.action__path`

    let l:linenr = (has_key(l:candidate, 'action__line') && l:candidate.action__line != '') ? l:candidate.action__line : 1

    if has_key(l:candidate, 'action__pattern') && l:candidate.action__pattern != ''
          \ && getline(l:linenr) !~ l:candidate.action__pattern
      " Search pattern.
      call search(l:candidate.action__pattern, 'w')
    else
      " Jump to a:candidate.line.
      execute l:linenr
    endif

    " Open folds.
    normal! zv
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate)"{{{
  execute 'pedit'
        \ (has_key(a:candidate, 'action__line') && a:candidate.action__line != '' ? '+'.a:candidate.action__line : '')
        \ .(has_key(a:candidate, 'action__pattern') && a:candidate.action__pattern != '' ? '+/'.escape(a:candidate.action__pattern, "\t /") : '')
        \ '`=a:candidate.action__path`'
endfunction"}}}
"}}}

" vim: foldmethod=marker
