"=============================================================================
" FILE: completion.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
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

function! unite#kinds#completion#define() abort "{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'completion',
      \ 'default_action' : 'insert',
      \ 'action_table': {},
      \}

" Actions "{{{
let s:kind.action_table.insert = {
      \ 'description' : 'insert word',
      \ }
function! s:kind.action_table.insert.func(candidate) abort "{{{
  call unite#kinds#common#insert_word(
        \ a:candidate.action__complete_word,
        \ { 'col' : a:candidate.action__complete_pos})
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview word in echo area',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate) abort "{{{
  echo ''
  redraw

  let complete_info = has_key(a:candidate, 'action__complete_info') ?
        \ a:candidate.action__complete_info :
        \ has_key(a:candidate, 'action__complete_info_lazy') ?
        \ a:candidate.action__complete_info_lazy() :
        \ ''
  if complete_info != ''
    let S = unite#util#get_vital().import('Data.String')
    echo join(S.wrap(complete_info)[: &cmdheight-1], "\n")
  endif
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
