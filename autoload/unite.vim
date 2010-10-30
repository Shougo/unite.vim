"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 26 Oct 2010
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
"}}}

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

let s:custom_actions = {}
let s:custom_default_actions = {}
let s:custom_aliases = {}

let s:substitute_pattern = {}
call unite#set_substitute_pattern('files', '^\~', substitute(substitute($HOME, '\\', '/', 'g'), ' ', '\\\\ ', 'g'), -100)
call unite#set_substitute_pattern('files', '[^~.*]\zs/', '*/*', 100)
"}}}


" Helper functions."{{{
function! unite#set_dictionary_helper(variable, keys, pattern)"{{{
  for key in split(a:keys, ',')
    if !has_key(a:variable, key)
      let a:variable[key] = a:pattern
    endif
  endfor
endfunction"}}}
function! unite#take_action(action_name, candidate)"{{{
  let l:candidate = type(a:candidate) == type([]) ?
        \ a:candidate[0] : a:candidate

  let l:action_table = unite#get_action_table(l:candidate.source, l:candidate.kind, 0)

  let l:action_name =
        \ a:action_name ==# 'default' ?
        \ unite#get_default_action(l:candidate.source, l:candidate.kind)
        \ : a:action_name

  if !has_key(l:action_table, a:action_name)
    return 'no such action ' . a:action_name
  endif

  call l:action_table[a:action_name].func(a:candidate)
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
  return a:0 == 0 ? l:unite.sources : get(l:unite.sources, a:1, {})
endfunction"}}}
function! unite#available_kinds(...)"{{{
  let l:unite = s:get_unite()
  return a:0 == 0 ? l:unite.kinds : get(l:unite.kinds, a:1, {})
endfunction"}}}
function! unite#get_action_table(source_name, kind_name, ...)"{{{
  let l:kind = unite#available_kinds(a:kind_name)
  let l:source = unite#available_sources(a:source_name)
  let l:contains_custom_action = a:0 > 0 ? a:1 : 1

  " Common actions.
  let l:action_table = (a:kind_name != 'common')?
        \ copy(unite#available_kinds('common').action_table) : {}
  " Common custom actions.
  if l:contains_custom_action && has_key(s:custom_actions, 'common')
    let l:action_table = extend(l:action_table, s:custom_actions['common'])
  endif
  " Common custom aliases.
  if l:contains_custom_action && has_key(s:custom_aliases, 'common')
    call s:filter_alias_action(l:action_table, s:custom_aliases['common'])
  endif

  " Kind actions.
  let l:action_table = extend(copy(l:action_table), l:kind.action_table)
  " Kind custom actions.
  if l:contains_custom_action && has_key(s:custom_actions, a:kind_name)
    let l:action_table = extend(l:action_table, s:custom_actions[a:kind_name])
  endif
  " Kind custom aliases.
  if l:contains_custom_action && has_key(s:custom_aliases, a:kind_name)
    call s:filter_alias_action(l:action_table, s:custom_aliases[a:kind_name])
  endif

  " Source/kind actions.
  if has_key(l:source, 'action_table')
        \ && has_key(l:source.action_table, a:kind_name)
    let l:action_table = extend(l:action_table, l:source.action_table[a:kind_name])
  endif
  let l:source_kind = a:source_name.'/'.a:kind_name
  " Source/kind custom actions.
  if l:contains_custom_action && has_key(s:custom_actions, l:source_kind)
    let l:action_table = extend(l:action_table, s:custom_actions[a:kind_name])
  endif
  " Source/kind custom aliases.
  if l:contains_custom_action && has_key(s:custom_aliases, l:source_kind)
    call s:filter_alias_action(l:action_table, s:custom_aliases[l:source_kind])
  endif

  " Filtering nop action.
  return filter(l:action_table, 'v:key !=# "nop"')
endfunction"}}}
function! unite#get_default_action(source_name, kind_name)"{{{
  let l:source = unite#available_sources(a:source_name)

  if has_key(s:custom_default_actions, a:source_name.'/'.a:kind_name)
    " Source/kind custom actions.
    return s:custom_default_actions[a:source_name.'/'.a:kind_name]
  elseif has_key(l:source, 'default_action')
        \ && has_key(l:source.default_action, a:kind_name)
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
  let l:options = ['-buffer-name=', '-input=', '-prompt=',  '-default-action=', '-start-insert']
  return filter(keys(l:sources)+l:options, 'stridx(v:val, a:arglead) == 0')
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
  if l:linenr <= 2 || &filetype !=# 'unite'
    " Ignore.
    return
  endif

  let l:modifiable_save = &l:modifiable
  setlocal modifiable

  let l:candidate = unite#get_unite_candidates()[l:linenr - 3]
  call setline(l:linenr, s:convert_line(l:candidate))

  let &l:modifiable = l:modifiable_save
endfunction"}}}
function! unite#quick_match_redraw() "{{{
  let l:modifiable_save = &l:modifiable
  setlocal modifiable

  call setline(3, s:convert_quick_match_lines(b:unite.candidates))
  redraw

  let &l:modifiable = l:modifiable_save
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
    elseif l:input =~ '[*]'
      " Wildcard.
      let l:input = unite#escape_match(l:input)
      call filter(a:list, 'v:val.word =~ ' . string(l:input))
    else
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
  if stridx(getline(2), b:unite.prompt) != 0
    " Restore prompt.
    call setline(2, b:unite.prompt . getline(2))
  endif

  return getline(2)[len(b:unite.prompt):]
endfunction"}}}
function! unite#print_error(message)"{{{
  echohl WarningMsg | echomsg a:message | echohl None
endfunction"}}}
function! unite#substitute_path_separator(path)"{{{
  return unite#is_win() ? substitute(a:path, '\\', '/', 'g') : a:path
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
  if !has_key(l:context, 'buffer_name')
    let l:context.buffer_name = ''
  endif
  if !has_key(l:context, 'prompt')
    let l:context.prompt = '>'
  endif
  if !has_key(l:context, 'default_action')
    let l:context.default_action = 'default'
  endif

  try
    call s:initialize_unite_buffer(a:sources, l:context)
  catch /^Invalid source/
    return
  endtry

  setlocal modifiable

  silent % delete _
  call setline(s:LNUM_STATUS, 'Sources: ' . join(map(copy(a:sources), 'v:val[0]'), ', '))
  call setline(s:LNUM_PATTERN, b:unite.prompt . b:unite.context.input)
  execute s:LNUM_PATTERN

  call unite#force_redraw()

  if !g:unite_enable_split_vertically
    execute g:unite_winheight 'wincmd _'
  endif

  if g:unite_enable_start_insert
        \ || b:unite.context.start_insert || b:unite.context.is_insert
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

  let s:unite = b:unite

  if !g:unite_enable_split_vertically
    execute g:unite_winheight 'wincmd _'
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
  execute g:unite_lcd_command '`=l:cwd`'

  if !s:unite.context.is_insert
    stopinsert
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
function! s:initialize_sources(sources)"{{{
  let l:all_sources = extend(copy(s:default_sources), s:custom_sources)
  let l:sources = {}

  let l:number = 0
  for [l:source_name, l:args] in a:sources
    if !has_key(l:all_sources, l:source_name)
      call unite#print_error('Invalid source name "' . l:source_name . '" is detected.')
      throw 'Invalid source'
    endif

    let l:source = l:all_sources[l:source_name]
    let l:source.args = l:args
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
  return extend(copy(s:default_kinds), s:custom_kinds)
endfunction"}}}
function! s:gather_candidates(input, context)"{{{
  let l:context = a:context
  let l:input_list = filter(split(a:input, '\\\@<! ', 1), 'v:val !~ "!"')
  let l:context.input = empty(l:input_list) ? '' : l:input_list[0]

  let l:candidates = []
  for l:source in unite#available_sources_list()
    if l:source.is_volatile
          \ || !has_key(b:unite.cached_candidates, l:source.name)
          \ || (l:context.is_force || l:source.unite__is_invalidate)

      let l:context.source = l:source

      " Check required pattern length.
      let l:source_candidates =
            \ (has_key(l:source, 'required_pattern_length')
            \   && len(l:context.input) < l:source.required_pattern_length) ?
            \ [] : copy(l:source.gather_candidates(l:source.args, l:context))

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

    if a:input != ''
      call unite#keyword_filter(l:source_candidates, a:input)
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
function! s:convert_quick_match_lines(candidates)"{{{
  let l:max_width = winwidth(0) - 20
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
          \ . (l:candidate.unite__is_marked ? '* ' : '- ')
          \ . unite#util#truncate_smart(l:candidate.abbr, l:max_width, 30, '..')
          \ . ' ' . l:candidate.source)

    let l:num += 1
  endfor

  return l:candidates
endfunction"}}}
function! s:convert_lines(candidates)"{{{
  let l:max_width = winwidth(0) - 20

  return map(copy(a:candidates),
        \ '(v:val.unite__is_marked ? "* " : "- ") . unite#util#truncate_smart(v:val.abbr, ' . l:max_width .  ', 30, "..") . " " . v:val.source')
endfunction"}}}
function! s:convert_line(candidate)"{{{
  let l:max_width = winwidth(0) - 20

  return (a:candidate.unite__is_marked ? '* ' : '- ')
        \ . unite#util#truncate_smart(a:candidate.abbr, l:max_width, 30, '..')
        \ . " " . a:candidate.source
endfunction"}}}

function! s:initialize_unite_buffer(sources, context)"{{{
  " Check sources.
  let l:sources = s:initialize_sources(a:sources)

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
  if unite#is_win()
    let l:buffer_name = '[unite]'
  else
    let l:buffer_name = '*unite*'
  endif
  if l:context.buffer_name != ''
    let l:buffer_name .= ' - ' . l:context.buffer_name
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
  let b:unite.context = l:context
  let b:unite.candidates = []
  let b:unite.cached_candidates = {}
  let b:unite.sources = l:sources
  let b:unite.kinds = s:initialize_kinds()
  let b:unite.buffer_name = (l:context.buffer_name == '') ? 'default' : l:context.buffer_name
  let b:unite.prompt = l:context.prompt
  let b:unite.input = l:context.input
  let b:unite.last_input = l:context.input
  let b:unite.bufnr = bufnr('%')

  let s:unite = b:unite

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
    let &redrawtime = 500
  endif

  " User's initialization.
  setlocal nomodifiable
  setfiletype unite

  " Set highlight.
  let l:match_prompt = escape(b:unite.prompt, '\/*~.^$[]')
  syntax clear uniteInputPrompt
  execute 'syntax match uniteInputPrompt' '/^'.l:match_prompt.'/ contained'
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

  let l:context = b:unite.context
  let l:context.is_force = a:is_force

  let l:candidates = s:gather_candidates(l:input, l:context)

  let &ignorecase = l:ignorecase_save

  let l:modifiable_save = &l:modifiable
  setlocal modifiable

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

  let &l:modifiable = l:modifiable_save

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

    " Prompt check.
    if col('.') <= len(b:unite.prompt)
      startinsert!
    endif
  endif
endfunction"}}}
function! s:on_cursor_moved()  "{{{
  execute 'setlocal' line('.') == 2 ? 'modifiable' : 'nomodifiable'
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
"}}}

" vim: foldmethod=marker
