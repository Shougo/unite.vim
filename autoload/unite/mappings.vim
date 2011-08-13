"=============================================================================
" FILE: mappings.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 13 Aug 2011.
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

" Define default mappings.
function! unite#mappings#define_default_mappings()"{{{
  " Plugin keymappings"{{{
  nnoremap <silent><buffer> <Plug>(unite_exit)  :<C-u>call <SID>exit()<CR>
  nnoremap <silent><buffer> <Plug>(unite_choose_action)  :<C-u>call <SID>choose_action()<CR>
  nnoremap <expr><buffer> <Plug>(unite_insert_enter)  <SID>insert_enter('i')
  nnoremap <expr><buffer> <Plug>(unite_insert_head)   <SID>insert_enter('0'.(len(unite#get_current_unite().prompt)-1).'li')
  nnoremap <expr><buffer> <Plug>(unite_append_enter)  <SID>insert_enter('a')
  nnoremap <expr><buffer> <Plug>(unite_append_end)    <SID>insert_enter('A')
  nnoremap <silent><buffer> <Plug>(unite_toggle_mark_current_candidate)  :<C-u>call <SID>toggle_mark()<CR>
  nnoremap <silent><buffer> <Plug>(unite_redraw)  :<C-u>call <SID>redraw()<CR>
  nnoremap <silent><buffer> <Plug>(unite_rotate_next_source)  :<C-u>call <SID>rotate_source(1)<CR>
  nnoremap <silent><buffer> <Plug>(unite_rotate_previous_source)  :<C-u>call <SID>rotate_source(0)<CR>
  nnoremap <silent><buffer> <Plug>(unite_print_candidate)  :<C-u>call <SID>print_candidate()<CR>
  nnoremap <buffer><expr> <Plug>(unite_cursor_top)  unite#get_current_unite().prompt_linenr.'G0z.'
  nnoremap <buffer><expr> <Plug>(unite_loop_cursor_down)  <SID>loop_cursor_down()
  nnoremap <buffer><expr> <Plug>(unite_loop_cursor_up)  <SID>loop_cursor_up()
  nnoremap <silent><buffer> <Plug>(unite_quick_match_default_action)  :<C-u>call <SID>quick_match()<CR>
  nnoremap <silent><buffer> <Plug>(unite_input_directory)   :<C-u>call <SID>input_directory()<CR>
  nnoremap <silent><buffer><expr> <Plug>(unite_do_default_action)   unite#do_action(unite#get_current_unite().context.default_action)
  nnoremap <silent><buffer> <Plug>(unite_delete_backward_path)  :<C-u>call <SID>normal_delete_backward_path()<CR>
  nnoremap <silent><buffer> <Plug>(unite_restart)  :<C-u>call <SID>restart()<CR>
  nnoremap <buffer><silent> <Plug>(unite_toggle_mark_all_candidates)  :<C-u>call <SID>toggle_mark_candidates(0, len(unite#get_unite_candidates()) - 1)<CR>
  nnoremap <buffer><silent> <Plug>(unite_toggle_transpose_window)  :<C-u>call <SID>toggle_transpose_window()<CR>
  nnoremap <buffer><silent> <Plug>(unite_toggle_auto_preview)  :<C-u>call <SID>toggle_auto_preview()<CR>
  nnoremap <buffer><silent> <Plug>(unite_narrowing_path)  :<C-u>call <SID>narrowing_path()<CR>
  nnoremap <buffer><silent> <Plug>(unite_narrowing_input_history)  :<C-u>call <SID>narrowing_input_history()<CR>

  vnoremap <buffer><silent> <Plug>(unite_toggle_mark_selected_candidates)  :<C-u>call <SID>toggle_mark_candidates(getpos("'<")[1] - unite#get_current_unite().prompt_linenr-1, getpos("'>")[1] - unite#get_current_unite().prompt_linenr - 1)<CR>

  inoremap <silent><buffer> <Plug>(unite_exit)  <ESC>:<C-u>call <SID>exit()<CR>
  inoremap <silent><expr><buffer> <Plug>(unite_insert_leave)
        \ (line('.') <= unite#get_current_unite().prompt_linenr) ?
        \ "\<ESC>0".(unite#get_current_unite().prompt_linenr+1)."G" : "\<ESC>0"
  inoremap <silent><expr><buffer> <Plug>(unite_delete_backward_char)
        \ col('.') <= (len(unite#get_current_unite().prompt)+1) ?
        \ "\<C-o>:\<C-u>call \<SID>exit()\<Cr>" : "\<C-h>"
  inoremap <expr><buffer> <Plug>(unite_delete_backward_line)
        \ repeat("\<C-h>", col('.')-(len(unite#get_current_unite().prompt)+1))
  inoremap <expr><buffer> <Plug>(unite_delete_backward_word)
        \ col('.') <= (len(unite#get_current_unite().prompt)+1) ? '' : "\<C-w>"
  inoremap <expr><buffer> <Plug>(unite_delete_backward_path)
        \ col('.') <= (len(unite#get_current_unite().prompt)+1) ? '' : <SID>delete_backward_path()
  inoremap <expr><buffer> <Plug>(unite_select_next_line)
        \ pumvisible() ? "\<C-n>" : <SID>loop_cursor_down()
  inoremap <expr><buffer> <Plug>(unite_select_previous_line)
        \ pumvisible() ? "\<C-p>" : <SID>loop_cursor_up()
  inoremap <expr><buffer> <Plug>(unite_select_next_page)
        \ pumvisible() ? "\<PageDown>" : repeat("\<Down>", winheight(0))
  inoremap <expr><buffer> <Plug>(unite_select_previous_page)
        \ pumvisible() ? "\<PageUp>" : repeat("\<Up>", winheight(0))
  inoremap <silent><buffer> <Plug>(unite_toggle_mark_current_candidate)  <C-o>:<C-u>call <SID>toggle_mark()<CR>
  inoremap <silent><buffer> <Plug>(unite_choose_action)  <C-o>:<C-u>call <SID>choose_action()<CR>
  inoremap <silent><buffer> <Plug>(unite_move_head)  <C-o>:<C-u>call <SID>insert_head()<CR>
  inoremap <silent><buffer> <Plug>(unite_quick_match_default_action)  <C-o>:<C-u>call <SID>quick_match()<CR>
  inoremap <silent><buffer> <Plug>(unite_input_directory)   <C-o>:<C-u>call <SID>input_directory()<CR>
  inoremap <silent><buffer><expr> <Plug>(unite_do_default_action)   unite#do_action(unite#get_current_unite().context.default_action)
  inoremap <buffer><silent> <Plug>(unite_toggle_transpose_window)  <C-o>:<C-u>call <SID>toggle_transpose_window()<CR>
  inoremap <buffer><silent> <Plug>(unite_toggle_auto_preview)  <C-o>:<C-u>call <SID>toggle_auto_preview()<CR>
  inoremap <buffer><silent> <Plug>(unite_narrowing_path)  <C-o>:<C-u>call <SID>narrowing_path()<CR>
  inoremap <buffer><silent> <Plug>(unite_narrowing_input_history)  <C-o>:<C-u>call <SID>narrowing_input_history()<CR>
  "}}}

  if exists('g:unite_no_default_keymappings') && g:unite_no_default_keymappings
    return
  endif

  " Normal mode key-mappings.
  nmap <buffer> i         <Plug>(unite_insert_enter)
  nmap <buffer> I         <Plug>(unite_insert_head)
  nmap <buffer> a         <Plug>(unite_append_enter)
  nmap <buffer> A         <Plug>(unite_append_end)
  nmap <buffer> q         <Plug>(unite_exit)
  nmap <buffer> <CR>      <Plug>(unite_do_default_action)
  nmap <buffer> <Space>   <Plug>(unite_toggle_mark_current_candidate)
  nmap <buffer> <Tab>     <Plug>(unite_choose_action)
  nmap <buffer> <C-n>     <Plug>(unite_rotate_next_source)
  nmap <buffer> <C-p>     <Plug>(unite_rotate_previous_source)
  nmap <buffer> <C-g>     <Plug>(unite_print_candidate)
  nmap <buffer> <C-l>     <Plug>(unite_redraw)
  nmap <buffer> gg        <Plug>(unite_cursor_top)
  nmap <buffer> j         <Plug>(unite_loop_cursor_down)
  nmap <buffer> <Down>         <Plug>(unite_loop_cursor_down)
  nmap <buffer> k         <Plug>(unite_loop_cursor_up)
  nmap <buffer> <Up>         <Plug>(unite_loop_cursor_up)
  nmap <buffer> <C-h>     <Plug>(unite_delete_backward_path)
  nmap <buffer> <C-r>     <Plug>(unite_restart)
  nmap <buffer> *         <Plug>(unite_toggle_mark_all_candidates)

  nnoremap <silent><buffer><expr> d   unite#smart_map('d', unite#do_action('delete'))
  nnoremap <silent><buffer><expr> b   unite#smart_map('b', unite#do_action('bookmark'))
  nnoremap <silent><buffer><expr> e   unite#smart_map('e', unite#do_action('edit'))
  nnoremap <silent><buffer><expr> p   unite#do_action('preview')
  nmap <silent><buffer><expr> x       unite#smart_map('x', "\<Plug>(unite_quick_match_default_action)")

  " Visual mode key-mappings.
  xmap <buffer> <Space>   <Plug>(unite_toggle_mark_selected_candidates)

  " Insert mode key-mappings.
  imap <buffer> <TAB>     <Plug>(unite_choose_action)
  imap <buffer> <C-n>     <Plug>(unite_select_next_line)
  imap <buffer> <Down>     <Plug>(unite_select_next_line)
  imap <buffer> <C-p>     <Plug>(unite_select_previous_line)
  imap <buffer> <Up>     <Plug>(unite_select_previous_line)
  imap <buffer> <C-f>     <Plug>(unite_select_next_page)
  imap <buffer> <C-b>     <Plug>(unite_select_previous_page)
  imap <buffer> <CR>      <Plug>(unite_do_default_action)
  imap <buffer> <C-h>     <Plug>(unite_delete_backward_char)
  imap <buffer> <BS>      <Plug>(unite_delete_backward_char)
  imap <buffer> <C-u>     <Plug>(unite_delete_backward_line)
  imap <buffer> <C-w>     <Plug>(unite_delete_backward_word)
  imap <buffer> <C-a>     <Plug>(unite_move_head)
  imap <buffer> <Home>    <Plug>(unite_move_head)

  inoremap <silent><buffer><expr> d         unite#smart_map('d', unite#do_action('delete'))
  inoremap <silent><buffer><expr> e         unite#smart_map('e', unite#do_action('edit'))
  imap <silent><buffer><expr> <Space>       unite#smart_map(' ', "\<Plug>(unite_toggle_mark_current_candidate)")
  imap <silent><buffer><expr> x             unite#smart_map('x', "\<Plug>(unite_quick_match_default_action)")
endfunction"}}}

function! unite#mappings#narrowing(word)"{{{
  setlocal modifiable
  let l:unite = unite#get_current_unite()
  let l:unite.input = escape(a:word, ' *')
  call setline(unite#get_current_unite().prompt_linenr, unite#get_current_unite().prompt . unite#get_current_unite().input)
  call unite#redraw()
  if l:unite.is_insert
    execute unite#get_current_unite().prompt_linenr
    startinsert!
  else
    execute unite#get_current_unite().prompt_linenr
    normal! 0z.
  endif
endfunction"}}}
function! unite#mappings#do_action(action_name, ...)"{{{
  let l:candidates = a:0 > 0 ? a:1 : unite#get_marked_candidates()

  let l:unite = unite#get_current_unite()
  if empty(l:candidates)
    let l:num = (line('.') <= l:unite.prompt_linenr) ? 0 :
          \ (line('.') - (l:unite.prompt_linenr + 1))
    if type(l:num) == type(0)
      if line('$') - (l:unite.prompt_linenr + 1) < l:num
        " Ignore.
        return
      endif

      let l:candidates = [ unite#get_current_candidate() ]
    else
      let l:candidates = [ l:num ]
    endif
  endif

  call filter(l:candidates, '!v:val.is_dummy')
  if empty(l:candidates)
    return
  endif

  " Clear mark flag.
  for l:candidate in l:candidates
    let l:candidate.unite__is_marked = 0
  endfor

  let l:action_tables = s:get_action_table(a:action_name, l:candidates)

  let l:context = l:unite.context

  " Execute action.
  let l:is_redraw = 0
  let l:is_quit = 0
  for l:table in l:action_tables
    " Check quit flag.
    if l:table.action.is_quit
      call unite#quit_session()
      let l:is_quit = 1
    endif

    call l:table.action.func(l:table.candidates)

    " Check invalidate cache flag.
    if l:table.action.is_invalidate_cache
      for l:source_name in l:table.source_names
        call unite#invalidate_cache(l:source_name)
      endfor

      let l:is_redraw = 1
    endif
  endfor

  if l:is_redraw
    call unite#force_redraw()
    normal! zz
  endif
endfunction"}}}

function! s:get_action_table(action_name, candidates)"{{{
  let l:action_tables = []
  let Self = unite#get_self_functions()[-1]
  for l:candidate in a:candidates
    let l:action_table = unite#get_action_table(l:candidate.source, l:candidate.kind, Self)

    let l:action_name =
          \ a:action_name ==# 'default' ?
          \ unite#get_default_action(l:candidate.source, l:candidate.kind)
          \ : a:action_name

    if !has_key(l:action_table, l:action_name)
      call unite#util#print_error(l:candidate.abbr . '(' . l:candidate.source . ')')
      call unite#util#print_error('No such action : ' . l:action_name)
      return []
    endif

    let l:action = l:action_table[l:action_name]

    " Check selectable flag.
    if !l:action.is_selectable && len(a:candidates) > 1
      call unite#util#print_error(l:candidate.abbr . '(' . l:candidate.source . ')')
      call unite#util#print_error('Not selectable action : ' . l:action_name)
      return []
    endif

    let l:found = 0
    for l:table in l:action_tables
      if l:action == l:table.action
        " Add list.
        call add(l:table.candidates, l:candidate)
        call add(l:table.source_names, l:candidate.source)
        let l:found = 1
        break
      endif
    endfor

    if !l:found
      " Add action table.
      call add(l:action_tables, {
            \ 'action' : l:action,
            \ 'source_names' : [l:candidate.source],
            \ 'candidates' : (!l:action.is_selectable ? l:candidate : [l:candidate]),
            \ })
    endif
  endfor

  return l:action_tables
endfunction"}}}
function! s:get_actions(candidates)"{{{
  let Self = unite#get_self_functions()[-1]
  let l:actions = unite#get_action_table(a:candidates[0].source, a:candidates[0].kind, Self)
  if len(a:candidates) > 1
    for l:candidate in a:candidates
      let l:action_table = unite#get_action_table(l:candidate.source, l:candidate.kind, Self)
      " Filtering unique items and check selectable flag.
      call filter(l:actions, 'has_key(l:action_table, v:key)
            \ && l:action_table[v:key].is_selectable')
    endfor
  endif

  return l:actions
endfunction"}}}

" key-mappings functions.
function! s:exit()"{{{
  call unite#force_quit_session()
endfunction"}}}
function! s:restart()"{{{
  let l:unite = unite#get_current_unite()
  let l:context = l:unite.context
  let l:sources = map(deepcopy(l:unite.sources), 'empty(v:val.args) ? v:val.name : [v:val.name, v:val.args]')
  call unite#force_quit_session()
  call unite#start(l:sources, l:context)
endfunction"}}}
function! s:delete_backward_path()"{{{
  let l:unite    = unite#get_current_unite()
  let l:prompt   = l:unite.prompt
  let l:input    = getline(l:unite.prompt_linenr)[len(l:prompt):]
  let l:startcol = match(l:input, '[^/]*.$') + 1 + len(l:prompt)
  let l:endcol   = virtcol('.')
  return repeat("\<C-h>", (l:startcol < l:endcol ? l:endcol - l:startcol : 0))
endfunction"}}}
function! s:normal_delete_backward_path()"{{{
  let l:modifiable_save = &l:modifiable
  setlocal modifiable
  call setline(unite#get_current_unite().prompt_linenr,
        \ substitute(getline(unite#get_current_unite().prompt_linenr)[len(unite#get_current_unite().prompt):],
        \                 '[^/]*.$', '', ''))
  call unite#redraw()
  let &l:modifiable = l:modifiable_save
endfunction"}}}
function! s:toggle_mark()"{{{
  let l:candidate = unite#get_current_candidate()
  let l:candidate.unite__is_marked = !l:candidate.unite__is_marked
  let l:candidate.unite__marked_time = localtime()

  let l:prompt_linenr = unite#get_current_unite().prompt_linenr
  if line('.') <= l:prompt_linenr
    call cursor(l:prompt_linenr+1, 0)
  endif
  call unite#redraw_line()

  normal! j
endfunction"}}}
function! s:toggle_mark_candidates(start, end)"{{{
  if a:start < 0 || a:end >= len(unite#get_unite_candidates())
    " Ignore.
    return
  endif

  let l:cnt = a:start
  while l:cnt <= a:end
    let l:candidate = unite#get_unite_candidates()[l:cnt]
    let l:candidate.unite__is_marked = !l:candidate.unite__is_marked
    let l:candidate.unite__marked_time = localtime()

    call unite#redraw_line(l:cnt + unite#get_current_unite().prompt_linenr+1)

    let l:cnt += 1
  endwhile
endfunction"}}}
function! s:choose_action()"{{{
  let l:unite = unite#get_current_unite()
  if line('$') < (l:unite.prompt_linenr+1)
        \ || l:unite.context.temporary
    " Ignore.
    return
  endif

  let l:candidates = unite#get_marked_candidates()
  if empty(l:candidates)
    let l:candidates = [ unite#get_current_candidate() ]
  endif

  call filter(l:candidates, '!v:val.is_dummy')
  if empty(l:candidates)
    return
  endif

  call unite#define_source(s:source_action)

  call unite#start_temporary([['action'] + l:candidates], {}, 'action')
endfunction"}}}
function! s:insert_enter(key)"{{{
  setlocal modifiable
  return a:key
endfunction"}}}
function! s:insert_head()"{{{
  let l:pos = getpos('.')
  let l:pos[2] = len(unite#get_current_unite().prompt)+1
  call setpos('.', l:pos)
  call s:insert_enter(col('.'))
endfunction"}}}
function! s:redraw()"{{{
  call unite#clear_message()

  let l:unite = unite#get_current_unite()
  call unite#force_redraw()
endfunction"}}}
function! s:rotate_source(is_next)"{{{
  let l:unite = unite#get_current_unite()

  for l:source in unite#loaded_sources_list()
    let l:unite.sources = a:is_next ?
          \ add(l:unite.sources[1:], l:unite.sources[0]) :
          \ insert(l:unite.sources[: -2], l:unite.sources[-1])

    if !empty(l:unite.sources[0].unite__candidates)
      break
    endif
  endfor

  call unite#redraw_status()
  call unite#redraw_candidates()
endfunction"}}}
function! s:print_candidate()"{{{
  if line('.') <= unite#get_current_unite().prompt_linenr
    " Ignore.
    return
  endif

  let l:candidate = unite#get_current_candidate()
  echo l:candidate.word
endfunction"}}}
function! s:insert_selected_candidate()"{{{
  if line('.') <= unite#get_current_unite().prompt_linenr
    " Ignore.
    return
  endif

  let l:candidate = unite#get_current_candidate()
  call unite#mappings#narrowing(l:candidate.word)
endfunction"}}}
function! s:quick_match()"{{{
  let l:unite = unite#get_current_unite()

  if line('$') < (l:unite.prompt_linenr+1)
    call unite#util#print_error('Candidate is nothing.')
    return
  elseif !empty(unite#get_marked_candidates())
    call unite#util#print_error('Marked candidates is detected.')
    return
  endif

  call unite#quick_match_redraw()

  if mode() !~# '^c'
    echo 'Input quick match key: '
  endif
  let l:char = ''

  while l:char == ''
    let l:char = nr2char(getchar())
  endwhile

  redraw
  echo ''

  call unite#redraw_candidates()

  if has_key(g:unite_quick_match_table, l:char)
        \ && g:unite_quick_match_table[l:char] < len(l:unite.candidates)
    call unite#mappings#do_action(l:unite.context.default_action,
          \ [ l:unite.candidates[g:unite_quick_match_table[l:char]] ])
  else
    call unite#util#print_error('Canceled.')
  endif
endfunction"}}}
function! s:input_directory()"{{{
  let l:path = unite#substitute_path_separator(input('Input narrowing directory: ', unite#get_input(), 'dir'))
  let l:path = l:path.(l:path == '' || l:path =~ '/$' ? '' : '/')
  call unite#mappings#narrowing(l:path)
endfunction"}}}
function! s:loop_cursor_down()"{{{
  let l:is_insert = mode() ==# 'i'
  let l:prompt_linenr = unite#get_current_unite().prompt_linenr

  if line('.') == line('$')
    " Loop.
    if l:is_insert
      return "\<C-Home>\<End>".repeat("\<Down>", l:prompt_linenr-1)."\<End>"
    else
      return l:prompt_linenr.'G0z.'
    endif
  endif

  let l:num = (line('.') <= l:prompt_linenr) ? 0 :
        \ (line('.') - (l:prompt_linenr + 1))
  let l:count = 1

  while 1
    let l:candidate = get(unite#get_unite_candidates(), l:num + l:count, {})
    if !empty(l:candidate) && l:candidate.is_dummy
      let l:count += 1
      continue
    endif

    break
  endwhile

  if l:is_insert && line('.') == l:prompt_linenr
    let l:count += 1
  endif

  if l:is_insert
    return "\<Home>" . repeat("\<Down>", l:count)
  else
    return '0' . repeat('j', l:count)
  endif
endfunction"}}}
function! s:loop_cursor_up()"{{{
  let l:is_insert = mode() ==# 'i'
  let l:prompt_linenr = unite#get_current_unite().prompt_linenr

  if line('.') <= l:prompt_linenr
    " Loop.
    if l:is_insert
      return "\<C-End>\<Home>"
    else
      return 'G'
    endif
  endif

  let l:num = (line('.') <= l:prompt_linenr) ? 0 :
        \ (line('.') - (l:prompt_linenr + 1))

  let l:count = 1

  if l:is_insert && line('.') == l:prompt_linenr + 2
    let l:count += 1
  endif

  while 1
    let l:candidate = get(unite#get_unite_candidates(), l:num - l:count, {})
    if l:num >= l:count && !empty(l:candidate) && l:candidate.is_dummy
      let l:count += 1
      continue
    endif

    break
  endwhile

  if l:num < 0
    if l:is_insert
      return "\<C-Home>\<End>".repeat("\<Down>", l:prompt_linenr)."\<Home>"
    else
      return l:prompt_linenr.'G0z.'
    endif
  endif

  if l:is_insert
    if line('.') <= l:prompt_linenr + 2
      return repeat("\<Up>", l:count) . "\<End>"
    else
      return "\<Home>" . repeat("\<Up>", l:count)
    endif
  else
    return '0' . repeat('k', l:count)
  endif
endfunction"}}}
function! s:toggle_transpose_window()"{{{
  " Toggle vertical/horizontal view.
  let l:context = unite#get_context()
  let l:direction = l:context.vertical ?
        \ (l:context.direction ==# 'topleft' ? 'K' : 'J') :
        \ (l:context.direction ==# 'topleft' ? 'H' : 'L')

  execute 'silent wincmd ' . l:direction

  let l:context.vertical = !l:context.vertical
endfunction"}}}
function! s:toggle_auto_preview()"{{{
  let l:context = unite#get_context()
  let l:context.auto_preview = !l:context.auto_preview

  if !l:context.auto_preview
        \ && !unite#get_current_unite().has_preview_window
    " Close preview window.
    pclose!
  endif
endfunction"}}}
function! s:narrowing_path()"{{{
  if line('.') <= unite#get_current_unite().prompt_linenr
    " Ignore.
    return
  endif

  let l:candidate = unite#get_current_candidate()
  call unite#mappings#narrowing(has_key(l:candidate, 'action__path')? l:candidate.action__path : l:candidate.word)
endfunction"}}}
function! s:narrowing_input_history()"{{{
  let l:unite = unite#get_current_unite()

  call unite#define_source(s:source_input)

  call unite#start_temporary(['history/input'],
        \ { 'old_source_names_string' : unite#loaded_source_names_string() },
        \ 'history/input')
endfunction"}}}

function! unite#mappings#complete_actions(arglead, cmdline, cursorpos)"{{{
  return filter(keys(s:actions), printf('stridx(v:val, %s) == 0', string(a:arglead)))
endfunction"}}}

" Unite action source."{{{
let s:source_action = {
      \ 'name' : 'action',
      \ 'description' : 'candidates from unite action',
      \ 'action_table' : {},
      \ 'hooks' : {},
      \ 'default_action' : 'do',
      \ 'syntax' : 'uniteSource__Action',
      \}

function! s:source_action.hooks.on_close(args, context)"{{{
  call unite#undef_source('action')
endfunction"}}}
function! s:source_action.hooks.on_syntax(args, context)"{{{
  syntax match uniteSource__ActionDescriptionLine / -- .*$/ contained containedin=uniteSource__Action
  syntax match uniteSource__ActionDescription /.*$/ contained containedin=uniteSource__ActionDescriptionLine
  syntax match uniteSource__ActionMarker / -- / contained containedin=uniteSource__ActionDescriptionLine
  highlight default link uniteSource__ActionMarker Special
  highlight default link uniteSource__ActionDescription Comment
endfunction"}}}

function! s:source_action.gather_candidates(args, context)"{{{
  let l:candidates = copy(a:args)

  " Print candidates.
  call unite#print_message(map(copy(l:candidates), '"[action] candidates: ".v:val.abbr."(".v:val.source.")"'))

  " Process Alias.
  let l:actions = s:get_actions(l:candidates)
  let l:alias_table = unite#get_alias_table(
        \ l:candidates[0].source, l:candidates[0].kind)
  for [l:alias_name, l:action_name] in items(l:alias_table)
    if has_key(l:actions, l:alias_name)
      let l:actions[l:action_name] = copy(l:actions[l:action_name])
      let l:actions[l:action_name].name = l:alias_name
    endif
  endfor

  " Uniq.
  let l:uniq_actions = {}
  for l:action in values(l:actions)
    if !has_key(l:action, l:action.name)
      let l:uniq_actions[l:action.name] = l:action
    endif
  endfor

  let l:max = max(map(values(l:uniq_actions), 'len(v:val.name)'))

  return sort(map(values(l:uniq_actions), '{
        \   "word": v:val.name,
        \   "abbr": printf("%-' . l:max . 's -- %s", v:val.name, v:val.description),
        \   "kind": "common",
        \   "source__candidates": l:candidates,
        \   "action__action": l:actions[v:val.name],
        \ }'), 's:compare_word')
endfunction"}}}

function! s:compare_word(i1, i2)
  return (a:i1.word ># a:i2.word) ? 1 : -1
endfunction

" Actions"{{{
let s:action_table = {}

let s:action_table.do = {
      \ 'description' : 'do action',
      \ }
function! s:action_table.do.func(candidate)"{{{
  call unite#mappings#do_action(a:candidate.word, a:candidate.source__candidates)
endfunction"}}}

let s:source_action.action_table['*'] = s:action_table

unlet s:action_table
"}}}
"}}}

" Unite history/input source."{{{
let s:source_input = {
      \ 'name' : 'history/input',
      \ 'description' : 'candidates from unite input history',
      \ 'action_table' : {},
      \ 'hooks' : {},
      \ 'default_action' : 'narrow',
      \ 'syntax' : 'uniteSource__Action',
      \}

function! s:source_input.hooks.on_close(args, context)"{{{
  call unite#undef_source('history/input')
endfunction"}}}

function! s:source_input.gather_candidates(args, context)"{{{
  let l:context = unite#get_context()
  let l:inputs = unite#get_buffer_name_option(
        \ l:context.old_buffer_info[0].buffer_name, 'unite__inputs')
  let l:key = l:context.old_source_names_string
  if !has_key(l:inputs, l:key)
    return []
  endif

  return map(copy(l:inputs[l:key]), '{
        \ "word" : v:val
        \ }')
endfunction"}}}

" Actions"{{{
let s:action_table = {}

let s:action_table.narrow = {
      \ 'description' : 'narrow by history',
      \ 'is_quit' : 0,
      \ }
function! s:action_table.narrow.func(candidate)"{{{
  call unite#force_quit_session()
  call unite#mappings#narrowing(a:candidate.word)
endfunction"}}}

let s:action_table.delete = {
      \ 'description' : 'delete from input history',
      \ 'is_selectable' : 1,
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ }
function! s:action_table.delete.func(candidates)"{{{
  let l:context = unite#get_context()
  let l:inputs = unite#get_buffer_name_option(
        \ l:context.old_buffer_info[0].buffer_name, 'unite__inputs')
  let l:key = l:context.old_source_names_string
  if !has_key(l:inputs, l:key)
    return
  endif

  for l:candidate in a:candidates
    call filter(l:inputs[l:key], 'v:val !=# l:candidate.word')
  endfor
endfunction"}}}

let s:source_input.action_table['*'] = s:action_table

unlet s:action_table
"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
