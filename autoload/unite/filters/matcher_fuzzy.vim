"=============================================================================
" FILE: matcher_fuzzy.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 09 Jan 2014.
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

function! unite#filters#matcher_fuzzy#define() "{{{
  return s:matcher
endfunction"}}}

call unite#util#set_default('g:unite_matcher_fuzzy_max_input_length', 20)

let s:matcher = {
      \ 'name' : 'matcher_fuzzy',
      \ 'description' : 'fuzzy matcher',
      \}

function! s:matcher.pattern(input) "{{{
  return substitute(substitute(unite#util#escape_match(a:input),
        \ '\([[:alnum:]_-]\|\\\.\)\ze.', '\0.\\{-}', 'g'), '\*\*', '*', 'g')
endfunction"}}}

function! s:matcher.filter(candidates, context) "{{{
  if a:context.input == ''
    return unite#filters#filter_matcher(
          \ a:candidates, '', a:context)
  endif

  if len(a:context.input) > g:unite_matcher_fuzzy_max_input_length
    " Fall back to matcher_glob.
    return unite#filters#matcher_glob#define().filter(
          \ a:candidates, a:context)
  endif

  let candidates = a:candidates
  for input_orig in a:context.input_list
    let input = substitute(input_orig, '\\ ', ' ', 'g')
    if input == '!'
      continue
    elseif input =~ '^:'
      " Executes command.
      let a:context.execute_command = input[1:]
      continue
    endif

    let input = substitute(substitute(unite#util#escape_match(input),
          \ '\([[:alnum:]_-]\|\\\.\)\ze.', '\0.\\{-}', 'g'), '\*\*', '*', 'g')

    let expr = (input =~ '^!') ?
          \ 'v:val.word !~ ' . string(input[1:]) :
          \ 'v:val.word =~ ' . string(input)
    if input !~ '^!' && unite#util#has_lua()
      let expr = 'if_lua_fuzzy'
      let a:context.input = input_orig
    endif

    let candidates = unite#filters#filter_matcher(
          \ a:candidates, expr, a:context)
  endfor

  return candidates
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
