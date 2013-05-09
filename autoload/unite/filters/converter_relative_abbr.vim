"=============================================================================
" FILE: converter_relative_abbr.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 09 May 2013.
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

function! unite#filters#converter_relative_abbr#define() "{{{
  return s:converter
endfunction"}}}

let s:converter = {
      \ 'name' : 'converter_relative_abbr',
      \ 'description' : 'relative path abbr converter',
      \}

function! s:converter.filter(candidates, context) "{{{
  try
    let directory = unite#util#substitute_path_separator(getcwd())
    if has_key(a:context, 'source__directory')
      let old_dir = directory
      let directory = substitute(
            \ a:context.source__directory, '*', '', 'g')

      if directory !=# old_dir && isdirectory(directory)
            \ && a:context.input == ''
        lcd `=directory`
      endif
    endif

    for candidate in a:candidates
      let candidate.abbr = unite#util#substitute_path_separator(
            \ fnamemodify(get(candidate, 'action__path',
            \     candidate.word), ':~:.'))
    endfor
  finally
    if has_key(a:context, 'source__directory')
          \ && directory !=# old_dir
      lcd `=old_dir`
    endif
  endtry

  return a:candidates
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
