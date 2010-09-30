"=============================================================================
" FILE: file_mru.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 27 Sep 2010
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
let s:mru_files = []

let s:mru_file_mtime = 0  " the last modified time of the mru file.

call unite#set_default('g:unite_source_file_mru_time_format', '(%x %H:%M:%S)')
call unite#set_default('g:unite_source_file_mru_file',  g:unite_data_directory . '/.file_mru')
call unite#set_default('g:unite_source_file_mru_limit', 100)
call unite#set_default('g:unite_source_file_mru_ignore_pattern', 
      \'\~$\|\.\%(o|exe|dll|bak|sw[po]\)$\|\%(^\|[/\\]\)\.\%(hg\|git\|bzr\|svn\)\%($\|[/\\]\)\|^\%(\\\\\|/mnt/\|/media/\|/Volumes/\)')
"}}}

function! unite#sources#file_mru#define()"{{{
  return s:source
endfunction"}}}
function! unite#sources#file_mru#_append()"{{{
  " Append the current buffer to the mru list.
  let l:path = substitute(expand('%:p'), '\\', '/', 'g')
  if !s:is_exists_path(path) || &l:buftype =~ 'help'
  \   || (g:unite_source_file_mru_ignore_pattern != ''
  \      && l:path =~# g:unite_source_file_mru_ignore_pattern)
    return
  endif

  call s:load()
  call insert(filter(s:mru_files, 'v:val.word !=# path'),
  \           s:convert2dictionary([path, localtime()]))
  if 0 < g:unite_source_file_mru_limit
    unlet s:mru_files[g:unite_source_file_mru_limit]
  endif
  call s:save()
endfunction"}}}
function! unite#sources#file_mru#_sweep()  "{{{
  call filter(s:mru_files, 's:is_exists_path(v:val.word)')
  call s:save()
endfunction"}}}

let s:source = {
      \ 'name' : 'file_mru',
      \ 'max_candidates': 30,
      \ 'action_table': {},
      \}

function! s:source.gather_candidates(args)"{{{
  call s:load()
  
  " Create abbr.
  for l:mru in s:mru_files
    let l:mru.abbr = strftime(g:unite_source_file_mru_time_format, l:mru.unite_file_mru_time) .
          \          fnamemodify(l:mru.word, ':.')
    if l:mru.abbr == ''
      let l:mru.abbr = strftime(g:unite_source_file_mru_time_format, l:mru.unite_file_mru_time) . l:mru.word
    endif
  endfor
  
  return sort(s:mru_files, 's:compare')
endfunction"}}}

" Actions"{{{
let s:source.action_table.delete = {
      \ 'is_invalidate_cache' : 1, 
      \ 'is_quit' : 0, 
      \ 'is_selectable' : 1, 
      \ }
function! s:source.action_table.delete.func(candidate)"{{{
  call filter(s:mru_files, 'v:val.word !=# ' . string(a:candidate.word))
  call s:save()
endfunction"}}}
"}}}

" Misc
function! s:compare(candidate_a, candidate_b)"{{{
  return a:candidate_b['unite_file_mru_time'] - a:candidate_a['unite_file_mru_time']
endfunction"}}}
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
      echohl WarningMsg
      echomsg 'Sorry, the version of MRU file is old.  Clears the MRU list.'
      echohl None
      let s:mru_files = []
      return
    endif
    let s:mru_files =
    \   map(filter(map(s:mru_files[0 : g:unite_source_file_mru_limit - 1],
    \              'split(v:val, "\t")'), 's:is_exists_path(v:val[0])'),
    \              's:convert2dictionary(v:val)')
    let s:mru_file_mtime = getftime(g:unite_source_file_mru_file)
  endif
endfunction"}}}
function! s:is_exists_path(path)  "{{{
  return isdirectory(a:path) || filereadable(a:path)
endfunction"}}}
function! s:convert2dictionary(list)  "{{{
  return {
        \ 'word' : a:list[0],
        \ 'source' : 'file_mru',
        \ 'unite_file_mru_time' : a:list[1],
        \ 'kind' : (isdirectory(a:list[0]) ? 'directory' : "file"),
        \   }
endfunction"}}}
function! s:convert2list(dict)  "{{{
  return [ a:dict.word, a:dict.unite_file_mru_time ]
endfunction"}}}

" vim: foldmethod=marker
