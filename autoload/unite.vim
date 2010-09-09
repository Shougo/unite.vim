"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 09 Sep 2010
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

function! unite#set_dictionary_helper(variable, keys, pattern)"{{{
  for key in split(a:keys, ',')
    if !has_key(a:variable, key) 
      let a:variable[key] = a:pattern
    endif
  endfor
endfunction"}}}

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
let s:old_winnr = s:INVALID_BUFNR
let s:update_time_save = &updatetime
let s:unite = {}
let s:is_invalidate = 0

call unite#set_dictionary_helper(g:unite_substitute_patterns, '^\~', substitute($HOME, '\\', '/', 'g'))
"}}}

" Helper functions."{{{
function! unite#get_unite_candidates()"{{{
  return s:unite.candidates
endfunction"}}}
function! unite#available_sources_name()"{{{
  return map(copy(s:unite.sources), 'v:val.name')
endfunction"}}}
function! unite#available_sources(...)"{{{
  return a:0 == 0 ? s:unite.sources_dict : s:unite.sources_dict[a:1]
endfunction"}}}
function! unite#escape_match(str)"{{{
  return escape(a:str, '~"\.$[]')
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
  for [l:pattern, l:subst] in items(g:unite_substitute_patterns)
    let l:cur_text = substitute(l:cur_text, l:pattern, l:subst, 'g')
  endfor
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
function! unite#keyword_filter(list, cur_text)"{{{
  for l:cur_keyword_str in split(a:cur_text, '\\\@<! ')
    if l:cur_keyword_str =~ '^!'
      " Exclusion.
      let l:cur_keyword_str = substitute(unite#escape_match(l:cur_keyword_str), '\*', '[^/]*', 'g')
      call filter(a:list, 'v:val.word !~ ' . string(l:cur_keyword_str[1:]))
    elseif l:cur_keyword_str =~ '[*]'
      " Wildcard.
      let l:cur_keyword_str = substitute(unite#escape_match(l:cur_keyword_str), '\*', '[^/]*', 'g')
      call filter(a:list, 'v:val.word =~ ' . string(l:cur_keyword_str))
    else
      let l:cur_keyword_str = substitute(l:cur_keyword_str, '\\ ', ' ', 'g')
      if &ignorecase
        let l:expr = printf('stridx(tolower(v:val.word), %s) != -1', string(tolower(l:cur_keyword_str)))
      else
        let l:expr = printf('stridx(v:val.word, %s) != -1', string(l:cur_keyword_str))
      endif

      call filter(a:list, l:expr)
    endif
  endfor

  return a:list
endfunction"}}}
"}}}

function! unite#start(sources, cur_text)"{{{
  let s:old_winnr = winnr()
  
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

  if exists('&redrawtime')
    " Save redrawtime
    let s:redrawtime_save = &redrawtime
    let &redrawtime = 500
  endif

  let s:is_invalidate = 0

  20 wincmd _
  
  " Initialize sources.
  call s:initialize_sources(a:sources)
  
  " Caching candidates.
  let s:unite.cached_candidates = s:caching_candidates({}, '')

  setlocal modifiable

  silent % delete _
  call setline(s:LNUM_STATUS, 'Sources: ' . join(a:sources, ', '))
  call setline(s:LNUM_PATTERN, '>' . a:cur_text)
  execute s:LNUM_PATTERN

  " User's initialization.
  setfiletype unite

  call unite#force_redraw()

  if g:unite_enable_start_insert
    2
    startinsert!
  else
    3
    normal! 0z.
  endif

  setlocal nomodifiable

  return s:TRUE
endfunction"}}}

function! s:initialize_sources(sources)"{{{
  " Gathering all sources name.
  let l:all_sources = {}
  for l:source_name in map(split(globpath(&runtimepath, 'autoload/unite/sources/*.vim'), '\n'),
        \ 'fnamemodify(v:val, ":t:r")')
    let l:all_sources[l:source_name] = 1
  endfor
  
  let s:unite.sources = []
  let s:unite.sources_dict = {}
  let s:unite.candidates = []
  for l:source_name in a:sources
    if !has_key(l:all_sources, l:source_name)
      echoerr 'Invalid source name "' . l:source_name . '" is detected.'
      return
    endif
      
    let l:source = call('unite#sources#' . l:source_name . '#define', [])
    if !has_key(s:unite.sources_dict, l:source_name)
      let s:unite.sources_dict[l:source_name] = l:source
      call add(s:unite.sources, l:source)
    endif
  endfor
endfunction"}}}
function! s:caching_candidates(args, text)"{{{
  " Save options.
  let l:ignorecase_save = &ignorecase

  if g:unite_enable_smart_case && a:text =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase = g:unite_enable_ignore_case
  endif
  
  let l:args = a:args
  let l:args.cur_text = a:text
  
  let l:cached = {}
  for l:source in filter(copy(s:unite.sources), '!has_key(v:val, "is_volatile") || !v:val.is_volatile')
    let l:candidates = []
    for l:candidate in l:source.gather_candidates(a:args)
      let l:candidate.is_marked = 0
      call add(l:candidates, l:candidate)
    endfor

    if a:text != ''
      call unite#keyword_filter(l:candidates, a:text)
    endif

    let l:cached[l:source.name] = l:candidates
  endfor

  let &ignorecase = l:ignorecase_save

  return l:cached
endfunction"}}}
function! s:gather_candidates(args, text)"{{{
  " Save options.
  let l:ignorecase_save = &ignorecase

  if g:unite_enable_smart_case && a:text =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase = g:unite_enable_ignore_case
  endif
  
  let l:args = a:args
  let l:cur_text_list = filter(split(a:text, '\\\@<! ', 1), 'v:val !~ "!"')
  let l:args.cur_text = empty(l:cur_text_list) ? '' : l:cur_text_list[0]
  
  let l:candidates = []
  for l:source in s:unite.sources
    let l:source_candidates = has_key(s:unite.cached_candidates, l:source.name) ?
          \ s:unite.cached_candidates[l:source.name] : l:source.gather_candidates(a:args)
    if has_key(l:source, 'max_candidates') && l:source.max_candidates != 0
      " Filtering too many candidates.
      let l:source_candidates = l:source_candidates[: l:source.max_candidates - 1]
    endif
    
    let l:candidates += l:source_candidates
  endfor

  if a:text != ''
    call unite#keyword_filter(l:candidates, a:text)
  endif

  let &ignorecase = l:ignorecase_save
  
  for l:candidate in l:candidates
    let l:candidate.is_marked = 0
  endfor

  return l:candidates
endfunction"}}}
function! s:convert_lines(candidates)"{{{
  let l:max_width = winwidth(0) - 20
  return map(copy(a:candidates),
        \ '(v:val.is_marked ? "* " : "- ") . unite#util#truncate_smart(has_key(v:val, "abbr")? v:val.abbr : v:val.word, ' . l:max_width .  ', 25, "..") . " " . v:val.source')
endfunction"}}}
function! s:convert_line(candidate)"{{{
  let l:max_width = winwidth(0) - 20
  return (a:candidate.is_marked ? '* ' : '- ')
        \ . unite#util#truncate_smart(has_key(a:candidate, 'abbr')? a:candidate.abbr : a:candidate.word, l:max_width, 25, '..')
        \ . " " . a:candidate.source
endfunction"}}}

function! s:initialize_unite_buffer()"{{{
  " The current buffer is initialized.
  let s:unite = {}

  silent! file `=s:unite_BUFFER_NAME`
  
  " Basic settings.
  setlocal number
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal nobuflisted
  setlocal noswapfile
  setlocal noreadonly
  setlocal nofoldenable
  setlocal foldcolumn=0

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

  return
endfunction"}}}

function! unite#quit_session()  "{{{
  call unite#leave_buffer()
endfunction"}}}
function! unite#leave_buffer()  "{{{
  if &filetype ==# 'unite'
    if exists('&redrawtime')
      let &redrawtime = s:redrawtime_save
    endif
    
    let l:cwd = getcwd()
    if winnr('$') != 1
      close
      execute s:old_winnr . 'wincmd w'
    endif
    
    " Restore current directory.
    lcd `=l:cwd`
    stopinsert
  endif
endfunction"}}}

" Autocmd events.
function! s:on_insert_enter()  "{{{
  if &eventignore =~# 'InsertEnter'
    return
  endif
  
  if &updatetime > g:unite_update_time
    let s:update_time_save = &updatetime
    let &updatetime = g:unite_update_time
  endif

  setlocal cursorline
  setlocal modifiable
  
  match
endfunction"}}}
function! s:on_insert_leave()  "{{{
  " Force redraw.
  call unite#force_redraw()
  
  if &updatetime < s:update_time_save
    let &updatetime = s:update_time_save
  endif

  setlocal nocursorline
  setlocal nomodifiable

  let l:cur_text = getline(2)[1:]
  for [l:pattern, l:subst] in items(g:unite_substitute_patterns)
    let l:cur_text = substitute(l:cur_text, l:pattern, l:subst, 'g')
  endfor
  let l:cur_text_list = split(substitute(unite#escape_match(l:cur_text), '\*', '[^/]*', 'g'), '\\\@<! ')
  call filter(l:cur_text_list, 'v:val !~ "^!"')
  execute 'match IncSearch' string(join(l:cur_text_list, '\|'))
endfunction"}}}
function! s:on_cursor_hold()  "{{{
  " Force redraw.
  call unite#force_redraw()
endfunction"}}}

" vim: foldmethod=marker
