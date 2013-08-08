"=============================================================================
" FILE: sorter_rank.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 Aug 2013.
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

  " Initialize.
  for candidate in a:candidates
    let candidate.filter__rank = 0
  endfor

  " let is_path = has_key(a:candidates[0], 'action__path')

  for input in split(a:context.input, '\\\@<! ')
    let input = substitute(substitute(input, '\\ ', ' ', 'g'),
          \ '\*', '', 'g')

    " Calc rank.
    let l1 = len(input)

    " for candidate in a:candidates
    "   let word = is_path ? fnamemodify(candidate.word, ':t') : candidate.word
    "   let index = stridx(word, input[0])
    "   let candidate.filter__rank +=
    "         \ len(word) + (index > 0 ? index * 2 : len(word))
    " endfor

    if unite#util#has_lua()
      for candidate in a:candidates
        let candidate.filter__rank +=
              \ s:calc_word_distance_lua(input, candidate.word, l1)
      endfor
    else
      for candidate in a:candidates
        let candidate.filter__rank +=
              \ s:calc_word_distance(input, candidate.word, l1)
      endfor
    endif
  endfor

  return unite#util#has_lua() ?
        \ s:sort_lua(a:candidates) :
        \ unite#util#sort_by(a:candidates, 'v:val.filter__rank')
endfunction"}}}

function! s:calc_word_distance(str1, str2, l1) "{{{
  return 

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

function! s:calc_word_distance_lua(str1, str2, l1) "{{{
  lua << EOF
  local str1 = vim.eval('a:str1')
  local str2 = vim.eval('a:str2')
  local l1 = vim.eval('a:l1')
  local l2 = string.len(str2)
  local p1 = {}
  local p2 = {}

  local cnt = 0
  for i = 0, l2+1 do
    p1[i] = cnt
    p2[i] = 0

    cnt = cnt + 1
  end

  for i = 0, l1 do
    p2[0] = p1[0] + 1
    for j = 0, l2 do
      p2[j+1] = math.min(p1[j+1] + 1, p2[j]+1)
    end
  end

  vim.command('let distance = ' .. p1[l2])
EOF

  " echomsg string([a:str1, a:str2, distance])
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
  " echomsg string(map(copy(a:candidates), '[v:val.word, v:val.filter__rank]'))
  return a:candidates
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
