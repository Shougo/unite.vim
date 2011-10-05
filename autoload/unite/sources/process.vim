"=============================================================================
" FILE: process.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 05 Oct 2011.
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

" Variables  "{{{
"}}}

function! unite#sources#process#define()"{{{
  return executable('ps') ? s:source : {}
endfunction"}}}

let s:source = {
      \ 'name' : 'process',
      \ 'description' : 'candidates from processes',
      \ 'default_action' : 'sigterm',
      \ 'action_table' : {},
      \ }

function! s:source.gather_candidates(args, context)"{{{
  " Get process list.
  let _ = []
  for line in split(unite#util#system('ps -A'), '\n')[1:]
    let process = split(line)
    if len(process) < 4
      " Invalid output.
      continue
    endif

    call add(_, {
          \ 'word' : process[3],
          \ 'abbr' : line,
          \ 'action__pid' : process[0],
          \})
  endfor

  return _
endfunction"}}}

" Actions"{{{
let s:source.action_table.sigkill = {
      \ 'description' : 'send KILL signal to processes',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.sigkill.func(candidates)"{{{
  for candidate in a:candidates
    call unite#util#system('kill -KILL ' . candidate.action__pid)
  endfor
endfunction"}}}

let s:source.action_table.sigterm = {
      \ 'description' : 'send TERM signal to processes',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.sigterm.func(candidates)"{{{
  for candidate in a:candidates
    call unite#util#system('kill -TERM ' . candidate.action__pid)
  endfor
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
