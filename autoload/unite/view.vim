"=============================================================================
" FILE: view.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 11 Jun 2013.
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

  let candidates = unite#gather_candidates(is_gather_all)

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
  let linenr = a:0 > 0 ? a:1 : line('.')
  if linenr <= unite#get_current_unite().prompt_linenr || &filetype !=# 'unite'
    " Ignore.
    return
  endif

  let modifiable_save = &l:modifiable
  setlocal modifiable

  let candidate = unite#get_unite_candidates()[linenr -
        \ (unite#get_current_unite().prompt_linenr+1)]
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

    let input = unite#get_input()
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
      call unite#_recache_candidates(input, a:is_force)
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

  execute 'syntax match uniteInputLine'
        \ '/\%'.unite.prompt_linenr.'l.*/'
        \ 'contains=uniteInputPrompt,uniteInputPromptError,uniteInputSpecial'

  silent! syntax clear uniteCandidateSourceName
  if unite.max_source_name > 0
    syntax match uniteCandidateSourceName
          \ /\%3c[[:alnum:]_\/-]\+/ contained
  else
    syntax match uniteCandidateSourceName /^- / contained
  endif

  execute 'highlight default link uniteCandidateAbbr'
        \ g:unite_abbr_highlight

  " Set syntax.
  for source in filter(copy(unite.sources), 'v:val.syntax != ""')
    let name = unite.max_source_name > 0 ?
          \ unite#_convert_source_name(source.name) : ''

    execute 'highlight default link'
          \ source.syntax g:unite_abbr_highlight

    execute printf('syntax match %s "^[- ] %s" '.
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
    let max_len = unite.prompt_linenr + len(unite.current_candidates)
    execute 'resize' min([max_len, context.winheight])
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
        \   empty(quick_match_table) ? '- ' :
        \   get(keys, v:key, '  '))
        \ . (unite.max_source_name == 0 ? ''
        \   : unite#util#truncate(unite#_convert_source_name(
        \     (v:val.is_dummy ? '' : v:val.source)), max_source_name))
        \ . unite#util#truncate_wrap(v:val.unite__abbr, " . max_width
        \    .  ", (context.truncate ? 0 : max_width/2), '..')")
endfunction"}}}

function! s:set_syntax() "{{{
  let unite = unite#get_current_unite()
  let source_padding = 3

  let abbr_head = unite.max_source_name+source_padding
  silent! syntax clear uniteCandidateAbbr
  execute 'syntax region uniteCandidateAbbr' 'start=/\%'
        \ .(abbr_head).'c/ end=/$/ keepend contained'

  " Set syntax.
  for source in filter(copy(unite.sources), 'v:val.syntax != ""')
    silent! execute 'syntax clear' source.syntax
    execute 'syntax region' source.syntax
          \ 'start=// end=/$/ keepend contained'
  endfor
endfunction"}}}

function! unite#view#_do_auto_preview() "{{{
  let unite = unite#get_current_unite()

  if unite.preview_candidate == unite#get_current_candidate()
    return
  endif

  let unite.preview_candidate = unite#get_current_candidate()

  call unite#clear_previewed_buffer_list()
  call unite#mappings#do_action('preview', [], {})

  " Restore window size.
  let context = unite#get_context()
  if s:has_preview_window()
    call unite#view#_resize_window()
  endif
endfunction"}}}
function! unite#view#_do_auto_highlight() "{{{
  let unite = unite#get_current_unite()

  if unite.highlight_candidate == unite#get_current_candidate()
    return
  endif
  let unite.highlight_candidate = unite#get_current_candidate()

  call unite#mappings#do_action('highlight', [], {})
endfunction"}}}

function! s:has_preview_window() "{{{
  return len(filter(range(1, winnr('$')),
        \    'getwinvar(v:val, "&previewwindow")')) > 0
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
