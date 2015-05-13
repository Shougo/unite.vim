"=============================================================================
" FILE: helpers.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
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

function! unite#helper#call_hook(sources, hook_name) "{{{
  let context = unite#get_context()
  if context.unite__disable_hooks
    return
  endif

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
            \ '[unite.vim] Error occurred in calling hook "' . a:hook_name . '"!')
      call unite#print_error(
            \ '[unite.vim] Source name is ' . source.name)
    endtry
  endfor
endfunction"}}}

function! unite#helper#get_substitute_input(input) "{{{
  let unite = unite#get_current_unite()

  let input = a:input
  if empty(unite.args) && input =~ '^.\{-}\%(\\\@<!\s\)\+'
    " Ignore source name
    let input = matchstr(input, '^.\{-}\%(\\\@<!\s\)\+\zs.*')
  endif

  let substitute_patterns = reverse(unite#util#sort_by(
        \ values(unite#custom#get_profile(unite.profile_name,
        \        'substitute_patterns')),
        \ 'v:val.priority'))
  if unite.input != '' && stridx(input, unite.input) == 0
        \ && !empty(unite.args)
    " Substitute after input.
    let input_save = input
    let input = input_save[len(unite.input) :]
    let head = input_save[: len(unite.input)-1]
  else
    " Substitute all input.
    let head = ''
  endif

  let inputs = unite#helper#get_substitute_input_loop(
        \ input, substitute_patterns)

  return map(inputs, 'head . v:val')
endfunction"}}}
function! unite#helper#get_substitute_input_loop(input, substitute_patterns) "{{{
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

function! unite#helper#adjustments(currentwinwidth, the_max_source_name, size) "{{{
  let max_width = a:currentwinwidth - a:the_max_source_name - a:size
  if max_width < 20
    return [a:currentwinwidth - a:size, 0]
  else
    return [max_width, a:the_max_source_name]
  endif
endfunction"}}}

function! unite#helper#parse_options(cmdline) "{{{
  let args = []
  let options = {}

  " Eval
  let cmdline = (a:cmdline =~ '\\\@<!`.*\\\@<!`') ?
        \ s:eval_cmdline(a:cmdline) : a:cmdline

  for arg in split(cmdline, '\%(\\\@<!\s\)\+')
    let arg = substitute(arg, '\\\( \)', '\1', 'g')
    let arg_key = substitute(arg, '=\zs.*$', '', '')

    let name = substitute(tr(arg_key, '-', '_'), '=$', '', '')
    let value = (arg_key =~ '=$') ? arg[len(arg_key) :] : 1

    if arg_key =~ '^-custom-'
          \ || index(unite#variables#options(), arg_key) >= 0
      let options[name[1:]] = value
    else
      call add(args, arg)
    endif
  endfor

  return [args, options]
endfunction"}}}
function! unite#helper#parse_options_args(cmdline) "{{{
  let _ = []
  let [args, options] = unite#helper#parse_options(a:cmdline)
  for arg in args
    " Add source name.
    let source_name = matchstr(arg, '^[^:]*')
    let source_arg = arg[len(source_name)+1 :]
    let source_args = source_arg  == '' ? [] :
          \  map(split(source_arg, '\\\@<!:', 1),
          \      'substitute(v:val, ''\\\(.\)'', "\\1", "g")')
    call add(_, insert(source_args, source_name))
  endfor

  return [_, options]
endfunction"}}}
function! unite#helper#parse_options_user(args) "{{{
  " Add for history/unite.
  let [args, options] = unite#helper#parse_options_args(a:args)
  let options.unite__is_manual = 1
  return [args, options]
endfunction"}}}
function! s:eval_cmdline(cmdline) abort "{{{
  let cmdline = ''
  let prev_match = 0
  let match = match(a:cmdline, '\\\@<!`.\{-}\\\@<!`')
  while match >= 0
    if match - prev_match > 0
      let cmdline .= a:cmdline[prev_match : match - 1]
    endif
    let prev_match = matchend(a:cmdline,
          \ '\\\@<!`.\{-}\\\@<!`', match)
    sandbox let cmdline .= escape(eval(
          \ a:cmdline[match+1 : prev_match - 2]), '\: ')

    let match = match(a:cmdline, '\\\@<!`.\{-}\\\@<!`', prev_match)
  endwhile
  if prev_match >= 0
    let cmdline .= a:cmdline[prev_match :]
  endif

  return cmdline
endfunction"}}}

function! unite#helper#parse_source_args(args) "{{{
  let args = copy(a:args)
  if empty(args)
    return []
  endif

  let args[0] = unite#helper#parse_source_path(args[0])
  return args
endfunction"}}}

function! unite#helper#parse_source_path(path) "{{{
  " Expand ?!/buffer_project_subdir, !/project_subdir and ?/buffer_subdir
  if a:path =~ '^?!'
    " Use project directory from buffer directory
    let path = unite#helper#get_buffer_directory(bufnr('%'))
    let path = unite#util#substitute_path_separator(
      \ unite#util#path2project_directory(path) . a:path[2:])
  elseif a:path =~ '^!'
    " Use project directory from cwd
    let path = &filetype ==# 'vimfiler' ?
          \ b:vimfiler.current_dir :
          \ unite#util#substitute_path_separator(getcwd())
    let path = unite#util#substitute_path_separator(
      \ unite#util#path2project_directory(path) . a:path[1:])
  elseif a:path =~ '^?'
    " Use buffer directory
    let path = unite#util#substitute_path_separator(
      \ unite#helper#get_buffer_directory(bufnr('%')) . a:path[1:])
  else
    let path = a:path
  endif

  " Don't assume empty path means current directory.
  " Let the sources customize default rules.
  if path != ''
    let path = unite#util#substitute_path_separator(
          \ fnamemodify(unite#util#expand(path), ':p'))
  endif

  " resolve .. in the paths
  return resolve(path)
endfunction"}}}

function! unite#helper#get_marked_candidates() "{{{
  return unite#util#sort_by(filter(copy(unite#get_unite_candidates()),
        \ 'v:val.unite__is_marked'), 'v:val.unite__marked_time')
