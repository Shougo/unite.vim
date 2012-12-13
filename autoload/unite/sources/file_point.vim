"=============================================================================
" FILE: file_point.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 16 Oct 2012.
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

function! unite#sources#file_point#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'file_point',
      \ 'description' : 'file candidate from cursor point',
      \ 'hooks' : {},
      \}
function! s:source.hooks.on_init(args, context) "{{{
  let filename_pattern = '[[:alnum:];/?:@&=+$_.!~|()#-]\+'
  let filename = unite#util#expand(
        \ matchstr(getline('.')[: col('.')-1], filename_pattern . '$')
        \ . matchstr(getline('.')[col('.') :], '^'.filename_pattern))
  let a:context.source__filename =
        \ (filename =~ '^\%(https\?\|ftp\)://') ?
        \ filename : fnamemodify(filename, ':p')
endfunction"}}}

function! s:source.gather_candidates(args, context) "{{{
  if a:context.source__filename =~ '^\%(https\?\|ftp\)://'
    if exists('*vimproc#host_exists') &&
          \ !vimproc#host_exists(a:context.source__filename)
      " URI is invalid.
      return []
    endif

    " URI.
    return [{
          \   'word' : a:context.source__filename,
          \   'kind' : 'uri',
          \   'action__path' : a:context.source__filename,
          \ }]
  elseif filereadable(a:context.source__filename)
    return [{
          \   'word' : a:context.source__filename,
          \   'kind' : 'file',
          \   'action__path' : a:context.source__filename,
          \   'action__directory' : unite#util#path2directory(
          \               a:context.source__filename),
          \ }]
  else
    " File not found.
    return []
  endif
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
