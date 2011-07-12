"=============================================================================
" FILE: completion.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 10 Jul 2011.
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

function! unite#kinds#completion#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'completion',
      \ 'default_action' : 'insert',
      \ 'action_table': {},
      \}

" Actions"{{{
let s:kind.action_table.insert = {
      \ 'description' : 'insert word',
      \ }
function! s:kind.action_table.insert.func(candidate)"{{{
  let l:col = a:candidate.action__complete_pos
  let l:cur_text = matchstr(getline('.'), '^.*\%' . l:col . 'c.')
  let l:word = a:candidate.action__complete_word

  " Insert word.
  let l:context_col = unite#get_current_unite().context.col
  let l:next_line = l:context_col < col('$') ?
        \ getline('.')[l:context_col-1 :] : ''
  let l:next_line = getline('.')[l:context_col :]
  call setline(line('.'), split(l:cur_text . l:word . l:next_line, '\n\|\r\n'))
  let l:pos = getpos('.')
  let l:pos[2] = len(l:cur_text)+len(l:word)+1
  call setpos('.', l:pos)
  let l:next_col = len(l:cur_text)+len(l:word)+1

  if l:next_col < col('$')
    startinsert
  else
    startinsert!
  endif
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview word in echo area',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate)"{{{
  echo ''
  redraw

  let complete_info = has_key(a:candidate, 'action__complete_info') ?
        \ a:candidate.action__complete_info :
        \ has_key(a:candidate, 'action__complete_info_lazy') ?
        \ a:candidate.action__complete_info_lazy() :
        \ ''
  if complete_info != ''
    let S = vital#of('unite').import('Data.String')
    echo join(S.wrap(complete_info)[: &cmdheight-1], "\n")
  endif
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
