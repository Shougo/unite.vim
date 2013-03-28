"=============================================================================
" FILE: bookmark.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 20 Aug 2010
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

if exists('g:loaded_unite_source_bookmark')
      \ || $SUDO_USER != ''
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

command! -nargs=? -complete=file UniteBookmarkAdd call unite#sources#bookmark#_append(<q-args>)

" Add custom action table. "{{{
let s:file_bookmark_action = {
      \ 'description' : 'append files to bookmark list',
      \ }
function! s:file_bookmark_action.func(candidate) "{{{
  " Add to bookmark.
  call unite#sources#bookmark#_append(a:candidate.action__path)
endfunction"}}}

let s:buffer_bookmark_action = {
      \ 'description' : 'append buffers to bookmark list',
      \ }
function! s:buffer_bookmark_action.func(candidate) "{{{
  let filetype = getbufvar(
        \ a:candidate.action__buffer_nr, '&filetype')
  if filetype ==# 'vimfiler'
    let filename = getbufvar(
          \ a:candidate.action__buffer_nr, 'vimfiler').current_dir
  elseif filetype ==# 'vimshell'
    let filename = getbufvar(
          \ a:candidate.action__buffer_nr, 'vimshell').current_dir
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

let g:loaded_unite_source_bookmark = 1

let &cpo = s:save_cpo
unlet s:save_cpo

" __END__
" vim: foldmethod=marker
