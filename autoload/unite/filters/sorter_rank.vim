"=============================================================================
" FILE: sorter_rank.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 18 Dec 2013.
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
  if a:context.input == '' || !has('float') || empty(a:candidates)
    return a:candidates
  endif

  return unite#filters#sorter_rank#_sort(
        \ a:candidates, a:context.input, unite#util#has_lua())
endfunction"}}}

function! unite#filters#sorter_rank#_sort(candidates, input, has_lua) "{{{
  " Initialize.
  for candidate in a:candidates
    let candidate.filter__rank = 0
  endfor

  let is_path = has_key(a:candidates[0], 'action__path')

  for input in split(a:input, '\\\@<! ')
    let input = tolower(substitute(substitute(input, '\\ ', ' ', 'g'),
          \ '\*', '', 'g'))

    if a:has_lua
      for candidate in a:candidates
        let candidate.filter__rank +=
              \ s:calc_word_distance_lua(input, (is_path ?
              \  fnamemodify(candidate.word, ':t') : candidate.word))
      endfor
    else
      for candidate in a:candidates
        let candidate.filter__rank +=
              \ s:calc_word_distance(input, (is_path ?
              \  fnamemodify(candidate.word, ':t') : candidate.word))
      endfor
    endif
  endfor

  " echomsg a:input
  " echomsg string(map(copy(unite#util#sort_by(a:candidates, 'v:val.filter__rank')),
  "       \ '[v:val.word, v:val.filter__rank]'))
  return a:has_lua ?
        \ s:sort_lua(a:candidates) :
        \ unite#util#sort_by(a:candidates, 'v:val.filter__rank')
endfunction"}}}

function! s:calc_word_distance(str1, str2) "{{{
  let index = stridx(a:str2, a:str1)
  return len(a:str2) - (index >= 0 ? ((200 - len(a:str2)) / (index+1)) : 0)
endfunction"}}}

function! s:calc_word_distance_lua(str1, str2) "{{{
  lua << EOF
  local pattern = vim.eval('a:str1')
  local word = vim.eval('a:str2')
  local index = string.find(string.lower(word), pattern, 1, true)
  local distance = string.len(word) - (index ~= nil
     and ((200 - string.len(word)) / (index+1)) * 10 or 0)
  vim.command('let distance = ' .. distance)
EOF

  return distance
endfunction"}}}

function! s:sort_lua(candidates) "{{{
  lua << EOF
do
  local candidates = vim.eval('a:candidates')
  local t = {}
  for i = 1, #candidates do
    t[i] = candidates[i-1]
  end
  table.sort(t, function(a, b)
        return a.filter__rank < b.filter__rank
      end)
  for i = 0, #candidates-1 do
    candidates[i] = t[i+1]
  end
end
EOF
  return a:candidates
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
