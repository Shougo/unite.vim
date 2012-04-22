"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 22 Apr 2012.
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
" Version: 3.1, for Vim 7.2
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! unite#version()"{{{
  return str2nr(printf('%02d%02d%03d', 3, 0, 0))
endfunction"}}}

" User functions."{{{
function! unite#get_substitute_pattern(profile_name)"{{{
  let profile_name = (a:profile_name == '' ? 'default' : a:profile_name)

  return has_key(s:profiles, profile_name) ?
        \ s:profiles[profile_name].substitute_patterns : ''
endfunction"}}}
function! unite#set_substitute_pattern(buffer_name, pattern, subst, ...)"{{{
  let buffer_name = (a:buffer_name == '' ? 'default' : a:buffer_name)

  for key in split(buffer_name, '\s*,\s*')
    let substitute_patterns = has_key(s:profiles, key) ?
          \ unite#get_profile(key, 'substitute_patterns') : {}

    if has_key(substitute_patterns, a:pattern)
          \ && a:pattern == ''
      call remove(substitute_patterns, a:pattern)
    else
      let substitute_patterns[a:pattern] = {
            \ 'pattern' : a:pattern,
            \ 'subst' : a:subst, 'priority' : (a:0 > 0 ? a:1 : 0),
            \ }
    endif

    call unite#set_profile(key, 'substitute_patterns', substitute_patterns)
  endfor
endfunction"}}}
function! unite#set_buffer_name_option(buffer_name, option_name, value)"{{{
  return unite#set_profile(a:buffer_name, a:option_name, a:value)
endfunction"}}}
function! unite#get_buffer_name_option(buffer_name, option_name)"{{{
  return unite#get_profile(a:buffer_name, a:option_name)
endfunction"}}}
function! unite#set_profile(profile_name, option_name, value)"{{{
  let profile_name =
        \ (a:profile_name == '' ? 'default' : a:profile_name)

  for key in split(profile_name, '\s*,\s*')
    if !has_key(s:profiles, key)
      let s:profiles[key] = {}
    endif

    let s:profiles[key][a:option_name] = a:value
  endfor
endfunction"}}}
function! unite#get_profile(profile_name, option_name)"{{{
  let profile_name = matchstr(a:profile_name, '^\S\+')
  if profile_name == ''
    let profile_name = 'default'
  endif

  return s:profiles[profile_name][a:option_name]
endfunction"}}}
function! unite#custom_filters(source_name, filters)"{{{
  let filters = type(a:filters) == type([]) ?
        \ a:filters : [a:filters]
  call unite#util#set_dictionary_helper(s:custom.filters,
        \ a:source_name, filters)
endfunction"}}}
function! unite#custom_alias(kind, name, action)"{{{
  for key in split(a:kind, '\s*,\s*')
    if !has_key(s:custom.aliases, key)
      let s:custom.aliases[key] = {}
    endif

    let s:custom.aliases[key][a:name] = a:action
  endfor
endfunction"}}}
function! unite#custom_default_action(kind, default_action)"{{{
  call unite#util#set_dictionary_helper(s:custom.default_actions,
        \ a:kind, a:default_action)
endfunction"}}}
function! unite#custom_action(kind, name, action)"{{{
  for key in split(a:kind, '\s*,\s*')
    if !has_key(s:custom.actions, key)
      let s:custom.actions[key] = {}
    endif
    let s:custom.actions[key][a:name] = a:action
  endfor
endfunction"}}}
function! unite#custom_max_candidates(source_name, max)"{{{
  call unite#util#set_dictionary_helper(s:custom.max_candidates,
        \ a:source_name, a:max)
endfunction"}}}
function! unite#undef_custom_action(kind, name)"{{{
  for key in split(a:kind, '\s*,\s*')
    if has_key(s:custom.actions, key)
      call remove(s:custom.actions, key)
    endif
  endfor
endfunction"}}}

function! unite#define_source(source)"{{{
  if type(a:source) == type([])
    for source in a:source
      let s:dynamic.sources[source.name] = source
    endfor
  else
    let s:dynamic.sources[a:source.name] = a:source
  endif
endfunction"}}}
function! unite#define_kind(kind)"{{{
  if type(a:kind) == type([])
    for kind in a:kind
      let s:dynamic.kinds[kind.name] = kind
    endfor
  else
    let s:dynamic.kinds[a:kind.name] = a:kind
  endif
endfunction"}}}
function! unite#define_filter(filter)"{{{
  if type(a:filter) == type([])
    for filter in a:filter
      let s:dynamic.filters[filter.name] = filter
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

