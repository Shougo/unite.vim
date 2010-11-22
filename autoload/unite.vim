"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 22 Nov 2010
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

" User functions."{{{
function! unite#get_substitute_pattern(buffer_name)"{{{
  return s:substitute_pattern[a:buffer_name]
endfunction"}}}
function! unite#set_substitute_pattern(buffer_name, pattern, subst, ...)"{{{
  let l:priority = a:0 > 0 ? a:1 : 0
  let l:buffer_name = (a:buffer_name == '' ? 'default' : a:buffer_name)

  for key in split(l:buffer_name, ',')
    if !has_key(s:substitute_pattern, key)
      let s:substitute_pattern[key] = {}
    endif

    if has_key(s:substitute_pattern[key], a:pattern)
          \ && a:pattern == ''
      call remove(s:substitute_pattern[key], a:pattern)
    else
      let s:substitute_pattern[key][a:pattern] = {
            \ 'pattern' : a:pattern,
            \ 'subst' : a:subst, 'priority' : l:priority
            \ }
    endif
  endfor
endfunction"}}}
function! unite#custom_alias(kind, name, action)"{{{
  for key in split(a:kind, ',')
    if !has_key(s:custom_aliases, key)
      let s:custom_aliases[key] = {}
    endif

    let s:custom_aliases[key][a:name] = a:action
  endfor
endfunction"}}}
function! unite#custom_default_action(kind, default_action)"{{{
  for key in split(a:kind, ',')
    let s:custom_default_actions[key] = a:default_action
  endfor
endfunction"}}}
function! unite#custom_action(kind, name, action)"{{{
  for key in split(a:kind, ',')
    if !has_key(s:custom_actions, key)
      let s:custom_actions[key] = {}
    endif
    let s:custom_actions[key][a:name] = a:action
  endfor
endfunction"}}}
function! unite#undef_custom_action(kind, name)"{{{
  for key in split(a:kind, ',')
    if has_key(s:custom_actions, key)
      call remove(s:custom_actions, key)
    endif
  endfor
endfunction"}}}

function! unite#define_source(source)"{{{
  if type(a:source) == type([])
    for l:source in a:source
      let s:custom_sources[l:source.name] = l:source
    endfor
  else
    let s:custom_sources[a:source.name] = a:source
  endif
endfunction"}}}
function! unite#define_kind(kind)"{{{
  if type(a:kind) == type([])
    for l:kind in a:kind
      let s:custom_kinds[l:kind.name] = l:kind
    endfor
  else
    let s:custom_kinds[a:kind.name] = a:kind
  endif
endfunction"}}}
function! unite#undef_source(name)"{{{
  if has_key(s:custom_sources, a:name)
    call remove(s:custom_sources, a:name)
  endif
endfunction"}}}
function! unite#undef_kind(name)"{{{
  if has_key(s:custom_kind, a:name)
    call remove(s:custom_kind, a:name)
  endif
endfunction"}}}

function! unite#do_action(action)
  return printf("%s:\<C-u>call unite#mappings#do_action(%s)\<CR>",
        \             (mode() ==# 'i' ? "\<ESC>" : ''), string(a:action))
endfunction
function! unite#smart_map(narrow_map, select_map)"{{{
  return (line('.') <= b:unite.prompt_linenr && empty(unite#get_marked_candidates())) ? a:narrow_map : a:select_map
endfunction"}}}

function! unite#take_action(action_name, candidate)"{{{
  call s:take_action(a:action_name, a:candidate, 0)
endfunction"}}}
function! unite#take_parents_action(action_name, candidate, extend_candidate)"{{{
  call s:take_action(a:action_name, extend(deepcopy(a:candidate), a:extend_candidate), 1)
endfunction"}}}
"}}}

" Constants"{{{
let s:FALSE = 0
let s:TRUE = !s:FALSE

let s:LNUM_STATUS = 1
"}}}

" Variables  "{{{
" buffer number of the unite buffer
let s:last_unite_bufnr = -1
let s:unite = {}

let s:default_sources = {}
let s:default_kinds = {}

let s:custom_sources = {}
let s:custom_kinds = {}

let s:custom_actions = {}
let s:custom_default_actions = {}
let s:custom_aliases = {}

let s:substitute_pattern = {}
call unite#set_substitute_pattern('files', '^\~', substitute(substitute($HOME, '\\', '/', 'g'), ' ', '\\\\ ', 'g'), -100)
call unite#set_substitute_pattern('files', '[^~.*]\zs/', '*/*', 100)

let s:unite_options = [
      \ '-buffer-name=', '-input=', '-prompt=',
      \ '-default-action=', '-start-insert', '-no-quit',
      \ '-winwidth=', '-winheight=',
      \]
"}}}

" Core functions."{{{
function! unite#available_kinds(...)"{{{
  let l:unite = s:get_unite()
  return a:0 == 0 ? l:unite.kinds : get(l:unite.kinds, a:1, {})
endfunction"}}}
function! unite#available_sources(...)"{{{
  let l:all_sources = s:initialize_sources()
  return a:0 == 0 ? l:all_sources : get(l:all_sources, a:1, {})
endfunction"}}}
"}}}

" Helper functions."{{{
function! unite#is_win()"{{{
  return unite#util#is_win()
endfunction"}}}
function! unite#loaded_source_names()"{{{
  return map(unite#loaded_sources_list(), 'v:val.name')
endfunction"}}}
function! unite#loaded_sources_list()"{{{
  return sort(values(s:get_loaded_sources()), 's:compare_sources')
endfunction"}}}
function! unite#get_unite_candidates()"{{{
  return s:get_unite().candidates
endfunction"}}}
function! unite#get_context()"{{{
  return s:get_unite().context
endfunction"}}}
" function! unite#get_action_table(source_name, kind_name, self_func, [is_parent_action])
function! unite#get_action_table(source_name, kind_name, self_func, ...)"{{{
  let l:kind = unite#available_kinds(a:kind_name)
  let l:source = s:get_loaded_sources(a:source_name)
  let l:is_parents_action = a:0 > 0 ? a:1 : 0

  let l:action_table = {}

  let l:source_kind = 'source/'.a:source_name.'/'.a:kind_name
  let l:source_kind_wild = 'source/'.a:source_name.'/*'

  if !l:is_parents_action
    " Source/kind custom actions.
    if has_key(s:custom_actions, l:source_kind)
      let l:action_table = s:extend_actions(a:self_func, l:action_table,
            \ s:custom_actions[l:source_kind])
    endif

    " Source/kind actions.
    if has_key(l:source.action_table, a:kind_name)
      let l:action_table = s:extend_actions(a:self_func, l:action_table,
            \ l:source.action_table[a:kind_name])
    endif

    " Source/* custom actions.
    if has_key(s:custom_actions, l:source_kind_wild)
      let l:action_table = s:extend_actions(a:self_func, l:action_table,
            \ s:custom_actions[l:source_kind_wild])
    endif

    " Source/* actions.
    if has_key(l:source.action_table, '*')
      let l:action_table = s:extend_actions(a:self_func, l:action_table,
            \ l:source.action_table['*'])
    endif

    " Kind custom actions.
    if has_key(s:custom_actions, a:kind_name)
      let l:action_table = s:extend_actions(a:self_func, l:action_table,
            \ s:custom_actions[a:kind_name])
    endif

    " Kind actions.
    let l:action_table = s:extend_actions(a:self_func, l:action_table,
          \ l:kind.action_table)
  endif

  " Parents actions.
  for l:parent in l:kind.parents
    let l:action_table = s:extend_actions(a:self_func, l:action_table,
          \ unite#get_action_table(a:source_name, l:parent, a:self_func))
  endfor

  if !l:is_parents_action
    " Kind aliases.
    call s:filter_alias_action(l:action_table, l:kind.alias_table)

    " Kind custom aliases.
    if has_key(s:custom_aliases, a:kind_name)
      call s:filter_alias_action(l:action_table, s:custom_aliases[a:kind_name])
    endif

    " Source/* aliases.
    if has_key(l:source.alias_table, '*')
      call s:filter_alias_action(l:action_table, l:source.alias_table['*'])
    endif

    " Source/* custom aliases.
    if has_key(s:custom_aliases, l:source_kind_wild)
      call s:filter_alias_action(l:action_table, s:custom_aliases[l:source_kind_wild])
    endif

    " Source/kind aliases.
    if has_key(s:custom_aliases, l:source_kind)
      call s:filter_alias_action(l:action_table, s:custom_aliases[l:source_kind])
    endif

    " Source/kind custom aliases.
    if has_key(l:source.alias_table, a:kind_name)
      call s:filter_alias_action(l:action_table, l:source.alias_table[a:kind_name])
    endif
  endif

  " Set default parameters.
  for l:action in values(l:action_table)
    if !has_key(l:action, 'description')
      let l:action.description = ''
    endif
    if !has_key(l:action, 'is_quit')
      let l:action.is_quit = 1
    endif
    if !has_key(l:action, 'is_selectable')
      let l:action.is_selectable = 0
    endif
    if !has_key(l:action, 'is_invalidate_cache')
      let l:action.is_invalidate_cache = 0
    endif
  endfor

  " Filtering nop action.
  return filter(l:action_table, 'v:key !=# "nop"')
endfunction"}}}
function! unite#get_default_action(source_name, kind_name)"{{{
  let l:source = s:get_loaded_sources(a:source_name)

  if has_key(s:custom_default_actions, a:source_name.'/'.a:kind_name)
    " Source/kind custom actions.
    return s:custom_default_actions[a:source_name.'/'.a:kind_name]
  elseif has_key(l:source.default_action, a:kind_name)
    " Source custom default actions.
    return l:source.default_action[a:kind_name]
  elseif has_key(s:custom_default_actions, a:kind_name)
    " Kind custom default actions.
    return s:custom_default_actions[a:kind_name]
  else
    " Kind default actions.
    return unite#available_kinds(a:kind_name).default_action
  endif
endfunction"}}}
function! unite#escape_match(str)"{{{
  return substitute(substitute(escape(a:str, '~"\.^$[]'), '\*\@<!\*', '[^/]*', 'g'), '\*\*\+', '.*', 'g')
endfunction"}}}
function! unite#complete_source(arglead, cmdline, cursorpos)"{{{
  if empty(s:default_sources)
    " Initialize load.
    call s:load_default_sources_and_kinds()
  endif

  let l:sources = extend(copy(s:default_sources), s:custom_sources)
  return filter(keys(l:sources)+s:unite_options, 'stridx(v:val, a:arglead) == 0')
endfunction"}}}
function! unite#complete_buffer(arglead, cmdline, cursorpos)"{{{
  let l:buffer_list = map(filter(range(1, bufnr('$')), 'getbufvar(v:val, "&filetype") ==# "unite"'), 'getbufvar(v:val, "unite").buffer_name')

  return filter(l:buffer_list, printf('stridx(v:val, %s) == 0', string(a:arglead)))
endfunction"}}}
function! unite#invalidate_cache(source_name)  "{{{
  let l:unite = s:get_unite()

  if has_key(l:unite.sources, a:source_name)
    let l:unite.sources[a:source_name].unite__is_invalidate = 1
  endif
endfunction"}}}
function! unite#force_redraw() "{{{
  call s:redraw(1)
endfunction"}}}
function! unite#redraw() "{{{
  call s:redraw(0)
endfunction"}}}
function! unite#redraw_line(...) "{{{
  let l:linenr = a:0 > 0 ? a:1 : line('.')
  if l:linenr <= b:unite.prompt_linenr || &filetype !=# 'unite'
    " Ignore.
    return
  endif

  let l:modifiable_save = &l:modifiable
  setlocal modifiable

  let l:candidate = unite#get_unite_candidates()[l:linenr - (b:unite.prompt_linenr+1)]
  call setline(l:linenr, s:convert_line(l:candidate))

  let &l:modifiable = l:modifiable_save
endfunction"}}}
function! unite#quick_match_redraw() "{{{
  let l:modifiable_save = &l:modifiable
  setlocal modifiable

  call setline(b:unite.prompt_linenr+1, s:convert_quick_match_lines(b:unite.candidates))
  redraw

  let &l:modifiable = l:modifiable_save
endfunction"}}}
function! unite#redraw_status() "{{{
  let l:modifiable_save = &l:modifiable
  setlocal modifiable

  call setline(s:LNUM_STATUS, 'Sources: ' . join(map(copy(unite#loaded_sources_list()), 'v:val.name'), ', '))

  let &l:modifiable = l:modifiable_save
endfunction"}}}
function! unite#redraw_candidates() "{{{
  let l:candidates = unite#gather_candidates()

  let l:modifiable_save = &l:modifiable
  setlocal modifiable

  let l:lines = s:convert_lines(l:candidates)
  if len(l:lines) < len(b:unite.candidates)
    if mode() !=# 'i' && line('.') == b:unite.prompt_linenr
      silent! execute (b:unite.prompt_linenr+1).',$delete _'
      startinsert!
    else
      let l:pos = getpos('.')
      silent! execute (b:unite.prompt_linenr+1).',$delete _'
      call setpos('.', l:pos)
    endif
  endif
  call setline(b:unite.prompt_linenr+1, l:lines)

  let &l:modifiable = l:modifiable_save
  let b:unite.candidates = l:candidates
endfunction"}}}
function! unite#get_marked_candidates() "{{{
  return sort(filter(copy(unite#get_unite_candidates()), 'v:val.unite__is_marked'), 's:compare_marked_candidates')
endfunction"}}}
function! unite#keyword_filter(list, input)"{{{
  for l:input in split(a:input, '\\\@<! ')
    let l:input = substitute(l:input, '\\ ', ' ', 'g')

    if l:input =~ '^!'
      " Exclusion.
      let l:input = unite#escape_match(l:input)
      call filter(a:list, 'v:val.word !~ ' . string(l:input[1:]))
    elseif l:input =~ '\\\@<!\*'
      " Wildcard.
      let l:input = unite#escape_match(l:input)
      call filter(a:list, 'v:val.word =~ ' . string(l:input))
    else
      let l:input = substitute(l:input, '\\\(.\)', '\1', 'g')
      if &ignorecase
        let l:expr = printf('stridx(tolower(v:val.word), %s) != -1', string(tolower(l:input)))
      else
        let l:expr = printf('stridx(v:val.word, %s) != -1', string(l:input))
      endif

      call filter(a:list, l:expr)
    endif
  endfor

  return a:list
endfunction"}}}
function! unite#get_input()"{{{
  " Prompt check.
  if stridx(getline(b:unite.prompt_linenr), b:unite.prompt) != 0
    " Restore prompt.
    call setline(b:unite.prompt_linenr, b:unite.prompt . getline(b:unite.prompt_linenr))
  endif

  return getline(b:unite.prompt_linenr)[len(b:unite.prompt):]
endfunction"}}}
function! unite#get_options()"{{{
  return s:unite_options
endfunction"}}}
function! unite#get_self_functions()"{{{
  return split(matchstr(expand('<sfile>'), '^function \zs.*$'), '\.\.')[: -2]
endfunction"}}}
function! unite#gather_candidates()"{{{
  let l:candidates = []
  for l:source in unite#loaded_sources_list()
    let l:candidates += b:unite.sources_candidates[l:source.name]
  endfor

  return l:candidates
endfunction"}}}

" Utils.
function! unite#print_error(message)"{{{
  echohl WarningMsg | echomsg a:message | echohl None
endfunction"}}}
function! unite#substitute_path_separator(path)"{{{
  return unite#util#substitute_path_separator(a:path)
endfunction"}}}
function! unite#path2directory(path)"{{{
  return unite#util#path2directory(a:path)
endfunction"}}}
"}}}

" Command functions.
function! unite#start(sources, ...)"{{{
  if empty(s:default_sources)
    " Initialize load.
    call s:load_default_sources_and_kinds()
  endif

  " Save context.
  let l:context = a:0 >= 1 ? a:1 : {}
  if !has_key(l:context, 'input')
    let l:context.input = ''
  endif
  if !has_key(l:context, 'start_insert')
    let l:context.start_insert = 0
  endif
  if !has_key(l:context, 'is_insert')
    let l:context.is_insert = 0
  endif
  if !has_key(l:context, 'no_quit')
    let l:context.no_quit = 0
  endif
  if !has_key(l:context, 'buffer_name')
    let l:context.buffer_name = ''
  endif
  if !has_key(l:context, 'prompt')
    let l:context.prompt = '>'
  endif
  if !has_key(l:context, 'default_action')
    let l:context.default_action = 'default'
  endif
  if !has_key(l:context, 'winwidth')
    let l:context.winwidth = g:unite_winwidth
  endif
  if !has_key(l:context, 'winheight')
    let l:context.winheight = g:unite_winheight
  endif
  let l:context.is_redraw = 0

  try
    call s:initialize_unite_buffer(a:sources, l:context)
  catch /^Invalid source/
    return
  endtry

  setlocal modifiable

  silent % delete _
  call unite#redraw_status()
  call setline(b:unite.prompt_linenr, b:unite.prompt . b:unite.context.input)

  call unite#force_redraw()

  if g:unite_enable_start_insert
        \ || b:unite.context.start_insert || b:unite.context.is_insert
    execute b:unite.prompt_linenr
    normal! 0z.
    startinsert!
  else
    execute (b:unite.prompt_linenr+1)
    normal! 0z.
  endif

  setlocal nomodifiable
endfunction"}}}
function! unite#resume(buffer_name)"{{{
  if a:buffer_name == ''
    " Use last unite buffer.
    if !bufexists(s:last_unite_bufnr)
      call unite#util#print_error('No unite buffer.')
      return
    endif

    let l:bufnr = s:last_unite_bufnr
  else
    let l:buffer_dict = {}
    for l:unite in map(filter(range(1, bufnr('$')), 'getbufvar(v:val, "&filetype") ==# "unite"'), 'getbufvar(v:val, "unite")')
      let l:buffer_dict[l:unite.buffer_name] = l:unite.bufnr
    endfor

    if !has_key(l:buffer_dict, a:buffer_name)
      call unite#util#print_error('Invalid buffer name : ' . a:buffer_name)
      return
    endif
    let l:bufnr = l:buffer_dict[a:buffer_name]
  endif

  let l:winnr = winnr()
  let l:win_rest_cmd = winrestcmd()

  call s:switch_unite_buffer(bufname(l:bufnr), getbufvar(l:bufnr, 'unite').context)

  " Set parameters.
  let b:unite.winnr = l:winnr
  let b:unite.win_rest_cmd = l:win_rest_cmd
  let b:unite.redrawtime_save = &redrawtime
  let b:unite.hlsearch_save = &hlsearch
  let b:unite.search_pattern_save = @/

  let s:unite = b:unite

  setlocal modifiable

  if g:unite_enable_start_insert
        \ || b:unite.context.start_insert || b:unite.context.is_insert
    execute b:unite.prompt_linenr
    normal! 0z.
    startinsert!
  else
    execute (b:unite.prompt_linenr+1)
    normal! 0z.
  endif

  setlocal nomodifiable
endfunction"}}}

function! unite#force_quit_session()  "{{{
  call s:quit_session(1)
endfunction"}}}
function! unite#quit_session()  "{{{
  call s:quit_session(0)
endfunction"}}}
function! s:quit_session(is_force)  "{{{
  if &filetype !=# 'unite'
    return
  endif

  " Save unite value.
  let s:unite = b:unite

  " Highlight off.
  let @/ = s:unite.search_pattern_save

  " Restore options.
  if exists('&redrawtime')
    let &redrawtime = s:unite.redrawtime_save
  endif
  let &hlsearch = s:unite.hlsearch_save

  nohlsearch

  " Close preview window.
  pclose

  " Call finalize functions.
  for l:source in unite#loaded_sources_list()
    if has_key(l:source.hooks, 'on_close')
      call l:source.hooks.on_close(l:source.args, s:unite.context)
    endif
  endfor

  if winnr('$') != 1
    if !a:is_force && s:unite.context.no_quit
      if winnr('#') > 0
        wincmd p
      endif
    else
      close
      execute s:unite.winnr . 'wincmd w'

      if winnr('$') != 1
        execute s:unite.win_rest_cmd
      endif
    endif
  endif

  if !s:unite.context.is_insert
    stopinsert
    redraw!
  endif
endfunction"}}}

function! s:load_default_sources_and_kinds()"{{{
  " Gathering all sources and kind name.
  let s:default_sources = {}
  let s:default_kinds = {}

  for l:name in map(split(globpath(&runtimepath, 'autoload/unite/sources/*.vim'), '\n'),
        \ 'fnamemodify(v:val, ":t:r")')

    if type({'unite#sources#' . l:name . '#define'}()) == type([])
      for l:source in {'unite#sources#' . l:name . '#define'}()
        if !has_key(s:default_sources, l:source.name)
          let s:default_sources[l:source.name] = l:source
        endif
      endfor
    else
      let l:source = {'unite#sources#' . l:name . '#define'}()

      if !has_key(s:default_sources, l:source.name)
        let s:default_sources[l:source.name] = l:source
      endif
    endif
  endfor

  for l:name in map(split(globpath(&runtimepath, 'autoload/unite/kinds/*.vim'), '\n'),
        \ 'fnamemodify(v:val, ":t:r")')

    if type({'unite#kinds#' . l:name . '#define'}()) == type([])
      for l:kind in {'unite#kinds#' . l:name . '#define'}()
        if !has_key(s:default_kinds, l:kind.name)
          let s:default_kinds[l:kind.name] = l:kind
        endif
      endfor
    else
      let l:kind = {'unite#kinds#' . l:name . '#define'}()

      if !has_key(s:default_kinds, l:kind.name)
        let s:default_kinds[l:kind.name] = l:kind
      endif
    endif
  endfor
endfunction"}}}
function! s:initialize_loaded_sources(sources)"{{{
  let l:all_sources = s:initialize_sources()
  let l:sources = {}

  let l:number = 0
  for [l:source_name, l:args] in map(a:sources, 'type(v:val) == type([]) ? [v:val[0], v:val[1:]] : [v:val, []]')
    if !has_key(l:all_sources, l:source_name)
      call unite#util#print_error('Invalid source name "' . l:source_name . '" is detected.')
      throw 'Invalid source'
    endif

    let l:source = l:all_sources[l:source_name]
    let l:source.args = l:args
    let l:source.unite__is_invalidate = 1

    let l:source.unite__number = l:number
    let l:number += 1

    let l:sources[l:source_name] = l:source
  endfor

  return l:sources
endfunction"}}}
function! s:initialize_sources()"{{{
  let l:all_sources = extend(copy(s:default_sources), s:custom_sources)

  for l:source in values(l:all_sources)
    if !has_key(l:source, 'is_volatile')
      let l:source.is_volatile = 0
    endif
    if !has_key(l:source, 'max_candidates')
      let l:source.max_candidates = 0
    endif
    if !has_key(l:source, 'required_pattern_length')
      let l:source.required_pattern_length = 0
    endif
    if !has_key(l:source, 'action_table')
      let l:source.action_table = {}
    endif
    if !has_key(l:source, 'default_action')
      let l:source.default_action = {}
    endif
    if !has_key(l:source, 'alias_table')
      let l:source.alias_table = {}
    endif
    if !has_key(l:source, 'hooks')
      let l:source.hooks = {}
    endif
  endfor

  return l:all_sources
endfunction"}}}
function! s:initialize_kinds()"{{{
  let l:kinds = extend(copy(s:default_kinds), s:custom_kinds)
  for l:kind in values(l:kinds)
    if !has_key(l:kind, 'alias_table')
      let l:kind.alias_table = {}
    endif
    if !has_key(l:kind, 'parents')
      let l:kind.parents = ['common']
    endif
  endfor

  return l:kinds
endfunction"}}}
function! s:recache_candidates(input, context)"{{{
  let l:context = a:context
  let l:input_list = filter(split(a:input, '\\\@<! ', 1), 'v:val !~ "!"')
  let l:context.input = empty(l:input_list) ? '' : l:input_list[0]
  let l:input_len = unite#util#strchars(l:context.input)

  for l:source in unite#loaded_sources_list()
    " Check required pattern length.
    if l:input_len < l:source.required_pattern_length
      let b:unite.sources_candidates[l:source.name] = []
      continue
    endif

    if l:source.is_volatile || l:context.is_force || l:source.unite__is_invalidate
      let l:context.source = l:source
      let l:source_candidates = copy(l:source.gather_candidates(l:source.args, l:context))
      let l:source.unite__is_invalidate = 0

      if !l:source.is_volatile
        " Recaching.
        let b:unite.cached_candidates[l:source.name] = l:source_candidates
      endif
    else
      let l:source_candidates = copy(b:unite.cached_candidates[l:source.name])
    endif

    if a:input != ''
      call unite#keyword_filter(l:source_candidates, a:input)
    endif

    if l:source.max_candidates != 0
      " Filtering too many candidates.
      let l:source_candidates = l:source_candidates[: l:source.max_candidates - 1]
    endif

    for l:candidate in l:source_candidates
      if !has_key(l:candidate, 'abbr')
        let l:candidate.abbr = l:candidate.word
      endif
      if !has_key(l:candidate, 'kind')
        let l:candidate.kind = 'common'
      endif

      " Initialize.
      let l:candidate.unite__is_marked = 0
    endfor

    let b:unite.sources_candidates[l:source.name] = l:source_candidates
  endfor
endfunction"}}}
function! s:convert_quick_match_lines(candidates)"{{{
  let l:max_width = winwidth(0) - b:unite.max_source_name - 5
  if l:max_width < 20
    let l:max_width = winwidth(0) - 5
    let l:max_source_name = 0
  else
    let l:max_source_name = b:unite.max_source_name
  endif

  let l:candidates = []

  " Create key table.
  let l:keys = {}
  for [l:key, l:number] in items(g:unite_quick_match_table)
    let l:keys[l:number] = l:key . ': '
  endfor

  " Add number.
  let l:num = 0
  for l:candidate in a:candidates
    call add(l:candidates,
          \ (has_key(l:keys, l:num) ? l:keys[l:num] : '   ')
          \ . unite#util#truncate(l:candidate.source, l:max_source_name)
          \ . unite#util#truncate_smart(l:candidate.abbr, l:max_width, l:max_width/3, '..'))
    let l:num += 1
  endfor

  return l:candidates
endfunction"}}}
function! s:convert_lines(candidates)"{{{
  let l:max_width = winwidth(0) - b:unite.max_source_name - 2
  if l:max_width < 20
    let l:max_width = winwidth(0) - 2
    let l:max_source_name = 0
  else
    let l:max_source_name = b:unite.max_source_name
  endif

  return map(copy(a:candidates),
        \ '(v:val.unite__is_marked ? "* " : "- ")
        \ . unite#util#truncate(v:val.source, l:max_source_name)
        \ . unite#util#truncate_smart(v:val.abbr, ' . l:max_width .  ', l:max_width/3, "..")')
endfunction"}}}
function! s:convert_line(candidate)"{{{
  let l:max_width = winwidth(0) - b:unite.max_source_name - 2
  if l:max_width < 20
    let l:max_width = winwidth(0) - 2
    let l:max_source_name = 0
  else
    let l:max_source_name = b:unite.max_source_name
  endif

  return (a:candidate.unite__is_marked ? '* ' : '- ')
        \ . unite#util#truncate(a:candidate.source, l:max_source_name)
        \ . unite#util#truncate_smart(a:candidate.abbr, l:max_width, l:max_width/3, '..')
endfunction"}}}

function! s:initialize_unite_buffer(sources, context)"{{{
  " Check sources.
  let l:sources = s:initialize_loaded_sources(a:sources)

  let l:context = a:context

  if getbufvar(bufnr('%'), '&filetype') ==# 'unite'
    if l:context.input == ''
          \ && b:unite.buffer_name ==# l:context.buffer_name
      " Get input text.
      let l:context.input = unite#get_input()
    endif

    " Quit unite buffer.
    call unite#quit_session()
  endif

  " The current buffer is initialized.
  let l:buffer_name = unite#is_win() ? '[unite]' : '*unite*'
  if l:context.buffer_name != ''
    let l:buffer_name .= ' - ' . l:context.buffer_name
  endif

  let l:winnr = winnr()
  let l:win_rest_cmd = winrestcmd()

  " Call initialize functions.
  for l:source in values(l:sources)
    if has_key(l:source.hooks, 'on_init')
      call l:source.hooks.on_init(l:source.args, l:context)
    endif
  endfor

  call s:switch_unite_buffer(l:buffer_name, a:context)

  " Set parameters.
  let b:unite = {}
  let b:unite.winnr = l:winnr
  let b:unite.win_rest_cmd = l:win_rest_cmd
  let b:unite.context = l:context
  let b:unite.candidates = []
  let b:unite.sources = l:sources
  let b:unite.kinds = s:initialize_kinds()
  let b:unite.buffer_name = (l:context.buffer_name == '') ? 'default' : l:context.buffer_name
  let b:unite.prompt = l:context.prompt
  let b:unite.input = l:context.input
  let b:unite.last_input = l:context.input
  let b:unite.bufnr = bufnr('%')
  let b:unite.hlsearch_save = &hlsearch
  let b:unite.search_pattern_save = @/
  let b:unite.prompt_linenr = 2
  let b:unite.max_source_name = max(map(copy(a:sources), 'len(v:val[0])')) + 2
  let b:unite.cached_candidates = {}
  let b:unite.sources_candidates = {}

  let s:unite = b:unite

  let s:last_unite_bufnr = bufnr('%')

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
  setlocal nowrap
  setlocal foldcolumn=0
  setlocal iskeyword+=-,+,\\,!,~
  set hlsearch

  " Autocommands.
  augroup plugin-unite
    autocmd InsertEnter <buffer>  call s:on_insert_enter()
    autocmd InsertLeave <buffer>  call s:on_insert_leave()
    autocmd CursorHoldI <buffer>  call s:on_cursor_hold_i()
    autocmd CursorHold <buffer>  call s:on_cursor_hold()
    autocmd CursorMoved,CursorMovedI <buffer>  call s:on_cursor_moved()
  augroup END

  call unite#mappings#define_default_mappings()

  if exists(':NeoComplCacheLock')
    " Lock neocomplcache.
    NeoComplCacheLock
  endif

  if exists('&redrawtime')
    " Save redrawtime
    let b:unite.redrawtime_save = &redrawtime
    let &redrawtime = 100
  endif

  " User's initialization.
  setlocal nomodifiable
  setfiletype unite

  if exists('b:current_syntax') && b:current_syntax == 'unite'
    " Set highlight.
    let l:match_prompt = escape(b:unite.prompt, '\/*~.^$[]')
    syntax clear uniteInputPrompt
    execute 'syntax match uniteInputPrompt' '/^'.l:match_prompt.'/ contained'

    execute 'syntax match uniteCandidateAbbr' '/\%'.(b:unite.max_source_name+2).'c.*/ contained'
  endif
endfunction"}}}
function! s:switch_unite_buffer(buffer_name, context)"{{{
  " Search unite window.
  " Note: must escape file-pattern.
  if bufwinnr(unite#util#escape_file_searching(a:buffer_name)) > 0
    silent execute bufwinnr(unite#util#escape_file_searching(a:buffer_name)) 'wincmd w'
  else
    " Split window.
    execute g:unite_split_rule
          \ g:unite_enable_split_vertically ?
          \        (bufexists(a:buffer_name) ? 'vsplit' : 'vnew')
          \      : (bufexists(a:buffer_name) ? 'split' : 'new')
    if bufexists(a:buffer_name)
      " Search buffer name.
      let l:bufnr = 1
      let l:max = bufnr('$')
      while l:bufnr <= l:max
        if bufname(l:bufnr) ==# a:buffer_name
          silent execute l:bufnr 'buffer'
        endif

        let l:bufnr += 1
      endwhile
    else
      silent! file `=a:buffer_name`
    endif
  endif

  if g:unite_enable_split_vertically
    execute 'vertical resize' a:context.winwidth
  else
    execute 'resize' a:context.winheight
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

  " Highlight off.
  let @/ = ''

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

  let l:context = b:unite.context
  let l:context.is_force = a:is_force

  " Recaching.
  call s:recache_candidates(l:input, l:context)

  let &ignorecase = l:ignorecase_save

  " Redraw.
  call unite#redraw_candidates()
endfunction"}}}

" Autocmd events.
function! s:on_insert_enter()  "{{{
  if &updatetime > g:unite_update_time
    let b:unite.update_time_save = &updatetime
    let &updatetime = g:unite_update_time
  endif

  setlocal modifiable
endfunction"}}}
function! s:on_insert_leave()  "{{{
  if line('.') == b:unite.prompt_linenr
    " Redraw.
    call unite#redraw()
  endif

  if has_key(b:unite, 'update_time_save') && &updatetime < b:unite.update_time_save
    let &updatetime = b:unite.update_time_save
  endif

  setlocal nomodifiable
endfunction"}}}
function! s:on_cursor_hold_i()  "{{{
  if line('.') == b:unite.prompt_linenr
    " Redraw.
    call unite#redraw()

    " Prompt check.
    if col('.') <= len(b:unite.prompt)
      startinsert!
    endif
  endif
endfunction"}}}
function! s:on_cursor_hold()  "{{{
  if line('.') == b:unite.prompt_linenr
    " Redraw.
    call unite#redraw()
  endif
endfunction"}}}
function! s:on_cursor_moved()  "{{{
  execute 'setlocal' line('.') == b:unite.prompt_linenr ? 'modifiable' : 'nomodifiable'
  execute 'match' (line('.') <= b:unite.prompt_linenr ? line('$') <= b:unite.prompt_linenr ?
        \ 'Error /\%'.b:unite.prompt_linenr.'l/' : 'PmenuSel /\%'.(b:unite.prompt_linenr+1).'l/' : 'PmenuSel /\%'.line('.').'l/')
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
function! s:compare_marked_candidates(candidate_a, candidate_b)"{{{
  return a:candidate_a.unite__marked_time - a:candidate_b.unite__marked_time
endfunction"}}}
function! s:extend_actions(self_func, action_table1, action_table2)"{{{
  return extend(a:action_table1, s:filter_self_func(a:action_table2, a:self_func), 'keep')
endfunction"}}}
function! s:filter_alias_action(action_table, alias_table)"{{{
  for [l:alias_name, l:alias_action] in items(a:alias_table)
    if l:alias_action ==# 'nop'
      if has_key(a:action_table, l:alias_name)
        " Delete nop action.
        call remove(a:action_table, l:alias_name)
      endif
    else
      let a:action_table[l:alias_name] = a:action_table[l:alias_action]
    endif
  endfor
endfunction"}}}
function! s:filter_self_func(action_table, self_func)"{{{
  return filter(copy(a:action_table), printf("string(v:val.func) !=# \"function('%s')\"", a:self_func))
endfunction"}}}
function! s:take_action(action_name, candidate, is_parent_action)"{{{
  let l:candidate_head = type(a:candidate) == type([]) ?
        \ a:candidate[0] : a:candidate

  let l:action_table = unite#get_action_table(
        \ l:candidate_head.source, l:candidate_head.kind,
        \ unite#get_self_functions()[-3], a:is_parent_action)

  let l:action_name =
        \ a:action_name ==# 'default' ?
        \ unite#get_default_action(l:candidate_head.source, l:candidate_head.kind)
        \ : a:action_name

  if !has_key(l:action_table, a:action_name)
    throw 'no such action ' . a:action_name
  endif

  let l:action = l:action_table[a:action_name]
  " Convert candidates.
  call l:action.func(
        \ (l:action.is_selectable && type(a:candidate) != type([])) ?
        \ [a:candidate] : a:candidate)
endfunction"}}}
function! s:get_loaded_sources(...)"{{{
  let l:unite = s:get_unite()
  return a:0 == 0 ? l:unite.sources : get(l:unite.sources, a:1, {})
endfunction"}}}
"}}}

" vim: foldmethod=marker
