"=============================================================================
" FILE: guicmd.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 18 Aug 2012.
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

function! unite#kinds#guicmd#define() "{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'guicmd',
      \ 'default_action' : 'execute',
      \ 'action_table': {},
      \ 'alias_table' : { 'ex' : 'nop' },
      \}

" Actions "{{{
let s:kind.action_table.execute = {
      \ 'description' : 'execute command',
      \ }
function! s:kind.action_table.execute.func(candidate) "{{{
  let args = [a:candidate.action__path]
  if has_key(a:candidate, 'action__args')
    let args += a:candidate.action__args
  endif

  if unite#util#is_windows()
    let args[0] = resolve(args[0])
  endif

  let cmdline = unite#util#is_windows() ?
        \ join(map(args, '"\"".v:val."\""')) :
        \ args[0] . ' ' . join(map(args[1:], "''''.v:val.''''"))

  if unite#util#is_windows()
    let cmdline = unite#util#iconv(cmdline, &encoding, 'char')
    silent execute ':!start' cmdline
  else
    call system(cmdline . ' &')
  endif
endfunction"}}}
let s:kind.action_table.edit = {
      \ 'description' : 'edit command args',
      \ }
function! s:kind.action_table.edit.func(candidate) "{{{
  let args = [a:candidate.action__path]
  if has_key(a:candidate, 'action__args')
    let args += a:candidate.action__args
  endif

  if unite#util#is_windows()
    let args[0] = resolve(args[0])
  endif

  let cmdline = unite#util#is_windows() ?
        \ join(map(args, '"\"".v:val."\""')) :
        \ args[0] . ' ' . join(map(args[1:], "''''.v:val.''''"))
  let cmdline = input('Edit command args :', cmdline, 'file')

  if unite#util#is_windows()
    silent execute ':!start' cmdline
  else
    call system(cmdline . ' &')
  endif
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
