"=============================================================================
" FILE: jump.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 02 Oct 2012.
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

function! unite#sources#jump#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'jump',
      \ 'description' : 'candidates from jumps',
      \ 'default_kind' : 'jump_list',
      \ }

let s:cached_result = []
function! s:source.gather_candidates(args, context) "{{{
  " Get jumps list.
  redir => redir
  silent! jumps
  redir END

  let result = []
  for jump in split(redir, '\n')[1:]
    let list = split(jump)
    if len(list) < 4
      continue
    endif

    let [linenr, col, file_text] = [list[1], list[2]+1, join(list[3:])]
    let lines = getbufline(file_text, linenr)
    let path = file_text
    let bufnr = bufnr(file_text)
    if empty(lines)
      if stridx(join(split(getline(linenr))), file_text) == 0
        let lines = [file_text]
        let path = bufname('%')
        let bufnr = bufnr('%')
      elseif filereadable(path)
        let bufnr = 0
        let lines = ['buffer unloaded']
      else
        " Skip.
        continue
      endif
    endif

    if getbufvar(bufnr, '&filetype') ==# 'unite'
      " Skip unite buffer.
      continue
    endif

    call add(result, [linenr, col, file_text, path, bufnr, lines])
  endfor

  let max_path = max(map(copy(result),
        \ 'len(printf("%s:%d-%d", v:val[3], v:val[0], v:val[1]))')) + 1
  let _ = []
  for [linenr, col, file_text, path, bufnr, lines] in result
    let text = substitute(get(lines, 0, ''), '^\s\+', '', '')

    let dict = {
          \ 'word' : unite#util#truncate(
          \     printf('%s:%d-%d  ', path, linenr, col), max_path) . text,
          \ 'action__path' : unite#util#substitute_path_separator(
          \     fnamemodify(unite#util#expand(path), ':p')),
          \ 'action__line' : linenr,
          \ 'action__col' : col,
          \ }

    if bufnr > 0
      let dict.action__buffer_nr = bufnr
    endif

    call add(_, dict)
  endfor

  return reverse(_)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
