"=============================================================================
" FILE: jump.vim
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

function! unite#sources#jump#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'jump',
      \ 'description' : 'candidates from jumps',
      \ 'hooks' : {},
      \ }

let s:cached_result = []
function! s:source.hooks.on_init(args, context)"{{{
endfunction"}}}
function! s:source.gather_candidates(args, context)"{{{
  " Get jumps list.
  redir => l:redir
  silent! jumps
  redir END

  let l:result = []
  let l:max_path = (winwidth(0) - 5) / 2
  let l:max_text = (winwidth(0) - 5) - l:max_path
  for jump in split(l:redir, '\n')[1:]
    let l:list = split(jump)
    if len(l:list) < 4
      continue
    endif

    let [l:linenr, l:col, l:file_text] = [l:list[1], l:list[2]+1, join(l:list[3:])]
    let l:lines = getbufline(l:file_text, l:linenr)
    let l:path = l:file_text
    let l:bufnr = bufnr(l:file_text)
    if empty(l:lines)
      if getline(l:linenr) ==# l:file_text
        let l:lines = [l:file_text]
        let l:path = bufname('%')
        let l:bufnr = bufnr('%')
      elseif filereadable(l:path)
        let l:bufnr = 0
        let l:lines = ['buffer unloaded']
      else
        " Skip.
        continue
      endif
    endif

    if getbufvar(l:bufnr, '&filetype') ==# 'unite'
      " Skip unite buffer.
      continue
    endif

    let l:text = get(l:lines, 0, '')

    let l:dict = {
          \ 'word' : unite#util#truncate_smart(printf('%s:%d-%d  ', l:path, l:linenr, l:col),
          \           l:max_path, l:max_path/3, '..') .
          \          unite#util#truncate_smart(l:text, l:max_text, l:max_text/3, '..'),
          \ 'kind' : 'jump_list',
          \ 'action__path' : unite#util#substitute_path_separator(fnamemodify(expand(l:path), ':p')),
          \ 'action__line' : l:linenr,
          \ 'action__col' : l:col,
          \ }

    if l:bufnr > 0
      let l:dict.action__buffer_nr = l:bufnr
    endif

    call add(l:result, l:dict)
  endfor

  return reverse(l:result)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
