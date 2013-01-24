"=============================================================================
" FILE: history_input.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
" Last Modified: 24 Jan 2013.
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

function! unite#sources#history_input#define()
  return s:source
endfunction

let s:source = {
      \ 'name' : 'history/input',
      \ 'description' : 'candidates from unite input history',
      \ 'action_table' : {},
      \ 'default_action' : 'narrow',
      \ 'is_listed' : 0,
      \}

function! s:source.gather_candidates(args, context) "{{{
  let context = unite#get_context()
  let inputs = unite#get_profile(
        \ context.old_buffer_info[0].profile_name, 'unite__inputs')
  let key = context.old_source_names_string
  if !has_key(inputs, key)
    return []
  endif

  return map(copy(inputs[key]), '{
        \ "word" : v:val
        \ }')
endfunction"}}}

" Actions "{{{
let s:source.action_table.narrow = {
      \ 'description' : 'narrow by history',
      \ 'is_quit' : 0,
      \ }
function! s:source.action_table.narrow.func(candidate) "{{{
  call unite#force_quit_session()
  call unite#mappings#narrowing(a:candidate.word)
endfunction"}}}

let s:source.action_table.delete = {
      \ 'description' : 'delete from input history',
      \ 'is_selectable' : 1,
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ }
function! s:source.action_table.delete.func(candidates) "{{{
  let context = unite#get_context()
  let inputs = unite#get_profile(
        \ context.old_buffer_info[0].profile_name, 'unite__inputs')
  let key = context.old_source_names_string
  if !has_key(inputs, key)
    return
  endif

  for candidate in a:candidates
    call filter(inputs[key], 'v:val !=# candidate.word')
  endfor
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo
