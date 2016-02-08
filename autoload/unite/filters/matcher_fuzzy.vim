"=============================================================================
" FILE: matcher_fuzzy.vim
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

function! unite#filters#matcher_fuzzy#define() abort "{{{
  return s:matcher
endfunction"}}}

call unite#util#set_default('g:unite_matcher_fuzzy_max_input_length', 20)

let s:matcher = {
      \ 'name' : 'matcher_fuzzy',
      \ 'description' : 'fuzzy matcher',
      \}

function! s:matcher.pattern(input) abort "{{{
  let chars = map(split(a:input, '\zs'), "escape(v:val, '\\[]^$.*')")
  if empty(chars)
    return ''
  endif

  let pattern =
        \   substitute(join(map(chars[:-2], "
        \       printf('%s[^%s]\\{-}', v:val, v:val)
        \   "), '') . chars[-1], '\*\*', '*', 'g')
  return pattern
endfunction"}}}

function! s:matcher.filter(candidates, context) abort "{{{
  if a:context.input == ''
    return unite#filters#filter_matcher(
          \ a:candidates, '', a:context)
  endif

  if len(a:context.input) == 1
    " Fallback to glob matcher.
    return unite#filters#matcher_glob#define().filter(
          \ a:candidates, a:context)
  endif

  " Fix for numeric problem.
  let $LC_NUMERIC = 'en_US.utf8'

  let candidates = a:candidates
  for input in a:context.input_list
    if input == '!' || input == ''
      continue
    elseif input =~ '^:'
      " Executes command.
      let a:context.execute_command = input[1:]
      continue
    endif

    let pattern = s:matcher.pattern(input)

    let expr = (pattern =~ '^!') ?
          \ 'v:val.word !~ ' . string(pattern[1:]) :
          \ 'v:val.word =~ ' . string(pattern)
    if input !~ '^!' && unite#util#has_lua()
      let expr = 'if_lua_fuzzy'
      let a:context.input_lua = input
    endif

    let candidates = unite#filters#filter_matcher(
          \ a:candidates, expr, a:context)
  endfor

  return candidates
endfunction"}}}

function! unite#filters#matcher_fuzzy#get_fuzzy_input(input) abort "{{{
  let input = a:input
  let head = ''
  if len(input) > g:unite_matcher_fuzzy_max_input_length
    let pos = strridx(input, '/')
    if pos > 0
      let head = input[: pos-1]
      let input = input[pos :]
    endif
    if len(input) > g:unite_matcher_fuzzy_max_input_length
      let head = input
      let input = ''
    endif
  endif

  return [head, input]
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
