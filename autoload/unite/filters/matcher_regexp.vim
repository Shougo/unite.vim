"=============================================================================
" FILE: matcher_regexp.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 Aug 2011.
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

function! unite#filters#matcher_regexp#define()"{{{
  return s:matcher
endfunction"}}}

let s:matcher = {
      \ 'name' : 'matcher_regexp',
      \ 'description' : 'regular expression matcher',
      \}

function! s:matcher.filter(candidates, context)"{{{
  if a:context.input == ''
    return a:candidates
  endif

  let l:candidates = a:candidates
  for l:input in split(a:context.input, '\\\@<! ')
    if l:input =~ '^!'
      if l:input == '!'
        continue
      endif
      " Exclusion match.
      try
        let l:candidates = filter(copy(l:candidates),
              \ 'v:val.word !~ ' . string(l:input[1:]))
      catch
      endtry
    elseif l:input !~ '[~\\.^$[\]*]'
      " Optimized filter.
      let l:input = substitute(l:input, '\\\(.\)', '\1', 'g')
      let l:expr = &ignorecase ?
            \ printf('stridx(tolower(v:val.word), %s) != -1', string(tolower(l:input))) :
            \ printf('stridx(v:val.word, %s) != -1', string(l:input))

      let l:candidates = filter(copy(l:candidates), l:expr)
    else
      try
        let l:candidates = filter(copy(l:candidates),
              \ 'v:val.word =~ ' . string(l:input))
      catch
      endtry
    endif
  endfor

  return l:candidates
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
