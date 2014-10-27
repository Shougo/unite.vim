"=============================================================================
" FILE: view.vim
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

function! unite#view#_redraw_prompt() "{{{
  let unite = unite#get_current_unite()
  if unite.prompt_linenr < 0
    return
  endif

  let modifiable_save = &l:modifiable
  try
    setlocal modifiable
    call setline(unite.prompt_linenr,
          \ unite.prompt . unite.context.input)

    silent! syntax clear uniteInputLine
    execute 'syntax match uniteInputLine'
          \ '/\%'.unite.prompt_linenr.'l.*/'
          \ 'contains=uniteInputPrompt,uniteInputPromptError,'.
          \ 'uniteInputCommand'
  finally
    let &l:modifiable = modifiable_save
  endtry
endfunction"}}}
function! unite#view#_remove_prompt() "{{{
  let unite = unite#get_current_unite()
  if unite.prompt_linenr == 0
    return
  endif

  let modifiable_save = &l:modifiable
  try
    setlocal modifiable

    silent! execute (unite.prompt_linenr).'delete _'
    silent! syntax clear uniteInputLine
  finally
    let &l:modifiable = modifiable_save
  endtry

  call cursor(unite.init_prompt_linenr, 0)
  let unite.prompt_linenr = 0
endfunction"}}}
function! unite#view#_redraw_candidates(...) "{{{
  let is_gather_all = get(a:000, 0, 0)

  call unite#view#_resize_window()

  let unite = unite#get_current_unite()
  let context = unite.context

  let candidates = unite#candidates#gather(is_gather_all)
  if context.prompt_direction ==# 'below'
    let unite.init_prompt_linenr = len(candidates) + 1
  endif

  let pos = getpos('.')
  let modifiable_save = &l:modifiable
  try
    setlocal modifiable

    if context.prompt_direction !=# 'below'
      call unite#view#_redraw_prompt()
    endif

    call unite#view#_set_candidates_lines(
          \ unite#view#_convert_lines(candidates))

    if context.prompt_direction ==# 'below' && unite.prompt_linenr != 0
      if empty(candidates)
        let unite.prompt_linenr = 1
      else
        call append(unite.prompt_linenr, '')
        let unite.prompt_linenr += 1
      endif
      call unite#view#_redraw_prompt()
    endif

    let unite.current_candidates = candidates
  finally
    let &l:modifiable = l:modifiable_save
    if pos != getpos('.')
      call setpos('.', pos)
    endif
  endtry

  if context.input == '' && context.log
        \ || context.prompt_direction ==# 'below'
    " Move to bottom.
    call cursor(line('$'), 0)
  endif

  if context.prompt_direction ==# 'below' && mode() ==# 'i'
    call unite#view#_bottom_cursor()
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

  if &filetype !=# 'unite'
    " Ignore.
    return
  endif

  let modifiable_save = &l:modifiable
  setlocal modifiable

  let candidate = unite#helper#get_current_candidate(linenr)
  call setline(linenr, unite#view#_convert_lines([candidate])[0])

  let &l:modifiable = modifiable_save
endfunction"}}}
function! unite#view#_quick_match_redraw(quick_match_table) "{{{
  call unite#view#_set_candidates_lines(
        \ unite#view#_convert_lines(
        \   unite#get_current_unite().current_candidates,
        \   a:quick_match_table))
  redraw
endfunction"}}}
function! unite#view#_set_candidates_lines(lines) "{{{
  let unite = unite#get_current_unite()
  let modifiable_save = &l:modifiable
  try
    let pos = getpos('.')
    setlocal modifiable

    " Clear candidates
    if unite.context.prompt_direction ==# 'below'
      silent! execute '1,'.(unite.prompt_linenr-1).'$delete _'
      call setline(1, a:lines)
      let start = (unite.prompt_linenr == 0) ?
            \ len(a:lines)+1 : unite.prompt_linenr+1
      silent! execute start.',$delete _'
    else
      silent! execute (unite.prompt_linenr+1).',$delete _'
      call setline(unite.prompt_linenr+1, a:lines)
    endif
  finally
    call setpos('.', pos)
    let &l:modifiable = modifiable_save
  endtry
endfunction"}}}

