"=============================================================================
" FILE: buffer.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 31 Oct 2010
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
      \ 'parents': ['file'],
      \}

" Actions"{{{
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
function! s:delete(delete_command, candidate)"{{{
  execute a:candidate.action__buffer_nr a:delete_command
endfunction"}}}
function! s:get_directory(candidate)"{{{
  let l:filetype = getbufvar(a:candidate.action__buffer_nr, '&filetype')
  if l:filetype ==# 'vimfiler'
    let l:dir = getbufvar(a:candidate.action__buffer_nr, 'vimfiler').current_dir
  elseif l:filetype ==# 'vimshell'
    let l:dir = getbufvar(a:candidate.action__buffer_nr, 'vimshell').save_dir
  else
    let l:dir = isdirectory(a:candidate.action__path) ? a:candidate.action__path : unite#substitute_path_separator(fnamemodify(a:candidate.action__path, ':p:h'))
  endif

  return l:dir
endfunction"}}}

" vim: foldmethod=marker
