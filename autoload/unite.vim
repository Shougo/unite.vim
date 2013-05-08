"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 May 2013.
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

augroup unite
  autocmd CursorHold
        \ call unite#_on_cursor_hold()
augroup END

function! unite#version() "{{{
  return str2nr(printf('%02d%02d', 5, 0))
endfunction"}}}

" User functions. "{{{
function! unite#get_substitute_pattern(profile_name) "{{{
  let profile_name = (a:profile_name == '' ? 'default' : a:profile_name)

  return has_key(s:profiles, profile_name) ?
        \ s:profiles[profile_name].substitute_patterns : ''
endfunction"}}}
function! unite#set_substitute_pattern(buffer_name, pattern, subst, ...) "{{{
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
function! unite#set_buffer_name_option(buffer_name, option_name, value) "{{{
  return unite#set_profile(a:buffer_name, a:option_name, a:value)
endfunction"}}}
function! unite#get_buffer_name_option(buffer_name, option_name) "{{{
  return unite#get_profile(a:buffer_name, a:option_name)
endfunction"}}}
function! s:initialize_profile(profile_name) "{{{
  if !has_key(s:profiles, a:profile_name)
    let s:profiles[a:profile_name] = {}
  endif

  let default_profile = {
        \ 'substitute_patterns' : {},
        \ 'filters' : [],
        \ 'context' : {},
        \ 'ignorecase' : &ignorecase,
        \ 'smartcase' : &smartcase,
        \ 'unite__save_pos' : {},
        \ 'unite__inputs' : {},
        \ }

  let s:profiles[a:profile_name] = extend(default_profile,
        \ s:profiles[a:profile_name])
endfunction"}}}
function! unite#set_profile(profile_name, option_name, value) "{{{
  let profile_name =
        \ (a:profile_name == '' ? 'default' : a:profile_name)

  for key in split(profile_name, '\s*,\s*')
    if !has_key(s:profiles, key)
      call s:initialize_profile(key)
    endif

    let s:profiles[key][a:option_name] = a:value
  endfor
endfunction"}}}
function! unite#get_profile(profile_name, option_name) "{{{
  let profile_name = matchstr(a:profile_name, '^\S\+')
  if profile_name == ''
    let profile_name = 'default'
  endif

  if !has_key(s:profiles, profile_name)
    call s:initialize_profile(profile_name)
  endif

  return s:profiles[profile_name][a:option_name]
endfunction"}}}
function! unite#custom_filters(source_name, expr) "{{{
  return unite#custom_source(a:source_name, 'filters', a:expr)
endfunction"}}}
function! unite#custom_alias(kind, name, action) "{{{
  for key in split(a:kind, '\s*,\s*')
    if !has_key(s:custom.aliases, key)
      let s:custom.aliases[key] = {}
    endif

    let s:custom.aliases[key][a:name] = a:action
  endfor
endfunction"}}}
function! unite#custom_default_action(kind, default_action) "{{{
  call unite#util#set_dictionary_helper(s:custom.default_actions,
        \ a:kind, a:default_action)
endfunction"}}}
function! unite#custom_action(kind, name, action) "{{{
  for key in split(a:kind, '\s*,\s*')
    if !has_key(s:custom.actions, key)
      let s:custom.actions[key] = {}
    endif
    let s:custom.actions[key][a:name] = a:action
  endfor
endfunction"}}}
function! unite#undef_custom_action(kind, name) "{{{
  for key in split(a:kind, '\s*,\s*')
    if has_key(s:custom.actions, key)
      call remove(s:custom.actions, key)
    endif
  endfor
endfunction"}}}
function! unite#custom_max_candidates(source_name, max) "{{{
  return unite#custom_source(a:source_name,
        \ 'max_candidates', a:max)
endfunction"}}}
function! unite#custom_source(source_name, option_name, value) "{{{
  for key in split(a:source_name, '\s*,\s*')
    if !has_key(s:custom.source, key)
      let s:custom.source[key] = {}
    endif

    let s:custom.source[key][a:option_name] = a:value
  endfor
endfunction"}}}

function! unite#define_source(source) "{{{
  for source in unite#util#convert2list(a:source)
    let s:dynamic.sources[source.name] = source
  endfor
endfunction"}}}
function! unite#define_kind(kind) "{{{
  for kind in unite#util#convert2list(a:kind)
    let s:dynamic.kinds[kind.name] = kind
  endfor
endfunction"}}}
function! unite#define_filter(filter) "{{{
  for filter in unite#util#convert2list(a:filter)
    let s:dynamic.filters[filter.name] = filter
  endfor
endfunction"}}}
function! unite#undef_source(name) "{{{
  if has_key(s:dynamic.sources, a:name)
    call remove(s:dynamic.sources, a:name)
  endif
endfunction"}}}
function! unite#undef_kind(name) "{{{
  if has_key(s:dynamic.kinds, a:name)
    call remove(s:dynamic.kinds, a:name)
  endif
endfunction"}}}
function! unite#undef_filter(name) "{{{
  if has_key(s:dynamic.filters, a:name)
    call remove(s:dynamic.filters, a:name)
  endif
endfunction"}}}

function! unite#do_action(action) "{{{
  return printf("%s:\<C-u>call unite#mappings#do_action(%s)\<CR>",
        \             (mode() ==# 'i' ? "\<C-o>" : ''), string(a:action))
endfunction"}}}
function! unite#smart_map(narrow_map, select_map) "{{{
  return (line('.') <= unite#get_current_unite().prompt_linenr
        \ && empty(unite#get_marked_candidates())) ?
        \   a:narrow_map : a:select_map
endfunction"}}}
function! unite#start_complete(sources, ...) "{{{
  let sources = type(a:sources) == type('') ?
        \ [a:sources] : a:sources
  let context = {
        \ 'col' : col('.'), 'complete' : 1,
        \ 'direction' : 'rightbelow',
        \ 'buffer_name' : 'completion',
        \ 'here' : 1,
        \ }
  call extend(context, get(a:000, 0, {}))

  return printf("\<ESC>:call unite#start(%s, %s)\<CR>",
        \  string(sources), string(context))
endfunction "}}}
function! unite#get_cur_text() "{{{
  let cur_text =
        \ (mode() ==# 'i' ? (col('.')-1) : col('.')) >= len(getline('.')) ?
        \      getline('.') :
        \      matchstr(getline('.'),
        \         '^.*\%' . col('.') . 'c' . (mode() ==# 'i' ? '' : '.'))

  return cur_text
endfunction "}}}

function! unite#take_action(action_name, candidate) "{{{
  call s:take_action(a:action_name, a:candidate, 0)
endfunction"}}}
function! unite#take_parents_action(action_name, candidate, extend_candidate) "{{{
  call s:take_action(a:action_name, extend(deepcopy(a:candidate), a:extend_candidate), 1)
endfunction"}}}

function! unite#do_candidates_action(action_name, candidates, ...) "{{{
  let context = get(a:000, 0, {})
  let context = s:initialize_context(context)
  let context.unite__is_interactive = 0
  let context.unite__disable_hooks = 1
  call unite#set_context(context)

  return unite#mappings#do_action(
        \ a:action_name, a:candidates, context)
endfunction"}}}
function! unite#get_unite_winnr(buffer_name) "{{{
  for winnr in filter(range(1, winnr('$')),
        \ "getbufvar(winbufnr(v:val), '&filetype') ==# 'unite'")
    let buffer_context = get(getbufvar(
          \ winbufnr(winnr), 'unite'), 'context', {})
    if !empty(buffer_context) &&
          \ buffer_context.buffer_name ==# a:buffer_name
      if buffer_context.temporary
            \ && !empty(filter(copy(buffer_context.old_buffer_info),
            \ 'v:val.buffer_name ==# buffer_context.buffer_name'))
        " Disable resume.
        let buffer_context.old_buffer_info = []
      endif
      return winnr
    endif
  endfor

  return -1
endfunction"}}}
function! unite#get_unite_bufnr(buffer_name) "{{{
  for bufnr in filter(range(1, bufnr('$')),
        \ "getbufvar(v:val, '&filetype') ==# 'unite'")
    let buffer_context = get(getbufvar(bufnr, 'unite'), 'context', {})
    if !empty(buffer_context) &&
          \ buffer_context.buffer_name ==# a:buffer_name
      if buffer_context.temporary
            \ && !empty(filter(copy(buffer_context.old_buffer_info),
            \ 'v:val.buffer_name ==# buffer_context.buffer_name'))
        " Disable resume.
        let buffer_context.old_buffer_info = []
      endif

      return bufnr
    endif
  endfor

  return -1
endfunction"}}}
"}}}

" Constants "{{{
let s:FALSE = 0
let s:TRUE = !s:FALSE
"}}}

" Variables  "{{{
" buffer number of the unite buffer
let s:current_unite = {}
let s:use_current_unite = 1

let s:static = {}
let s:static.sources = {}
let s:static.kinds = {}
let s:static.filters = {}

let s:loaded_defaults = {}

let s:dynamic = {}
let s:dynamic.sources = {}
let s:dynamic.kinds = {}
let s:dynamic.filters = {}

let s:custom = {}
let s:custom.actions = {}
let s:custom.default_actions = {}
let s:custom.aliases = {}
let s:custom.source = {}

let s:profiles = {}
call unite#set_substitute_pattern('files', '^\~',
      \ substitute(substitute($HOME, '\\', '/', 'g'),
      \ ' ', '\\\\ ', 'g'), -100)
call unite#set_substitute_pattern('files', '\.\{2,}\ze[^/]',
      \ "\\=repeat('../', len(submatch(0))-1)", 10000)
call unite#set_substitute_pattern('files', '[^~.* ]\ze/', '\0*', 100)
call unite#set_substitute_pattern('files', '/\ze[^~.* ]', '/*', 100)
call unite#set_substitute_pattern('files', '\.', '*.', 1000)
call unite#set_profile('files', 'smartcase', 0)
call unite#set_profile('files', 'ignorecase', 1)

let s:unite_options = [
      \ '-buffer-name=', '-profile-name=', '-input=', '-prompt=',
      \ '-default-action=', '-start-insert','-no-start-insert', '-no-quit',
      \ '-winwidth=', '-winheight=',
      \ '-immediately', '-no-empty', '-auto-preview', '-auto-highlight', '-complete',
      \ '-vertical', '-horizontal', '-direction=', '-no-split',
      \ '-verbose', '-auto-resize', '-toggle', '-quick-match', '-create',
      \ '-cursor-line-highlight=', '-no-cursor-line',
      \ '-update-time=', '-hide-source-names', '-hide-status-line',
      \ '-max-multi-lines=', '-here', '-silent', '-keep-focus',
      \ '-auto-quit', '-no-focus',
      \ '-long-source-names', '-short-source-names',
      \ '-multi-line', '-resume', '-wrap', '-select=', '-log',
      \]
"}}}

" Core functions. "{{{
function! unite#get_kinds(...) "{{{
  if a:0 == 0
    call s:load_default_scripts('kinds', [])
  else
    call s:load_default_scripts('kinds', [a:1])
  endif

  let kinds = s:initialize_kinds()
  return (a:0 == 0) ? kinds : get(kinds, a:1, {})
endfunction"}}}
function! unite#get_sources(...) "{{{
  let unite = unite#get_current_unite()
  if !has_key(unite, 'sources')
    return {}
  endif

  if a:0 == 0
    return unite.sources
  endif

  return unite#util#get_name(unite.sources, a:1, {})
endfunction"}}}
function! unite#get_all_sources(...) "{{{
  if a:0 == 0
    return s:initialize_sources()
  endif

  let unite = unite#get_current_unite()

  let all_sources = s:initialize_sources([], a:1)
  let source = get(all_sources, a:1, {})

  return empty(source) ?
        \ get(filter(copy(get(unite, 'sources', [])),
        \ 'v:val.name ==# a:1'), 0, {}) : source
endfunction"}}}
function! unite#get_filters(...) "{{{
  if a:0 == 0
    call s:load_default_scripts('filters', [])
  else
    call s:load_default_scripts('filters', [a:1])
  endif

  let filters = s:initialize_filters()

  if a:0 == 0
    return filters
  endif

  return get(filters, a:1, {})
endfunction"}}}
"}}}

" Helper functions. "{{{
function! unite#is_win() "{{{
  return unite#util#is_windows()
endfunction"}}}
function! unite#loaded_source_names() "{{{
  return map(copy(unite#loaded_sources_list()), 'v:val.name')
endfunction"}}}
function! unite#loaded_source_names_string() "{{{
  return join(unite#loaded_source_names())
endfunction"}}}
function! unite#loaded_source_names_with_args() "{{{
  return map(copy(unite#loaded_sources_list()), "
        \ join(insert(filter(copy(v:val.args),
        \  'type(v:val) <= 1'), unite#_convert_source_name(v:val.name)), ':')
        \ . (v:val.unite__orig_len_candidates == 0 ? '' :
        \      v:val.unite__orig_len_candidates ==
        \            v:val.unite__len_candidates ?
        \            '(' .  v:val.unite__len_candidates . ')' :
        \      printf('(%s/%s)', v:val.unite__len_candidates,
        \      v:val.unite__orig_len_candidates))
        \ ")
endfunction"}}}
function! unite#loaded_sources_list() "{{{
  return s:get_loaded_sources()
endfunction"}}}
function! unite#get_vimfiler_source_names() "{{{
  return map(filter(values(s:initialize_sources()),
        \ 'has_key(v:val, "vimfiler_check_filetype")'), 'v:val.name')
endfunction"}}}
function! unite#get_unite_candidates() "{{{
  return unite#get_current_unite().current_candidates
endfunction"}}}
function! unite#get_current_candidate(...) "{{{
  let linenr = a:0 > 1? a:1 : line('.')
  let num = linenr <= unite#get_current_unite().prompt_linenr ?
        \ 0 : linenr - (unite#get_current_unite().prompt_linenr+1)

  return get(unite#get_unite_candidates(), num, {})
endfunction"}}}
function! unite#get_context() "{{{
  let unite = unite#get_current_unite()
  return has_key(unite, 'context') ?
        \ unite.context : s:initialize_context({})
endfunction"}}}
function! unite#set_context(context) "{{{
  let old_context = unite#get_context()

  if exists('b:unite') && !s:use_current_unite
    let b:unite.context = a:context
  else
    let s:current_unite.context = a:context
  endif

  return old_context
endfunction"}}}

function! unite#get_action_table(source_name, kind, self_func, ...) "{{{
  let is_parents_action = get(a:000, 0, 0)
  let source_table = get(a:000, 1, {})

  let action_table = {}
  for kind_name in unite#util#convert2list(a:kind)
    call extend(action_table,
          \ s:get_action_table(a:source_name,
          \                kind_name, a:self_func,
          \                is_parents_action, source_table))
  endfor

  return action_table
endfunction"}}}
function! s:get_action_table(source_name, kind_name, self_func, is_parents_action, source_table) "{{{
  let kind = unite#get_kinds(a:kind_name)
  let source = empty(a:source_table) ?
        \ unite#get_sources(a:source_name) :
        \ unite#util#get_name(a:source_table, a:source_name, {})
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
  for parent in source.parents
    let parent_kind = unite#get_kinds(parent)
    let action_table = s:extend_actions(a:self_func, action_table,
          \ parent_kind.action_table, parent)
  endfor
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

  " Initialize action.
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
    if !has_key(action, 'is_start')
      let action.is_start = 0
    endif
    if !has_key(action, 'is_selectable')
      let action.is_selectable = 0
    endif
    if !has_key(action, 'is_invalidate_cache')
      let action.is_invalidate_cache = 0
    endif
    if !has_key(action, 'is_listed')
      let action.is_listed =
            \ (action.name !~ '^unite__\|^vimfiler__')
    endif
  endfor

  " Filtering nop action.
  return filter(action_table, 'v:key !=# "nop"')
endfunction"}}}
function! unite#get_alias_table(source_name, kind, ...) "{{{
  let source_table = get(a:000, 0, {})
  let alias_table = {}
  for kind_name in unite#util#convert2list(a:kind)
    call extend(alias_table,
          \ s:get_alias_table(a:source_name, kind_name, source_table))
  endfor

  return alias_table
endfunction"}}}
function! s:get_alias_table(source_name, kind_name, source_table) "{{{
  let kind = unite#get_kinds(a:kind_name)
  let source = empty(a:source_table) ?
        \ unite#get_sources(a:source_name) :
        \ unite#util#get_name(a:source_table, a:source_name, {})
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
function! unite#get_default_action(source_name, kind) "{{{
  let kinds = unite#util#convert2list(a:kind)

  return s:get_default_action(a:source_name, kinds[-1])
endfunction"}}}
function! s:get_default_action(source_name, kind_name) "{{{
  let source = unite#get_all_sources(a:source_name)
  if empty(source)
    return ''
  endif

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
  let kind = unite#get_kinds(a:kind_name)
  return get(kind, 'default_action', '')
endfunction"}}}

function! unite#escape_match(str) "{{{
  return substitute(substitute(escape(a:str, '~\.^$[]'),
        \ '\*\@<!\*', '[^/]*', 'g'), '\*\*\+', '.*', 'g')
endfunction"}}}
function! unite#complete_source(arglead, cmdline, cursorpos) "{{{
  let ret = unite#parse_path(join(split(a:cmdline)[1:]))
  let source_name = ret[0]
  let source_args = ret[1:]

  let _ = []

  if a:arglead !~ ':'
    " Option names completion.
    let _ +=  copy(s:unite_options)

    " Source name completion.
    if mode() ==# 'c'
      let _ += keys(filter(s:initialize_sources([], a:arglead),
            \ 'v:val.is_listed'))
    endif
    if exists('*neobundle#get_unite_sources')
      let _ += neobundle#get_unite_sources()
    endif
  else
    " Add "{source-name}:".
    let _  = map(_, 'source_name.":".v:val')
  endif

  if source_name != '' && mode() ==# 'c'
    " Source args completion.
    let args = source_name . ':' . join(source_args[: -2], ':')
    if args !~ ':$'
      let args .= ':'
    endif
    let _ += map(unite#args_complete(
          \ [insert(copy(source_args), source_name)],
          \ join(source_args, ':'), a:cmdline, a:cursorpos),
          \ "args.escape(v:val, ':')")
  endif

  return sort(filter(_, 'stridx(v:val, a:arglead) == 0'))
endfunction"}}}
function! unite#complete_buffer_name(arglead, cmdline, cursorpos) "{{{
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
  call s:redraw(1, get(a:000, 0, 0), get(a:000, 1, 0))
endfunction"}}}
function! unite#redraw(...) "{{{
  call s:redraw(0, get(a:000, 0, 0), get(a:000, 1, 0))
endfunction"}}}
function! unite#redraw_line(...) "{{{
  let linenr = a:0 > 0 ? a:1 : line('.')
  if linenr <= unite#get_current_unite().prompt_linenr || &filetype !=# 'unite'
    " Ignore.
    return
  endif

  let modifiable_save = &l:modifiable
  setlocal modifiable

  let candidate = unite#get_unite_candidates()[linenr -
        \ (unite#get_current_unite().prompt_linenr+1)]
  call setline(linenr, unite#convert_lines([candidate])[0])

  let &l:modifiable = modifiable_save
endfunction"}}}
function! unite#quick_match_redraw(quick_match_table) "{{{
  let modifiable_save = &l:modifiable
  setlocal modifiable

  call setline(unite#get_current_unite().prompt_linenr+1,
        \ s:convert_quick_match_lines(
        \ unite#get_current_unite().current_candidates,
        \ a:quick_match_table))
  redraw

  let &l:modifiable = modifiable_save
endfunction"}}}
function! unite#get_status_string() "{{{
  return !exists('b:unite') ? '' : ((b:unite.is_async ? '[async] ' : '') .
        \ join(unite#loaded_source_names_with_args(), ', '))
endfunction"}}}
function! unite#redraw_candidates(...) "{{{
  let is_gather_all = get(a:000, 0, 0)

  call unite#_resize_window()

  let candidates = unite#gather_candidates(is_gather_all)

  let modifiable_save = &l:modifiable
  setlocal modifiable

  let lines = unite#convert_lines(candidates)
  let pos = getpos('.')
  let unite = unite#get_current_unite()
  if len(lines) < len(unite.current_candidates)
    silent! execute (unite.prompt_linenr+1).',$delete _'
  endif
  call setline(unite.prompt_linenr+1, lines)

  let &l:modifiable = l:modifiable_save

  let unite = unite#get_current_unite()
  let context = unite.context
  let unite.current_candidates = candidates

  if pos != getpos('.')
    call setpos('.', pos)
  endif

  if context.input == '' && context.log
    " Move to bottom.
    call cursor(line('$'), 0)
  endif

  " Set syntax.
  call s:set_syntax()
endfunction"}}}
function! unite#get_marked_candidates() "{{{
  return unite#util#sort_by(filter(copy(unite#get_unite_candidates()),
        \ 'v:val.unite__is_marked'), 'v:val.unite__marked_time')
endfunction"}}}
function! unite#get_input() "{{{
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
function! unite#get_options() "{{{
  return s:unite_options
endfunction"}}}
function! unite#get_self_functions() "{{{
  return split(matchstr(expand('<sfile>'), '^function \zs.*$'), '\.\.')[: -2]
endfunction"}}}
function! unite#gather_candidates(...) "{{{
  let is_gather_all = get(a:000, 0, 0)

  let unite = unite#get_current_unite()
  let unite.candidates = []
  for source in unite#loaded_sources_list()
    let unite.candidates += source.unite__candidates
  endfor

  if is_gather_all
    let unite.candidates_pos = len(unite.candidates)
  elseif unite.context.is_redraw || unite.candidates_pos == 0
    let height = unite.context.no_split ?
          \ winheight(0) : unite.context.winheight
    let unite.candidates_pos = height
  endif

  let candidates = s:initialize_candidates(
        \ unite.candidates[: unite.candidates_pos-1])

  " Post filter.
  for filter_name in unite.post_filters
    let candidates = unite#call_filter(
          \ filter_name, candidates, unite.context)
  endfor

  return candidates
endfunction"}}}
function! unite#gather_candidates_pos(offset) "{{{
  let unite = unite#get_current_unite()
  if unite.context.is_redraw || unite.candidates_pos == 0
    return []
  endif

  let unite = unite#get_current_unite()
  let candidates = unite.candidates[unite.candidates_pos :
        \ unite.candidates_pos + a:offset - 1]

  " Post filter.
  for filter_name in unite.post_filters
    let candidates = unite#call_filter(
          \ filter_name, candidates, unite.context)
  endfor

  let unite.candidates_pos += len(candidates)

  return s:initialize_candidates(candidates)
endfunction"}}}
function! unite#get_current_unite() "{{{
  return exists('b:unite') && !s:use_current_unite ?
        \ b:unite : s:current_unite
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
function! unite#parse_path(path) "{{{
  let source_name = matchstr(a:path, '^[^:]*\ze:')
  let source_arg = a:path[len(source_name)+1 :]

  let source_args = source_arg  == '' ? [] :
        \  map(split(source_arg, '\\\@<!:', 1),
        \      'substitute(v:val, ''\\\(.\)'', "\\1", "g")')

  return insert(source_args, source_name)
endfunction"}}}
function! unite#call_filter(filter_name, candidates, context) "{{{
  let filter = unite#get_filters(a:filter_name)
  if empty(filter)
    return a:candidates
  endif

  return filter.filter(a:candidates, a:context)
endfunction"}}}
function! unite#get_source_variables(context) "{{{
  return a:context.source.variables
endfunction"}}}

" Utils.
function! unite#print_error(message) "{{{
  let message = unite#util#msg2list(a:message)
  let unite = unite#get_current_unite()
  if !empty(unite)
    let unite.err_msgs += message
  endif
  for mes in message
    echohl WarningMsg | echomsg mes | echohl None
  endfor
endfunction"}}}
function! unite#print_source_error(message, source_name) "{{{
  call unite#print_error(map(copy(unite#util#msg2list(a:message)),
        \ "printf('[%s] %s', a:source_name, v:val)"))
endfunction"}}}
function! unite#print_message(message) "{{{
  let context = unite#get_context()
  if get(context, 'silent', 0)
    return
  endif

  let unite = unite#get_current_unite()
  let message = unite#util#msg2list(a:message)
  if !empty(unite)
    let unite.msgs += message
  endif
  echohl Comment | call unite#util#redraw_echo(message) | echohl None
endfunction"}}}
function! unite#print_source_message(message, source_name) "{{{
  call unite#print_message(map(copy(unite#util#msg2list(a:message)),
        \ "printf('[%s] %s', a:source_name, v:val)"))
endfunction"}}}
function! unite#clear_message() "{{{
  let unite = unite#get_current_unite()
  let unite.msgs = []
  redraw
endfunction"}}}
function! unite#substitute_path_separator(path) "{{{
  return unite#util#substitute_path_separator(a:path)
endfunction"}}}
function! unite#path2directory(path) "{{{
  return unite#util#path2directory(a:path)
endfunction"}}}
"}}}

" Command functions.
function! unite#start(sources, ...) "{{{
  if empty(a:sources)
    call unite#print_error('[unite.vim] Source names is required.')
    return
  endif

  " Check command line window.
  if unite#util#is_cmdwin()
    call unite#print_error(
          \ '[unite.vim] Command line buffer is detected! '.
          \ 'Please close command line buffer.')
    return
  endif

  let context = get(a:000, 0, {})
  let context = s:initialize_context(context,
        \ s:get_source_names(a:sources))

  if context.resume
    " Check resume buffer.
    let resume_bufnr = s:get_resume_buffer(context.buffer_name)
    if resume_bufnr > 0 &&
          \ getbufvar(resume_bufnr, 'unite').source_names ==#
          \    s:get_source_names(a:sources)
      return unite#resume(context.buffer_name, context)
    endif
  endif

  let s:use_current_unite = 1

  if context.toggle "{{{
    if unite#close(context.buffer_name)
      return
    endif
  endif"}}}

  try
    call s:initialize_current_unite(a:sources, context)
  catch /^unite.vim: Invalid source/
    call unite#print_error('[unite.vim] ' . v:exception)
    return
  endtry

  " Caching.
  let s:current_unite.last_input = context.input
  let s:current_unite.input = context.input
  call s:recache_candidates(context.input, context.is_redraw)

  if !s:current_unite.is_async &&
        \ (context.immediately || context.no_empty) "{{{
    let candidates = unite#gather_candidates()

    if empty(candidates)
      " Ignore.
      let s:use_current_unite = 0
      return
    elseif context.immediately && len(candidates) == 1
      " Immediately action.
      call unite#mappings#do_action(
            \ context.default_action, [candidates[0]])
      let s:use_current_unite = 0
      return
    endif
  endif"}}}

  call s:initialize_unite_buffer()
  call s:on_bufwin_enter(bufnr('%'))

  let s:use_current_unite = 0

  let unite = unite#get_current_unite()

  setlocal modifiable

  " Redraw prompt.
  silent % delete _
  call setline(unite.prompt_linenr,
        \ unite.prompt . unite.context.input)

  call unite#redraw_candidates()

  call s:init_cursor()

endfunction"}}}
function! unite#start_script(sources, ...) "{{{
  " Start unite from script.

  let context = get(a:000, 0, {})

  let context.script = 1

  " Set buffer-name.
  if !has_key(context, 'buffer_name')
    let context.buffer_name =
          \ type(get(a:sources, 0, [])) == type([]) ?
          \ join(map(copy(a:sources), 'v:val[0]')) :
          \ join(a:sources)
  endif

  return get(unite#get_context(), 'temporary', 0) ?
        \ unite#start_temporary(a:sources, context) :
        \ unite#start(a:sources, context)
endfunction"}}}
function! unite#start_temporary(sources, ...) "{{{
  " Get current context.
  let old_context = unite#get_context()
  let unite = unite#get_current_unite()

  if !empty(unite) && !empty(old_context)
    let context = deepcopy(old_context)
    let context.old_buffer_info = insert(context.old_buffer_info, {
          \ 'buffer_name' : unite.buffer_name,
          \ 'pos' : getpos('.'),
          \ 'profile_name' : unite.profile_name,
          \ })
  else
    let context = {}
    let context = s:initialize_context(context,
          \ s:get_source_names(a:sources))
    let context.old_buffer_info = []
  endif

  let new_context = get(a:000, 0, {})

  " Overwrite context.
  let context = extend(context, new_context)

  let context.temporary = 1
  let context.unite__direct_switch = 1
  let context.input = ''
  let context.auto_preview = 0
  let context.auto_highlight = 0
  let context.unite__is_vimfiler = 0
  let context.default_action = 'default'
  let context.unite__old_winwidth = 0
  let context.unite__old_winheight = 0
  let context.is_resize = 0

  let buffer_name = get(a:000, 1,
        \ matchstr(context.buffer_name, '^\S\+')
        \ . ' - ' . len(context.old_buffer_info))

  let context.buffer_name = buffer_name

  let unite_save = unite#get_current_unite()

  let cwd = getcwd()

  call unite#start(a:sources, context)

  " Overwrite unite.
  let unite = unite#get_current_unite()
  let unite.prev_bufnr = unite_save.prev_bufnr
  let unite.prev_winnr = unite_save.prev_winnr
  if has_key(unite, 'update_time_save')
    let unite.update_time_save = unite_save.update_time_save
  endif
  let unite.winnr = unite_save.winnr

  " Restore current directory.
  execute 'lcd' fnameescape(cwd)
endfunction"}}}
function! unite#vimfiler_check_filetype(sources, ...) "{{{
  let context = get(a:000, 0, {})
  let context = s:initialize_context(context,
        \ s:get_source_names(a:sources))
  let context.unite__is_vimfiler = 1
  let context.unite__is_interactive = 0

  try
    call s:initialize_current_unite(a:sources, context)
  catch /^unite.vim: Invalid source/
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
      call unite#initialize_candidates_source([info[1]], source.name)
      call s:initialize_vimfiler_candidates([info[1]], source.name)
    elseif type ==# 'directory'
      " nop
    elseif type ==# 'error'
      call unite#print_error('[unite.vim] ' . info)
      return []
    else
      call unite#print_error('[unite.vim] Invalid filetype : ' . type)
    endif

    return [type, info]
  endfor

  " Not found.
  return []
endfunction"}}}
function! unite#get_candidates(sources, ...) "{{{
  let unite_save = unite#get_current_unite()

  try
    let context = get(a:000, 0, {})
    let context = s:initialize_context(context,
          \ s:get_source_names(a:sources))
    let context.no_buffer = 1
    let context.unite__is_interactive = 0

    " Finalize.
    let candidates = s:get_candidates(a:sources, context)

    " Call finalize functions.
    call s:call_hook(unite#loaded_sources_list(), 'on_close')
    let unite = unite#get_current_unite()
    let unite.is_finalized = 1
  finally
    call unite#set_current_unite(unite_save)
  endtry

  return candidates
endfunction"}}}
function! unite#get_vimfiler_candidates(sources, ...) "{{{
  let unite_save = unite#get_current_unite()

  try
    let context = get(a:000, 0, {})
    let context = s:initialize_context(context,
          \ s:get_source_names(a:sources))
    let context.no_buffer = 1
    let context.unite__is_vimfiler = 1
    let context.unite__is_interactive = 0

    let candidates = s:get_candidates(a:sources, context)
  finally
    call unite#set_current_unite(unite_save)
  endtry

  return candidates
endfunction"}}}
function! unite#vimfiler_complete(sources, arglead, cmdline, cursorpos) "{{{
  let context = {}
  let context = s:initialize_context(context,
        \ s:get_source_names(a:sources))
  let context.unite__is_interactive = 0
  let context.unite__is_complete = 1

  try
    call s:initialize_current_unite(a:sources, context)
  catch /^unite.vim: Invalid source/
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
function! unite#args_complete(sources, arglead, cmdline, cursorpos) "{{{
  let context = {}
  let context = s:initialize_context(context,
        \ s:get_source_names(a:sources))
  let context.unite__is_interactive = 0
  let context.unite__is_complete = 1

  try
    call s:initialize_current_unite(a:sources, context)
  catch /^unite.vim: Invalid source/
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
function! unite#resume(buffer_name, ...) "{{{
  " Check command line window.
  if unite#util#is_cmdwin()
    call unite#print_error(
          \ '[unite.vim] Command line buffer is detected! '.
          \ 'Please close command line buffer.')
    return
  endif

  if a:buffer_name == ''
    " Use last unite buffer.
    if !exists('t:unite') ||
          \ !bufexists(t:unite.last_unite_bufnr)
      call unite#util#print_error('No unite buffer.')
      return
    endif

    let bufnr = t:unite.last_unite_bufnr
  else
    let bufnr = s:get_resume_buffer(a:buffer_name)
  endif

  if bufnr < 0
    return
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

  call s:switch_unite_buffer(context.buffer_name, context)

  " Set parameters.
  let unite = unite#get_current_unite()
  let unite.winnr = winnr
  if !context.unite__direct_switch
    let unite.win_rest_cmd = win_rest_cmd
  endif
  let unite.redrawtime_save = &redrawtime
  let unite.access_time = localtime()
  let unite.context = context
  let unite.is_finalized = 0

  call unite#set_current_unite(unite)

  call s:init_cursor()
endfunction"}}}
function! s:get_candidates(sources, context) "{{{
  try
    call s:initialize_current_unite(a:sources, a:context)
  catch /^unite.vim: Invalid source/
    return []
  endtry

  " Caching.
  let s:current_unite.last_input = a:context.input
  let s:current_unite.input = a:context.input
  call s:recache_candidates(a:context.input, a:context.is_redraw)

  let candidates = []
  for source in unite#loaded_sources_list()
    if !empty(source.unite__candidates)
      let candidates += a:context.unite__is_vimfiler ?
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
    let buffer_name .= s:get_postfix(
          \ prefix, 0, tabpagebuflist(tabpagenr()))
  endif

  " Search unite window.
  let quit_winnr = unite#get_unite_winnr(a:buffer_name)

  if quit_winnr > 0
    " Quit unite buffer.
    silent execute quit_winnr 'wincmd w'
    call unite#force_quit_session()
  endif

  return quit_winnr > 0
endfunction"}}}

function! unite#all_quit_session(...)  "{{{
  call s:quit_session(get(a:000, 0, 1), 1)
endfunction"}}}
function! unite#force_quit_session()  "{{{
  call s:quit_session(1)

  let context = unite#get_context()
  if context.temporary && !empty(context.old_buffer_info)
      call unite#resume_from_temporary(context)
  endif
endfunction"}}}
function! unite#quit_session()  "{{{
  call s:quit_session(0)

  let context = unite#get_context()
  if context.temporary && !empty(context.old_buffer_info)
    call unite#resume_from_temporary(context)
  endif
endfunction"}}}
function! s:quit_session(is_force, ...)  "{{{
  if &filetype !=# 'unite'
    return
  endif

  let is_all = get(a:000, 0, 0)

  " Save unite value.
  let unite_save = s:current_unite
  call unite#set_current_unite(b:unite)
  let unite = b:unite
  let context = unite.context

  let key = unite#loaded_source_names_string()

  " Clear mark.
  for source in unite#loaded_sources_list()
    for candidate in source.unite__cached_candidates
      let candidate.unite__is_marked = 0
    endfor
  endfor

  " Save position.
  let positions = unite#get_profile(
        \ unite.profile_name, 'unite__save_pos')
  if key != ''
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
  endif

  if a:is_force || !context.no_quit
    let bufname = bufname('%')

    if winnr('$') == 1 || context.no_split
      call unite#util#alternate_buffer()
    elseif is_all || !context.temporary
      noautocmd close!
      if unite.winnr == winnr()
        doautocmd WinEnter
      else
        execute unite.winnr . 'wincmd w'
      endif
      call unite#_resize_window()
    endif

    call s:on_buf_unload(bufname)

    if !unite.has_preview_window
      let preview_windows = filter(range(1, winnr('$')),
            \ 'getwinvar(v:val, "&previewwindow") != 0')
      if !empty(preview_windows)
        " Close preview window.
        pclose!

      endif
    endif

    call unite#clear_previewed_buffer_list()

    if winnr('$') != 1 && !unite.context.temporary
      execute unite.win_rest_cmd
      execute unite.prev_winnr 'wincmd w'
    endif
  else
    " Note: Except preview window.
    let winnr = get(filter(range(1, winnr('$')),
          \ "winbufnr(v:val) == unite.prev_bufnr &&
          \  !getwinvar(v:val, '&previewwindow')"), 0, unite.prev_winnr)

    if winnr == winnr()
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

    " Skip next auto completion.
    if exists('*neocomplcache#skip_next_complete')
      call neocomplcache#skip_next_complete()
    endif
  else
    redraw
    stopinsert
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
  call unite#resume(buffer_info.buffer_name,
        \ {'unite__direct_switch' : 1})
  call setpos('.', buffer_info.pos)
  let a:context.old_buffer_info = a:context.old_buffer_info[1:]

  " Overwrite unite.
  let unite = unite#get_current_unite()
  let unite.prev_bufnr = unite_save.prev_bufnr
  let unite.prev_winnr = unite_save.prev_winnr

  call unite#redraw()
endfunction"}}}

function! s:load_default_scripts(kind, names) "{{{
  let names = empty(a:names) ? [''] : a:names
  if a:kind ==# 'sources' && !empty(a:names)
    call add(names, 'alias')

    if !exists('*neobundle#autoload#unite_sources')
      " Dummy call.
      try
        call neobundle#autoload#unite_sources([])
      catch /E117.*/
      endtry
    endif

    if exists('*neobundle#autoload#unite_sources')
      call neobundle#autoload#unite_sources(a:names)
    endif
  endif

  if get(s:loaded_defaults, a:kind, '') ==# &runtimepath
    return
  endif

  for name in names
    if name != '' && has_key(s:static[a:kind], name)
          \ || (a:kind ==# 'sources' && name ==# 'alias' &&
          \     get(s:loaded_defaults, 'alias', 0))
      continue
    endif

    if name == ''
      let s:loaded_defaults[a:kind] = &runtimepath
    elseif a:kind ==# 'sources' && name ==# 'alias'
      let s:loaded_defaults['alias'] = &runtimepath
    endif

    " Search files by prefix or postfix.
    let prefix_name = (a:kind ==# 'filters') ?
          \ substitute(name,
          \'^\%(matcher\|sorter\|converter\)_[^/_-]\+\zs[/_-].*$', '', '') :
          \ substitute(name, '^[^/_-]\+\zs[/_-].*$', '', '')
    let postfix_name = matchstr(name, '[^/_-]\+$')

    let files = []
    for name in ((postfix_name != '' &&
          \ prefix_name !=# postfix_name) ?
          \ [prefix_name, postfix_name] : [prefix_name])
      let files += split(globpath(&runtimepath,
            \ 'autoload/unite/'.a:kind.'/'.name.'*.vim', 1), '\n')
    endfor

    for define in map(files,
          \ "unite#{a:kind}#{fnamemodify(v:val, ':t:r')}#define()")
      for dict in filter(unite#util#convert2list(define),
            \ '!empty(v:val) && !has_key(s:static[a:kind], v:val.name)')
        let s:static[a:kind][dict.name] = dict
      endfor
      unlet define
    endfor
  endfor
endfunction"}}}
function! s:initialize_context(context, ...) "{{{
  let default_context = {
        \ 'input' : '',
        \ 'start_insert' : g:unite_enable_start_insert,
        \ 'complete' : 0,
        \ 'script' : 0,
        \ 'col' : col('.'),
        \ 'no_quit' : 0,
        \ 'buffer_name' : 'default',
        \ 'profile_name' : '',
        \ 'prompt' : g:unite_prompt,
        \ 'default_action' : 'default',
        \ 'winwidth' : g:unite_winwidth,
        \ 'winheight' : g:unite_winheight,
        \ 'immediately' : 0,
        \ 'no_empty' : 0,
        \ 'auto_preview' : 0,
        \ 'auto_highlight' : 0,
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
        \ 'cursor_line_highlight' :
        \    g:unite_cursor_line_highlight,
        \ 'no_cursor_line' : 0,
        \ 'update_time' : g:unite_update_time,
        \ 'no_buffer' : 0,
        \ 'hide_source_names' : 0,
        \ 'max_multi_lines' : 5,
        \ 'here' : 0,
        \ 'silent' : 0,
        \ 'keep_focus' : 0,
        \ 'auto_quit' : 0,
        \ 'is_redraw' : 0,
        \ 'is_resize' : 0,
        \ 'no_focus' : 0,
        \ 'multi_line' : 0,
        \ 'resume' : 0,
        \ 'wrap' : 0,
        \ 'select' : 0,
        \ 'log' : 0,
        \ 'unite__direct_switch' : 0,
        \ 'unite__is_interactive' : 1,
        \ 'unite__is_complete' : 0,
        \ 'unite__is_vimfiler' : 0,
        \ 'unite__old_winwidth' : 0,
        \ 'unite__old_winheight' : 0,
        \ 'unite__disable_hooks' : 0,
        \ }

  let source_names = get(a:000, 0, [])

  let profile_name = get(a:context, 'profile_name',
        \ ((len(source_names) == 1 && !has_key(a:context, 'buffer_name')) ?
        \    'source/' . source_names[0] :
        \    get(a:context, 'buffer_name', 'default')))

  " Overwrite default_context by profile context.
  let default_context = extend(default_context,
        \ unite#get_profile(profile_name, 'context'))

  let context = extend(default_context, a:context)

  if context.temporary || context.script
    " User can overwrite context by profile context.
    let context = extend(context,
          \ unite#get_profile(profile_name, 'context'))
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
  let context.is_changed = 0

  return context
endfunction"}}}
function! s:initialize_loaded_sources(sources, context) "{{{
  let all_sources = s:initialize_sources(
        \ s:get_source_names(a:sources))
  let sources = []

  let number = 0
  for [source, args] in s:get_source_args(a:sources)
    if type(source) == type('')
      let source_name = source
      unlet source
      if !has_key(all_sources, source_name)
        if a:context.unite__is_vimfiler || a:context.unite__is_complete
          " Ignore error.
          continue
        endif

        call unite#util#print_error(
              \ 'unite.vim: Invalid source name "' .
              \ source_name . '" is detected.')
        throw 'unite.vim: Invalid source'
      endif

      let source = deepcopy(all_sources[source_name])
    else
      " Use source dictionary.
      call s:initialize_sources(source)
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
function! s:initialize_sources(...) "{{{
  " args: source_names or source_definition

  " Initialize load.
  if type(get(a:000, 0, [])) != type({})
    let source_names = type(get(a:000, 0, [])) == type([]) ?
          \ get(a:000, 0, []) : []
    let head_name = get(a:000, 1, '')
    if empty(source_names) && head_name != ''
      let source_names = [head_name]
    endif
    call s:load_default_scripts('sources', source_names)
  endif

  let default_source = {
        \ 'is_volatile' : 0,
        \ 'is_listed' : 1,
        \ 'is_forced' : 0,
        \ 'required_pattern_length' : 0,
        \ 'action_table' : {},
        \ 'default_action' : {},
        \ 'default_kind' : 'common',
        \ 'alias_table' : {},
        \ 'parents' : [],
        \ 'description' : '',
        \ 'syntax' : '',
        \ }

  let sources = {}
  let sources = extend(sources, s:static.sources)
  let sources = extend(sources, s:dynamic.sources)
  if type(get(a:000, 0, [])) == type({})
    let sources[a:1.name] = a:1
  endif

  for source in type(sources) == type([]) ?
        \ sources : values(sources)
    try
      if !get(source, 'is_initialized', 0)
        let source.is_initialized = 1

        if !has_key(source, 'hooks')
          let source.hooks = {}
        elseif has_key(source.hooks, 'on_pre_init')
          " Call pre_init hook.

          " Set dummey value.
          let source.args = []
          let source.unite__context = { 'source' : source }

          " Overwrite source values.
          call s:call_hook([source], 'on_pre_init')
        endif

        let source = extend(source, default_source, 'keep')

        if !empty(source.action_table)
          let action = values(source.action_table)[0]

          " Check if '*' action_table?
          if has_key(action, 'func')
                \ && type(action.func) == type(function('type'))
            " Syntax sugar.
            let source.action_table = { '*' : source.action_table }
          endif
        endif

        if type(source.default_action) == type('')
          " Syntax sugar.
          let source.default_action = { '*' : source.default_action }
        endif

        if !empty(source.alias_table)
          " Check if '*' alias_table?
          if type(values(source.alias_table)[0]) == type('')
            " Syntax sugar.
            let source.alias_table = { '*' : source.alias_table }
          endif
        endif
        if source.is_volatile
              \ && !has_key(source, 'change_candidates')
          let source.change_candidates = source.gather_candidates
          call remove(source, 'gather_candidates')
        endif
      endif

      " For custom sources.
      let custom_source = get(s:custom.source, source.name, {})

      " Set filters.
      if has_key(custom_source, 'filters')
        let source.filters = custom_source.filters
      elseif !has_key(source, 'filters')
            \ || has_key(custom_source, 'matchers')
            \ || has_key(custom_source, 'sorters')
            \ || has_key(custom_source, 'converters')
        let matchers = unite#util#convert2list(
              \ get(custom_source, 'matchers',
              \   get(source, 'matchers', 'matcher_default')))
        let sorters = unite#util#convert2list(
              \ get(custom_source, 'sorters',
              \   get(source, 'sorters', 'sorter_default')))
        let converters = unite#util#convert2list(
              \ get(custom_source, 'converters',
              \   get(source, 'converters', 'converter_default')))
        let source.filters = matchers + sorters + converters
      endif

      let source.max_candidates =
            \ get(custom_source, 'max_candidates',
            \    get(source, 'max_candidates', 0))
      let source.ignore_pattern =
            \ get(custom_source, 'ignore_pattern',
            \    get(source, 'ignore_pattern', ''))
      let source.variables =
            \ extend(get(custom_source, 'variables', {}),
            \    get(source, 'variables', {}), 'keep')

      let source.unite__len_candidates = 0
      let source.unite__orig_len_candidates = 0
      let source.unite__candidates = []
    catch
      call unite#print_error(v:throwpoint)
      call unite#print_error(v:exception)
      call unite#print_error(
            \ '[unite.vim] Error occured in source initialization!')
      call unite#print_error(
            \ '[unite.vim] Source name is ' . source.name)
    endtry
  endfor

  return sources
endfunction"}}}
function! s:initialize_kinds() "{{{
  let kinds = extend(copy(s:static.kinds), s:dynamic.kinds)
  for kind in values(filter(copy(kinds),
        \ '!has_key(v:val, "is_initialized")'))
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
function! s:initialize_filters() "{{{
  return extend(copy(s:static.filters), s:dynamic.filters)
endfunction"}}}
function! unite#initialize_candidates_source(candidates, source_name) "{{{
  let source = s:get_loaded_sources(a:source_name)

  let default_candidate = {
        \ 'kind' : source.default_kind,
        \ 'is_dummy' : 0,
        \ 'is_matched' : 1,
        \ 'is_multiline' : 0,
        \ 'unite__is_marked' : 0,
        \ }

  let candidates = []
  for candidate in a:candidates
    let candidate = extend(candidate, default_candidate, 'keep')
    let candidate.source = a:source_name

    call add(candidates, candidate)
  endfor

  return candidates
endfunction"}}}
function! s:initialize_candidates(candidates) "{{{
  let unite = unite#get_current_unite()
  let context = unite.context
  let [max_width, max_source_name] =
        \ s:adjustments(winwidth(0)-5, unite.max_source_name, 2)
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
function! s:initialize_vimfiler_candidates(candidates, source_name) "{{{
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
    if !has_key(candidate, 'vimfiler__is_writable')
      let candidate.vimfiler__is_writable = 1
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
    let candidate.unite__abbr = candidate.vimfiler__abbr
  endfor

  return a:candidates
endfunction"}}}
function! s:initialize_tab_variable()  "{{{
  let t:unite = { 'last_unite_bufnr' : -1 }
endfunction"}}}

function! s:recache_candidates(input, is_force) "{{{
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
          \ && !context.unite__is_interactive
          \ && len(source.unite__candidates) > source.max_candidates
      " Filtering too many candidates.
      let source.unite__candidates =
            \ source.unite__candidates[: source.max_candidates - 1]

      if context.verbose && filtered_count < &cmdheight
        echohl WarningMsg | echomsg printf(
              \ '[%s] Filtering too many candidates.', source.name)
              \ | echohl None
        let filtered_count += 1
      endif
    endif

    " Call post_filter hook.
    let source.unite__context.candidates =
          \ source.unite__candidates
    call s:call_hook([source], 'on_post_filter')

    let source.unite__candidates =
          \ unite#initialize_candidates_source(
          \   source.unite__context.candidates, source.name)
  endfor

  " Update async state.
  let unite.is_async =
        \ len(filter(copy(unite.sources),
        \           'v:val.unite__context.is_async')) > 0

  let &ignorecase = ignorecase_save
endfunction"}}}
function! s:recache_candidates_loop(context, is_force) "{{{
  let unite = unite#get_current_unite()

  let input_len = unite#util#strchars(a:context.input)

  let candidate_sources = []
  let unite.max_source_candidates = 0
  for source in unite#loaded_sources_list()
    " Check required pattern length.
    if input_len < source.required_pattern_length
      continue
    endif

    " Set context.
    let context = source.unite__context
    let context.input = a:context.input

    if source.required_pattern_length > 0
          \ && !source.is_forced
      " Forced redraw.
      let context.is_redraw = 1
      let source.is_forced = 1
    else
      let context.is_redraw = a:context.is_redraw
    endif
    let context.is_changed = a:context.is_changed
    let context.is_invalidate = source.unite__is_invalidate
    let context.is_list_input = a:context.is_list_input
    let context.input_list = split(context.input, '\\\@<! ')
    let context.unite__max_candidates = source.max_candidates

    let source_candidates = s:get_source_candidates(source)

    let custom_source = get(s:custom.source, source.name, {})
    if source.ignore_pattern != '' && !context.unite__is_vimfiler
      call filter(source_candidates,
            \ "get(v:val, 'action__path', v:val.word)
            \             !~# source.ignore_pattern")
    endif

    " Call pre_filter hook.
    let context.candidates = source_candidates
    call s:call_hook([source], 'on_pre_filter')

    " Set filters.
    let matchers = []
    let sorters = []
    let prev_filters = []
    let post_filters = []
    for Filter in get(custom_source, 'filters', source.filters)
      if type(Filter) != type('')
        call add((empty(matchers) ?
              \ prev_filters : post_filters), Filter)

        unlet Filter
        continue
      endif

      let name = get(unite#get_filters(Filter),
            \              'name', '')
      if name =~# '\%(^\|_\)matcher_'
        call add(matchers, Filter)
      elseif name =~# '\%(^\|_\)sorter_'
        if name ==# 'sorter_default'
          let sorters += unite#filters#sorter_default#get()
        else
          call add(sorters, Filter)
        endif
      else
        call add((empty(matchers) ?
              \ prev_filters : post_filters), Filter)
      endif
      unlet Filter
    endfor

    if sorters ==# ['sorter_nothing']
      let sorters = []
    endif

    let context.unite__is_sort_nothing =
          \ empty(sorters) && context.unite__is_interactive
    let source.unite__orig_len_candidates = len(source_candidates)
    let unite.max_source_candidates +=
          \ (context.unite__is_sort_nothing
          \    && source.max_candidates > 0) ?
          \ source.max_candidates : source.unite__orig_len_candidates

    " Call filters.
    for Filter in prev_filters + matchers + sorters + post_filters
      if type(Filter) == type('')
        let source_candidates = unite#call_filter(
              \ Filter, source_candidates, context)
      else
        let source_candidates = call(Filter,
              \ [source_candidates, context], source)
      endif

      unlet Filter
    endfor

    let source.unite__candidates += source_candidates
    let source.unite__len_candidates = len(source_candidates)
    if !empty(source_candidates)
      call add(candidate_sources,
            \ unite#_convert_source_name(source.name))
    endif
  endfor

  if !a:context.hide_source_names
        \ && len(unite#loaded_sources_list()) > 1
    let unite.max_source_name =
          \ max(map(candidate_sources, 'len(v:val)')) + 1
  endif
endfunction"}}}
function! s:get_source_candidates(source) "{{{
  let context = a:source.unite__context

  let funcname = 's:get_source_candidates()'
  try
    if context.unite__is_vimfiler
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

        if context.unite__is_interactive
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
            \ a:source.change_candidates(
            \     a:source.args, a:source.unite__context)
    endif
  catch
    call unite#print_error(v:throwpoint)
    call unite#print_error(v:exception)
    call unite#print_error(
          \ '[unite.vim] Error occured in ' . funcname . '!')
    call unite#print_error(
          \ '[unite.vim] Source name is ' . a:source.name)

    return []
  endtry

  return a:source.unite__cached_candidates
        \ + a:source.unite__cached_change_candidates
endfunction"}}}
function! s:convert_quick_match_lines(candidates, quick_match_table) "{{{
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
          \    unite#util#truncate(unite#_convert_source_name(
          \    candidate.source), max_source_name))
          \ . unite#util#truncate_wrap(candidate.unite__abbr,
          \      max_width, max_width/2, '..'))
    let num += 1
  endfor

  return candidates
endfunction"}}}
function! unite#convert_lines(candidates) "{{{
  let unite = unite#get_current_unite()
  let [max_width, max_source_name] =
        \ s:adjustments(winwidth(0)-1, unite.max_source_name, 2)
  if unite.max_source_name == 0
    let max_width -= 1
  endif

  return map(copy(a:candidates),
        \ "(v:val.unite__is_marked ? g:unite_marked_icon . ' ' : '- ')
        \ . (unite.max_source_name == 0 ? ''
        \   : unite#util#truncate(unite#_convert_source_name(
        \     v:val.source), max_source_name))
        \ . unite#util#truncate_wrap(v:val.unite__abbr, " . max_width
        \    .  ", max_width/2, '..')")
endfunction"}}}

function! s:initialize_current_unite(sources, context) "{{{
  let context = a:context

  " Quit previous unite buffer.
  if !context.create && !context.temporary
        \ && context.unite__is_interactive
    let winnr = unite#get_unite_winnr(context.buffer_name)
    if winnr > 0 && s:get_source_args(a:sources) !=#
          \ getbufvar(winbufnr(winnr), 'unite').args
      " Quit unite buffer.
      execute winnr 'wincmd w'

      if context.input == ''
        " Get input text.
        let context.input = unite#get_input()
      endif

      " Get winwidth.
      let context.winwidth = winwidth(0)

      " Get winheight.
      let context.winheight = winheight(0)

      call unite#force_quit_session()
    endif
  endif

  " The current buffer is initialized.
  let buffer_name = unite#util#is_windows() ?
        \ '[unite] - ' : '*unite* - '
  let buffer_name .= context.buffer_name

  let winnr = winnr()
  let win_rest_cmd = winrestcmd()

  " Check sources.
  let sources = s:initialize_loaded_sources(a:sources, a:context)

  " Set parameters.
  let unite = {}
  let unite.winnr = winnr
  let unite.win_rest_cmd = (!context.unite__direct_switch) ?
        \ win_rest_cmd : ''
  let unite.context = context
  let unite.current_candidates = []
  let unite.sources = sources
  let unite.source_names = s:get_source_names(sources)
  let unite.buffer_name = (context.buffer_name == '') ?
        \ 'default' : context.buffer_name
  let unite.profile_name =
        \ (context.profile_name != '') ? context.profile_name :
        \ (len(sources) == 1) ? 'source/' . sources[0].name :
        \ unite.buffer_name
  let unite.prev_bufnr = bufnr('%')
  let unite.prev_winnr = winnr()
  let unite.update_time_save = &updatetime
  let unite.statusline = '*unite* : %{unite#get_status_string()}'
          \ . "\ %=%{printf(' %5d/%d',line('.'),
          \       b:unite.max_source_candidates+b:unite.prompt_linenr)}"

  " Create new buffer name.
  let postfix = s:get_postfix(
        \ buffer_name, unite.context.create)
  let unite.buffer_name .= postfix

  let unite.real_buffer_name = buffer_name . postfix
  let unite.prompt = context.prompt
  let unite.input = context.input
  let unite.last_input = context.input
  let unite.sidescrolloff_save = &sidescrolloff
  let unite.prompt_linenr = 1
  let unite.is_async =
        \ len(filter(copy(sources),
        \  'v:val.unite__context.is_async')) > 0
  let unite.access_time = localtime()
  let unite.is_finalized = 0
  let unite.previewd_buffer_list = []
  let unite.post_filters = unite#get_profile(
        \ unite.profile_name, 'filters')
  let unite.preview_candidate = {}
  let unite.highlight_candidate = {}
  let unite.max_source_name = 0
  let unite.candidates_pos = 0
  let unite.candidates = []
  let unite.max_source_candidates = 0
  let unite.is_multi_line = 0
  let unite.args = s:get_source_args(a:sources)
  let unite.msgs = []
  let unite.err_msgs = []

  if context.here
    let context.winheight = winheight(0) - winline() +
          \ unite.prompt_linenr + 1
    if context.winheight < 7
      let context.winheight = 7
    endif
  endif

  " Preview windows check.
  let unite.has_preview_window =
        \ len(filter(range(1, winnr('$')),
        \  'getwinvar(v:val, "&previewwindow")')) > 0

  " Help windows check.

  call unite#set_current_unite(unite)

  call unite#set_context(context)

  if !context.unite__is_complete
    call s:call_hook(sources, 'on_init')
  endif
endfunction"}}}
function! s:initialize_unite_buffer() "{{{
  let is_bufexists = bufexists(s:current_unite.real_buffer_name)
  let s:current_unite.context.real_buffer_name =
        \ s:current_unite.real_buffer_name

  call s:switch_unite_buffer(
        \ s:current_unite.buffer_name, s:current_unite.context)

  let b:unite = s:current_unite
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
            \ call s:on_insert_enter()
      autocmd InsertLeave <buffer>
            \ call s:on_insert_leave()
      autocmd CursorHoldI <buffer>
            \ call s:on_cursor_hold_i()
      autocmd CursorMovedI <buffer>
            \ call s:on_cursor_moved_i()
      autocmd CursorMoved,CursorMovedI <buffer>  nested
            \ call s:on_cursor_moved()
      autocmd BufUnload,BufHidden <buffer>
            \ call s:on_buf_unload(expand('<afile>'))
      autocmd WinEnter,BufWinEnter <buffer>
            \ call s:on_bufwin_enter(bufnr(expand('<abuf>')))
      autocmd WinLeave,BufWinLeave <buffer>
            \ call s:restore_updatetime()
    augroup END

    call unite#mappings#define_default_mappings()
  endif

  let &l:wrap = unite.context.wrap

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
endfunction"}}}
function! s:switch_unite_buffer(buffer_name, context) "{{{
  " Search unite window.
  let winnr = unite#get_unite_winnr(a:buffer_name)
  if !a:context.no_split && winnr > 0
    silent execute winnr 'wincmd w'
    return
  endif

  " Search unite buffer.
  let bufnr = unite#get_unite_bufnr(a:buffer_name)

  if !a:context.no_split && !a:context.unite__direct_switch
    " Split window.
    execute a:context.direction ((bufnr > 0) ?
          \ ((a:context.vertical) ? 'vsplit' : 'split') :
          \ ((a:context.vertical) ? 'vnew' : 'new'))
  endif

  if bufnr > 0
    silent execute bufnr 'buffer'
  else
    silent! edit `=a:context.real_buffer_name`
  endif

  call s:on_bufwin_enter(bufnr('%'))
endfunction"}}}

function! s:redraw(is_force, winnr, is_gather_all) "{{{
  if unite#util#is_cmdwin()
    return
  endif

  if a:winnr > 0
    " Set current unite.
    let unite = getbufvar(winbufnr(a:winnr), 'unite')
    let unite_save = s:current_unite
    let winnr_save = winnr()

    execute a:winnr 'wincmd w'

    let line_save = unite.prompt_linenr
  endif

  try
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
          \ && !context.is_resize
          \ && !a:is_gather_all
      return
    endif

    let is_gather_all = a:is_gather_all || context.log

    if context.is_redraw
          \ || input !=# unite.last_input
          \ || unite.is_async
      " Recaching.
      call s:recache_candidates(input, a:is_force)
    endif

    let unite.last_input = input

    " Redraw.
    call unite#redraw_candidates(is_gather_all)
    let unite.context.is_redraw = 0
  finally
    if a:winnr > 0
      if unite.prompt_linenr != line_save
        " Updated.
        normal! G
      endif

      " Restore current unite.
      let s:current_unite = unite_save
      execute winnr_save 'wincmd w'
      " call unite#_resize_window()
    endif
  endtry

  if context.auto_preview
    call s:do_auto_preview()
  endif
  if context.auto_highlight
    call s:do_auto_highlight()
  endif
endfunction"}}}
function! unite#_resize_window() "{{{
  if &filetype !=# 'unite' || winnr('$') == 1
    return
  endif

  let context = unite#get_context()
  let unite = unite#get_current_unite()

  if context.no_split
    let context.is_resize = 0
    return
  endif

  if context.unite__old_winwidth != 0
        \ && context.unite__old_winheight != 0
        \ && winheight(0) != context.unite__old_winheight
        \ && winwidth(0) != context.unite__old_winwidth
    " Disabled auto resize.
    let context.winwidth = 0
    let context.winheight = 0
    let context.is_resize = 1
    return
  endif

  if context.auto_resize
    " Auto resize.
    let max_len = unite.prompt_linenr + len(unite.current_candidates)
    execute 'resize' min([max_len, context.winheight])
    if line('.') < winheight(0)
      normal! zb
    endif
    if mode() ==# 'i' && col('.') == (col('$') - 1)
      startinsert!
    endif

    let context.is_resize = 1
  elseif context.vertical
        \ && context.unite__old_winwidth  == 0
        " \ && winwidth(winnr()) != context.winwidth
        " \ && (context.unite__old_winwidth  == 0 ||
        " \     winheight(winnr()) == context.unite__old_winheight)
    execute 'vertical resize' context.winwidth

    let context.is_resize = 1
  elseif !context.vertical
        \ && context.unite__old_winheight  == 0
        " \ && winheight(winnr()) != context.winheight
        " \ && (context.unite__old_winheight == 0 ||
        " \     winwidth(winnr()) == context.unite__old_winwidth)
    execute 'resize' context.winheight

    let context.is_resize = 1
  else
    let context.is_resize = 0
  endif

  let context.unite__old_winheight = winheight(winnr())
  let context.unite__old_winwidth = winwidth(winnr())
endfunction"}}}

" Autocmd events.
function! s:on_insert_enter()  "{{{
  let unite = unite#get_current_unite()
  let unite.is_insert = 1

  if exists(':NeoComplCacheLock')
    " Lock neocomplcache.
    NeoComplCacheLock
  endif

  if &filetype ==# 'unite'
    setlocal modifiable
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

  if unite.max_source_candidates > 4000
    call s:check_redraw()
  endif

  if unite.is_async && &l:modifiable
    " Ignore key sequences.
    call feedkeys("a\<BS>", 'n')
    " call feedkeys("\<C-r>\<ESC>", 'n')
  endif
endfunction"}}}
function! s:on_cursor_moved_i()  "{{{
  let unite = unite#get_current_unite()
  let prompt_linenr = unite.prompt_linenr

  if unite.max_source_candidates <= 4000
    call s:check_redraw()
  endif

  " Prompt check.
  if line('.') == prompt_linenr && col('.') <= len(unite.prompt)
    startinsert!
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
function! s:on_bufwin_enter(bufnr)  "{{{
  let unite = getbufvar(a:bufnr, 'unite')
  if type(unite) != type({})
        \ || bufwinnr(a:bufnr) < 1
    return
  endif

  if bufwinnr(a:bufnr) != winnr()
    let winnr = winnr()
    execute bufwinnr(a:bufnr) 'wincmd w'
  endif

  call s:save_updatetime()

  call s:restore_statusline()

  if !unite.context.no_split && winnr('$') != 1
    call unite#_resize_window()
  endif

  setlocal nomodified

  if exists('winnr')
    execute winnr.'wincmd w'
  endif

  if !exists('t:unite')
    call s:initialize_tab_variable()
  endif
  let t:unite.last_unite_bufnr = a:bufnr
endfunction"}}}
function! unite#_on_cursor_hold()  "{{{
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
function! s:on_cursor_moved()  "{{{
  if &filetype !=# 'unite'
    return
  endif

  let unite = unite#get_current_unite()
  let prompt_linenr = unite.prompt_linenr
  let context = unite.context

  setlocal nocursorline

  execute 'setlocal' line('.') == prompt_linenr ?
        \ 'modifiable' : 'nomodifiable'
  if line('.') <= prompt_linenr
    nnoremap <silent><buffer> <Plug>(unite_loop_cursor_up)
          \ <ESC>:call unite#mappings#loop_cursor_up_call(
          \    0, 'n')<CR>
    nnoremap <silent><buffer> <Plug>(unite_skip_cursor_up)
          \ <ESC>:call unite#mappings#loop_cursor_up_call(
          \    1, 'n')<CR>
    inoremap <silent><buffer> <Plug>(unite_select_previous_line)
          \ <ESC>:call unite#mappings#loop_cursor_up_call(
          \    0, 'i')<CR>
    inoremap <silent><buffer> <Plug>(unite_skip_previous_line)
          \ <ESC>:call unite#mappings#loop_cursor_up_call(
          \    1, 'i')<CR>
  else
    if winline() <= winheight('$') / 2
      normal! zz
    endif

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
    silent! execute 'match' (line('.') <= prompt_linenr ?
          \ line('$') <= prompt_linenr ?
          \ 'uniteError /\%'.prompt_linenr.'l/' :
          \ context.cursor_line_highlight.' /\%'.(prompt_linenr+1).'l/' :
          \ context.cursor_line_highlight.' /\%'.line('.').'l/')
  endif

  if context.auto_preview
    call s:do_auto_preview()
  endif
  if context.auto_highlight
    call s:do_auto_highlight()
  endif

  call s:restore_statusline()

  " Check lines. "{{{
  if winheight(0) < line('$') &&
        \ line('.') + winheight(0) / 2 < line('$')
    return
  endif

  let height =
        \ (unite.context.no_split
        \  || unite.context.winheight == 0) ?
        \ winheight(0) : unite.context.winheight
  let candidates = unite#gather_candidates_pos(height)
  if empty(candidates)
    " Nothing.
    return
  endif

  call unite#_resize_window()

  let modifiable_save = &l:modifiable
  try
    setlocal modifiable
    let lines = unite#convert_lines(candidates)
    let pos = getpos('.')
    call append('$', lines)
  finally
    let &l:modifiable = l:modifiable_save
  endtry

  let context = unite.context
  let unite.current_candidates += candidates

  if pos != getpos('.')
    call setpos('.', pos)
  endif"}}}
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
  if empty(unite)
    return
  endif

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

  if &updatetime > unite.context.update_time
    let unite.update_time_save = &updatetime
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

" Internal helper functions. "{{{
function! s:adjustments(currentwinwidth, the_max_source_name, size) "{{{
  let max_width = a:currentwinwidth - a:the_max_source_name - a:size
  if max_width < 20
    return [a:currentwinwidth - a:size, 0]
  else
    return [max_width, a:the_max_source_name]
  endif
endfunction"}}}
function! s:extend_actions(self_func, action_table1, action_table2, ...) "{{{
  let filterd_table = s:filter_self_func(a:action_table2, a:self_func)

  if a:0 > 0
    for action in values(filterd_table)
      let action.from = a:1
    endfor
  endif

  return extend(a:action_table1, filterd_table, 'keep')
endfunction"}}}
function! s:filter_alias_action(action_table, alias_table, from) "{{{
  for [alias_name, alias_action] in items(a:alias_table)
    if alias_action ==# 'nop'
      if has_key(a:action_table, alias_name)
        " Delete nop action.
        call remove(a:action_table, alias_name)
      endif
    elseif has_key(a:action_table, alias_action)
          \ && !has_key(a:action_table, alias_name)
      let a:action_table[alias_name] = copy(a:action_table[alias_action])
      let a:action_table[alias_name].from = a:from
      let a:action_table[alias_name].name = alias_name
    endif
  endfor
endfunction"}}}
function! s:filter_self_func(action_table, self_func) "{{{
  return filter(copy(a:action_table),
        \ printf("string(v:val.func) !=# \"function('%s')\"", a:self_func))
endfunction"}}}
function! s:take_action(action_name, candidate, is_parent_action) "{{{
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
    " throw 'unite.vim: no such action ' . a:action_name
    return 1
  endif

  let action = action_table[a:action_name]
  " Convert candidates.
  call action.func(
        \ (action.is_selectable && type(a:candidate) != type([])) ?
        \ [a:candidate] : a:candidate)
endfunction"}}}
function! s:get_loaded_sources(...) "{{{
  " Initialize load.
  let unite = unite#get_current_unite()
  return a:0 == 0 ? unite.sources :
        \ get(filter(copy(unite.sources), 'v:val.name ==# a:1'), 0, {})
endfunction"}}}
function! s:get_substitute_input(input) "{{{
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
function! s:get_substitute_input_loop(input, substitute_patterns) "{{{
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
function! s:call_hook(sources, hook_name) "{{{
  let context = unite#get_context()
  if context.unite__disable_hooks
    return
  endif

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
      call unite#print_error(
            \ '[unite.vim] Error occured in calling hook "' . a:hook_name . '"!')
      call unite#print_error(
            \ '[unite.vim] Source name is ' . source.name)
    endtry
  endfor
endfunction"}}}
function! s:has_preview_window() "{{{
  return len(filter(range(1, winnr('$')),
        \    'getwinvar(v:val, "&previewwindow")')) > 0
endfunction"}}}
function! s:do_auto_preview() "{{{
  let unite = unite#get_current_unite()

  if unite.preview_candidate == unite#get_current_candidate()
    return
  endif

  let unite.preview_candidate = unite#get_current_candidate()

  call unite#clear_previewed_buffer_list()
  call unite#mappings#do_action('preview', [], {})

  " Restore window size.
  let context = unite#get_context()
  if s:has_preview_window()
    call unite#_resize_window()
  endif
endfunction"}}}
function! s:do_auto_highlight() "{{{
  let unite = unite#get_current_unite()

  if unite.highlight_candidate == unite#get_current_candidate()
    return
  endif
  let unite.highlight_candidate = unite#get_current_candidate()

  call unite#mappings#do_action('highlight', [], {})
endfunction"}}}
function! s:init_cursor() "{{{
  let unite = unite#get_current_unite()
  let context = unite.context

  let positions = unite#get_profile(
        \ unite.profile_name, 'unite__save_pos')
  let key = unite#loaded_source_names_string()
  let is_restore = has_key(positions, key) &&
        \ context.select == 0

  if context.start_insert && !context.auto_quit
    let unite.is_insert = 1

    call cursor(unite.prompt_linenr, 0)
    if line('.') < winheight(0)
      normal! zb
    endif
    setlocal modifiable

    startinsert!
  else
    if is_restore
      " Restore position.
      call setpos('.', positions[key].pos)
    endif

    let candidate = unite#get_current_candidate()

    let unite.is_insert = 0

    if !is_restore
          \ || candidate != unite#get_current_candidate()
      call cursor(unite.prompt_linenr+1, 0)
    endif

    normal! 0
    if line('.') < winheight(0)
      normal! zb
    endif

    stopinsert
  endif

  if context.select != 0
    " Select specified candidate.
    call cursor(line('.') + context.select, 0)
  elseif context.input == '' && context.log
    call unite#redraw_candidates(1)
  endif

  if context.no_focus
    if winbufnr(winnr('#')) > 0
      wincmd p
    else
      execute bufwinnr(unite.prev_bufnr).'wincmd w'
    endif
  endif

  if context.quick_match
    call unite#mappings#_quick_match(0)
  endif
endfunction"}}}
function! s:get_postfix(prefix, is_create, ...) "{{{
  let buffers = get(a:000, 0, range(1, bufnr('$')))
  let buflist = sort(filter(map(buffers,
        \ 'bufname(v:val)'), 'stridx(v:val, a:prefix) >= 0'))
  if empty(buflist)
    return ''
  endif

  return a:is_create ? '@'.(matchstr(buflist[-1], '@\zs\d\+$') + 1)
        \ : matchstr(buflist[-1], '@\d\+$')
endfunction"}}}
function! unite#_convert_source_name(source_name) "{{{
  let context = unite#get_context()
  return !context.short_source_names ? a:source_name :
        \ a:source_name !~ '\A'  ? a:source_name[:1] :
        \ substitute(a:source_name, '\a\zs\a\+', '', 'g')
endfunction"}}}
function! unite#set_highlight() "{{{
  let unite = unite#get_current_unite()

  " Set highlight.
  let match_prompt = escape(unite.prompt, '\/*~.^$[]')
  syntax clear uniteInputPrompt
  execute 'syntax match uniteInputPrompt'
        \ '/^'.match_prompt.'/ contained'

  let marked_icon = unite#util#escape_pattern(g:unite_marked_icon)
  execute 'syntax region uniteMarkedLine start=/^'.
        \ marked_icon.'/ end=''$'' keepend'

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

  execute 'highlight default link uniteCandidateAbbr'
        \ g:unite_abbr_highlight

  " Set syntax.
  for source in filter(copy(unite.sources), 'v:val.syntax != ""')
    let name = unite.max_source_name > 0 ?
          \ unite#_convert_source_name(source.name) : ''

    execute 'highlight default link'
          \ source.syntax g:unite_abbr_highlight

    execute printf('syntax match %s "^- %s" '.
          \ 'nextgroup='.source.syntax.
          \ ' keepend contains=uniteCandidateMarker,%s',
          \ 'uniteSourceLine__'.source.syntax,
          \ (name == '' ? '' : name . '\>'),
          \ (name == '' ? '' : 'uniteCandidateSourceName')
          \ )

    call s:call_hook([source], 'on_syntax')
  endfor

  call s:set_syntax()
endfunction"}}}
function! s:set_syntax() "{{{
  let unite = unite#get_current_unite()
  let source_padding = 3

  let abbr_head = unite.max_source_name+source_padding
  syntax clear uniteCandidateAbbr
  execute 'syntax region uniteCandidateAbbr' 'start=/\%'
        \ .(abbr_head).'c/ end=/$/ keepend contained'

  " Set syntax.
  for source in filter(copy(unite.sources), 'v:val.syntax != ""')
    execute 'syntax clear' source.syntax
    execute 'syntax region' source.syntax
          \ 'start=// end=/$/ keepend contained'
  endfor
endfunction"}}}
function! s:get_resume_buffer(buffer_name) "{{{
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
        \ "getbufvar(v:val, '&filetype') ==# 'unite' &&
        \  type(getbufvar(v:val, 'unite')) == type({})"),
        \ "getbufvar(v:val, 'unite')")
    let buffer_dict[unite.buffer_name] = unite.bufnr
  endfor

  return get(buffer_dict, buffer_name, -1)
endfunction"}}}
function! s:get_source_names(sources) "{{{
  return map(map(copy(a:sources),
        \ "type(v:val) == type([]) ? v:val[0] : v:val"),
        \ "type(v:val) == type('') ? v:val : v:val.name")
endfunction"}}}
function! s:get_source_args(sources)
  return map(copy(a:sources),
        \ 'type(v:val) == type([]) ? [v:val[0], v:val[1:]] : [v:val, []]')
endfunction
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