function! unite#view#_redraw(is_force, winnr, is_gather_all) "{{{
  if unite#util#is_cmdwin()
    return
  endif

  let unite_save = unite#variables#current_unite()
  let winnr_save = winnr()
  if a:winnr > 0
    " Set current unite.
    let unite = getbufvar(winbufnr(a:winnr), 'unite')

    execute a:winnr 'wincmd w'
  endif

  let pos = getpos('.')
  let unite = unite#get_current_unite()
  let context = unite.context

  try
    if &filetype !=# 'unite'
      return
    endif

    if !context.is_redraw
      let context.is_redraw = a:is_force
    endif

    if context.is_redraw
      call unite#clear_message()
    endif

    let input = unite#helper#get_input(1)
    if !context.is_redraw
          \ && input ==# unite.last_input
          \ && context.path ==# unite.last_path
          \ && !unite.is_async
          \ && !context.unite__is_resize
          \ && !a:is_gather_all
      return
    endif

    let is_gather_all = a:is_gather_all || context.log

    if context.is_redraw
          \ || input !=# unite.last_input
          \ || context.path !=# unite.last_path
          \ || unite.is_async
          \ || empty(unite.args)
      " Recaching.
      call unite#candidates#_recache(input, a:is_force)
    endif

    let unite.last_input = input
    let unite.last_path = context.path

    " Redraw.
    call unite#view#_redraw_candidates(is_gather_all)
    call unite#view#_change_highlight()
    let unite.context.is_redraw = 0
  finally
    if empty(unite.args) && getpos('.') !=# pos
      call setpos('.', pos)

      if context.prompt_direction ==# 'below'
        call cursor(line('$'), 0)
        call unite#view#_bottom_cursor()
      endif
    endif

    if a:winnr > 0
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

function! unite#view#_set_syntax() "{{{
  syntax clear

  syntax match uniteQuickMatchMarker /^.|/ contained
  syntax match uniteInputCommand /\\\@<! :\S\+/ contained

  let unite = unite#get_current_unite()

  " Set highlight.
  let match_prompt = escape(unite.prompt, '\/*~.^$[]')
  execute 'syntax match uniteInputPrompt'
        \ '/^'.match_prompt.'/ contained'

  let candidate_icon = unite#util#escape_pattern(
        \ unite.context.candidate_icon)
  execute 'syntax region uniteNonMarkedLine start=/^'.
        \ candidate_icon.' / end=''$'' keepend'.
        \ ' contains=uniteCandidateMarker,'.
        \ 'uniteCandidateSourceName'
  execute 'syntax match uniteCandidateMarker /^'.
        \ candidate_icon.' / contained'

  let marked_icon = unite#util#escape_pattern(
        \ unite.context.marked_icon)
  execute 'syntax region uniteMarkedLine start=/^'.
        \ marked_icon.'/ end=''$'' keepend'

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
          \ source.syntax unite.context.abbr_highlight

    execute printf('syntax match %s "^\%(['.
          \ unite.context.candidate_icon.' ] \|.|\)%s" '.
          \ 'nextgroup='.source.syntax. ' keepend
          \ contains=uniteCandidateMarker,uniteQuickMatchMarker,%s',
          \ 'uniteSourceLine__'.source.syntax,
          \ (name == '' ? '' : name . '\>'),
          \ (name == '' ? '' : 'uniteCandidateSourceName')
          \ )

    call unite#helper#call_hook([source], 'on_syntax')
  endfor

  call s:set_syntax()

  call unite#view#_redraw_prompt()

  let b:current_syntax = 'unite'
endfunction"}}}
function! unite#view#_change_highlight()  "{{{
  if &filetype !=# 'unite'
        \ || !exists('b:current_syntax')
    return
  endif

  let unite = unite#get_current_unite()
  if empty(unite)
    return
  endif

  call unite#view#_set_cursor_line()

  silent! syntax clear uniteCandidateInputKeyword

  syntax case ignore

  for input_str in unite#helper#get_substitute_input(
        \ unite#helper#get_input())
    if input_str == ''
      continue
    endif

    let input_list = map(filter(split(input_str, '\\\@<! '),
          \ "v:val !~ '^[!:]'"),
          \ "substitute(v:val, '\\\\ ', ' ', 'g')")

    for source in filter(copy(unite.sources), "v:val.syntax != ''")
      for matcher in filter(copy(map(filter(
            \ copy(source.matchers),
            \ "type(v:val) == type('')"), 'unite#get_filters(v:val)')),
            \ "has_key(v:val, 'pattern')")
        let patterns = map(copy(input_list),
              \ "escape(matcher.pattern(v:val), '/~')")

        silent! execute 'syntax match uniteCandidateInputKeyword'
              \ '/'.join(patterns, '\|').'/'
              \ 'containedin='.source.syntax.' contained'
      endfor
    endfor
  endfor

  syntax case match
