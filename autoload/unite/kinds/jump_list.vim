"=============================================================================
" FILE: jump_list.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 22 Nov 2010
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

function! unite#kinds#jump_list#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'jump_list',
      \ 'default_action' : 'open',
      \ 'action_table': {},
      \ 'parents': ['openable'],
      \}

" Actions"{{{
let s:kind.action_table.open = {
      \ 'description' : 'jump this position',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.open.func(candidates)"{{{
  for l:candidate in a:candidates
    execute 'edit' '+call\ s:jump(l:candidate)' '`=l:candidate.action__path`'

    " Open folds.
    normal! zv
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview this position',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate)"{{{
  execute 'pedit' '+call\ s:jump(a:candidate)' '`=a:candidate.action__path`'
endfunction"}}}
"}}}

" Misc.
function! s:jump(candidate)"{{{
  if !has_key(a:candidate, 'action__line') && !has_key(a:candidate, 'action__pattern')
    " Move to head.
    0
    return
  endif

  if !has_key(a:candidate, 'action__pattern')
    " Jump to the line number.
    execute a:candidate.action__line
    return
  endif

  " Jump by search().
  if !(has_key(a:candidate, 'action__signature_lines') && has_key(a:candidate, 'action__signature_len'))
    " Not found signature.
    if getline(a:candidate.action__line) =~# a:candidate.action__pattern
      execute a:candidate.action__line
    else
      call search(a:candidate.action__pattern, 'w')
    endif
    return
  endif

  call search(a:candidate.action__pattern, 'w')

  let l:lnum_prev = line('.')
  call search(a:candidate.action__pattern, 'w')
  let l:lnum = line('.')
  if l:lnum != l:lnum_prev
    " Detected same pattern lines!!
    let l:signature_lines = a:candidate.action__signature_lines
    let l:signature_len = a:candidate.action__signature_len
    let l:start_lnum = l:lnum
    while !s:check_signature(l:lnum, l:signature_lines, l:signature_len)
      call search(a:candidate.action__pattern, 'w')
      let l:lnum = line('.')
      if l:lnum == l:start_lnum
        " Not found.
        call unite#print_error("unite: jump_list: Target position is not found.")
        0
        return
      endif
    endwhile
  endif
endfunction"}}}

function! s:check_signature(lnum, signature_lines, signature_len)
  if empty(a:signature_lines)
    return 1
  endif

  let l:from = max([1, a:lnum - a:signature_len])
  let l:to   = min([a:lnum + a:signature_len, line('$')])
  return join(getline(l:from, l:to)) ==# a:signature_lines
endfunction

" vim: foldmethod=marker
