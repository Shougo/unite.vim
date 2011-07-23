"=============================================================================
" FILE: changes.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 23 Jul 2011.
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

" Variables  "{{{
"}}}

function! unite#sources#change#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'change',
      \ 'description' : 'candidates from changes',
      \ 'hooks' : {},
      \ }

let s:cached_result = []
function! s:source.hooks.on_init(args, context)"{{{
  " Get changes list.
  redir => l:redir
  silent! changes
  redir END

  let l:result = []
  let l:max_width = (winwidth(0) - 5)
  for change in split(l:redir, '\n')[1:]
    let l:list = split(change)
    if len(l:list) < 4
      continue
    endif

    let [l:linenr, l:col, l:text] = [l:list[1], l:list[2]+1, join(l:list[3:])]

    call add(l:result, {
          \ 'word' : unite#util#truncate_smart(printf('%4d-%-3d  %s', l:linenr, l:col, l:text),
          \           l:max_width, l:max_width/3, '..'),
          \ 'kind' : 'jump_list',
          \ 'action__path' : unite#util#substitute_path_separator(fnamemodify(expand('%'), ':p')),
          \ 'action__buffer_nr' : bufnr('%'),
          \ 'action__line' : l:linenr,
          \ 'action__col' : l:col,
          \ })
  endfor

  let a:context.source__result = l:result
endfunction"}}}
function! s:source.gather_candidates(args, context)"{{{
  return a:context.source__result
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
