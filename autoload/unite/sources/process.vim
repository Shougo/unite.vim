"=============================================================================
" FILE: process.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 03 May 2012.
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
  return executable('ps') || (unite#util#is_windows() && executable('tasklist')) ?
        \ s:source : {}
endfunction"}}}

let s:source = {
      \ 'name' : 'process',
      \ 'description' : 'candidates from processes',
      \ 'default_action' : 'sigterm',
      \ 'action_table' : {},
      \ 'alias_table' : { 'delete' : 'sigkill' },
      \ }

function! s:source.gather_candidates(args, context)"{{{
  " Get process list.
  let _ = []
  let command = unite#util#is_windows() ? 'tasklist' : 'ps aux'

  let result = split(vimproc#system(command), '\n')
  if empty(result)
    return []
  endif

  if unite#util#is_windows()
    " Use tasklist.
    call unite#print_source_message(result[1], s:source.name)
    for line in result[3:]
      let process = split(line)
      if len(process) < 5
        " Invalid output.
        continue
      endif

      call add(_, {
            \ 'word' : process[0],
            \ 'abbr' : line,
            \ 'action__pid' : process[1],
            \})
    endfor
  else
    call unite#print_source_message(result[0], s:source.name)
    for line in result[1:]
      let process = split(line)
      if len(process) < 2
        " Invalid output.
        continue
      endif

      call add(_, {
            \ 'word' : join(process[10:]),
            \ 'abbr' : '      ' . line,
            \ 'action__pid' : process[1],
            \})
    endfor
  endif

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
    call s:kill('-KILL', candidate.action__pid)
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
    call s:kill('-TERM', candidate.action__pid)
  endfor
endfunction"}}}

function! s:kill(signal, pid)
  call unite#util#system(unite#util#is_windows() ?
        \ printf('taskkill /PID %d', a:pid) :
        \  printf('kill %s %d', a:signal, a:pid)
        \ )
endfunction
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
