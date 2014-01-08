"=============================================================================
" FILE: start.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 Jan 2014.
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

function! unite#start#standard(sources, ...) "{{{
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
      return unite#start#resume(context.buffer_name, context)
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
  catch /^unite.vim: Invalid /
    call unite#print_error('[unite.vim] ' . v:exception)
    return
  endtry

  " Caching.
  let current_unite = unite#variables#current_unite()
  let current_unite.last_input = context.input
  let current_unite.input = context.input
  call unite#candidates#_recache(context.input, context.is_redraw)

  if !current_unite.is_async &&
        \ (context.immediately || context.no_empty) "{{{
    let candidates = unite#candidates#gather()

    if empty(candidates)
      " Ignore.
      call unite#variables#disable_current_unite()
      return
    elseif context.immediately && len(candidates) == 1
      " Immediately action.
      call unite#action#do(
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

function! unite#start#script(sources, ...) "{{{
  " Start unite from script.

  let context = get(a:000, 0, {})

  let context.script = 1

  return &filetype == 'unite' ?
        \ unite#start#temporary(a:sources, context) :
        \ unite#start#standard(a:sources, context)
endfunction"}}}

function! unite#start#temporary(sources, ...) "{{{
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
  let context.is_restart = 0
  let context.quick_match = 0

  if context.script
    " Set buffer-name automatically.
    let context.buffer_name = unite#helper#get_source_names(a:sources)
  endif

  let buffer_name = get(a:000, 1,
        \ matchstr(context.buffer_name, '^\S\+')
        \ . '-' . len(context.old_buffer_info))

  let context.buffer_name = buffer_name

  let unite_save = unite#get_current_unite()

  let cwd = getcwd()

  call unite#start#standard(a:sources, context)

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

function! unite#start#vimfiler_check_filetype(sources, ...) "{{{
  let context = get(a:000, 0, {})
  let context = unite#init#_context(context,
        \ unite#helper#get_source_names(a:sources))
  let context.unite__is_vimfiler = 1
  let context.unite__is_interactive = 0
  if !has_key(context, 'vimfiler__is_dummy')
    let context.vimfiler__is_dummy = 0
  endif

  try
    call unite#init#_current_unite(a:sources, context)
  catch /^unite.vim: Invalid /
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

function! unite#start#get_candidates(sources, ...) "{{{
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

function! unite#start#get_vimfiler_candidates(sources, ...) "{{{
  let unite_save = unite#get_current_unite()

  try
    let unite = unite#get_current_unite()
    let context = get(a:000, 0, {})
    let context = unite#init#_context(context,
          \ unite#helper#get_source_names(a:sources))
    let context.no_buffer = 1
    let context.unite__is_vimfiler = 1
    let context.unite__is_interactive = 0
    if !has_key(context, 'vimfiler__is_dummy')
      let context.vimfiler__is_dummy = 0
    endif

    let candidates = s:get_candidates(a:sources, context)

    " Converts utf-8-mac to the current encoding.
    if unite#util#is_mac() && has('iconv')
      for item in filter(copy(candidates),
            \ "v:val.action__path =~# '[^\\x00-\\x7f]'")
        let item.action__path = unite#util#iconv(
              \ item.action__path, 'utf-8-mac', &encoding)
        let item.action__directory = unite#util#iconv(
              \ item.action__directory, 'utf-8-mac', &encoding)
        let item.word = unite#util#iconv(item.word, 'utf-8-mac', &encoding)
        let item.abbr = unite#util#iconv(item.abbr, 'utf-8-mac', &encoding)
        let item.vimfiler__filename = unite#util#iconv(
              \ item.vimfiler__filename, 'utf-8-mac', &encoding)
        let item.vimfiler__abbr = unite#util#iconv(
              \ item.vimfiler__abbr, 'utf-8-mac', &encoding)
      endfor
    endif
  finally
    call unite#set_current_unite(unite_save)
  endtry

  return candidates
endfunction"}}}

function! unite#start#resume(buffer_name, ...) "{{{
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
  let unite = b:unite
  let unite.winnr = winnr
  if !context.unite__direct_switch
    let unite.win_rest_cmd = win_rest_cmd
  endif
  let unite.redrawtime_save = &redrawtime
  let unite.access_time = localtime()
  let unite.context = context
  let unite.is_finalized = 0
  let unite.preview_candidate = {}
  let unite.highlight_candidate = {}

  call unite#set_current_unite(unite)

  call unite#view#_init_cursor()
endfunction"}}}

function! unite#start#resume_from_temporary(context)  "{{{
  if empty(a:context.old_buffer_info)
    return
  endif

  call unite#handlers#_on_buf_unload(a:context.buffer_name)

  let unite_save = unite#get_current_unite()

  " Resume unite buffer.
  let buffer_info = a:context.old_buffer_info[0]
  call unite#start#resume(buffer_info.buffer_name,
        \ {'unite__direct_switch' : 1})
  call setpos('.', buffer_info.pos)
  let a:context.old_buffer_info = a:context.old_buffer_info[1:]

  " Overwrite unite.
  let unite = unite#get_current_unite()
  let unite.prev_bufnr = unite_save.prev_bufnr
  let unite.prev_winnr = unite_save.prev_winnr

  call unite#redraw()
endfunction"}}}

function! unite#start#complete(sources, ...) "{{{
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

function! s:get_candidates(sources, context) "{{{
  try
    let current_unite = unite#init#_current_unite(a:sources, a:context)
  catch /^unite.vim: Invalid /
    return []
  endtry

  " Caching.
  let current_unite.last_input = a:context.input
  let current_unite.input = a:context.input
  call unite#set_current_unite(current_unite)
  call unite#set_context(a:context)

  call unite#variables#enable_current_unite()

  call unite#candidates#_recache(a:context.input, a:context.is_redraw)

  let candidates = []
  for source in current_unite.sources
    if !empty(source.unite__candidates)
      let candidates += source.unite__candidates
    endif
  endfor

  return candidates
endfunction"}}}

function! s:get_resume_buffer(buffer_name) "{{{
  let buffer_name = a:buffer_name
  if buffer_name !~ '@\d\+$'
    " Add postfix.
    let prefix = '[unite] - '
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

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
