"=============================================================================
" FILE: view.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 13 Jan 2014.
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

function! unite#view#_redraw_candidates(...) "{{{
  let is_gather_all = get(a:000, 0, 0)

  call unite#view#_resize_window()

  let candidates = unite#candidates#gather(is_gather_all)

  let modifiable_save = &l:modifiable
  setlocal modifiable

  let lines = unite#view#_convert_lines(candidates)
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
function! unite#view#_redraw_line(...) "{{{
  let prompt_linenr = unite#get_current_unite().prompt_linenr
  let linenr = a:0 > 0 ? a:1 : line('.')
  if linenr ==# prompt_linenr
    let linenr += 1
  endif

  if linenr <= prompt_linenr || &filetype !=# 'unite'
    " Ignore.
    return
  endif

  let modifiable_save = &l:modifiable
  setlocal modifiable

  let candidate = unite#get_unite_candidates()[linenr -
        \ (prompt_linenr+1)]
  call setline(linenr, unite#view#_convert_lines([candidate])[0])

  let &l:modifiable = modifiable_save
endfunction"}}}
function! unite#view#_quick_match_redraw(quick_match_table) "{{{
  let modifiable_save = &l:modifiable
  setlocal modifiable

  call setline(unite#get_current_unite().prompt_linenr+1,
        \ unite#view#_convert_lines(
        \ unite#get_current_unite().current_candidates,
        \ a:quick_match_table))
  redraw

  let &l:modifiable = modifiable_save
endfunction"}}}

function! unite#view#_redraw(is_force, winnr, is_gather_all) "{{{
  if unite#util#is_cmdwin()
    return
  endif

  if a:winnr > 0
    " Set current unite.
    let unite = getbufvar(winbufnr(a:winnr), 'unite')
    let unite_save = unite#variables#current_unite()
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

    let input = unite#helper#get_input()
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
      call unite#candidates#_recache(input, a:is_force)
    endif

    let unite.last_input = input

    " Redraw.
    call unite#view#_redraw_candidates(is_gather_all)
    let unite.context.is_redraw = 0
  finally
    if a:winnr > 0
      if unite.prompt_linenr != line_save
        " Updated.
        normal! G
      endif

      " Restore current unite.
      call unite#set_current_unite(unite_save)
      execute winnr_save 'wincmd w'
    endif
  endtry

  if context.auto_preview
    call unite#view#_do_auto_preview()
  endif
  if context.auto_highlight
    call unite#view#_do_auto_highlight()
  endif
endfunction"}}}

function! unite#view#_set_highlight() "{{{
  let unite = unite#get_current_unite()

  " Set highlight.
  let match_prompt = escape(unite.prompt, '\/*~.^$[]')
  silent! syntax clear uniteInputPrompt
  execute 'syntax match uniteInputPrompt'
        \ '/^'.match_prompt.'/ contained'

  let marked_icon = unite#util#escape_pattern(g:unite_marked_icon)
  execute 'syntax region uniteMarkedLine start=/^'.
        \ marked_icon.'/ end=''$'' keepend'

  let candidate_icon = unite#util#escape_pattern(g:unite_candidate_icon)
  execute 'syntax region uniteNonMarkedLine start=/^'.
        \ candidate_icon.' / end=''$'' keepend'.
        \ ' contains=uniteCandidateMarker,'.
        \ 'uniteCandidateSourceName'
  execute 'syntax match uniteCandidateMarker /^'.
        \ candidate_icon.' / contained'

  execute 'syntax match uniteInputLine'
        \ '/\%'.unite.prompt_linenr.'l.*/'
        \ 'contains=uniteInputPrompt,uniteInputPromptError,'.
        \ 'uniteInputCommand'

  silent! syntax clear uniteCandidateSourceName
  if unite.max_source_name > 0
    syntax match uniteCandidateSourceName
          \ /\%3c[[:alnum:]_\/-]\+/ contained
  else
    execute 'syntax match uniteCandidateSourceName /^'.
          \ candidate_icon.' / contained'
  endif

  " Set syntax.
  let syntax = {}
  for source in filter(copy(unite.sources), 'v:val.syntax != ""')
    " Skip previous syntax
    if has_key(syntax, source.name)
      continue
    endif
    let syntax[source.name] = 1

    let name = unite.max_source_name > 0 ?
          \ unite#helper#convert_source_name(source.name) : ''

    execute 'highlight default link'
          \ source.syntax g:unite_abbr_highlight

    execute printf('syntax match %s "^['.g:unite_candidate_icon.' ] %s" '.
          \ 'nextgroup='.source.syntax.
          \ ' keepend contains=uniteCandidateMarker,%s',
          \ 'uniteSourceLine__'.source.syntax,
          \ (name == '' ? '' : name . '\>'),
          \ (name == '' ? '' : 'uniteCandidateSourceName')
          \ )

    call unite#helper#call_hook([source], 'on_syntax')
  endfor

  call s:set_syntax()
