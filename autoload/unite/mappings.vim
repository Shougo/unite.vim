"=============================================================================
" FILE: mappings.vim
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

" Define default mappings.
function! unite#mappings#define_default_mappings() "{{{
  " Plugin keymappings "{{{
  nnoremap <silent><buffer> <Plug>(unite_exit)
        \ :<C-u>call <SID>exit()<CR>
  nnoremap <silent><buffer> <Plug>(unite_all_exit)
        \ :<C-u>call <SID>all_exit()<CR>
  nnoremap <silent><buffer> <Plug>(unite_choose_action)
        \ :<C-u>call <SID>choose_action()<CR>
  if b:unite.prompt_linenr == 0
    nnoremap <silent><buffer> <Plug>(unite_insert_enter)
          \ :<C-u>call <SID>insert_enter2()<CR>
    nnoremap <silent><buffer> <Plug>(unite_insert_head)
          \ :<C-u>call <SID>insert_enter2()<CR>
    nnoremap <silent><buffer> <Plug>(unite_append_enter)
          \ :<C-u>call <SID>insert_enter2()<CR>
    nnoremap <silent><buffer> <Plug>(unite_append_end)
          \ :<C-u>call <SID>insert_enter2()<CR>
  else
    nnoremap <expr><buffer> <Plug>(unite_insert_enter)
          \ <SID>insert_enter('i')
    nnoremap <expr><buffer> <Plug>(unite_insert_head)
          \ <SID>insert_enter('A'.
          \  (repeat("\<Left>", len(substitute(
          \    unite#helper#get_input(), '.', 'x', 'g')))))
    nnoremap <expr><buffer> <Plug>(unite_append_enter)
          \ <SID>insert_enter('a')
    nnoremap <expr><buffer> <Plug>(unite_append_end)
          \ <SID>insert_enter('A')
  endif
  nnoremap <silent><buffer> <Plug>(unite_toggle_mark_current_candidate)
        \ :<C-u>call <SID>toggle_mark('j')<CR>
  nnoremap <silent><buffer> <Plug>(unite_toggle_mark_current_candidate_up)
        \ :<C-u>call <SID>toggle_mark('k')<CR>
  nnoremap <silent><buffer> <Plug>(unite_redraw)
        \ :<C-u>call <SID>redraw()<CR>
  nnoremap <silent><buffer> <Plug>(unite_rotate_next_source)
        \ :<C-u>call <SID>rotate_source(1)<CR>
  nnoremap <silent><buffer> <Plug>(unite_rotate_previous_source)
        \ :<C-u>call <SID>rotate_source(0)<CR>
  nnoremap <silent><buffer> <Plug>(unite_print_candidate)
        \ :<C-u>call <SID>print_candidate()<CR>
  nnoremap <silent><buffer> <Plug>(unite_print_message_log)
        \ :<C-u>call <SID>print_message_log()<CR>
  nnoremap <buffer><expr> <Plug>(unite_cursor_top)
        \ 'gg0z.'
  nnoremap <silent><buffer> <Plug>(unite_cursor_bottom)
        \ :<C-u>call <SID>redraw_all_candidates()<CR>G
  nnoremap <buffer><silent> <Plug>(unite_next_screen)
        \ :<C-u>call <SID>move_screen(1)<CR>
  nnoremap <buffer><silent> <Plug>(unite_next_half_screen)
        \ :<C-u>call <SID>move_half_screen(1)<CR>
  nnoremap <silent><buffer> <Plug>(unite_quick_match_default_action)
        \ :<C-u>call unite#mappings#_quick_match(0)<CR>
  nnoremap <silent><buffer> <Plug>(unite_quick_match_choose_action)
        \ :<C-u>call unite#mappings#_quick_match(1)<CR>
  nnoremap <silent><buffer> <Plug>(unite_input_directory)
        \ :<C-u>call <SID>input_directory()<CR>
  nnoremap <silent><buffer><expr> <Plug>(unite_do_default_action)
        \ unite#do_action(unite#get_current_unite().context.default_action)
  nnoremap <silent><buffer> <Plug>(unite_delete_backward_path)
        \ :<C-u>call <SID>delete_backward_path()<CR>
  nnoremap <silent><buffer> <Plug>(unite_restart)
        \ :<C-u>call <SID>restart()<CR>
  nnoremap <buffer><silent> <Plug>(unite_toggle_mark_all_candidates)
        \ :<C-u>call <SID>toggle_mark_all_candidates()<CR>
  nnoremap <buffer><silent> <Plug>(unite_toggle_transpose_window)
        \ :<C-u>call <SID>toggle_transpose_window()<CR>
  nnoremap <buffer><silent> <Plug>(unite_toggle_auto_preview)
        \ :<C-u>call <SID>toggle_auto_preview()<CR>
  nnoremap <buffer><silent> <Plug>(unite_toggle_auto_highlight)
        \ :<C-u>call <SID>toggle_auto_highlight()<CR>
  nnoremap <buffer><silent> <Plug>(unite_narrowing_input_history)
        \ :<C-u>call <SID>narrowing_input_history()<CR>
  nnoremap <buffer><silent> <Plug>(unite_narrowing_dot)
        \ :<C-u>call <SID>narrowing_dot()<CR>
  nnoremap <buffer><silent> <Plug>(unite_disable_max_candidates)
        \ :<C-u>call <SID>disable_max_candidates()<CR>
  nnoremap <buffer><silent> <Plug>(unite_quick_help)
        \ :<C-u>call <SID>quick_help()<CR>
  nnoremap <buffer><silent> <Plug>(unite_new_candidate)
        \ :<C-u>call <SID>do_new_candidate_action()<CR>

  vnoremap <buffer><silent> <Plug>(unite_toggle_mark_selected_candidates)
        \ :<C-u>call <SID>toggle_mark_candidates(
        \      getpos("'<")[1], getpos("'>")[1])<CR>

  inoremap <silent><buffer> <Plug>(unite_exit)
        \ <ESC>:<C-u>call <SID>exit()<CR>
  inoremap <silent><buffer> <Plug>(unite_insert_leave)
        \ <ESC>:<C-u>call <SID>insert_leave()<CR>
  inoremap <silent><expr><buffer> <Plug>(unite_delete_backward_char)
        \ <SID>smart_imap("\<ESC>:\<C-u>call \<SID>all_exit()\<CR>",
        \ (unite#helper#get_input() == '' ?
        \ "\<ESC>:\<C-u>call \<SID>all_exit()\<CR>" : "\<C-h>"))
  inoremap <silent><expr><buffer> <Plug>(unite_delete_backward_line)
        \ <SID>smart_imap('', repeat("\<C-h>",
        \     col('.')-(len(unite#get_current_unite().prompt)+1)))
  inoremap <silent><expr><buffer> <Plug>(unite_delete_backward_word)
        \ <SID>smart_imap('', "\<C-w>")
  inoremap <silent><buffer> <Plug>(unite_delete_backward_path)
        \ <C-o>:<C-u>call <SID>delete_backward_path()<CR>
  inoremap <expr><buffer> <Plug>(unite_select_next_page)
        \ pumvisible() ? "\<PageDown>" : repeat("\<Down>", winheight(0))
  inoremap <expr><buffer> <Plug>(unite_select_previous_page)
        \ pumvisible() ? "\<PageUp>" : repeat("\<Up>", winheight(0))
  inoremap <silent><buffer> <Plug>(unite_toggle_mark_current_candidate)
        \ <C-o>:<C-u>call <SID>toggle_mark('j')<CR>
  inoremap <silent><buffer> <Plug>(unite_toggle_mark_current_candidate_up)
        \ <C-o>:<C-u>call <SID>toggle_mark('k')<CR>
  inoremap <silent><buffer> <Plug>(unite_choose_action)
        \ <C-o>:<C-u>call <SID>choose_action()<CR>
  inoremap <expr><buffer> <Plug>(unite_move_head)
        \ <SID>smart_imap("\<ESC>".<SID>insert_enter('A'),
        \   repeat("\<Left>", len(substitute(
        \     unite#helper#get_input(), '.', 'x', 'g'))))
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
  inoremap <silent><buffer> <Plug>(unite_toggle_auto_highlight)
        \ <C-o>:<C-u>call <SID>toggle_auto_highlight()<CR>
  inoremap <silent><buffer> <Plug>(unite_narrowing_input_history)
        \ <C-o>:<C-u>call <SID>narrowing_input_history()<CR>
  inoremap <silent><buffer> <Plug>(unite_disable_max_candidates)
        \ <C-o>:<C-u>call <SID>disable_max_candidates()<CR>
  inoremap <silent><buffer> <Plug>(unite_redraw)
        \ <C-o>:<C-u>call <SID>redraw()<CR>
  inoremap <buffer><silent> <Plug>(unite_new_candidate)
        \ <C-o>:<C-u>call <SID>do_new_candidate_action()<CR>
  inoremap <silent><buffer> <Plug>(unite_print_message_log)
        \ <C-o>:<C-u>call <SID>print_message_log()<CR>
  inoremap <expr><silent><buffer> <Plug>(unite_complete)
        \ <SID>complete()
  "}}}

  if exists('g:unite_no_default_keymappings')
        \ && g:unite_no_default_keymappings
    return
  endif

  " Normal mode key-mappings.
  nmap <buffer> i         <Plug>(unite_insert_enter)
  nmap <buffer> I         <Plug>(unite_insert_head)
  nmap <buffer> A         <Plug>(unite_append_end)
  nmap <buffer> q         <Plug>(unite_exit)
  nmap <buffer> <C-g>     <Plug>(unite_exit)
  nmap <buffer> Q         <Plug>(unite_all_exit)
  nmap <buffer> g<C-g>    <Plug>(unite_all_exit)
  nmap <buffer> <CR>      <Plug>(unite_do_default_action)
  nmap <buffer> <Space>   <Plug>(unite_toggle_mark_current_candidate)
  nmap <buffer> <S-Space> <Plug>(unite_toggle_mark_current_candidate_up)
  nmap <buffer> <Tab>     <Plug>(unite_choose_action)
  nmap <buffer> <C-n>     <Plug>(unite_rotate_next_source)
  nmap <buffer> <C-p>     <Plug>(unite_rotate_previous_source)
  nmap <buffer> <C-a>     <Plug>(unite_print_message_log)
  nmap <buffer> <C-k>     <Plug>(unite_print_candidate)
  nmap <buffer> <C-l>     <Plug>(unite_redraw)
  nmap <buffer> gg        <Plug>(unite_cursor_top)
  nmap <buffer> G         <Plug>(unite_cursor_bottom)
  nmap <buffer> j         <Plug>(unite_loop_cursor_down)
  nmap <buffer> <Down>    <Plug>(unite_loop_cursor_down)
  nmap <buffer> k         <Plug>(unite_loop_cursor_up)
  nmap <buffer> <Up>      <Plug>(unite_loop_cursor_up)
  nmap <buffer> J         <Plug>(unite_skip_cursor_down)
  nmap <buffer> K         <Plug>(unite_skip_cursor_up)
  nmap <buffer> <C-h>     <Plug>(unite_delete_backward_path)
  nmap <buffer> <C-r>     <Plug>(unite_restart)
  nmap <buffer> *         <Plug>(unite_toggle_mark_all_candidates)
  nmap <buffer> M         <Plug>(unite_disable_max_candidates)
  nmap <buffer> g?        <Plug>(unite_quick_help)
  nmap <buffer> N         <Plug>(unite_new_candidate)
  nmap <buffer> .         <Plug>(unite_narrowing_dot)
  nmap <buffer> <2-LeftMouse>   <Plug>(unite_do_default_action)
  nmap <buffer> <RightMouse>    <Plug>(unite_exit)

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
        \ unite#smart_map('p', unite#mappings#smart_preview())
  nmap <silent><buffer><expr> x
        \ unite#smart_map('x', "\<Plug>(unite_quick_match_default_action)")
  nnoremap <silent><buffer><expr> t
        \ unite#smart_map('t', unite#do_action('tabopen'))
  nnoremap <silent><buffer><expr> yy
        \ unite#smart_map('yy', unite#do_action('yank'))
  nnoremap <silent><buffer><expr> o
        \ unite#smart_map('o', unite#do_action('open'))

  " Visual mode key-mappings.
  xmap <buffer> <Space>
        \ <Plug>(unite_toggle_mark_selected_candidates)

  " Insert mode key-mappings.
  imap <buffer> <TAB>     <Plug>(unite_choose_action)
  imap <buffer> <C-n>     <Plug>(unite_select_next_line)
  imap <buffer> <Down>    <Plug>(unite_select_next_line)
  imap <buffer> <C-p>     <Plug>(unite_select_previous_line)
  imap <buffer> <Up>      <Plug>(unite_select_previous_line)
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
  if has('gui_running')
    imap <buffer> <ESC>   <Plug>(unite_insert_leave)
  endif
  imap <buffer> <C-g>     <Plug>(unite_exit)
  imap <buffer> <2-LeftMouse>   <Plug>(unite_do_default_action)
  imap <buffer> <RightMouse>    <Plug>(unite_exit)

  imap <silent><buffer><expr> <Space>
        \ unite#smart_map(' ', "\<Plug>(unite_toggle_mark_current_candidate)")
  imap <silent><buffer><expr> <S-Space>
        \ unite#smart_map(' ', "\<Plug>(unite_toggle_mark_current_candidate_up)")

  inoremap <silent><buffer><expr> <C-d>
        \ unite#do_action('delete')
  inoremap <silent><buffer><expr> <C-e>
        \ unite#do_action('edit')
  inoremap <silent><buffer><expr> <C-t>
        \ unite#do_action('tabopen')
  inoremap <silent><buffer><expr> <C-y>
        \ unite#do_action('yank')
  inoremap <silent><buffer><expr> <C-o>
        \ unite#do_action('open')
endfunction"}}}

function! unite#mappings#narrowing(word, ...) "{{{
  let is_escape = get(a:000, 0, 1)

  setlocal modifiable
  let unite = unite#get_current_unite()

  let unite.input = is_escape ? escape(a:word, ' *') : a:word
  let unite.context.input = unite.input

  call unite#handlers#_on_insert_enter()
  call unite#view#_redraw_prompt()
  call unite#helper#cursor_prompt()
  call unite#view#_bottom_cursor()
  startinsert!
endfunction"}}}

function! unite#mappings#do_action(...) "{{{
  return call('unite#action#do', a:000)
endfunction"}}}

function! unite#mappings#get_current_filters() "{{{
  let unite = unite#get_current_unite()
  return unite.post_filters
endfunction"}}}
function! unite#mappings#set_current_filters(filters) "{{{
  let unite = unite#get_current_unite()
  let unite.post_filters = a:filters
  let unite.context.is_redraw = 1
  return mode() ==# 'i' ? "\<C-r>\<ESC>" : "g\<ESC>"
endfunction"}}}

function! s:smart_imap(lhs, rhs) "{{{
  call s:clear_complete()
  return line('.') != unite#get_current_unite().prompt_linenr ||
        \ col('.') <= (unite#util#wcswidth(unite#get_current_unite().prompt)) ?
        \ a:lhs : a:rhs
endfunction"}}}
function! s:smart_imap2(lhs, rhs) "{{{
  call s:clear_complete()
  return line('.') <= (len(unite#get_current_unite().prompt)+1) ?
       \ a:lhs : a:rhs
endfunction"}}}

function! s:do_new_candidate_action() "{{{
  if empty(unite#helper#get_current_candidate())
    " Get source name.
    if len(unite#get_sources()) != 1
      call unite#print_error('[unite] No candidates and multiple sources.')
      return
    endif

    " Dummy candidate.
    let candidates = unite#init#_candidates_source([{}],
          \ unite#get_sources()[0].name)
  else
    let candidates = [unite#helper#get_current_candidate()]
  endif

  return unite#action#do('unite__new_candidate', candidates)
endfunction"}}}

" key-mappings functions.
function! s:exit() "{{{
  let context = unite#get_context()

  call unite#force_quit_session()

  if context.tab && winnr('$') == 1 && !context.temporary
    " Close window.
    close
  endif
endfunction"}}}
function! s:all_exit() "{{{
  call unite#all_quit_session()
endfunction"}}}
function! s:restart() "{{{
  let unite = unite#get_current_unite()
  let context = unite.context
  let context.resume = 0
  let context.unite__is_restart = 1
  let sources = map(deepcopy(unite.sources),
        \ 'empty(v:val.args) ? v:val.name : [v:val.name] + v:val.args')
  call unite#force_quit_session()
  call unite#start(sources, context)
endfunction"}}}
function! s:delete_backward_path() "{{{
  let context = unite#get_context()
  if context.input != ''
    call unite#mappings#narrowing(
          \ substitute(context.input, '[^/ ]*.$', '', ''), 0)
  else
    let context.path = substitute(context.path, '[^/ ]*.$', '', '')
    call unite#redraw()
  endif
endfunction"}}}
function! s:toggle_mark(map) "{{{
  call unite#helper#skip_prompt()

  let candidate = unite#helper#get_current_candidate()
  if !get(candidate, 'is_dummy', 0)
    let candidate.unite__is_marked = !candidate.unite__is_marked
    let candidate.unite__marked_time = localtime()

    call unite#view#_redraw_line()
  endif

  let context = unite#get_context()
  execute 'normal!' (a:map ==# 'j' && context.prompt_direction !=# 'below'
        \ || a:map ==# 'k' && context.prompt_direction ==# 'below') ?
        \ unite#mappings#cursor_down(1) : unite#mappings#cursor_up(1)
endfunction"}}}
function! s:toggle_mark_all_candidates() "{{{
  call s:redraw_all_candidates()
  call s:toggle_mark_candidates(1, line('$'))
endfunction"}}}
function! s:toggle_mark_candidates(start, end) "{{{
  if a:start < 0
    " Ignore.
    return
  endif

  let unite = unite#get_current_unite()

  let pos = getpos('.')
  try
    call cursor(a:start, 1)
    for _ in range(a:start, a:end)
      if line('.') == unite.prompt_linenr
        call unite#helper#skip_prompt()
      else
        let context = unite#get_context()
        if context.prompt_direction ==# 'below'
          call s:toggle_mark('k')
        else
          call s:toggle_mark('j')
        endif
      endif
    endfor
  finally
    call setpos('.', pos)
    call unite#view#_bottom_cursor()
  endtry
endfunction"}}}
function! s:quick_help() "{{{
  call unite#start_temporary([['mapping', bufnr('%')]], {}, 'mapping-help')
endfunction"}}}
function! s:choose_action() "{{{
  let candidates = unite#helper#get_marked_candidates()
  if empty(candidates)
    if empty(unite#helper#get_current_candidate())
      return
    endif

    let candidates = [ unite#helper#get_current_candidate() ]
  endif

  call unite#mappings#_choose_action(candidates)
endfunction"}}}
function! unite#mappings#_choose_action(candidates, ...) "{{{
  call filter(a:candidates,
        \ '!has_key(v:val, "is_dummy") || !v:val.is_dummy')
  if empty(a:candidates)
    return
  endif

  let unite = unite#get_current_unite()
  let context = deepcopy(get(a:000, 0, {}))
  let context.source__sources = unite.sources
  let context.buffer_name = 'action'
  let context.profile_name = 'action'
  let context.start_insert = 1
  let context.truncate = 1

  call call((has_key(context, 'vimfiler__current_directory') ?
        \ 'unite#start' : 'unite#start_temporary'),
        \ [[[unite#sources#action#define(), a:candidates]], context])
endfunction"}}}
function! s:insert_enter(key) "{{{
  setlocal modifiable

  let unite = unite#get_current_unite()

  return (line('.') != unite.prompt_linenr) ?
        \     unite.prompt_linenr . 'Gzb$a' :
        \ (a:key == 'i' && col('.') <= len(unite.prompt)
        \     || a:key == 'a' && col('.') < len(unite.prompt)) ?
        \     'A' :
        \     a:key
endfunction"}}}
function! s:insert_enter2() "{{{
  nnoremap <expr><buffer> <Plug>(unite_insert_enter)
        \ <SID>insert_enter('i')
  nnoremap <expr><buffer> <Plug>(unite_insert_head)
        \ <SID>insert_enter('A'.
        \  (repeat("\<Left>", len(substitute(
        \    unite#helper#get_input(), '.', 'x', 'g')))))
  nnoremap <expr><buffer> <Plug>(unite_append_enter)
        \ <SID>insert_enter('a')
  nnoremap <expr><buffer> <Plug>(unite_append_end)
        \ <SID>insert_enter('A')

  setlocal modifiable

  " Restore prompt
  call unite#handlers#_on_insert_enter()

  let unite = unite#get_current_unite()
  call cursor(unite.init_prompt_linenr, 0)
  call unite#view#_bottom_cursor()
  startinsert!
endfunction"}}}
function! s:insert_leave() "{{{
  call unite#helper#skip_prompt()
endfunction"}}}
function! s:redraw() "{{{
  call unite#clear_message()
  call unite#force_redraw()
endfunction"}}}
function! s:rotate_source(is_next) "{{{
  let unite = unite#get_current_unite()

  for _ in unite#loaded_sources_list()
    let unite.sources = a:is_next ?
          \ add(unite.sources[1:], unite.sources[0]) :
          \ insert(unite.sources[: -2], unite.sources[-1])

    if !empty(unite.sources[0].unite__candidates)
      break
    endif
  endfor

  call unite#view#_redraw_candidates()
endfunction"}}}
function! s:print_candidate() "{{{
  let candidate = unite#helper#get_current_candidate()
  if empty(candidate)
    " Ignore.
    return
  endif

  echo 'abbr: ' . candidate.unite__abbr
  echo 'word: ' . candidate.word
endfunction"}}}
function! s:print_message_log() "{{{
  for msg in unite#get_current_unite().msgs
    echohl Comment | echo msg | echohl None
  endfor
  for msg in unite#get_current_unite().err_msgs
    echohl WarningMsg | echo msg | echohl None
  endfor
endfunction"}}}
function! s:insert_selected_candidate() "{{{
  let candidate = unite#helper#get_current_candidate()
  if empty(candidate)
    " Ignore.
    return
  endif

  call unite#mappings#narrowing(candidate.word)
endfunction"}}}
function! unite#mappings#_quick_match(is_choose) "{{{
  if !empty(unite#helper#get_marked_candidates())
    call unite#util#print_error('Marked candidates is detected.')
    return
  endif

  let quick_match_table = s:get_quick_match_table()
  call unite#view#_quick_match_redraw(quick_match_table)

  if mode() !~# '^c'
    echo 'Input quick match key: '
  endif
  let char = ''

  while char == ''
    let char = nr2char(getchar())
  endwhile

  redraw
  echo ''

  call unite#view#_redraw_candidates()

  stopinsert

  let unite = unite#get_current_unite()

  if !has_key(quick_match_table, char)
        \ || quick_match_table[char] >= len(unite.current_candidates)
    call unite#util#print_error('Canceled.')

    if unite.context.quick_match && char == "\<ESC>"
      call unite#force_quit_session()
    endif
    return
  endif

  let candidate = unite.current_candidates[quick_match_table[char]]
  if candidate.is_dummy
    call unite#util#print_error('Canceled.')
    return
  endif

  if a:is_choose
    call unite#mappings#_choose_action([candidate])
  else
    call unite#action#do(
          \ unite.context.default_action, [candidate])
  endif
endfunction"}}}
function! s:input_directory() "{{{
  let path = unite#util#substitute_path_separator(
        \ input('Input narrowing directory: ',
        \         unite#helper#get_input(), 'dir'))
  let path = path.(path == '' || path =~ '/$' ? '' : '/')
  call unite#mappings#narrowing(path)
endfunction"}}}
function! unite#mappings#loop_cursor_up(mode) "{{{
  " Loop.
  call s:redraw_all_candidates()

  if a:mode ==# 'i'
    noautocmd startinsert
  endif

  call cursor(line('$'), 1)
endfunction"}}}
function! unite#mappings#loop_cursor_down(mode) "{{{
  " Loop.
  call s:redraw_all_candidates()

  if a:mode ==# 'i'
    noautocmd startinsert
  endif

  call cursor(1, 1)
endfunction"}}}
function! unite#mappings#cursor_up(is_skip_not_matched) "{{{
  let is_insert = mode() ==# 'i'
  let prompt_linenr = unite#get_current_unite().prompt_linenr

  let num = line('.') - 1
  let cnt = 1
  let offset = prompt_linenr == 1 ? 1 : 0
  if line('.') == prompt_linenr
    let cnt += 1
  endif

  while 1
    let candidate = get(unite#get_unite_candidates(), num - offset - cnt, {})
    if num >= cnt && !empty(candidate) && (candidate.is_dummy
          \ || (a:is_skip_not_matched && !candidate.is_matched))
      let cnt += 1
      continue
    endif

    break
  endwhile

  if is_insert
    return repeat("\<Up>", cnt) .
        \ (unite#helper#is_prompt(line('.') - cnt) ? "\<End>" : "\<Home>")
  else
    return cnt == 1 ? 'k' : cnt.'k'
  endif
endfunction"}}}
function! unite#mappings#cursor_down(is_skip_not_matched) "{{{
  let is_insert = mode() ==# 'i'
  let prompt_linenr = unite#get_current_unite().prompt_linenr

  let num = line('.') - 1
  let cnt = 1
  let offset = prompt_linenr == 1 ? 1 : 0
  if line('.') == prompt_linenr
    let cnt += 1
  endif

  while 1
    let candidate = get(unite#get_unite_candidates(), num - offset + cnt, {})
    if !empty(candidate) && (candidate.is_dummy
          \ || (a:is_skip_not_matched && !candidate.is_matched))
      let cnt += 1
      continue
    endif

    break
  endwhile

  if is_insert
    return repeat("\<Down>", cnt) .
          \ (unite#helper#is_prompt(line('.') + cnt) ? "\<End>" : "\<Home>")
  else
    return cnt == 1 ? 'j' : cnt.'j'
  endif
endfunction"}}}
function! unite#mappings#smart_preview() "{{{
  if b:unite.preview_candidate !=#
        \           unite#helper#get_current_candidate()
    let b:unite.preview_candidate = unite#helper#get_current_candidate()
    return unite#do_action('preview')
  else
    let b:unite.preview_candidate = {}
    return ":\<C-u>pclose!\<CR>"
  endif
endfunction"}}}
function! s:toggle_transpose_window() "{{{
  " Toggle vertical/horizontal view.
  let context = unite#get_context()
  let direction = context.vertical ?
        \ (context.direction ==# 'topleft' ? 'K' : 'J') :
        \ (context.direction ==# 'topleft' ? 'H' : 'L')

  execute 'silent wincmd ' . direction

  let context.vertical = !context.vertical
endfunction"}}}
function! s:toggle_auto_preview() "{{{
  let context = unite#get_context()
  let context.auto_preview = !context.auto_preview

  if !context.auto_preview
        \ && !unite#get_current_unite().has_preview_window
    " Close preview window.
    noautocmd pclose!
  endif
endfunction"}}}
function! s:toggle_auto_highlight() "{{{
  let context = unite#get_context()
  let context.auto_highlight = !context.auto_highlight
endfunction"}}}
function! s:disable_max_candidates() "{{{
  let unite = unite#get_current_unite()
  let unite.disabled_max_candidates = 1

  call unite#force_redraw()
  call s:redraw_all_candidates()
endfunction"}}}
function! s:narrowing_input_history() "{{{
  call unite#start_temporary(
        \ [unite#sources#history_input#define()],
        \ { 'old_source_names_string' : unite#loaded_source_names_string() },
        \ 'history/input')
endfunction"}}}
function! s:redraw_all_candidates() "{{{
  let unite = unite#get_current_unite()
  if len(unite.candidates) != len(unite.current_candidates)
    call unite#redraw(0, 1)
  endif
endfunction"}}}
function! s:narrowing_dot() "{{{
  call unite#mappings#narrowing(unite#helper#get_input().'.')
endfunction"}}}
function! s:get_quick_match_table() "{{{
  let unite = unite#get_current_unite()
  let offset = unite.context.prompt_direction ==# 'below' ?
        \ (unite.prompt_linenr == 0 ?
        \  line('$') - line('.') + 1 :
        \  unite.prompt_linenr - line('.')) :
        \ (line('.') - unite.prompt_linenr - 1)
  if line('.') == unite.prompt_linenr
    let offset = unite.context.prompt_direction
          \ ==# 'below' ? 1 : 0
  endif
  if unite.context.prompt_direction ==# 'below'
    let offset = offset * -1
  endif

  let table = deepcopy(g:unite_quick_match_table)
  if unite.context.prompt_direction ==# 'below'
    let max = len(unite.current_candidates)
    call map(table, 'max - v:val')
  endif
  for key in keys(table)
    let table[key] += offset
  endfor
  return table
endfunction"}}}


function! s:complete() "{{{
  let unite = unite#get_current_unite()
  let input = matchstr(unite#get_input(), '\h\w*$')
  let cur_text = unite#get_input()[: -len(input)-1]

  if !has_key(unite, 'complete_cur_text')
        \ || cur_text !=# unite.complete_cur_text
        \ || index(unite.complete_candidates, input) < 0
    " Recache
    let start = reltime()
    let unite.complete_candidates =
          \ unite#complete#gather(unite.current_candidates, input)
    echomsg string(reltimestr(reltime(start)))
    let unite.complete_candidate_num = 0
    let unite.complete_cur_text = cur_text
    let unite.complete_input = input
  endif

  call unite#view#_redraw_echo(printf('match %d of %d : %s',
        \ unite.complete_candidate_num+1, len(unite.complete_candidates),
        \ join(unite.complete_candidates[unite.complete_candidate_num+1 :
        \      unite.complete_candidate_num + 10])))

  let candidate = get(unite.complete_candidates,
        \ unite.complete_candidate_num, input)
  let unite.complete_candidate_num += 1
  if unite.complete_candidate_num >= len(unite.complete_candidates)
    " Cycle
    let unite.complete_candidate_num = 0
  endif

  return repeat("\<C-h>", unite#util#strchars(input)) . candidate
endfunction"}}}
function! s:clear_complete() "{{{
  let unite = unite#get_current_unite()
  if has_key(unite, 'complete_cur_text')
    call remove(unite, 'complete_cur_text')
    redraw
    echo ''
  endif

  return ''
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
