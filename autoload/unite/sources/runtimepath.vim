"=============================================================================
" FILE: runtimepath.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Mar 2013.
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

function! unite#sources#runtimepath#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'runtimepath',
      \ 'description' : 'candidates from Vim runtimepath',
      \ 'default_action' : 'lcd',
      \ 'default_kind' : 'directory',
      \ 'action_table' : {},
      \ }

function! s:source.gather_candidates(args, context) "{{{
  return map(map(s:split_rtp(), 'unite#util#expand(v:val)'), "{
        \ 'word' : unite#util#expand(v:val),
        \ 'abbr' : unite#util#substitute_path_separator(
        \         fnamemodify(unite#util#expand(v:val), ':~')),
        \ 'action__path' : unite#util#expand(v:val),
        \ 'action__directory' : unite#util#expand(v:val),
        \ 'source__runtimepath' : v:val,
        \ }")
endfunction"}}}

" Actions "{{{
let s:source.action_table.delete = {
      \ 'description' : 'delete from runtimepath',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.delete.func(candidates) "{{{
  for candidate in a:candidates
    execute 'set runtimepath-=' . fnameescape(candidate.action__path)
  endfor
endfunction"}}}
"}}}

function! s:split_rtp(...) "{{{
  let rtp = a:0 ? a:1 : &runtimepath
  if type(rtp) == type([])
    return rtp
  endif
  let split = split(rtp, '\\\@<!\%(\\\\\)*\zs,')
  return map(split,'substitute(v:val, ''\\\([\\,]\)'', "\\1", "g")')
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