endfunction"}}}

function! unite#view#_resize_window() "{{{
  if &filetype !=# 'unite'
    return
  endif

  let context = unite#get_context()
  let unite = unite#get_current_unite()

  if (winheight(0) + &cmdheight + 2 >= &lines
        \ && !context.vertical)
        \ || !context.resize
    " Cannot resize.
    let context.unite__is_resize = 0
    return
  endif

  if context.unite__old_winwidth != 0
        \ && context.unite__old_winheight != 0
        \ && winheight(0) != context.unite__old_winheight
        \ && winwidth(0) != context.unite__old_winwidth
    " Disabled resize.
    let context.winwidth = 0
    let context.winheight = 0
    let context.unite__is_resize = 1
    return
  endif

  if context.auto_resize
    " Auto resize.
    let max_len = unite.candidates_len
    if unite.prompt_linenr > 0
      let max_len += 1
    endif

    let winheight = winheight(0)

    silent! execute 'resize' min([max_len, context.winheight])

    if line('.') == unite.prompt_linenr
          \ || line('$') < winheight
      call unite#view#_bottom_cursor()
    endif

    let context.unite__is_resize = winheight != winheight(0)
  elseif context.vertical
        \ && context.unite__old_winwidth  == 0
    execute 'vertical resize' context.winwidth

    let context.unite__is_resize = 1
  elseif !context.vertical
        \ && (context.unite__old_winheight == 0 || context.auto_preview)
    execute 'resize' context.winheight

    let context.unite__is_resize = 1
  else
    let context.unite__is_resize = 0
  endif

  let context.unite__old_winheight = winheight(winnr())
  let context.unite__old_winwidth = winwidth(winnr())
endfunction"}}}

" @vimlint(EVL102, 1, l:max_source_name)
" @vimlint(EVL102, 1, l:context)
function! unite#view#_convert_lines(candidates, ...) "{{{
  let quick_match_table = get(a:000, 0, {})

  let unite = unite#get_current_unite()
  let context = unite#get_context()
  let [max_width, max_source_name] = unite#helper#adjustments(
        \ winwidth(0), unite.max_source_name, 2)

  " Create key table.
  let keys = {}
  for [key, number] in items(quick_match_table)
    let keys[number] = key . '|'
  endfor

  return map(copy(a:candidates),
        \ "(v:val.is_dummy ? '  ' :
        \   v:val.unite__is_marked ? context.marked_icon . ' ' :
        \   empty(quick_match_table) ? context.candidate_icon . ' ' :
        \   get(keys, v:key, '  '))
        \ . (unite.max_source_name == 0 ? ''
        \   : unite#util#truncate(unite#helper#convert_source_name(
        \     (v:val.is_dummy ? '' : v:val.source)), max_source_name))
        \ . unite#util#truncate_wrap(v:val.unite__abbr, " . max_width
        \    .  ", (context.truncate ? 0 : max_width/2), '..')")
endfunction"}}}
" @vimlint(EVL102, 0, l:max_source_name)
" @vimlint(EVL102, 0, l:context)

function! unite#view#_do_auto_preview() "{{{
  let unite = unite#get_current_unite()

  if unite.preview_candidate == unite#helper#get_current_candidate()
    return
  endif

  let unite.preview_candidate = unite#helper#get_current_candidate()

  call unite#action#do('preview', [], {})

  " Restore window size.
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
  if a:context.split && winnr > 0
    silent execute winnr 'wincmd w'
    return
  endif

  " Search unite buffer.
  let bufnr = unite#helper#get_unite_bufnr(a:buffer_name)

  if a:context.split && !a:context.unite__direct_switch
    " Split window.
    noautocmd execute a:context.direction ((bufnr > 0) ?
          \ ((a:context.vertical) ? 'vsplit' : 'split') :
          \ ((a:context.vertical) ? 'vnew' : 'new'))
  endif

  if bufnr > 0
    silent noautocmd execute bufnr 'buffer'
  else
    if bufname('%') == ''
      noautocmd silent enew
    endif
    silent! execute 'noautocmd edit'
          \ fnameescape(a:context.real_buffer_name)
  endif

  call unite#handlers#_on_bufwin_enter(bufnr('%'))
  doautocmd WinEnter
  doautocmd BufWinEnter
endfunction"}}}

