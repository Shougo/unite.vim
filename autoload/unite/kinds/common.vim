"=============================================================================
" FILE: common.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 29 Apr 2013.
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

function! unite#kinds#common#define() "{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'common',
      \ 'default_action' : 'nop',
      \ 'action_table': {},
      \ 'parents': [],
      \}

" Actions "{{{
let s:kind.action_table.nop = {
      \ 'description' : 'no operation',
      \ }
function! s:kind.action_table.nop.func(candidate) "{{{
endfunction"}}}

let s:kind.action_table.yank = {
      \ 'description' : 'yank word or text',
      \ 'is_selectable' : 1,
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.yank.func(candidates) "{{{
  let text = join(map(copy(a:candidates),
        \ 's:get_candidate_text(v:val)'), "\n")
  let @" = text
  echo 'Yanked: ' . text

  if has('clipboard')
    let @* = text
  endif
endfunction"}}}

let s:kind.action_table.yank_escape = {
      \ 'description' : 'yank escaped word or text',
      \ }
function! s:kind.action_table.yank_escape.func(candidate) "{{{
  let @" = escape(s:get_candidate_text(a:candidate), " *?[{`$\\%#\"|!<>")
endfunction"}}}

let s:kind.action_table.ex = {
      \ 'description' : 'insert candidates into command line',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.ex.func(candidates) "{{{
  " Result is ':| {candidate}', here '|' means the cursor position.
  call feedkeys(printf(": %s\<C-b>",
        \ join(map(map(copy(a:candidates), 'v:val.word'),
        \ 'escape(v:val, " *?[{`$\\%#\"|!<>")'))), 'n')
endfunction"}}}

let s:kind.action_table.insert = {
      \ 'description' : 'insert word or text',
      \ }
function! s:kind.action_table.insert.func(candidate) "{{{
  call unite#kinds#common#insert_word(s:get_candidate_text(a:candidate),
        \ { 'regtype' : get(a:candidate, 'action__regtype', 'v')})
endfunction"}}}

let s:kind.action_table.insert_directory = {
      \ 'description' : 'insert directory',
      \ }
function! s:kind.action_table.insert_directory.func(candidate) "{{{
  let context = unite#get_current_unite().context

  if has_key(a:candidate,'action__directory')
      let directory = a:candidate.action__directory
  elseif has_key(a:candidate, 'action__path')
      let directory = unite#util#substitute_path_separator(
            \ fnamemodify(a:candidate.action__path, ':p:h'))
  elseif has_key(a:candidate, 'word') && isdirectory(a:candidate.word)
      let directory = a:candidate.word
  else
      return
  endif

  call unite#kinds#common#insert_word(directory)
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview word',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate) "{{{
  redraw
  echo s:get_candidate_text(a:candidate)
endfunction"}}}

let s:kind.action_table.echo = {
      \ 'description' : 'echo candidates for debug',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.echo.func(candidates) "{{{
  echomsg string(a:candidates)
endfunction"}}}
"}}}

function! unite#kinds#common#insert_word(word, ...) "{{{
  let unite = unite#get_current_unite()
  let context = unite.context
  let opt = get(a:000, 0, {})
  let col = get(opt, 'col', context.col)
  let regtype = get(opt, 'regtype', 'v')

  if !context.complete
    " Paste.
    let old_reg = [getreg('"'), getregtype('"')]

    call setreg('"', a:word, regtype)
    try
      execute 'normal! ""'.(
            \ regtype !=# 'v' || (col('$') - col('.') <= 1) ? 'p' : 'P')
    finally
      call setreg('"', old_reg[0], old_reg[1])
    endtry

    " Open folds.
    normal! zv

    return
  endif

  let cur_text = col < 0 ? '' :
        \ matchstr(getline('.'), '^.*\%' . col . 'c.')

  let next_line = getline('.')[context.col-1 :]
  call setline(line('.'),
        \ split(cur_text . a:word . next_line,
        \            '\n\|\r\n'))
  let next_col = len(cur_text)+len(a:word)+1
  call cursor('', next_col)

  if next_col < col('$')
    startinsert
  else
    startinsert!
  endif
endfunction"}}}
function! s:get_candidate_text(candidate) "{{{
  return get(a:candidate, 'action__text', a:candidate.word)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
