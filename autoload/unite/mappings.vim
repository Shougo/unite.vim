"=============================================================================
" FILE: mappings.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 04 Feb 2012.
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
  nnoremap <silent><buffer> <Plug>(unite_exit)
        \ :<C-u>call <SID>exit()<CR>
  nnoremap <silent><buffer> <Plug>(unite_all_exit)
        \ :<C-u>call <SID>all_exit()<CR>
  nnoremap <silent><buffer> <Plug>(unite_choose_action)
        \ :<C-u>call <SID>choose_action()<CR>
  nnoremap <expr><buffer> <Plug>(unite_insert_enter)
        \ <SID>insert_enter('i')
  nnoremap <expr><buffer> <Plug>(unite_insert_head)
        \ <SID>insert_enter('0'.(len(unite#get_current_unite().prompt)-1).'li')
  nnoremap <expr><buffer> <Plug>(unite_append_enter)
        \ <SID>insert_enter('a')
  nnoremap <expr><buffer> <Plug>(unite_append_end)
        \ <SID>insert_enter('A')
  nnoremap <silent><buffer> <Plug>(unite_toggle_mark_current_candidate)
        \ :<C-u>call <SID>toggle_mark()<CR>
  nnoremap <silent><buffer> <Plug>(unite_redraw)
        \ :<C-u>call <SID>redraw()<CR>
  nnoremap <silent><buffer> <Plug>(unite_rotate_next_source)
        \ :<C-u>call <SID>rotate_source(1)<CR>
  nnoremap <silent><buffer> <Plug>(unite_rotate_previous_source)
        \ :<C-u>call <SID>rotate_source(0)<CR>
  nnoremap <silent><buffer> <Plug>(unite_print_candidate)
        \ :<C-u>call <SID>print_candidate()<CR>
  nnoremap <buffer><expr> <Plug>(unite_cursor_top)
        \ unite#get_current_unite().prompt_linenr.'G0z.'
  nnoremap <buffer><expr> <Plug>(unite_loop_cursor_down)
        \ <SID>loop_cursor_down(0)
  nnoremap <buffer><expr> <Plug>(unite_loop_cursor_up)
        \ <SID>loop_cursor_up(0)
  nnoremap <buffer><expr> <Plug>(unite_skip_cursor_down)
        \ <SID>loop_cursor_down(1)
  nnoremap <buffer><expr> <Plug>(unite_skip_cursor_up)
        \ <SID>loop_cursor_up(1)
  nnoremap <silent><buffer> <Plug>(unite_quick_match_default_action)
        \ :<C-u>call unite#mappings#_quick_match(0)<CR>
  nnoremap <silent><buffer> <Plug>(unite_quick_match_choose_action)
        \ :<C-u>call unite#mappings#_quick_match(1)<CR>
  nnoremap <silent><buffer> <Plug>(unite_input_directory)
        \ :<C-u>call <SID>input_directory()<CR>
  nnoremap <silent><buffer><expr> <Plug>(unite_do_default_action)
        \ unite#do_action(unite#get_current_unite().context.default_action)
  nnoremap <silent><buffer> <Plug>(unite_delete_backward_path)
        \ :<C-u>call <SID>normal_delete_backward_path()<CR>
  nnoremap <silent><buffer> <Plug>(unite_restart)
        \ :<C-u>call <SID>restart()<CR>
  nnoremap <buffer><silent> <Plug>(unite_toggle_mark_all_candidates)
        \ :<C-u>call <SID>toggle_mark_candidates(0,
        \     len(unite#get_unite_candidates()) - 1)<CR>
  nnoremap <buffer><silent> <Plug>(unite_toggle_transpose_window)
        \ :<C-u>call <SID>toggle_transpose_window()<CR>
  nnoremap <buffer><silent> <Plug>(unite_toggle_auto_preview)
        \ :<C-u>call <SID>toggle_auto_preview()<CR>
  nnoremap <buffer><silent> <Plug>(unite_narrowing_path)
        \ :<C-u>call <SID>narrowing_path()<CR>
  nnoremap <buffer><silent> <Plug>(unite_narrowing_input_history)
        \ :<C-u>call <SID>narrowing_input_history()<CR>
  nnoremap <buffer><silent> <Plug>(unite_toggle_max_candidates)
        \ :<C-u>call <SID>toggle_max_candidates()<CR>
  nnoremap <buffer><silent> <Plug>(unite_quick_help)
        \ :<C-u>call <SID>quick_help()<CR>

  vnoremap <buffer><silent> <Plug>(unite_toggle_mark_selected_candidates)
        \ :<C-u>call <SID>toggle_mark_candidates(getpos("'<")[1]
        \  - unite#get_current_unite().prompt_linenr-1,
        \ getpos("'>")[1] - unite#get_current_unite().prompt_linenr - 1)<CR>

  inoremap <silent><buffer> <Plug>(unite_exit)
        \ <ESC>:<C-u>call <SID>exit()<CR>
  inoremap <silent><expr><buffer> <Plug>(unite_insert_leave)
        \ (line('.') <= unite#get_current_unite().prompt_linenr) ?
        \ "\<ESC>0".(unite#get_current_unite().prompt_linenr+1)."G" : "\<ESC>0"
  inoremap <silent><expr><buffer> <Plug>(unite_delete_backward_char)
        \ col('.') <= (len(unite#get_current_unite().prompt)+1) ?
        \ "\<C-o>:\<C-u>call \<SID>exit()\<Cr>" : "\<C-h>"
  inoremap <expr><buffer> <Plug>(unite_delete_backward_line)
        \ repeat("\<C-h>", col('.')-(len(unite#get_current_unite().prompt)+1))
  inoremap <expr><buffer> <Plug>(unite_delete_backward_word)
        \ col('.') <= (len(unite#get_current_unite().prompt)+1) ?
        \ '' : "\<C-w>"
  inoremap <expr><buffer> <Plug>(unite_delete_backward_path)
        \ col('.') <= (len(unite#get_current_unite().prompt)+1) ?
        \ '' : <SID>delete_backward_path()
  inoremap <expr><buffer> <Plug>(unite_select_next_line)
        \ pumvisible() ? "\<C-n>" : <SID>loop_cursor_down(0)
  inoremap <expr><buffer> <Plug>(unite_select_previous_line)
        \ pumvisible() ? "\<C-p>" : <SID>loop_cursor_up(0)
  inoremap <expr><buffer> <Plug>(unite_skip_next_line)
        \ pumvisible() ? "\<C-n>" : <SID>loop_cursor_down(1)
  inoremap <expr><buffer> <Plug>(unite_skip_previous_line)
        \ pumvisible() ? "\<C-p>" : <SID>loop_cursor_up(1)
  inoremap <expr><buffer> <Plug>(unite_select_next_page)
        \ pumvisible() ? "\<PageDown>" : repeat("\<Down>", winheight(0))
  inoremap <expr><buffer> <Plug>(unite_select_previous_page)
        \ pumvisible() ? "\<PageUp>" : repeat("\<Up>", winheight(0))
  inoremap <silent><buffer> <Plug>(unite_toggle_mark_current_candidate)
        \ <C-o>:<C-u>call <SID>toggle_mark()<CR>
  inoremap <silent><buffer> <Plug>(unite_choose_action)
        \ <C-o>:<C-u>call <SID>choose_action()<CR>
  inoremap <silent><buffer> <Plug>(unite_move_head)
        \ <C-o>:<C-u>call <SID>insert_head()<CR>
  inoremap <silent><buffer> <Plug>(unite_quick_match_default_action)
        \ <C-o>:<C-u>call unite#mappings#_quick_match(0)<CR>
  inoremap <silent><buffer> <Plug>(unite_quick_match_choose_action)
        \ <C-o>:<C-u>call unite#mappings#_quick_match(1)<CR>
  inoremap <silent><buffer> <Plug>(unite_input_directory)
        \ <C-o>:<C-u>call <SID>input_directory()<CR>
  inoremap <silent><buffer><expr> <Plug>(unite_do_default_action)
        \ unite#do_action(unite#get_current_unite().context.default_action)
  inoremap <silent><buffer> <Plug>(unite_toggle_transpose_window)
        \ <C-o>:<C-u>call <SID>toggle_transpose_window()<CR>
  inoremap <silent><buffer> <Plug>(unite_toggle_auto_preview)
        \ <C-o>:<C-u>call <SID>toggle_auto_preview()<CR>
  inoremap <silent><buffer> <Plug>(unite_narrowing_path)
        \ <C-o>:<C-u>call <SID>narrowing_path()<CR>
  inoremap <silent><buffer> <Plug>(unite_narrowing_input_history)
        \ <C-o>:<C-u>call <SID>narrowing_input_history()<CR>
  inoremap <silent><buffer> <Plug>(unite_toggle_max_candidates)
        \ <C-o>:<C-u>call <SID>toggle_max_candidates()<CR>
  inoremap <silent><buffer> <Plug>(unite_redraw)
        \ <C-o>:<C-u>call <SID>redraw()<CR>
  "}}}

  if exists('g:unite_no_default_keymappings') && g:unite_no_default_keymappings
    return
  endif

  " Normal mode key-mappings.
  nmap <buffer> i         <Plug>(unite_insert_enter)
  nmap <buffer> I         <Plug>(unite_insert_head)
  nmap <buffer> A         <Plug>(unite_append_end)
  nmap <buffer> q         <Plug>(unite_exit)
  nmap <buffer> Q         <Plug>(unite_all_exit)
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
  nmap <buffer> J         <Plug>(unite_skip_cursor_down)
  nmap <buffer> K         <Plug>(unite_skip_cursor_up)
  nmap <buffer> <C-h>     <Plug>(unite_delete_backward_path)
  nmap <buffer> <C-r>     <Plug>(unite_restart)
  nmap <buffer> *         <Plug>(unite_toggle_mark_all_candidates)
  nmap <buffer> M         <Plug>(unite_toggle_max_candidates)
  nmap <buffer> ?         <Plug>(unite_quick_help)

  nmap <silent><buffer><expr> a
        \ unite#smart_map("\<Plug>(unite_append_enter)",
        \                 "\<Plug>(unite_choose_action)")
  nnoremap <silent><buffer><expr> d
        \ unite#smart_map('d', unite#do_action('delete'))
  nnoremap <silent><buffer><expr> b
        \ unite#smart_map('b', unite#do_action('bookmark'))
  nnoremap <silent><buffer><expr> e
        \ unite#smart_map('e', unite#do_action('edit'))
  nnoremap <silent><buffer><expr> p
        \ unite#do_action('preview')
  nmap <silent><buffer><expr> x
        \ unite#smart_map('x', "\<Plug>(unite_quick_match_default_action)")
  nnoremap <silent><buffer><expr> t
        \ unite#smart_map('t', unite#do_action('tabopen'))
  inoremap <silent><buffer><expr> t
        \ unite#smart_map('t', unite#do_action('tabopen'))

  " Visual mode key-mappings.
  xmap <buffer> <Space>
        \ <Plug>(unite_toggle_mark_selected_candidates)

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
  imap <buffer> <C-l>     <Plug>(unite_redraw)

  inoremap <silent><buffer><expr> d
        \ unite#smart_map('d', unite#do_action('delete'))
  inoremap <silent><buffer><expr> e
        \ unite#smart_map('e', unite#do_action('edit'))
  imap <silent><buffer><expr> <Space>
        \ unite#smart_map(' ', "\<Plug>(unite_toggle_mark_current_candidate)")
  imap <silent><buffer><expr> x
        \ unite#smart_map('x', "\<Plug>(unite_quick_match_default_action)")
endfunction"}}}

function! unite#mappings#narrowing(word)"{{{
  setlocal modifiable
  let unite = unite#get_current_unite()
  let unite.input = escape(a:word, ' *')
  let prompt_linenr = unite.prompt_linenr
  call setline(prompt_linenr, unite.prompt . unite.input)
  call unite#redraw()
  execute prompt_linenr
  if unite.is_insert
    startinsert!
  else
    normal! 0z.
  endif
endfunction"}}}
function! unite#mappings#do_action(action_name, ...)"{{{
  let candidates = get(a:000, 0, unite#get_marked_candidates())
  let new_context = get(a:000, 1, {})
  let is_clear_marks = get(a:000, 2, 1)
  let sources = get(a:000, 3, {})

  let unite = unite#get_current_unite()
  if empty(candidates)
    let num = (line('.') <= unite.prompt_linenr) ? 0 :
          \ (line('.') - (unite.prompt_linenr + 1))
    if type(num) == type(0)
      if line('$') - (unite.prompt_linenr + 1) < num
        " Ignore.
        return []
      endif

      let candidates = [ unite#get_current_candidate() ]
    else
      let candidates = [ num ]
    endif
  endif

  let candidates = filter(copy(candidates),
        \ '!has_key(v:val, "is_dummy") || !v:val.is_dummy')
  if empty(candidates)
    return []
  endif

  if is_clear_marks
    " Clear marks.
    for candidate in candidates
      let candidate.unite__is_marked = 0
    endfor
  endif

  let action_tables = s:get_action_table(
        \ a:action_name, candidates, sources)

  if !empty(new_context)
    " Set new context.
    let new_context = extend(
          \ deepcopy(unite#get_context()), new_context)
    let old_context = unite#set_context(new_context)
  endif

  let context = unite#get_context()

  " Execute action.
  let is_redraw = 0
  let is_quit = 0
  let _ = []
  for table in action_tables
    " Check quit flag.
    if table.action.is_quit
      call unite#all_quit_session(0)
      let is_quit = 1
    endif

    try
      call add(_, table.action.func(table.candidates))
    catch /^Vim\%((\a\+)\)\=:E325/
      " Ignore catch.
      call unite#print_error(v:exception)
      call unite#print_error('Attenssion: Swap file is found in executing action!')
      call unite#print_error('Action name is ' . table.action.name)
    catch
      call unite#print_error(v:throwpoint)
      call unite#print_error(v:exception)
      call unite#print_error('Error occured in executing action!')
      call unite#print_error('Action name is ' . table.action.name)
    endtry

    " Check invalidate cache flag.
    if table.action.is_invalidate_cache
      for source_name in table.source_names
        call unite#invalidate_cache(source_name)
      endfor

      let is_redraw = 1
    endif
  endfor

  if !empty(new_context)
    " Restore context.
    call unite#set_context(old_context)
  endif

  if is_redraw
    call unite#force_redraw()
    normal! zb
  endif

  return _
endfunction"}}}

function! unite#mappings#get_current_filters()"{{{
  let unite = unite#get_current_unite()
  return unite.post_filters
endfunction"}}}
function! unite#mappings#set_current_filters(filters)"{{{
  let unite = unite#get_current_unite()
  let unite.post_filters = a:filters
  let unite.context.is_redraw = 1
  return mode() ==# 'i' ? "\<C-r>\<ESC>" : "g\<ESC>"
endfunction"}}}

function! s:get_action_table(action_name, candidates, sources)"{{{
  let action_tables = []
  let Self = unite#get_self_functions()[-1]
  for candidate in a:candidates
    let action_table = s:get_candidate_action_table(candidate, a:sources)

    let action_name = a:action_name
    if action_name ==# 'default'
      " Get default action.
      let action_name = unite#get_default_action(
            \ candidate.source, candidate.kind)
    endif

    if !has_key(action_table, action_name)
      call unite#util#print_error(candidate.abbr . '(' . candidate.source . ')')
      call unite#util#print_error('No such action : ' . action_name)
      return []
    endif

    let action = action_table[action_name]

    " Check selectable flag.
    if !action.is_selectable && len(a:candidates) > 1
      call unite#util#print_error(candidate.abbr . '(' . candidate.source . ')')
      call unite#util#print_error('Not selectable action : ' . action_name)
      return []
    endif

    let found = 0
    for table in action_tables
      if action == table.action
        " Add list.
        call add(table.candidates, candidate)
        call add(table.source_names, candidate.source)
        let found = 1
        break
      endif
    endfor

    if !found
      " Add action table.
      call add(action_tables, {
            \ 'action' : action,
            \ 'source_names' : [candidate.source],
            \ 'candidates' : (!action.is_selectable ? candidate : [candidate]),
            \ })
    endif
  endfor

  return action_tables
endfunction"}}}
function! s:get_actions(candidates, sources)"{{{
  let Self = unite#get_self_functions()[-1]

  let actions = s:get_candidate_action_table(a:candidates[0], a:sources)

  for candidate in a:candidates[1:]
    let action_table = s:get_candidate_action_table(candidate, a:sources)
    " Filtering unique items and check selectable flag.
    call filter(actions, 'has_key(action_table, v:key)
          \ && action_table[v:key].is_selectable')
  endfor

  return actions
endfunction"}}}
function! s:get_candidate_action_table(candidate, sources)"{{{
  let Self = unite#get_self_functions()[-1]

  return unite#get_action_table(a:candidate.source, a:candidate.kind, Self,
        \ 0, a:sources)
endfunction"}}}

" key-mappings functions.
function! s:exit()"{{{
  call unite#force_quit_session()
endfunction"}}}
function! s:all_exit()"{{{
  call unite#all_quit_session()
endfunction"}}}
function! s:restart()"{{{
  let unite = unite#get_current_unite()
  let context = unite.context
  let sources = map(deepcopy(unite.sources), 'empty(v:val.args) ? v:val.name : [v:val.name, v:val.args]')
  call unite#force_quit_session()
  call unite#start(sources, context)
endfunction"}}}
function! s:delete_backward_path()"{{{
  let unite    = unite#get_current_unite()
  let prompt   = unite.prompt
  let input    = getline(unite.prompt_linenr)[len(prompt):]
  let startcol = match(input, '[^/]*.$') + 1 + len(prompt)
  let endcol   = virtcol('.')
  return repeat("\<C-h>", (startcol < endcol ? endcol - startcol : 0))
endfunction"}}}
function! s:normal_delete_backward_path()"{{{
  let modifiable_save = &l:modifiable
  setlocal modifiable
  call setline(unite#get_current_unite().prompt_linenr,
        \ substitute(getline(unite#get_current_unite().prompt_linenr)[len(unite#get_current_unite().prompt):],
        \                 '[^/]*.$', '', ''))
  call unite#redraw()
  let &l:modifiable = modifiable_save
endfunction"}}}
function! s:toggle_mark()"{{{
  let candidate = unite#get_current_candidate()
  if empty(candidate)
    return
  endif

  let candidate.unite__is_marked = !candidate.unite__is_marked
  let candidate.unite__marked_time = localtime()

  let prompt_linenr = unite#get_current_unite().prompt_linenr
  if line('.') <= prompt_linenr
    call cursor(prompt_linenr+1, 0)
  endif
  call unite#redraw_line()

  normal! j
endfunction"}}}
function! s:toggle_mark_candidates(start, end)"{{{
  if a:start < 0 || a:end >= len(unite#get_unite_candidates())
    " Ignore.
    return
  endif

  let cnt = a:start
  while cnt <= a:end
    let candidate = unite#get_unite_candidates()[cnt]
    let candidate.unite__is_marked = !candidate.unite__is_marked
    let candidate.unite__marked_time = localtime()

    call unite#redraw_line(cnt + unite#get_current_unite().prompt_linenr+1)

    let cnt += 1
  endwhile
endfunction"}}}
function! s:quick_help()"{{{
  let unite = unite#get_current_unite()

  call unite#start_temporary([['mapping', bufnr('%')]], {}, 'mapping-help')
endfunction"}}}
function! s:choose_action()"{{{
  let unite = unite#get_current_unite()
  if line('$') < (unite.prompt_linenr+1)
    " Ignore.
    return
  endif

  let candidates = unite#get_marked_candidates()
  if empty(candidates)
    let candidates = [ unite#get_current_candidate() ]
  endif

  call unite#mappings#_choose_action(candidates)
endfunction"}}}
function! unite#mappings#_choose_action(candidates)"{{{
  call filter(a:candidates, '!has_key(v:val, "is_dummy") || !v:val.is_dummy')
  if empty(a:candidates)
    return
  endif

  let unite = unite#get_current_unite()

  call unite#start_temporary([[s:source_action] + a:candidates],
        \ { 'source__sources' : unite.sources }, 'action')
endfunction"}}}
function! s:insert_enter(key)"{{{
  setlocal modifiable
  return a:key
endfunction"}}}
function! s:insert_head()"{{{
  let pos = getpos('.')
  let pos[2] = len(unite#get_current_unite().prompt)+1
  call setpos('.', pos)
  call s:insert_enter(col('.'))
endfunction"}}}
function! s:redraw()"{{{
  call unite#clear_message()

  let unite = unite#get_current_unite()
  call unite#force_redraw()
endfunction"}}}
function! s:rotate_source(is_next)"{{{
  let unite = unite#get_current_unite()

  for source in unite#loaded_sources_list()
    let unite.sources = a:is_next ?
          \ add(unite.sources[1:], unite.sources[0]) :
          \ insert(unite.sources[: -2], unite.sources[-1])

    if !empty(unite.sources[0].unite__candidates)
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

  let candidate = unite#get_current_candidate()
  echo 'abbr: ' . candidate.abbr
  echo 'word: ' . candidate.word
endfunction"}}}
function! s:insert_selected_candidate()"{{{
  if line('.') <= unite#get_current_unite().prompt_linenr
    " Ignore.
    return
  endif

  let candidate = unite#get_current_candidate()
  call unite#mappings#narrowing(candidate.word)
endfunction"}}}
function! unite#mappings#_quick_match(is_choose)"{{{
  if !empty(unite#get_marked_candidates())
    call unite#util#print_error('Marked candidates is detected.')
    return
  endif

  let quick_match_table = s:get_quick_match_table()
  call unite#quick_match_redraw(quick_match_table)

  if mode() !~# '^c'
    echo 'Input quick match key: '
  endif
  let char = ''

  while char == ''
    let char = nr2char(getchar())
  endwhile

  redraw
  echo ''

  call unite#redraw_candidates()

  let unite = unite#get_current_unite()

  if !has_key(quick_match_table, char)
        \ || quick_match_table[char] >= len(unite.candidates)
    call unite#util#print_error('Canceled.')
    return
  endif

  let candidate = unite.candidates[quick_match_table[char]]
  if candidate.is_dummy
    call unite#util#print_error('Canceled.')
    return
  endif

  if a:is_choose
    call unite#mappings#_choose_action([candidate])
  else
    call unite#mappings#do_action(
          \ unite.context.default_action, [candidate])
  endif
endfunction"}}}
function! s:input_directory()"{{{
  let path = unite#substitute_path_separator(input('Input narrowing directory: ', unite#get_input(), 'dir'))
  let path = path.(path == '' || path =~ '/$' ? '' : '/')
  call unite#mappings#narrowing(path)
endfunction"}}}
function! s:loop_cursor_down(is_skip_not_matched)"{{{
  let is_insert = mode() ==# 'i'
  let prompt_linenr = unite#get_current_unite().prompt_linenr

  if line('.') == line('$')
    " Loop.
    if is_insert
      return "\<C-Home>\<End>".repeat("\<Down>", prompt_linenr-1)."\<End>"
    else
      return prompt_linenr.'G0z.'
    endif
  endif

  let num = line('.') - (prompt_linenr + 1)
  let cnt = 1
  if line('.') <= prompt_linenr
    let cnt += prompt_linenr - line('.')
  endif
  if is_insert && line('.') == prompt_linenr
    let cnt += 1
  endif

  while 1
    let candidate = get(unite#get_unite_candidates(), num + cnt, {})
    if !empty(candidate) && (candidate.is_dummy
          \ || (a:is_skip_not_matched && !candidate.is_matched))
      let cnt += 1
      continue
    endif

    break
  endwhile

  if is_insert
    return "\<Home>" . repeat("\<Down>", cnt)
  else
    return repeat('j', cnt)
  endif
endfunction"}}}
function! s:loop_cursor_up(is_skip_not_matched)"{{{
  let is_insert = mode() ==# 'i'
  let prompt_linenr = unite#get_current_unite().prompt_linenr

  if line('.') <= prompt_linenr
    " Loop.
    if is_insert
      return "\<C-End>\<Home>"
    else
      return 'G'
    endif
  endif

  let num = line('.') - (prompt_linenr + 1)
  let cnt = 1
  if line('.') <= prompt_linenr
    let cnt += prompt_linenr - line('.')
  endif
  if is_insert && line('.') == prompt_linenr+2
    let cnt += 1
  endif

  while 1
    let candidate = get(unite#get_unite_candidates(), num - cnt, {})
    if num >= cnt && !empty(candidate) && (candidate.is_dummy
          \ || (a:is_skip_not_matched && !candidate.is_matched))
      let cnt += 1
      continue
    endif

    break
  endwhile

  if num < 0
    if is_insert
      return "\<C-Home>\<End>".repeat("\<Down>", prompt_linenr)."\<Home>"
    else
      return prompt_linenr.'G0z.'
    endif
  endif

  if is_insert
    if line('.') <= prompt_linenr + 2
      return repeat("\<Up>", cnt) . "\<End>"
    else
      return "\<Home>" . repeat("\<Up>", cnt)
    endif
  else
    return repeat('k', cnt)
  endif
endfunction"}}}
function! s:toggle_transpose_window()"{{{
  " Toggle vertical/horizontal view.
  let context = unite#get_context()
  let direction = context.vertical ?
        \ (context.direction ==# 'topleft' ? 'K' : 'J') :
        \ (context.direction ==# 'topleft' ? 'H' : 'L')

  execute 'silent wincmd ' . direction

  let context.vertical = !context.vertical
endfunction"}}}
function! s:toggle_auto_preview()"{{{
  let context = unite#get_context()
  let context.auto_preview = !context.auto_preview

  if !context.auto_preview
        \ && !unite#get_current_unite().has_preview_window
    " Close preview window.
    pclose!
  endif
endfunction"}}}
function! s:toggle_max_candidates()"{{{
  let unite = unite#get_current_unite()
  let unite.is_enabled_max_candidates = !unite.is_enabled_max_candidates
  call unite#force_redraw()
endfunction"}}}
function! s:narrowing_path()"{{{
  if line('.') <= unite#get_current_unite().prompt_linenr
    " Ignore.
    return
  endif

  let candidate = unite#get_current_candidate()
  call unite#mappings#narrowing(has_key(candidate, 'action__path')? candidate.action__path : candidate.word)
endfunction"}}}
function! s:narrowing_input_history()"{{{
  call unite#start_temporary([s:source_input],
        \ { 'old_source_names_string' : unite#loaded_source_names_string() },
        \ 'history/input')
endfunction"}}}

function! s:get_quick_match_table()"{{{
  let offset = line('.') - unite#get_current_unite().prompt_linenr - 1
  if offset < 0
    let offset = 0
  endif

  let table = deepcopy(g:unite_quick_match_table)
  for key in keys(table)
    let table[key] += offset
  endfor
  return table
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

function! s:source_action.hooks.on_syntax(args, context)"{{{
  syntax match uniteSource__ActionDescriptionLine / -- .*$/ contained containedin=uniteSource__Action
  syntax match uniteSource__ActionDescription /.*$/ contained containedin=uniteSource__ActionDescriptionLine
  syntax match uniteSource__ActionMarker / -- / contained containedin=uniteSource__ActionDescriptionLine
  highlight default link uniteSource__ActionMarker Special
  highlight default link uniteSource__ActionDescription Comment
endfunction"}}}

function! s:source_action.gather_candidates(args, context)"{{{
  let candidates = copy(a:args)

  " Print candidates.
  call unite#print_message(map(copy(candidates),
        \ '"[action] candidates: ".v:val.abbr."(".v:val.source.")"'))

  " Process Alias.
  let actions = s:get_actions(candidates,
        \ unite#get_context().source__sources)

  " Uniq.
  let uniq_actions = {}
  for action in values(actions)
    if !has_key(action, action.name)
      let uniq_actions[action.name] = action
    endif
  endfor

  let max = max(map(values(actions), 'len(v:val.name)'))

  let sources = map(copy(candidates), 'v:val.source')

  return sort(map(filter(values(uniq_actions), 'v:val.is_listed'), '{
        \   "word" : v:val.name,
        \   "abbr" : printf("%-' . max . 's -- %s",
        \       v:val.name, v:val.description),
        \   "source__candidates" : candidates,
        \   "action__action" : v:val,
        \   "source__sources" : sources,
        \ }'), 's:compare_word')
endfunction"}}}

function! s:compare_word(i1, i2)
  return (a:i1.word ># a:i2.word) ? 1 : -1
endfunction

" Actions"{{{
let s:source_action.action_table = {}

let s:source_action.action_table.do = {
      \ 'description' : 'do action',
      \ }
function! s:source_action.action_table.do.func(candidate)"{{{
  let context = unite#get_context()
  call unite#mappings#do_action(a:candidate.word,
   \ a:candidate.source__candidates, {}, 1,
   \ context.source__sources)

  " Check quit flag.
  if !a:candidate.action__action.is_quit
        \ && context.temporary
    call unite#resume_from_temporary(context)

    " Check invalidate cache flag.
    if a:candidate.action__action.is_invalidate_cache
      for source_name in a:candidate.source__sources
        call unite#invalidate_cache(source_name)
      endfor

      call unite#force_redraw()
      normal! zb
    endif
  endif
endfunction"}}}
"}}}
"}}}

" Unite history/input source."{{{
let s:source_input = {
      \ 'name' : 'history/input',
      \ 'description' : 'candidates from unite input history',
      \ 'action_table' : {},
      \ 'default_action' : 'narrow',
      \ 'syntax' : 'uniteSource__Action',
      \}

function! s:source_input.gather_candidates(args, context)"{{{
  let context = unite#get_context()
  let inputs = unite#get_profile(
        \ context.old_buffer_info[0].profile_name, 'unite__inputs')
  let key = context.old_source_names_string
  if !has_key(inputs, key)
    return []
  endif

  return map(copy(inputs[key]), '{
        \ "word" : v:val
        \ }')
endfunction"}}}

" Actions"{{{
let s:source_input.action_table = {}

let s:source_input.action_table.narrow = {
      \ 'description' : 'narrow by history',
      \ 'is_quit' : 0,
      \ }
function! s:source_input.action_table.narrow.func(candidate)"{{{
  call unite#force_quit_session()
  call unite#mappings#narrowing(a:candidate.word)
endfunction"}}}

let s:source_input.action_table.delete = {
      \ 'description' : 'delete from input history',
      \ 'is_selectable' : 1,
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ }
function! s:source_input.action_table.delete.func(candidates)"{{{
  let context = unite#get_context()
  let inputs = unite#get_profile(
        \ context.old_buffer_info[0].profile_name, 'unite__inputs')
  let key = context.old_source_names_string
  if !has_key(inputs, key)
    return
  endif

  for candidate in a:candidates
    call filter(inputs[key], 'v:val !=# candidate.word')
  endfor
endfunction"}}}
"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
