"=============================================================================
" FILE: handlers.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 12 Jan 2014.
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

function! unite#handlers#_on_insert_enter()  "{{{
  let unite = unite#get_current_unite()
  let unite.is_insert = 1

  if &filetype ==# 'unite'
    setlocal modifiable
  endif
endfunction"}}}
function! unite#handlers#_on_insert_leave()  "{{{
  let unite = unite#get_current_unite()

  if line('.') != unite.prompt_linenr
    normal! 0
  endif

  let unite.is_insert = 0

  if &filetype ==# 'unite'
    setlocal nomodifiable
  endif
endfunction"}}}
function! unite#handlers#_on_cursor_hold_i()  "{{{
  let unite = unite#get_current_unite()

  call s:change_highlight()

  if unite.max_source_candidates > unite.redraw_hold_candidates
    call s:check_redraw()
  endif

  if unite.is_async && &l:modifiable
    " Ignore key sequences.
    call feedkeys("a\<BS>", 'n')
    " call feedkeys("\<C-r>\<ESC>", 'n')
  endif
endfunction"}}}
function! unite#handlers#_on_cursor_moved_i()  "{{{
  let unite = unite#get_current_unite()
  let prompt_linenr = unite.prompt_linenr

  if unite.max_source_candidates <= unite.redraw_hold_candidates
    call s:check_redraw()
  endif

  " Prompt check.
  if line('.') == prompt_linenr && col('.') <= len(unite.prompt)
    startinsert!
  endif
endfunction"}}}
function! unite#handlers#_on_bufwin_enter(bufnr)  "{{{
  let unite = getbufvar(a:bufnr, 'unite')
  if type(unite) != type({})
        \ || bufwinnr(a:bufnr) < 1
    return
  endif

  if bufwinnr(a:bufnr) != winnr()
    let winnr = winnr()
    execute bufwinnr(a:bufnr) 'wincmd w'
  endif

  call unite#handlers#_save_updatetime()

  call s:restore_statusline()

  if !unite.context.no_split && winnr('$') != 1
    call unite#view#_resize_window()
  endif

  setlocal nomodified

  if exists('winnr')
    execute winnr.'wincmd w'
  endif

  call unite#init#_tab_variables()
  let t:unite.last_unite_bufnr = a:bufnr
endfunction"}}}
function! unite#handlers#_on_cursor_hold()  "{{{
  let is_async = 0

  call s:restore_statusline()

  if &filetype ==# 'unite'
    " Redraw.
    call unite#redraw()
    call s:change_highlight()

    let unite = unite#get_current_unite()
    let is_async = unite.is_async

    if !unite.is_async && unite.context.auto_quit
      call unite#force_quit_session()
    endif
  else
    " Search other unite window.
    for winnr in filter(range(1, winnr('$')),
          \ "getbufvar(winbufnr(v:val), '&filetype') ==# 'unite'")
      let unite = getbufvar(winbufnr(winnr), 'unite')
      if unite.is_async
        " Redraw unite buffer.
        call unite#redraw(winnr)

        let is_async = unite.is_async
      endif
    endfor
  endif

  if is_async
    " Ignore key sequences.
    call feedkeys("g\<ESC>", 'n')
  endif
