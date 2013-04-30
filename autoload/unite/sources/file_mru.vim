"=============================================================================
" FILE: file_mru.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 12 Jan 2013.
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

let s:V = vital#of('unite.vim')
let s:L = s:V.import("Data.List")

" Variables  "{{{
" The version of MRU file format.
let s:VERSION = '0.2.0'

" [[full_path, localtime()], ... ]
let s:mru_candidates = []

" the last modified time of the mru file.
let s:mru_file_mtime = 0

let s:mru_long_file_loaded = 0
call unite#util#set_default(
      \ 'g:unite_source_mru_validate', 1)

call unite#util#set_default(
      \ 'g:unite_source_file_mru_time_format',
      \ '(%Y/%m/%d %H:%M:%S) ')
call unite#util#set_default(
      \ 'g:unite_source_file_mru_filename_format',
      \ ':~:.')
call unite#util#set_default(
      \ 'g:unite_source_file_mru_file',
      \ g:unite_data_directory . '/file_mru')
call unite#util#set_default(
      \ 'g:unite_source_file_mru_long_file',
      \ g:unite_data_directory . '/file_mru_long')
call unite#util#set_default(
      \ 'g:unite_source_file_mru_limit',
      \ 100)
call unite#util#set_default(
      \ 'g:unite_source_file_mru_long_limit',
      \ 1000)
call unite#util#set_default(
      \ 'g:unite_source_file_mru_ignore_pattern',
      \'\~$\|\.\%(o\|exe\|dll\|bak\|zwc\|pyc\|sw[po]\)$'
      \'\|\%(^\|/\)\.\%(hg\|git\|bzr\|svn\)\%($\|/\)'
      \'\|^\%(\\\\\|/mnt/\|/media/\|/temp/\|/tmp/\|\%(/private\)\=/var/folders/\)'
      \'\|\%(^\%(fugitive\)://\)'
      \)
"}}}

function! unite#sources#file_mru#define() "{{{
  return s:source
endfunction"}}}
function! unite#sources#file_mru#append() "{{{
  let path = unite#util#substitute_path_separator(expand('%:p'))
  if path !~ '\a\+:'
    let path = unite#util#substitute_path_separator(
          \ simplify(resolve(path)))
  endif

  " Append the current buffer to the mru list.
  if !s:is_exists_path(path) || &l:buftype =~# 'help\|nofile'
    return
  endif

  if empty(s:mru_candidates)
    call unite#sources#file_mru#load()
  endif

  let save_ignorecase = &ignorecase
  let &ignorecase = unite#util#is_windows()

  call insert(filter(s:mru_candidates, 'v:val.action__path !=# path'),
  \           s:convert2dictionary([path, localtime()]))

  let &ignorecase = save_ignorecase


endfunction"}}}

let s:source = {
      \ 'name' : 'file_mru',
      \ 'description' : 'candidates from file MRU list',
      \ 'hooks' : {},
      \ 'action_table' : {},
      \ 'syntax' : 'uniteSource__FileMru',
      \ 'default_kind' : 'file',
      \ 'ignore_pattern' : g:unite_source_file_mru_ignore_pattern,
      \}

function! s:source.hooks.on_syntax(args, context) "{{{
  syntax match uniteSource__FileMru_Time
        \ /([^)]*)\s\+/
        \ contained containedin=uniteSource__FileMru
  highlight default link uniteSource__FileMru_Time Statement
endfunction"}}}
function! s:source.hooks.on_post_filter(args, context) "{{{
  for mru in a:context.candidates
    let mru.action__directory =
          \ unite#util#path2directory(mru.action__path)
    let mru.kind =
          \ (isdirectory(mru.action__path) ? 'directory' : 'file')
  endfor
endfunction"}}}

function! s:source.gather_candidates(args, context) "{{{
  if empty(s:mru_candidates)
    call unite#sources#file_mru#load()
  endif

  if get(a:args, 0, '') =~# '\%(long\|all\|\*\|_\)'
      \ || a:context.is_redraw
    call unite#sources#file_mru#load()
    return s:mru_candidates
  else
    return s:mru_candidates[: g:unite_source_file_mru_limit - 1]
  endif

endfunction"}}}