endfunction"}}}

function! unite#view#_resize_window() "{{{
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
    let max_len = unite.prompt_linenr + len(unite.candidates)
    silent! execute 'resize' min([max_len, context.winheight])
    if line('.') <= winheight(0)
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

function! unite#view#_convert_lines(candidates, ...) "{{{
  let quick_match_table = get(a:000, 0, {})

  let unite = unite#get_current_unite()
  let context = unite.context
  let [max_width, max_source_name] =
        \ unite#helper#adjustments(winwidth(0)-1, unite.max_source_name, 2)
  if unite.max_source_name == 0
    let max_width -= 1
  endif

  " Create key table.
  let keys = {}
  for [key, number] in items(quick_match_table)
    let keys[number] = key . '|'
  endfor

  return map(copy(a:candidates),
        \ "(v:val.is_dummy ? '  ' :
        \   v:val.unite__is_marked ? g:unite_marked_icon . ' ' :
        \   empty(quick_match_table) ? g:unite_candidate_icon . ' ' :
        \   get(keys, v:key, '  '))
        \ . (unite.max_source_name == 0 ? ''
        \   : unite#util#truncate(unite#helper#convert_source_name(
        \     (v:val.is_dummy ? '' : v:val.source)), max_source_name))
        \ . unite#util#truncate_wrap(v:val.unite__abbr, " . max_width
        \    .  ", (context.truncate ? 0 : max_width/2), '..')")
endfunction"}}}

function! unite#view#_do_auto_preview() "{{{
  let unite = unite#get_current_unite()

  if unite.preview_candidate == unite#helper#get_current_candidate()
    return
  endif

  let unite.preview_candidate = unite#helper#get_current_candidate()

  call unite#action#do('preview', [], {})

  " Restore window size.
  let context = unite#get_context()
  if s:has_preview_window()
    call unite#view#_resize_window()
  endif
endfunction"}}}
function! unite#view#_do_auto_highlight() "{{{
  let unite = unite#get_current_unite()

  if unite.highlight_candidate == unite#helper#get_current_candidate()
    return
  endif
  let unite.highlight_candidate = unite#helper#get_current_candidate()

  call unite#action#do('highlight', [], {})
endfunction"}}}

function! unite#view#_switch_unite_buffer(buffer_name, context) "{{{
  " Search unite window.
  let winnr = unite#helper#get_unite_winnr(a:buffer_name)
  if !a:context.no_split && winnr > 0
    silent execute winnr 'wincmd w'
    return
  endif

  " Search unite buffer.
  let bufnr = unite#helper#get_unite_bufnr(a:buffer_name)

  if !a:context.no_split && !a:context.unite__direct_switch
    " Split window.
    execute a:context.direction ((bufnr > 0) ?
          \ ((a:context.vertical) ? 'vsplit' : 'split') :
          \ ((a:context.vertical) ? 'vnew' : 'new'))
  endif

  if bufnr > 0
    silent noautocmd execute bufnr 'buffer'
  else
    if bufname('%') == ''
      noautocmd silent enew
    endif
    silent! noautocmd edit `=a:context.real_buffer_name`
  endif

  call unite#handlers#_on_bufwin_enter(bufnr('%'))
  doautocmd WinEnter
  doautocmd BufWinEnter
endfunction"}}}

function! unite#view#_close(buffer_name)  "{{{
  let buffer_name = a:buffer_name
  if buffer_name !~ '@\d\+$'
    " Add postfix.
    let prefix = '[unite] - '
    let prefix .= buffer_name
    let buffer_name .= unite#helper#get_postfix(
          \ prefix, 0, tabpagebuflist(tabpagenr()))
  endif

  " Search unite window.
  let quit_winnr = unite#helper#get_unite_winnr(a:buffer_name)

  if quit_winnr > 0
    " Quit unite buffer.
    silent execute quit_winnr 'wincmd w'
    call unite#force_quit_session()
  endif

  return quit_winnr > 0
endfunction"}}}

