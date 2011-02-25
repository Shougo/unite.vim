"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 25 Feb 2011.
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
" Version: 1.1, for Vim 7.0
"=============================================================================

function! unite#version()"{{{
  return str2nr(printf('%02d%02d%03d', 1, 1, 0))
endfunction"}}}

" User functions."{{{
function! s:initialize_buffer_name_settings(buffer_name)"{{{
  if !has_key(s:buffer_name_settings, a:buffer_name)
    let s:buffer_name_settings[a:buffer_name] = {}
  endif
  let l:setting = s:buffer_name_settings[a:buffer_name]
  if !has_key(l:setting, 'substitute_patterns')
    let l:setting.substitute_patterns = {}
  endif
endfunction"}}}
function! unite#get_substitute_pattern(buffer_name)"{{{
  return has_key(s:buffer_name_settings, a:buffer_name) ?
        \ s:buffer_name_settings[a:buffer_name].substitute_patterns : ''
endfunction"}}}
function! unite#set_substitute_pattern(buffer_name, pattern, subst, ...)"{{{
  let l:priority = a:0 > 0 ? a:1 : 0
  let l:buffer_name = (a:buffer_name == '' ? 'default' : a:buffer_name)

  for key in split(l:buffer_name, ',')
    if !has_key(s:buffer_name_settings, key)
      let s:buffer_name_settings[key] = {}
    endif

    if !has_key(s:buffer_name_settings[key], 'substitute_patterns')
      let s:buffer_name_settings[key].substitute_patterns = {}
    endif

    let l:substitute_patterns = s:buffer_name_settings[key].substitute_patterns

    if has_key(l:substitute_patterns, a:pattern)
          \ && a:pattern == ''
      call remove(l:substitute_patterns, a:pattern)
    else
      let l:substitute_patterns[a:pattern] = {
            \ 'pattern' : a:pattern,
            \ 'subst' : a:subst, 'priority' : l:priority
            \ }
    endif
  endfor
endfunction"}}}
function! unite#custom_matcher(source_name, matchers)"{{{
  let l:matchers = type(a:matchers) == type([]) ?
        \ a:matchers : [a:matchers]
  for key in split(a:source_name, ',')
    if !has_key(s:dynamic.sources, key)
      let s:dynamic.source[key] = {}
    endif

    let s:dynamic.source[key].matchers = l:matchers
  endfor
endfunction"}}}
function! unite#custom_sorter(source_name, sorters)"{{{
  let l:sorters = type(a:sorters) == type([]) ?
        \ a:sorters : [a:sorters]
  for key in split(a:source_name, ',')
    if !has_key(s:dynamic.sources, key)
      let s:dynamic.source[key] = {}
    endif

    let s:dynamic.source.[key].sorters = l:sorters
  endfor
endfunction"}}}
function! unite#custom_alias(kind, name, action)"{{{
  for key in split(a:kind, ',')
    if !has_key(s:custom.aliases, key)
      let s:custom.aliases[key] = {}
    endif

    let s:custom.aliases[key][a:name] = a:action
  endfor
endfunction"}}}
function! unite#custom_default_action(kind, default_action)"{{{
  for key in split(a:kind, ',')
    let s:custom.default_actions[key] = a:default_action
  endfor
endfunction"}}}
function! unite#custom_action(kind, name, action)"{{{
  for key in split(a:kind, ',')
    if !has_key(s:custom.actions, key)
      let s:custom.actions[key] = {}
    endif
    let s:custom.actions[key][a:name] = a:action
  endfor
endfunction"}}}
function! unite#undef_custom_action(kind, name)"{{{
  for key in split(a:kind, ',')
    if has_key(s:custom.actions, key)
      call remove(s:custom.actions, key)
    endif
  endfor
endfunction"}}}

function! unite#define_source(source)"{{{
  if type(a:source) == type([])
    for l:source in a:source
      let s:dynamic.sources[l:source.name] = l:source
    endfor
  else
    let s:dynamic.sources[a:source.name] = a:source
  endif
endfunction"}}}
function! unite#define_kind(kind)"{{{
  if type(a:kind) == type([])
    for l:kind in a:kind
      let s:dynamic.kinds[l:kind.name] = l:kind
    endfor
  else
    let s:dynamic.kinds[a:kind.name] = a:kind
  endif
endfunction"}}}
function! unite#define_matcher(matcher)"{{{
  if type(a:matcher) == type([])
    for l:matcher in a:matcher
      let s:dynamic.matchers[l:matcher.name] = l:matcher
    endfor
  else
    let s:dynamic.matchers[a:matcher.name] = a:matcher
  endif
endfunction"}}}
function! unite#define_sorter(sorter)"{{{
  if type(a:sorter) == type([])
    for l:sorter in a:sorter
      let s:dynamic.sorters[l:sorter.name] = l:sorter
    endfor
  else
    let s:dynamic.sorters[a:sorter.name] = a:sorter
  endif
endfunction"}}}
function! unite#undef_source(name)"{{{
  if has_key(s:dynamic.sources, a:name)
    call remove(s:dynamic.sources, a:name)
  endif
endfunction"}}}
function! unite#undef_kind(name)"{{{
  if has_key(s:dynamic.kinds, a:name)
    call remove(s:dynamic.kinds, a:name)
  endif
endfunction"}}}
function! unite#undef_matcher(name)"{{{
  if has_key(s:dynamic.matchers, a:name)
    call remove(s:dynamic.matchers, a:name)
  endif
endfunction"}}}
function! unite#undef_sorter(name)"{{{
  if has_key(s:dynamic.sorters, a:name)
    call remove(s:dynamic.sorters, a:name)
  endif
endfunction"}}}

function! unite#do_action(action)
  return printf("%s:\<C-u>call unite#mappings#do_action(%s)\<CR>",
        \             (mode() ==# 'i' ? "\<ESC>" : ''), string(a:action))
endfunction
function! unite#smart_map(narrow_map, select_map)"{{{
  return (line('.') <= unite#get_current_unite().prompt_linenr && empty(unite#get_marked_candidates())) ? a:narrow_map : a:select_map
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
let s:current_unite = {}
let s:unite_cached_message = []

let s:static = {}

let s:dynamic = {}
let s:dynamic.sources = {}
let s:dynamic.kinds = {}
let s:dynamic.matchers = {}
let s:dynamic.sorters = {}

let s:custom = {}
let s:custom.actions = {}
let s:custom.default_actions = {}
let s:custom.aliases = {}
let s:custom.source = {}

let s:buffer_name_settings = {}
call unite#set_substitute_pattern('files', '^\~', substitute(substitute($HOME, '\\', '/', 'g'), ' ', '\\\\ ', 'g'), -100)
call unite#set_substitute_pattern('files', '[^~.*]\zs/', '*/*', 100)

let s:unite_options = [
      \ '-buffer-name=', '-input=', '-prompt=',
      \ '-default-action=', '-start-insert','-no-start-insert', '-no-quit',
      \ '-winwidth=', '-winheight=',
      \ '-immediately', '-auto-preview', '-complete',
      \ '-vertical', '-horizontal', '-direction=',
      \]
"}}}

" Core functions."{{{
function! unite#get_kinds(...)"{{{
  let l:unite = unite#get_current_unite()
  return a:0 == 0 ? l:unite.kinds : get(l:unite.kinds, a:1, {})
endfunction"}}}
function! unite#get_sources(...)"{{{
  let l:all_sources = s:initialize_sources()
  return a:0 == 0 ? l:all_sources : get(l:all_sources, a:1, {})
endfunction"}}}
"}}}

" Helper functions."{{{
function! unite#is_win()"{{{
  return unite#util#is_win()
endfunction"}}}
function! unite#loaded_source_names()"{{{
  return map(copy(unite#loaded_sources_list()), 'v:val.name')
endfunction"}}}
function! unite#loaded_source_names_with_args()"{{{
  return map(copy(unite#loaded_sources_list()), 'join(insert(copy(v:val.args), v:val.name), ":")')
endfunction"}}}
function! unite#loaded_sources_list()"{{{
  return s:get_loaded_sources()
endfunction"}}}
function! unite#get_unite_candidates()"{{{
  return unite#get_current_unite().candidates
endfunction"}}}
function! unite#get_context()"{{{
  return unite#get_current_unite().context
endfunction"}}}
" function! unite#get_action_table(source_name, kind_name, self_func, [is_parent_action])
function! unite#get_action_table(source_name, kind_name, self_func, ...)"{{{
  let l:kind = unite#get_kinds(a:kind_name)
  let l:source = s:get_loaded_sources(a:source_name)
  let l:is_parents_action = a:0 > 0 ? a:1 : 0

  let l:action_table = {}

  let l:source_kind = 'source/'.a:source_name.'/'.a:kind_name
  let l:source_kind_wild = 'source/'.a:source_name.'/*'

  if !l:is_parents_action
    " Source/kind custom actions.
    if has_key(s:custom.actions, l:source_kind)
      let l:action_table = s:extend_actions(a:self_func, l:action_table,
            \ s:custom.actions[l:source_kind], 'custom/'.l:source.name.'/'.l:kind.name)
    endif

    " Source/kind actions.
    if has_key(l:source.action_table, a:kind_name)
      let l:action_table = s:extend_actions(a:self_func, l:action_table,
            \ l:source.action_table[a:kind_name], l:source.name.'/'.l:kind.name)
    endif

    " Source/* custom actions.
    if has_key(s:custom.actions, l:source_kind_wild)
      let l:action_table = s:extend_actions(a:self_func, l:action_table,
            \ s:custom.actions[l:source_kind_wild], 'custom/source/'.l:source.name)
    endif

    " Source/* actions.
    if has_key(l:source.action_table, '*')
      let l:action_table = s:extend_actions(a:self_func, l:action_table,
            \ l:source.action_table['*'], 'source/'.l:source.name)
    endif

    " Kind custom actions.
    if has_key(s:custom.actions, a:kind_name)
      let l:action_table = s:extend_actions(a:self_func, l:action_table,
            \ s:custom.actions[a:kind_name], 'custom/'.l:kind.name)
    endif

    " Kind actions.
    let l:action_table = s:extend_actions(a:self_func, l:action_table,
          \ l:kind.action_table, l:kind.name)
  endif

  " Parents actions.
  for l:parent in l:kind.parents
    let l:action_table = s:extend_actions(a:self_func, l:action_table,
          \ unite#get_action_table(a:source_name, l:parent, a:self_func))
  endfor

  if !l:is_parents_action
    " Kind aliases.
    call s:filter_alias_action(l:action_table, l:kind.alias_table,
          \ l:kind.name)

    " Kind custom aliases.
    if has_key(s:custom.aliases, a:kind_name)
      call s:filter_alias_action(l:action_table, s:custom.aliases[a:kind_name],
            \ 'custom/'.l:kind.name)
    endif

    " Source/* aliases.
    if has_key(l:source.alias_table, '*')
      call s:filter_alias_action(l:action_table, l:source.alias_table['*'],
            \ 'source/'.l:source.name)
    endif

    " Source/* custom aliases.
    if has_key(s:custom.aliases, l:source_kind_wild)
      call s:filter_alias_action(l:action_table, s:custom.aliases[l:source_kind_wild],
            \ 'custom/source/'.l:source.name)
    endif

    " Source/kind aliases.
    if has_key(s:custom.aliases, l:source_kind)
      call s:filter_alias_action(l:action_table, s:custom.aliases[l:source_kind],
            \ 'source/'.l:source.name.'/'.l:kind.name)
    endif

    " Source/kind custom aliases.
    if has_key(l:source.alias_table, a:kind_name)
      call s:filter_alias_action(l:action_table, l:source.alias_table[a:kind_name],
            \ 'custom/source/'.l:source.name.'/'.l:kind.name)
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

  let l:source_kind = 'source/'.a:source_name.'/'.a:kind_name
  let l:source_kind_wild = 'source/'.a:source_name.'/*'

  " Source/kind custom default actions.
  if has_key(s:custom.default_actions, l:source_kind)
    return s:custom.default_actions[l:source_kind]
  endif

  " Source custom default actions.
  if has_key(l:source.default_action, a:kind_name)
    return l:source.default_action[a:kind_name]
  endif

  " Source/* custom default actions.
  if has_key(s:custom.default_actions, l:source_kind_wild)
    return s:custom.default_actions[l:source_kind_wild]
  endif

  " Source/* default actions.
  if has_key(l:source.default_action, '*')
    return l:source.default_action['*']
  endif

  " Kind custom default actions.
  if has_key(s:custom.default_actions, a:kind_name)
    return s:custom.default_actions[a:kind_name]
  endif

  " Kind default actions.
  return unite#get_kinds(a:kind_name).default_action
endfunction"}}}
function! unite#escape_match(str)"{{{
  return substitute(substitute(escape(a:str, '~"\.^$[]'), '\*\@<!\*', '[^/]*', 'g'), '\*\*\+', '.*', 'g')
endfunction"}}}
function! unite#complete_source(arglead, cmdline, cursorpos)"{{{
  if empty(s:static)
    " Initialize load.
    call s:load_default_scripts()
  endif

  let l:sources = extend(copy(s:static.sources), s:dynamic.sources)
  return filter(sort(keys(l:sources))+s:unite_options, 'stridx(v:val, a:arglead) == 0')
endfunction"}}}
function! unite#complete_buffer(arglead, cmdline, cursorpos)"{{{
  let l:buffer_list = map(filter(range(1, bufnr('$')), 'getbufvar(v:val, "&filetype") ==# "unite"'), 'getbufvar(v:val, "unite").buffer_name')

  return filter(l:buffer_list, printf('stridx(v:val, %s) == 0', string(a:arglead)))
endfunction"}}}
function! unite#invalidate_cache(source_name)  "{{{
  for l:source in unite#get_current_unite().sources
    if l:source.name ==# a:source_name
      let l:source.unite__is_invalidate = 1
    endif
  endfor
endfunction"}}}
function! unite#force_redraw() "{{{
  call s:redraw(1)
endfunction"}}}
function! unite#redraw() "{{{
  call s:redraw(0)
endfunction"}}}
function! unite#redraw_line(...) "{{{
  let l:linenr = a:0 > 0 ? a:1 : line('.')
  if l:linenr <= unite#get_current_unite().prompt_linenr || &filetype !=# 'unite'
    " Ignore.
    return
  endif

  let l:modifiable_save = &l:modifiable
  setlocal modifiable

  let l:candidate = unite#get_unite_candidates()[l:linenr - (unite#get_current_unite().prompt_linenr+1)]
  call setline(l:linenr, s:convert_line(l:candidate))

  let &l:modifiable = l:modifiable_save
endfunction"}}}
function! unite#quick_match_redraw() "{{{
  let l:modifiable_save = &l:modifiable
  setlocal modifiable

  call setline(unite#get_current_unite().prompt_linenr+1, s:convert_quick_match_lines(unite#get_current_unite().candidates))
  redraw

  let &l:modifiable = l:modifiable_save
endfunction"}}}
function! unite#redraw_status() "{{{
  let l:modifiable_save = &l:modifiable
  setlocal modifiable

  call setline(s:LNUM_STATUS, 'Sources: ' . join(unite#loaded_source_names_with_args(), ', '))

  let &l:modifiable = l:modifiable_save
endfunction"}}}
function! unite#redraw_candidates() "{{{
  let l:candidates = unite#gather_candidates()

  let l:modifiable_save = &l:modifiable
  setlocal modifiable

  let l:lines = s:convert_lines(l:candidates)
  if len(l:lines) < len(unite#get_current_unite().candidates)
    if mode() !=# 'i' && line('.') == unite#get_current_unite().prompt_linenr
      silent! execute (unite#get_current_unite().prompt_linenr+1).',$delete _'
      startinsert!
    else
      let l:pos = getpos('.')
      silent! execute (unite#get_current_unite().prompt_linenr+1).',$delete _'
      call setpos('.', l:pos)
    endif
  endif
  call setline(unite#get_current_unite().prompt_linenr+1, l:lines)

  let &l:modifiable = l:modifiable_save

  let l:unite = unite#get_current_unite()
  let l:unite.candidates = l:candidates
endfunction"}}}
function! unite#get_marked_candidates() "{{{
  return sort(filter(copy(unite#get_unite_candidates()), 'v:val.unite__is_marked'), 's:compare_marked_candidates')
endfunction"}}}
function! unite#get_input()"{{{
  let l:unite = unite#get_current_unite()
  " Prompt check.
  if stridx(getline(l:unite.prompt_linenr), l:unite.prompt) != 0
    let l:modifiable_save = &l:modifiable
    setlocal modifiable

    " Restore prompt.
    call setline(l:unite.prompt_linenr, l:unite.prompt
          \ . getline(l:unite.prompt_linenr))

    let &l:modifiable = l:modifiable_save
  endif

  return getline(l:unite.prompt_linenr)[len(l:unite.prompt):]
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
    let l:candidates += l:source.unite__candidates
  endfor

  return l:candidates
endfunction"}}}
function! unite#get_current_unite() "{{{
  return exists('b:unite') ? b:unite : s:current_unite
endfunction"}}}
function! unite#set_search_pattern(pattern) "{{{
  let l:unite = unite#get_current_unite()
  let l:unite.search_pattern_save = a:pattern
endfunction"}}}

" Utils.
function! unite#print_error(message)"{{{
  call s:print_buffer('!!!' . a:message . '!!!')

  echohl WarningMsg | echomsg a:message | echohl None
endfunction"}}}
function! unite#print_message(message)"{{{
  if &filetype ==# 'unite'
    call s:print_buffer(a:message)
  else
    call add(s:unite_cached_message, a:message)
  endif
endfunction"}}}
function! unite#substitute_path_separator(path)"{{{
  return unite#util#substitute_path_separator(a:path)
endfunction"}}}
function! unite#path2directory(path)"{{{
  return unite#util#path2directory(a:path)
endfunction"}}}
function! s:print_buffer(message)"{{{
  if &filetype ==# 'unite'
    let l:modifiable_save = &l:modifiable
    setlocal modifiable
    let l:unite = unite#get_current_unite()
    call append(l:unite.prompt_linenr-1, a:message)
    let l:unite.prompt_linenr += 1
    let &l:modifiable = l:modifiable_save
    call s:on_cursor_moved()

    syntax clear uniteInputLine
    execute 'syntax match uniteInputLine'
          \ '/\%'.l:unite.prompt_linenr.'l.*/'
          \ 'contains=uniteInputPrompt,uniteInputPromptError,uniteInputSpecial'
  endif
endfunction"}}}
"}}}

" Command functions.
function! unite#start(sources, ...)"{{{
  if empty(s:static)
    " Initialize load.
    call s:load_default_scripts()
  endif

  " Save context.
  let l:context = a:0 >= 1 ? a:1 : {}
  if !has_key(l:context, 'input')
    let l:context.input = ''
  endif
  if !has_key(l:context, 'start_insert')
    let l:context.start_insert = g:unite_enable_start_insert
  endif
  if has_key(l:context, 'no_start_insert')
        \ && l:context.no_start_insert
    " Disable start insert.
    let l:context.start_insert = 0
  endif
  if !has_key(l:context, 'complete')
    let l:context.complete = 0
  endif
  if !has_key(l:context, 'col')
    let l:context.col = col('.')
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
  if !has_key(l:context, 'immediately')
    let l:context.immediately = 0
  endif
  if !has_key(l:context, 'auto_preview')
    let l:context.auto_preview = 0
  endif
  if !has_key(l:context, 'vertical')
    let l:context.vertical = g:unite_enable_split_vertically
  endif
  if has_key(l:context, 'horizontal')
    " Disable vertically.
    let l:context.vertical = 0
  endif
  if !has_key(l:context, 'direction')
    let l:context.direction = g:unite_split_rule
  endif
  let l:context.is_redraw = 0

  try
    call s:initialize_current_unite(a:sources, l:context)
  catch /^Invalid source/
    return
  endtry

  " Force caching.
  let s:current_unite.last_input = l:context.input
  let s:current_unite.input = l:context.input
  call s:recache_candidates(l:context.input, 1)

  if l:context.immediately
    let l:candidates = unite#gather_candidates()

    " Immediately action.
    if empty(l:candidates)
      " Ignore.
      return
    elseif len(l:candidates) == 1
      " Default action.
      call unite#mappings#do_action(l:context.default_action, l:candidates[0])
      return
    endif
  endif

  call s:initialize_unite_buffer()

  setlocal modifiable

  let l:unite = unite#get_current_unite()

  silent % delete _
  call unite#redraw_status()
  call setline(l:unite.prompt_linenr, l:unite.prompt . l:unite.context.input)
  for message in s:unite_cached_message
    call s:print_buffer(message)
  endfor
  call unite#redraw_candidates()

  if l:unite.context.start_insert || l:unite.context.complete
    let l:unite.is_insert = 1
    execute l:unite.prompt_linenr
    normal! 0z.
    startinsert!
  else
    let l:unite.is_insert = 0
    execute (l:unite.prompt_linenr+1)
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
  let l:unite = unite#get_current_unite()
  let l:unite.winnr = l:winnr
  let l:unite.win_rest_cmd = l:win_rest_cmd
  let l:unite.redrawtime_save = &redrawtime
  let l:unite.hlsearch_save = &hlsearch
  let l:unite.search_pattern_save = @/

  let s:current_unite = b:unite

  setlocal modifiable

  if g:unite_enable_start_insert
        \ || l:unite.context.start_insert || l:unite.context.complete
    let l:unite.is_insert = 1
    execute l:unite.prompt_linenr
    normal! 0z.
    startinsert!
  else
    let l:unite.is_insert = 0
    execute (l:unite.prompt_linenr+1)
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
  let s:current_unite = b:unite
  let l:unite = s:current_unite

  " Highlight off.
  let @/ = l:unite.search_pattern_save

  " Restore options.
  if exists('&redrawtime')
    let &redrawtime = l:unite.redrawtime_save
  endif
  let &hlsearch = l:unite.hlsearch_save

  nohlsearch
  match

  if !l:unite.has_preview_window
    " Close preview window.
    pclose!
  endif

  " Call finalize functions.
  for l:source in unite#loaded_sources_list()
    if has_key(l:source.hooks, 'on_close')
      call l:source.hooks.on_close(l:source.args, l:source.unite__context)
    endif
  endfor

  if winnr('$') != 1
    if !a:is_force && l:unite.context.no_quit
      if winnr('#') > 0
        wincmd p
      endif
    else
      close!
      execute l:unite.winnr . 'wincmd w'

      if winnr('$') != 1
        execute l:unite.win_rest_cmd
      endif
    endif
  endif

  if l:unite.context.complete
    if l:unite.context.col < col('$')
      startinsert
    else
      startinsert!
    endif
  else
    stopinsert
    redraw!
  endif
endfunction"}}}

function! s:load_default_scripts()"{{{
  " Gathering all sources and kind name.
  let s:static.sources = {}
  let s:static.kinds = {}
  let s:static.matchers = {}
  let s:static.sorters = {}

  for l:key in ['sources', 'kinds', 'matchers', 'sorters']
    for l:name in map(split(globpath(&runtimepath, 'autoload/unite/' . l:key . '/*.vim'), '\n'),
          \ 'fnamemodify(v:val, ":t:r")')

      let l:define = {'unite#' . l:key . '#' . l:name . '#define'}()
      for l:dict in (type(l:define) == type([]) ? l:define : [l:define])
        if !empty(l:dict) && !has_key(s:static[l:key], l:dict.name)
          let s:static[l:key][l:dict.name] = l:dict
        endif
      endfor
      unlet l:define
    endfor
  endfor
endfunction"}}}
function! s:initialize_loaded_sources(sources, context)"{{{
  let l:all_sources = s:initialize_sources()
  let l:sources = []

  let l:number = 0
  for [l:source_name, l:args] in map(a:sources, 'type(v:val) == type([]) ? [v:val[0], v:val[1:]] : [v:val, []]')
    if !has_key(l:all_sources, l:source_name)
      call unite#util#print_error('Invalid source name "' . l:source_name . '" is detected.')
      throw 'Invalid source'
    endif

    let l:source = deepcopy(l:all_sources[l:source_name])
    let l:source.args = l:args
    let l:source.unite__is_invalidate = 1

    let l:source.unite__context = deepcopy(a:context)
    let l:source.unite__candidates = []
    let l:source.unite__cached_candidates = []
    let l:source.unite__number = l:number
    let l:number += 1

    call add(l:sources, l:source)
  endfor

  return l:sources
endfunction"}}}
function! s:initialize_sources()"{{{
  let l:sources = extend(deepcopy(s:static.sources), deepcopy(s:dynamic.sources))

  for l:source in values(l:sources)
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
    if !has_key(l:source, 'description')
      let l:source.description = ''
    endif
    if !has_key(l:source, 'matcher')
      let l:source.matcher = unite#matchers#default#get()
    endif
    if type(l:source.matcher) != type([])
      let l:source.matcher = [l:source.matcher]
    endif
    if !has_key(l:source, 'sorter')
      let l:source.sorter = unite#sorters#default#get()
    endif
    if type(l:source.sorter) != type([])
      let l:source.sorter = [l:source.sorter]
    endif
    if l:source.is_volatile
          \ && !has_key(l:source, 'change_candidates')
      let l:source.change_candidates = l:source.gather_candidates
    endif
  endfor

  return l:sources
endfunction"}}}
function! s:initialize_kinds()"{{{
  let l:kinds = extend(copy(s:static.kinds), s:dynamic.kinds)
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
function! s:initialize_matchers()"{{{
  let l:matchers = extend(copy(s:static.matchers), s:dynamic.matchers)
  for l:matcher in values(l:matchers)
    if !has_key(l:matcher, 'hooks')
      let l:matcher.hooks = {}
    endif
  endfor

  return l:matchers
endfunction"}}}
function! s:initialize_sorters()"{{{
  let l:sorters = extend(copy(s:static.sorters), s:dynamic.sorters)
  for l:sorter in values(l:sorters)
  endfor

  return l:sorters
endfunction"}}}
function! s:recache_candidates(input, is_force)"{{{
  " Save options.
  let l:ignorecase_save = &ignorecase

  if g:unite_enable_smart_case && a:input =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase = g:unite_enable_ignore_case
  endif

  let l:input = s:get_substitute_input(a:input)
  let l:input_len = unite#util#strchars(l:input)
  let l:unite = unite#get_current_unite()

  for l:source in unite#loaded_sources_list()
    " Check required pattern length.
    if l:input_len < l:source.required_pattern_length
      let l:source.unite__candidates = []
      continue
    endif

    " Set context.
    let l:source.unite__context.input = l:input
    let l:source.unite__context.source = l:source
    let l:source.unite__context.is_force = a:is_force
    let l:source.unite__context.is_redraw = l:unite.context.is_redraw

    if !l:source.is_volatile && has_key(l:source, 'gather_candidates') && (a:is_force || l:source.unite__is_invalidate)
      " Recaching.
      let l:source.unite__cached_candidates = copy(l:source.gather_candidates(l:source.args, l:source.unite__context))
      let l:source.unite__is_invalidate = 0
    endif

    if has_key(l:source, 'async_gather_candidates')
      let l:source.unite__cached_candidates += l:source.async_gather_candidates(l:source.args, l:source.unite__context)
    endif

    let l:source_candidates = copy(l:source.unite__cached_candidates)

    let l:custom_source = has_key(s:custom.source, l:source.name) ?
          \ s:custom.source[l:source.name] : {}

    if has_key(l:source, 'change_candidates')
      let l:source_candidates += l:source.change_candidates(l:source.args, l:source.unite__context)
    endif

    if l:input != ''
      let l:matcher_names = has_key(l:custom_source, 'matchers') ?
            \ l:custom_source.matchers : l:source.matcher
      for l:matcher_name in l:matcher_names
        if has_key(l:unite.matchers, l:matcher_name)
          let l:source_candidates =
                \ l:unite.matchers[l:matcher_name].match(l:source_candidates, l:source.unite__context)
        endif
      endfor
    endif

    " Sort.
    let l:sorter_names = has_key(l:custom_source, 'sorters') ?
          \ l:custom_source.sorters : l:source.sorter
    for l:sorter_name in l:sorter_names
      if has_key(l:unite.sorters, l:sorter_name)
        let l:source_candidates =
              \ l:unite.sorters[l:sorter_name].sort(l:source_candidates, l:source.unite__context)
      endif
    endfor

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

    let l:source.unite__candidates = l:source_candidates
  endfor

  let &ignorecase = l:ignorecase_save
endfunction"}}}
function! s:convert_quick_match_lines(candidates)"{{{
  let [l:max_width, l:max_source_name] = s:adjustments(winwidth(0), unite#get_current_unite().max_source_name, 5)
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
  let [l:max_width, l:max_source_name] = s:adjustments(winwidth(0), unite#get_current_unite().max_source_name, 2)

  return map(copy(a:candidates),
        \ '(v:val.unite__is_marked ? "* " : "- ")
        \ . unite#util#truncate(v:val.source, l:max_source_name)
        \ . unite#util#truncate_smart(v:val.abbr, ' . l:max_width .  ', l:max_width/3, "..")')
endfunction"}}}
function! s:convert_line(candidate)"{{{
  let [l:max_width, l:max_source_name] = s:adjustments(winwidth(0), unite#get_current_unite().max_source_name, 2)

  return (a:candidate.unite__is_marked ? '* ' : '- ')
        \ . unite#util#truncate(a:candidate.source, l:max_source_name)
        \ . unite#util#truncate_smart(a:candidate.abbr, l:max_width, l:max_width/3, '..')
endfunction"}}}

function! s:initialize_current_unite(sources, context)"{{{
  let s:unite_cached_message = []

  let l:context = a:context

  if getbufvar(bufnr('%'), '&filetype') ==# 'unite'
    if l:context.input == ''
          \ && unite#get_current_unite().buffer_name ==# l:context.buffer_name
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

  " Check sources.
  let l:sources = s:initialize_loaded_sources(a:sources, a:context)

  " Call initialize functions.
  for l:source in l:sources
    if has_key(l:source.hooks, 'on_init')
      call l:source.hooks.on_init(l:source.args, l:source.unite__context)
    endif
  endfor

  " Set parameters.
  let l:unite = {}
  let l:unite.winnr = l:winnr
  let l:unite.win_rest_cmd = l:win_rest_cmd
  let l:unite.context = l:context
  let l:unite.candidates = []
  let l:unite.sources = l:sources
  let l:unite.kinds = s:initialize_kinds()
  let l:unite.matchers = s:initialize_matchers()
  let l:unite.sorters = s:initialize_sorters()
  let l:unite.buffer_name = (l:context.buffer_name == '') ? 'default' : l:context.buffer_name
  let l:unite.buffer_settings =
        \ s:initialize_buffer_name_settings(l:unite.buffer_name)
  let l:unite.real_buffer_name = l:buffer_name
  let l:unite.prompt = l:context.prompt
  let l:unite.input = l:context.input
  let l:unite.last_input = l:context.input
  let l:unite.bufnr = bufnr('%')
  let l:unite.hlsearch_save = &hlsearch
  let l:unite.search_pattern_save = @/
  let l:unite.prompt_linenr = 2
  let l:unite.max_source_name = len(a:sources) > 1 ?
        \ max(map(copy(a:sources), 'len(v:val[0])')) + 2 : 0
  let l:unite.is_async =
        \ len(filter(copy(l:sources), 'has_key(v:val, "async_gather_candidates")')) > 0

  " Preview windows check.
  let l:unite.has_preview_window =
   \ len(filter(range(1, winnr('$')), 'getwinvar(v:val, "&previewwindow")')) > 0

  let s:current_unite = l:unite
endfunction"}}}
function! s:initialize_unite_buffer()"{{{
  call s:switch_unite_buffer(s:current_unite.real_buffer_name, s:current_unite.context)

  let b:unite = s:current_unite
  let l:unite = unite#get_current_unite()

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
  if has('conceal')
    setlocal conceallevel=3
    setlocal concealcursor=n
  endif

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
    let l:unite.redrawtime_save = &redrawtime
    let &redrawtime = 100
  endif

  " User's initialization.
  setlocal nomodifiable
  setfiletype unite

  if exists('b:current_syntax') && b:current_syntax == 'unite'
    " Set highlight.
    let l:match_prompt = escape(l:unite.prompt, '\/*~.^$[]')
    syntax clear uniteInputPrompt
    execute 'syntax match uniteInputPrompt' '/^'.l:match_prompt.'/ contained'

    syntax clear uniteCandidateSourceName
    if l:unite.max_source_name > 0
      syntax match uniteCandidateSourceName /^- \zs[[:alnum:]_\/-]\+/ contained
      let l:source_padding = 2
    else
      syntax match uniteCandidateSourceName /^-/ contained
      let l:source_padding = 3
    endif
    execute 'syntax match uniteCandidateAbbr' '/\%'.(l:unite.max_source_name+l:source_padding).'c.*/ contained'

    execute 'highlight default link uniteCandidateAbbr'  g:unite_abbr_highlight
  endif
endfunction"}}}
function! s:switch_unite_buffer(buffer_name, context)"{{{
  " Search unite window.
  " Note: must escape file-pattern.
  if bufwinnr(unite#util#escape_file_searching(a:buffer_name)) > 0
    silent execute bufwinnr(unite#util#escape_file_searching(a:buffer_name)) 'wincmd w'
  else
    " Split window.
    execute a:context.direction
          \ a:context.vertical ?
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

  if a:context.vertical
    execute 'vertical resize' a:context.winwidth
  else
    execute 'resize' a:context.winheight
  endif
endfunction"}}}

function! s:redraw(is_force) "{{{
  if &filetype !=# 'unite'
    return
  endif

  let l:unite = unite#get_current_unite()
  let l:input = unite#get_input()
  if !a:is_force && l:input ==# l:unite.last_input
        \ && !l:unite.is_async
    return
  endif

  let l:unite.last_input = l:input
  let l:unite.context.is_redraw = 1

  " Recaching.
  call s:recache_candidates(l:input, a:is_force)

  " Redraw.
  call unite#redraw_candidates()
  let l:unite.context.is_redraw = 0
endfunction"}}}

" Autocmd events.
function! s:on_insert_enter()  "{{{
  if &updatetime > g:unite_update_time
    let l:unite = unite#get_current_unite()
    let l:unite.update_time_save = &updatetime
    let &updatetime = g:unite_update_time
  endif

  setlocal modifiable
endfunction"}}}
function! s:on_insert_leave()  "{{{
  if line('.') == unite#get_current_unite().prompt_linenr
    " Redraw.
    call unite#redraw()
  endif

  if has_key(unite#get_current_unite(), 'update_time_save') && &updatetime < unite#get_current_unite().update_time_save
    let &updatetime = unite#get_current_unite().update_time_save
  endif

  setlocal nomodifiable
endfunction"}}}
function! s:on_cursor_hold_i()  "{{{
  if line('.') == unite#get_current_unite().prompt_linenr
    " Redraw.
    call unite#redraw()

    " Prompt check.
    if col('.') <= len(unite#get_current_unite().prompt)
      startinsert!
    endif
  endif

  if unite#get_current_unite().is_async
    " Ignore key sequences.
    call feedkeys("\<C-r>\<ESC>", 'n')
  endif
endfunction"}}}
function! s:on_cursor_hold()  "{{{
  " Redraw.
  call unite#redraw()

  if unite#get_current_unite().is_async
    " Ignore key sequences.
    call feedkeys("g\<ESC>", 'n')
  endif
endfunction"}}}
function! s:on_cursor_moved()  "{{{
  let l:prompt_linenr = unite#get_current_unite().prompt_linenr
  execute 'setlocal' line('.') == l:prompt_linenr ? 'modifiable' : 'nomodifiable'
  execute 'match' (line('.') <= l:prompt_linenr ?
        \ line('$') <= l:prompt_linenr ?
        \ 'Error /\%'.l:prompt_linenr.'l/' :
        \ g:unite_cursor_line_highlight.' /\%'.(l:prompt_linenr+1).'l/' :
        \ g:unite_cursor_line_highlight.' /\%'.line('.').'l/')

  if unite#get_current_unite().context.auto_preview
    if !unite#get_current_unite().has_preview_window
      pclose!
    endif

    call unite#mappings#do_action('preview')
    if line('.') != l:prompt_linenr
      normal! zz
    endif
  endif
endfunction"}}}

" Internal helper functions."{{{
function! s:adjustments(currentwinwidth, the_max_source_name, size)"{{{
  let l:max_width = a:currentwinwidth - a:the_max_source_name - a:size
  if l:max_width < 20
    return [a:currentwinwidth - a:size, 0]
  else
    return [l:max_width, a:the_max_source_name]
  endif
endfunction"}}}
function! s:compare_substitute_patterns(pattern_a, pattern_b)"{{{
  return a:pattern_b.priority - a:pattern_a.priority
endfunction"}}}
function! s:compare_marked_candidates(candidate_a, candidate_b)"{{{
  return a:candidate_a.unite__marked_time - a:candidate_b.unite__marked_time
endfunction"}}}
function! s:extend_actions(self_func, action_table1, action_table2, ...)"{{{
  let l:filterd_table = s:filter_self_func(a:action_table2, a:self_func)

  if a:0 > 0
    for l:action in values(l:filterd_table)
      let l:action.from = a:1
    endfor
  endif

  return extend(a:action_table1, l:filterd_table, 'keep')
endfunction"}}}
function! s:filter_alias_action(action_table, alias_table, from)"{{{
  for [l:alias_name, l:alias_action] in items(a:alias_table)
    if l:alias_action ==# 'nop'
      if has_key(a:action_table, l:alias_name)
        " Delete nop action.
        call remove(a:action_table, l:alias_name)
      endif
    else
      let a:action_table[l:alias_name] = a:action_table[l:alias_action]
      let a:action_table[l:alias_name].from = a:from
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
  let l:unite = unite#get_current_unite()
  return a:0 == 0 ? l:unite.sources : get(l:unite.sources, a:1, {})
endfunction"}}}
function! s:get_substitute_input(input)"{{{
  let l:input = a:input

  let l:unite = unite#get_current_unite()
  if has_key(s:buffer_name_settings, l:unite.buffer_name)
    let l:substitute_patterns =
          \ s:buffer_name_settings[l:unite.buffer_name].substitute_patterns
    if l:unite.input != '' && stridx(l:input, l:unite.input) == 0
      " Substitute after input.
      let l:input_save = l:input
      let l:subst = l:input_save[len(l:unite.input) :]
      let l:input = l:input_save[: len(l:unite.input)-1]
    else
      " Substitute all input.
      let l:subst = l:input
      let l:input = ''
    endif

    for l:pattern in sort(values(l:substitute_patterns),
          \ 's:compare_substitute_patterns')
      let l:subst = substitute(l:subst, l:pattern.pattern, l:pattern.subst, 'g')
    endfor

    let l:input .= l:subst
  endif

  return l:input
endfunction"}}}
"}}}

" vim: foldmethod=marker
