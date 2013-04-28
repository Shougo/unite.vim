"=============================================================================
" FILE: jump_list.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Apr 2013.
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

function! unite#kinds#jump_list#define() "{{{
  let kind = {
        \ 'name' : 'jump_list',
        \ 'default_action' : 'open',
        \ 'action_table': {},
        \ 'alias_table' : { 'rename' : 'replace' },
        \ 'parents': ['openable'],
        \}

  " Actions "{{{
  let kind.action_table.open = {
        \ 'description' : 'jump to this position',
        \ 'is_selectable' : 1,
        \ }
  function! kind.action_table.open.func(candidates) "{{{
    for candidate in a:candidates
      let bufnr = s:open(candidate)
      call s:jump(candidate, 0)

      " Open folds.
      normal! zv
      call s:adjust_scroll(s:best_winline())

      call unite#remove_previewed_buffer_list(bufnr)
    endfor
  endfunction"}}}

  let kind.action_table.preview = {
        \ 'description' : 'preview this position',
        \ 'is_quit' : 0,
        \ }
  function! kind.action_table.preview.func(candidate) "{{{
    let filename = s:get_filename(a:candidate)
    let buflisted = buflisted(
          \ unite#util#escape_file_searching(filename))
    let preview_windows = filter(range(1, winnr('$')),
          \ 'getwinvar(v:val, "&previewwindow") != 0')
    if empty(preview_windows)
      pedit! `=filename`
      let preview_windows = filter(range(1, winnr('$')),
            \ 'getwinvar(v:val, "&previewwindow") != 0')
    endif

    let prev_winnr = winnr('#')
    let winnr = winnr()
    wincmd P
    let bufnr = s:open(a:candidate)
    call s:jump(a:candidate, 1)
    execute prev_winnr.'wincmd w'
    execute winnr.'wincmd w'

    if !buflisted
      call unite#add_previewed_buffer_list(bufnr)
    endif
  endfunction"}}}

  let kind.action_table.highlight = {
        \ 'description' : 'highlight this position',
        \ 'is_quit' : 0,
        \ }
  function! kind.action_table.highlight.func(candidate) "{{{
    let candidate_winnr = bufwinnr(s:get_bufnr(a:candidate))

    if candidate_winnr > 0
      let unite = unite#get_current_unite()
      let context = unite.context
      let current_winnr = winnr()

      if context.vertical 
          setlocal winfixwidth
      else 
          setlocal winfixheight
      endif

      noautocmd execute candidate_winnr 'wincmd w'

      call s:jump(a:candidate, 1)
      let unite_winnr = bufwinnr(unite.bufnr)
      if unite_winnr < 0
        let unite_winnr = current_winnr
      endif
      if unite_winnr > 0
        noautocmd execute unite_winnr 'wincmd w'
      endif
    endif
  endfunction"}}}


  let kind.action_table.replace = {
        \ 'description' : 'replace with qfreplace',
        \ 'is_selectable' : 1,
        \ }
  function! kind.action_table.replace.func(candidates) "{{{
    if globpath(&runtimepath, 'autoload/qfreplace.vim') == ''
      echo 'qfreplace.vim is not installed.'
      return
    endif

    let qflist = []
    for candidate in a:candidates
      if has_key(candidate, 'action__line')
            \ && has_key(candidate, 'action__text')
        let filename = s:get_filename(candidate)
        call add(qflist, {
              \ 'filename' : filename,
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

  return kind
endfunction"}}}

"}}}

" Misc.
function! s:jump(candidate, is_highlight) "{{{
  let line = get(a:candidate, 'action__line', 1)
  let pattern = get(a:candidate, 'action__pattern', '')

  if line !~ '^\d\+$'
    call unite#print_error('unite: jump_list: Invalid action__line format.')
    return
  endif

  if !has_key(a:candidate, 'action__pattern')
    " Jump to the line number.
    let col = get(a:candidate, 'action__col', 0)
    if col == 0
      if line('.') != line
        execute line
      endif
    else
      call cursor(line, col)
    endif

    call s:open_current_line(a:is_highlight)
    return
  endif

  " Jump by search().
  let source = unite#get_sources(a:candidate.source)
  if !(has_key(a:candidate, 'action__signature')
        \ && has_key(source, 'calc_signature'))
    " Not found signature.
    if line != '' && getline(line) =~# pattern
      if line('.') != line
        execute line
      endif
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
    while source.calc_signature(lnum) !=#
          \ a:candidate.action__signature
      call search(pattern, 'w')
      let lnum = line('.')
      if lnum == start_lnum
        " Not found.
        call unite#print_error(
              \ "unite: jump_list: Target position is not found.")
        call cursor(1, 1)
        return
      endif
    endwhile
  endif

  call s:open_current_line(a:is_highlight)
endfunction"}}}

function! s:best_winline() "{{{
  return max([1, winheight(0) * g:unite_kind_jump_list_after_jump_scroll / 100])
endfunction"}}}

function! s:adjust_scroll(best_winline) "{{{
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

function! s:open_current_line(is_highlight) "{{{
  normal! zv
  normal! zz
  if a:is_highlight
    execute 'match Search /\%'.line('.').'l/'
  endif
endfunction"}}}

function! s:open(candidate) "{{{
  let bufnr = s:get_bufnr(a:candidate)
  if bufnr != bufnr('%')
    if has_key(a:candidate, 'action__buffer_nr')
      execute 'buffer' bufnr
    else
      edit `=a:candidate.action__path`
    endif
  endif

  return bufnr
endfunction"}}}
function! s:get_filename(candidate) "{{{
  return has_key(a:candidate, 'action__path') ?
            \ a:candidate.action__path :
            \ bufname(a:candidate.action__buffer_nr)
endfunction"}}}
function! s:get_bufnr(candidate) "{{{
  return has_key(a:candidate, 'action__buffer_nr') ?
        \ a:candidate.action__buffer_nr :
        \ bufnr(unite#util#escape_file_searching(
        \     a:candidate.action__path))
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
