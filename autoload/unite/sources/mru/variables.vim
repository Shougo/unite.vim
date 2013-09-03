"=============================================================================
" FILE: variables.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
" Last Modified: 30 Apr 2013
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

let s:is_windows = has('win16') || has('win32') || has('win64')

let s:mru_files = []
let s:mru_directories = []

function! unite#sources#mru#variables#append() "{{{
  if &l:buftype =~ 'help\|nofile'
    return
  endif

  let path = s:substitute_path_separator(expand('%:p'))
  if path !~ '\a\+:'
    let path = s:substitute_path_separator(
          \ simplify(resolve(path)))
  endif

  " Append the current buffer to the mru list.
  if s:is_file_exist(path)
    call insert(s:mru_files, s:convert2dictionary([path, localtime()]))
  endif

  let filetype = getbufvar(bufnr('%'), '&filetype')
  if filetype ==# 'vimfiler' &&
        \ type(getbufvar(bufnr('%'), 'vimfiler')) == type({})
    let path = getbufvar(bufnr('%'), 'vimfiler').current_dir
  elseif filetype ==# 'vimshell' &&
        \ type(getbufvar(bufnr('%'), 'vimshell')) == type({})
    let path = getbufvar(bufnr('%'), 'vimshell').current_dir
  else
    let path = getcwd()
  endif

  let path = s:substitute_path_separator(simplify(resolve(path)))
  " Chomp last /.
  let path = substitute(path, '/$', '', '')

  " Append the current buffer to the mru list.
  if isdirectory(path)
    call insert(s:mru_directories, s:convert2dictionary([path, localtime()]))
  endif
endfunction"}}}

function! unite#sources#mru#variables#get_mrus(type) "{{{
  return a:type ==# 'file' ? s:mru_files : s:mru_directories
endfunction"}}}

function! unite#sources#mru#variables#clear(type) "{{{
  if a:type ==# 'file'
    let s:mru_files = []
  else
    let s:mru_directories = []
  endif
endfunction"}}}

function! s:convert2candidates(items)  "{{{
  try
    return map(a:items, 's:convert2dictionary(split(v:val, "\t"))')
  catch
    call unite#util#print_error('Sorry, MRU file is invalid.')
    return []
  endtry
endfunction"}}}

function! s:convert2dictionary(list)  "{{{
  return { 'word' : a:list[0], 'source__time' : str2nr(a:list[1]),
        \ 'action__path' : a:list[0], }
endfunction"}}}

function! s:convert2list(dict)  "{{{
  return [ a:dict.action__path, a:dict.source__time ]
endfunction"}}}

function! s:is_file_exist(path)  "{{{
  return a:path !~ '^\a\w\+:' && getftype(a:path) ==# 'file'
endfunction"}}}

function! s:substitute_path_separator(path)
  return s:is_windows ? substitute(a:path, '\\', '/', 'g') : a:path
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