function! unite#view#_close(buffer_name)  "{{{
  let buffer_name = a:buffer_name

  if buffer_name == ''
    " Use last unite buffer.
    if !exists('t:unite') ||
          \ !bufexists(t:unite.last_unite_bufnr)
      call unite#util#print_error('No unite buffer.')
      return
    endif

    let buffer_name = getbufvar(
          \ t:unite.last_unite_bufnr, 'unite').buffer_name
  endif

  " Search unite window.
  let quit_winnr = unite#helper#get_unite_winnr(buffer_name)

  if buffer_name !~ '@\d\+$'
    " Add postfix.
    let prefix = '[unite] - '
    let prefix .= buffer_name
    let buffer_name .= unite#helper#get_postfix(
          \ prefix, 0, tabpagebuflist(tabpagenr()))
  endif

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
  let is_restore = context.restore
        \ && has_key(positions, key) && context.select <= 0
        \ && positions[key].candidate ==#
        \     unite#helper#get_current_candidate(positions[key].pos[1])

  if context.start_insert && !context.auto_quit
    let unite.is_insert = 1

    if is_restore && context.resume
          \ && positions[key].pos[1] != unite.prompt_linenr
      " Restore position.
      call setpos('.', positions[key].pos)
      call cursor(0, 1)
      startinsert
    else
      call unite#helper#cursor_prompt()
      startinsert!
    endif
  else
    let unite.is_insert = 0

    if is_restore
      " Restore position.
      call setpos('.', positions[key].pos)
    else
      call unite#helper#cursor_prompt()
    endif

    call cursor(0, 1)
    stopinsert
  endif

  if context.select > 0
    " Select specified candidate.
    call cursor(unite#helper#get_current_candidate_linenr(
          \ context.select), 0)
  elseif context.input == '' && context.log
    call unite#view#_redraw_candidates(1)
  endif

  if context.quick_match
    call unite#helper#cursor_prompt()

    call unite#mappings#_quick_match(0)
  endif

  if line('.') <= winheight(0)
        \ || (context.prompt_direction ==# 'below'
        \     && (line('$') - line('.')) <= winheight(0))
    call unite#view#_bottom_cursor()
  endif

  if !context.focus
    if winbufnr(winnr('#')) > 0
      wincmd p
    else
      execute bufwinnr(unite.prev_bufnr).'wincmd w'
    endif
  endif

  let unite.prev_line = line('.')
  call unite#view#_set_cursor_line()
  call unite#handlers#_on_cursor_moved()
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

  " Clear mark.
  for source in unite#loaded_sources_list()
    for candidate in source.unite__cached_candidates
      let candidate.unite__is_marked = 0
    endfor
  endfor

  call unite#view#_save_position()

  if a:is_force || context.quit
    let bufname = bufname('%')

    if winnr('$') == 1 || !context.split
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
  endif

  " Restore unite.
  call unite#set_current_unite(unite_save)
endfunction"}}}

function! unite#view#_set_cursor_line() "{{{
  if !exists('b:current_syntax') || &filetype !=# 'unite'
    return
  endif

  let unite = unite#get_current_unite()
  let context = unite.context
  if !context.cursor_line
    return
  endif

  let prompt_linenr = unite.prompt_linenr

  call unite#view#_clear_match()

  if line('.') != prompt_linenr
    call unite#view#_match_line(context.cursor_line_highlight,
          \ line('.'), unite.match_id)
  elseif (context.prompt_direction !=# 'below'
          \   && line('$') == prompt_linenr)
          \ || (context.prompt_direction ==# 'below'
          \   && prompt_linenr == 1)
    call unite#view#_match_line('uniteError',
          \ prompt_linenr, unite.match_id)
  else
    call unite#view#_match_line(context.cursor_line_highlight,
          \ prompt_linenr+(context.prompt_direction ==#
          \                   'below' ? -1 : 1), unite.match_id)
  endif
  let unite.cursor_line_time = reltime()
endfunction"}}}

function! unite#view#_bottom_cursor() "{{{
  let pos = getpos('.')
  try
    normal! zb
  finally
    call setpos('.', pos)
  endtry
endfunction"}}}
function! unite#view#_clear_match() "{{{
  let unite = unite#get_current_unite()
  if unite.match_id > 0
    silent! call matchdelete(unite.match_id)
  endif
endfunction"}}}

