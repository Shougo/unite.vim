"=============================================================================
" FILE: buffer.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 31 Jul 2011.
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

function! unite#kinds#buffer#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'buffer',
      \ 'default_action' : 'open',
      \ 'action_table': {},
      \ 'parents': ['file'],
      \}

" Actions"{{{
let s:kind.action_table.open = {
      \ 'description' : 'open buffer',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.open.func(candidates)"{{{
  for l:candidate in a:candidates
    execute 'buffer' l:candidate.action__buffer_nr
  endfor
endfunction"}}}

let s:kind.action_table.delete = {
      \ 'description' : 'delete from buffer list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.delete.func(candidates)"{{{
  for l:candidate in a:candidates
    call s:delete('bdelete', l:candidate)
  endfor
endfunction"}}}

let s:kind.action_table.fdelete = {
      \ 'description' : 'force delete from buffer list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.fdelete.func(candidates)"{{{
  for l:candidate in a:candidates
    call s:delete('bdelete!', l:candidate)
  endfor
endfunction"}}}

let s:kind.action_table.wipeout = {
      \ 'description' : 'wipeout from buffer list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.wipeout.func(candidates)"{{{
  for l:candidate in a:candidates
    call s:delete('bwipeout', l:candidate)
  endfor
endfunction"}}}

let s:kind.action_table.unload = {
      \ 'description' : 'unload from buffer list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.unload.func(candidates)"{{{
  for l:candidate in a:candidates
    call s:delete('unload', l:candidate)
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview buffer',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate)"{{{
  pedit `=a:candidate.action__path`

  let l:filetype = getbufvar(a:candidate.action__buffer_nr, '&filetype')
  if l:filetype != ''
    let l:winnr = winnr()
    execute bufwinnr(a:candidate.action__buffer_nr) . 'wincmd w'
    execute 'setfiletype' l:filetype
    execute l:winnr . 'wincmd w'
  endif
endfunction"}}}

let s:kind.action_table.rename = {
      \ 'description' : 'rename buffers',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.rename.func(candidates)"{{{
  for l:candidate in a:candidates
    let l:old_buffer_name = bufname(l:candidate.action__buffer_nr)
    let l:buffer_name = input(printf('New buffer name: %s -> ', l:old_buffer_name), l:old_buffer_name)
    if l:buffer_name != '' && l:buffer_name !=# l:old_buffer_name
      let l:bufnr = bufnr('%')
      execute 'buffer' l:candidate.action__buffer_nr
      saveas! `=l:buffer_name`
      call delete(l:candidate.action__path)
      execute 'buffer' l:bufnr
    endif
  endfor
endfunction"}}}
"}}}

" Misc
function! s:delete(delete_command, candidate)"{{{
  " Not to close window, move to alternate buffer.
  let l:winnr = 1
  while l:winnr <= winnr('$')
    if winbufnr(l:winnr) == a:candidate.action__buffer_nr
      execute l:winnr . 'wincmd w'
      call s:alternate_buffer()
      wincmd p
    endif

    let l:winnr += 1
  endwhile

  execute a:candidate.action__buffer_nr a:delete_command
endfunction"}}}
function! s:alternate_buffer()"{{{
  if bufnr('%') != bufnr('#') && buflisted(bufnr('#'))
    buffer #
  else
    let l:cnt = 0
    let l:pos = 1
    let l:current = 0
    while l:pos <= bufnr('$')
      if buflisted(l:pos)
        if l:pos == bufnr('%')
          let l:current = l:cnt
        endif

        let l:cnt += 1
      endif

      let l:pos += 1
    endwhile

    if l:current > l:cnt / 2
      bprevious
    else
      bnext
    endif
  endif
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
