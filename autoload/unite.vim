"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
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

augroup plugin-unite
  autocmd CursorHold
        \ call unite#handlers#_on_cursor_hold()
augroup END

function! unite#version() "{{{
  return str2nr(printf('%02d%02d', 5, 1))
endfunction"}}}

" User functions. "{{{
function! unite#set_profile(profile_name, option_name, value) "{{{
  return unite#custom#profile(a:profile_name, a:option_name, a:value)
endfunction"}}}
function! unite#get_profile(profile_name, option_name) "{{{
  return unite#custom#get_profile(a:profile_name, a:option_name)
endfunction"}}}

function! unite#custom_filters(source_name, expr) "{{{
  return unite#custom#source(a:source_name, 'filters', a:expr)
endfunction"}}}
function! unite#custom_alias(kind, name, action) "{{{
  return unite#custom#alias(a:kind, a:name, a:action)
endfunction"}}}
function! unite#custom_default_action(kind, default_action) "{{{
  return unite#custom#default_action(a:kind, a:default_action)
endfunction"}}}
function! unite#custom_action(kind, name, action) "{{{
  return unite#custom#action(a:kind, a:name, a:action)
endfunction"}}}
function! unite#custom_max_candidates(source_name, max) "{{{
  return unite#custom#source(a:source_name,
        \ 'max_candidates', a:max)
endfunction"}}}
function! unite#custom_source(source_name, option_name, value) "{{{
  return unite#custom#source(
        \ a:source_name, a:option_name, a:value)
endfunction"}}}

function! unite#define_source(source) "{{{
  let dynamic = unite#variables#dynamic()
  for source in unite#util#convert2list(a:source)
    let dynamic.sources[source.name] = source
  endfor
endfunction"}}}
function! unite#define_kind(kind) "{{{
  let dynamic = unite#variables#dynamic()
  for kind in unite#util#convert2list(a:kind)
    let dynamic.kinds[kind.name] = kind
  endfor
endfunction"}}}
function! unite#define_filter(filter) "{{{
  let dynamic = unite#variables#dynamic()
  for filter in unite#util#convert2list(a:filter)
    let dynamic.filters[filter.name] = filter
  endfor
endfunction"}}}
function! unite#undef_source(name) "{{{
  let dynamic = unite#variables#dynamic()
  if has_key(dynamic.sources, a:name)
    call remove(dynamic.sources, a:name)
  endif
endfunction"}}}
function! unite#undef_kind(name) "{{{
  let dynamic = unite#variables#dynamic()
  if has_key(dynamic.kinds, a:name)
    call remove(dynamic.kinds, a:name)
  endif
endfunction"}}}
function! unite#undef_filter(name) "{{{
  let dynamic = unite#variables#dynamic()
  if has_key(dynamic.filters, a:name)
    call remove(dynamic.filters, a:name)
  endif
endfunction"}}}

function! unite#do_action(action) "{{{
  return printf("%s:\<C-u>call unite#mappings#do_action(%s)\<CR>",
        \             (mode() ==# 'i' ? "\<C-o>" : ''), string(a:action))
endfunction"}}}
function! unite#smart_map(narrow_map, select_map) "{{{
  return (line('.') <= unite#get_current_unite().prompt_linenr
        \ && empty(unite#helper#get_marked_candidates())) ?
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
  let context = unite#init#_context(context)
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

" Core functions. "{{{
function! unite#get_kinds(...) "{{{
  return call('unite#variables#kinds', a:000)
endfunction"}}}
function! unite#get_sources(...) "{{{
  return call('unite#variables#sources', a:000)
endfunction"}}}
function! unite#get_all_sources(...) "{{{
  return call('unite#variables#all_sources', a:000)
endfunction"}}}
function! unite#get_filters(...) "{{{
  return call('unite#variables#filters', a:000)
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
  return unite#variables#loaded_sources()
endfunction"}}}
function! unite#get_vimfiler_source_names() "{{{
  return map(filter(values(unite#init#_sources()),
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
function! unite#get_current_candidate_linenr(num) "{{{
  let num = 0

  let candidate_num = 0
  for candidate in unite#get_unite_candidates()
    if !candidate.is_dummy
      let candidate_num += 1
    endif

    let num += 1

    if candidate_num >= a:num+1
      break
    endif
  endfor

  return unite#get_current_unite().prompt_linenr + num
endfunction"}}}
function! unite#get_context() "{{{
  let unite = unite#get_current_unite()
  return has_key(unite, 'context') ?
        \ unite.context : unite#init#_context({})
endfunction"}}}
function! unite#set_context(context) "{{{
  let old_context = unite#get_context()

  if exists('b:unite') && !unite#variables#use_current_unite()
    let b:unite.context = a:context
  else
    let current_unite = unite#variables#current_unite()
    let current_unite.context = a:context
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

  let custom = unite#custom#get()

  if !a:is_parents_action
    " Source/kind custom actions.
    if has_key(custom.actions, source_kind)
      let action_table = s:extend_actions(a:self_func, action_table,
            \ custom.actions[source_kind], 'custom/'.source.name.'/'.kind.name)
    endif

    " Source/kind actions.
    if has_key(source.action_table, a:kind_name)
      let action_table = s:extend_actions(a:self_func, action_table,
            \ source.action_table[a:kind_name], source.name.'/'.kind.name)
    endif

    " Source/* custom actions.
    if has_key(custom.actions, source_kind_wild)
      let action_table = s:extend_actions(a:self_func, action_table,
            \ custom.actions[source_kind_wild], 'custom/source/'.source.name)
    endif

    " Source/* actions.
    if has_key(source.action_table, '*')
      let action_table = s:extend_actions(a:self_func, action_table,
            \ source.action_table['*'], 'source/'.source.name)
    endif

    " Kind custom actions.
    if has_key(custom.actions, a:kind_name)
      let action_table = s:extend_actions(a:self_func, action_table,
            \ custom.actions[a:kind_name], 'custom/'.kind.name)
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
    if has_key(custom.aliases, a:kind_name)
      call s:filter_alias_action(action_table, custom.aliases[a:kind_name],
            \ 'custom/'.kind.name)
    endif

    " Source/* aliases.
    if has_key(source.alias_table, '*')
      call s:filter_alias_action(action_table, source.alias_table['*'],
            \ 'source/'.source.name)
    endif

    " Source/* custom aliases.
    if has_key(custom.aliases, source_kind_wild)
      call s:filter_alias_action(action_table, custom.aliases[source_kind_wild],
            \ 'custom/source/'.source.name)
    endif

    " Source/kind aliases.
    if has_key(custom.aliases, source_kind)
      call s:filter_alias_action(action_table, custom.aliases[source_kind],
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

  let custom = unite#custom#get()

  " Kind custom aliases.
  if has_key(custom.aliases, a:kind_name)
    let table = extend(table, custom.aliases[a:kind_name])
  endif

  " Source/* aliases.
  if has_key(source.alias_table, '*')
    let table = extend(table, source.alias_table['*'])
  endif

  " Source/* custom aliases.
  if has_key(custom.aliases, source_kind_wild)
    let table = extend(table, custom.aliases[source_kind_wild])
  endif

  " Source/kind aliases.
  if has_key(custom.aliases, source_kind)
    let table = extend(table, custom.aliases[source_kind])
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

  let custom = unite#custom#get()

  " Source/kind custom default actions.
  if has_key(custom.default_actions, source_kind)
    return custom.default_actions[source_kind]
  endif

  " Source custom default actions.
  if has_key(source.default_action, a:kind_name)
    return source.default_action[a:kind_name]
  endif

  " Source/* custom default actions.
  if has_key(custom.default_actions, source_kind_wild)
    return custom.default_actions[source_kind_wild]
  endif

  " Source/* default actions.
  if has_key(source.default_action, '*')
    return source.default_action['*']
  endif

  " Kind custom default actions.
  if has_key(custom.default_actions, a:kind_name)
    return custom.default_actions[a:kind_name]
  endif

  " Kind default actions.
  let kind = unite#get_kinds(a:kind_name)
  return get(kind, 'default_action', '')
endfunction"}}}

function! unite#escape_match(str) "{{{
  return substitute(substitute(escape(a:str, '~\.^$[]'),
        \ '\*\@<!\*', '[^/]*', 'g'), '\*\*\+', '.*', 'g')
endfunction"}}}
function! unite#invalidate_cache(source_name)  "{{{
  for source in unite#get_current_unite().sources
    if source.name ==# a:source_name
      let source.unite__is_invalidate = 1
    endif
  endfor
endfunction"}}}
function! unite#force_redraw(...) "{{{
  call unite#view#_redraw(1, get(a:000, 0, 0), get(a:000, 1, 0))
endfunction"}}}
function! unite#redraw(...) "{{{
  call unite#view#_redraw(0, get(a:000, 0, 0), get(a:000, 1, 0))
endfunction"}}}
function! unite#get_status_string() "{{{
  return !exists('b:unite') ? '' : ((b:unite.is_async ? '[async] ' : '') .
        \ join(unite#loaded_source_names_with_args(), ', '))
endfunction"}}}
function! unite#get_marked_candidates() "{{{
  return unite#helper#get_marked_candidates()
endfunction"}}}
function! unite#get_input() "{{{
  return unite#helper#get_input()
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

  let candidates = unite#init#_candidates(
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

  return unite#init#_candidates(candidates)
endfunction"}}}
function! unite#get_current_unite() "{{{
  return exists('b:unite') && !unite#variables#use_current_unite() ?
        \ b:unite : unite#variables#current_unite()
endfunction"}}}
function! unite#set_current_unite(unite) "{{{
  return unite#variables#set_current_unite(a:unite)
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
  let context = unite#init#_context(context,
        \ unite#helper#get_source_names(a:sources))

  if context.resume
    " Check resume buffer.
    let resume_bufnr = s:get_resume_buffer(context.buffer_name)
    if resume_bufnr > 0 &&
          \ getbufvar(resume_bufnr, 'unite').source_names ==#
          \    unite#helper#get_source_names(a:sources)
      return unite#resume(context.buffer_name, context)
    endif
  endif

  call unite#variables#enable_current_unite()

  if context.toggle "{{{
    if unite#view#_close(context.buffer_name)
      return
    endif
  endif"}}}

  try
    call unite#init#_current_unite(a:sources, context)
  catch /^unite.vim: Invalid source/
    call unite#print_error('[unite.vim] ' . v:exception)
    return
  endtry

  " Caching.
  let current_unite = unite#variables#current_unite()
  let current_unite.last_input = context.input
  let current_unite.input = context.input
  call unite#_recache_candidates(context.input, context.is_redraw)

  if !current_unite.is_async &&
        \ (context.immediately || context.no_empty) "{{{
    let candidates = unite#gather_candidates()

    if empty(candidates)
      " Ignore.
      call unite#variables#disable_current_unite()
      return
    elseif context.immediately && len(candidates) == 1
      " Immediately action.
      call unite#mappings#do_action(
            \ context.default_action, [candidates[0]])
      call unite#variables#disable_current_unite()
      return
    endif
  endif"}}}

  call unite#init#_unite_buffer()

  call unite#variables#disable_current_unite()

  let unite = unite#get_current_unite()

  setlocal modifiable

  " Redraw prompt.
  silent % delete _
  call setline(unite.prompt_linenr,
        \ unite.prompt . unite.context.input)

  call unite#view#_redraw_candidates()

  call unite#handlers#_on_bufwin_enter(bufnr('%'))

  call unite#view#_init_cursor()
endfunction"}}}
function! unite#start_script(sources, ...) "{{{
  " Start unite from script.

  let context = get(a:000, 0, {})

  let context.script = 1

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
    let context = unite#init#_context(context,
          \ unite#helper#get_source_names(a:sources))
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

  if context.script
    " Set buffer-name automatically.
    let context.buffer_name = unite#helper#get_source_names(a:sources)
  endif

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
  let context = unite#init#_context(context,
        \ unite#helper#get_source_names(a:sources))
  let context.unite__is_vimfiler = 1
  let context.unite__is_interactive = 0

  try
    call unite#init#_current_unite(a:sources, context)
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
      call unite#init#_candidates_source([info[1]], source.name)
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
    let context = unite#init#_context(context,
          \ unite#helper#get_source_names(a:sources))
    let context.no_buffer = 1
    let context.unite__is_interactive = 0

    " Finalize.
    let candidates = s:get_candidates(a:sources, context)

    " Call finalize functions.
    call unite#helper#call_hook(unite#loaded_sources_list(), 'on_close')
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
    let context = unite#init#_context(context,
          \ unite#helper#get_source_names(a:sources))
    let context.no_buffer = 1
    let context.unite__is_vimfiler = 1
    let context.unite__is_interactive = 0

    let candidates = s:get_candidates(a:sources, context)
  finally
    call unite#set_current_unite(unite_save)
  endtry

  return candidates
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

  call unite#view#_switch_unite_buffer(context.buffer_name, context)

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

  call unite#view#_init_cursor()
endfunction"}}}
function! s:get_candidates(sources, context) "{{{
  try
    call unite#init#_current_unite(a:sources, a:context)
  catch /^unite.vim: Invalid source/
    return []
  endtry

  let current_unite = unite#get_current_unite()

  " Caching.
  let current_unite.last_input = a:context.input
  let current_unite.input = a:context.input
  call unite#_recache_candidates(a:context.input, a:context.is_redraw)

  let candidates = []
  for source in unite#loaded_sources_list()
    if !empty(source.unite__candidates)
      let candidates += source.unite__candidates
    endif
  endfor

  return candidates
endfunction"}}}

function! unite#vimfiler_complete(sources, arglead, cmdline, cursorpos) "{{{
  return unite#complete#vimfiler()
endfunction"}}}
function! unite#complete_source(arglead, cmdline, cursorpos) "{{{
  return unite#complete#source(a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}
function! unite#complete_buffer_name(arglead, cmdline, cursorpos) "{{{
  return unite#complete#buffer_name(a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}
function! unite#args_complete(sources, arglead, cmdline, cursorpos) "{{{
  return unite#complete#args()
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
  let unite_save = unite#variables#current_unite()
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
  let positions = unite#custom#get_profile(
        \ unite.profile_name, 'unite__save_pos')
  if key != ''
    let positions[key] = {
          \ 'pos' : getpos('.'),
          \ 'candidate' : unite#get_current_candidate(),
          \ }

    if context.input != ''
      " Save input.
      let inputs = unite#custom#get_profile(
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
      call unite#view#_resize_window()
    endif

    call unite#handlers#_on_buf_unload(bufname)

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

  call unite#handlers#_on_buf_unload(a:context.buffer_name)

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

function! unite#_recache_candidates(input, is_force) "{{{
  let unite = unite#get_current_unite()

  " Save options.
  let ignorecase_save = &ignorecase

  if unite#custom#get_profile(unite.profile_name, 'smartcase')
        \ && a:input =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase =
          \ unite#custom#get_profile(unite.profile_name, 'ignorecase')
  endif

  let context = unite.context
  let context.is_redraw = a:is_force
  let context.is_changed = a:input !=# unite.last_input

  for source in unite#loaded_sources_list()
    let source.unite__candidates = []
  endfor

  let inputs = unite#helper#get_substitute_input(a:input)
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
    call unite#helper#call_hook([source], 'on_post_filter')

    let source.unite__candidates =
          \ unite#init#_candidates_source(
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

  let custom = unite#custom#get()

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

    let custom_source = get(custom.sources, source.name, {})
    if source.ignore_pattern != '' && !context.unite__is_vimfiler
      call filter(source_candidates,
            \ "get(v:val, 'action__path', v:val.word)
            \             !~# source.ignore_pattern")
    endif

    " Call pre_filter hook.
    let context.candidates = source_candidates
    call unite#helper#call_hook([source], 'on_pre_filter')

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
          \ || unite.context.unite__is_vimfiler
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
      " Get asynchronous candidates.
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

" Internal helper functions. "{{{
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
function! unite#_convert_source_name(source_name) "{{{
  let context = unite#get_context()
  return !context.short_source_names ? a:source_name :
        \ a:source_name !~ '\A'  ? a:source_name[:1] :
        \ substitute(a:source_name, '\a\zs\a\+', '', 'g')
endfunction"}}}
function! s:get_resume_buffer(buffer_name) "{{{
  let buffer_name = a:buffer_name
  if buffer_name !~ '@\d\+$'
    " Add postfix.
    let prefix = unite#util#is_windows() ?
          \ '[unite] - ' : '*unite* - '
    let prefix .= buffer_name
    let buffer_name .= unite#helper#get_postfix(prefix, 0)
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
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
