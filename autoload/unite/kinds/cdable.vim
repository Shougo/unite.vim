"=============================================================================
" FILE: cdable.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 01 Nov 2010
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

function! unite#kinds#cdable#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'cdable',
      \ 'action_table': {},
      \}

" Actions"{{{
let s:kind.action_table.cd = {
      \ }
function! s:kind.action_table.cd.func(candidate)"{{{
  if &filetype ==# 'vimfiler'
    call vimfiler#internal_commands#cd(a:candidate.action__directory)
  elseif &filetype ==# 'vimshell'
    call vimshell#switch_shell(0, a:candidate.action__directory)
  endif

  execute g:unite_cd_command '`=a:candidate.action__directory`'
endfunction"}}}

let s:kind.action_table.lcd = {
      \ }
function! s:kind.action_table.lcd.func(candidate)"{{{
  if &filetype ==# 'vimfiler'
    call vimfiler#internal_commands#cd(a:candidate.action__directory)
  elseif &filetype ==# 'vimshell'
    call vimshell#switch_shell(0, a:candidate.action__directory)
  endif

  execute g:unite_lcd_command '`=a:candidate.action__directory`'
endfunction"}}}

let s:kind.action_table.narrow = {
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.narrow.func(candidate)"{{{
  let l:word = a:candidate.action__directory . (a:candidate.action__directory =~ '[\\/]$' ? '' : '/')
  call unite#mappings#narrowing(l:word)
endfunction"}}}

if exists(':VimShell')
  let s:kind.action_table.vimshell = {
        \ }
  function! s:kind.action_table.vimshell.func(candidate)"{{{
    VimShellCreate `=a:candidate.action__directory`
  endfunction"}}}
endif
if exists(':VimShellTab')
  let s:kind.action_table.tabvimshell = {
        \ }
  function! s:kind.action_table.tabvimshell.func(candidate)"{{{
    VimShellTab `=a:candidate.action__directory`
  endfunction"}}}
endif
"}}}

" vim: foldmethod=marker