function! unite#view#_init_cursor() "{{{
  let unite = unite#get_current_unite()
  let context = unite.context

  let positions = unite#custom#get_profile(
        \ unite.profile_name, 'unite__save_pos')
  let key = unite#loaded_source_names_string()
  let is_restore = has_key(positions, key) && context.select == 0 &&
        \   positions[key].candidate ==#
        \     unite#helper#get_current_candidate(positions[key].pos[1])

  if context.start_insert && !context.auto_quit
    let unite.is_insert = 1

    if is_restore
      " Restore position.
      call setpos('.', positions[key].pos)
      startinsert
    else
      call cursor(unite.prompt_linenr, 0)
      startinsert!
    endif

    setlocal modifiable
  else
    let unite.is_insert = 0

    if is_restore
      " Restore position.
      call setpos('.', positions[key].pos)
    else
      call cursor(unite#helper#get_current_candidate_linenr(0), 0)
    endif

    normal! 0
    stopinsert
  endif

  if line('.') <= winheight(0)
    normal! zb
  endif

  if context.select != 0
    " Select specified candidate.
    call cursor(unite#helper#get_current_candidate_linenr(
          \ context.select), 0)
  elseif context.input == '' && context.log
    call unite#view#_redraw_candidates(1)
  endif

  if context.no_focus
    if winbufnr(winnr('#')) > 0
      wincmd p
    else
      execute bufwinnr(unite.prev_bufnr).'wincmd w'
    endif
  endif

  if context.quick_match
    " Move to prompt linenr.
    call cursor(unite.prompt_linenr, 0)

    call unite#mappings#_quick_match(0)
  endif
endfunction"}}}

function! unite#view#_quit(is_force, ...)  "{{{
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
          \ 'candidate' : unite#helper#get_current_candidate(),
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
      close!
      if unite.winnr != winnr()
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
        noautocmd pclose!

      endif
    endif

    call s:clear_previewed_buffer_list()

    if winnr('$') != 1 && !unite.context.temporary
          \ && winnr('$') == unite.winmax
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

" Message output.
function! unite#view#_print_error(message) "{{{
  let message = s:msg2list(a:message)
  let unite = unite#get_current_unite()
  if !empty(unite)
    let unite.err_msgs += message
  endif
  for mes in message
    echohl WarningMsg | echomsg mes | echohl None
  endfor
endfunction"}}}
function! unite#view#_print_source_error(message, source_name) "{{{
  call unite#view#_print_error(
        \ map(copy(s:msg2list(a:message)),
        \   "printf('[%s] %s', a:source_name, v:val)"))
endfunction"}}}
function! unite#view#_print_message(message) "{{{
  let context = unite#get_context()
  if get(context, 'silent', 0)
    return
  endif

  let unite = unite#get_current_unite()
  let message = s:msg2list(a:message)
  if !empty(unite)
    let unite.msgs += message
  endif
  echohl Comment | call s:redraw_echo(message[: &cmdheight-1]) | echohl None
endfunction"}}}
function! unite#view#_print_source_message(message, source_name) "{{{
  call unite#view#_print_message(
        \ map(copy(s:msg2list(a:message)),
        \    "printf('[%s] %s', a:source_name, v:val)"))
endfunction"}}}
function! unite#view#_clear_message() "{{{
  let unite = unite#get_current_unite()
  let unite.msgs = []
  redraw
endfunction"}}}

function! unite#view#_get_status_string() "{{{
  return !exists('b:unite') ? '' : ((b:unite.is_async ? '[async] ' : '') .
        \ join(unite#helper#loaded_source_names_with_args(), ', '))
endfunction"}}}

function! unite#view#_add_previewed_buffer_list(bufnr) "{{{
  let unite = unite#get_current_unite()
  call add(unite.previewd_buffer_list, a:bufnr)
endfunction"}}}
function! unite#view#_remove_previewed_buffer_list(bufnr) "{{{
  let unite = unite#get_current_unite()
  call filter(unite.previewd_buffer_list, 'v:val != a:bufnr')
endfunction"}}}

function! s:clear_previewed_buffer_list() "{{{
  let unite = unite#get_current_unite()
  for bufnr in unite.previewd_buffer_list
    if buflisted(bufnr)
      silent execute 'bdelete!' bufnr
    endif
  endfor

  let unite.previewd_buffer_list = []
endfunction"}}}

function! s:set_syntax() "{{{
  let unite = unite#get_current_unite()

  " Set syntax.
  for source in filter(copy(unite.sources), 'v:val.syntax != ""')
    silent! execute 'syntax clear' source.syntax
    execute 'syntax region' source.syntax
          \ 'start=// end=/$/ keepend contained'
  endfor
endfunction"}}}

function! s:has_preview_window() "{{{
  return len(filter(range(1, winnr('$')),
        \    'getwinvar(v:val, "&previewwindow")')) > 0
endfunction"}}}

function! s:msg2list(expr) "{{{
  return type(a:expr) ==# type([]) ? a:expr : split(a:expr, '\n')
endfunction"}}}

function! s:redraw_echo(expr) "{{{
  if has('vim_starting')
    echo join(s:msg2list(a:expr), "\n")
    return
  endif

  let msg = s:msg2list(a:expr)
  let height = max([1, &cmdheight])
  for i in range(0, len(msg)-1, height)
    redraw
    echo join(msg[i : i+height-1], "\n")
  endfor
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
