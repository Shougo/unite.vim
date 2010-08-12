"=============================================================================
" FILE: buffer.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 07 Aug 2010
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

" Variables  "{{{
let s:buffer_list = {}
"}}}

let s:source = {
      \ 'name' : 'buffer',
      \ 'key_table': {
      \     'd': 'delete',
      \     'u': 'unload',
      \     'w': 'wipeout',
      \     'default' : 'open'
      \    },
      \ 'action_table': {},
      \}

function! s:source.gather_candidates(args)"{{{
  call filter(s:buffer_list, 'bufexists(v:val.bufnr) && buflisted(v:val.bufnr) && v:val.bufnr != ' . bufnr('#'))
  let l:candidates = map(values(s:buffer_list), '{
        \ "word" : bufname(v:val.bufnr),
        \ "abbr" : s:make_abbr(v:val.bufnr),
        \ "source" : "buffer",
        \ "unite_buffer_nr" : v:val.bufnr,
        \ "time" : v:val.time,
        \}')

  return sort(l:candidates, 's:compare')
endfunction"}}}

function! s:source.action_table.delete(candidate)"{{{
  call unite#invalidate_cache('buffer')
  return s:delete('bdelete', a:candidate)
endfunction"}}}
function! s:source.action_table.open(candidate)"{{{
  return s:open('', a:candidate)
endfunction"}}}
function! s:source.action_table.open_x(candidate)"{{{
  return s:open('!', a:candidate)
endfunction"}}}
function! s:source.action_table.unload(candidate)"{{{
  return s:delete('bunload', a:candidate)
endfunction"}}}
function! s:source.action_table.wipeout(candidate)"{{{
  return s:delete('bwipeout', a:candidate)
endfunction"}}}

function! unite#sources#buffer#define()"{{{
  return s:source
endfunction"}}}
function! unite#sources#buffer#_append()"{{{
  " Append the current buffer.
  let s:buffer_list[bufnr('%')] = {
        \ 'bufnr' : bufnr('%'), 'time' : localtime()
        \ }
endfunction"}}}

" Misc
function! s:bufnr_from_candidate(candidate)"{{{
  if has_key(a:candidate, 'unite_buffer_nr')
    return a:candidate.unite_buffer_nr
  else
    let _ = bufnr(fnameescape(a:candidate.word))
    if 1 <= _
      return _
    else
      return ('There is no corresponding buffer to candidate: '
      \       . string(a:candidate.word))
    endif
  endif
endfunction"}}}
function! s:make_abbr(bufnr)"{{{
  let l:filetype = getbufvar(a:bufnr, '&filetype')
  if l:filetype ==# 'vimfiler'
    let l:bufvar = getbufvar(a:bufnr, 'vimfiler')
    return '*vimfiler* - ' . l:bufvar.current_dir
  elseif l:filetype ==# 'vimshell'
    let l:bufvar = getbufvar(a:bufnr, 'vimshell')
    return '*vimshell* - ' . l:bufvar.save_dir
  else
    return bufname(a:bufnr)
  endif
endfunction"}}}
function! s:delete(delete_command, candidate)"{{{
  let v:errmsg = ''

  let _ = s:bufnr_from_candidate(a:candidate)
  if type(_) == type(0)
    execute s:bufnr_from_candidate(a:candidate) a:delete_command
  else
    let v:errmsg = _
  endif

  return v:errmsg == '' ? 0 : v:errmsg
endfunction"}}}
function! s:open(bang, candidate)"{{{
  let v:errmsg = ''

  let _ = s:bufnr_from_candidate(a:candidate)
  if type(_) == type(0)
    call unite#leave_buffer()
    execute s:bufnr_from_candidate(a:candidate) 'buffer'.a:bang
  else
    let v:errmsg = _
  endif

  return v:errmsg == '' ? 0 : v:errmsg
endfunction"}}}
function! s:compare(candidate_a, candidate_b)"{{{
  return a:candidate_b.time - a:candidate_a.time
endfunction"}}}

" vim: foldmethod=marker
