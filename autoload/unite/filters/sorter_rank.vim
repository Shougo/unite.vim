"=============================================================================
" FILE: sorter_rank.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 03 Jul 2013.
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

function! unite#filters#sorter_rank#define() "{{{
  return s:sorter
endfunction"}}}

let s:sorter = {
      \ 'name' : 'sorter_rank',
      \ 'description' : 'sort by matched rank order',
      \}

function! s:sorter.filter(candidates, context) "{{{
  if a:context.input == '' || !has('float')
    return a:candidates
  endif

  " Initialize.
  for candidate in a:candidates
    let candidate.filter__rank = 0
  endfor

  for input in split(a:context.input, '\\\@<! ')
    let input = substitute(substitute(input, '\\ ', ' ', 'g'),
          \ '\*', '', 'g')

    " Calc rank.
    let l1 = len(input)
    for candidate in a:candidates
      let candidate.filter__rank +=
            \ s:calc_word_distance(input, candidate.word, l1)
    endfor
  endfor

  return unite#util#sort_by(a:candidates, 'v:val.filter__rank')
endfunction"}}}

function! s:calc_word_distance(str1, str2, l1) "{{{
  let l2 = len(a:str2)
  let p1 = range(l2+1)
  let p2 = []

  for i in range(l2+1)
    call add(p2, 0)
  endfor

  for i in range(a:l1)
    let p2[0] = p1[0] + 1
    for j in range(l2)
      let p2[j+1] = min([p1[j+1] + 1, p2[j]+1])
    endfor
    let [p1, p2] = [p2, p1]
  endfor

  " echomsg string([a:str1, a:str2, p1[l2]])
  return p1[l2]
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
