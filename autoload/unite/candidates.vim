"=============================================================================
" FILE: candidates.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 16 Jan 2014.
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

function! unite#candidates#_recache(input, is_force) "{{{
  let unite = unite#get_current_unite()

  " Save options.
  let ignorecase_save = &ignorecase

  if unite#custom#get_profile(unite.profile_name, 'smartcase')
        \ && get(split(a:input, '\W'), -1, '') =~ '\u'
    let &ignorecase = 0
  else
    let &ignorecase =
          \ unite#custom#get_profile(unite.profile_name, 'ignorecase')
  endif

  let context = unite.context
  let context.is_redraw = a:is_force
  let context.is_changed = a:input !=# unite.last_input

  for source in unite.sources
    let source.unite__candidates = []
  endfor

  let inputs = unite#helper#get_substitute_input(a:input)
  let context.is_list_input = len(inputs) > 1
  for input in inputs
    let context.input = input
    call s:recache_candidates_loop(context, a:is_force)
  endfor

  let filtered_count = 0

  for source in unite.sources
    let source.unite__is_invalidate = 0

    if !context.no_buffer && source.max_candidates != 0
          \ && context.unite__is_interactive
          \ && !unite.disabled_max_candidates
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

    if source.is_grouped
      let source.unite__candidates =
            \ unite#candidates#_group_post_filters(source.unite__candidates)
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

function! unite#candidates#gather(...) "{{{
  let is_gather_all = get(a:000, 0, 0)

  let unite = unite#get_current_unite()
  let unite.candidates = []
  for source in unite.sources
    let unite.candidates += source.unite__candidates
  endfor

  if is_gather_all
    let unite.candidates_pos = len(unite.candidates)
  elseif unite.context.is_redraw || unite.candidates_pos == 0
    let unite.candidates_pos = line('.') + winheight(0)
  endif

  let candidates = unite#init#_candidates(
        \ unite.candidates[: unite.candidates_pos-1])

  " Post filter.
  for filter_name in unite.post_filters
    let candidates = unite#helper#call_filter(
          \ filter_name, candidates, unite.context)
  endfor

  return candidates
endfunction"}}}

function! unite#candidates#_gather_pos(offset) "{{{
  let unite = unite#get_current_unite()
  if unite.context.is_redraw || unite.candidates_pos == 0
    return []
  endif

  let unite = unite#get_current_unite()
  let candidates = unite.candidates[unite.candidates_pos :
        \ unite.candidates_pos + a:offset - 1]

  " Post filter.
  for filter_name in unite.post_filters
    let candidates = unite#helper#call_filter(
          \ filter_name, candidates, unite.context)
  endfor

  let unite.candidates_pos += len(candidates)

  return unite#init#_candidates(candidates)
endfunction"}}}

function! s:recache_candidates_loop(context, is_force) "{{{
  let unite = unite#get_current_unite()

  let input_len = unite#util#strchars(a:context.input)

  let custom = unite#custom#get()

  let candidate_sources = []
  let unite.max_source_candidates = 0
  for source in unite.sources
    " Check required pattern length.
    if input_len < source.required_pattern_length
      continue
    endif

    " Set context.
    let context = source.unite__context
    let context.input = a:context.input
    let context.source_name = source.name

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
    let context.input_list = split(context.input, '\\\@<! ', 1)
    let context.path = get(filter(copy(context.input_list),
        \         "v:val !~ '^[!:]'"), 0, '')
    let context.unite__max_candidates =
          \ (unite.disabled_max_candidates ? 0 : source.max_candidates)

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
    for Filter in (context.unite__is_vimfiler ?
          \ [] : get(custom_source, 'filters', source.filters))
      if type(Filter) != type('')
        call add((empty(matchers) ?
              \ prev_filters : post_filters), Filter)

        unlet Filter
        continue
      endif

      let name = get(unite#get_filters(Filter),
            \              'name', '')
      if name == ''
        call unite#print_error(printf(
              \ 'Invalid filter name "%s" is detected.', Filter))
      elseif name =~# '\%(^\|_\)matcher_'
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
          \    && context.unite__max_candidates > 0) ?
          \ source.max_candidates : source.unite__orig_len_candidates

    " Call filters.
    for Filter in prev_filters + matchers + sorters + post_filters
      if type(Filter) == type('')
        let source_candidates = unite#helper#call_filter(
              \ Filter, source_candidates, context)
      else
        let source_candidates = call(Filter,
              \ [source_candidates, context], source)
      endif

      unlet Filter
    endfor

    " Get execute_command.
    let a:context.execute_command = context.execute_command

    let source.unite__candidates += source_candidates
    let source.unite__len_candidates = len(source_candidates)
    if !empty(source_candidates)
      call add(candidate_sources,
            \ unite#helper#convert_source_name(source.name))
    endif
  endfor

  if !a:context.hide_source_names && len(unite.sources) > 1
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
              \ copy(a:source.gather_candidates(a:source.args,
              \ a:source.unite__context))
      endif
    endif

    if a:source.unite__context.is_async
      " Get asynchronous candidates.
      let funcname = 'async_gather_candidates'
      while 1
        let a:source.unite__cached_candidates +=
              \ a:source.async_gather_candidates(a:source.args, context)

        if (!context.sync && context.unite__is_interactive)
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

function! unite#candidates#_group_post_filters(candidates) "{{{
  " Post filters for group
  let groups = {}
  for i in range(0, len(a:candidates) - 1)
    let group = a:candidates[i].group
    if has_key(groups, 'group')
      call add(groups[group].indexes, i)
    else
      let groups[group] = { 'index' : i, 'indexes' : [i] }
    endif
  endfor

  let _ = []
  for [group, val] in unite#util#sort_by(items(groups), 'v:val[1].index')
    " Add group candidate
    call add(_, {'word' : group, 'is_dummy' : 1})

    " Add children candidates
    let _ += map(val.indexes, 'a:candidates[v:val]')
  endfor

  return _
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
