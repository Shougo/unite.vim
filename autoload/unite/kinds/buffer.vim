"=============================================================================
" FILE: buffer.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 Feb 2012.
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

function! unite#kinds#buffer#define() "{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'buffer',
      \ 'default_action' : 'open',
      \ 'action_table': {},
      \ 'parents': ['file'],
      \}

" Actions "{{{
let s:kind.action_table.open = {
      \ 'description' : 'open buffer',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.open.func(candidates) "{{{
  for candidate in a:candidates
    execute 'buffer' candidate.action__buffer_nr
  endfor
endfunction"}}}

let s:kind.action_table.goto = {
      \ 'description' : 'goto buffer tab',
      \ }
function! s:kind.action_table.goto.func(candidate) "{{{
  for i in range(tabpagenr('$'))
    let tabnr = i + 1
    for nr in tabpagebuflist(tabnr)
      if nr == a:candidate.action__buffer_nr
        execute 'tabnext' tabnr
        execute bufwinnr(nr) 'wincmd w'

        " Jump to the first.
        return
      endif
    endfor
  endfor
  execute 'buffer' a:candidate.action__buffer_nr
endfunction"}}}

let s:kind.action_table.delete = {
      \ 'description' : 'delete from buffer list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.delete.func(candidates) "{{{
  for candidate in a:candidates
    call s:delete('bdelete', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.fdelete = {
      \ 'description' : 'force delete from buffer list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.fdelete.func(candidates) "{{{
  for candidate in a:candidates
    call s:delete('bdelete!', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.wipeout = {
      \ 'description' : 'wipeout from buffer list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.wipeout.func(candidates) "{{{
  for candidate in a:candidates
    call s:delete('bwipeout', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.unload = {
      \ 'description' : 'unload from buffer list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.unload.func(candidates) "{{{
  for candidate in a:candidates
    call s:delete('unload', candidate)
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview buffer',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate) "{{{
  pedit `=a:candidate.action__path`

  let filetype = getbufvar(a:candidate.action__buffer_nr, '&filetype')
  if filetype != ''
    let winnr = winnr()
    execute bufwinnr(a:candidate.action__buffer_nr) . 'wincmd w'
    execute 'setfiletype' filetype
    execute winnr . 'wincmd w'
  endif
endfunction"}}}

let s:kind.action_table.rename = {
      \ 'description' : 'rename buffers',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.rename.func(candidates) "{{{
  for candidate in a:candidates
    if getbufvar(candidate.action__buffer_nr, '&buftype') =~ 'nofile'
      " Skip nofile buffer.
      continue
    endif

    let old_buffer_name = bufname(candidate.action__buffer_nr)
    let buffer_name = input(printf('New buffer name: %s -> ', old_buffer_name), old_buffer_name)
    if buffer_name == '' || buffer_name ==# old_buffer_name
      continue
    endif

    call unite#kinds#file#do_rename(old_buffer_name, buffer_name)
  endfor
endfunction"}}}
"}}}

" Misc
function! s:delete(delete_command, candidate) "{{{
  " Not to close window, move to alternate buffer.

  let winnr = 1
  while winnr <= winnr('$')
    if winbufnr(winnr) == a:candidate.action__buffer_nr
      execute winnr . 'wincmd w'
      call unite#util#alternate_buffer()

      let unite_winnr = bufwinnr(unite#get_current_unite().bufnr)
      if unite_winnr > 0
        execute unite_winnr 'wincmd w'
      endif
    endif

    let winnr += 1
  endwhile

  silent execute a:candidate.action__buffer_nr a:delete_command
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
