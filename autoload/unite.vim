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
  return printf("%s:\<C-u>call unite#action#do(%s)\<CR>",
        \             (mode() ==# 'i' ? "\<C-o>" : ''), string(a:action))
endfunction"}}}
function! unite#smart_map(narrow_map, select_map) "{{{
  return (line('.') <= unite#get_current_unite().prompt_linenr
        \ && empty(unite#helper#get_marked_candidates())) ?
        \   a:narrow_map : a:select_map
endfunction"}}}
function! unite#start_complete(...) "{{{
  return call('unite#start#complete', a:000)
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
  call unite#action#take(a:action_name, a:candidate, 0)
endfunction"}}}
function! unite#take_parents_action(action_name, candidate, extend_candidate) "{{{
  call unite#action#take(a:action_name,
        \ extend(deepcopy(a:candidate), a:extend_candidate), 1)
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

function! unite#force_redraw(...) "{{{
  call unite#view#_redraw(1, get(a:000, 0, 0), get(a:000, 1, 0))
endfunction"}}}
function! unite#redraw(...) "{{{
  call unite#view#_redraw(0, get(a:000, 0, 0), get(a:000, 1, 0))
endfunction"}}}
function! unite#get_status_string() "{{{
  return unite#view#_get_status_string()
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
  return unite#view#_add_previewed_buffer_list(a:bufnr)
endfunction"}}}
function! unite#remove_previewed_buffer_list(bufnr) "{{{
  return unite#view#_remove_previewed_buffer_list(a:bufnr)
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
function! unite#start(...) "{{{
  return call('unite#start#standard', a:000)
endfunction"}}}
function! unite#start_script(...) "{{{
  return call('unite#start#script', a:000)
endfunction"}}}
function! unite#start_temporary(...) "{{{
  return call('unite#start#temporary', a:000)
endfunction"}}}
function! unite#vimfiler_check_filetype(...) "{{{
  return call('unite#start#vimfiler_check_filetype', a:000)
endfunction"}}}
function! unite#get_candidates(...) "{{{
  return call('unite#start#get_candidates', a:000)
endfunction"}}}
function! unite#get_vimfiler_candidates(...) "{{{
  return call('unite#start#get_vimfiler_candidates', a:000)
endfunction"}}}
function! unite#resume(...) "{{{
  return call('unite#start#resume', a:000)
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
  call unite#view#_quit(get(a:000, 0, 1), 1)
endfunction"}}}
function! unite#force_quit_session()  "{{{
  call unite#view#_quit(1)

  let context = unite#get_context()
  if context.temporary && !empty(context.old_buffer_info)
      call unite#start#resume_from_temporary(context)
  endif
endfunction"}}}
function! unite#quit_session()  "{{{
  call unite#view#_quit(0)

  let context = unite#get_context()
  if context.temporary && !empty(context.old_buffer_info)
    call unite#start#resume_from_temporary(context)
  endif
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
            \ unite#helper#convert_source_name(source.name))
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

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
