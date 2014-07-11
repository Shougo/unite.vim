"=============================================================================
" FILE: sorter_selecta.vim
" AUTHOR:  David Lee
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
  if has('ruby')
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

  let candidates = s:sort_ruby(a:candidates, inputs)

  return candidates
endfunction

" @vimlint(EVL102, 1, l:input)
" @vimlint(EVL102, 1, l:candidate)
function! s:sort_ruby(candidates, inputs)
  for input in a:inputs
    for candidate in a:candidates
ruby << RUBYEOF
        score = Score.score(VIM::evaluate('candidate.word'), VIM::evaluate('input'))
        VIM::command("let candidate.filter__rank += #{1.0 / score}")
RUBYEOF
    endfor
  endfor

  return unite#util#sort_by(a:candidates, 'v:val.filter__rank')
endfunction"}}}
" @vimlint(EVL102, 0, l:input)
" @vimlint(EVL102, 0, l:candidate)

function! s:def_ruby()
  ruby << RUBYEOF
  class Score
    class << self
      def score(choice, query)
        return 1.0 if query.length == 0
        return 0.0 if choice.length == 0

        choice = choice.downcase
        query = query.downcase

        match_length = compute_match_length(choice, query.each_char.to_a)
        return 0.0 unless match_length

        # Penalize longer matches.
        score = query.length.to_f / match_length.to_f

        # Normalize vs. the length of the choice, penalizing longer strings.
        score / choice.length
      end

      # Find the length of the shortest substring matching the given characters.
      def compute_match_length(string, chars)
        first_char, *rest = chars
        first_indexes = find_char_in_string(string, first_char)

        first_indexes.map do |first_index|
          last_index = find_end_of_match(string, rest, first_index)
          if last_index
            last_index - first_index + 1
          else
            nil
          end
        end.compact.min
      end

      # Find all occurrences of the character in the string, returning their indexes.
      def find_char_in_string(string, char)
        index = 0
        indexes = []
        while index
          index = string.index(char, index)
          if index
            indexes << index
            index += 1
          end
        end
        indexes
      end

      # Find each of the characters in the string, moving strictly left to right.
      def find_end_of_match(string, chars, first_index)
        last_index = first_index
        chars.each do |this_char|
          index = string.index(this_char, last_index + 1)
          return nil unless index
          last_index = index
        end
        last_index
      end
    end
  end
RUBYEOF
endfunction

call s:def_ruby()

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
