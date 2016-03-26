"=============================================================================
" FILE: openable.vim
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

" Variables  "{{{
call unite#util#set_default('g:unite_kind_openable_persist_open_blink_time', '250m')
"}}}
function! unite#kinds#openable#define() abort "{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'openable',
      \ 'action_table': {},
      \ 'parents' : [],
      \}

" Actions "{{{
let s:kind.action_table.tabopen = {
      \ 'description' : 'tabopen items',
      \ 'is_selectable' : 1,
      \ 'is_tab' : 1,
      \ }
function! s:kind.action_table.tabopen.func(candidates) abort "{{{
  for candidate in a:candidates
    let hidden_save = &hidden
    try
      set nohidden
      tabnew
      call unite#take_action('open', candidate)
    finally
      let &hidden = hidden_save
    endtry
  endfor
endfunction"}}}

let s:kind.action_table.choose = {
      \ 'description' : 'choose windows and open items',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.choose.func(candidates) abort "{{{
  for candidate in a:candidates
    if winnr('$') != 1
      let winnr = unite#helper#choose_window()
      if winnr > 0 && winnr != winnr()
        execute winnr.'wincmd w'
      endif
    endif

    call unite#take_action('open', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.split = {
      \ 'description' : 'horizontal split open items',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.split.func(candidates) abort "{{{
  for candidate in a:candidates
    call unite#util#command_with_restore_cursor('split')
    call unite#take_action('open', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.vsplit = {
      \ 'description' : 'vertical split open items',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.vsplit.func(candidates) abort "{{{
  for candidate in a:candidates
    call unite#util#command_with_restore_cursor('vsplit')
    call unite#take_action('open', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.left = {
      \ 'description' : 'vertical left split items',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.left.func(candidates) abort "{{{
  for candidate in a:candidates
    call unite#util#command_with_restore_cursor('leftabove vsplit')
    call unite#take_action('open', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.right = {
      \ 'description' : 'vertical right split open items',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.right.func(candidates) abort "{{{
  for candidate in a:candidates
    call unite#util#command_with_restore_cursor('rightbelow vsplit')
    call unite#take_action('open', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.above = {
      \ 'description' : 'horizontal above split open items',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.above.func(candidates) abort "{{{
  for candidate in a:candidates
    call unite#util#command_with_restore_cursor('leftabove split')
    call unite#take_action('open', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.below = {
      \ 'description' : 'horizontal below split open items',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.below.func(candidates) abort "{{{
  for candidate in a:candidates
    call unite#util#command_with_restore_cursor('rightbelow split')
    call unite#take_action('open', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.persist_open = {
      \ 'description' : 'persistent open',
      \ 'is_quit'     : 0,
      \ }
function! s:kind.action_table.persist_open.func(candidate) abort "{{{
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
  let unite.prev_pos = getpos('.')

  if g:unite_kind_openable_persist_open_blink_time != ''
    let left = getpos("'<")
    let right = getpos("'>")
    let vimode = visualmode()
    normal! V
    redraw!
    execute 'sleep ' . g:unite_kind_openable_persist_open_blink_time
    execute "normal! \<ESC>" . vimode . "\<ESC>"
    call setpos("'<", left)
    call setpos("'>", right)
  endif

  let unite_winnr = bufwinnr(unite.bufnr)
  if unite_winnr < 0
    let unite_winnr = current_winnr
  endif
  if unite_winnr > 0
    execute unite_winnr 'wincmd w'
  endif
endfunction"}}}

let s:kind.action_table.tabsplit = {
      \ 'description' : 'tabopen and split items',
      \ 'is_selectable' : 1,
      \ 'is_tab' : 1,
      \ }
function! s:kind.action_table.tabsplit.func(candidates) abort "{{{
  let hidden_save = &hidden
  try
    set nohidden
    tabnew
    silent call unite#take_action('open', a:candidates[0])
  finally
    let &hidden = hidden_save
  endtry

  for candidate in a:candidates[1:]
    silent call unite#take_action('vsplit', candidate)
  endfor

  " Resize all windows
  wincmd =
endfunction"}}}

let s:kind.action_table.switch = {
      \ 'description' : 'open in current window'
      \   . ' or jump to existing window/tabpage',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.switch.func(candidates) abort "{{{
  for candidate in a:candidates
    call s:switch(candidate)
  endfor
endfunction"}}}

let s:kind.action_table.tabswitch = {
      \ 'description' : 'open in new tab'
      \   . ' or jump to existing window/tabpage',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.tabswitch.func(candidates) abort "{{{
  for candidate in a:candidates
    if s:switch(candidate)
      call unite#take_action('tabopen', candidate)
    endif
  endfor
endfunction"}}}

let s:kind.action_table.splitswitch = {
      \ 'description' : 'horizontal split open items'
      \   . ' or jump to existing window/tabpage',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.splitswitch.func(candidates) abort "{{{
  for candidate in a:candidates
    if s:switch(candidate)
      call unite#take_action('split', candidate)
    endif
  endfor
endfunction"}}}

let s:kind.action_table.vsplitswitch = {
      \ 'description' : 'vertical split open items'
      \   . ' or jump to existing window/tabpage',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.vsplitswitch.func(candidates) abort "{{{
  for candidate in a:candidates
    if s:switch(candidate)
      call unite#take_action('vsplit', candidate)
    endif
  endfor
endfunction"}}}

"}}}

function! s:search_buffer(candidate) abort "{{{
  let bufnr = bufnr(a:candidate.action__path)
  for tabnr in range(1, tabpagenr('$'))
    if index(tabpagebuflist(tabnr), bufnr) >= 0
      return tabnr
    endif
  endfor

  return -1
endfunction"}}}

function! s:switch(candidate) abort "{{{
  let tabnr = s:search_buffer(a:candidate)
  if tabnr >= 0
    execute 'tabnext' tabnr
    execute bufwinnr(a:candidate.action__path) . 'wincmd w'
  endif

  call unite#take_action('open', a:candidate)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
