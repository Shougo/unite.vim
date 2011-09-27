"=============================================================================
" FILE: history_yank.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 27 Sep 2011.
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

" Variables  "{{{
let s:yank_histories = []

call unite#util#set_default('g:unite_source_history_yank_limit', 100)
"}}}

function! unite#sources#history_yank#define()"{{{
  return s:source
endfunction"}}}
function! unite#sources#history_yank#_append()"{{{
  if empty(s:yank_histories) ||
        \ s:yank_histories[0] != @"
    " Append @" value.
    call insert(s:yank_histories, @")

    if g:unite_source_history_yank_limit > len(s:yank_histories)
      let s:yank_histories =
            \ s:yank_histories[ : g:unite_source_history_yank_limit - 1]
    endif
  endif
endfunction"}}}

let s:source = {
      \ 'name' : 'history/yank',
      \ 'description' : 'candidates from yank history',
      \ 'action_table' : {},
      \}

function! s:source.gather_candidates(args, context)"{{{
  return map(copy(s:yank_histories), '{
        \ "word" : v:val,
        \ "kind" : "word",
        \ }')
endfunction"}}}

" Actions"{{{
let s:source.action_table.delete = {
      \ 'description' : 'delete from yank history',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.delete.func(candidates)"{{{
  for candidate in a:candidates
    call filter(s:yank_histories, 'v:val !=# candidate.word')
  endfor
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
