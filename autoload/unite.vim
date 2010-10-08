"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 Oct 2010
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
" Version: 1.0, for Vim 7.0
"=============================================================================

function! unite#set_dictionary_helper(variable, keys, pattern)"{{{
  for key in split(a:keys, ',')
    if !has_key(a:variable, key) 
      let a:variable[key] = a:pattern
    endif
  endfor
endfunction"}}}
function! unite#set_substitute_pattern(buffer_name, pattern, subst, ...)"{{{
  let l:priority = a:0 > 0 ? a:1 : 0
  let l:buffer_name = (a:buffer_name == '' ? 'default' : a:buffer_name)

  if !has_key(s:substitute_pattern, l:buffer_name)
    let s:substitute_pattern[l:buffer_name] = {}
  endif

  if has_key(s:substitute_pattern[l:buffer_name], a:pattern)
        \ && a:pattern == ''
    call remove(s:substitute_pattern[l:buffer_name], a:pattern)
  else
    let s:substitute_pattern[l:buffer_name][a:pattern] = {
          \ 'pattern' : a:pattern,
          \ 'subst' : a:subst, 'priority' : l:priority
          \ }
  endif
endfunction"}}}

" Constants"{{{
let s:FALSE = 0
let s:TRUE = !s:FALSE

let s:LNUM_STATUS = 1
let s:LNUM_PATTERN = 2
"}}}

" Variables  "{{{
" buffer number of the unite buffer
let s:last_unite_bufnr = -1
let s:unite = {}

let s:default_sources = {}
let s:default_kinds = {}

let s:custom_sources = {}
let s:custom_kinds = {}

let s:substitute_pattern = {}
call unite#set_substitute_pattern('files', '^\~', substitute(substitute($HOME, '\\', '/', 'g'), ' ', '\\ ', 'g'), -100)
call unite#set_substitute_pattern('files', '[^~.*]\zs/', '*/*', 100)
"}}}

" Helper functions."{{{
function! unite#_take_action(action_name, candidate)"{{{
  let l:action_table = unite#get_action_table(a:candidate.source, a:candidate.kind)

  let l:action_name =
        \ a:action_name ==# 'default' ?
        \ unite#get_default_action(a:candidate.source, a:candidate.kind)
        \ : a:action_name

  if !has_key(l:action_table, a:action_name)
    return 'no such action ' . a:action_name
  endif

  return l:action_table[a:action_name].func(a:candidate)
endfunction"}}}
function! unite#is_win()"{{{
  return has('win16') || has('win32') || has('win64')
endfunction"}}}
function! unite#get_unite_candidates()"{{{
  return s:get_unite().candidates
endfunction"}}}
function! unite#available_sources_name()"{{{
  return map(unite#available_sources_list(), 'v:val.name')
endfunction"}}}
function! unite#available_sources_list()"{{{
  return sort(values(unite#available_sources()), 's:compare_sources')
endfunction"}}}
function! unite#available_sources(...)"{{{
  let l:unite = s:get_unite()
  return a:0 == 0 ? l:unite.sources : l:unite.sources[a:1]
endfunction"}}}
function! unite#available_kinds(...)"{{{
  let l:unite = s:get_unite()
  return a:0 == 0 ? l:unite.kinds : l:unite.kinds[a:1]
endfunction"}}}
function! unite#get_action_table(source_name, kind_name)"{{{
  let l:kind = unite#available_kinds(a:kind_name)
  let l:source = unite#available_sources(a:source_name)

  " Default actions.
  let l:action_table = (a:kind_name != 'common')?
        \ unite#available_kinds('common').action_table : {}

  let l:action_table = extend(copy(l:action_table), l:kind.action_table)

  if has_key(l:source, 'action_table')
    " Overwrite actions.
    let l:action_table = extend(copy(l:action_table), l:source.action_table)
  endif

  return l:action_table
endfunction"}}}
function! unite#get_default_action(source_name, kind_name)"{{{
  let l:kind = unite#available_kinds(a:kind_name)
  let l:source = unite#available_sources(a:source_name)

  if has_key(l:source, 'default_action')
    let l:default_action = l:source.default_action
  else
    let l:default_action = l:kind.default_action
  endif

  return l:default_action
endfunction"}}}
function! unite#escape_match(str)"{{{
  return substitute(substitute(escape(a:str, '~"\.^$[]'), '\*\@<!\*', '[^/]*', 'g'), '\*\*\+', '.*', 'g')
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
function! unite#complete_buffer(arglead, cmdline, cursorpos)"{{{
  let l:buffer_list = map(filter(range(1, bufnr('$')), 'getbufvar(v:val, "&filetype") ==# "unite"'), 'getbufvar(v:val, "unite").buffer_name')

  return filter(l:buffer_list, printf('stridx(v:val, %s) == 0', string(a:arglead)))
endfunction"}}}
function! unite#set_default(var, val)  "{{{
  if !exists(a:var) || type({a:var}) != type(a:val)
    let {a:var} = a:val
  endif
endfunction"}}}
function! unite#invalidate_cache(source_name)  "{{{
  let l:unite = s:get_unite()
  let l:unite.sources[a:source_name].unite__is_invalidate = 1
endfunction"}}}
function! unite#force_redraw() "{{{
  call s:redraw(1)
endfunction"}}}
function! unite#redraw() "{{{
  call s:redraw(0)
endfunction"}}}
function! unite#redraw_line(...) "{{{
  let l:linenr = a:0 > 0 ? a:1 : line('.')
  if l:linenr <= 2 || &filetype !=# 'unite'
    " Ignore.
    return
  endif

  setlocal modifiable

  let l:candidate = unite#get_unite_candidates()[l:linenr - 3]
  call setline(l:linenr, s:convert_line(l:candidate))

  setlocal nomodifiable
endfunction"}}}
function! unite#get_marked_candidates() "{{{
  return filter(copy(unite#get_unite_candidates()), 'v:val.unite__is_marked')
endfunction"}}}
function! unite#keyword_filter(list, input)"{{{
  for l:input in split(a:input, '\\\@<! ')
    let l:input = substitute(l:input, '\\ ', ' ', 'g')

    if l:input =~ '^!'
      " Exclusion.
      let l:input = unite#escape_match(l:input)
      call filter(a:list, 'v:val.abbr !~ ' . string(l:input[1:]))
    elseif l:input =~ '[*]'
      " Wildcard.
      let l:input = unite#escape_match(l:input)
      call filter(a:list, 'v:val.abbr =~ ' . string(l:input))
    else
      if &ignorecase
        let l:expr = printf('stridx(tolower(v:val.abbr), %s) != -1', string(tolower(l:input)))
      else
        let l:expr = printf('stridx(v:val.abbr, %s) != -1', string(l:input))
      endif

      call filter(a:list, l:expr)
    endif
  endfor

  return a:list
endfunction"}}}
function! unite#get_input()"{{{
  return getline(2)[len(b:unite.prompt):]
endfunction"}}}
function! unite#print_error(message)"{{{
  echohl WarningMsg | echomsg a:message | echohl None
endfunction"}}}
"}}}

" Command functions.
function! unite#start(sources, ...)"{{{
  if empty(s:default_sources)
    " Initialize load.
    call s:load_default_sources_and_kinds()
  endif

  " Save args.
  let l:args = a:0 >= 1 ? a:1 : {}
  if !has_key(l:args, 'input')
    let l:args.input = ''
  endif
  if !has_key(l:args, 'is_insert')
    let l:args.is_insert = 0
  endif
  if !has_key(l:args, 'buffer_name')
    let l:args.buffer_name = ''
  endif
  if !has_key(l:args, 'prompt')
    let l:args.prompt = '>'
  endif

  try
    call s:initialize_unite_buffer(a:sources, l:args)
  catch /^Invalid source/
    return
  endtry

  " User's initialization.
  setlocal nomodifiable
  setfiletype unite

  setlocal modifiable

  silent % delete _
  call setline(s:LNUM_STATUS, 'Sources: ' . join(a:sources, ', '))
  call setline(s:LNUM_PATTERN, b:unite.prompt . b:unite.args.input)
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
function! unite#resume(buffer_name)"{{{
  if a:buffer_name == ''
    " Use last unite buffer.
    if !bufexists(s:last_unite_bufnr)
      call unite#print_error('No unite buffer.')
      return
    endif

    let l:bufnr = s:last_unite_bufnr
  else
    let l:buffer_dict = {}
    for l:unite in map(filter(range(1, bufnr('$')), 'getbufvar(v:val, "&filetype") ==# "unite"'), 'getbufvar(v:val, "unite")')
      let l:buffer_dict[l:unite.buffer_name] = l:unite.bufnr
    endfor

    if !has_key(l:buffer_dict, a:buffer_name)
      call unite#print_error('Invalid buffer name : ' . a:buffer_name)
      return
    endif
    let l:bufnr = l:buffer_dict[a:buffer_name]
  endif

  let l:winnr = winnr()
  let l:win_rest_cmd = winrestcmd()

  " Split window.
  execute g:unite_split_rule
        \ g:unite_enable_split_vertically ?  'vsplit' : 'split'

  silent execute l:bufnr 'buffer'

  " Set parameters.
  let b:unite.old_winnr = l:winnr
  let b:unite.win_rest_cmd = l:win_rest_cmd

  if !g:unite_enable_split_vertically
    20 wincmd _
  endif

  setlocal modifiable

  if g:unite_enable_start_insert
    2
    startinsert!
  else
    3
    normal! 0z.
  endif

  setlocal nomodifiable
endfunction"}}}

function! unite#quit_session()  "{{{
  if &filetype !=# 'unite'
    return
  endif

  " Save unite value.
  let s:unite = b:unite

  if exists('&redrawtime')
    let &redrawtime = s:unite.redrawtime_save
  endif

  " Close preview window.
  pclose

  let l:cwd = getcwd()
  if winnr('$') != 1
    close
    execute s:unite.old_winnr . 'wincmd w'

    if winnr('$') != 1
      execute s:unite.win_rest_cmd
    endif
  endif

  " Restore current directory.
  lcd `=l:cwd`

  if !s:unite.args.is_insert
    stopinsert
  endif
endfunction"}}}

function! s:load_default_sources_and_kinds()"{{{
  " Gathering all sources and kind name.
  let s:default_sources = {}
  let s:default_kinds = {}

  for l:name in map(split(globpath(&runtimepath, 'autoload/unite/sources/*.vim'), '\n'),
        \ 'fnamemodify(v:val, ":t:r")')
    if !has_key(s:default_sources, l:name)
      let s:default_sources[l:name] = 
            \ call('unite#sources#' . l:name . '#define', [])
    endif
  endfor

  for l:name in map(split(globpath(&runtimepath, 'autoload/unite/kinds/*.vim'), '\n'),
        \ 'fnamemodify(v:val, ":t:r")')
    if !has_key(s:default_kinds, l:name)
      let s:default_kinds[l:name] = 
            \ call('unite#kinds#' . l:name . '#define', [])
    endif
  endfor
endfunction"}}}
function! s:initialize_sources(sources)"{{{
  let l:sources = {}

  let l:number = 0
  for l:source_name in a:sources
    if !has_key(s:default_sources, l:source_name)
      call unite#print_error('Invalid source name "' . l:source_name . '" is detected.')
      throw 'Invalid source'
    endif

    let l:source = s:default_sources[l:source_name]
    if !has_key(l:source, 'is_volatile')
      let l:source.is_volatile = 0
    endif
    let l:source.unite__is_invalidate = 1

    let l:source.unite__number = l:number
    let l:number += 1

    let l:sources[l:source_name] = l:source
  endfor

  return l:sources
endfunction"}}}
function! s:initialize_kinds()"{{{
  return s:default_kinds
endfunction"}}}
function! s:gather_candidates(text, args)"{{{
  let l:args = a:args
  let l:input_list = filter(split(a:text, '\\\@<! ', 1), 'v:val !~ "!"')
  let l:args.input = empty(l:input_list) ? '' : l:input_list[0]

  let l:candidates = []
  for l:source in unite#available_sources_list()
    if l:source.is_volatile
          \ || !has_key(b:unite.cached_candidates, l:source.name)
          \ || (l:args.is_force || l:source.unite__is_invalidate)

      " Check required pattern length.
      let l:source_candidates = 
            \ (has_key(l:source, 'required_pattern_length')
            \   && len(l:args.input) < l:source.required_pattern_length) ?
            \ [] : l:source.gather_candidates(l:args)

      let l:source.unite__is_invalidate = 0

      if !l:source.is_volatile
        " Recaching.
        let b:unite.cached_candidates[l:source.name] = l:source_candidates
      endif
    else
      let l:source_candidates = copy(b:unite.cached_candidates[l:source.name])
    endif

    for l:candidate in l:source_candidates
      if !has_key(l:candidate, 'abbr')
        let l:candidate.abbr = l:candidate.word
      endif
    endfor

    if a:text != ''
      call unite#keyword_filter(l:source_candidates, a:text)
    endif

    if has_key(l:source, 'max_candidates') && l:source.max_candidates != 0
      " Filtering too many candidates.
      let l:source_candidates = l:source_candidates[: l:source.max_candidates - 1]
    endif

    let l:candidates += l:source_candidates
  endfor

  for l:candidate in l:candidates
    " Initialize.
    let l:candidate.unite__is_marked = 0
  endfor

  return l:candidates
endfunction"}}}
function! s:convert_lines(candidates)"{{{
  let l:max_width = winwidth(0) - 20
  return map(copy(a:candidates),
        \ '(v:val.unite__is_marked ? "* " : "- ") . unite#util#truncate_smart(v:val.abbr, ' . l:max_width .  ', 25, "..") . " " . v:val.source')
endfunction"}}}
function! s:convert_line(candidate)"{{{
  let l:max_width = winwidth(0) - 20
  return (a:candidate.unite__is_marked ? '* ' : '- ')
        \ . unite#util#truncate_smart(a:candidate.abbr, l:max_width, 25, '..')
        \ . " " . a:candidate.source
endfunction"}}}

function! s:initialize_unite_buffer(sources, args)"{{{
  " Check sources.
  let l:sources = s:initialize_sources(a:sources)

  let l:args = a:args

  if getbufvar(bufnr('%'), '&filetype') ==# 'unite'
    if l:args.input == ''
          \ && b:unite.buffer_name ==# l:args.buffer_name
      " Get input text.
      let l:args.input = unite#get_input()
    endif

    " Quit unite buffer.
    call unite#quit_session()
  endif

  " The current buffer is initialized.
  if unite#is_win()
    let l:buffer_name = '[unite]'
  else
    let l:buffer_name = '*unite*'
  endif
  if l:args.buffer_name != ''
    let l:buffer_name .= ' - ' . l:args.buffer_name
  endif

  let l:winnr = winnr()
  let l:win_rest_cmd = winrestcmd()

  " Split window.
  execute g:unite_split_rule
        \ g:unite_enable_split_vertically ?
        \        (bufexists(l:buffer_name) ? 'vsplit' : 'vnew')
        \      : (bufexists(l:buffer_name) ? 'split' : 'new')

  if bufexists(l:buffer_name)
    " Search buffer name.
    let l:bufnr = 1
    let l:max = bufnr('$')
    while l:bufnr <= l:max
      if bufname(l:bufnr) ==# l:buffer_name
        silent execute l:bufnr 'buffer'
      endif

      let l:bufnr += 1
    endwhile
  else
    silent! file `=l:buffer_name`
  endif

  " Set parameters.
  let b:unite = {}
  let b:unite.old_winnr = l:winnr
  let b:unite.win_rest_cmd = l:win_rest_cmd
  let b:unite.args = l:args
  let b:unite.candidates = []
  let b:unite.cached_candidates = {}
  let b:unite.sources = l:sources
  let b:unite.kinds = s:initialize_kinds()
  let b:unite.buffer_name = (l:args.buffer_name == '') ? 'default' : l:args.buffer_name
  let b:unite.prompt = l:args.prompt
  let b:unite.input = l:args.input
  let b:unite.last_input = l:args.input
  let b:unite.bufnr = bufnr('%')

  let s:last_unite_bufnr = bufnr('%')

  " Basic settings.
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal nobuflisted
  setlocal noswapfile
  setlocal noreadonly
  setlocal nofoldenable
  setlocal nomodeline
  setlocal foldcolumn=0
  setlocal iskeyword+=-,+,\\,!,~

  " Autocommands.
  augroup plugin-unite
    autocmd InsertEnter <buffer>  call s:on_insert_enter()
    autocmd InsertLeave <buffer>  call s:on_insert_leave()
    autocmd CursorHoldI <buffer>  call s:on_cursor_hold()
  augroup END

  call unite#mappings#define_default_mappings()

  if exists(':NeoComplCacheLock')
    " Lock neocomplcache.
    NeoComplCacheLock
  endif

  if exists('&redrawtime')
    " Save redrawtime
    let b:unite.redrawtime_save = &redrawtime
    let &redrawtime = 500
  endif

  if !g:unite_enable_split_vertically
    20 wincmd _
  endif
endfunction"}}}

function! s:redraw(is_force) "{{{
  if &filetype !=# 'unite'
    return
  endif

  let l:input = unite#get_input()
  if !a:is_force && l:input ==# b:unite.last_input
    return
  endif

  let b:unite.last_input = l:input

  " Save options.
  let l:ignorecase_save = &ignorecase

  if g:unite_enable_smart_case && l:input =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase = g:unite_enable_ignore_case
  endif

  if has_key(s:substitute_pattern, b:unite.buffer_name)
    if b:unite.input != '' && stridx(l:input, b:unite.input) == 0
      " Substitute after input.
      let l:input_save = l:input
      let l:subst = l:input_save[len(b:unite.input) :]
      let l:input = l:input_save[: len(b:unite.input)-1]
    else
      " Substitute all input.
      let l:subst = l:input
      let l:input = ''
    endif

    for l:pattern in sort(values(s:substitute_pattern[b:unite.buffer_name]), 's:compare_substitute_patterns')
      let l:subst = substitute(l:subst, l:pattern.pattern, l:pattern.subst, 'g')
    endfor

    let l:input .= l:subst
  endif

  let l:args = b:unite.args
  let l:args.is_force = a:is_force

  let l:candidates = s:gather_candidates(l:input, l:args)

  let &ignorecase = l:ignorecase_save

  if mode() != 'i'
    setlocal modifiable
  endif

  let l:lines = s:convert_lines(l:candidates)
  if len(l:lines) < len(b:unite.candidates)
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

  if mode() != 'i'
    setlocal nomodifiable
  endif

  let b:unite.candidates = l:candidates
endfunction"}}}

" Autocmd events.
function! s:on_insert_enter()  "{{{
  if &updatetime > g:unite_update_time
    let b:unite.update_time_save = &updatetime
    let &updatetime = g:unite_update_time
  endif

  setlocal cursorline
  setlocal modifiable
endfunction"}}}
function! s:on_insert_leave()  "{{{
  if line('.') == 2
    " Redraw.
    call unite#redraw()
  endif

  if has_key(b:unite, 'update_time_save') && &updatetime < b:unite.update_time_save
    let &updatetime = b:unite.update_time_save
  endif

  setlocal nocursorline
  setlocal nomodifiable
endfunction"}}}
function! s:on_cursor_hold()  "{{{
  if line('.') == 2
    " Redraw.
    call unite#redraw()
  endif
endfunction"}}}

" Internal helper functions."{{{
function! s:get_unite() "{{{
  return exists('b:unite') ? b:unite : s:unite
endfunction"}}}
function! s:compare_sources(source_a, source_b) "{{{
  return a:source_a.unite__number - a:source_b.unite__number
endfunction"}}}
function! s:compare_substitute_patterns(pattern_a, pattern_b)"{{{
  return a:pattern_b.priority - a:pattern_a.priority
endfunction"}}}
"}}}

" vim: foldmethod=marker
