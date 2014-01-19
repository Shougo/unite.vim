"=============================================================================
" FILE: helpers.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 19 Jan 2014.
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

function! unite#helper#get_substitute_input(input) "{{{
  let input = a:input

  let unite = unite#get_current_unite()
  let substitute_patterns = reverse(unite#util#sort_by(
        \ values(unite#custom#get_profile(unite.profile_name,
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

  let inputs = unite#helper#get_substitute_input_loop(input, substitute_patterns)

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

function! unite#helper#parse_options(args) "{{{
  let args = []
  let options = {}
  for arg in split(a:args, '\%(\\\@<!\s\)\+')
    let arg = substitute(arg, '\\\( \)', '\1', 'g')

    let arg_key = substitute(arg, '=\zs.*$', '', '')
    let matched_list = filter(copy(unite#variables#options()),
          \  'v:val ==# arg_key')
    for option in matched_list
      let key = substitute(substitute(option, '-', '_', 'g'), '=$', '', '')[1:]
      let options[key] = (option =~ '=$') ?
            \ arg[len(option) :] : 1
    endfor

    if empty(matched_list)
      call add(args, arg)
    endif
  endfor

  return [args, options]
endfunction"}}}
function! unite#helper#parse_options_args(args) "{{{
  let _ = []
  let [args, options] = unite#helper#parse_options(a:args)
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

function! unite#helper#get_marked_candidates() "{{{
  return unite#util#sort_by(filter(copy(unite#get_unite_candidates()),
        \ 'v:val.unite__is_marked'), 'v:val.unite__marked_time')
endfunction"}}}

function! unite#helper#get_input() "{{{
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

function! unite#helper#get_source_names(sources) "{{{
  return map(map(copy(a:sources),
        \ "type(v:val) == type([]) ? v:val[0] : v:val"),
        \ "type(v:val) == type('') ? v:val : v:val.name")
endfunction"}}}

function! unite#helper#get_postfix(prefix, is_create, ...) "{{{
  let buffers = get(a:000, 0, range(1, bufnr('$')))
  let buflist = sort(filter(map(buffers,
        \ 'bufname(v:val)'), 'stridx(v:val, a:prefix) >= 0'))
  if empty(buflist)
    return ''
  endif

  return a:is_create ? '@'.(matchstr(buflist[-1], '@\zs\d\+$') + 1)
        \ : matchstr(buflist[-1], '@\d\+$')
endfunction"}}}

function! unite#helper#convert_source_name(source_name) "{{{
  let context = unite#get_context()
  return !context.short_source_names ? a:source_name :
        \ a:source_name !~ '\A'  ? a:source_name[:1] :
        \ substitute(a:source_name, '\a\zs\a\+', '', 'g')
endfunction"}}}

function! unite#helper#loaded_source_names_with_args() "{{{
  return map(copy(unite#loaded_sources_list()), "
        \ join(insert(filter(copy(v:val.args),
        \  'type(v:val) <= 1'),
        \   unite#helper#convert_source_name(v:val.name)), ':')
        \ . (v:val.unite__orig_len_candidates == 0 ? '' :
        \      v:val.unite__orig_len_candidates ==
        \            v:val.unite__len_candidates ?
        \            '(' .  v:val.unite__len_candidates . ')' :
        \      printf('(%s/%s)', v:val.unite__len_candidates,
        \      v:val.unite__orig_len_candidates))
        \ ")
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
function! unite#helper#get_unite_bufnr(buffer_name) "{{{
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

function! unite#helper#get_current_candidate(...) "{{{
  let linenr = a:0 >= 1? a:1 : line('.')
  let num = linenr <= unite#get_current_unite().prompt_linenr ?
        \ 0 : linenr - (unite#get_current_unite().prompt_linenr+1)

  return get(unite#get_unite_candidates(), num, {})
endfunction"}}}

function! unite#helper#get_current_candidate_linenr(num) "{{{
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

function! unite#helper#call_filter(filter_name, candidates, context) "{{{
  let filter = unite#get_filters(a:filter_name)
  if empty(filter)
    return a:candidates
  endif

  return filter.filter(a:candidates, a:context)
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


let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
