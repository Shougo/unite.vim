"=============================================================================
" FILE: file_mru.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 26 Mar 2012.
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
" The version of MRU file format.
let s:VERSION = '0.2.0'

" [[full_path, localtime()], ... ]
let s:mru_files = []

let s:mru_file_mtime = 0  " the last modified time of the mru file.

call unite#util#set_default('g:unite_source_file_mru_time_format',
      \ '(%Y/%m/%d %H:%M:%S) ')
call unite#util#set_default('g:unite_source_file_mru_filename_format',
      \ ':~:.')
call unite#util#set_default('g:unite_source_file_mru_file',
      \ g:unite_data_directory . '/file_mru')
call unite#util#set_default('g:unite_source_file_mru_limit',
      \ 100)
call unite#util#set_default('g:unite_source_file_mru_ignore_pattern',
      \'\~$\|\.\%(o\|exe\|dll\|bak\|sw[po]\)$'
      \'\|\%(^\|/\)\.\%(hg\|git\|bzr\|svn\)\%($\|/\)'
      \'\|^\%(\\\\\|/mnt/\|/media/\|/temp/\|/tmp/\|/private/var/folders/\)')
"}}}

function! unite#sources#file_mru#define()"{{{
  return s:source
endfunction"}}}
function! unite#sources#file_mru#_append()"{{{
  let path = unite#util#substitute_path_separator(expand('%:p'))
  if path !~ '\a\+:'
    let path = unite#util#substitute_path_separator(
          \ simplify(resolve(path)))
  endif

  " Append the current buffer to the mru list.
  if !s:is_exists_path(path) || &buftype =~ 'help'
  \   || (g:unite_source_file_mru_ignore_pattern != ''
  \      && path =~# g:unite_source_file_mru_ignore_pattern)
    return
  endif

  call s:load()

  let save_ignorecase = &ignorecase
  let &ignorecase = unite#util#is_windows()

  call insert(filter(s:mru_files, 'v:val.action__path !=# path'),
  \           s:convert2dictionary([path, localtime()]))

  let &ignorecase = save_ignorecase

  if g:unite_source_file_mru_limit > len(s:mru_files)
    let s:mru_files = s:mru_files[ : g:unite_source_file_mru_limit - 1]
  endif

  call s:save()
endfunction"}}}

let s:source = {
      \ 'name' : 'file_mru',
      \ 'description' : 'candidates from file MRU list',
      \ 'max_candidates' : 30,
      \ 'hooks' : {},
      \ 'action_table' : {},
      \ 'syntax' : 'uniteSource__FileMru',
      \}

function! s:source.hooks.on_syntax(args, context)"{{{
  syntax match uniteSource__FileMru_Time
        \ /\s\+\zs([^)]*)/
        \ contained containedin=uniteSource__FileMru
  highlight default link uniteSource__FileMru_Time Statement
endfunction"}}}
function! s:source.hooks.on_post_filter(args, context)"{{{
  for mru in filter(copy(a:context.candidates), "!has_key(v:val, 'abbr')")
    let path = (g:unite_source_file_mru_filename_format == '') ?
          \ mru.action__path :
          \ unite#util#substitute_path_separator(
          \     fnamemodify(mru.action__path, g:unite_source_file_mru_filename_format))
    if path == ''
      let path = mru.action__path
    endif

    " Set default abbr.
    let mru.abbr = (g:unite_source_file_mru_time_format == '' ? '' :
          \ strftime(g:unite_source_file_mru_time_format, mru.source__time)) .path
  endfor
endfunction"}}}

function! s:source.gather_candidates(args, context)"{{{
  call s:load()

  return s:mru_files
endfunction"}}}

" Actions"{{{
let s:source.action_table.delete = {
      \ 'description' : 'delete from file_mru list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.delete.func(candidates)"{{{
  for candidate in a:candidates
    call filter(s:mru_files, 'v:val.action__path !=# candidate.action__path')
  endfor

  call s:save()
endfunction"}}}
"}}}

" Misc
function! s:save()  "{{{
  call writefile([s:VERSION] + map(copy(s:mru_files), 'join(s:convert2list(v:val), "\t")'),
  \              g:unite_source_file_mru_file)
  let s:mru_file_mtime = getftime(g:unite_source_file_mru_file)
endfunction"}}}
function! s:load()  "{{{
  if !filereadable(g:unite_source_file_mru_file)
  \  || s:mru_file_mtime == getftime(g:unite_source_file_mru_file)
    return
  endif

  let [ver; s:mru_files] = readfile(g:unite_source_file_mru_file)

  if ver !=# s:VERSION
    call unite#util#print_error('Sorry, the version of MRU file is old.  Clears the MRU list.')
    let s:mru_files = []
    return
  endif

  try
    let s:mru_files = map(s:mru_files[: g:unite_source_file_mru_limit - 1],
          \              's:convert2dictionary(split(v:val, "\t"))')
  catch
    call unite#util#print_error('Sorry, MRU file is invalid.  Clears the MRU list.')
    let s:mru_files = []
    return
  endtry

  let s:mru_files = filter(s:mru_files, 's:is_exists_path(v:val.action__path)')

  let s:mru_file_mtime = getftime(g:unite_source_file_mru_file)
endfunction"}}}
function! s:is_exists_path(path)  "{{{
  return a:path =~ '^\a\w\+:' ||
        \ (getftype(a:path) != '' && !isdirectory(a:path))
endfunction"}}}
function! s:convert2dictionary(list)  "{{{
  return {
        \ 'word' : a:list[0],
        \ 'kind' : (isdirectory(a:list[0]) ? 'directory' : 'file'),
        \ 'source__time' : a:list[1],
        \ 'action__path' : a:list[0],
        \ 'action__directory' : unite#util#path2directory(a:list[0]),
        \   }
endfunction"}}}
function! s:convert2list(dict)  "{{{
  return [ a:dict.action__path, a:dict.source__time ]
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
