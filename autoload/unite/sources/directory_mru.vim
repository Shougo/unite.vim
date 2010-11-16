"=============================================================================
" FILE: directory_mru.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 16 Nov 2010
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
" The version of MRU file format.
let s:VERSION = '0.2.0'

" [[full_path, localtime()], ... ]
let s:mru_dirs = []

let s:mru_file_mtime = 0  " the last modified time of the mru file.

call unite#util#set_default('g:unite_source_directory_mru_time_format', '(%c)')
call unite#util#set_default('g:unite_source_directory_mru_file',  g:unite_data_directory . '/.directory_mru')
call unite#util#set_default('g:unite_source_directory_mru_limit', 100)
call unite#util#set_default('g:unite_source_directory_mru_ignore_pattern',
      \'\%(^\|/\)\.\%(hg\|git\|bzr\|svn\)\%($\|/\)\|^\%(\\\\\|/mnt/\|/media/\|/Volumes/\)')
"}}}

function! unite#sources#directory_mru#define()"{{{
  return s:source
endfunction"}}}
function! unite#sources#directory_mru#_append()"{{{
  let l:filetype = getbufvar(bufnr('%'), '&filetype')
  if l:filetype ==# 'vimfiler'
    let l:path = getbufvar(bufnr('%'), 'vimfiler').current_dir
  elseif l:filetype ==# 'vimshell'
    let l:path = getbufvar(bufnr('%'), 'vimshell').save_dir
  else
    let l:path = getcwd()
  endif

  let l:path = unite#util#substitute_path_separator(simplify(l:path))
  if l:path !~ '^\%(\a\+:\)\?/$'
    " Chomp last /.
    let l:path = l:path[: -2]
  endif

  " Append the current buffer to the mru list.
  if !isdirectory(path) || &l:buftype =~ 'help'
  \   || (g:unite_source_directory_mru_ignore_pattern != ''
  \      && l:path =~# g:unite_source_directory_mru_ignore_pattern)
    return
  endif

  call s:load()
  call insert(filter(s:mru_dirs, 'v:val.action__path !=# l:path'),
  \           s:convert2dictionary([l:path, localtime()]))

  if g:unite_source_directory_mru_limit > 0
    unlet s:mru_dirs[g:unite_source_directory_mru_limit]
  endif

  call s:save()
endfunction"}}}

let s:source = {
      \ 'name' : 'directory_mru',
      \ 'max_candidates': 30,
      \ 'action_table': {},
      \}

function! s:source.gather_candidates(args, context)"{{{
  call s:load()

  for l:mru in s:mru_dirs
    let l:relative_path = unite#util#substitute_path_separator(fnamemodify(l:mru.action__path, ':~:.'))
    if l:relative_path == ''
      let l:relative_path = l:mru.action__path
    endif
    if l:relative_path !~ '/$'
      let l:relative_path .= '/'
    endif

    let l:mru.abbr = strftime(g:unite_source_directory_mru_time_format, l:mru.source__time)
          \ . l:relative_path
  endfor

  return s:mru_dirs
endfunction"}}}

" Actions"{{{
let s:action_table = {}

let s:action_table.delete = {
      \ 'description' : 'delete from directory_mru list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:action_table.delete.func(candidates)"{{{
  for l:candidate in a:candidates
    call filter(s:mru_dirs, 'v:val.action__path !=# l:candidate.action__path')
  endfor

  call s:save()
endfunction"}}}

let s:source.action_table.directory = s:action_table
"}}}

" Misc
function! s:save()  "{{{
  call writefile([s:VERSION] + map(copy(s:mru_dirs), 'join(s:convert2list(v:val), "\t")'),
  \              g:unite_source_directory_mru_file)
  let s:mru_file_mtime = getftime(g:unite_source_directory_mru_file)
endfunction"}}}
function! s:load()  "{{{
  if filereadable(g:unite_source_directory_mru_file)
  \  && s:mru_file_mtime != getftime(g:unite_source_directory_mru_file)
    let [ver; s:mru_dirs] = readfile(g:unite_source_directory_mru_file)

    if ver !=# s:VERSION
      call unite#util#print_error('Sorry, the version of MRU file is old.  Clears the MRU list.')
      let s:mru_dirs = []
      return
    endif

    let s:mru_dirs =
    \   map(s:mru_dirs[: g:unite_source_directory_mru_limit - 1],
    \              's:convert2dictionary(split(v:val, "\t"))')
    call filter(s:mru_dirs, 'isdirectory(v:val.action__path)')

    let s:mru_file_mtime = getftime(g:unite_source_directory_mru_file)
  endif
endfunction"}}}
function! s:convert2dictionary(list)  "{{{
  return {
        \ 'word' : unite#util#substitute_path_separator(a:list[0]),
        \ 'source' : 'directory_mru',
        \ 'kind' : 'directory',
        \ 'source__time' : a:list[1],
        \ 'action__path' : unite#util#substitute_path_separator(a:list[0]),
        \ 'action__directory' : unite#util#substitute_path_separator(a:list[0]),
        \   }
endfunction"}}}
function! s:convert2list(dict)  "{{{
  return [ a:dict.action__path, a:dict.source__time ]
endfunction"}}}

" vim: foldmethod=marker
