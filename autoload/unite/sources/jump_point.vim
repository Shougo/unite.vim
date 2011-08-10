"=============================================================================
" FILE: jump_point.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 10 Aug 2011.
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

function! unite#sources#jump_point#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'jump_point',
      \ 'description' : 'candidates from cursor point',
      \ 'hooks' : {},
      \}
function! s:source.hooks.on_init(args, context)"{{{
  let l:line = substitute(getline('.'), '^!!!\|!!!$', '', 'g')
  let a:context.source__lines =
        \ (l:line =~ '^\f\+:') ?  [l:line] : []
endfunction"}}}

function! s:source.gather_candidates(args, context)"{{{
  let l:candidates = []

  for [word, list] in map(a:context.source__lines,
        \ '[v:val, split(v:val[2:], ":")]')
    let l:candidate = {
        \   'word': word,
        \   'kind': 'jump_list',
        \ }
    if len(word) == 1 && unite#util#is_win()
      let l:candidate.word = word . list[0]
      let list = list[1:]
    endif

    let l:candidate.action__path = unite#util#substitute_path_separator(
          \ fnamemodify(word[:1].list[0], ':p'))

    if len(list) >= 1 && list[1] =~ '^\d\+$'
      let l:candidate.action__line = list[1]
      if len(list) >= 2 && list[2] =~ '^\d\+$'
        let l:candidate.action__col = list[2]
      endif
    else
      let l:candidate.action__text = join(list[1:], ':')
      let l:candidate.action__pattern =
            \ unite#escape_match(l:candidate.action__text)
    endif

    call add(l:candidates, l:candidate)
  endfor

  return l:candidates
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
