"=============================================================================
" FILE: sorter_rank.vim
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

function! unite#filters#sorter_rank#define() abort "{{{
  return s:sorter
endfunction"}}}

let s:sorter = {
      \ 'name' : 'sorter_rank',
      \ 'description' : 'sort by matched rank order',
      \}

function! s:sorter.filter(candidates, context) abort "{{{
  if a:context.input == '' || !has('float') || empty(a:candidates)
    return a:candidates
  endif

  return unite#filters#sorter_rank#_sort(
        \ a:candidates, a:context.input_list, unite#util#has_lua())
endfunction"}}}

function! unite#filters#sorter_rank#_sort(candidates, input_list, has_lua) abort "{{{
  " Initialize.
  let is_path = has_key(a:candidates[0], 'action__path')
  for candidate in a:candidates
    let candidate.filter__rank = 0
    let candidate.filter__word = is_path ?
          \ fnamemodify(candidate.word, ':t') : candidate.word
  endfor


  let inputs = map(a:input_list, "
        \ tolower(substitute(v:val, '\\*', '', 'g'))")

  let candidates = a:has_lua ?
        \ s:sort_lua(a:candidates, inputs) :
        \ s:sort_vim(a:candidates, inputs)
  " let candidates = s:sort_vim(a:candidates, inputs)

  " echomsg a:input
  " echomsg string(map(copy(candidates),
  "       \ '[v:val.word, v:val.filter__rank]'))

  return candidates
endfunction"}}}

function! s:sort_vim(candidates, inputs) abort "{{{
  for input in a:inputs
    for candidate in a:candidates
      let word = tolower(candidate.filter__word)
      let index = stridx(word, input)
      let candidate.filter__rank += len(candidate.filter__word)
            \ - (index >= 0 ? ((200 - len(candidate.filter__word))
            \      / (index+1)) : 0)
    endfor
  endfor

  return unite#util#sort_by(a:candidates, 'v:val.filter__rank')
endfunction"}}}

function! s:sort_lua(candidates, inputs) abort "{{{
  lua << EOF
do
  local candidates = vim.eval('a:candidates')

  -- Calc rank
  local inputs = vim.eval('a:inputs')
  for i = 0, #inputs-1 do
    for j = 0, #candidates-1 do
      local word = string.lower(candidates[j].filter__word)
      local index = string.find(word, inputs[i], 1, true)

      candidates[j].filter__rank = candidates[j].filter__rank
        + string.len(word) - (index ~= nil
        and ((200 - string.len(word)) / (index+1)) * 10 or 0)
    end
  end

  -- Sort
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
