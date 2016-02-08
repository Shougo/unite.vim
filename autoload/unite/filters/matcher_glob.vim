"=============================================================================
" FILE: matcher_glob.vim
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

function! unite#filters#matcher_glob#define() abort "{{{
  return s:matcher
endfunction"}}}

let s:matcher = {
      \ 'name' : 'matcher_glob',
      \ 'description' : 'glob matcher',
      \}

function! s:matcher.pattern(input) abort "{{{
  return substitute(unite#util#escape_match(a:input),
          \ '\\\@<!|', '\\|', 'g')
endfunction"}}}

function! s:matcher.filter(candidates, context) abort "{{{
  if a:context.input == ''
    return unite#filters#filter_matcher(
          \ a:candidates, '', a:context)
  endif

  let candidates = a:candidates
  for input in a:context.input_list
    let candidates = unite#filters#matcher_glob#glob_matcher(
          \ candidates, input, a:context)
  endfor

  return candidates
endfunction"}}}

function! unite#filters#matcher_glob#glob_matcher(candidates, input, context) abort "{{{
  let input = a:input

  if input =~ '^!'
    if input == '!'
      return a:candidates
    endif

    " Exclusion.
    let input = substitute(unite#util#escape_match(input),
          \ '\\\@<!|', '\\|', 'g')
    let expr = 'v:val.word !~ ' . string(input[1:])
  elseif input =~ '^:'
    " Executes command.
    let a:context.execute_command = input[1:]
    return a:candidates
  elseif input =~ '\\\@<![*|]'
    " Wildcard(*) or OR(|).
    let input = s:matcher.pattern(input)
    let expr = 'v:val.word =~ ' . string(input)
  elseif unite#util#has_lua()
    let expr = 'if_lua'
    let a:context.input_lua = input
  else
    let input = substitute(input, '\\\(.\)', '\1', 'g')
    let expr = &ignorecase ?
          \ printf('stridx(tolower(v:val.word), %s) != -1',
          \     string(tolower(input))) :
          \ printf('stridx(v:val.word, %s) != -1',
          \     string(input))
  endif

  return unite#filters#filter_matcher(a:candidates, expr, a:context)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
