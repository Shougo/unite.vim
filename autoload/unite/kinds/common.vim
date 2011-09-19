"=============================================================================
" FILE: common.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 19 Sep 2011.
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

function! unite#kinds#common#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'common',
      \ 'default_action' : 'nop',
      \ 'action_table': {},
      \ 'parents': [],
      \}

" Actions"{{{
let s:kind.action_table.nop = {
      \ 'description' : 'no operation',
      \ }
function! s:kind.action_table.nop.func(candidate)"{{{
endfunction"}}}

let s:kind.action_table.yank = {
      \ 'description' : 'yank text',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.yank.func(candidates)"{{{
  let @" = join(map(copy(a:candidates), 'v:val.word'), "\n")
  if has('clipboard')
    let @* = @"
  endif
endfunction"}}}

let s:kind.action_table.yank_escape = {
      \ 'description' : 'yank escaped text',
      \ }
function! s:kind.action_table.yank_escape.func(candidate)"{{{
  let @" = escape(a:candidate.word, " *?[{`$\\%#\"|!<>")
endfunction"}}}

let s:kind.action_table.ex = {
      \ 'description' : 'insert candidates into command line',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.ex.func(candidates)"{{{
  " Result is ':| {candidate}', here '|' means the cursor position.
  call feedkeys(printf(": %s\<C-b>", join(map(map(copy(a:candidates), 'v:val.word'), 'escape(v:val, " *?[{`$\\%#\"|!<>")'))), 'n')
endfunction"}}}

let s:kind.action_table.insert = {
      \ 'description' : 'insert word',
      \ }
function! s:kind.action_table.insert.func(candidate)"{{{
  let context = unite#get_current_unite().context

  if !context.complete
    " Paste.
    let old_reg = @"
    let @" = a:candidate.word
    normal! ""p
    let @" = old_reg

    return
  endif

  let cur_text = matchstr(getline('.'), '^.*\%'
        \ . (context.col-1) . 'c.')

  let next_line = getline('.')[context.col :]
  call setline(line('.'),
        \ split(cur_text . a:candidate.word . next_line,
        \            '\n\|\r\n'))
  let next_col = len(cur_text)+len(a:candidate.word)+1
  call cursor('', next_col)

  if next_col < col('$')
    startinsert
  else
    startinsert!
  endif
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