endfunction"}}}
function! unite#handlers#_on_cursor_moved()  "{{{
  if &filetype !=# 'unite'
    return
  endif

  let unite = unite#get_current_unite()
  let prompt_linenr = unite.prompt_linenr
  let context = unite.context

  if line('.') == prompt_linenr && !&l:modifiable
    setlocal modifiable
  endif
  if line('.') != prompt_linenr && &l:modifiable
    setlocal nomodifiable
  endif

  if line('.') <= prompt_linenr
    nnoremap <silent><buffer> <Plug>(unite_loop_cursor_up)
          \ :call unite#mappings#loop_cursor_up_call(
          \    0, 'n')<CR>
    nnoremap <silent><buffer> <Plug>(unite_skip_cursor_up)
          \ :call unite#mappings#loop_cursor_up_call(
          \    1, 'n')<CR>
    inoremap <silent><buffer> <Plug>(unite_select_previous_line)
          \ <ESC>:call unite#mappings#loop_cursor_up_call(
          \    0, 'i')<CR>
    inoremap <silent><buffer> <Plug>(unite_skip_previous_line)
          \ <ESC>:call unite#mappings#loop_cursor_up_call(
          \    1, 'i')<CR>
  else
    nnoremap <expr><buffer> <Plug>(unite_loop_cursor_up)
          \ unite#mappings#loop_cursor_up_expr(0)
    nnoremap <expr><buffer> <Plug>(unite_skip_cursor_up)
          \ unite#mappings#loop_cursor_up_expr(1)
    inoremap <expr><buffer> <Plug>(unite_select_previous_line)
          \ unite#mappings#loop_cursor_up_expr(0)
    inoremap <expr><buffer> <Plug>(unite_skip_previous_line)
          \ unite#mappings#loop_cursor_up_expr(1)
  endif

  if exists('b:current_syntax') && !context.no_cursor_line
    match

    if line('.') <= prompt_linenr+1 || mode('.') == 'i' ||
          \ split(reltimestr(reltime(unite.cursor_line_time)))[0] > '0.10'
      call s:set_cursor_line()
    endif
    let unite.cursor_line_time = reltime()
  endif

  if context.auto_preview
    call unite#view#_do_auto_preview()
  endif
  if context.auto_highlight
    call unite#view#_do_auto_highlight()
  endif

  call s:restore_statusline()

  " Check lines. "{{{
  if !context.auto_resize &&
        \ winheight(0) < line('$') && line('.') + winheight(0) < line('$')
    return
  endif

  let height =
        \ (unite.context.no_split
        \  || unite.context.winheight == 0) ?
        \ winheight(0) : unite.context.winheight
  let candidates = unite#candidates#_gather_pos(height)
  if !context.auto_resize && empty(candidates)
    " Nothing.
    return
  endif

  call unite#view#_resize_window()

  let modifiable_save = &l:modifiable
  try
    setlocal modifiable
    let lines = unite#view#_convert_lines(candidates)
    let pos = getpos('.')
    silent! call append('$', lines)
  finally
    let &l:modifiable = l:modifiable_save
  endtry

  let context = unite.context
  let unite.current_candidates += candidates

  if pos != getpos('.')
    call setpos('.', pos)
  endif"}}}
endfunction"}}}
function! unite#handlers#_on_buf_unload(bufname)  "{{{
  match

  " Save unite value.
  let unite = getbufvar(a:bufname, 'unite')
  if type(unite) != type({})
    " Invalid unite.
    return
  endif

  if unite.is_finalized
    return
  endif

  " Restore options.
  if has_key(unite, 'redrawtime_save')
    let &redrawtime = unite.redrawtime_save
  endif
  let &sidescrolloff = unite.sidescrolloff_save

  call unite#handlers#_restore_updatetime()

  " Call finalize functions.
  call unite#helper#call_hook(unite#loaded_sources_list(), 'on_close')
  let unite.is_finalized = 1
endfunction"}}}
function! unite#handlers#_on_insert_char_pre()  "{{{
  let prompt_linenr = unite#get_current_unite().prompt_linenr

  if line('.') <= prompt_linenr
    return
  endif

  call cursor(prompt_linenr, 0)
  startinsert!
  call unite#handlers#_on_cursor_moved()
endfunction"}}}

function! s:change_highlight()  "{{{
  if &filetype !=# 'unite'
        \ || !exists('b:current_syntax')
    return
  endif

  let unite = unite#get_current_unite()
  if empty(unite)
    return
  endif

  let context = unite#get_context()
  let prompt_linenr = unite.prompt_linenr
  if !context.no_cursor_line
    call s:set_cursor_line()
  endif

  silent! syntax clear uniteCandidateInputKeyword

  if !context.is_changed || unite#helper#get_input() == ''
    return
  endif

  syntax case ignore

  for input_str in unite#helper#get_substitute_input(
        \ unite#helper#get_input())
    let input_list = map(filter(split(input_str, '\\\@<! '),
          \ "v:val !~ '^[!:]'"),
          \ "substitute(v:val, '\\\\ ', ' ', 'g')")

    for source in filter(copy(unite.sources), "v:val.syntax != ''")
      for matcher in filter(copy(map(filter(
            \ copy(source.filters),
            \ "type(v:val) == type('')"), 'unite#get_filters(v:val)')),
            \ "has_key(v:val, 'pattern')")
        let patterns = map(copy(input_list),
              \ "escape(matcher.pattern(v:val), '/~')")

        silent! execute 'syntax match uniteCandidateInputKeyword'
              \ '/'.join(patterns, '\|').'/'
              \ 'containedin='.source.syntax.' contained'
      endfor
    endfor
  endfor

  syntax case match
endfunction"}}}
function! unite#handlers#_save_updatetime()  "{{{
  let unite = unite#get_current_unite()

  if unite.is_async && &updatetime > unite.context.update_time
    let unite.update_time_save = &updatetime
    let &updatetime = unite.context.update_time
  endif
endfunction"}}}
function! unite#handlers#_restore_updatetime()  "{{{
  let unite = unite#get_current_unite()

  if !has_key(unite, 'update_time_save')
    return
  endif

  if &updatetime < unite.update_time_save
    let &updatetime = unite.update_time_save
  endif
endfunction"}}}
function! s:restore_statusline()  "{{{
  if &filetype !=# 'unite' || !g:unite_force_overwrite_statusline
    return
  endif

  let unite = unite#get_current_unite()

  if &l:statusline != unite.statusline
    " Restore statusline.
    let &l:statusline = unite.statusline
  endif
endfunction"}}}

function! s:check_redraw() "{{{
  let unite = unite#get_current_unite()
  let prompt_linenr = unite.prompt_linenr
  if line('.') == prompt_linenr || unite.context.is_redraw
    " Redraw.
    call unite#redraw()
    call s:change_highlight()
  endif
endfunction"}}}
function! s:set_cursor_line()
  let unite = unite#get_current_unite()
  let prompt_linenr = unite.prompt_linenr
  let context = unite.context

  execute 'match' (line('.') <= prompt_linenr ?
        \ line('$') <= prompt_linenr ?
        \ 'uniteError /^\%'.prompt_linenr.'l.*/' :
        \ context.cursor_line_highlight.' /^\%'.(prompt_linenr+1).'l.*/' :
        \ context.cursor_line_highlight.' /^\%'.line('.').'l.*/')
  let unite.cursor_line_time = reltime()
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