function! unite#view#_save_position() "{{{
  let unite = b:unite
  let context = unite.context

  let key = unite#loaded_source_names_string()
  if key == ''
    return
  endif

  " Save position.
  let positions = unite#custom#get_profile(
        \ unite.profile_name, 'unite__save_pos')

  let positions[key] = {
        \ 'pos' : getpos('.'),
        \ 'candidate' : unite#helper#get_current_candidate(),
        \ }

  if context.input == ''
    return
  endif

  " Save input.
  let inputs = unite#custom#get_profile(
        \ unite.profile_name, 'unite__inputs')
  if !has_key(inputs, key)
    let inputs[key] = []
  endif
  call insert(filter(inputs[key],
        \ 'v:val !=# unite.context.input'), context.input)
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
  let unite = unite#get_current_unite()
  let message = s:msg2list(a:message)
  if !empty(unite)
    let unite.msgs += message
  endif

  if !get(context, 'silent', 0)
    echohl Comment | call unite#view#_redraw_echo(message[: &cmdheight-1]) | echohl None
  endif
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
function! unite#view#_redraw_echo(expr) "{{{
  if has('vim_starting')
    echo join(s:msg2list(a:expr), "\n")
    return
  endif

  let more_save = &more
  let showcmd_save = &showcmd
  let ruler_save = &ruler
  try
    set nomore
    set noshowcmd
    set noruler

    let msg = map(s:msg2list(a:expr), "unite#util#truncate_smart(
          \ v:val, &columns-1, &columns/2, '...')")
    let height = max([1, &cmdheight])
    for i in range(0, len(msg)-1, height)
      redraw
      echo join(msg[i : i+height-1], "\n")
    endfor
  finally
    let &more = more_save
    let &showcmd = showcmd_save
    let &ruler = ruler_save
  endtry
endfunction"}}}

function! unite#view#_match_line(highlight, line, id) "{{{
  return exists('*matchaddpos') ?
        \ matchaddpos(a:highlight, [a:line], 10, a:id) :
        \ matchadd(a:highlight, '^\%'.a:line.'l.*', 10, a:id)
endfunction"}}}

function! unite#view#_get_status_string() "{{{
  if !exists('b:unite')
    return ''
  endif

  let head = (b:unite.is_async ? '[async] ' : '') .
        \ join(unite#helper#loaded_source_names_with_args())
  let tail = b:unite.context.path != '' ? ' ['. b:unite.context.path.']' :
        \    (b:unite.is_async || get(b:unite.msgs, 0, '') == '') ? '' :
        \    ' |' . substitute(get(b:unite.msgs, 0, ''), '^\[.\{-}\]', '', '')
  let tail = unite#util#strwidthpart(tail,
        \ winwidth(0) - (unite#util#wcswidth('*unite* : ' . head) + 10))
  return head . tail
endfunction"}}}

function! unite#view#_add_previewed_buffer_list(bufnr) "{{{
  let unite = unite#get_current_unite()
  call add(unite.previewed_buffer_list, a:bufnr)
endfunction"}}}
function! unite#view#_remove_previewed_buffer_list(bufnr) "{{{
  let unite = unite#get_current_unite()
  call filter(unite.previewed_buffer_list, 'v:val != a:bufnr')
endfunction"}}}

function! unite#view#_preview_file(filename) "{{{
  let context = unite#get_context()
  if context.vertical_preview
    let unite_winwidth = winwidth(0)
    noautocmd silent execute 'vertical pedit!'
          \ fnameescape(a:filename)
    wincmd P
    let target_winwidth = (unite_winwidth + winwidth(0)) / 2
    execute 'wincmd p | vert resize ' . target_winwidth
  else
    noautocmd silent execute 'pedit!'
          \ fnameescape(a:filename)
  endif
endfunction"}}}

function! s:clear_previewed_buffer_list() "{{{
  let unite = unite#get_current_unite()
  for bufnr in unite.previewed_buffer_list
    if buflisted(bufnr)
      if bufnr == bufnr('%')
        call unite#util#alternate_buffer()
      endif
      silent execute 'bdelete!' bufnr
    endif
  endfor

  let unite.previewed_buffer_list = []
endfunction"}}}

function! s:set_syntax() "{{{
  let unite = unite#get_current_unite()

  " Set syntax.
  for source in filter(copy(unite.sources), 'v:val.syntax != ""')
    silent! execute 'syntax clear' source.syntax
    execute 'syntax region' source.syntax
          \ 'start=// end=/$/ keepend contained'
  endfor

  call unite#view#_change_highlight()
endfunction"}}}

function! s:has_preview_window() "{{{
  return len(filter(range(1, winnr('$')),
        \    'getwinvar(v:val, "&previewwindow")')) > 0
endfunction"}}}

function! s:msg2list(expr) "{{{
  return type(a:expr) ==# type([]) ? a:expr : split(a:expr, '\n')
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
