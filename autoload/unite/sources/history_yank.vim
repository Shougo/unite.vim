"=============================================================================
" FILE: history_yank.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
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
let s:VERSION = '1.0'

let s:yank_histories = {}

" the last modified time of the yank histories file.
let s:yank_histories_file_mtime = 0

let s:prev_registers = {}

call unite#util#set_default('g:unite_source_history_yank_file',
      \ unite#get_data_directory() . '/history_yank')

call unite#util#set_default('g:unite_source_history_yank_limit', 100)

call unite#util#set_default(
      \ 'g:unite_source_history_yank_save_registers', ['"'])
"}}}

function! unite#sources#history_yank#define() "{{{
  return s:source
endfunction"}}}
function! unite#sources#history_yank#_append() "{{{
  let prev_histories = copy(s:yank_histories)

  for register in g:unite_source_history_yank_save_registers
    call s:add_register(register)
  endfor

  if prev_histories !=# s:yank_histories
    " Updated.
    call s:save()
  endif
endfunction"}}}

let s:source = {
      \ 'name' : 'history/yank',
      \ 'description' : 'candidates from yank history',
      \ 'action_table' : {},
      \ 'default_kind' : 'word',
      \}

function! s:source.gather_candidates(args, context) "{{{
  let registers = split(get(a:args, 0, '"'), '\zs')

  call s:load()

  let candidates = []
  for register in registers
    let candidates += map(copy(get(s:yank_histories, register, [])), "{
        \ 'word' : v:val[0],
        \ 'abbr' : printf('%-2d - %s', v:key, v:val[0]),
        \ 'is_multiline' : 1,
        \ 'action__regtype' : v:val[1],
        \ }")
  endfor

  return candidates
endfunction"}}}

" Actions "{{{
let s:source.action_table.delete = {
      \ 'description' : 'delete from yank history',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.delete.func(candidates) "{{{
  for candidate in a:candidates
    call filter(s:yank_histories, 'v:val[0] !=# candidate.word')
  endfor

  call s:save()
endfunction"}}}
"}}}

function! s:save()  "{{{
  if g:unite_source_history_yank_file == ''
        \ || unite#util#is_sudo()
    return
  endif

  call s:load()

  call writefile([s:VERSION, string(s:yank_histories)],
        \              g:unite_source_history_yank_file)
  let s:yank_histories_file_mtime = getftime(g:unite_source_history_yank_file)
endfunction"}}}
function! s:load()  "{{{
  if !filereadable(g:unite_source_history_yank_file)
  \  || s:yank_histories_file_mtime == getftime(g:unite_source_history_yank_file)
    return
  endif

  let file = readfile(g:unite_source_history_yank_file)

  " Version check.
  if empty(file) || len(file) != 2 || file[0] !=# s:VERSION
    return
  endif

  try
    sandbox let yank_histories = eval(file[1])
  catch
    unlet! yank_histories
    let yank_histories = {}
  endtry

  for register in g:unite_source_history_yank_save_registers
    if !has_key(s:yank_histories, register)
      let s:yank_histories[register] = []
    endif
    let s:yank_histories[register] += get(yank_histories, register, [])
    call s:uniq(register)
  endfor

  let s:yank_histories_file_mtime =
        \ getftime(g:unite_source_history_yank_file)
endfunction"}}}

function! s:add_register(name) "{{{
  let reg = [getreg(a:name), getregtype(a:name)]
  if get(s:yank_histories, 0, []) ==# reg
    " Skip same register value.
    return
  endif

  let len_history = len(reg[0])
  " Ignore too long yank.
  if len_history < 2 || len_history > 100000
        \ || reg[0] =~ '[\x00-\x09\x10-\x1a\x1c-\x1f]\{3,}'
    return
  endif

  let s:prev_registers[a:name] = reg

  " Append register value.
  if !has_key(s:yank_histories, a:name)
    let s:yank_histories[a:name] = []
  endif

  call insert(s:yank_histories[a:name], reg)
  call s:uniq(a:name)
endfunction"}}}

function! s:uniq(name) "{{{
  let history = unite#util#uniq(s:yank_histories[a:name])
  if g:unite_source_history_yank_limit < len(history)
    let history = history[ : g:unite_source_history_yank_limit - 1]
  endif
  let s:yank_histories[a:name] = history
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
