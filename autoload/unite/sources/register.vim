"=============================================================================
" FILE: register.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 03 Jun 2011.
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
      \}

function! s:source.gather_candidates(args, context)"{{{
  let l:candidates = []

  let l:max_width = winwidth(0) - 5
  let l:registers = [['"', @"],
        \ ['0', @0], ['1', @1], ['2', @2], ['3', @3], ['4', @4],
        \ ['5', @5], ['6', @6], ['7', @7], ['8', @8], ['9', @9],
        \ ['a', @a], ['b', @b], ['c', @c], ['d', @d], ['e', @e],
        \ ['f', @f], ['g', @g], ['h', @h], ['i', @i], ['j', @j],
        \ ['k', @k], ['l', @l], ['m', @m], ['n', @n], ['o', @o],
        \ ['p', @p], ['q', @q], ['r', @r], ['s', @s], ['t', @t],
        \ ['u', @u], ['v', @v], ['w', @w], ['x', @x], ['y', @y], ['z', @z],
        \ ['-', @-], ['*', @*], ['+', @+], ['.', @.], [':', @:],
        \ ['%', @%], ['#', @#], ['/', @/], ['=', @=],
        \ ]
  if exists('g:yanktmp_file') && filereadable(g:yanktmp_file)
    call add(l:registers, ['yanktmp', join(readfile(g:yanktmp_file, "b"), "\n")])
  endif

  for [l:reg, l:register] in l:registers
    if l:register != ''
      let l:abbr = substitute(l:register[ : l:max_width], '\t', '>---', 'g')
      let l:abbr = substitute(l:abbr, '\r\?\n', '\\n', 'g')

      call add(l:candidates, {
            \ 'word' : l:register,
            \ 'abbr' : printf('%-7s - %s', l:reg, l:abbr),
            \ 'kind' : 'word',
            \ })
    endif
  endfor

  return l:candidates
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
