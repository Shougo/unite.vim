"=============================================================================
" FILE: launcher.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
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
"}}}

function! unite#sources#launcher#define() abort "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'launcher',
      \ 'description' : 'candidates from executable files',
      \ 'default_kind' : 'guicmd',
      \ 'converters' : 'converter_file_directory',
      \ 'max_candidates' : 100,
      \ }

let s:cached_result = {}
function! s:source.gather_candidates(args, context) abort "{{{
  let path = get(a:args, 0, '')
  if path == ''
    " Use $PATH.
    let path = substitute($PATH,
          \ (unite#util#is_windows() ? ';' : ':'), ',', 'g')
  endif

  if !has_key(s:cached_result, path) || a:context.is_redraw
    let s:cached_result[path] = map(
          \ unite#sources#launcher#get_executables(path), "{
          \ 'word' : v:val,
          \ 'action__path' : v:val,
          \ }")
  endif

  return s:cached_result[path]
endfunction"}}}

function! unite#sources#launcher#get_executables(path) abort "{{{
  " Search executable files from $PATH.
  let files = unite#util#uniq(split(globpath(a:path, '*'), '\n'))

  if unite#util#is_windows()
    let exts = escape(substitute($PATHEXT . ';.LNK', ';', '\\|', 'g'), '.')
    let pattern = '"." . fnamemodify(v:val, ":e") =~? '.string(exts)
  else
    let pattern = 'executable(v:val)'
  endif

  return filter(files, pattern)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
