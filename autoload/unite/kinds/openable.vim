"=============================================================================
" FILE: openable.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 05 Aug 2012.
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
call unite#util#set_default('g:unite_kind_openable_persist_open_blink_time', '250m')
call unite#util#set_default('g:unite_kind_openable_cd_command', 'cd')
call unite#util#set_default('g:unite_kind_openable_lcd_command', 'lcd')
"}}}
function! unite#kinds#openable#define() "{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'openable',
      \ 'action_table': {},
      \}

" Actions "{{{
let s:kind.action_table.tabopen = {
      \ 'description' : 'tabopen items',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.tabopen.func(candidates) "{{{
  for candidate in a:candidates
    tabnew
    call unite#take_action('open', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.tabdrop = {
      \ 'description' : 'open files by ":tab drop" command',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.tabdrop.func(candidates) "{{{
  let bufpath = unite#util#substitute_path_separator(expand('%:p'))

  for candidate in a:candidates
    if bufpath !=# candidate.action__path
      call unite#util#smart_execute_command('tab drop',
            \ candidate.action__path)

      call unite#remove_previewed_buffer_list(
            \ bufnr(unite#util#escape_file_searching(
            \       candidate.action__path)))
    endif
  endfor
endfunction"}}}

let s:kind.action_table.split = {
      \ 'description' : 'horizontal split open items',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.split.func(candidates) "{{{
  for candidate in a:candidates
    call unite#util#command_with_restore_cursor('split')
    call unite#take_action('open', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.vsplit = {
      \ 'description' : 'vertical split open items',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.vsplit.func(candidates) "{{{
  for candidate in a:candidates
    call unite#util#command_with_restore_cursor('vsplit')
    call unite#take_action('open', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.left = {
      \ 'description' : 'vertical left split items',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.left.func(candidates) "{{{
  for candidate in a:candidates
    call unite#util#command_with_restore_cursor('leftabove vsplit')
    call unite#take_action('open', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.right = {
      \ 'description' : 'vertical right split open items',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.right.func(candidates) "{{{
  for candidate in a:candidates
    call unite#util#command_with_restore_cursor('rightbelow vsplit')
    call unite#take_action('open', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.above = {
      \ 'description' : 'horizontal above split open items',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.above.func(candidates) "{{{
  for candidate in a:candidates
    call unite#util#command_with_restore_cursor('leftabove split')
    call unite#take_action('open', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.below = {
      \ 'description' : 'horizontal below split open items',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.below.func(candidates) "{{{
  for candidate in a:candidates
    call unite#util#command_with_restore_cursor('rightbelow split')
    call unite#take_action('open', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.persist_open = {
      \ 'description' : 'persistent open',
      \ 'is_quit'     : 0,
      \ }
function! s:kind.action_table.persist_open.func(candidate) "{{{
  let unite = unite#get_current_unite()

  let current_winnr = winnr()

  let winnr = bufwinnr(unite.prev_bufnr)
  if winnr < 0
    let winnr = unite.prev_winnr
  endif
  if winnr == winnr() || winnr < 0
    call unite#util#command_with_restore_cursor('new')
  else
    execute winnr 'wincmd w'
  endif
  let unite.prev_winnr = winnr()

  call unite#take_action('open', a:candidate)
  let unite.prev_bufnr = bufnr('%')

  if g:unite_kind_openable_persist_open_blink_time != ''
    normal! V
    redraw!
    execute 'sleep ' . g:unite_kind_openable_persist_open_blink_time
    execute "normal! \<ESC>"
  endif

  let unite_winnr = bufwinnr(unite.bufnr)
  if unite_winnr < 0
    let unite_winnr = current_winnr
  endif
  if unite_winnr > 0
    execute unite_winnr 'wincmd w'
  endif
endfunction"}}}

"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