endfunction"}}}

function! unite#helper#get_input(...) "{{{
  let is_force = get(a:000, 0, 0)
  let unite = unite#get_current_unite()
  if !is_force && mode() !=# 'i'
    return unite.context.input
  endif

  if unite.prompt_linenr == 0
    return ''
  endif

  " Prompt check.
  if unite.context.prompt != '' &&
        \ getline(unite.prompt_linenr)[: len(unite.context.prompt)-1]
        \   !=# unite.context.prompt
    let modifiable_save = &l:modifiable
    setlocal modifiable

    " Restore prompt.
    call setline(unite.prompt_linenr, unite.context.prompt)

    let &l:modifiable = modifiable_save
  endif

  return getline(unite.prompt_linenr)[len(unite.context.prompt):]
endfunction"}}}

function! unite#helper#get_source_names(sources) "{{{
  return map(map(copy(a:sources),
        \ "type(v:val) == type([]) ? v:val[0] : v:val"),
        \ "type(v:val) == type('') ? v:val : v:val.name")
endfunction"}}}

function! unite#helper#get_postfix(prefix, is_create, ...) "{{{
  let prefix = substitute(a:prefix, '@\d\+$', '', '')
  let buffers = get(a:000, 0, range(1, bufnr('$')))
  let buflist = sort(filter(map(buffers,
        \ 'bufname(v:val)'), 'stridx(v:val, prefix) >= 0'), 's:sort_buffer_name')
  if empty(buflist)
    return ''
  endif

  return a:is_create ? '@'.(matchstr(buflist[-1], '@\zs\d\+$') + 1)
        \ : matchstr(buflist[-1], '@\d\+$')
endfunction"}}}

function! s:sort_buffer_name(lhs, rhs) "{{{
  return matchstr(a:lhs, '@\zs\d\+$') - matchstr(a:rhs, '@\zs\d\+$')
endfunction"}}}

function! unite#helper#convert_source_name(source_name) "{{{
  let unite = unite#get_current_unite()
  return (len(unite.sources) == 1 ||
        \  !unite.context.short_source_names) ? a:source_name :
        \ a:source_name !~ '\A'  ? a:source_name[:1] :
        \ substitute(a:source_name, '\a\zs\a\+', '', 'g')
