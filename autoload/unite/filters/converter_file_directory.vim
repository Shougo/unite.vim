"=============================================================================
" FILE: converter_file_directory.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu (at) gmail.com>
"          basyura <basyura (at) gmail.com>
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

function! unite#filters#converter_file_directory#define() abort "{{{
  return s:converter
endfunction"}}}

let s:converter = {
      \ 'name' : 'converter_file_directory',
      \ 'description' : 'converter to separate file and directory',
      \}

function! s:converter.filter(candidates, context) abort
  let candidates = copy(a:candidates)

  let max = min([max(map(copy(candidates), "
        \ strwidth(s:convert_to_abbr(
        \  get(v:val, 'action__path', v:val.word)))"))+2,
        \ get(g:, 'unite_converter_file_directory_width', 45)])

  for candidate in candidates
    let path = get(candidate, 'action__path', candidate.word)

    let abbr = s:convert_to_abbr(path)
    let abbr = unite#util#truncate(abbr, max) . ' '
    let path = unite#util#substitute_path_separator(
          \ fnamemodify(path, ':~:.:h'))
    if path ==# '.'
      let path = ''
    endif
    let candidate.abbr = abbr . path
  endfor

  return candidates
endfunction

function! s:convert_to_abbr(path) abort
  return printf('%s (%s)', fnamemodify(a:path, ':p:t'),
        \ fnamemodify(a:path, ':p:h:t'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
