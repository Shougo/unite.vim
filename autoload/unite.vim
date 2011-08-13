"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 13 Aug 2011.
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
" Version: 2.2, for Vim 7.0
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! unite#version()"{{{
  return str2nr(printf('%02d%02d%03d', 2, 2, 0))
endfunction"}}}

" User functions."{{{
function! unite#get_substitute_pattern(buffer_name)"{{{
  let l:buffer_name = (a:buffer_name == '' ? 'default' : a:buffer_name)

  return has_key(s:buffer_name_options, l:buffer_name) ?
        \ s:buffer_name_options[l:buffer_name].substitute_patterns : ''
endfunction"}}}
function! unite#set_substitute_pattern(buffer_name, pattern, subst, ...)"{{{
  let l:buffer_name = (a:buffer_name == '' ? 'default' : a:buffer_name)

  for key in split(l:buffer_name, ',')
    let l:substitute_patterns = has_key(s:buffer_name_options, key) ?
          \ unite#get_buffer_name_option(key, 'substitute_patterns') : {}

    if has_key(l:substitute_patterns, a:pattern)
          \ && a:pattern == ''
      call remove(l:substitute_patterns, a:pattern)
    else
      let l:substitute_patterns[a:pattern] = {
            \ 'pattern' : a:pattern,
            \ 'subst' : a:subst, 'priority' : (a:0 > 0 ? a:1 : 0),
            \ }
    endif

    call unite#set_buffer_name_option(key, 'substitute_patterns', l:substitute_patterns)
  endfor
endfunction"}}}
function! unite#set_buffer_name_option(buffer_name, option_name, value)"{{{
  let l:buffer_name = (a:buffer_name == '' ? 'default' : a:buffer_name)

  for key in split(l:buffer_name, ',')
    if !has_key(s:buffer_name_options, key)
      let s:buffer_name_options[key] = {}
    endif

    let s:buffer_name_options[key][a:option_name] = a:value
  endfor
endfunction"}}}
function! unite#get_buffer_name_option(buffer_name, option_name)"{{{
  let l:buffer_name = (a:buffer_name == '' ? 'default' : a:buffer_name)

  return s:buffer_name_options[a:buffer_name][a:option_name]
endfunction"}}}
function! unite#custom_filters(source_name, filters)"{{{
  let l:filters = type(a:filters) == type([]) ?
        \ a:filters : [a:filters]
  for key in split(a:source_name, ',')
    let s:custom.filters[key] = l:filters
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
function! unite#custom_max_candidates(source_name, max)"{{{
  for key in split(a:source_name, ',')
    let s:custom.max_candidates[key] = a:max
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
function! unite#define_filter(filter)"{{{
  if type(a:filter) == type([])
    for l:filter in a:filter
      let s:dynamic.filters[l:filter.name] = l:filter
    endfor
  else
    let s:dynamic.filters[a:filter.name] = a:filter
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
function! unite#undef_filter(name)"{{{
  if has_key(s:dynamic.filters, a:name)
    call remove(s:dynamic.filters, a:name)
  endif
endfunction"}}}

function! unite#do_action(action)
  return printf("%s:\<C-u>call unite#mappings#do_action(%s)\<CR>",
        \             (mode() ==# 'i' ? "\<C-o>" : ''), string(a:action))
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
let s:is_initialized_unite_buffer = 0

let s:static = {}

let s:dynamic = {}
let s:dynamic.sources = {}
let s:dynamic.kinds = {}
let s:dynamic.filters = {}

let s:custom = {}
let s:custom.actions = {}
let s:custom.default_actions = {}
let s:custom.aliases = {}
let s:custom.filters = {}
let s:custom.source = {}
let s:custom.max_candidates = {}

let s:buffer_name_options = {}
call unite#set_substitute_pattern('files', '^\~',
      \ substitute(unite#util#substitute_path_separator($HOME), ' ', '\\\\ ', 'g'), -100)
call unite#set_substitute_pattern('files', '[^~.*]\ze/', '\0*', 100)
call unite#set_substitute_pattern('files', '/\ze[^~.*]', '/*', 100)
call unite#set_substitute_pattern('files', '\.', '*.', 1000)
call unite#set_buffer_name_option('files', 'smartcase', 0)
call unite#set_buffer_name_option('files', 'ignorecase', 1)

let s:unite_options = [
      \ '-buffer-name=', '-input=', '-prompt=',
      \ '-default-action=', '-start-insert','-no-start-insert', '-no-quit',
      \ '-winwidth=', '-winheight=',
      \ '-immediately', '-auto-preview', '-complete',
      \ '-vertical', '-horizontal', '-direction=',
      \ '-verbose', '-auto-resize',
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
function! unite#get_filters(...)"{{{
  let l:all_filters = s:initialize_filters()
  return a:0 == 0 ? l:all_filters : get(l:all_filters, a:1, {})
endfunction"}}}
"}}}

" Helper functions."{{{
function! unite#is_win()"{{{
  return unite#util#is_win()
endfunction"}}}
function! unite#loaded_source_names()"{{{
  return map(copy(unite#loaded_sources_list()), 'v:val.name')
endfunction"}}}
function! unite#loaded_source_names_string()"{{{
  return join(unite#loaded_source_names())
endfunction"}}}
function! unite#loaded_source_names_with_args()"{{{
  return map(copy(unite#loaded_sources_list()), 'join(insert(filter(copy(v:val.args), "type(v:val) < 1"), v:val.name), ":")')
endfunction"}}}
function! unite#loaded_sources_list()"{{{
  return s:get_loaded_sources()
endfunction"}}}
function! unite#get_unite_candidates()"{{{
  return unite#get_current_unite().candidates
endfunction"}}}
function! unite#get_current_candidate(...)"{{{
  let l:linenr = a:0 > 1? a:1 : line('.')
  let l:num = l:linenr <= unite#get_current_unite().prompt_linenr ?
        \ 0 : l:linenr - (unite#get_current_unite().prompt_linenr+1)

  return get(unite#get_unite_candidates(), l:num, {})
endfunction"}}}
function! unite#get_context()"{{{
  return unite#get_current_unite().context
endfunction"}}}
" function! unite#get_action_table(source_name, kind_name, self_func, [is_parent_action])
function! unite#get_action_table(source_name, kind_name, self_func, ...)"{{{
  let l:kind = unite#get_kinds(a:kind_name)
  let l:source = unite#get_sources(a:source_name)
  if empty(l:source)
    call unite#print_error('source "' . a:source_name . '" is not found.')
    return {}
  endif

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
  for [l:action_name, l:action] in items(l:action_table)
    if !has_key(l:action, 'name')
      let l:action.name = l:action_name
    endif
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
function! unite#get_alias_table(source_name, kind_name)"{{{
  let l:kind = unite#get_kinds(a:kind_name)
  let l:source = unite#get_sources(a:source_name)

  let l:table = l:kind.alias_table

  let l:source_kind = 'source/'.a:source_name.'/'.a:kind_name
  let l:source_kind_wild = 'source/'.a:source_name.'/*'

  " Kind custom aliases.
  if has_key(s:custom.aliases, a:kind_name)
    let l:table = extend(l:table, s:custom.aliases[a:kind_name])
  endif

  " Source/* aliases.
  if has_key(l:source.alias_table, '*')
    let l:table = extend(l:table, l:source.alias_table['*'])
  endif

  " Source/* custom aliases.
  if has_key(s:custom.aliases, l:source_kind_wild)
    let l:table = extend(l:table, s:custom.aliases[l:source_kind_wild])
  endif

  " Source/kind aliases.
  if has_key(s:custom.aliases, l:source_kind)
    let l:table = extend(l:table, s:custom.aliases[l:source_kind])
  endif

  " Source/kind custom aliases.
  if has_key(l:source.alias_table, a:kind_name)
    let l:table = extend(l:table, l:source.alias_table[a:kind_name])
  endif

  return l:table
endfunction"}}}
function! unite#get_default_action(source_name, kind_name)"{{{
  let l:source = unite#get_sources(a:source_name)

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
  return substitute(substitute(escape(a:str, '~\.^$[]'), '\*\@<!\*', '[^/]*', 'g'), '\*\*\+', '.*', 'g')
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
  let l:buffer_list = map(filter(range(1, bufnr('$')), '
        \ getbufvar(v:val, "&filetype") ==# "unite" &&
        \ !getbufvar(v:val, "unite").context.temporary'),
        \ 'getbufvar(v:val, "unite").buffer_name')

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
  call setline(l:linenr, s:convert_lines([l:candidate])[0])

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
    let l:pos = getpos('.')
    silent! execute (unite#get_current_unite().prompt_linenr+1).',$delete _'
    execute 'normal!' "1z\<Enter>"
    call setpos('.', l:pos)
  endif
  call setline(unite#get_current_unite().prompt_linenr+1, l:lines)

  let &l:modifiable = l:modifiable_save

  let l:unite = unite#get_current_unite()
  let l:unite.candidates = l:candidates

  if l:unite.context.auto_resize
        \ && l:unite.prompt_linenr + len(l:candidates)
        \      < l:unite.context.winheight
    " Auto resize.
    let l:pos = getpos('.')
    execute 'resize' l:unite.prompt_linenr + len(l:candidates)
    execute 'normal!' "1z\<Enter>"
    call setpos('.', l:pos)
  endif
endfunction"}}}
function! unite#get_marked_candidates() "{{{
  return unite#util#sort_by(filter(copy(unite#get_unite_candidates()),
        \ 'v:val.unite__is_marked'), 'v:val.unite__marked_time')
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

  " Post filter.
  let l:unite = unite#get_current_unite()
  for l:filter_name in unite#get_buffer_name_option(
        \ l:unite.buffer_name, 'filters')
    if has_key(l:unite.filters, l:filter_name)
      let l:candidates =
            \ l:unite.filters[l:filter_name].filter(l:candidates, l:unite.context)
    endif
  endfor

  return l:candidates
endfunction"}}}
function! unite#get_current_unite() "{{{
  return exists('b:unite') && s:is_initialized_unite_buffer ? b:unite : s:current_unite
endfunction"}}}

" Utils.
function! unite#print_error(message)"{{{
  let l:message = type(a:message) == type([]) ?
        \ l:message : [a:message]
  for l:mes in l:message
    call unite#print_message('!!!'.l:mes.'!!!')

    echohl WarningMsg | echomsg l:mes | echohl None
  endfor
endfunction"}}}
function! unite#print_message(message)"{{{
  if &filetype ==# 'unite'
    call s:print_buffer(a:message)
  else
    call add(s:unite_cached_message, a:message)
  endif
endfunction"}}}
function! unite#clear_message()"{{{
  if &filetype ==# 'unite'
    let l:unite = unite#get_current_unite()
    if l:unite.prompt_linenr > 2
      let l:modifiable_save = &l:modifiable
      setlocal modifiable

      let l:pos = getpos('.')
      silent! execute '2,'.(l:unite.prompt_linenr-1).'delete _'
      let l:pos[1] -= l:unite.prompt_linenr-2
      call setpos('.', l:pos)
      normal! zb
      if mode() ==# 'i' && l:pos[2] == col('$')
        startinsert!
      endif

      let l:unite.prompt_linenr = 2

      let &l:modifiable = l:modifiable_save
      call s:on_cursor_moved()

      if exists('b:current_syntax') && b:current_syntax ==# 'unite'
        syntax clear uniteInputLine
        execute 'syntax match uniteInputLine'
              \ '/\%'.l:unite.prompt_linenr.'l.*/'
              \ 'contains=uniteInputPrompt,uniteInputPromptError,uniteInputSpecial'
      endif
    endif
  endif
  let s:unite_cached_message = []
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
    let l:pos = getpos('.')
    call append(l:unite.prompt_linenr-1, a:message)
    let l:len = type(a:message) == type([]) ?
          \ len(a:message) : 1
    let l:unite.prompt_linenr += l:len

    let l:pos[1] += l:len
    call setpos('.', l:pos)
    normal! zb
    if mode() ==# 'i' && l:pos[2] == col('$')
      startinsert!
    endif

    let &l:modifiable = l:modifiable_save
    call s:on_cursor_moved()

    if exists('b:current_syntax') && b:current_syntax ==# 'unite'
      syntax clear uniteInputLine
      execute 'syntax match uniteInputLine'
            \ '/\%'.l:unite.prompt_linenr.'l.*/'
            \ 'contains=uniteInputPrompt,uniteInputPromptError,uniteInputSpecial'
    endif
  endif
endfunction"}}}
"}}}

" Command functions.
function! unite#start(sources, ...)"{{{
  " Check command line window.
  if s:is_cmdwin()
    echoerr 'Command line buffer is detected!'
    echoerr 'Please close command line buffer.'
    return
  endif

  let l:context = a:0 >= 1 ? a:1 : {}
  call s:initialize_context(l:context)

  let s:is_initialized_unite_buffer = 0

  try
    call s:initialize_current_unite(a:sources, l:context)
  catch /^Invalid source/
    return
  endtry

  " Caching.
  let s:current_unite.last_input = l:context.input
  let s:current_unite.input = l:context.input
  call s:recache_candidates(l:context.input, l:context.is_redraw)

  if l:context.immediately
    let l:candidates = unite#gather_candidates()

    " Immediately action.
    if empty(l:candidates)
      " Ignore.
      let s:is_initialized_unite_buffer = 1
      return
    elseif len(l:candidates) == 1
      " Default action.
      call unite#mappings#do_action(l:context.default_action, [l:candidates[0]])
      let s:is_initialized_unite_buffer = 1
      return
    endif
  endif

  call s:initialize_unite_buffer()

  let s:is_initialized_unite_buffer = 1

  let l:unite = unite#get_current_unite()

  setlocal modifiable

  silent % delete _
  call unite#redraw_status()
  call setline(l:unite.prompt_linenr, l:unite.prompt . l:unite.context.input)
  for message in s:unite_cached_message
    call s:print_buffer(message)
    unlet message
  endfor
  call unite#redraw_candidates()

  if l:unite.context.start_insert || l:unite.context.complete
    let l:unite.is_insert = 1

    execute l:unite.prompt_linenr
    normal! zb

    startinsert!
  else
    let l:positions = unite#get_buffer_name_option(l:unite.buffer_name, 'unite__save_pos')
    let l:key = unite#loaded_source_names_string()
    let l:is_restore = l:unite.context.input == '' &&
          \ has_key(l:positions, l:key)
    if l:is_restore
      " Restore position.
      call setpos('.', l:positions[l:key].pos)
    endif
    let l:candidate = has_key(l:positions, l:key) ?
          \ l:positions[l:key].candidate : {}

    let l:unite.is_insert = 0

    if !l:is_restore ||
          \ l:candidate != unite#get_current_candidate(l:unite.prompt_linenr+1)
      execute (l:unite.prompt_linenr+1)
      normal! zb
    endif
    normal! 0
  endif
endfunction"}}}
function! unite#start_temporary(sources, new_context, buffer_name)"{{{
  " Get current context.
  let l:context = deepcopy(unite#get_context())
  let l:context.old_buffer_info = insert(l:context.old_buffer_info,
        \ { 'buffer_name' : unite#get_current_unite().buffer_name,
        \   'pos' : getpos('.'), })

  let l:context.buffer_name = a:buffer_name
  let l:context.temporary = 1
  let l:context.input = ''
  let l:context.auto_preview = 0
  let l:context.default_action = 'default'

  " Overwrite context.
  let l:context = extend(l:context, a:new_context)

  call unite#force_quit_session()
  call unite#start(a:sources, l:context)
endfunction"}}}
function! unite#resume(buffer_name)"{{{
  " Check command line window.
  if s:is_cmdwin()
    echoerr 'Command line buffer is detected!'
    echoerr 'Please close command line buffer.'
    return
  endif

  if a:buffer_name == ''
    " Use last unite buffer.
    if !bufexists(s:last_unite_bufnr)
      call unite#util#print_error('No unite buffer.')
      return
    endif

    let l:bufnr = s:last_unite_bufnr
  else
    let l:buffer_dict = {}
    for l:unite in map(filter(range(1, bufnr('$')),
          \ 'getbufvar(v:val, "&filetype") ==# "unite" && !getbufvar(v:val, "unite").context.temporary'),
          \ 'getbufvar(v:val, "unite")')
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

  let l:unite = getbufvar(l:bufnr, 'unite')
  let l:context = l:unite.context

  call s:switch_unite_buffer(bufname(l:bufnr), l:context)

  " Set parameters.
  let l:unite = unite#get_current_unite()
  let l:unite.winnr = l:winnr
  let l:unite.win_rest_cmd = l:win_rest_cmd
  let l:unite.redrawtime_save = &redrawtime
  let l:unite.access_time = localtime()

  let s:current_unite = l:unite

  if g:unite_enable_start_insert
    let l:unite.is_insert = 1

    execute l:unite.prompt_linenr
    normal! zb

    startinsert!
  else
    let l:positions = unite#get_buffer_name_option(l:unite.buffer_name, 'unite__save_pos')
    let l:key = unite#loaded_source_names_string()
    let l:is_restore = has_key(l:positions, l:key)
    let l:candidate = unite#get_current_candidate()

    if l:is_restore
      " Restore position.
      call setpos('.', l:positions[l:key].pos)
    endif

    let l:unite.is_insert = 0

    if !l:is_restore
          \ || l:candidate != unite#get_current_candidate()
      execute (l:unite.prompt_linenr+1)
    endif
    normal! 0zb
  endif
endfunction"}}}
function! s:initialize_context(context)"{{{
  if !has_key(a:context, 'input')
    let a:context.input = ''
  endif
  if !has_key(a:context, 'start_insert')
    let a:context.start_insert = g:unite_enable_start_insert
  endif
  if has_key(a:context, 'no_start_insert')
        \ && a:context.no_start_insert
    " Disable start insert.
    let a:context.start_insert = 0
  endif
  if !has_key(a:context, 'complete')
    let a:context.complete = 0
  endif
  if !has_key(a:context, 'col')
    let a:context.col = col('.')
  endif
  if !has_key(a:context, 'no_quit')
    let a:context.no_quit = 0
  endif
  if !has_key(a:context, 'buffer_name')
    let a:context.buffer_name = 'default'
  endif
  if !has_key(a:context, 'prompt')
    let a:context.prompt = '> '
  endif
  if !has_key(a:context, 'default_action')
    let a:context.default_action = 'default'
  endif
  if !has_key(a:context, 'winwidth')
    let a:context.winwidth = g:unite_winwidth
  endif
  if !has_key(a:context, 'winheight')
    let a:context.winheight = g:unite_winheight
  endif
  if !has_key(a:context, 'immediately')
    let a:context.immediately = 0
  endif
  if !has_key(a:context, 'auto_preview')
    let a:context.auto_preview = 0
  endif
  if !has_key(a:context, 'vertical')
    let a:context.vertical = g:unite_enable_split_vertically
  endif
  if has_key(a:context, 'horizontal')
    " Disable vertically.
    let a:context.vertical = 0
  endif
  if !has_key(a:context, 'direction')
    let a:context.direction = g:unite_split_rule
  endif
  if !has_key(a:context, 'temporary')
    let a:context.temporary = 0
  endif
  if !has_key(a:context, 'verbose')
    let a:context.verbose = 0
  endif
  if !has_key(a:context, 'auto_resize')
    let a:context.auto_resize = 0
  endif
  if !has_key(a:context, 'old_buffer_info')
    let a:context.old_buffer_info = []
  endif
  let a:context.is_redraw = 0
endfunction"}}}

function! unite#force_quit_session()  "{{{
  call s:quit_session(1)

  let l:context = unite#get_context()
  if l:context.temporary
    call s:resume_from_temporary(l:context)
  endif
endfunction"}}}
function! unite#quit_session()  "{{{
  call s:quit_session(0)

  let l:context = unite#get_context()
  if l:context.temporary
    call s:resume_from_temporary(l:context)
  endif
endfunction"}}}
function! s:quit_session(is_force)  "{{{
  if &filetype !=# 'unite'
    return
  endif

  " Save unite value.
  let s:current_unite = b:unite
  let l:unite = s:current_unite
  let l:context = l:unite.context

  let l:key = unite#loaded_source_names_string()

  " Save position.
  let l:positions = unite#get_buffer_name_option(
        \ l:unite.buffer_name, 'unite__save_pos')
  let l:positions[l:key] = {
        \ 'pos' : getpos('.'),
        \ 'candidate' : unite#get_current_candidate(),
        \ }

  if l:context.input != ''
    " Save input.
    let l:inputs = unite#get_buffer_name_option(
          \ l:unite.buffer_name, 'unite__inputs')
    if !has_key(l:inputs, l:key)
      let l:inputs[l:key] = []
    endif
    call insert(filter(l:inputs[l:key],
          \ 'v:val !=# l:unite.context.input'), l:context.input)
  endif

  if winnr('$') != 1
    if !a:is_force && l:context.no_quit
      if winnr('#') > 0
        wincmd p
      endif
    else
      let l:bufname = bufname('%')
      noautocmd close!
      execute l:unite.winnr . 'wincmd w'
      call s:on_buf_unload(l:bufname)
    endif
  endif

  if l:context.complete
    if l:context.col < col('$')
      startinsert
    else
      startinsert!
    endif
  else
    stopinsert
    redraw!
  endif
endfunction"}}}
function! s:resume_from_temporary(context)  "{{{
  " Resume unite buffer.
  let l:buffer_info = a:context.old_buffer_info[0]
  call unite#resume(l:buffer_info.buffer_name)
  call setpos('.', l:buffer_info.pos)
  let a:context.old_buffer_info = a:context.old_buffer_info[1:]
endfunction"}}}

function! s:load_default_scripts()"{{{
  " Gathering all sources and kind name.
  let s:static.sources = {}
  let s:static.kinds = {}
  let s:static.filters = {}

  for l:key in ['sources', 'kinds', 'filters']
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
    let l:source.unite__context.is_async =
          \ has_key(l:source, 'async_gather_candidates')
    let l:source.unite__context.source = l:source
    let l:source.unite__candidates = []
    let l:source.unite__cached_candidates = []
    let l:source.unite__cached_change_candidates = []
    let l:source.unite__number = l:number
    let l:number += 1

    call add(l:sources, l:source)
  endfor

  return l:sources
endfunction"}}}
function! s:initialize_sources()"{{{
  if empty(s:static)
    " Initialize load.
    call s:load_default_scripts()
  endif

  let l:sources = extend(deepcopy(s:static.sources), deepcopy(s:dynamic.sources))

  for l:source in values(filter(copy(l:sources), '!has_key(v:val, "is_initialized")'))
    let l:source.is_initialized = 1

    if !has_key(l:source, 'is_volatile')
      let l:source.is_volatile = 0
    endif
    if !has_key(l:source, 'required_pattern_length')
      let l:source.required_pattern_length = 0
    endif
    if !has_key(l:source, 'action_table')
      let l:source.action_table = {}
    endif
    if !has_key(l:source, 'default_action')
      let l:source.default_action = {}
    elseif type(l:source.default_action) == type('')
      " Syntax sugar.
      let l:source.default_action = { '*' : l:source.default_action }
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
    if !has_key(l:source, 'syntax')
      let l:source.syntax = ''
    endif
    if l:source.is_volatile
          \ && !has_key(l:source, 'change_candidates')
      let l:source.change_candidates = l:source.gather_candidates
      call remove(l:source, 'gather_candidates')
    endif

    let l:source.filters =
          \ has_key(s:custom.filters, l:source.name) ?
          \ s:custom.filters[l:source.name] :
          \ has_key(l:source, 'filters') ?
          \ l:source.filters :
          \ unite#filters#default#get()
    let l:source.max_candidates =
          \ has_key(s:custom.max_candidates, l:source.name) ?
          \ s:custom.max_candidates[l:source.name] :
          \ has_key(l:source, 'max_candidates') ?
          \ l:source.max_candidates :
          \ 0
  endfor

  return l:sources
endfunction"}}}
function! s:initialize_kinds()"{{{
  let l:kinds = extend(copy(s:static.kinds), s:dynamic.kinds)
  for l:kind in values(filter(copy(l:kinds), '!has_key(v:val, "is_initialized")'))
    let l:kind.is_initialized = 1
    if !has_key(l:kind, 'alias_table')
      let l:kind.alias_table = {}
    endif
    if !has_key(l:kind, 'parents')
      let l:kind.parents = ['common']
    endif
  endfor

  return l:kinds
endfunction"}}}
function! s:initialize_filters()"{{{
  return extend(copy(s:static.filters), s:dynamic.filters)
endfunction"}}}
function! s:initialize_buffer_name_options(buffer_name)"{{{
  if !has_key(s:buffer_name_options, a:buffer_name)
    let s:buffer_name_options[a:buffer_name] = {}
  endif
  let l:setting = s:buffer_name_options[a:buffer_name]
  if !has_key(l:setting, 'substitute_patterns')
    let l:setting.substitute_patterns = {}
  endif
  if !has_key(l:setting, 'filters')
    let l:setting.filters = []
  endif
  if !has_key(l:setting, 'ignorecase')
    let l:setting.ignorecase = &ignorecase
  endif
  if !has_key(l:setting, 'smartcase')
    let l:setting.smartcase = &smartcase
  endif
  if !has_key(l:setting, 'unite__save_pos')
    let l:setting.unite__save_pos = {}
  endif
  if !has_key(l:setting, 'unite__inputs')
    let l:setting.unite__inputs = {}
  endif
endfunction"}}}

function! s:recache_candidates(input, is_force)"{{{
  let l:unite = unite#get_current_unite()

  " Save options.
  let l:ignorecase_save = &ignorecase

  if unite#get_buffer_name_option(l:unite.buffer_name, 'smartcase') && a:input =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase = unite#get_buffer_name_option(l:unite.buffer_name, 'ignorecase')
  endif

  let l:input = s:get_substitute_input(a:input)
  let l:input_len = unite#util#strchars(l:input)

  let l:context = l:unite.context
  let l:context.input = l:input
  let l:context.is_redraw = a:is_force
  let l:filtered_count = 0

  for l:source in unite#loaded_sources_list()
    " Check required pattern length.
    if l:input_len < l:source.required_pattern_length
      continue
    endif

    " Set context.
    let l:source.unite__context.input = l:context.input
    let l:source.unite__context.is_redraw = l:context.is_redraw
    let l:source.unite__context.is_invalidate = l:source.unite__is_invalidate

    if l:context.is_redraw || l:source.unite__is_invalidate
      " Recaching.
      let l:source.unite__cached_candidates = []

      if has_key(l:source, 'gather_candidates')
        let l:source.unite__cached_candidates +=
              \ copy(l:source.gather_candidates(l:source.args, l:source.unite__context))
      endif
    endif

    if l:source.unite__context.is_async
      let l:source.unite__cached_candidates +=
            \ l:source.async_gather_candidates(l:source.args, l:source.unite__context)
    endif

    " Update async state.
    let l:unite.is_async =
          \ len(filter(copy(l:unite.sources), 'v:val.unite__context.is_async')) > 0

    if has_key(l:source, 'change_candidates')
          \ && (l:context.is_redraw || l:source.unite__is_invalidate
          \      || a:input !=# l:unite.last_input)
      " Recaching.
      let l:source.unite__cached_change_candidates =
            \ l:source.change_candidates(l:source.args, l:source.unite__context)
    endif

    let l:source_candidates = l:source.unite__cached_candidates
          \ + l:source.unite__cached_change_candidates

    let l:custom_source = has_key(s:custom.source, l:source.name) ?
          \ s:custom.source[l:source.name] : {}

    " Filter.
    for l:filter_name in has_key(l:custom_source, 'filters') ?
          \ l:custom_source.filters : l:source.filters
      if has_key(l:unite.filters, l:filter_name)
        let l:source_candidates =
              \ l:unite.filters[l:filter_name].filter(l:source_candidates, l:source.unite__context)
      endif
    endfor

    if l:source.max_candidates != 0
          \ && len(l:source_candidates) > l:source.max_candidates
      " Filtering too many candidates.
      let l:source_candidates = l:source_candidates[: l:source.max_candidates - 1]

      if l:context.verbose && l:filtered_count < &cmdheight
        echohl WarningMsg | echomsg printf('[%s] Filtering too many candidates.', l:source.name) | echohl None
        let l:filtered_count += 1
      endif
    endif

    " Call post_filter hook.
    let l:source.unite__context.candidates = l:source_candidates
    call s:call_hook([l:source], 'on_post_filter')

    for l:candidate in l:source_candidates
      if !has_key(l:candidate, 'abbr')
        let l:candidate.abbr = l:candidate.word
      endif
      if !has_key(l:candidate, 'kind')
        let l:candidate.kind = 'common'
      endif
      if !has_key(l:candidate, 'source')
        let l:candidate.source = l:source.name
      endif
      if !has_key(l:candidate, 'is_dummy')
        let l:candidate.is_dummy = 0
      endif
      if !has_key(l:candidate, 'unite__is_marked')
        let l:candidate.unite__is_marked = 0
      endif
    endfor

    let l:source.unite__candidates = l:source_candidates
    let l:source.unite__is_invalidate = 0
  endfor

  let &ignorecase = l:ignorecase_save
endfunction"}}}
function! s:convert_quick_match_lines(candidates)"{{{
  let l:unite = unite#get_current_unite()
  let [l:max_width, l:max_source_name] = s:adjustments(winwidth(0)-2, l:unite.max_source_name, 5)
  if l:unite.max_source_name == 0
    let l:max_width -= 1
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
          \ . (l:unite.max_source_name == 0 ? ' ' :
          \    unite#util#truncate(l:candidate.source, l:max_source_name))
          \ . unite#util#truncate_smart(l:candidate.abbr, l:max_width, l:max_width/3, '..'))
    let l:num += 1
  endfor

  return l:candidates
endfunction"}}}
function! s:convert_lines(candidates)"{{{
  let l:unite = unite#get_current_unite()
  let [l:max_width, l:max_source_name] = s:adjustments(winwidth(0)-2, l:unite.max_source_name, 2)
  if l:unite.max_source_name == 0
    let l:max_width -= 1
  endif

  return map(copy(a:candidates),
        \ '(v:val.unite__is_marked ? "*  " : "-  ")
        \ . (l:unite.max_source_name == 0 ? " " : unite#util#truncate(v:val.source, l:max_source_name))
        \ . unite#util#truncate_smart(v:val.abbr, ' . l:max_width .  ', l:max_width/3, "..")')
endfunction"}}}

function! s:initialize_current_unite(sources, context)"{{{
  let s:unite_cached_message = []

  let l:context = a:context

  if getbufvar(bufnr('%'), '&filetype') ==# 'unite'
    if unite#get_current_unite().buffer_name ==# l:context.buffer_name
      " Quit unite buffer.
      call unite#force_quit_session()

      if l:context.input == ''
        " Get input text.
        let l:context.input = unite#get_input()
      endif
    endif
  endif

  " The current buffer is initialized.
  let l:buffer_name = unite#is_win() ? '[unite]' : '*unite*'
  let l:buffer_name .= ' - ' . l:context.buffer_name

  let l:winnr = winnr()
  let l:win_rest_cmd = winrestcmd()

  " Check sources.
  let l:sources = s:initialize_loaded_sources(a:sources, a:context)

  " Call initialize functions.
  call s:call_hook(l:sources, 'on_init')

  " Set parameters.
  let l:unite = {}
  let l:unite.winnr = l:winnr
  let l:unite.win_rest_cmd = l:win_rest_cmd
  let l:unite.context = l:context
  let l:unite.candidates = []
  let l:unite.sources = l:sources
  let l:unite.kinds = s:initialize_kinds()
  let l:unite.filters = s:initialize_filters()
  let l:unite.buffer_name = (l:context.buffer_name == '') ? 'default' : l:context.buffer_name
  let l:unite.buffer_options =
        \ s:initialize_buffer_name_options(l:unite.buffer_name)
  let l:unite.real_buffer_name = l:buffer_name
  let l:unite.prompt = l:context.prompt
  let l:unite.input = l:context.input
  let l:unite.last_input = l:context.input
  let l:unite.sidescrolloff_save = &sidescrolloff
  let l:unite.prompt_linenr = 2
  let l:unite.max_source_name = len(a:sources) > 1 ?
        \ max(map(copy(a:sources), 'len(v:val[0])')) + 2 : 0
  let l:unite.is_async =
        \ len(filter(copy(l:sources), 'v:val.unite__context.is_async')) > 0
  let l:unite.access_time = localtime()
  let l:unite.is_finalized = 0

  " Preview windows check.
  let l:unite.has_preview_window =
   \ len(filter(range(1, winnr('$')), 'getwinvar(v:val, "&previewwindow")')) > 0

  let s:current_unite = l:unite
endfunction"}}}
function! s:initialize_unite_buffer()"{{{
  let l:is_bufexists = bufexists(s:current_unite.real_buffer_name)
  call s:switch_unite_buffer(s:current_unite.real_buffer_name, s:current_unite.context)

  let b:unite = s:current_unite
  let l:unite = unite#get_current_unite()

  if !l:unite.context.temporary
    let s:last_unite_bufnr = bufnr('%')
  endif
  let l:unite.bufnr = bufnr('%')

  " Note: If unite buffer initialize is incomplete, &modified or &wrap.
  if !l:is_bufexists || &modified || &wrap
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
    setlocal nocursorline

    " Autocommands.
    augroup plugin-unite
      autocmd InsertEnter <buffer>  call s:on_insert_enter()
      autocmd InsertLeave <buffer>  call s:on_insert_leave()
      autocmd CursorHoldI <buffer>  call s:on_cursor_hold_i()
      autocmd CursorHold <buffer>  call s:on_cursor_hold()
      autocmd CursorMoved,CursorMovedI <buffer>  call s:on_cursor_moved()
      autocmd BufUnload,BufHidden <buffer>  call s:on_buf_unload(expand('<afile>'))
    augroup END

    call unite#mappings#define_default_mappings()

    if exists(':NeoComplCacheLock')
      " Lock neocomplcache.
      NeoComplCacheLock
    endif
  endif

  if exists('&redrawtime')
    " Save redrawtime
    let l:unite.redrawtime_save = &redrawtime
    let &redrawtime = 100
  endif

  " User's initialization.
  setlocal nomodifiable
  set sidescrolloff=0
  setfiletype unite

  if exists('b:current_syntax') && b:current_syntax ==# 'unite'
    " Set highlight.
    let l:match_prompt = escape(l:unite.prompt, '\/*~.^$[]')
    syntax clear uniteInputPrompt
    execute 'syntax match uniteInputPrompt' '/^'.l:match_prompt.'/ contained'

    syntax clear uniteCandidateSourceName
    if l:unite.max_source_name > 0
      syntax match uniteCandidateSourceName /\%4c[[:alnum:]_\/-]\+/ contained
    else
      syntax match uniteCandidateSourceName /^- / contained
    endif
    let l:source_padding = 3
    execute 'syntax match uniteCandidateAbbr' '/\%'.(l:unite.max_source_name+l:source_padding).'c.*/ contained'

    execute 'highlight default link uniteCandidateAbbr'  g:unite_abbr_highlight

    " Set syntax.
    for l:source in l:unite.sources
      if l:source.syntax != ''
        let l:name = len(l:unite.sources) > 1 ? l:source.name : ''

        execute 'syntax match' l:source.syntax '/\%'.(l:unite.max_source_name+l:source_padding).'c.*/ contained'

        execute 'highlight default link' l:source.syntax g:unite_abbr_highlight

        execute printf('syntax region %s start="^- %s" end="$" contains=%s%s',
              \ 'uniteSourceLine__'.l:source.syntax, (l:name == '' ? '' : l:name . '\>'), (l:name == '' ? '' : 'uniteSourceNames,'), l:source.syntax
              \ )

        call s:call_hook([l:source], 'on_syntax')
      endif
    endfor
  endif
endfunction"}}}
function! s:switch_unite_buffer(buffer_name, context)"{{{
  " Search unite window.
  " Note: must escape file-pattern.
  if bufwinnr(unite#util#escape_file_searching(a:buffer_name)) > 0
    silent execute bufwinnr(unite#util#escape_file_searching(a:buffer_name)) 'wincmd w'
  else
    " Split window.
    execute a:context.direction (bufexists(a:buffer_name) ?
          \ ((a:context.vertical) ? 'vsplit' : 'split') :
          \ ((a:context.vertical) ? 'vnew' : 'new'))

    if bufexists(a:buffer_name)
      " Search buffer name.
      let l:bufnr = 1
      let l:max = bufnr('$')
      while l:bufnr <= l:max
        if bufname(l:bufnr) ==# a:buffer_name
          silent execute l:bufnr 'buffer'
          break
        endif

        let l:bufnr += 1
      endwhile
    else
      silent! file `=a:buffer_name`
    endif
  endif

  if winnr('$') != 1
    if a:context.vertical
      execute 'vertical resize' a:context.winwidth
    else
      execute 'resize' a:context.winheight
    endif
  endif
endfunction"}}}

function! s:redraw(is_force) "{{{
  if &filetype !=# 'unite'
    return
  endif

  if a:is_force
    call unite#clear_message()
  endif

  let l:unite = unite#get_current_unite()
  let l:input = unite#get_input()
  if !a:is_force && l:input ==# l:unite.last_input
        \ && !l:unite.is_async
    return
  endif

  let l:unite.context.is_redraw = a:is_force

  " Recaching.
  call s:recache_candidates(l:input, a:is_force)

  let l:unite.last_input = l:input

  " Redraw.
  call unite#redraw_candidates()
  let l:unite.context.is_redraw = 0
endfunction"}}}

" Autocmd events.
function! s:on_insert_enter()  "{{{
  let l:unite = unite#get_current_unite()
  let l:unite.is_insert = 1
  setlocal modifiable

  if line('.') != l:unite.prompt_linenr
        \ || col('.') <= len(l:unite.prompt)
    execute l:unite.prompt_linenr
    normal! zb
    startinsert!
  endif

  if &updatetime > g:unite_update_time
    let l:unite = unite#get_current_unite()
    let l:unite.update_time_save = &updatetime
    let &updatetime = g:unite_update_time
  endif
endfunction"}}}
function! s:on_insert_leave()  "{{{
  let l:unite = unite#get_current_unite()

  if line('.') == l:unite.prompt_linenr
    " Redraw.
    call unite#redraw()
  else
    normal! 0
  endif

  let l:unite.is_insert = 0

  setlocal nomodifiable

  if has_key(l:unite, 'update_time_save')
        \ && &updatetime < l:unite.update_time_save
    let &updatetime = l:unite.update_time_save
  endif
endfunction"}}}
function! s:on_cursor_hold_i()  "{{{
  let l:prompt_linenr = unite#get_current_unite().prompt_linenr
  if line('.') == l:prompt_linenr
    " Redraw.
    call unite#redraw()

    execute 'match' (line('.') <= l:prompt_linenr ?
          \ line('$') <= l:prompt_linenr ?
          \ 'UniteError /\%'.l:prompt_linenr.'l/' :
          \ g:unite_cursor_line_highlight.' /\%'.(l:prompt_linenr+1).'l/' :
          \ g:unite_cursor_line_highlight.' /\%'.line('.').'l/')

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
  if &filetype !=# 'unite'
    return
  endif

  let l:prompt_linenr = unite#get_current_unite().prompt_linenr

  setlocal nocursorline

  execute 'setlocal' line('.') == l:prompt_linenr ?
        \ 'modifiable' : 'nomodifiable'

  execute 'match' (line('.') <= l:prompt_linenr ?
        \ line('$') <= l:prompt_linenr ?
        \ 'UniteError /\%'.l:prompt_linenr.'l/' :
        \ g:unite_cursor_line_highlight.' /\%'.(l:prompt_linenr+1).'l/' :
        \ g:unite_cursor_line_highlight.' /\%'.line('.').'l/')

  if unite#get_current_unite().context.auto_preview
    if !unite#get_current_unite().has_preview_window
      pclose!
    endif

    call unite#mappings#do_action('preview')

    " Restore window size.
    let l:context = unite#get_context()
    if winnr('$') != 1
      if l:context.vertical
        if winwidth(winnr()) != l:context.winwidth
          execute 'vertical resize' l:context.winwidth
        endif
      elseif winheight(winnr()) != l:context.winwidth
        execute 'resize' l:context.winheight
      endif
    endif
  endif
endfunction"}}}
function! s:on_buf_unload(bufname)  "{{{
  " Save unite value.
  let s:current_unite = getbufvar(a:bufname, 'unite')
  let l:unite = s:current_unite

  if l:unite.is_finalized
    return
  endif

  " Restore options.
  if exists('&redrawtime')
    let &redrawtime = l:unite.redrawtime_save
  endif
  let &sidescrolloff = l:unite.sidescrolloff_save

  match

  if !l:unite.has_preview_window
    " Close preview window.
    pclose!
  endif

  if winnr('$') != 1
    execute l:unite.win_rest_cmd
  endif

  " Call finalize functions.
  call s:call_hook(unite#loaded_sources_list(), 'on_close')
  let l:unite.is_finalized = 1
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
    " throw 'no such action ' . a:action_name
    return
  endif

  let l:action = l:action_table[a:action_name]
  " Convert candidates.
  call l:action.func(
        \ (l:action.is_selectable && type(a:candidate) != type([])) ?
        \ [a:candidate] : a:candidate)
endfunction"}}}
function! s:get_loaded_sources(...)"{{{
  let l:unite = unite#get_current_unite()
  return a:0 == 0 ? l:unite.sources : get(filter(copy(l:unite.sources), 'v:val.name ==# a:1'), 0, {})
endfunction"}}}
function! s:get_substitute_input(input)"{{{
  let l:input = a:input

  let l:unite = unite#get_current_unite()
  let l:substitute_patterns =
        \ unite#get_buffer_name_option(l:unite.buffer_name, 'substitute_patterns')
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

  for l:pattern in reverse(unite#util#sort_by(values(l:substitute_patterns),
        \ 'v:val.priority'))
    let l:subst = substitute(l:subst, l:pattern.pattern, l:pattern.subst, 'g')
  endfor

  let l:input .= l:subst

  return l:input
endfunction"}}}
function! s:call_hook(sources, hook_name)"{{{
  for l:source in a:sources
    if has_key(l:source.hooks, a:hook_name)
      call call(l:source.hooks[a:hook_name], [l:source.args, l:source.unite__context], l:source.hooks)
    endif
  endfor
endfunction"}}}
function! s:is_cmdwin()"{{{
  silent! noautocmd wincmd p
  silent! noautocmd wincmd p
  return v:errmsg =~ '^E11:'
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
