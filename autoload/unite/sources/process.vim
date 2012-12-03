"=============================================================================
" FILE: process.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 19 Nov 2012.
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

  " In Windows, use tasklist.
  let command = unite#util#is_windows() ? 'tasklist' : 'ps aux'

  let result = split(vimproc#system(command), '\n')
  if empty(result)
    return []
  endif

  if unite#util#is_windows()
    let [message_linenr, start_result, min_len] = [1, 3, 5]
  else
    let [message_linenr, start_result, min_len] = [0, 1, 2]
  endif

  call unite#print_source_message(result[message_linenr], s:source.name)
  for line in result[start_result :]
    let process = split(line)
    if len(process) < min_len
      " Invalid output.
      continue
    endif

    call add(_, {
          \ 'word' : (unite#util#is_windows() ?
          \           process[0] : join(process[10:])),
          \ 'abbr' : (unite#util#is_windows() ? '' : '      ') . line,
          \ 'action__pid' : process[1],
          \})
  endfor

  return _
endfunction"}}}

" Actions"{{{
let s:source.action_table.sigkill = {
      \ 'description' : 'send the KILL signal to processes',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.sigkill.func(candidates)"{{{
  call s:kill('KILL', a:candidates)
endfunction"}}}

let s:source.action_table.sigterm = {
      \ 'description' : 'send the TERM signal to processes',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.sigterm.func(candidates)"{{{
  call s:kill('TERM', a:candidates)
endfunction"}}}

let s:source.action_table.sigint = {
      \ 'description' : 'send the INT signal to processes',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.sigint.func(candidates)"{{{
  call s:kill('INT', a:candidates)
endfunction"}}}

let s:source.action_table.unite__new_candidate = {
      \ 'description' : 'create new process',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ }
function! s:source.action_table.unite__new_candidate.func(candidate)"{{{
  let cmdline = unite#util#input(
        \ 'Please input command args : ', '', 'shellcmd')

  if unite#util#is_windows()
    silent execute ':!start' cmdline
  else
    call system(cmdline . ' &')
  endif
endfunction"}}}

function! s:kill(signal, candidates)"{{{
  if !unite#util#input_yesno(
        \ 'Really send the ' . a:signal .' signal to the processes?')
    redraw
    echo 'Canceled.'
    return
  endif

  redraw

  for candidate in a:candidates
    call unite#util#system(unite#util#is_windows() ?
          \ printf('taskkill /PID %d', candidate.action__pid) :
          \  printf('kill -%s %d', a:signal, candidate.action__pid)
          \ )
    if unite#util#get_last_status()
      call unite#print_error(unite#util#get_last_errmsg())
    endif
  endfor
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
