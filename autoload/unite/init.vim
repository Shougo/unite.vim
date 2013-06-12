"=============================================================================
" FILE: init.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 12 Jun 2013.
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

function! unite#init#_tab_variables() "{{{
  if !exists('t:unite')
    let t:unite = { 'last_unite_bufnr' : -1 }
  endif
endfunction"}}}

function! unite#init#_unite_buffer() "{{{
  let current_unite = unite#variables#current_unite()
  let is_bufexists = bufexists(current_unite.real_buffer_name)
  let current_unite.context.real_buffer_name =
        \ current_unite.real_buffer_name

  call unite#view#_switch_unite_buffer(
        \ current_unite.buffer_name, current_unite.context)

  let b:unite = current_unite
  let unite = unite#get_current_unite()

  let unite.bufnr = bufnr('%')

  " Note: If unite buffer initialize is incomplete, &modified or &modifiable.
  if !is_bufexists || &modified || &modifiable
    " Basic settings.
    setlocal bufhidden=hide
    setlocal buftype=nofile
    setlocal nolist
    setlocal nobuflisted
    setlocal noswapfile
    setlocal noreadonly
    setlocal nofoldenable
    setlocal nomodeline
    setlocal nonumber
    setlocal foldcolumn=0
    setlocal iskeyword+=-,+,\\,!,~
    setlocal matchpairs-=<:>
    setlocal completefunc=
    setlocal omnifunc=
    match
    if has('conceal')
      setlocal conceallevel=3
      setlocal concealcursor=n
    endif
    if exists('+cursorcolumn')
      setlocal nocursorcolumn
    endif
    if exists('+colorcolumn')
      setlocal colorcolumn=0
    endif

    " Autocommands.
    augroup plugin-unite
      autocmd InsertEnter <buffer>
            \ call unite#handlers#_on_insert_enter()
      autocmd InsertLeave <buffer>
            \ call unite#handlers#_on_insert_leave()
      autocmd CursorHoldI <buffer>
            \ call unite#handlers#_on_cursor_hold_i()
      autocmd CursorMovedI <buffer>
            \ call unite#handlers#_on_cursor_moved_i()
      autocmd CursorMoved,CursorMovedI <buffer>  nested
            \ call unite#handlers#_on_cursor_moved()
      autocmd BufUnload,BufHidden <buffer>
            \ call unite#handlers#_on_buf_unload(expand('<afile>'))
      autocmd WinEnter,BufWinEnter <buffer>
            \ call unite#handlers#_on_bufwin_enter(bufnr(expand('<abuf>')))
      autocmd WinLeave,BufWinLeave <buffer>
            \ call unite#handlers#_restore_updatetime()
    augroup END

    call unite#mappings#define_default_mappings()
  endif

  let &l:wrap = unite.context.wrap

  if exists('&redrawtime')
    " Save redrawtime
    let unite.redrawtime_save = &redrawtime
    let &redrawtime = 100
  endif

  call unite#handlers#_save_updatetime()

  " User's initialization.
  setlocal nomodifiable
  set sidescrolloff=0
  setlocal nocursorline
  setfiletype unite
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
