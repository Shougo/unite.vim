"=============================================================================
" FILE: jump_list.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 22 Nov 2011.
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
  for candidate in a:candidates
    if bufnr(unite#util#escape_file_searching(candidate.action__path)) != bufnr('%')
      if has_key(candidate, 'action__buffer_nr')
        execute 'buffer' candidate.action__buffer_nr
      else
        edit `=candidate.action__path`
      endif
    endif
    call s:jump(candidate, 0)

    " Open folds.
    normal! zv
    call s:adjust_scroll(s:best_winline())

    call unite#remove_previewed_buffer_list(
          \ bufnr(unite#util#escape_file_searching(
          \       candidate.action__path)))
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview this position',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate)"{{{
  let buflisted = buflisted(
        \ unite#util#escape_file_searching(
        \ a:candidate.action__path))

  pedit +call\ s:jump(a:candidate,1) `=a:candidate.action__path`
  if has_key(a:candidate, 'action__buffer_nr')
    let filetype = getbufvar(a:candidate.action__buffer_nr, '&filetype')
    if filetype != ''
      let winnr = winnr()
      execute bufwinnr(a:candidate.action__buffer_nr) . 'wincmd w'
      execute 'setfiletype' filetype
      execute winnr . 'wincmd w'
    endif
  endif

  if !buflisted
    call unite#add_previewed_buffer_list(
        \ bufnr(unite#util#escape_file_searching(
        \       a:candidate.action__path)))
  endif
endfunction"}}}

if globpath(&runtimepath, 'autoload/qfreplace.vim') != ''
  let s:kind.action_table.replace = {
        \ 'description' : 'replace with qfreplace',
        \ 'is_selectable' : 1,
        \ }
  function! s:kind.action_table.replace.func(candidates)"{{{
    let qflist = []
    for candidate in a:candidates
      if has_key(candidate, 'action__line')
            \ && has_key(candidate, 'action__text')
        call add(qflist, {
              \ 'filename' : candidate.action__path,
              \ 'lnum' : candidate.action__line,
              \ 'text' : candidate.action__text,
              \ })
      endif
    endfor

    if !empty(qflist)
      call setqflist(qflist)
      call qfreplace#start('')
    endif
  endfunction"}}}
endif
"}}}

" Misc.
function! s:jump(candidate, is_highlight)"{{{
  if !has_key(a:candidate, 'action__line')
        \ && !has_key(a:candidate, 'action__pattern')
    " Move to head.
    call cursor(1, 1)
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
    let col = has_key(a:candidate, 'action__col') ?
          \ a:candidate.action__col : 0
    call cursor(a:candidate.action__line, col)
    call s:open_current_line(a:is_highlight)
    return
  endif

  let pattern = a:candidate.action__pattern

  " Jump by search().
  let source = unite#get_sources(a:candidate.source)
  if !(has_key(a:candidate, 'action__signature') && has_key(source, 'calc_signature'))
    " Not found signature.
    if has_key(a:candidate, 'action__line')
          \ && a:candidate.action__line != ''
          \ && getline(a:candidate.action__line) =~# pattern
      execute a:candidate.action__line
    else
      call search(pattern, 'w')
    endif

    call s:open_current_line(a:is_highlight)
    return
  endif

  call search(pattern, 'w')

  let lnum_prev = line('.')
  call search(pattern, 'w')
  let lnum = line('.')
  if lnum != lnum_prev
    " Detected same pattern lines!!
    let start_lnum = lnum
    while source.calc_signature(lnum) !=# a:candidate.action__signature
      call search(pattern, 'w')
      let lnum = line('.')
      if lnum == start_lnum
        " Not found.
        call unite#print_error("unite: jump_list: Target position is not found.")
        call cursor(1, 1)
        return
      endif
    endwhile
  endif

  call s:open_current_line(a:is_highlight)
endfunction"}}}

function! s:best_winline()"{{{
  return max([1, winheight(0) * g:unite_kind_jump_list_after_jump_scroll / 100])
endfunction"}}}

function! s:adjust_scroll(best_winline)"{{{
  normal! zt
  let save_cursor = getpos('.')
  let winl = 1
  " Scroll the cursor line down.
  while winl <= a:best_winline
    let winl_prev = winl
    execute "normal! \<C-y>"
    let winl = winline()
    if winl == winl_prev
      break
    end
    let winl_prev = winl
  endwhile
  if winl > a:best_winline
    execute "normal! \<C-e>"
  endif
  call setpos('.', save_cursor)
endfunction"}}}

function! s:open_current_line(is_highlight)"{{{
  normal! zv
  normal! zz
  if a:is_highlight
    execute 'match Search /\%'.line('.').'l/'
  endif
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
