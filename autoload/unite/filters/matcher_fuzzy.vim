"=============================================================================
" FILE: matcher_fuzzy.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Feb 2012.
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

function! unite#filters#matcher_fuzzy#define()"{{{
  return s:matcher
endfunction"}}}

let s:matcher = {
      \ 'name' : 'matcher_fuzzy',
      \ 'description' : 'fuzzy matcher',
      \}

function! s:matcher.filter(candidates, context)"{{{
  if a:context.input == ''
    return a:candidates
  endif

  let candidates = a:candidates
  for input in split(a:context.input, '\\\@<! ')
    let input = substitute(input, '\\ ', ' ', 'g')
    if input == '!'
      continue
    endif

    let input = substitute(substitute(unite#escape_match(input),
          \ '[[:alnum:]._-]', '\0.*', 'g'), '\*\*', '*', 'g')

    let expr = (input =~ '^!') ?
          \ 'v:val.word !~ ' . string(input[1:]) :
          \ 'v:val.word =~ ' . string(input)

    let candidates = filter(copy(candidates), expr)
  endfor

  return candidates
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