endfunction"}}}

function! unite#helper#invalidate_cache(source_name)  "{{{
  for source in unite#get_current_unite().sources
    if source.name ==# a:source_name
      let source.unite__is_invalidate = 1
    endif
  endfor
endfunction"}}}

function! unite#helper#get_unite_winnr(buffer_name) "{{{
  for winnr in filter(range(1, winnr('$')),
        \ "getbufvar(winbufnr(v:val), '&filetype') ==# 'unite'")
    let buffer_context = get(getbufvar(
          \ winbufnr(winnr), 'unite'), 'context', {})
    if !empty(buffer_context) &&
          \ buffer_context.buffer_name ==# a:buffer_name
      if buffer_context.temporary
            \ && !empty(filter(copy(buffer_context.unite__old_buffer_info),
            \ 'v:val.buffer_name ==# buffer_context.buffer_name'))
        " Disable resume.
        let buffer_context.unite__old_buffer_info = []
      endif
      return winnr
    endif
  endfor

  return -1
endfunction"}}}
function! unite#helper#get_unite_bufnr(buffer_name) "{{{
  for bufnr in filter(range(1, bufnr('$')),
        \ "getbufvar(v:val, '&filetype') ==# 'unite'")
    let buffer_context = get(getbufvar(bufnr, 'unite'), 'context', {})
    if !empty(buffer_context) &&
          \ buffer_context.buffer_name ==# a:buffer_name
      if buffer_context.temporary
            \ && !empty(filter(copy(buffer_context.unite__old_buffer_info),
            \ 'v:val.buffer_name ==# buffer_context.buffer_name'))
        " Disable resume.
        let buffer_context.unite__old_buffer_info = []
      endif

      return bufnr
    endif
  endfor

  return -1
endfunction"}}}

function! unite#helper#get_current_candidate(...) "{{{
  let linenr = a:0 >= 1? a:1 : line('.')
  let unite = unite#get_current_unite()
  if unite.context.prompt_direction ==# 'below'
    let num = unite.prompt_linenr == 0 ?
          \ linenr - line('$') - 1 :
          \ linenr == unite.prompt_linenr ?
          \ -1 : linenr - line('$')
  else
    let num = linenr == unite.prompt_linenr ?
          \ 0 : linenr - 1 - unite.prompt_linenr
  endif

  let unite.candidate_cursor = num

  return get(unite#get_unite_candidates(), num, {})
endfunction"}}}

function! unite#helper#get_current_candidate_linenr(num) "{{{
  let candidate_num = 0
  let num = 0
  for candidate in unite#get_unite_candidates()
    if !candidate.is_dummy
      let candidate_num += 1
    endif

    let num += 1

    if candidate_num >= a:num
      break
    endif
  endfor

  let unite = unite#get_current_unite()
  if unite.context.prompt_direction ==# 'below'
    let num = num * -1
    if unite.prompt_linenr == 0
      let num += line('$') + 1
    endif
  endif

  return unite.prompt_linenr + num
endfunction"}}}

function! unite#helper#call_filter(filter_name, candidates, context) "{{{
  let filter = unite#get_filters(a:filter_name)
  if empty(filter)
    return a:candidates
  endif

  return filter.filter(a:candidates, a:context)
endfunction"}}}
function! unite#helper#call_source_filters(filters, candidates, context, source) "{{{
  let candidates = a:candidates
  for l:Filter in a:filters
    if type(l:Filter) == type('')
      let candidates = unite#helper#call_filter(
            \ l:Filter, candidates, a:context)
    else
      let candidates = call(l:Filter, [candidates, a:context], a:source)
    endif

    unlet l:Filter
  endfor

  return candidates
endfunction"}}}

function! unite#helper#get_source_args(sources) "{{{
  return map(copy(a:sources),
        \ 'type(v:val) == type([]) ? [v:val[0], v:val[1:]] : [v:val, []]')
endfunction"}}}

