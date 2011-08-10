"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 10 Aug 2011.
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

function! unite#kinds#file#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'file',
      \ 'default_action' : 'open',
      \ 'action_table' : {},
      \ 'parents' : ['openable', 'cdable', 'uri'],
      \}

" Actions"{{{
let s:kind.action_table.open = {
      \ 'description' : 'open files',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.open.func(candidates)"{{{
  for l:candidate in a:candidates
    call s:execute_command('edit', l:candidate)
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview file',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate)"{{{
  if filereadable(a:candidate.action__path)
    call s:execute_command('pedit', a:candidate)
  endif
endfunction"}}}

let s:kind.action_table.mkdir = {
      \ 'description' : 'make this directory or parents directory',
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ }
function! s:kind.action_table.mkdir.func(candidate)"{{{
  if !filereadable(a:candidate.action__path)
    call mkdir(iconv(a:candidate.action__path, &encoding, &termencoding), 'p')
  endif
endfunction"}}}

let s:kind.action_table.rename = {
      \ 'description' : 'rename files',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.rename.func(candidates)"{{{
  for l:candidate in a:candidates
    let l:filename = input(printf('New buffer name: %s -> ', l:candidate.action__path), l:candidate.action__path)
    if l:filename != '' && l:filename !=# l:candidate.action__path
      call rename(l:candidate.action__path, l:filename)
    endif
  endfor
endfunction"}}}
"}}}

function! s:execute_command(command, candidate)"{{{
  let l:dir = unite#util#path2directory(a:candidate.action__path)
  " Auto make directory.
  if !isdirectory(l:dir) &&
        \ input(printf('"%s" does not exist. Create? [y/N]', l:dir)) =~? '^y\%[es]$'
    call mkdir(iconv(l:dir, &encoding, &termencoding), 'p')
  endif

  silent call unite#util#smart_execute_command(a:command, a:candidate.action__path)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
