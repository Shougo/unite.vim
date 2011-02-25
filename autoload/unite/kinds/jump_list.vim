"=============================================================================
" FILE: jump_list.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 25 Feb 2011.
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

" Variables  "{{{
if !exists('g:unite_kind_jump_list_after_jump_scroll')
  let g:unite_kind_jump_list_after_jump_scroll = 25
else
  let g:unite_kind_jump_list_after_jump_scroll =
        \ min([max([0, g:unite_kind_jump_list_after_jump_scroll]), 100])
endif
"}}}

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
      \ 'description' : 'jump to this position',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.open.func(candidates)"{{{
  for l:candidate in a:candidates
    if bufnr(unite#util#escape_file_searching(l:candidate.action__path)) != bufnr('%')
      edit `=l:candidate.action__path`
    endif
    call s:jump(l:candidate)

    " Open folds.
    normal! zv
    call s:adjust_scroll(s:best_winline())
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview this position',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate)"{{{
  pedit +call\ s:jump(a:candidate) `=a:candidate.action__path`
endfunction"}}}
"}}}

" Misc.
function! s:jump(candidate)"{{{
  if !has_key(a:candidate, 'action__line') && !has_key(a:candidate, 'action__pattern')
    " Move to head.
    0
    return
  endif

  if has_key(a:candidate, 'action__line')
        \ && a:candidate.action__line != ''
        \ && a:candidate.action__line !~ '^\d\+$'
    call unite#print_error('unite: jump_list: Invalid action__line format.')
    return
  endif

  if !has_key(a:candidate, 'action__pattern')
    " Jump to the line number.
    execute a:candidate.action__line
    return
  endif

  let l:pattern = a:candidate.action__pattern

  " Jump by search().
  let l:source = unite#get_sources(a:candidate.source)
  if !(has_key(a:candidate, 'action__signature') && has_key(l:source, 'calc_signature'))
    " Not found signature.
    if has_key(a:candidate, 'action__line')
          \ && a:candidate.action__line != ''
          \ && getline(a:candidate.action__line) =~# l:pattern
      execute a:candidate.action__line
    else
      call search(l:pattern, 'w')
    endif
    return
  endif

  call search(l:pattern, 'w')

  let l:lnum_prev = line('.')
  call search(l:pattern, 'w')
  let l:lnum = line('.')
  if l:lnum != l:lnum_prev
    " Detected same pattern lines!!
    let l:start_lnum = l:lnum
    while l:source.calc_signature(l:lnum) !=# a:candidate.action__signature
      call search(l:pattern, 'w')
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

function! s:best_winline()"{{{
  return max([1, winheight(0) * g:unite_kind_jump_list_after_jump_scroll / 100])
endfunction"}}}

function! s:adjust_scroll(best_winline)"{{{
  normal! zt
  let l:save_cursor = getpos('.')
  let l:winl = 1
  " Scroll the cursor line down.
  while l:winl <= a:best_winline
    let l:winl_prev = l:winl
    execute "normal! \<C-y>"
    let l:winl = winline()
    if l:winl == l:winl_prev
      break
    end
    let l:winl_prev = l:winl
  endwhile
  if l:winl > a:best_winline
    execute "normal! \<C-e>"
  endif
  call setpos('.', l:save_cursor)
endfunction"}}}

" vim: foldmethod=marker