function! unite#helper#choose_window() "{{{
  " Create key table.
  let keys = {}
  for [key, number] in items(g:unite_quick_match_table)
    let keys[number] = key
  endfor

  " Save statusline.
  let save_statuslines = map(unite#helper#get_choose_windows(),
        \ "[v:val, getbufvar(winbufnr(v:val), '&statusline')]")

  try
    let winnr_save = winnr()
    for [winnr, statusline] in save_statuslines
      noautocmd execute winnr.'wincmd w'
      let &l:statusline =
            \ repeat(' ', winwidth(0)/2-len(winnr())).get(keys, winnr()-1, 0)
      redraw
    endfor

    noautocmd execute winnr_save.'wincmd w'
    redraw

    while 1
      echohl PreProc
      echon 'choose > '
      echohl Normal

      let num = get(g:unite_quick_match_table,
            \ nr2char(getchar()), 0) + 1
      if num < 0 || winbufnr(num) > 0
        return num
      endif

      echo ''
    endwhile
  finally
    echo ''

    let winnr_save = winnr()
    for [winnr, statusline] in save_statuslines
      noautocmd execute winnr.'wincmd w'
      let &l:statusline = statusline
      redraw
    endfor

    noautocmd execute winnr_save.'wincmd w'
    redraw
  endtry
endfunction"}}}

function! unite#helper#get_choose_windows() "{{{
  return filter(range(1, winnr('$')), "v:val != winnr()
        \ && !getwinvar(v:val, '&previewwindow')
        \ && (getwinvar(v:val, '&buftype') !~# 'nofile'
        \   || getwinvar(v:val, '&buftype') =~# 'acwrite')
        \ && !getwinvar(v:val, '&filetype') !=# 'qf'")
endfunction"}}}

function! unite#helper#get_buffer_directory(bufnr) "{{{
  let filetype = getbufvar(a:bufnr, '&filetype')
  if filetype ==# 'vimfiler'
    let dir = getbufvar(a:bufnr, 'vimfiler').current_dir
  elseif filetype ==# 'vimshell'
    let dir = getbufvar(a:bufnr, 'vimshell').current_dir
  elseif filetype ==# 'vinarise'
    let dir = getbufvar(a:bufnr, 'vinarise').current_dir
  else
    let path = unite#util#substitute_path_separator(bufname(a:bufnr))
    let dir = unite#util#path2directory(path)
  endif

  return dir
endfunction"}}}

function! unite#helper#cursor_prompt() "{{{
  " Move to prompt linenr.
  let unite = unite#get_current_unite()
  call cursor((unite.context.prompt_direction ==# 'below' ?
        \ line('$') : unite.init_prompt_linenr), 0)
endfunction"}}}

function! unite#helper#skip_prompt() "{{{
  " Skip prompt linenr.
  let unite = unite#get_current_unite()
  if line('.') == unite.prompt_linenr
    call cursor(line('.') + (unite.context.prompt_direction
          \ ==# 'below' ? -1 : 1), 1)
  endif
endfunction"}}}

if unite#util#has_lua()
  function! unite#helper#paths2candidates(paths) "{{{
    let candidates = []
  lua << EOF
do
  local paths = vim.eval('a:paths')
  local candidates = vim.eval('candidates')
  for path in paths() do
    local candidate = vim.dict()
    candidate.word = path
    candidate.action__path = path
    candidates:add(candidate)
  end
end
EOF

    return candidates
  endfunction"}}}
else
  function! unite#helper#paths2candidates(paths) "{{{
    return map(copy(a:paths), "{
          \ 'word' : v:val,
          \ 'action__path' : v:val,
          \ }")
  endfunction"}}}
endif

function! unite#helper#get_candidate_directory(candidate) "{{{
  return has_key(a:candidate, 'action__directory') ?
        \ a:candidate.action__directory :
        \ unite#util#path2directory(a:candidate.action__path)
endfunction"}}}

function! unite#helper#is_prompt(line) "{{{
  let prompt_linenr = unite#get_current_unite().prompt_linenr
  let context = unite#get_context()
  return (context.prompt_direction ==# 'below' && a:line >= prompt_linenr)
        \ || (context.prompt_direction !=# 'below' && a:line <= prompt_linenr)
endfunction"}}}

function! unite#helper#join_targets(targets) "{{{
  return join(map(copy(a:targets),
        \    "unite#util#escape_shell(
        \               substitute(v:val, '/$', '', ''))"))
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
