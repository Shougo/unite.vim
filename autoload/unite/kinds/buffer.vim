"=============================================================================
" FILE: buffer.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 12 Oct 2010
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

function! unite#kinds#buffer#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'buffer',
      \ 'default_action' : 'open',
      \ 'action_table': {},
      \}

" Actions"{{{
let s:kind.action_table = deepcopy(unite#kinds#openable#define().action_table)

let s:kind.action_table.open = {
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.open.func(candidates)"{{{
  for l:candidate in a:candidates
    call s:open('', l:candidate)
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate)"{{{
  pedit `=a:candidate.word`
endfunction"}}}

let s:kind.action_table.delete = {
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.delete.func(candidates)"{{{
  for l:candidate in a:candidates
    call s:delete('bdelete', l:candidate)
  endfor
endfunction"}}}

let s:kind.action_table.fopen = {
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.fopen.func(candidates)"{{{
  for l:candidate in a:candidates
    call s:open('!', l:candidate)
  endfor
endfunction"}}}

let s:kind.action_table.fdelete = {
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.fdelete.func(candidates)"{{{
  for l:candidate in a:candidates
    call s:delete('bdelete!', l:candidate)
  endfor
endfunction"}}}

let s:kind.action_table.narrow = {
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.narrow.func(candidate)"{{{
  let l:word = s:get_directory(a:candidate)
  if l:word !~ '[\\/]$'
    let l:word .= '/'
  endif

  call unite#mappings#narrowing(l:word)
endfunction"}}}

let s:kind.action_table.cd = {
      \ }
function! s:kind.action_table.cd.func(candidate)"{{{
  let l:dir = s:get_directory(a:candidate)

  if &filetype ==# 'vimfiler'
    call vimfiler#internal_commands#cd(l:dir)
  elseif &filetype ==# 'vimshell'
    call vimshell#switch_shell(0, l:dir)
  endif

  execute g:unite_cd_command '`=l:dir`'
endfunction"}}}

let s:kind.action_table.lcd = {
      \ }
function! s:kind.action_table.lcd.func(candidate)"{{{
  let l:dir = s:get_directory(a:candidate)

  if &filetype ==# 'vimfiler'
    call vimfiler#internal_commands#cd(l:dir)
  elseif &filetype ==# 'vimshell'
    call vimshell#switch_shell(0, l:dir)
  endif

  execute g:unite_lcd_command '`=l:dir`'
endfunction"}}}

let s:kind.action_table.bookmark = {
      \ }
function! s:kind.action_table.bookmark.func(candidate)"{{{
  let l:filetype = getbufvar(a:candidate.unite_buffer_nr, '&filetype')
  if l:filetype ==# 'vimfiler'
    let l:filename = getbufvar(a:candidate.unite_buffer_nr, 'vimfiler').current_dir
  elseif l:filetype ==# 'vimshell'
    let l:filename = getbufvar(a:candidate.unite_buffer_nr, 'vimshell').save_dir
  else
    let l:filename = a:candidate.word
  endif

  " Add to bookmark.
  call unite#sources#bookmark#_append(l:filename)
endfunction"}}}

if exists(':VimShell')
  let s:kind.action_table.vimshell = {
        \ }
  function! s:kind.action_table.vimshell.func(candidate)"{{{
    let l:dir = s:get_directory(a:candidate)
    VimShellCreate `=l:dir`
  endfunction"}}}
endif
"}}}

" Misc
function! s:bufnr_from_candidate(candidate)"{{{
  if has_key(a:candidate, 'unite_buffer_nr')
    return a:candidate.unite_buffer_nr
  else
    let _ = bufnr(fnameescape(a:candidate.word))
    if 1 <= _
      return _
    else
      return ('There is no corresponding buffer to candidate: '
      \       . string(a:candidate.word))
    endif
  endif
endfunction"}}}
function! s:delete(delete_command, candidate)"{{{
  let _ = s:bufnr_from_candidate(a:candidate)
  if type(_) == type(0)
    execute s:bufnr_from_candidate(a:candidate) a:delete_command
  else
    let v:errmsg = _
  endif
endfunction"}}}
function! s:open(bang, candidate)"{{{
  let _ = s:bufnr_from_candidate(a:candidate)
  if type(_) == type(0)
    execute s:bufnr_from_candidate(a:candidate) 'buffer'.a:bang
  else
    let v:errmsg = _
  endif
endfunction"}}}
function! s:get_directory(candidate)"{{{
  let l:filetype = getbufvar(a:candidate.unite_buffer_nr, '&filetype')
  if l:filetype ==# 'vimfiler'
    let l:dir = getbufvar(a:candidate.unite_buffer_nr, 'vimfiler').current_dir
  elseif l:filetype ==# 'vimshell'
    let l:dir = getbufvar(a:candidate.unite_buffer_nr, 'vimshell').save_dir
  else
    let l:dir = isdirectory(a:candidate.word) ? a:candidate.word : fnamemodify(a:candidate.word, ':p:h')
  endif
  
  return l:dir
endfunction"}}}

" vim: foldmethod=marker
