"=============================================================================
" FILE: bookmark.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 14 May 2011.
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
" The version of bookmark file format.
let s:VERSION = '0.1.0'

let s:bookmark_file_mtime = 0  " the last modified time of the bookmark file.

" [ [ name, full_path, linenr, search pattern ], ... ]
let s:bookmark_files = []

call unite#util#set_default('g:unite_source_bookmark_file',  g:unite_data_directory . '/.bookmark')
"}}}

function! unite#sources#bookmark#define()"{{{
  return s:source
endfunction"}}}
function! unite#sources#bookmark#_append(filename)"{{{
  if a:filename == ''
    " Append the current buffer to the bookmark list.
    let l:path = expand('%:p')
    let l:linenr = line('.')
    let l:pattern = '^' . escape(getline('.'), '~"\.^*$[]') . '$'
  else
    let l:path = fnamemodify(a:filename, ':p')
    let l:linenr = ''
    let l:pattern = ''
  endif

  let l:filename = (a:filename == '' ? expand('%') : a:filename)
  if bufexists(l:filename)
    let l:filetype = getbufvar(l:path, '&filetype')

    " Detect vimfiler and vimshell.
    if l:filetype ==# 'vimfiler'
      let l:path = getbufvar(l:path, 'vimfiler').current_dir
    elseif l:filetype ==# 'vimshell'
      let l:path = getbufvar(l:path, 'vimshell').save_dir
    endif
  endif

  let l:path = unite#substitute_path_separator(l:path)
  if !s:is_exists_path(path)
    return
  endif

  redraw
  echo a:filename
  let l:name = input('Please input bookmark name : ')

  call s:load()
  call insert(s:bookmark_files, [l:name, l:path, l:linenr, l:pattern])
  call s:save()
endfunction"}}}

let s:source = {
      \ 'name' : 'bookmark',
      \ 'description' : 'candidates from bookmark list',
      \ 'action_table' : {},
      \}

function! s:source.gather_candidates(args, context)"{{{
  call s:load()
  return map(copy(s:bookmark_files), '{
        \ "abbr" : (v:val[0] != "" ? "[" . v:val[0] . "] " : "") .  
        \          (fnamemodify(v:val[1], ":~:.") != "" ? fnamemodify(v:val[1], ":~:.") : v:val[1]),
        \ "word" : v:val[1],
        \ "kind" : (isdirectory(v:val[1]) ? "directory" : "jump_list"),
        \ "source_bookmark_name" : v:val[0],
        \ "action__path" : v:val[1],
        \ "action__line" : v:val[2],
        \ "action__pattern" : v:val[3],
        \ "action__directory" : unite#path2directory(v:val[1]),
        \   }')
endfunction"}}}

" Actions"{{{
let s:action_table = {}

let s:action_table.delete = {
      \ 'description' : 'delete from bookmark list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:action_table.delete.func(candidates)"{{{
  for l:candidate in a:candidates
    call filter(s:bookmark_files, 'string(v:val) !=# ' .
        \ string(string([l:candidate.source_bookmark_name, l:candidate.action__path, l:candidate.action__line, l:candidate.action__pattern])))
  endfor

  call s:save()
endfunction"}}}

let s:source.action_table['*'] = s:action_table
unlet! s:action_table
"}}}

" Add custom action table."{{{
let s:file_bookmark_action = {
      \ 'description' : 'append files to bookmark list',
      \ }
function! s:file_bookmark_action.func(candidate)"{{{
  " Add to bookmark.
  call unite#sources#bookmark#_append(a:candidate.action__path)
endfunction"}}}

let s:buffer_bookmark_action = {
      \ 'description' : 'append buffers to bookmark list',
      \ }
function! s:buffer_bookmark_action.func(candidate)"{{{
  let l:filetype = getbufvar(a:candidate.action__buffer_nr, '&filetype')
  if l:filetype ==# 'vimfiler'
    let l:filename = getbufvar(a:candidate.action__buffer_nr, 'vimfiler').current_dir
  elseif l:filetype ==# 'vimshell'
    let l:filename = getbufvar(a:candidate.action__buffer_nr, 'vimshell').save_dir
  else
    let l:filename = a:candidate.action__path
  endif

  " Add to bookmark.
  call unite#sources#bookmark#_append(l:filename)
endfunction"}}}

call unite#custom_action('file', 'bookmark', s:file_bookmark_action)
call unite#custom_action('buffer', 'bookmark', s:buffer_bookmark_action)
unlet! s:file_bookmark_action
unlet! s:buffer_bookmark_action
"}}}

" Misc
function! s:save()  "{{{
  call writefile([s:VERSION] + map(copy(s:bookmark_files), 'join(v:val, "\t")'),
  \              g:unite_source_bookmark_file)
  let s:bookmark_file_mtime = getftime(g:unite_source_bookmark_file)
endfunction"}}}
function! s:load()  "{{{
  if filereadable(g:unite_source_bookmark_file)
  \  && s:bookmark_file_mtime != getftime(g:unite_source_bookmark_file)
    let [ver; s:bookmark_files] = readfile(g:unite_source_bookmark_file)
    if ver !=# s:VERSION
      echohl WarningMsg
      echomsg 'Sorry, the version of bookmark file is old.  Clears the bookmark list.'
      echohl None
      let s:bookmark_files = []
      return
    endif
    let s:bookmark_files =
    \   filter(map(s:bookmark_files,
    \              'split(v:val, "\t", 1)'), 's:is_exists_path(v:val[1])')
    let s:bookmark_file_mtime = getftime(g:unite_source_bookmark_file)
  endif
endfunction"}}}
function! s:is_exists_path(path)  "{{{
  return isdirectory(a:path) || filereadable(a:path)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
