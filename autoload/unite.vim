"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 Aug 2010
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
" Version: 0.1, for Vim 7.0
"=============================================================================

" Constants"{{{

let s:FALSE = 0
let s:TRUE = !s:FALSE

let s:LNUM_STATUS = 1
let s:LNUM_PATTERN = 2

let s:INVALID_BUFNR = -2357
let s:INVALID_COLUMN = -20091017

if has('win16') || has('win32') || has('win64')  " on Microsoft Windows
  let s:unite_BUFFER_NAME = '[unite]'
else
  let s:unite_BUFFER_NAME = '*unite*'
endif
"}}}

" Variables  "{{{
" buffer number of the unite buffer
let s:unite_bufnr = s:INVALID_BUFNR
let s:update_time_save = &updatetime
let s:unite = {}
let s:is_invalidate = 0
"}}}

" Helper functions."{{{
function! unite#get_unite_candidates()"{{{
  return s:unite.candidates
endfunction"}}}
function! unite#available_sources(...)"{{{
  return a:0 == 0 ? s:unite.sources_dict : s:unite.sources_dict[a:1]
endfunction"}}}
function! unite#escape_match(str)"{{{
  return escape(a:str, '~" \.^$[]')
endfunction"}}}
function! unite#complete_source(arglead, cmdline, cursorpos)"{{{
  return filter(map(split(globpath(&runtimepath, 'autoload/unite/sources/*.vim'), '\n'), 'fnamemodify(v:val, ":t:r")')
        \ , printf('v:val =~ "^%s"', a:arglead))
endfunction"}}}
function! unite#set_default(var, val)  "{{{
  if !exists(a:var) || type({a:var}) != type(a:val)
    let {a:var} = a:val
  endif
endfunction"}}}
function! unite#invalidate_cache(source_name)  "{{{
  let s:is_invalidate = 1
endfunction"}}}
function! unite#force_redraw() "{{{
  if mode() !=# 'i'
    setlocal modifiable
  endif

  let l:cur_text = getline(2)[1:]
  let l:candidates = s:gather_candidates({}, l:cur_text)
  let l:lines = s:convert_lines(l:candidates)
  if len(l:lines) < len(s:unite.candidates)
    let l:pos = getpos('.')
    silent! 3,$delete _
    call setpos('.', l:pos)
  endif
  call setline(3, l:lines)

  let s:unite.candidates = l:candidates

  let s:is_invalidate = 0

  if mode() !=# 'i'
    setlocal nomodifiable
  endif
endfunction"}}}
function! unite#redraw() "{{{
  if s:is_invalidate
    call unite#force_redraw()
  elseif &filetype ==# 'unite'
    " Redraw marks.
    if mode() !=# 'i'
      setlocal modifiable
    endif
    
    call setline(3, s:convert_lines(s:unite.candidates))

    if mode() !=# 'i'
      setlocal nomodifiable
    endif
  endif
endfunction"}}}
function! unite#redraw_current_line() "{{{
  if line('.') <= 2 || &filetype !=# 'unite'
    " Ignore.
    return
  endif

  setlocal modifiable

  let l:candidate = unite#get_unite_candidates()[line('.') - 3]
  call setline('.', s:convert_line(l:candidate))

  setlocal nomodifiable
endfunction"}}}
function! unite#get_marked_candidates() "{{{
  return filter(copy(s:unite.candidates), 'v:val.is_marked')
endfunction"}}}
"}}}

function! unite#start(sources, cur_text)"{{{
  " Open or create the unite buffer.
  let v:errmsg = ''
  execute 'topleft' (bufexists(s:unite_bufnr) ? 'split' : 'new')
  if v:errmsg != ''
    return s:FALSE
  endif
  if bufexists(s:unite_bufnr)
    silent execute s:unite_bufnr 'buffer'
  else
    let s:unite_bufnr = bufnr('')
    call s:initialize_unite_buffer()
  endif

  " Save redrawtime
  let s:redrawtime_save = &redrawtime
  let &redrawtime = 500

  let s:is_invalidate = 0

  20 wincmd _
  
  " Initialize sources.
  call s:initialize_sources(a:sources)

  setlocal modifiable
  silent % delete _
  call setline(s:LNUM_STATUS, 'Sources: ' . join(a:sources, ', '))
  call setline(s:LNUM_PATTERN, '>' . a:cur_text)
  execute s:LNUM_PATTERN
  setlocal nomodifiable

  call unite#force_redraw()

  3
  normal! 0z.

  return s:TRUE
endfunction"}}}

function! s:initialize_sources(sources)"{{{
  let s:unite.sources = []
  let s:unite.sources_dict = {}
  for l:source_name in a:sources
    let l:source = call('unite#sources#' . l:source_name . '#define', [])
    if !has_key(s:unite.sources_dict, l:source_name)
      let s:unite.sources_dict[l:source_name] = l:source
      call add(s:unite.sources, l:source)
    endif
  endfor
  let s:unite.candidates = []
endfunction"}}}
function! s:gather_candidates(args, text)"{{{
  let l:args = a:args
  let l:args.cur_text = a:text
  
  let l:candidates = []
  for l:source in s:unite.sources
    for l:candidate in l:source.gather_candidates(a:args)
      let l:candidate.is_marked = 0
      call add(l:candidates, l:candidate)
    endfor
  endfor

  if a:text != ''
    for l:pattern in split(a:text)
      call filter(l:candidates, 'stridx(v:val.word, ' . string(l:pattern) . ') != -1')
    endfor
  endif

  return l:candidates
endfunction"}}}
function! s:convert_lines(candidates)"{{{
  return map(copy(a:candidates),
        \ '(v:val.is_marked ? "* " : "- ") . unite#util#truncate(has_key(v:val, "abbr")? v:val.abbr : v:val.word, 80) . " " . v:val.source')
endfunction"}}}
function! s:convert_line(candidate)"{{{
  return (a:candidate.is_marked ? '* ' : '- ')
        \ . unite#util#truncate(has_key(a:candidate, 'abbr')? a:candidate.abbr : a:candidate.word, 80)
        \ . " " . a:candidate.source
endfunction"}}}

function! s:initialize_unite_buffer()"{{{
  " The current buffer is initialized.
  let s:unite = {}

  " Basic settings.
  setlocal number
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal nobuflisted
  setlocal noswapfile
  setlocal nomodifiable
  setlocal nofoldenable
  setlocal foldcolumn=0
  silent! file `=s:unite_BUFFER_NAME`

  " Autocommands.
  augroup plugin-unite
    autocmd InsertEnter <buffer>  call s:on_insert_enter()
    autocmd InsertLeave <buffer>  call s:on_insert_leave()
    autocmd CursorHoldI <buffer>  call s:on_cursor_hold()
    autocmd WinLeave <buffer>  call unite#quit_session()
    " autocmd TabLeave <buffer>  call unite#quit_session()  " not necessary
  augroup END

  call unite#mappings#define_default_mappings()

  if exists(':NeoComplCacheLock')
    " Lock neocomplcache.
    NeoComplCacheLock
  endif

  " User's initialization.
  setfiletype unite

  return
endfunction"}}}

function! unite#quit_session()  "{{{
  call unite#leave_buffer()
endfunction"}}}
function! unite#leave_buffer()  "{{{
  if &filetype ==# 'unite'
    let &redrawtime = s:redrawtime_save
    let l:cwd = getcwd()
    if winnr('$') != 1
      close
    endif
    
    " Restore current directory.
    lcd `=l:cwd`
  endif
endfunction"}}}

" Autocmd events.
function! s:on_insert_enter()  "{{{
  if &updatetime > g:unite_update_time
    let s:update_time_save = &updatetime
    let &updatetime = g:unite_update_time
  endif
  
  setlocal modifiable
  if line('.') != 2 || col('.') == 1
    2
    startinsert!
  endif

  match
endfunction"}}}
function! s:on_insert_leave()  "{{{
  if &updatetime < s:update_time_save
    let &updatetime = s:update_time_save
  endif

  setlocal nomodifiable

  let l:cur_text = getline(2)[1:]
  execute 'match IncSearch' '"'.substitute(l:cur_text, ' ', '\\|', 'g').'"'
endfunction"}}}
function! s:on_cursor_hold()  "{{{
  " Force redraw.
  call unite#force_redraw()
endfunction"}}}

" vim: foldmethod=marker
