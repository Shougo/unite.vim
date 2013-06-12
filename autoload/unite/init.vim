"=============================================================================
" FILE: init.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 12 Jun 2013.
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

function! unite#init#_context(context, ...) "{{{
  let source_names = get(a:000, 0, [])

  let profile_name = get(a:context, 'profile_name',
        \ ((len(source_names) == 1 && !has_key(a:context, 'buffer_name')) ?
        \    'source/' . source_names[0] :
        \    get(a:context, 'buffer_name', 'default')))

  " Overwrite default_context by profile context.
  let default_context = extend(copy(unite#variables#default_context()),
        \ unite#custom#get_profile(profile_name, 'context'))

  let context = extend(default_context, a:context)

  if context.temporary || context.script
    " User can overwrite context by profile context.
    let context = extend(context,
          \ unite#custom#get_profile(profile_name, 'context'))
  endif

  " Complex initializer.
  if get(context, 'complete', 1) && !has_key(a:context, 'start_insert')
    let context.start_insert = 1
  endif
  if get(context, 'no_start_insert', 0)
    " Disable start insert.
    let context.start_insert = 0
  endif
  if has_key(context, 'horizontal')
    " Disable vertically.
    let context.vertical = 0
  endif
  if context.immediately
    " Ignore empty unite buffer.
    let context.no_empty = 1
  endif
  if !has_key(context, 'short_source_names')
    let context.short_source_names = g:unite_enable_short_source_names
  endif
  if get(context, 'long_source_names', 0)
    " Disable short name.
    let context.short_source_names = 0
  endif
  if &l:modified && !&l:hidden
    " Split automatically.
    let context.no_split = 0
  endif
  if !has_key(a:context, 'buffer_name') && context.script
    " Set buffer-name automatically.
    let context.buffer_name = join(source_names)
  endif

  let context.is_changed = 0

  return context
endfunction"}}}

function! unite#init#_unite_buffer() "{{{
  let current_unite = unite#variables#current_unite()
  let is_bufexists = bufexists(current_unite.real_buffer_name)
  let current_unite.context.real_buffer_name =
        \ current_unite.real_buffer_name

  call unite#view#_switch_unite_buffer(
        \ current_unite.buffer_name, current_unite.context)

  let b:unite = current_unite
  let unite = unite#get_current_unite()

  let unite.bufnr = bufnr('%')

  " Note: If unite buffer initialize is incomplete, &modified or &modifiable.
  if !is_bufexists || &modified || &modifiable
    " Basic settings.
    setlocal bufhidden=hide
    setlocal buftype=nofile
    setlocal nolist
    setlocal nobuflisted
    setlocal noswapfile
    setlocal noreadonly
    setlocal nofoldenable
    setlocal nomodeline
    setlocal nonumber
    setlocal foldcolumn=0
    setlocal iskeyword+=-,+,\\,!,~
    setlocal matchpairs-=<:>
    setlocal completefunc=
    setlocal omnifunc=
    match
    if has('conceal')
      setlocal conceallevel=3
      setlocal concealcursor=n
    endif
    if exists('+cursorcolumn')
      setlocal nocursorcolumn
    endif
    if exists('+colorcolumn')
      setlocal colorcolumn=0
    endif

    " Autocommands.
    augroup plugin-unite
      autocmd InsertEnter <buffer>
            \ call unite#handlers#_on_insert_enter()
      autocmd InsertLeave <buffer>
            \ call unite#handlers#_on_insert_leave()
      autocmd CursorHoldI <buffer>
            \ call unite#handlers#_on_cursor_hold_i()
      autocmd CursorMovedI <buffer>
            \ call unite#handlers#_on_cursor_moved_i()
      autocmd CursorMoved,CursorMovedI <buffer>  nested
            \ call unite#handlers#_on_cursor_moved()
      autocmd BufUnload,BufHidden <buffer>
            \ call unite#handlers#_on_buf_unload(expand('<afile>'))
      autocmd WinEnter,BufWinEnter <buffer>
            \ call unite#handlers#_on_bufwin_enter(bufnr(expand('<abuf>')))
      autocmd WinLeave,BufWinLeave <buffer>
            \ call unite#handlers#_restore_updatetime()
    augroup END

    call unite#mappings#define_default_mappings()
  endif

  let &l:wrap = unite.context.wrap

  if exists('&redrawtime')
    " Save redrawtime
    let unite.redrawtime_save = &redrawtime
    let &redrawtime = 100
  endif

  call unite#handlers#_save_updatetime()

  " User's initialization.
  setlocal nomodifiable
  set sidescrolloff=0
  setlocal nocursorline
  setfiletype unite
endfunction"}}}

function! unite#init#_candidates(candidates) "{{{
  let unite = unite#get_current_unite()
  let context = unite.context
  let [max_width, max_source_name] =
        \ unite#helper#adjustments(winwidth(0)-5, unite.max_source_name, 2)
  let is_multiline = 0

  let candidates = []
  for candidate in a:candidates
    let candidate.unite__abbr =
          \ get(candidate, 'abbr', candidate.word)

    " Delete too long abbr.
    if !&l:wrap && (candidate.is_multiline || context.multi_line)
      let candidate.unite__abbr =
            \ candidate.unite__abbr[: max_width *
            \  (context.max_multi_lines + 1)+10]
    elseif len(candidate.unite__abbr) > max_width * 2 && !context.wrap
      let candidate.unite__abbr =
            \ candidate.unite__abbr[: max_width * 2]
    endif

    " Substitute tab.
    if candidate.unite__abbr =~ '\t'
      let candidate.unite__abbr = substitute(
            \ candidate.unite__abbr, '\t',
            \ repeat(' ', &tabstop), 'g')
    endif

    if !candidate.is_multiline && !context.multi_line
      call add(candidates, candidate)
      continue
    endif

    if candidate.unite__abbr !~ '\n'
      " Auto split.
      let abbr = candidate.unite__abbr
      let candidate.unite__abbr = ''

      while abbr !~ '^\s\+$'
        let trunc_abbr = unite#util#strwidthpart(
              \ abbr, max_width)
        let candidate.unite__abbr .= trunc_abbr . "~\n"
        let abbr = '  ' . abbr[len(trunc_abbr):]
      endwhile

      let candidate.unite__abbr =
            \ substitute(candidate.unite__abbr,
            \    '\~\n$', '', '')
    else
      let candidate.unite__abbr =
            \ substitute(candidate.unite__abbr,
            \    '\r\?\n$', '^@', '')
    endif

    if candidate.unite__abbr !~ '\n'
      let candidate.is_multiline = 0
      call add(candidates, candidate)
      continue
    endif

    " Convert multi line.
    let cnt = 0
    for multi in split(
          \ candidate.unite__abbr, '\r\?\n', 1)[:
          \   context.max_multi_lines-1]
      let candidate_multi = (cnt != 0) ?
            \ deepcopy(candidate) : candidate
      let candidate_multi.unite__abbr =
            \ (cnt == 0 ? '+ ' : '| ') . multi

      if cnt != 0
        let candidate_multi.is_dummy = 1
      endif

      let is_multiline = 1
      call add(candidates, candidate_multi)

      let cnt += 1
    endfor
  endfor

  " Multiline check.
  if is_multiline || context.multi_line
    for candidate in filter(copy(candidates), '!v:val.is_multiline')
      let candidate.unite__abbr = '  ' . candidate.unite__abbr
    endfor

    let unite.is_multi_line = 1
  endif

  return candidates
endfunction"}}}

function! unite#init#_tab_variables() "{{{
  if !exists('t:unite')
    let t:unite = { 'last_unite_bufnr' : -1 }
  endif
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
