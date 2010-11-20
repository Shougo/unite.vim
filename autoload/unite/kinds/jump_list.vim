"=============================================================================
" FILE: jump_list.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 20 Nov 2010
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
  let g:unite_kind_jump_list_after_jump_scroll = 0.25
else
  " 0.0 <= x <= 1.0
  let g:unite_kind_jump_list_after_jump_scroll =
        \ min([max([0.0, g:unite_kind_jump_list_after_jump_scroll]), 1.0])
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
      \ 'description': 'jump to this position',
      \ 'is_selectable': 1,
      \ }
function! s:kind.action_table.open.func(candidates)"{{{
  for l:candidate in a:candidates
    " work around `scroll-to-top' problem on :edit %
    if l:candidate.action__path !=# expand('%:p')
      edit `=l:candidate.action__path`
    endif
    call s:jump(l:candidate)
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description': 'preview this position',
      \ 'is_selectable': 0,
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate)"{{{
  execute unite#context_winnr() . 'wincmd w'
  let l:save_pos  = getpos('.')
  let l:save_winl = winline()
  wincmd p
  pedit `=a:candidate.action__path`
  wincmd p
  call s:jump(a:candidate)
  wincmd p
  " work around `scroll-to-top' problem on :pedit %
  execute unite#context_winnr() . 'wincmd w'
  let l:pos  = getpos('.')
  if l:pos != l:save_pos
    call setpos('.', l:save_pos)
    call s:adjust_scroll(l:save_winl)
  endif
  wincmd p
endfunction"}}}

function! s:jump(candidate)"{{{
  if has_key(a:candidate, 'action__pattern') && a:candidate.action__pattern != ""
    " Jump by search()
    call search(a:candidate.action__pattern, 'w')
    if !has_key(a:candidate, 'action__signature')
      return
    endif
    let l:lnum0 = line('.')
    call search(a:candidate.action__pattern, 'w')
    let l:lnum = line('.')
    if l:lnum != l:lnum0
      " same pattern lines detected!!
      let l:source = unite#available_sources(a:candidate.source)
      let l:start_lnum = l:lnum
      while 1
        if l:source.signature(lnum) ==# a:candidate.action__signature
          " found
          break
        endif
        call search(a:candidate.action__pattern, 'w')
        let l:lnum = line('.')
        if l:lnum == l:start_lnum
          " not found
          call unite#print_error("unite: jump_list: target position not found")
          0
          return
        endif
      endwhile
    endif
  elseif has_key(a:candidate, 'action__line')
    " Jump to the line number.
    execute a:candidate.action__line
  else
    0
  endif
  normal! zv
  let l:best = max([1, float2nr(winheight(0) * g:unite_kind_jump_list_after_jump_scroll)])
  call s:adjust_scroll(l:best)
endfunction"}}}

function! s:adjust_scroll(best)"{{{
  normal! zz
  let l:save_pos = getpos('.')
  let l:winl = winline()
  let l:delta = l:winl - a:best
  let l:prev_winl = l:winl
  if l:delta > 0
    " scroll up
    while 1
      execute "normal! \<C-e>"
      let l:winl = winline()
      if l:winl < a:best || l:winl == l:prev_winl
        break
      end
      let l:prev_winl = l:winl
    endwhile
    execute "normal! \<C-y>"
  elseif l:delta < 0
    " scroll down
    while 1
      execute "normal! \<C-y>"
      let l:winl = winline()
      if l:winl > a:best || l:winl == l:prev_winl
        break
      end
      let l:prev_winl = l:winl
    endwhile
    execute "normal! \<C-e>"
  endif
  call setpos('.', l:save_pos)
endfunction"}}}
"}}}

" vim: foldmethod=marker
