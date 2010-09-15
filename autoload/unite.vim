"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 14 Sep 2010
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
" Version: 0.5, for Vim 7.0
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
let s:args = {}

call unite#set_dictionary_helper(g:unite_substitute_patterns, '^\~', substitute($HOME, '\\', '/', 'g'))
"}}}

" Helper functions."{{{
function! unite#get_unite_candidates()"{{{
  return s:unite.candidates
endfunction"}}}
function! unite#available_sources_name()"{{{
  return map(unite#available_sources_list(), 'v:val.name')
endfunction"}}}
function! unite#available_sources_list()"{{{
  return sort(values(s:unite.sources), 's:compare')
endfunction"}}}
function! unite#available_sources(...)"{{{
  return a:0 == 0 ? s:unite.sources : s:unite.sources[a:1]
endfunction"}}}
function! unite#available_kinds(...)"{{{
  return a:0 == 0 ? s:unite.kinds : s:unite.kinds[a:1]
endfunction"}}}
function! unite#escape_match(str)"{{{
  return escape(a:str, '~"\.$[]')
endfunction"}}}
function! unite#complete_source(arglead, cmdline, cursorpos)"{{{
  " Unique.
  let l:dict = {}
  for l:source in map(split(globpath(&runtimepath, 'autoload/unite/sources/*.vim'), '\n'), 'fnamemodify(v:val, ":t:r")')
    if !has_key(l:dict, l:source)
      let l:dict[l:source] = 1
    endif
  endfor
  
  return filter(keys(l:dict), printf('stridx(v:val, %s) == 0', string(a:arglead)))
endfunction"}}}
function! unite#set_default(var, val)  "{{{
  if !exists(a:var) || type({a:var}) != type(a:val)
    let {a:var} = a:val
  endif
endfunction"}}}
function! unite#invalidate_cache(source_name)  "{{{
  let s:unite.sources[a:source_name].unite__is_invalidate = 1
endfunction"}}}
function! unite#force_redraw() "{{{
  call s:redraw(1)
endfunction"}}}
function! unite#redraw() "{{{
  call s:redraw(0)
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
  return filter(copy(s:unite.candidates), 'v:val.unite__is_marked')
endfunction"}}}
function! unite#keyword_filter(list, input)"{{{
  for l:cur_keyword_str in split(a:input, '\\\@<! ')
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

function! unite#start(sources, ...)"{{{
  let s:old_winnr = winnr()
  
  " Save args.
  let s:args = a:0 > 1 ? a:1 : {}
  if !has_key(s:args, 'input')
    let s:args.input = ''
  endif
  if !has_key(s:args, 'is_insert')
    let s:args.is_insert = 0
  endif
  
  " Open or create the unite buffer.
  let v:errmsg = ''
  execute g:unite_split_rule 
        \ g:unite_enable_split_vertically ?
        \        (bufexists(s:unite_bufnr) ? 'vsplit' : 'vnew')
        \      : (bufexists(s:unite_bufnr) ? 'split' : 'new')
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

  if !g:unite_enable_split_vertically
    20 wincmd _
  endif
  
  " Initialize sources.
  call s:initialize_sources(a:sources)
  " Initialize kinds.
  call s:initialize_kinds()
  
  " User's initialization.
  setlocal nomodifiable
  setfiletype unite

  setlocal modifiable

  silent % delete _
  call setline(s:LNUM_STATUS, 'Sources: ' . join(a:sources, ', '))
  call setline(s:LNUM_PATTERN, '>' . s:args.input)
  execute s:LNUM_PATTERN

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
  let s:unite.sources = {}
  let s:unite.candidates = []
  let s:unite.cached_candidates = {}
  
  let l:all_sources = {}
  for l:source_name in map(split(globpath(&runtimepath, 'autoload/unite/sources/*.vim'), '\n'),
        \ 'fnamemodify(v:val, ":t:r")')
    let l:all_sources[l:source_name] = 1
  endfor
  
  let l:number = 0
  for l:source_name in a:sources
    if !has_key(l:all_sources, l:source_name)
      echoerr 'Invalid source name "' . l:source_name . '" is detected.'
      return
    endif
      
    let l:source = call('unite#sources#' . l:source_name . '#define', [])
    if !has_key(s:unite.sources, l:source_name)
      if !has_key(l:source, 'is_volatile')
        let l:source.is_volatile = 0
      endif
      let l:source.unite__is_invalidate = 1
      
      let l:source.unite__number = l:number
      let l:number += 1
      
      let s:unite.sources[l:source_name] = l:source
    endif
  endfor
endfunction"}}}
function! s:initialize_kinds()"{{{
  " Gathering all kinds name.
  let s:unite.kinds = {}
  for l:kind_name in map(split(globpath(&runtimepath, 'autoload/unite/kinds/*.vim'), '\n'),
        \ 'fnamemodify(v:val, ":t:r")')
    let l:kind = call('unite#kinds#' . l:kind_name . '#define', [])
    if !has_key(s:unite.kinds, l:kind_name)
      let s:unite.kinds[l:kind_name] = l:kind
    endif
  endfor
endfunction"}}}
function! s:gather_candidates(text, args)"{{{
  " Save options.
  let l:ignorecase_save = &ignorecase

  if g:unite_enable_smart_case && a:text =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase = g:unite_enable_ignore_case
  endif
  
  let l:args = a:args
  let l:input_list = filter(split(a:text, '\\\@<! ', 1), 'v:val !~ "!"')
  let l:args.input = empty(l:input_list) ? '' : l:input_list[0]
  
  let l:candidates = []
  for l:source in unite#available_sources_list()
    if l:source.is_volatile
          \ || has_key(s:unite.cached_candidates, l:source.name)
          \ || (l:args.is_force && l:source.unite__is_invalidate)
      " Check required pattern length.
      let l:source_candidates = 
            \ (has_key(l:source, 'required_pattern_length')
            \   && len(l:args.input) < l:source.required_pattern_length) ?
            \ [] : l:source.gather_candidates(l:args)

      if l:args.input != ''
        call unite#keyword_filter(l:candidates, l:args.input)
      elseif !l:source.is_volatile
        " Recaching.
        let s:unite.cached_candidates[l:source.name] = l:source_candidates
      endif
    else
      let l:source_candidates = s:unite.cached_candidates[l:source.name]
    endif
    
    if a:text != ''
      call unite#keyword_filter(l:source_candidates, a:text)
    endif
    
    if has_key(l:source, 'max_candidates') && l:source.max_candidates != 0
      " Filtering too many candidates.
      let l:source_candidates = l:source_candidates[: l:source.max_candidates - 1]
    endif
    
    let l:candidates += l:source_candidates
  endfor

  let &ignorecase = l:ignorecase_save
  
  for l:candidate in l:candidates
    let l:candidate.unite__is_marked = 0
  endfor

  return l:candidates
endfunction"}}}
function! s:convert_lines(candidates)"{{{
  let l:max_width = winwidth(0) - 20
  return map(copy(a:candidates),
        \ '(v:val.unite__is_marked ? "* " : "- ") . unite#util#truncate_smart(has_key(v:val, "abbr")? v:val.abbr : v:val.word, ' . l:max_width .  ', 25, "..") . " " . v:val.source')
endfunction"}}}
function! s:convert_line(candidate)"{{{
  let l:max_width = winwidth(0) - 20
  return (a:candidate.unite__is_marked ? '* ' : '- ')
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

function! s:redraw(is_force) "{{{
  if &filetype !=# 'unite'
    return
  endif
  
  if mode() !=# 'i'
    setlocal modifiable
  endif

  let l:input = getline(2)[1:]
  for [l:pattern, l:subst] in items(g:unite_substitute_patterns)
    let l:input = substitute(l:input, l:pattern, l:subst, 'g')
  endfor

  let l:args = s:args
  let l:args.is_force = a:is_force
  let l:candidates = s:gather_candidates(l:input, l:args)
  let l:lines = s:convert_lines(l:candidates)
  if len(l:lines) < len(s:unite.candidates)
    if mode() !=# 'i' && line('.') == 2
      silent! 3,$delete _
      startinsert!
    else
      let l:pos = getpos('.')
      silent! 3,$delete _
      call setpos('.', l:pos)
    endif
  endif
  call setline(3, l:lines)

  let s:unite.candidates = l:candidates

  if mode() !=# 'i'
    setlocal nomodifiable
  endif
endfunction"}}}
function! s:compare(source_a, source_b) "{{{
  return a:source_a.unite__number - a:source_b.unite__number
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
    
    if !s:args.is_insert
      stopinsert
    endif
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

  let l:input = getline(2)[1:]
  for [l:pattern, l:subst] in items(g:unite_substitute_patterns)
    let l:input = substitute(l:input, l:pattern, l:subst, 'g')
  endfor
  let l:input_list = split(substitute(unite#escape_match(l:input), '\*', '[^/]*', 'g'), '\\\@<! ')
  call filter(l:input_list, 'v:val !~ "^!"')
  execute 'match IncSearch' string(join(l:input_list, '\|'))
endfunction"}}}
function! s:on_cursor_hold()  "{{{
  " Force redraw.
  call unite#force_redraw()
endfunction"}}}

" vim: foldmethod=marker
