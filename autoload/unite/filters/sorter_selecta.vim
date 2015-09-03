"=============================================================================
" FILE: sorter_selecta.vim
" AUTHOR:  David Lee
" CONTRIBUTOR:  Jean Cavallo
" DESCRIPTION: Scoring code by Gary Bernhardt
"     https://github.com/garybernhardt/selecta
" License: MIT license
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
" 
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! unite#filters#sorter_selecta#define()
  if has('python')
    return s:sorter
  else
    return {}
  endif
endfunction

let s:sorter = {
      \ 'name' : 'sorter_selecta',
      \ 'description' : 'sort by selecta algorithm',
      \}

function! s:sorter.filter(candidates, context)
  if a:context.input == '' || !has('float') || empty(a:candidates)
    return a:candidates
  endif

  return unite#filters#sorter_selecta#_sort(
        \ a:candidates, a:context.input)
endfunction

function! unite#filters#sorter_selecta#_sort(candidates, input)
  " Initialize.
  let is_path = has_key(a:candidates[0], 'action__path')
  for candidate in a:candidates
    let candidate.filter__rank = 0
    let candidate.filter__word = is_path ?
          \ fnamemodify(candidate.word, ':t') : candidate.word
  endfor


  let inputs = map(split(a:input, '\\\@<! '), "
        \ tolower(substitute(substitute(v:val, '\\\\ ', ' ', 'g'),
        \ '\\*', '', 'g'))")

  let candidates = s:sort_python(a:candidates, inputs)

  return candidates
endfunction

" @vimlint(EVL102, 1, l:input)
" @vimlint(EVL102, 1, l:candidate)
function! s:sort_python(candidates, inputs)
  for input in a:inputs
    for candidate in a:candidates
python << PYTHONEOF
import vim
score = get_score(vim.eval('candidate.word'), vim.eval('input'))
if score:
    vim.command('let candidate.filter__rank += %s' % score)
PYTHONEOF
    endfor
  endfor

  return unite#util#sort_by(a:candidates, 'v:val.filter__rank')
endfunction"}}}
" @vimlint(EVL102, 0, l:input)
" @vimlint(EVL102, 0, l:candidate)

function! s:def_python()
python << PYTHONEOF
import string

BOUNDARY_CHARS = string.punctuation + string.whitespace

def get_score(string, query_chars):
    # Highest possible score is the string length
    best_score, best_range = len(string), None
    head, tail = query_chars[0], query_chars[1:]

    # For each occurence of the first character of the query in the string
    for first_index in (idx for idx, val in enumerate(string)
            if val == head):
        # Get the score for the rest
        score, last_index = find_end_of_match(string, tail, first_index)

        if last_index and score < best_score:
            best_score = score
            best_range = (first_index, last_index)

    # Solve equal scores by sorting on the string length. The ** 0.5 part makes
    # it less and less important for big strings
    best_score = best_score * (len(string) ** 0.5)
    return best_score


def find_end_of_match(to_match, chars, first_index):
    score, last_index, last_type = 1.0, first_index, None

    for char in chars:
        try:
            index = to_match.index(char, last_index + 1)
        except ValueError:
            return None, None
        if not index:
            return None, None

        # Do not count sequential characters more than once
        if index == last_index + 1:
            if last_type != 'sequential':
                last_type = 'sequential'
                score += 1
        # Same for first characters of words
        elif to_match[index - 1] in BOUNDARY_CHARS:
            if last_type != 'boundary':
                last_type = 'boundary'
                score += 1
        # Same for camel case
        elif char in string.ascii_uppercase and \
                to_match[index - 1] in string.ascii_lowercase:
            if last_type != 'camelcase':
                last_type = 'camelcase'
                score += 1
        else:
            last_type = 'normal'
            score += index - last_index
        last_index = index
    return (score, last_index)
PYTHONEOF
endfunction

call s:def_python()

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
