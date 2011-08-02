"=============================================================================
" FILE: file_mru.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 02 Aug 2011.
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

call unite#util#set_default('g:unite_source_file_mru_time_format', '(%c) ')
call unite#util#set_default('g:unite_source_file_mru_filename_format', ':~:.')
call unite#util#set_default('g:unite_source_file_mru_file',  g:unite_data_directory . '/.file_mru')
call unite#util#set_default('g:unite_source_file_mru_limit', 100)
call unite#util#set_default('g:unite_source_file_mru_ignore_pattern',
      \'\~$\|\.\%(o|exe|dll|bak|sw[po]\)$\|\%(^\|/\)\.\%(hg\|git\|bzr\|svn\)\%($\|/\)\|^\%(\\\\\|/mnt/\|/media/\|/Volumes/\)')
"}}}

function! unite#sources#file_mru#define()"{{{
  return s:source
endfunction"}}}
function! unite#sources#file_mru#_append()"{{{
  let l:path = unite#util#substitute_path_separator(
        \ simplify(resolve(expand('%:p'))))

  " Append the current buffer to the mru list.
  if !s:is_exists_path(path) || &l:buftype =~ 'help'
  \   || (g:unite_source_file_mru_ignore_pattern != ''
  \      && l:path =~# g:unite_source_file_mru_ignore_pattern)
    return
  endif

  call s:load()

  let l:save_ignorecase = &ignorecase
  let &ignorecase = unite#is_win()

  call insert(filter(s:mru_files, 'v:val.action__path != l:path'),
  \           s:convert2dictionary([l:path, localtime()]))

  let &ignorecase = l:save_ignorecase

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
  syntax match uniteSource__FileMru_Time /(.*)/ contained containedin=uniteSource__FileMru
  highlight default link uniteSource__FileMru_Time Statement
endfunction"}}}
function! s:source.hooks.on_post_filter(args, context)"{{{
  for l:mru in a:context.candidates
    let l:path = (g:unite_source_file_mru_filename_format == '') ?
          \ l:mru.action__path :
          \ unite#util#substitute_path_separator(
          \     fnamemodify(l:mru.action__path, g:unite_source_file_mru_filename_format))
    if l:path == ''
      let l:path = l:mru.action__path
    endif
    let l:mru.abbr = (g:unite_source_file_mru_time_format == '' ? '' :
          \ strftime(g:unite_source_file_mru_time_format, l:mru.source__time)) .l:path
  endfor
endfunction"}}}

function! s:source.gather_candidates(args, context)"{{{
  call s:load()

  return s:mru_files
endfunction"}}}

" Actions"{{{
let s:action_table = {}

let s:action_table.delete = {
      \ 'description' : 'delete from file_mru list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:action_table.delete.func(candidates)"{{{
  for l:candidate in a:candidates
    call filter(s:mru_files, 'v:val.action__path !=# l:candidate.action__path')
  endfor

  call s:save()
endfunction"}}}

let s:source.action_table['*'] = s:action_table
"}}}

" Misc
function! s:save()  "{{{
  call writefile([s:VERSION] + map(copy(s:mru_files), 'join(s:convert2list(v:val), "\t")'),
  \              g:unite_source_file_mru_file)
  let s:mru_file_mtime = getftime(g:unite_source_file_mru_file)
endfunction"}}}
function! s:load()  "{{{
  if filereadable(g:unite_source_file_mru_file)
  \  && s:mru_file_mtime != getftime(g:unite_source_file_mru_file)
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
  endif
endfunction"}}}
function! s:is_exists_path(path)  "{{{
  return getftype(a:path) != ''
endfunction"}}}
function! s:convert2dictionary(list)  "{{{
  let l:path = unite#util#substitute_path_separator(a:list[0])
  return {
        \ 'word' : l:path,
        \ 'kind' : (isdirectory(l:path) ? 'directory' : 'file'),
        \ 'source__time' : a:list[1],
        \ 'action__path' : l:path,
        \ 'action__directory' : unite#util#path2directory(l:path),
        \   }
endfunction"}}}
function! s:convert2list(dict)  "{{{
  return [ a:dict.action__path, a:dict.source__time ]
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