" Actions "{{{
let s:source.action_table.delete = {
      \ 'description' : 'delete from file_mru list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.delete.func(candidates) "{{{
  for candidate in a:candidates
    call filter(s:mru_candidates, 'v:val.action__path !=# candidate.action__path')
  endfor

  call unite#sources#file_mru#save()
endfunction"}}}
"}}}

" Filters "{{{
function! s:source.source__converter(candidates, context) "{{{
  for mru in filter(copy(a:candidates),
        \ "!has_key(v:val, 'abbr')")
    let path = (g:unite_source_file_mru_filename_format == '') ?
          \ mru.action__path :
          \ unite#util#substitute_path_separator(
          \     fnamemodify(mru.action__path,
          \      g:unite_source_file_mru_filename_format))
    if path == ''
      let path = mru.action__path
    endif

    " Set default abbr.
    let mru.abbr = (g:unite_source_file_mru_time_format == '' ? '' :
          \ strftime(g:unite_source_file_mru_time_format, mru.source__time)) .path
  endfor

  return a:candidates
endfunction"}}}

let s:source.converters = [ s:source.source__converter ]
"}}}

" Misc
function! unite#sources#file_mru#save(...)  "{{{
  let event = a:0 >= 1 ? a:1 : ''

  let opts = {}
  if a:0 >= 1 && s:V.is_dict(a:1)
    call extend(opts, a:1)
  endif

  if empty(s:mru_candidates)
    " nothing to save, file_mru is not loaded
    return
  endif

  if s:mru_long_file_loaded == 0
    call unite#sources#file_mru#load()
  endif

  let mru_file = g:unite_source_file_mru_file 
  " In case other vim instance updated the mru_file
  if s:mru_file_mtime < getftime(mru_file)
    let [ver; items] = readfile(mru_file)
    if s:version_check(ver)
      let merge_candidates = s:convert2candidates(items)
      let new_candidates = filter(
          \ merge_candidates, 'str2nr(v:val.source__time) > s:mru_file_mtime')
      call extend(new_candidates, s:mru_candidates)
      let s:mru_candidates = s:uniq_sort(s:mru_candidates)
      let s:mru_file_mtime = getftime(mru_file)
    endif
  endif
  
  if get(opts, 'event') == 'VimLeavePre'
      \ && g:unite_source_mru_validate
    call s:validate(s:mru_candidates)
  endif

  call writefile([s:VERSION] + map(copy(
      \ s:mru_candidates[: g:unite_source_file_mru_limit - 1]),
      \ 'join(s:convert2list(v:val), "\t")'),
      \ g:unite_source_file_mru_file)

  if len(s:mru_candidates) > g:unite_source_file_mru_limit
    call writefile([s:VERSION] + map(copy(
        \ s:mru_candidates[g:unite_source_file_mru_limit : g:unite_source_file_mru_long_limit - 1]), 
        \ 'join(s:convert2list(v:val), "\t")'),
        \ g:unite_source_file_mru_long_file)
    let s:mru_file_mtime = getftime(g:unite_source_file_mru_long_file)
  else
    let s:mru_file_mtime = getftime(g:unite_source_file_mru_file)
  endif
endfunction"}}}
function! unite#sources#file_mru#load()  "{{{
  if s:mru_long_file_loaded == 1
    return
  endif

  " Load Order:
  " 1. (load)  short list
  " 2. (merge) long list on_redraw
  if empty(s:mru_candidates)
    let mru_file = g:unite_source_file_mru_file
  else
    let mru_file = g:unite_source_file_mru_long_file
  endif

  if !filereadable(mru_file)
    return
  endif

  call s:load(mru_file)
endfunction"}}}
function! s:is_exists_path(path)  "{{{
  return a:path !~ '^\a\w\+:' &&
        \ getftype(a:path) ==# 'file' && !isdirectory(a:path)
endfunction"}}}
function! s:load(mru_file)  "{{{
  let [ver; items] = readfile(a:mru_file)
  if ! s:version_check(ver)
    return
  endif

  " Assume properly saved and sorted
  call extend(s:mru_candidates, s:convert2candidates(items))

  " s:mru_file_mtime 
  " - set once when loading the short mru_file
  " - update when #save
  if a:mru_file == g:unite_source_file_mru_file
    let s:mru_file_mtime = getftime(a:mru_file)
  endif

  if a:mru_file == g:unite_source_file_mru_long_file
    let s:mru_long_file_loaded = 1
  endif
endfunction"}}}
function! s:convert2candidates(items)  "{{{
  try
    return map(a:items, 's:convert2dictionary(split(v:val, "\t"))')
  catch
    call unite#util#print_error('Sorry, MRU file is invalid.  Clears the MRU list.')
    let s:mru_candidates = []
    return
  endtry
endfunction"}}}
function! s:validate(items)  "{{{
  call filter(a:items, 's:is_exists_path(v:val.action__path)')
endfunction"}}}
function! s:uniq_sort(items)  "{{{
  function! s:compare(i1, i2)  "{{{
    return a:i2.source__time - a:i1.source__time
  endfunction"}}}
  call sort(a:items, function('s:compare'))
  return s:L.uniq(a:items, 'v:val.action__path')
endfunction"}}}
function! s:convert2dictionary(list)  "{{{
  return { 'word' : a:list[0], 'source__time' : str2nr(a:list[1]),
        \ 'action__path' : a:list[0], }
endfunction"}}}
function! s:convert2list(dict)  "{{{
  return [ a:dict.action__path, a:dict.source__time ]
endfunction"}}}
function! s:version_check(ver)  "{{{
  if str2float(a:ver) < s:VERSION
    call unite#util#print_error('Sorry, the version of MRU file is old.  Clears the MRU list.')
    let s:mru_candidates = []
    return 0
  else
    return 1
  endif
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
