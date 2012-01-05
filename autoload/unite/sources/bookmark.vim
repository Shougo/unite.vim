"=============================================================================
" FILE: bookmark.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 05 Jan 2012.
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

let s:bookmarks = {}

call unite#util#set_default('g:unite_source_bookmark_directory',  g:unite_data_directory . '/bookmark')
"}}}

function! unite#sources#bookmark#define()"{{{
  return s:source
endfunction"}}}
function! unite#sources#bookmark#_append(filename)"{{{
  if !isdirectory(g:unite_source_bookmark_directory)
    call mkdir(g:unite_source_bookmark_directory, 'p')
  endif

  if a:filename == ''
    " Append the current buffer to the bookmark list.
    let path = unite#util#expand('%:p')
    let linenr = line('.')
    let pattern = '^' . escape(getline('.'), '~"\.^*$[]') . '$'
  else
    let path = fnamemodify(a:filename, ':p')
    let linenr = ''
    let pattern = ''
  endif

  let filename = (a:filename == '' ?
        \ unite#util#expand('%') : a:filename)
  if bufexists(filename) && a:filename == ''
    " Detect vimfiler and vimshell.
    if &filetype ==# 'vimfiler'
      let path = getbufvar(bufnr(filename), 'vimfiler').current_dir
    elseif &filetype ==# 'vimshell'
      let path = getbufvar(bufnr(filename), 'vimshell').current_dir
    endif
  endif

  let path = unite#substitute_path_separator(
        \ simplify(fnamemodify(unite#util#expand(path), ':p')))

  redraw
  echo 'Path: ' . path
  let bookmark_name = input('Please input bookmark file name (default): ',
        \ '', 'customlist,' . s:SID_PREFIX() . 'complete_bookmark_filename')
  if bookmark_name == ''
    let bookmark_name = 'default'
  endif
  let entry_name = input('Please input bookmark entry name : ')

  let bookmark = s:load(bookmark_name)
  call insert(bookmark.files, [entry_name, path, linenr, pattern])
  call s:save(bookmark_name, bookmark)
endfunction"}}}

let s:source = {
      \ 'name' : 'bookmark',
      \ 'description' : 'candidates from bookmark list',
      \ 'action_table' : {},
      \}

function! s:source.gather_candidates(args, context)"{{{
  let bookmark_name = get(a:args, 0, 'default')

  let bookmark = s:load(bookmark_name)
  return map(copy(bookmark.files), "{
        \ 'word' : (v:val[0] != '' ? '[' . v:val[0] . '] ' : '') .
        \          (fnamemodify(v:val[1], ':~:.') != '' ?
        \           fnamemodify(v:val[1], ':~:.') : v:val[1]),
        \ 'kind' : (isdirectory(v:val[1]) ? 'directory' : 'jump_list'),
        \ 'source_bookmark_name' : bookmark_name,
        \ 'source_entry_name' : v:val[0],
        \ 'action__path' : v:val[1],
        \ 'action__line' : v:val[2],
        \ 'action__pattern' : v:val[3],
        \ 'action__directory' : unite#path2directory(v:val[1]),
        \   }")
endfunction"}}}
function! s:source.complete(args, context, arglead, cmdline, cursorpos)"{{{
  return ['default'] + map(split(glob(
        \ g:unite_source_bookmark_directory . '/' . a:arglead . '*'), '\n'),
        \ "fnamemodify(v:val, ':t')")
endfunction"}}}

" Actions"{{{
let s:source.action_table.delete = {
      \ 'description' : 'delete from bookmark list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:source.action_table.delete.func(candidates)"{{{
  for candidate in a:candidates
    let bookmark = s:bookmarks[candidate.source_bookmark_name]
    call filter(bookmark.files, 'v:val !=# ' .
          \ string([candidate.source_entry_name, candidate.action__path,
          \      candidate.action__line, candidate.action__pattern]))
    call s:save(candidate.source_bookmark_name, bookmark)
  endfor
endfunction"}}}
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
  let filetype = getbufvar(a:candidate.action__buffer_nr, '&filetype')
  if filetype ==# 'vimfiler'
    let filename = getbufvar(a:candidate.action__buffer_nr, 'vimfiler').current_dir
  elseif filetype ==# 'vimshell'
    let filename = getbufvar(a:candidate.action__buffer_nr, 'vimshell').current_dir
  else
    let filename = a:candidate.action__path
  endif

  " Add to bookmark.
  call unite#sources#bookmark#_append(filename)
endfunction"}}}

call unite#custom_action('file', 'bookmark', s:file_bookmark_action)
call unite#custom_action('buffer', 'bookmark', s:buffer_bookmark_action)
unlet! s:file_bookmark_action
unlet! s:buffer_bookmark_action
"}}}

" Misc
function! s:save(filename, bookmark)  "{{{
  let filename = g:unite_source_bookmark_directory . '/' . a:filename
  call writefile([s:VERSION] + map(copy(a:bookmark.files), 'join(v:val, "\t")'),
        \ filename)
  let a:bookmark.file_mtime = getftime(filename)
endfunction"}}}
function! s:load(filename)  "{{{
  let filename = g:unite_source_bookmark_directory . '/' . a:filename

  call s:init_bookmark(a:filename)

  let bookmark = s:bookmarks[a:filename]
  if filereadable(filename)
  \  && bookmark.file_mtime != getftime(filename)
    let [ver; bookmark.files] = readfile(filename)
    if ver !=# s:VERSION
      echohl WarningMsg
      echomsg 'Sorry, the version of bookmark file is old.  Clears the bookmark list.'
      echohl None
      let bookmark.files = []
      return
    endif
    let bookmark.files = map(bookmark.files, 'split(v:val, "\t", 1)')
    for files in bookmark.files
      let files[1] = unite#util#substitute_path_separator(
            \ unite#util#expand(files[1]))
    endfor
    let bookmark.file_mtime = getftime(filename)
  endif

  return bookmark
endfunction"}}}
function! s:init_bookmark(filename)  "{{{
  if !has_key(s:bookmarks, a:filename)
    " file_mtime: the last modified time of the bookmark file.
    " files: [ [ name, full_path, linenr, search pattern ], ... ]
    let s:bookmarks[a:filename] = { 'file_mtime' : 0,  'files' : [] }
  endif
endfunction"}}}
function! s:complete_bookmark_filename(arglead, cmdline, cursorpos)"{{{
  return sort(filter(map(split(glob(g:unite_source_bookmark_directory . '/*'), '\n'),
        \ 'fnamemodify(v:val, ":t")'), 'stridx(v:val, a:arglead) == 0'))
endfunction"}}}
function! s:SID_PREFIX()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSID_PREFIX$')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
