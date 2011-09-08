"=============================================================================
" FILE: register.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 Sep 2011.
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

function! unite#sources#register#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'register',
      \ 'description' : 'candidates from register',
      \ 'action_table' : {},
      \}

function! s:source.gather_candidates(args, context)"{{{
  let l:candidates = []

  let l:max_width = winwidth(0) - 5
  let l:registers = [
        \ '"',
        \ '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        \ 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
        \ 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
        \ 'u', 'v', 'w', 'x', 'y', 'z',
        \ '-', '*', '+', '.', ':', '#', '%', '/', '=',
        \ ]
  if exists('g:yanktmp_file') && filereadable(g:yanktmp_file)
    call add(l:registers, 'yanktmp')
  endif

  for l:reg in l:registers
    let l:register = (l:reg ==# 'yanktmp') ?
          \ join(readfile(g:yanktmp_file, "b"), "\n") :
          \ getreg(l:reg, 1)
    if l:register != ''
      let l:abbr = substitute(l:register[ : l:max_width], '\t', '>---', 'g')
      let l:abbr = substitute(l:abbr, '\r\?\n', '\\n', 'g')

      call add(l:candidates, {
            \ 'word' : l:register,
            \ 'abbr' : printf('%-7s - %s', l:reg, l:abbr),
            \ 'kind' : 'word',
            \ 'action__register' : l:reg,
            \ })
    endif
  endfor

  return l:candidates
endfunction"}}}

" Actions"{{{
let s:source.action_table.delete = {
      \ 'description' : 'delete registers',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.delete.func(candidates)"{{{
  for l:candidate in a:candidates
    if l:candidate.action__register ==# 'yanktmp'
      call delete(g:yanktmp_file)
    else
      silent! call setreg(l:candidate.action__register, '')
    endif
  endfor
endfunction"}}}

let s:source.action_table.edit = {
      \ 'description' : 'change register value',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ }
function! s:source.action_table.edit.func(candidate)"{{{
  let l:register = (a:candidate.action__register ==# 'yanktmp') ?
        \ join(readfile(g:yanktmp_file, "b"), "\n") :
        \ getreg(a:candidate.action__register, 1)
  let l:register = substitute(l:register, '\r\?\n', '\\n', 'g')
  let l:new_value = substitute(input('', l:register), '\\n', '\n', 'g')
  if a:candidate.action__register ==# 'yanktmp'
    call writefile(split(l:new_value, "\n", 1), g:yanktmp_file)
  else
    silent! call setreg(a:candidate.action__register, l:new_value)
  endif
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
