"=============================================================================
" FILE: glob.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Feb 2011.
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

function! unite#matchers#glob#define()"{{{
  return s:matcher
endfunction"}}}

let s:matcher = {
      \ 'name' : 'glob',
      \ 'description' : 'glob matcher',
      \ 'hooks' : {},
      \}

function! s:matcher.hooks.on_init(context)"{{{
endfunction"}}}

function! s:matcher.match(candidates, context)"{{{
  let l:candidates = copy(a:candidates)

  for l:input in split(a:context.input, '\\\@<! ')
    let l:input = substitute(l:input, '\\ ', ' ', 'g')

    if l:input =~ '^!'
      " Exclusion.
      let l:input = unite#escape_match(l:input)
      call filter(l:candidates, 'v:val.word !~ ' . string(l:input[1:]))
    elseif l:input =~ '\\\@<!\*'
      " Wildcard.
      let l:input = unite#escape_match(l:input)
      call filter(l:candidates, 'v:val.word =~ ' . string(l:input))
    else
      let l:input = substitute(l:input, '\\\(.\)', '\1', 'g')
      if &ignorecase
        let l:expr = printf('stridx(tolower(v:val.word), %s) != -1', string(tolower(l:input)))
      else
        let l:expr = printf('stridx(v:val.word, %s) != -1', string(l:input))
      endif

      let l:candidates = filter(l:candidates, l:expr)
    endif
  endfor

  return l:candidates
endfunction"}}}

" vim: foldmethod=marker