function! unite#do_action(action)"{{{
  return printf("%s:\<C-u>call unite#mappings#do_action(%s)\<CR>",
        \             (mode() ==# 'i' ? "\<C-o>" : ''), string(a:action))
endfunction"}}}
function! unite#smart_map(narrow_map, select_map)"{{{
  return (line('.') <= unite#get_current_unite().prompt_linenr && empty(unite#get_marked_candidates())) ? a:narrow_map : a:select_map
endfunction"}}}
function! unite#start_complete(sources, ...) "{{{
  let context = {
        \ 'col' : col('.'), 'complete' : 1,
        \ 'direction' : 'rightbelow',
        \ 'buffer_name' : 'completion',
        \ }
  let context.winheight = winheight(0) - winline() + 2
  if context.winheight < 7
    let context.winheight = 7
  endif
  call extend(context, get(a:000, 0, {}))

  return printf("\<ESC>:call unite#start(%s, %s)\<CR>",
        \  string(a:sources), string(context))
endfunction "}}}

function! unite#take_action(action_name, candidate)"{{{
  call s:take_action(a:action_name, a:candidate, 0)
endfunction"}}}
function! unite#take_parents_action(action_name, candidate, extend_candidate)"{{{
  call s:take_action(a:action_name, extend(deepcopy(a:candidate), a:extend_candidate), 1)
endfunction"}}}

function! unite#do_candidates_action(action_name, candidates, ...)"{{{
  let context = get(a:000, 0, {})
  let context = s:initialize_context(context)
  let context.is_interactive = 0

  " Get sources.
  let sources = {}
  for candidate in a:candidates
    if !has_key(sources, candidate.source)
      let sources[candidate.source] = 1
    endif
  endfor

  try
    call s:initialize_current_unite(keys(sources), context)
  catch /^Invalid source/
    return
  endtry

  return unite#mappings#do_action(
        \ a:action_name, a:candidates, context)
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
let s:use_current_unite = 1

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

let s:profiles = {}
call unite#set_substitute_pattern('files', '^\~',
      \ substitute(unite#util#substitute_path_separator($HOME),
      \ ' ', '\\\\ ', 'g'), -100)
call unite#set_substitute_pattern('files', '[^~.* ]\ze/', '\0*', 100)
call unite#set_substitute_pattern('files', '/\ze[^~.* ]', '/*', 100)
call unite#set_substitute_pattern('files', '\.', '*.', 1000)
call unite#set_profile('files', 'smartcase', 0)
call unite#set_profile('files', 'ignorecase', 1)

let s:unite_options = [
      \ '-buffer-name=', '-profile-name=', '-input=', '-prompt=',
      \ '-default-action=', '-start-insert','-no-start-insert', '-no-quit',
      \ '-winwidth=', '-winheight=',
      \ '-immediately', '-no-empty', '-auto-preview', '-complete',
      \ '-vertical', '-horizontal', '-direction=', '-no-split',
      \ '-verbose', '-auto-resize', '-toggle', '-quick-match', '-create',
      \ '-cursor-line-highlight=', '-no-cursor-line',
      \ '-update-time=', '-hide-source-names'
      \]
"}}}

" Core functions."{{{
function! unite#get_kinds(...)"{{{
  let unite = unite#get_current_unite()
  if !has_key(unite, 'kinds')
    return {}
  endif

  return a:0 == 0 ? unite.kinds : get(unite.kinds, a:1, {})
endfunction"}}}
function! unite#get_sources(...)"{{{
  let unite = unite#get_current_unite()
  if !has_key(unite, 'sources')
    return {}
  endif

  return a:0 == 0 ? unite.sources : get(unite.sources, a:1, {})
endfunction"}}}
function! unite#get_all_sources(...)"{{{
  let all_sources = s:initialize_sources()
  return a:0 == 0 ? all_sources : get(all_sources, a:1, {})
endfunction"}}}
function! unite#get_filters(...)"{{{
  let all_filters = s:initialize_filters()
  return a:0 == 0 ? all_filters : get(all_filters, a:1, {})
endfunction"}}}
"}}}

" Helper functions."{{{
function! unite#is_win()"{{{
  return unite#util#is_windows()
endfunction"}}}
function! unite#loaded_source_names()"{{{
  return map(copy(unite#loaded_sources_list()), 'v:val.name')
endfunction"}}}
function! unite#loaded_source_names_string()"{{{
  return join(unite#loaded_source_names())
endfunction"}}}
function! unite#loaded_source_names_with_args()"{{{
  return map(copy(unite#loaded_sources_list()),
        \ 'join(insert(filter(copy(v:val.args), "type(v:val) < 1"), v:val.name), ":")')
endfunction"}}}
function! unite#loaded_sources_list()"{{{
  return s:get_loaded_sources()
endfunction"}}}
function! unite#get_vimfiler_source_names()"{{{
  return map(filter(values(s:initialize_sources()),
        \ 'has_key(v:val, "vimfiler_check_filetype")'), 'v:val.name')
endfunction"}}}
function! unite#get_unite_candidates()"{{{
  return unite#get_current_unite().candidates
endfunction"}}}
function! unite#get_current_candidate(...)"{{{
  let linenr = a:0 > 1? a:1 : line('.')
  let num = linenr <= unite#get_current_unite().prompt_linenr ?
        \ 0 : linenr - (unite#get_current_unite().prompt_linenr+1)

  return get(unite#get_unite_candidates(), num, {})
endfunction"}}}
function! unite#get_context()"{{{
  return unite#get_current_unite().context
endfunction"}}}
function! unite#set_context(context)"{{{
  let old_context = unite#get_context()

  if exists('b:unite') && !s:use_current_unite
    let b:unite.context = a:context
  else
    let s:current_unite.context = a:context
  endif

  return old_context
endfunction"}}}

function! unite#get_action_table(source_name, kind, self_func, ...)"{{{
  let is_parents_action = get(a:000, 0, 0)
  let source_table = get(a:000, 1, {})

  let action_table = {}
  for kind_name in type(a:kind) == type([]) ?
        \ a:kind : [a:kind]
    call extend(action_table,
          \ s:get_action_table(a:source_name,
          \                kind_name, a:self_func,
          \                is_parents_action, source_table))
  endfor

  return action_table
endfunction"}}}
function! s:get_action_table(source_name, kind_name, self_func, is_parents_action, source_table)"{{{
  let kind = unite#get_kinds(a:kind_name)
  let source = empty(a:source_table) ?
        \ unite#get_sources(a:source_name) :
        \ get(a:source_table, a:source_name, {})
  if empty(source)
    call unite#print_error('[unite.vim] source "' . a:source_name . '" is not found.')
    return {}
  endif

  let action_table = {}

  let source_kind = 'source/'.a:source_name.'/'.a:kind_name
  let source_kind_wild = 'source/'.a:source_name.'/*'

  if !a:is_parents_action
    " Source/kind custom actions.
    if has_key(s:custom.actions, source_kind)
      let action_table = s:extend_actions(a:self_func, action_table,
            \ s:custom.actions[source_kind], 'custom/'.source.name.'/'.kind.name)
    endif

    " Source/kind actions.
    if has_key(source.action_table, a:kind_name)
      let action_table = s:extend_actions(a:self_func, action_table,
            \ source.action_table[a:kind_name], source.name.'/'.kind.name)
    endif

    " Source/* custom actions.
    if has_key(s:custom.actions, source_kind_wild)
      let action_table = s:extend_actions(a:self_func, action_table,
            \ s:custom.actions[source_kind_wild], 'custom/source/'.source.name)
    endif

    " Source/* actions.
    if has_key(source.action_table, '*')
      let action_table = s:extend_actions(a:self_func, action_table,
            \ source.action_table['*'], 'source/'.source.name)
    endif

    " Kind custom actions.
    if has_key(s:custom.actions, a:kind_name)
      let action_table = s:extend_actions(a:self_func, action_table,
            \ s:custom.actions[a:kind_name], 'custom/'.kind.name)
    endif

    " Kind actions.
    let action_table = s:extend_actions(a:self_func, action_table,
          \ kind.action_table, kind.name)
  endif

  " Parents actions.
  for parent in kind.parents
    let action_table = s:extend_actions(a:self_func, action_table,
          \ unite#get_action_table(a:source_name, parent,
          \                    a:self_func, 0, a:source_table))
  endfor

  if !a:is_parents_action
    " Kind aliases.
    call s:filter_alias_action(action_table, kind.alias_table,
          \ kind.name)

    " Kind custom aliases.
    if has_key(s:custom.aliases, a:kind_name)
      call s:filter_alias_action(action_table, s:custom.aliases[a:kind_name],
            \ 'custom/'.kind.name)
    endif

    " Source/* aliases.
    if has_key(source.alias_table, '*')
      call s:filter_alias_action(action_table, source.alias_table['*'],
            \ 'source/'.source.name)
    endif

    " Source/* custom aliases.
    if has_key(s:custom.aliases, source_kind_wild)
      call s:filter_alias_action(action_table, s:custom.aliases[source_kind_wild],
            \ 'custom/source/'.source.name)
    endif

    " Source/kind aliases.
    if has_key(s:custom.aliases, source_kind)
      call s:filter_alias_action(action_table, s:custom.aliases[source_kind],
            \ 'source/'.source.name.'/'.kind.name)
    endif

    " Source/kind custom aliases.
    if has_key(source.alias_table, a:kind_name)
      call s:filter_alias_action(action_table, source.alias_table[a:kind_name],
            \ 'custom/source/'.source.name.'/'.kind.name)
    endif
  endif

  " Set default parameters.
  for [action_name, action] in items(action_table)
    if !has_key(action, 'name')
      let action.name = action_name
    endif
    if !has_key(action, 'description')
      let action.description = ''
    endif
    if !has_key(action, 'is_quit')
      let action.is_quit = 1
    endif
    if !has_key(action, 'is_selectable')
      let action.is_selectable = 0
    endif
    if !has_key(action, 'is_invalidate_cache')
      let action.is_invalidate_cache = 0
    endif
    if !has_key(action, 'is_listed')
      let action.is_listed = 1
    endif
  endfor

  " Filtering nop action.
  return filter(action_table, 'v:key !=# "nop"')
endfunction"}}}
function! unite#get_alias_table(source_name, kind, ...)"{{{
  let source_table = get(a:000, 0, {})
  let alias_table = {}
  for kind_name in type(a:kind) == type([]) ?
        \ a:kind : [a:kind]
    call extend(alias_table,
          \ s:get_alias_table(a:source_name, kind_name, source_table))
  endfor

  return alias_table
endfunction"}}}
function! s:get_alias_table(source_name, kind_name, source_table)"{{{
  let kind = unite#get_kinds(a:kind_name)
  let source = empty(a:source_table) ?
        \ unite#get_sources(a:source_name) :
        \ get(a:source_table, a:source_name, {})
  if empty(source)
    call unite#print_error('[unite.vim] source "' . a:source_name . '" is not found.')
    return {}
  endif

  let table = kind.alias_table

  let source_kind = 'source/'.a:source_name.'/'.a:kind_name
  let source_kind_wild = 'source/'.a:source_name.'/*'

  " Kind custom aliases.
  if has_key(s:custom.aliases, a:kind_name)
    let table = extend(table, s:custom.aliases[a:kind_name])
  endif

  " Source/* aliases.
  if has_key(source.alias_table, '*')
    let table = extend(table, source.alias_table['*'])
  endif

  " Source/* custom aliases.
  if has_key(s:custom.aliases, source_kind_wild)
    let table = extend(table, s:custom.aliases[source_kind_wild])
  endif

  " Source/kind aliases.
  if has_key(s:custom.aliases, source_kind)
    let table = extend(table, s:custom.aliases[source_kind])
  endif

  " Source/kind custom aliases.
  if has_key(source.alias_table, a:kind_name)
    let table = extend(table, source.alias_table[a:kind_name])
  endif

  return table
endfunction"}}}
function! unite#get_default_action(source_name, kind)"{{{
  let kinds = type(a:kind) == type([]) ?
        \ a:kind : [a:kind]

  return s:get_default_action(a:source_name, kinds[-1])
endfunction"}}}
function! s:get_default_action(source_name, kind_name)"{{{
  let source = unite#get_sources(a:source_name)

  let source_kind = 'source/'.a:source_name.'/'.a:kind_name
  let source_kind_wild = 'source/'.a:source_name.'/*'

  " Source/kind custom default actions.
  if has_key(s:custom.default_actions, source_kind)
    return s:custom.default_actions[source_kind]
  endif

  " Source custom default actions.
  if has_key(source.default_action, a:kind_name)
    return source.default_action[a:kind_name]
  endif

  " Source/* custom default actions.
  if has_key(s:custom.default_actions, source_kind_wild)
    return s:custom.default_actions[source_kind_wild]
  endif

  " Source/* default actions.
  if has_key(source.default_action, '*')
    return source.default_action['*']
  endif

  " Kind custom default actions.
  if has_key(s:custom.default_actions, a:kind_name)
    return s:custom.default_actions[a:kind_name]
  endif

  " Kind default actions.
  return unite#get_kinds(a:kind_name).default_action
endfunction"}}}

function! unite#escape_match(str)"{{{
  return substitute(substitute(escape(a:str, '~\.^$[]'),
        \ '\*\@<!\*', '[^/]*', 'g'), '\*\*\+', '.*', 'g')
endfunction"}}}
function! unite#complete_source(arglead, cmdline, cursorpos)"{{{
  let ret = unite#parse_path(join(split(a:cmdline)[1:]))
  let source_name = ret[0]
  let source_args = ret[1:]

  let _ = []

  if a:arglead !~ ':'
    " Option names completion.
    let _ +=  copy(s:unite_options)

    " Source name completion.
    let _ += keys(filter(s:initialize_sources(), 'v:val.is_listed'))
  else
    " Add "{source-name}:".
    let _  = map(_, 'source_name.":".v:val')
  endif

  if source_name != ''
    " Source args completion.
    let args = source_name . ':' . join(source_args[: -2], ':')
    let _ += map(unite#args_complete(
          \ [insert(copy(source_args), source_name)],
          \ join(source_args, ':'), a:cmdline, a:cursorpos),
          \ "args.escape(v:val, '\  :')")
  endif

  return sort(filter(_, 'stridx(v:val, a:arglead) == 0'))
endfunction"}}}
function! unite#complete_buffer_name(arglead, cmdline, cursorpos)"{{{
  let _ = map(filter(range(1, bufnr('$')), '
        \ getbufvar(v:val, "&filetype") ==# "unite" &&
        \ !getbufvar(v:val, "unite").context.temporary'),
        \ 'getbufvar(v:val, "unite").buffer_name')
  let _ += s:unite_options

  return filter(_, printf('stridx(v:val, %s) == 0', string(a:arglead)))
endfunction"}}}
function! unite#invalidate_cache(source_name)  "{{{
  for source in unite#get_current_unite().sources
    if source.name ==# a:source_name
      let source.unite__is_invalidate = 1
    endif
  endfor
endfunction"}}}
function! unite#force_redraw(...) "{{{
  call s:redraw(1, get(a:000, 0, 0))
endfunction"}}}
function! unite#redraw(...) "{{{
  call s:redraw(0, get(a:000, 0, 0))
endfunction"}}}
function! unite#redraw_line(...) "{{{
  let linenr = a:0 > 0 ? a:1 : line('.')
  if linenr <= unite#get_current_unite().prompt_linenr || &filetype !=# 'unite'
    " Ignore.
    return
  endif

  let modifiable_save = &l:modifiable
  setlocal modifiable

  let candidate = unite#get_unite_candidates()[linenr - (unite#get_current_unite().prompt_linenr+1)]
  call setline(linenr, s:convert_lines([candidate])[0])

  let &l:modifiable = modifiable_save
endfunction"}}}
function! unite#quick_match_redraw(quick_match_table) "{{{
  let modifiable_save = &l:modifiable
  setlocal modifiable

  call setline(unite#get_current_unite().prompt_linenr+1,
        \ s:convert_quick_match_lines(
        \ unite#get_current_unite().candidates, a:quick_match_table))
  redraw

  let &l:modifiable = modifiable_save
endfunction"}}}
function! unite#redraw_status() "{{{
  if unite#get_context().hide_source_names
    return
  endif

  let modifiable_save = &l:modifiable
  setlocal modifiable

  call setline(s:LNUM_STATUS, 'Sources: ' .
        \ join(unite#loaded_source_names_with_args(), ', '))

  let &l:modifiable = modifiable_save
endfunction"}}}
function! unite#redraw_candidates() "{{{
  let candidates = unite#gather_candidates()

  let modifiable_save = &l:modifiable
  setlocal modifiable

  let lines = s:convert_lines(candidates)
  let pos = getpos('.')
  if len(lines) < len(unite#get_current_unite().candidates)
    silent! execute (unite#get_current_unite().prompt_linenr+1).',$delete _'
  endif
  call setline(unite#get_current_unite().prompt_linenr+1, lines)

  let &l:modifiable = l:modifiable_save

  let unite = unite#get_current_unite()
  let context = unite.context
  let unite.candidates = candidates

  call unite#_resize_window()

  if pos != getpos('.')
    call setpos('.', pos)
  endif
endfunction"}}}
function! unite#get_marked_candidates() "{{{
  return unite#util#sort_by(filter(copy(unite#get_unite_candidates()),
        \ 'v:val.unite__is_marked'), 'v:val.unite__marked_time')
endfunction"}}}
function! unite#get_input()"{{{
  let unite = unite#get_current_unite()
  " Prompt check.
  if stridx(getline(unite.prompt_linenr), unite.prompt) != 0
    let modifiable_save = &l:modifiable
    setlocal modifiable

    " Restore prompt.
    call setline(unite.prompt_linenr, unite.prompt
          \ . getline(unite.prompt_linenr))

    let &l:modifiable = modifiable_save
  endif

  return getline(unite.prompt_linenr)[len(unite.prompt):]
endfunction"}}}
function! unite#get_options()"{{{
  return s:unite_options
endfunction"}}}
function! unite#get_self_functions()"{{{
  return split(matchstr(expand('<sfile>'), '^function \zs.*$'), '\.\.')[: -2]
endfunction"}}}
function! unite#gather_candidates()"{{{
  let candidates = []
  for source in unite#loaded_sources_list()
    let candidates += source.unite__candidates
  endfor

  " Post filter.
  let unite = unite#get_current_unite()
  for filter_name in unite.post_filters
    let candidates = unite#call_filter(filter_name, candidates, unite.context)
  endfor

  return candidates
endfunction"}}}
function! unite#get_current_unite() "{{{
  return exists('b:unite') && !s:use_current_unite ? b:unite : s:current_unite
endfunction"}}}
function! unite#set_current_unite(unite) "{{{
  let s:current_unite = a:unite
endfunction"}}}
function! unite#add_previewed_buffer_list(bufnr) "{{{
  let unite = unite#get_current_unite()
  call add(unite.previewd_buffer_list, a:bufnr)
endfunction"}}}
function! unite#remove_previewed_buffer_list(bufnr) "{{{
  let unite = unite#get_current_unite()
  call filter(unite.previewd_buffer_list, 'v:val != a:bufnr')
endfunction"}}}
function! unite#clear_previewed_buffer_list() "{{{
  let unite = unite#get_current_unite()
  for bufnr in unite.previewd_buffer_list
    if buflisted(bufnr)
      silent execute 'bdelete!' bufnr
    endif
  endfor

  let unite.previewd_buffer_list = []
endfunction"}}}
function! unite#parse_path(path)"{{{
  let source_name = matchstr(a:path, '^[^:]*\ze:')
  let source_arg = a:path[len(source_name)+1 :]

  let source_args = source_arg  == '' ? [] :
        \  map(split(source_arg, '\\\@<!:', 1),
        \      'substitute(v:val, ''\\\(.\)'', "\\1", "g")')

  return insert(source_args, source_name)
endfunction"}}}
function! unite#call_filter(filter_name, candidates, context)"{{{
  let unite = unite#get_current_unite()
  if !has_key(unite.filters, a:filter_name)
    return a:candidates
  endif

  return unite.filters[a:filter_name].filter(a:candidates, a:context)
endfunction"}}}

" Utils.
function! unite#print_error(message)"{{{
  let message = type(a:message) == type([]) ?
        \ a:message : [a:message]
  for mes in message
    call unite#print_message('!!!'.mes.'!!!')

    echohl WarningMsg | echomsg mes | echohl None
  endfor
endfunction"}}}
function! unite#print_message(message)"{{{
  if &filetype ==# 'unite' && !s:use_current_unite
    call s:print_buffer(a:message)
  else
    call add(s:unite_cached_message, a:message)
  endif
endfunction"}}}
function! unite#clear_message()"{{{
  if &filetype ==# 'unite'
    let unite = unite#get_current_unite()
    if unite.prompt_linenr > 2
      let modifiable_save = &l:modifiable
      setlocal modifiable

      let pos = getpos('.')
      silent! execute '2,'.(unite.prompt_linenr-1).'delete _'
      let pos[1] -= unite.prompt_linenr-2
      call setpos('.', pos)
      normal! zb
      if mode() ==# 'i' && pos[2] == col('$')
        startinsert!
      endif

      let unite.prompt_linenr = 2

      let &l:modifiable = modifiable_save
      call s:on_cursor_moved()

      if exists('b:current_syntax') && b:current_syntax ==# 'unite'
        syntax clear uniteInputLine
        execute 'syntax match uniteInputLine'
              \ '/\%'.unite.prompt_linenr.'l.*/'
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
  if &filetype !=# 'unite'
    return
  endif

  let modifiable_save = &l:modifiable
  setlocal modifiable

  let unite = unite#get_current_unite()
  let pos = getpos('.')

  let message = type(a:message) == type([]) ?
        \ a:message : [a:message]

  call append(unite.prompt_linenr-1, message)
  let unite.prompt_linenr += len(message)

  let pos[1] += len(message)
  call setpos('.', pos)
  normal! zb
  if mode() ==# 'i' && pos[2] == col('$')
    startinsert!
  endif

  let &l:modifiable = modifiable_save
  call s:on_cursor_moved()

  if exists('b:current_syntax') && b:current_syntax ==# 'unite'
    syntax clear uniteInputLine
    execute 'syntax match uniteInputLine'
          \ '/\%'.unite.prompt_linenr.'l.*/'
          \ 'contains=uniteInputPrompt,uniteInputPromptError,uniteInputSpecial'
  endif
endfunction"}}}
"}}}

" Command functions.
function! unite#start(sources, ...)"{{{
  if empty(a:sources)
    call unite#print_error('[unite.vim] Source names is required.')
    return
  endif

  " Check command line window.
  if unite#util#is_cmdwin()
    call unite#print_error(
          \ '[unite.vim] Command line buffer is detected! Please close command line buffer.')
    return
  endif

  let context = get(a:000, 0, {})
  let context = s:initialize_context(context)

  let s:use_current_unite = 1

  if context.toggle"{{{
    if unite#close(context.buffer_name)
      return
    endif
  endif"}}}

  try
    call s:initialize_current_unite(a:sources, context)
  catch /^Invalid source/
    return
  endtry

  " Caching.
  let s:current_unite.last_input = context.input
  let s:current_unite.input = context.input
  call s:recache_candidates(context.input, context.is_redraw)

  if context.immediately || context.no_empty"{{{
    let candidates = unite#gather_candidates()

    if empty(candidates)
      " Ignore.
      let s:use_current_unite = 0
      return
    elseif context.immediately && len(candidates) == 1
      " Immediately action.
      call unite#mappings#do_action(context.default_action, [candidates[0]])
      let s:use_current_unite = 0
      return
    endif
  endif"}}}

  call s:initialize_unite_buffer()

  let s:use_current_unite = 0

  let unite = unite#get_current_unite()

  setlocal modifiable

  silent % delete _
  call unite#redraw_status()
  call setline(unite.prompt_linenr, unite.prompt . unite.context.input)
  for message in s:unite_cached_message
    call s:print_buffer(message)
    unlet message
  endfor
  call unite#redraw_candidates()

  call s:init_cursor()
endfunction"}}}
function! unite#start_temporary(sources, ...)"{{{
  if &filetype == 'unite'
    " Get current context.
    let old_context = unite#get_context()
    let unite = unite#get_current_unite()
    let context = deepcopy(old_context)
    let context.old_buffer_info = insert(context.old_buffer_info, {
          \ 'buffer_name' : unite.buffer_name,
          \ 'pos' : getpos('.'),
          \ 'profile_name' : unite.profile_name,
          \ })
  else
    let context = {}
    let context = s:initialize_context(context)
    let context.old_buffer_info = []
  endif

  let new_context = get(a:000, 0, {})
  let buffer_name = get(a:000, 1, matchstr(context.buffer_name, '^\S\+')
        \ . ' - ' . len(context.old_buffer_info))

  let context.buffer_name = buffer_name
  let context.temporary = 1
  let context.input = ''
  let context.auto_preview = 0
  let context.is_vimfiler = 0
  let context.default_action = 'default'

  " Overwrite context.
  let context = extend(context, new_context)

  let unite_save = unite#get_current_unite()

  call unite#all_quit_session()
  call unite#start(a:sources, context)

  " Overwrite unite.
  let unite = unite#get_current_unite()
  let unite.prev_bufnr = unite_save.prev_bufnr
  let unite.prev_winnr = unite_save.prev_winnr
endfunction"}}}
function! unite#vimfiler_check_filetype(sources, ...)"{{{
  let context = get(a:000, 0, {})
  let context = s:initialize_context(context)
  let context.is_vimfiler = 1

  try
    call s:initialize_current_unite(a:sources, context)
  catch /^Invalid source/
    return []
  endtry

  for source in filter(copy(unite#loaded_sources_list()),
        \ "has_key(v:val, 'vimfiler_check_filetype')")
    let ret = source.vimfiler_check_filetype(source.args, context)
    if empty(ret)
      continue
    endif

    let [type, info] = ret
    if type ==# 'file'
      call s:initialize_candidates([info[1]], source.name)
      call s:initialize_vimfiler_candidates([info[1]], source.name)
    elseif type ==# 'directory'
      " nop
    elseif type ==# 'error'
      call unite#print_error('[unite.vim]' . info)
      return []
    else
      call unite#print_error('[unite.vim] Invalid filetype : ' . type)
    endif

    return [type, info]
  endfor

  " Not found.
  return []
endfunction"}}}
function! unite#get_candidates(sources, ...)"{{{
  let context = get(a:000, 0, {})
  let context = s:initialize_context(context)
  let context.no_buffer = 1
  let context.is_interactive = 0

  let candidates = s:get_candidates(a:sources, context)

  " Finalize.
  let unite = unite#get_current_unite()

  " Call finalize functions.
  call s:call_hook(unite#loaded_sources_list(), 'on_close')
  let unite.is_finalized = 1

  return candidates
endfunction"}}}
function! unite#get_vimfiler_candidates(sources, ...)"{{{
  let context = get(a:000, 0, {})
  let context = s:initialize_context(context)
  let context.no_buffer = 1
  let context.is_vimfiler = 1

  return s:get_candidates(a:sources, context)
endfunction"}}}
function! unite#vimfiler_complete(sources, arglead, cmdline, cursorpos)"{{{
  let context = {}
  let context = s:initialize_context(context)
  let context.is_interactive = 0

  try
    call s:initialize_current_unite(a:sources, context)
  catch /^Invalid source/
    return
  endtry

  let _ = []
  for source in unite#loaded_sources_list()
    if has_key(source, 'vimfiler_complete')
      let _ += source.vimfiler_complete(
            \ source.args, context, a:arglead, a:cmdline, a:cursorpos)
    endif
  endfor

  return _
endfunction"}}}
function! unite#args_complete(sources, arglead, cmdline, cursorpos)"{{{
  let context = {}
  let context = s:initialize_context(context)
  let context.is_interactive = 0

  try
    call s:initialize_current_unite(a:sources, context)
  catch /^Invalid source/
    return []
  endtry

  let _ = []
  for source in unite#loaded_sources_list()
    if has_key(source, 'complete')
      let _ += source.complete(
            \ source.args, context, a:arglead, a:cmdline, a:cursorpos)
    endif
  endfor

  return _
endfunction"}}}
function! unite#resume(buffer_name, ...)"{{{
  " Check command line window.
  if unite#util#is_cmdwin()
    call unite#print_error(
          \ '[unite.vim] Command line buffer is detected! Please close command line buffer.')
    return
  endif

  if a:buffer_name == ''
    " Use last unite buffer.
    if !bufexists(s:last_unite_bufnr)
      call unite#util#print_error('No unite buffer.')
      return
    endif

    let bufnr = s:last_unite_bufnr
  else
    let buffer_name = a:buffer_name
    if buffer_name !~ '@\d\+$'
      " Add postfix.
      let prefix = unite#util#is_windows() ?
            \ '[unite] - ' : '*unite* - '
      let prefix .= buffer_name
      let buffer_name .= s:get_postfix(prefix, 0)
    endif

    let buffer_dict = {}
    for unite in map(filter(range(1, bufnr('$')),
          \ 'getbufvar(v:val, "&filetype") ==# "unite" &&
          \  !getbufvar(v:val, "unite").context.temporary'),
          \ 'getbufvar(v:val, "unite")')
      let buffer_dict[unite.buffer_name] = unite.bufnr
    endfor

    if !has_key(buffer_dict, buffer_name)
      return
    endif
    let bufnr = buffer_dict[buffer_name]
  endif

  let winnr = winnr()
  let win_rest_cmd = winrestcmd()

  if type(getbufvar(bufnr, 'unite')) != type({})
    " Unite buffer is released.
    call unite#util#print_error(
          \ printf('Invalid unite buffer(%d) is detected.', bufnr))
    return
  endif

  let context = getbufvar(bufnr, 'unite').context

  let new_context = get(a:000, 0, {})
  if has_key(new_context, 'no_start_insert')
        \ && new_context.no_start_insert
    let new_context.start_insert = 0
  endif
  call extend(context, new_context)

  call s:switch_unite_buffer(bufname(bufnr), context)

  " Set parameters.
  let unite = unite#get_current_unite()
  let unite.winnr = winnr
  let unite.win_rest_cmd = win_rest_cmd
  let unite.redrawtime_save = &redrawtime
  let unite.access_time = localtime()
  let unite.context = context

  call unite#set_current_unite(unite)

  call s:init_cursor()
endfunction"}}}
function! s:get_candidates(sources, context)"{{{
  try
    call s:initialize_current_unite(a:sources, a:context)
  catch /^Invalid source/
    return []
  endtry

  " Call initialize functions.
  let unite = unite#get_current_unite()
  call s:call_hook(unite.sources, 'on_init')

  " Caching.
  let s:current_unite.last_input = a:context.input
  let s:current_unite.input = a:context.input
  call s:recache_candidates(a:context.input, a:context.is_redraw)

  let candidates = []
  for source in unite#loaded_sources_list()
    if !empty(source.unite__candidates)
      let candidates += a:context.is_vimfiler ?
            \ s:initialize_vimfiler_candidates(
            \   source.unite__candidates, source.name) :
            \ source.unite__candidates
    endif
  endfor

  return candidates
endfunction"}}}

function! unite#close(buffer_name)  "{{{
  let buffer_name = a:buffer_name
  if buffer_name !~ '@\d\+$'
    " Add postfix.
    let prefix = unite#util#is_windows() ?
          \ '[unite] - ' : '*unite* - '
    let prefix .= buffer_name
    let buffer_name .= s:get_postfix(prefix, 0)
  endif

  let quit_winnr = 0

  " Search unite window.
  " Note: must escape file-pattern.
  let buffer_name = unite#util#escape_file_searching(buffer_name)

  if bufwinnr(buffer_name) > 0
    let quit_winnr = bufwinnr(buffer_name)
  else
    " Search from temporary buffer.
    let winnr = 1
    while winnr <= winnr('$')
      if getbufvar(winbufnr(winnr), '&filetype') ==# 'unite'
        let buffer_context = getbufvar(winbufnr(winnr), 'unite').context
        if buffer_context.temporary
              \ && !empty(filter(copy(buffer_context.old_buffer_info),
              \ 'v:val.buffer_name ==# context.buffer_name'))
          let quit_winnr = winnr
          " Disable resume.
          let buffer_context.old_buffer_info = []
          break
        endif
      endif

      let winnr += 1
    endwhile
  endif

  if quit_winnr > 0
    " Quit unite buffer.
    silent execute quit_winnr 'wincmd w'
    call unite#force_quit_session()
  endif

  return quit_winnr > 0
endfunction"}}}

function! unite#all_quit_session(...)  "{{{
  call s:quit_session(get(a:000, 0, 1))
endfunction"}}}
function! unite#force_quit_session()  "{{{
  call s:quit_session(1)

  let context = unite#get_context()
  if context.temporary
    call unite#resume_from_temporary(context)
  endif
endfunction"}}}
function! unite#quit_session()  "{{{
  call s:quit_session(0)

  let context = unite#get_context()
  if context.temporary
    call unite#resume_from_temporary(context)
  endif
endfunction"}}}
function! s:quit_session(is_force)  "{{{
  if &filetype !=# 'unite'
    return
  endif

  " Save unite value.
  let unite_save = s:current_unite
  call unite#set_current_unite(b:unite)
  let unite = b:unite
  let context = unite.context

  let key = unite#loaded_source_names_string()

  " Save position.
  let positions = unite#get_profile(
        \ unite.profile_name, 'unite__save_pos')
  let positions[key] = {
        \ 'pos' : getpos('.'),
        \ 'candidate' : unite#get_current_candidate(),
        \ }

  if context.input != ''
    " Save input.
    let inputs = unite#get_profile(
          \ unite.profile_name, 'unite__inputs')
    if !has_key(inputs, key)
      let inputs[key] = []
    endif
    call insert(filter(inputs[key],
          \ 'v:val !=# unite.context.input'), context.input)
  endif

  if a:is_force || !context.no_quit
    let bufname = bufname('%')

    if winnr('$') == 1 || context.no_split
      call unite#util#alternate_buffer()
    else
      noautocmd close!
      if unite.winnr == winnr()
        doautocmd WinEnter
      else
        execute unite.winnr . 'wincmd w'
      endif
      call unite#_resize_window()
    endif

    call s:on_buf_unload(bufname)
  else
    let winnr = bufwinnr(unite.prev_bufnr)
    if winnr < 0
      let winnr = unite.prev_winnr
    endif
    if winnr == winnr() || winnr < 0
      new
    else
      execute winnr 'wincmd w'
    endif
    let unite.prev_winnr = winnr()
  endif

  if context.complete
    if context.col < col('$')
      startinsert
    else
      startinsert!
    endif
  else
    stopinsert
    redraw!
  endif

  " Restore unite.
  call unite#set_current_unite(unite_save)
endfunction"}}}
function! unite#resume_from_temporary(context)  "{{{
  if empty(a:context.old_buffer_info)
    return
  endif

  call s:on_buf_unload(a:context.buffer_name)

  let unite_save = unite#get_current_unite()

  " Resume unite buffer.
  let buffer_info = a:context.old_buffer_info[0]
  call unite#resume(buffer_info.buffer_name)
  call setpos('.', buffer_info.pos)
  let a:context.old_buffer_info = a:context.old_buffer_info[1:]

  " Overwrite unite.
  let unite = unite#get_current_unite()
  let unite.prev_bufnr = unite_save.prev_bufnr
  let unite.prev_winnr = unite_save.prev_winnr
endfunction"}}}

function! s:load_default_scripts()"{{{
  " Gathering all sources and kind name.
  let s:static.sources = {}
  let s:static.kinds = {}
  let s:static.filters = {}

  for key in ['sources', 'kinds', 'filters']
    for name in map(split(globpath(&runtimepath,
          \ 'autoload/unite/' . key . '/*.vim'), '\n'),
          \ 'fnamemodify(v:val, ":t:r")')

      let define = unite#{key}#{name}#define()
      for dict in (type(define) == type([]) ? define : [define])
        if !empty(dict) && !has_key(s:static[key], dict.name)
          let s:static[key][dict.name] = dict
        endif
      endfor
      unlet define
    endfor
  endfor
endfunction"}}}
function! s:initialize_context(context)"{{{
  let default_context = {
        \ 'input' : '',
        \ 'complete' : 0,
        \ 'col' : col('.'),
        \ 'no_quit' : 0,
        \ 'buffer_name' : 'default',
        \ 'prompt' : '> ',
        \ 'default_action' : 'default',
        \ 'winwidth' : g:unite_winwidth,
        \ 'winheight' : g:unite_winheight,
        \ 'immediately' : 0,
        \ 'no_empty' : 0,
        \ 'auto_preview' : 0,
        \ 'vertical' : g:unite_enable_split_vertically,
        \ 'direction' : g:unite_split_rule,
        \ 'no_split' : 0,
        \ 'temporary' : 0,
        \ 'verbose' : 0,
        \ 'auto_resize' : 0,
        \ 'old_buffer_info' : [],
        \ 'toggle' : 0,
        \ 'quick_match' : 0,
        \ 'create' : 0,
        \ 'is_redraw' : 0,
        \ 'cursor_line_highlight' :
        \    g:unite_cursor_line_highlight,
        \ 'no_cursor_line' : 0,
        \ 'update_time' : g:unite_update_time,
        \ 'no_buffer' : 0,
        \ 'is_interactive' : 1,
        \ 'is_vimfiler' : 0,
        \ 'hide_source_names' : 0,
        \ }

  let context = extend(default_context, a:context)

  " Complex initializer.
  if !has_key(context, 'start_insert')
    let context.start_insert = context.complete ?
          \ 1 : g:unite_enable_start_insert
  endif
  if has_key(context, 'no_start_insert')
        \ && context.no_start_insert
    " Disable start insert.
    let context.start_insert = 0
  endif
  if !has_key(context, 'profile_name')
    let context.profile_name = context.buffer_name
  endif
  if has_key(context, 'horizontal')
    " Disable vertically.
    let context.vertical = 0
  endif
  if context.immediately
    " Ignore empty unite buffer.
    let context.no_empty = 1
  endif
  let context.is_changed = 0

  return context
endfunction"}}}
function! s:initialize_loaded_sources(sources, context)"{{{
  let all_sources = s:initialize_sources()
  let sources = []

  let number = 0
  for [source, args] in map(a:sources,
        \ 'type(v:val) == type([]) ? [v:val[0], v:val[1:]] : [v:val, []]')
    if type(source) == type('')
      let source_name = source
      unlet source
      if !has_key(all_sources, source_name)
        if a:context.is_vimfiler
          " Ignore error.
          continue
        endif

        call unite#util#print_error(
              \ 'unite.vim: Invalid source name "' .
              \ source_name . '" is detected.')
        throw 'Invalid source'
      endif

      let source = deepcopy(all_sources[source_name])
    else
      " Use source dictionary.
      call s:initialize_sources([source])
    endif

    let source.args = args
    let source.unite__is_invalidate = 1

    let source.unite__context = deepcopy(a:context)
    let source.unite__context.is_async =
          \ has_key(source, 'async_gather_candidates')
    let source.unite__context.source = source
    let source.unite__candidates = []
    let source.unite__cached_candidates = []
    let source.unite__cached_change_candidates = []
    let source.unite__number = number
    let number += 1

    call add(sources, source)

    unlet source
  endfor

  return sources
endfunction"}}}
function! s:initialize_sources(...)"{{{
  if empty(s:static)
    " Initialize load.
    call s:load_default_scripts()
  endif

  let sources = get(a:000, 0,
        \ extend(copy(s:static.sources), s:dynamic.sources))

  let filterd_sources = filter(copy(sources),
        \ '!has_key(v:val, "is_initialized")')
  for source in type(filterd_sources) == type([]) ?
        \ filterd_sources : values(filterd_sources)
    try
      let source.is_initialized = 1

      if !has_key(source, 'hooks')
        let source.hooks = {}
      endif

      if has_key(source.hooks, 'on_pre_init')
        " Call pre_init hook.

        " Set dummey value.
        let source.args = []
        let source.unite__context = { 'source' : source }

        " Overwrite source values.
        call s:call_hook([source], 'on_pre_init')
      endif

      if !has_key(source, 'is_volatile')
        let source.is_volatile = 0
      endif
      if !has_key(source, 'is_listed')
        let source.is_listed = 1
      endif
      if !has_key(source, 'is_forced')
        let source.is_forced = 0
      endif
      if !has_key(source, 'required_pattern_length')
        let source.required_pattern_length = 0
      endif

      if !has_key(source, 'action_table')
        let source.action_table = {}
      elseif !empty(source.action_table)
        let action = values(source.action_table)[0]

        " Check if '*' action_table?
        if has_key(action, 'func')
              \ && type(action.func) == type(function('type'))
          " Syntax sugar.
          let source.action_table = { '*' : source.action_table }
        endif
      endif

      if !has_key(source, 'default_action')
        let source.default_action = {}
      elseif type(source.default_action) == type('')
        " Syntax sugar.
        let source.default_action = { '*' : source.default_action }
      endif

      if !has_key(source, 'alias_table')
        let source.alias_table = {}
      elseif !empty(source.alias_table)
        " Check if '*' alias_table?
        if type(values(source.alias_table)[0]) == type('')
          " Syntax sugar.
          let source.alias_table = { '*' : source.alias_table }
        endif
      endif
      if !has_key(source, 'description')
        let source.description = ''
      endif
      if !has_key(source, 'syntax')
        let source.syntax = ''
      endif
      if source.is_volatile
            \ && !has_key(source, 'change_candidates')
        let source.change_candidates = source.gather_candidates
        call remove(source, 'gather_candidates')
      endif

      let source.filters =
            \ has_key(s:custom.filters, source.name) ?
            \ s:custom.filters[source.name] :
            \ has_key(source, 'filters') ?
            \ source.filters :
            \ unite#filters#default#get()
      let source.max_candidates =
            \ has_key(s:custom.max_candidates, source.name) ?
            \ s:custom.max_candidates[source.name] :
            \ has_key(source, 'max_candidates') ?
            \ source.max_candidates :
            \ 0
    catch
      call unite#print_error(v:throwpoint)
      call unite#print_error(v:exception)
      call unite#print_error('[unite.vim] Error occured in source initialization!')
      call unite#print_error('[unite.vim] Source name is ' . source.name)
    endtry
  endfor

  return sources
endfunction"}}}
function! s:initialize_kinds()"{{{
  let kinds = extend(copy(s:static.kinds), s:dynamic.kinds)
  for kind in values(filter(copy(kinds), '!has_key(v:val, "is_initialized")'))
    let kind.is_initialized = 1
    if !has_key(kind, 'action_table')
      let kind.action_table = {}
    endif
    if !has_key(kind, 'alias_table')
      let kind.alias_table = {}
    endif
    if !has_key(kind, 'parents')
      let kind.parents = ['common']
    endif
  endfor

  return kinds
endfunction"}}}
function! s:initialize_filters()"{{{
  return extend(copy(s:static.filters), s:dynamic.filters)
endfunction"}}}
function! s:initialize_profile(profile_name)"{{{
  if !has_key(s:profiles, a:profile_name)
    let s:profiles[a:profile_name] = {}
  endif
  let setting = s:profiles[a:profile_name]
  if !has_key(setting, 'substitute_patterns')
    let setting.substitute_patterns = {}
  endif
  if !has_key(setting, 'filters')
    let setting.filters = []
  endif
  if !has_key(setting, 'ignorecase')
    let setting.ignorecase = &ignorecase
  endif
  if !has_key(setting, 'smartcase')
    let setting.smartcase = &smartcase
  endif
  if !has_key(setting, 'unite__save_pos')
    let setting.unite__save_pos = {}
  endif
  if !has_key(setting, 'unite__inputs')
    let setting.unite__inputs = {}
  endif
endfunction"}}}
function! s:initialize_candidates(candidates, source_name)"{{{
  let unite = unite#get_current_unite()
  let winwidth = unite.context.vertical ?
        \ unite.context.winwidth : &columns
  let [max_width, max_source_name] =
        \ s:adjustments(winwidth-5, unite.max_source_name, 2)

  let candidates = []
  for candidate in a:candidates
    let candidate = deepcopy(candidate)
    if !has_key(candidate, 'abbr')
      let candidate.abbr = candidate.word
    endif
    if !has_key(candidate, 'kind')
      let candidate.kind = 'common'
    endif
    if !has_key(candidate, 'is_dummy')
      let candidate.is_dummy = 0
    endif
    if !has_key(candidate, 'is_matched')
      let candidate.is_matched = 1
    endif
    if !has_key(candidate, 'unite__is_marked')
      let candidate.unite__is_marked = 0
    endif

    " Force set.
    let candidate.source = a:source_name

    let candidate.is_multiline = get(candidate, 'is_multiline', 0)

    " Delete too long abbr.
    if candidate.is_multiline
      let candidate.abbr = candidate.abbr[: max_width * 8+10]
    elseif len(candidate.abbr) > max_width * 2
      let candidate.abbr = candidate.abbr[: max_width * 2]
    endif

    " Substitute tab.
    let candidate.abbr = substitute(candidate.abbr, '\t',
          \ repeat(' ', &tabstop), 'g')

    if !candidate.is_multiline
      let candidate.abbr = '  ' . candidate.abbr
      call add(candidates, candidate)
      continue
    endif

    if candidate.abbr !~ '\n'
      " Auto split.
      let abbr = candidate.abbr
      let candidate.abbr = ''

      while abbr != ''
        let trunc_abbr = unite#util#strwidthpart(abbr, max_width)
        let candidate.abbr .= trunc_abbr . "~\n"
        let abbr = abbr[len(trunc_abbr):]
      endwhile

      let candidate.abbr = substitute(candidate.abbr, '\~\n$', '', '')
    else
      let candidate.abbr = substitute(candidate.abbr, '\r\?\n$', '^@', '')
    endif

    if candidate.abbr !~ '\n'
      let candidate.abbr = '  ' . candidate.abbr
      call add(candidates, candidate)
      continue
    endif

    " Convert multi line.
    let cnt = 0
    for multi in split(candidate.abbr, '\r\?\n', 1)[:4]
      let candidate_multi = deepcopy(candidate)
      let candidate_multi.abbr =
            \ (cnt == 0 ? '+ ' : '| ') . multi

      if cnt != 0
        let candidate_multi.is_dummy = 1
      endif

      call add(candidates, candidate_multi)

      let cnt += 1
    endfor
  endfor

  return candidates
endfunction"}}}
function! s:initialize_vimfiler_candidates(candidates, source_name)"{{{
  " Set default vimfiler property.
  for candidate in a:candidates
    if !has_key(candidate, 'vimfiler__filename')
      let candidate.vimfiler__filename = candidate.word
    endif
    if !has_key(candidate, 'vimfiler__abbr')
      let candidate.vimfiler__abbr = candidate.word
    endif
    if !has_key(candidate, 'vimfiler__is_directory')
      let candidate.vimfiler__is_directory = 0
    endif
    if !has_key(candidate, 'vimfiler__is_executable')
      let candidate.vimfiler__is_executable = 0
    endif
    if !has_key(candidate, 'vimfiler__filesize')
      let candidate.vimfiler__filesize = -1
    endif
    if !has_key(candidate, 'vimfiler__filetime')
      let candidate.vimfiler__filetime = 0
    endif
    if !has_key(candidate, 'vimfiler__datemark')
      let candidate.vimfiler__datemark = vimfiler#get_datemark(candidate)
    endif
    if !has_key(candidate, 'vimfiler__extension')
      let candidate.vimfiler__extension =
            \ candidate.vimfiler__is_directory ?
            \ '' : fnamemodify(candidate.vimfiler__filename, ':e')
    endif
    if !has_key(candidate, 'vimfiler__filetype')
      let candidate.vimfiler__filetype = vimfiler#get_filetype(candidate)
    endif
    let candidate.vimfiler__is_marked = 0
    let candidate.source = a:source_name
  endfor

  return a:candidates
endfunction"}}}

function! s:recache_candidates(input, is_force)"{{{
  let unite = unite#get_current_unite()

  " Save options.
  let ignorecase_save = &ignorecase

  if unite#get_profile(unite.profile_name, 'smartcase')
        \ && a:input =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase =
          \ unite#get_profile(unite.profile_name, 'ignorecase')
  endif

  let context = unite.context
  let context.is_redraw = a:is_force
  let context.is_changed = a:input !=# unite.last_input

  for source in unite#loaded_sources_list()
    let source.unite__candidates = []
  endfor

  let inputs = s:get_substitute_input(a:input)
  let context.is_list_input = len(inputs) > 1
  for input in inputs
    let context.input = input
    call s:recache_candidates_loop(context, a:is_force)
  endfor

  let filtered_count = 0

  for source in unite#loaded_sources_list()
    let source.unite__is_invalidate = 0

    if !context.no_buffer && source.max_candidates != 0
          \ && !unite.is_enabled_max_candidates
          \ && len(source.unite__candidates) > source.max_candidates
      " Filtering too many candidates.
      let source.unite__candidates =
            \ source.unite__candidates[: source.max_candidates - 1]

      if context.verbose && filtered_count < &cmdheight
        echohl WarningMsg | echomsg printf('[%s] Filtering too many candidates.', source.name) | echohl None
        let filtered_count += 1
      endif
    endif

    " Call post_filter hook.
    let source.unite__context.candidates = source.unite__candidates
    call s:call_hook([source], 'on_post_filter')

    let source.unite__candidates = s:initialize_candidates(
          \ source.unite__candidates, source.name)
  endfor

  " Update async state.
  let unite.is_async =
        \ len(filter(copy(unite.sources),
        \           'v:val.unite__context.is_async')) > 0

  let &ignorecase = ignorecase_save
endfunction"}}}
function! s:recache_candidates_loop(context, is_force)"{{{
  let unite = unite#get_current_unite()

  let input_len = unite#util#strchars(a:context.input)

  for source in unite#loaded_sources_list()
    " Check required pattern length.
    if input_len < source.required_pattern_length
      continue
    endif

    " Set context.
    let source.unite__context.input = a:context.input
    if source.required_pattern_length > 0
          \ && !source.is_forced
      " Forced redraw.
      let source.unite__context.is_redraw = 1
      let source.is_forced = 1
    else
      let source.unite__context.is_redraw =
            \ a:context.is_redraw
    endif
    let source.unite__context.is_changed =
          \ a:context.is_changed
    let source.unite__context.is_invalidate =
          \ source.unite__is_invalidate
    let source.unite__context.is_list_input =
          \ a:context.is_list_input

    let source_candidates = s:get_source_candidates(source)

    let custom_source = get(s:custom.source, source.name, {})

    " Call pre_filter hook.
    let source.unite__context.candidates = source_candidates
    call s:call_hook([source], 'on_pre_filter')

    " Filter.
    for filter_name in get(custom_source, 'filters', source.filters)
        let source_candidates = unite#call_filter(
              \ filter_name, source_candidates, source.unite__context)
    endfor

    let source.unite__candidates += source_candidates
  endfor
endfunction"}}}
function! s:get_source_candidates(source)"{{{
  let context = a:source.unite__context

  let funcname = 's:get_source_candidates()'
  try
    if context.is_vimfiler
      if context.vimfiler__is_dummy
        let funcname = 'vimfiler_dummy_candidates'
        return has_key(a:source, 'vimfiler_dummy_candidates') ?
              \ copy(a:source.vimfiler_dummy_candidates(
              \           a:source.args, a:source.unite__context)) : []
      else
        let funcname = 'vimfiler_gather_candidates'
        return has_key(a:source, 'vimfiler_gather_candidates') ?
              \ copy(a:source.vimfiler_gather_candidates(
              \           a:source.args, a:source.unite__context)) : []
      endif
    endif

    if context.is_redraw || a:source.unite__is_invalidate
      " Recaching.
      let a:source.unite__cached_candidates = []

      let funcname = 'gather_candidates'
      if has_key(a:source, 'gather_candidates')
        let a:source.unite__cached_candidates +=
              \ copy(a:source.gather_candidates(a:source.args, context))
      endif
    endif

    if a:source.unite__context.is_async
      " Get asyncronous candidates.
      let funcname = 'async_gather_candidates'
      while 1
        let a:source.unite__cached_candidates +=
              \ a:source.async_gather_candidates(a:source.args, context)

        if context.is_interactive
              \ || !a:source.unite__context.is_async
          break
        endif
      endwhile
    endif

    if has_key(a:source, 'change_candidates')
          \ && (context.is_redraw || context.is_changed
          \     || a:source.unite__is_invalidate)
      " Recaching.
      let funcname = 'change_candidates'
      let a:source.unite__cached_change_candidates =
            \ a:source.change_candidates(a:source.args, a:source.unite__context)
    endif
  catch
      call unite#print_error(v:throwpoint)
      call unite#print_error(v:exception)
      call unite#print_error('[unite.vim] Error occured in ' . funcname . '!')
      call unite#print_error('[unite.vim] Source name is ' . a:source.name)

      return []
  endtry

  return a:source.unite__cached_candidates
        \ + a:source.unite__cached_change_candidates
endfunction"}}}
function! s:convert_quick_match_lines(candidates, quick_match_table)"{{{
  let unite = unite#get_current_unite()
  let [max_width, max_source_name] =
        \ s:adjustments(winwidth(0)-1, unite.max_source_name, 2)
  if unite.max_source_name == 0
    let max_width -= 1
  endif

  let candidates = []

  " Create key table.
  let keys = {}
  for [key, number] in items(a:quick_match_table)
    let keys[number] = key . '|'
  endfor

  " Add number.
  let num = 0
  for candidate in a:candidates
    call add(candidates,
          \ (candidate.is_dummy ? '  ' : get(keys, num, '  '))
          \ . (unite.max_source_name == 0 ? '' :
          \    unite#util#truncate(candidate.source, max_source_name))
          \ . unite#util#truncate_smart(candidate.abbr, max_width, max_width/3, '..'))
    let num += 1
  endfor

  return candidates
endfunction"}}}
function! s:convert_lines(candidates)"{{{
  let unite = unite#get_current_unite()
  let [max_width, max_source_name] =
        \ s:adjustments(winwidth(0)-1, unite.max_source_name, 2)
  if unite.max_source_name == 0
    let max_width -= 1
  endif

  return map(copy(a:candidates),
        \ "(v:val.unite__is_marked ? '* ' : '- ')
        \ . (unite.max_source_name == 0 ? ''
        \   : unite#util#truncate(v:val.source, max_source_name))
        \ . unite#util#truncate_smart(v:val.abbr, " . max_width .  ", max_width/3, '..')")
endfunction"}}}

function! s:initialize_current_unite(sources, context)"{{{
  let s:unite_cached_message = []

  let context = a:context

  if getbufvar(bufnr('%'), '&filetype') ==# 'unite'
        \ && unite#get_current_unite().buffer_name ==# context.buffer_name
        \ && context.input == ''
    " Get input text.
    let context.input = unite#get_input()
  endif

  " Quit previous unite buffer.
  if !context.create
    let winnr = 1
    while winnr <= winnr('$')
      if getbufvar(winbufnr(winnr), '&filetype') ==# 'unite'
        let buffer_context = getbufvar(winbufnr(winnr), 'unite').context
        if buffer_context.buffer_name ==# context.buffer_name
          " Quit unite buffer.
          execute winnr 'wincmd w'
          call unite#force_quit_session()
          break
        endif
      endif

      let winnr += 1
    endwhile
  endif

  " The current buffer is initialized.
  let buffer_name = unite#util#is_windows() ?
        \ '[unite] - ' : '*unite* - '
  let buffer_name .= context.buffer_name

  let winnr = winnr()
  let win_rest_cmd = winrestcmd()

  " Check sources.
  let sources = s:initialize_loaded_sources(a:sources, a:context)

  if a:context.is_interactive
    " Call initialize functions.
    call s:call_hook(sources, 'on_init')
  endif

  " Set parameters.
  let unite = {}
  let unite.winnr = winnr
  let unite.win_rest_cmd = win_rest_cmd
  let unite.context = context
  let unite.candidates = []
  let unite.sources = sources
  let unite.kinds = s:initialize_kinds()
  let unite.filters = s:initialize_filters()
  let unite.buffer_name = (context.buffer_name == '') ?
        \ 'default' : context.buffer_name
  let unite.profile_name = (context.profile_name == '') ?
        \ unite.buffer_name : context.profile_name
  let unite.buffer_options =
        \ s:initialize_profile(unite.profile_name)
  let unite.prev_bufnr = bufnr('%')
  let unite.prev_winnr = winnr()

  " Create new buffer name.
  let postfix = s:get_postfix(buffer_name, 1)
  let unite.buffer_name .= postfix

  let unite.real_buffer_name = buffer_name . postfix
  let unite.prompt = context.prompt
  let unite.input = context.input
  let unite.last_input = context.input
  let unite.sidescrolloff_save = &sidescrolloff
  let unite.prompt_linenr = (context.hide_source_names) ? 1 : 2
  let unite.is_async =
        \ len(filter(copy(sources),
        \  'v:val.unite__context.is_async')) > 0
  let unite.access_time = localtime()
  let unite.is_finalized = 0
  let unite.is_enabled_max_candidates = 0
  let unite.previewd_buffer_list = []
  let unite.post_filters = unite#get_profile(
        \ unite.profile_name, 'filters')
  let unite.preview_candidate = {}

  let unite.max_source_name =
        \ !context.hide_source_names && len(a:sources) > 1 ?
        \ max(map(copy(a:sources), 'len(v:val[0])')) : 0

  " Preview windows check.
  let unite.has_preview_window =
   \ len(filter(range(1, winnr('$')),
   \  'getwinvar(v:val, "&previewwindow")')) > 0

  call unite#set_current_unite(unite)
endfunction"}}}
function! s:initialize_unite_buffer()"{{{
  let is_bufexists = bufexists(s:current_unite.real_buffer_name)
  call s:switch_unite_buffer(
        \ s:current_unite.real_buffer_name, s:current_unite.context)

  let b:unite = s:current_unite
  let unite = unite#get_current_unite()

  if !unite.context.temporary
    let s:last_unite_bufnr = bufnr('%')
  endif
  let unite.bufnr = bufnr('%')

  " Note: If unite buffer initialize is incomplete, &modified or &wrap.
  if !is_bufexists || &modified || &wrap
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

    " Keep window width and height.
    if !unite.context.no_split
      if unite.context.vertical
        setlocal winfixwidth
      else
        setlocal winfixheight
      endif
    endif

    " Autocommands.
    augroup plugin-unite
      autocmd InsertEnter <buffer>
            \ call s:on_insert_enter()
      autocmd InsertLeave <buffer>
            \ call s:on_insert_leave()
      autocmd CursorHoldI <buffer>
            \ call s:on_cursor_hold_i()
      autocmd CursorMoved,CursorMovedI <buffer>  nested
            \ call s:on_cursor_moved()
      autocmd BufUnload,BufHidden <buffer>
            \ call s:on_buf_unload(expand('<afile>'))
      autocmd WinEnter,BufWinEnter <buffer>
            \ call s:save_updatetime()
      autocmd WinLeave,BufWinLeave <buffer>
            \ call s:restore_updatetime()
    augroup END

    call unite#mappings#define_default_mappings()

    if exists(':NeoComplCacheLock')
      " Lock neocomplcache.
      NeoComplCacheLock
    endif
  endif

  if exists('&redrawtime')
    " Save redrawtime
    let unite.redrawtime_save = &redrawtime
    let &redrawtime = 100
  endif

  call s:save_updatetime()

  " User's initialization.
  setlocal nomodifiable
  set sidescrolloff=0
  setlocal nocursorline
  setfiletype unite

  if !exists('b:current_syntax') || b:current_syntax !=# 'unite'
    return
  endif

  " Set highlight.
  let match_prompt = escape(unite.prompt, '\/*~.^$[]')
  syntax clear uniteInputPrompt
  execute 'syntax match uniteInputPrompt'
        \ '/^'.match_prompt.'/ contained'

  if !unite.context.hide_source_names
    syntax match uniteStatusLine /\%1l.*/
          \  contains=uniteSourcePrompt,uniteSeparator,uniteSourceNames,uniteSourceArgs
  endif

  execute 'syntax match uniteInputLine'
        \ '/\%'.unite.prompt_linenr.'l.*/'
        \ 'contains=uniteInputPrompt,uniteInputPromptError,uniteInputSpecial'

  syntax clear uniteCandidateSourceName
  if unite.max_source_name > 0
    syntax match uniteCandidateSourceName
          \ /\%3c[[:alnum:]_\/-]\+/ contained
  else
    syntax match uniteCandidateSourceName /^- / contained
  endif
  let source_padding = 4

  let unite.abbr_head = unite.max_source_name+source_padding
  execute 'syntax match uniteCandidateAbbr' '/\%'
        \ .(unite.abbr_head).'c.*/ contained'

  execute 'highlight default link uniteCandidateAbbr'
        \ g:unite_abbr_highlight

  " Set syntax.
  for source in filter(copy(unite.sources), 'v:val.syntax != ""')
    let name = unite.max_source_name > 0 ?
          \ source.name : ''

    execute 'syntax match' source.syntax '/\%'
          \ .(unite.abbr_head).'c.*/ contained'

    execute 'highlight default link'
          \ source.syntax g:unite_abbr_highlight

    execute printf('syntax region %s start="^- %s" end="$" '.
          \ 'contains=uniteCandidateMarker,%s%s',
          \ 'uniteSourceLine__'.source.syntax,
          \ (name == '' ? '' : name . '\>'),
          \ (name == '' ? '' : 'uniteCandidateSourceName,'),
          \    source.syntax
          \ )

    call s:call_hook([source], 'on_syntax')
  endfor
endfunction"}}}
function! s:switch_unite_buffer(buffer_name, context)"{{{
  " Search unite window.
  " Note: must escape file-pattern.
  let buffer_name = unite#util#escape_file_searching(a:buffer_name)
  if !a:context.no_split && bufwinnr(buffer_name) > 0
    silent execute bufwinnr(buffer_name) 'wincmd w'
  else
    if !a:context.no_split
      " Split window.
      execute a:context.direction (bufexists(a:buffer_name) ?
            \ ((a:context.vertical) ? 'vsplit' : 'split') :
            \ ((a:context.vertical) ? 'vnew' : 'new'))
    endif

    if bufexists(a:buffer_name)
      " Search buffer name.
      let bufnr = 1
      let max = bufnr('$')
      while bufnr <= max
        if bufname(bufnr) ==# a:buffer_name
          silent execute bufnr 'buffer'
          break
        endif

        let bufnr += 1
      endwhile
    else
      silent! edit `=a:buffer_name`
    endif
  endif

  if !a:context.no_split && winnr('$') != 1
    call unite#_resize_window()
  endif
endfunction"}}}

function! s:redraw(is_force, winnr) "{{{
  if unite#util#is_cmdwin()
    return
  endif

  if a:winnr > 0
    " Set current unite.
    let use_current_unite_save = s:use_current_unite
    let s:use_current_unite = 1
    let unite = getbufvar(winbufnr(a:winnr), 'unite')
    let unite_save = s:current_unite
    let winnr_save = winnr()

    execute a:winnr 'wincmd w'
  endif

  if &filetype !=# 'unite'
    return
  endif

  let unite = unite#get_current_unite()
  let context = unite.context

  if !context.is_redraw
    let context.is_redraw = a:is_force
  endif

  if context.is_redraw
    call unite#clear_message()
  endif

  let input = unite#get_input()
  if !context.is_redraw && input ==# unite.last_input
        \ && !unite.is_async
    return
  endif

  " Recaching.
  call s:recache_candidates(input, a:is_force)

  let unite.last_input = input

  " Redraw.
  call unite#redraw_candidates()
  let unite.context.is_redraw = 0

  if a:winnr > 0
    " Restore current unite.
    let s:use_current_unite = use_current_unite_save
    let s:current_unite = unite_save
    execute winnr_save 'wincmd w'
    call unite#_resize_window()
  endif

  let context = unite#get_context()
  if context.immediately
    " Immediately action.
    let candidates = unite#gather_candidates()

    if len(candidates) == 1
      " Default action.
      call unite#mappings#do_action(
            \ context.default_action, [candidates[0]])
    endif
  endif

  if context.auto_preview
    call s:do_auto_preview()
  endif
endfunction"}}}
function! unite#_resize_window() "{{{
  if &filetype !=# 'unite' || winnr('$') == 1
    return
  endif

  let context = unite#get_context()
  let unite = unite#get_current_unite()

  if context.no_split
    return
  endif

  if context.auto_resize
    " Auto resize.
    let max_len = unite.prompt_linenr + len(unite.candidates)
    execute 'resize' min([max_len, context.winheight])
    normal! zb
    if mode() ==# 'i' && col('.') == (col('$') - 1)
      startinsert!
    endif
  elseif context.vertical
        \ && winwidth(winnr()) != context.winwidth
    execute 'vertical resize' context.winwidth
    let context.winwidth = winwidth(winnr())
  elseif !context.vertical
        \ && winheight(winnr()) != context.winheight
    execute 'resize' context.winheight
    let context.winheight = winheight(winnr())
  endif
endfunction"}}}

" Autocmd events.
function! s:on_insert_enter()  "{{{
  let unite = unite#get_current_unite()
  let unite.is_insert = 1
  setlocal modifiable

  if line('.') != unite.prompt_linenr
        \ || col('.') <= len(unite.prompt)
    execute unite.prompt_linenr
    normal! zb
    startinsert!
  endif
endfunction"}}}
function! s:on_insert_leave()  "{{{
  let unite = unite#get_current_unite()

  if line('.') != unite.prompt_linenr
    normal! 0
  endif

  let unite.is_insert = 0

  if &filetype ==# 'unite'
    setlocal nomodifiable
  endif
endfunction"}}}
function! s:on_cursor_hold_i()  "{{{
  let unite = unite#get_current_unite()
  let prompt_linenr = unite.prompt_linenr
  if line('.') == prompt_linenr || unite.context.is_redraw
    " Redraw.
    call unite#redraw()
    call s:change_highlight()
  endif

  " Prompt check.
  if line('.') == prompt_linenr && col('.') <= len(unite.prompt)
    startinsert!
  endif

  if unite.is_async && &l:modifiable
    " Ignore key sequences.
    call feedkeys("a\<BS>", 'n')
    " call feedkeys("\<C-r>\<ESC>", 'n')
  endif
endfunction"}}}
function! unite#_on_cursor_hold()  "{{{
  if &filetype ==# 'unite'
    " Redraw.
    call unite#redraw()
    call s:change_highlight()

    if unite#get_current_unite().is_async
      " Ignore key sequences.
      call feedkeys("g\<ESC>", 'n')
    endif
  else
    " Search other unite window.
    let winnr = 1
    while winnr <= winnr('$')
      if getbufvar(winbufnr(winnr), '&filetype') ==# 'unite'
            \ && getbufvar(winbufnr(winnr), 'unite').is_async
        " Redraw unite buffer.
        call unite#redraw(winnr)
      endif

      let winnr += 1
    endwhile
  endif
endfunction"}}}
function! s:on_cursor_moved()  "{{{
  if &filetype !=# 'unite'
    return
  endif

  let prompt_linenr = unite#get_current_unite().prompt_linenr
  let context = unite#get_context()

  setlocal nocursorline

  execute 'setlocal' line('.') == prompt_linenr ?
        \ 'modifiable' : 'nomodifiable'

  if exists('b:current_syntax') && !context.no_cursor_line
    silent! execute 'match' (line('.') <= prompt_linenr ?
          \ line('$') <= prompt_linenr ?
          \ 'uniteError /\%'.prompt_linenr.'l/' :
          \ context.cursor_line_highlight.' /\%'.(prompt_linenr+1).'l/' :
          \ context.cursor_line_highlight.' /\%'.line('.').'l/')
  endif

  if context.auto_preview
    call s:do_auto_preview()
  endif
endfunction"}}}
function! s:on_buf_unload(bufname)  "{{{
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
  if exists('&redrawtime')
    let &redrawtime = unite.redrawtime_save
  endif
  let &sidescrolloff = unite.sidescrolloff_save

  call s:restore_updatetime()

  if !unite.has_preview_window
    " Close preview window.
    pclose!
  endif

  call unite#clear_previewed_buffer_list()

  if winnr('$') != 1
    execute unite.win_rest_cmd
  endif

  " Call finalize functions.
  call s:call_hook(unite#loaded_sources_list(), 'on_close')
  let unite.is_finalized = 1
endfunction"}}}
function! s:change_highlight()  "{{{
  if &filetype !=# 'unite'
        \ || !exists('b:current_syntax')
    return
  endif

  let unite = unite#get_current_unite()
  let context = unite#get_context()
  let prompt_linenr = unite.prompt_linenr
  if !context.no_cursor_line
    execute 'match' (line('.') <= prompt_linenr ?
          \ line('$') <= prompt_linenr ?
          \ 'uniteError /\%'.prompt_linenr.'l/' :
          \ context.cursor_line_highlight.' /\%'.(prompt_linenr+1).'l/' :
          \ context.cursor_line_highlight.' /\%'.line('.').'l/')
  endif

  syntax clear uniteCandidateInputKeyword

  if unite#get_input() == ''
    return
  endif

  syntax case ignore

  for input in s:get_substitute_input(unite#get_input())
    for pattern in map(split(input, '\\\@<! '),
          \ "substitute(escape(unite#escape_match(v:val), '/'),
          \   '\\\\\\@<!|', '\\\\|', 'g')")
      execute 'syntax match uniteCandidateInputKeyword' '/'.pattern.'/'
            \ 'containedin=uniteCandidateAbbr contained'
      for source in filter(copy(unite.sources), 'v:val.syntax != ""')
        execute 'syntax match uniteCandidateInputKeyword' '/'.pattern.'/'
              \ 'containedin='.source.syntax.' contained'
      endfor
    endfor
  endfor

  syntax case match
endfunction"}}}
function! s:save_updatetime()  "{{{
  let unite = unite#get_current_unite()

  let unite.update_time_save = &updatetime
  if &updatetime > unite.context.update_time
    let &updatetime = unite.context.update_time
  endif
endfunction"}}}
function! s:restore_updatetime()  "{{{
  let unite = unite#get_current_unite()

  if !has_key(unite, 'update_time_save')
    return
  endif

  if &updatetime < unite.update_time_save
    let &updatetime = unite.update_time_save
  endif
endfunction"}}}

" Internal helper functions."{{{
function! s:adjustments(currentwinwidth, the_max_source_name, size)"{{{
  let max_width = a:currentwinwidth - a:the_max_source_name - a:size
  if max_width < 20
    return [a:currentwinwidth - a:size, 0]
  else
    return [max_width, a:the_max_source_name]
  endif
endfunction"}}}
function! s:extend_actions(self_func, action_table1, action_table2, ...)"{{{
  let filterd_table = s:filter_self_func(a:action_table2, a:self_func)

  if a:0 > 0
    for action in values(filterd_table)
      let action.from = a:1
    endfor
  endif

  return extend(a:action_table1, filterd_table, 'keep')
endfunction"}}}
function! s:filter_alias_action(action_table, alias_table, from)"{{{
  for [alias_name, alias_action] in items(a:alias_table)
    if alias_action ==# 'nop'
      if has_key(a:action_table, alias_name)
        " Delete nop action.
        call remove(a:action_table, alias_name)
      endif
    elseif has_key(a:action_table, alias_action)
      let a:action_table[alias_name] = copy(a:action_table[alias_action])
      let a:action_table[alias_name].from = a:from
      let a:action_table[alias_name].name = alias_name
    endif
  endfor
endfunction"}}}
function! s:filter_self_func(action_table, self_func)"{{{
  return filter(copy(a:action_table), printf("string(v:val.func) !=# \"function('%s')\"", a:self_func))
endfunction"}}}
function! s:take_action(action_name, candidate, is_parent_action)"{{{
  let candidate_head = type(a:candidate) == type([]) ?
        \ a:candidate[0] : a:candidate

  let action_table = unite#get_action_table(
        \ candidate_head.source, candidate_head.kind,
        \ unite#get_self_functions()[-3], a:is_parent_action)

  let action_name =
        \ a:action_name ==# 'default' ?
        \ unite#get_default_action(candidate_head.source, candidate_head.kind)
        \ : a:action_name

  if !has_key(action_table, a:action_name)
    " throw 'no such action ' . a:action_name
    return 1
  endif

  let action = action_table[a:action_name]
  " Convert candidates.
  call action.func(
        \ (action.is_selectable && type(a:candidate) != type([])) ?
        \ [a:candidate] : a:candidate)
endfunction"}}}
function! s:get_loaded_sources(...)"{{{
  if empty(s:static)
    " Initialize load.
    call s:load_default_scripts()
  endif

  let unite = unite#get_current_unite()
  return a:0 == 0 ? unite.sources :
        \ get(filter(copy(unite.sources), 'v:val.name ==# a:1'), 0, {})
endfunction"}}}
function! s:get_substitute_input(input)"{{{
  let input = a:input

  let unite = unite#get_current_unite()
  let substitute_patterns = reverse(unite#util#sort_by(
        \ values(unite#get_profile(unite.profile_name,
        \        'substitute_patterns')),
        \ 'v:val.priority'))
  if unite.input != '' && stridx(input, unite.input) == 0
    " Substitute after input.
    let input_save = input
    let input = input_save[len(unite.input) :]
    let head = input_save[: len(unite.input)-1]
  else
    " Substitute all input.
    let head = ''
  endif

  let inputs = s:get_substitute_input_loop(input, substitute_patterns)

  return map(inputs, 'head . v:val')
endfunction"}}}
function! s:get_substitute_input_loop(input, substitute_patterns)"{{{
  if empty(a:substitute_patterns)
    return [a:input]
  endif

  let inputs = [a:input]
  for pattern in a:substitute_patterns
    let cnt = 0
    for input in inputs
      if input =~ pattern.pattern
        if type(pattern.subst) == type([])
          if len(inputs) == 1
            " List substitute.
            let inputs = []
            for subst in pattern.subst
              call add(inputs,
                    \ substitute(input, pattern.pattern, subst, 'g'))
            endfor
          endif
        else
          let inputs[cnt] = substitute(
                \ input, pattern.pattern, pattern.subst, 'g')
        endif
      endif

      let cnt += 1
    endfor
  endfor

  return inputs
endfunction"}}}
function! s:call_hook(sources, hook_name)"{{{
  let _ = []
  for source in a:sources
    if !has_key(source.hooks, a:hook_name)
      continue
    endif

    try
      call call(source.hooks[a:hook_name],
            \ [source.args, source.unite__context], source.hooks)
    catch
      call unite#print_error(v:throwpoint)
      call unite#print_error(v:exception)
      call unite#print_error('[unite.vim] Error occured in calling hook "' . a:hook_name . '"!')
      call unite#print_error('[unite.vim] Source name is ' . source.name)
    endtry
  endfor
endfunction"}}}
function! s:has_preview_window()"{{{
  return len(filter(range(1, winnr('$')),
          \    'getwinvar(v:val, "&previewwindow")')) > 0
endfunction"}}}
function! s:do_auto_preview()"{{{
  let unite = unite#get_current_unite()
  if !unite.has_preview_window
        \ && s:has_preview_window()
    pclose!
  endif

  if unite.preview_candidate == unite#get_current_candidate()
    return
  endif

  let unite.preview_candidate = unite#get_current_candidate()

  call unite#mappings#do_action('preview', [], {}, 0)

  " Restore window size.
  let context = unite#get_context()
  if s:has_preview_window()
    call unite#_resize_window()
  endif
endfunction"}}}
function! s:init_cursor()"{{{
  let unite = unite#get_current_unite()

  if unite.context.start_insert
    let unite.is_insert = 1

    execute unite.prompt_linenr
    normal! zb

    startinsert!
  else
    let positions = unite#get_profile(
          \ unite.profile_name, 'unite__save_pos')
    let key = unite#loaded_source_names_string()
    let is_restore = has_key(positions, key)
    let candidate = unite#get_current_candidate()

    if is_restore
      " Restore position.
      call setpos('.', positions[key].pos)
    endif

    let unite.is_insert = 0

    if !is_restore
          \ || candidate != unite#get_current_candidate()
      execute (unite.prompt_linenr+1)
    endif
    normal! 0zb

    stopinsert
  endif

  if unite.context.quick_match
    call unite#mappings#_quick_match(0)
  endif
endfunction"}}}
function! s:get_postfix(prefix, is_create)"{{{
  let postfix = '@1'
  let cnt = 1

  if a:is_create
    let tabnr = 1
    while tabnr <= tabpagenr('$')
      let buflist = map(tabpagebuflist(tabnr), 'bufname(v:val)')
      if index(buflist, a:prefix.postfix) >= 0
        let cnt += 1
        let postfix = '@' . cnt
      endif

      let tabnr += 1
    endwhile
  else
    let buflist = map(tabpagebuflist(tabpagenr()), 'bufname(v:val)')
    for bufname in buflist
      if stridx(bufname, a:prefix) >= 0
        return matchstr(bufname, '@\d\+$')
      endif
    endfor
  endif

  return postfix
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
