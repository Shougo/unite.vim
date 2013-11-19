"=============================================================================
" FILE: action.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 19 Nov 2013.
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

function! unite#action#get_action_table(source_name, kind, self_func, ...) "{{{
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

function! unite#action#get_alias_table(source_name, kind, ...) "{{{
  let source_table = get(a:000, 0, {})
  let alias_table = {}
  for kind_name in unite#util#convert2list(a:kind)
    call extend(alias_table,
          \ s:get_alias_table(a:source_name, kind_name, source_table))
  endfor

  return alias_table
endfunction"}}}

function! unite#action#get_default_action(source_name, kind) "{{{
  let kinds = unite#util#convert2list(a:kind)

  return s:get_default_action(a:source_name, kinds[-1])
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
  if empty(kind)
    call unite#print_error('[unite.vim] kind "' . a:kind_name . '" is not found.')
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
          \ unite#action#get_action_table(a:source_name, parent,
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
    if !has_key(action, 'from')
      let action.from = ''
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
    if !has_key(action, 'is_tab')
      let action.is_tab = 0
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

function! unite#action#take(action_name, candidate, is_parent_action) "{{{
  let candidate_head = type(a:candidate) == type([]) ?
        \ a:candidate[0] : a:candidate

  let action_table = unite#action#get_action_table(
        \ candidate_head.source, candidate_head.kind,
        \ unite#get_self_functions()[-3], a:is_parent_action)

  let action_name =
        \ a:action_name ==# 'default' ?
        \ unite#action#get_default_action(
        \   candidate_head.source, candidate_head.kind)
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

function! unite#action#do(action_name, ...) "{{{
  if &filetype == 'vimfiler' && has_key(b:vimfiler, 'unite')
    " Restore unite condition in vimfiler.
    call unite#set_current_unite(b:vimfiler.unite)
  endif

  call unite#redraw()

  let candidates = get(a:000, 0,
        \ unite#helper#get_marked_candidates())
  let new_context = get(a:000, 1, {})
  let sources = get(a:000, 2, {})

  let unite = unite#get_current_unite()
  if empty(candidates)
    let num = (line('.') <= unite.prompt_linenr) ? 0 :
          \ (line('.') - (unite.prompt_linenr + 1))
    if line('$') - (unite.prompt_linenr + 1) < num
      " Ignore.
      return []
    endif

    let candidates = [ unite#helper#get_current_candidate() ]
  endif

  let candidates = filter(copy(candidates),
        \ "!empty(v:val) && !get(v:val, 'is_dummy', 0)")
  if empty(candidates)
    return []
  endif

  let action_tables = s:get_candidates_action_table(
        \ a:action_name, candidates, sources)

  if !empty(new_context)
    " Set new context.
    let new_context = extend(
          \ deepcopy(unite#get_context()), new_context)
    let old_context = unite#set_context(new_context)
    let unite = unite#get_current_unite()
  endif

  let context = unite#get_context()

  " Execute action.
  let is_quit = 0
  let is_redraw = 0
  let _ = []
  for table in action_tables
    " Check quit flag.
    if table.action.is_quit && unite.profile_name !=# 'action'
          \ && !table.action.is_start
          \ && !(table.action.is_tab && context.no_quit)
      call unite#all_quit_session(0)
      let is_quit = 1
    endif

    if table.action.is_start && !empty(unite#helper#get_marked_candidates())
      call s:clear_marks(candidates)
      call unite#force_redraw()
      let is_redraw = 0
    elseif table.action.is_selectable
      let is_redraw = 1
    endif

    try
      call add(_, table.action.func(table.candidates))
    catch /^Vim\%((\a\+)\)\=:E325/
      " Ignore catch.
      call unite#print_error(v:exception)
      call unite#print_error('Warning: Swap file was found while executing action!')
      call unite#print_error('Action name is ' . table.action.name)
    catch
      call unite#print_error(v:throwpoint)
      call unite#print_error(v:exception)
      call unite#print_error('Error occured while executing action!')
      call unite#print_error('Action name is ' . table.action.name)
    endtry

    " Executes command.
    if context.execute_command != ''
      execute context.execute_command
    endif

    " Check invalidate cache flag.
    if table.action.is_invalidate_cache
      for source_name in table.source_names
        call unite#helper#invalidate_cache(source_name)
      endfor

      let is_redraw = 1
    endif
  endfor

  if (!is_quit || unite.context.no_quit) && unite.context.keep_focus
    let winnr = bufwinnr(unite.bufnr)

    if winnr > 0
      " Restore focus.
      execute winnr 'wincmd w'
    endif
  endif

  if !empty(new_context)
    " Restore context.
    let unite.context = old_context
  endif

  if is_redraw && !empty(filter(range(1, winnr('$')),
          \ "getwinvar(v:val, '&filetype') ==# 'vimfiler'"))
    " Redraw vimfiler buffer.
    call vimfiler#force_redraw_all_vimfiler(1)
  endif

  if !is_quit && is_redraw
    call s:clear_marks(candidates)
    call unite#force_redraw()
  endif

  return _
endfunction"}}}

function! unite#action#do_candidates(action_name, candidates, ...) "{{{
  let context = get(a:000, 0, {})
  let context = unite#init#_context(context)
  let context.unite__is_interactive = 0
  let context.unite__disable_hooks = 1
  call unite#set_context(context)

  return unite#action#do(
        \ a:action_name, a:candidates, context)
endfunction"}}}

function! unite#action#_get_candidate_action_table(candidate, sources) "{{{
  let Self = unite#get_self_functions()[-1]

  return unite#action#get_action_table(
        \ a:candidate.source, a:candidate.kind, Self, 0, a:sources)
endfunction"}}}

function! s:get_candidates_action_table(action_name, candidates, sources) "{{{
  let action_tables = []
  let Self = unite#get_self_functions()[-1]
  for candidate in a:candidates
    let action_table = unite#action#_get_candidate_action_table(
          \ candidate, a:sources)

    let action_name = a:action_name
    if action_name ==# 'default'
      " Get default action.
      let action_name = unite#action#get_default_action(
            \ candidate.source, candidate.kind)
    endif

    if action_name == ''
      " Ignore.
      return []
    endif

    if !has_key(action_table, action_name)
      call unite#util#print_error(
            \ candidate.unite__abbr . '(' . candidate.source . ')')
      call unite#util#print_error(
            \ 'No such action : ' . action_name)

      return []
    endif

    let action = action_table[action_name]

    " Check selectable flag.
    if !action.is_selectable && len(a:candidates) > 1
      call unite#util#print_error(
            \ candidate.unite__abbr . '(' . candidate.source . ')')
      call unite#util#print_error(
            \ 'Not selectable action : ' . action_name)
      return []
    endif

    let found = 0
    for table in action_tables
      if action == table.action
        " Add list.
        call add(table.candidates, candidate)
        call add(table.source_names, candidate.source)
        let found = 1
        break
      endif
    endfor

    if !found
      " Add action table.
      call add(action_tables, {
            \ 'action' : action,
            \ 'source_names' : [candidate.source],
            \ 'candidates' : (!action.is_selectable ? candidate : [candidate]),
            \ })
    endif
  endfor

  return action_tables
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
function! s:clear_marks(candidates) "{{{
  for candidate in a:candidates
    let candidate.unite__is_marked = 0
  endfor
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
