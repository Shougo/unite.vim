"=============================================================================
" FILE: resume.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 06 Oct 2012.
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

function! unite#sources#resume#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'resume',
      \ 'description' : 'candidates from resume list',
      \ 'default_kind' : 'command',
      \}

function! s:source.gather_candidates(args, context) "{{{
  let a:context.source__buffer_list = filter(range(1, bufnr('$')), "
        \ getbufvar(v:val, '&filetype') ==# 'unite'
        \  && !getbufvar(v:val, 'unite').context.temporary
        \  && getbufvar(v:val, 'unite').sources[0].name != 'resume'")

  let max_width = max(map(copy(a:context.source__buffer_list),
        \ 'len(getbufvar(v:val, "unite").buffer_name)'))
  let candidates = map(copy(a:context.source__buffer_list), "{
        \ 'word' : getbufvar(v:val, 'unite').buffer_name,
        \ 'abbr' : printf('%-'.max_width.'s : '
        \          . join(map(copy(getbufvar(v:val, 'unite').sources),
        \              'v:val.name'), ', '),
        \            getbufvar(v:val, 'unite').buffer_name),
        \ 'action__command' : 'UniteResume ' .
        \          getbufvar(v:val, 'unite').buffer_name,
        \ 'source__time' : getbufvar(v:val, 'unite').access_time,
        \}")

  return sort(candidates, 's:compare')
endfunction"}}}

" Misc.
function! s:compare(candidate_a, candidate_b) "{{{
  return a:candidate_b.source__time - a:candidate_a.source__time
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
