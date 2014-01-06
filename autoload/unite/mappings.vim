"=============================================================================
" FILE: mappings.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 07 Jan 2014.
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
        \ unite#get_current_unite().prompt_linenr.'G0z.'
  nnoremap <silent><buffer> <Plug>(unite_cursor_bottom)
        \ :<C-u>call <SID>redraw_all_candidates()<CR>G
  nnoremap <buffer><expr> <Plug>(unite_loop_cursor_down)
        \ <SID>loop_cursor_down(0)
  nnoremap <buffer><expr> <Plug>(unite_skip_cursor_down)
        \ <SID>loop_cursor_down(1)
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
        \ :<C-u>call <SID>normal_delete_backward_path()<CR>
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
  nnoremap <buffer><silent> <Plug>(unite_narrowing_path)
        \ :<C-u>call <SID>narrowing_path()<CR>
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
        \ :<C-u>call <SID>toggle_mark_candidates(getpos("'<")[1]
        \  - unite#get_current_unite().prompt_linenr-1,
        \ getpos("'>")[1] - unite#get_current_unite().prompt_linenr - 1)<CR>

  inoremap <silent><buffer> <Plug>(unite_exit)
        \ <ESC>:<C-u>call <SID>exit()<CR>
  inoremap <silent><expr><buffer> <Plug>(unite_insert_leave)
        \ "\<ESC>0".((line('.') <= unite#get_current_unite().prompt_linenr) ?
        \ (unite#get_current_unite().prompt_linenr+1)."G" : "")
        \ . ":call unite#redraw()\<CR>"
  inoremap <silent><expr><buffer> <Plug>(unite_delete_backward_char)
        \ <SID>smart_imap("\<ESC>:\<C-u>call \<SID>all_exit()\<CR>",
        \ (unite#helper#get_input() == '' ?
        \ "\<ESC>:\<C-u>call \<SID>all_exit()\<CR>" : "\<C-h>"))
  inoremap <silent><expr><buffer> <Plug>(unite_delete_backward_line)
        \ <SID>smart_imap('', repeat("\<C-h>",
        \     col('.')-(len(unite#get_current_unite().prompt)+1)))
  inoremap <silent><expr><buffer> <Plug>(unite_delete_backward_word)
        \ <SID>smart_imap('', "\<C-w>")
  inoremap <silent><expr><buffer> <Plug>(unite_delete_backward_path)
        \ <SID>smart_imap('', <SID>delete_backward_path())
  inoremap <expr><buffer> <Plug>(unite_select_next_line)
        \ pumvisible() ? "\<C-n>" : <SID>loop_cursor_down(0)
  inoremap <silent><buffer> <Plug>(unite_skip_previous_line)
        \ <ESC>:call unite#mappings#loop_cursor_up_call(1, 'i')<CR>
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
  inoremap <silent><buffer> <Plug>(unite_narrowing_path)
        \ <C-o>:<C-u>call <SID>narrowing_path()<CR>
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
  nmap <buffer> Q         <Plug>(unite_all_exit)
  nmap <buffer> <CR>      <Plug>(unite_do_default_action)
  nmap <buffer> <Space>   <Plug>(unite_toggle_mark_current_candidate)
  nmap <buffer> <S-Space> <Plug>(unite_toggle_mark_current_candidate_up)
  nmap <buffer> <Tab>     <Plug>(unite_choose_action)
  nmap <buffer> <C-n>     <Plug>(unite_rotate_next_source)
  nmap <buffer> <C-p>     <Plug>(unite_rotate_previous_source)
  nmap <buffer> <C-g>     <Plug>(unite_print_message_log)
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
  nmap <buffer> ?         <Plug>(unite_quick_help)
  nmap <buffer> N         <Plug>(unite_new_candidate)
  nmap <buffer> .         <Plug>(unite_narrowing_dot)

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
  nnoremap <silent><buffer><expr> yy
        \ unite#smart_map('yy', unite#do_action('yank'))

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
  if has('gui_running')
    imap <buffer> <ESC>     <Plug>(unite_insert_leave)
  endif
  imap <buffer> <C-g>     <Plug>(unite_exit)

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
endfunction"}}}

function! unite#mappings#narrowing(word) "{{{
  setlocal modifiable
  let unite = unite#get_current_unite()
  let unite.input = escape(a:word, ' *')
  let prompt_linenr = unite.prompt_linenr
  call setline(prompt_linenr, unite.prompt . unite.input)
  call unite#redraw()

  call cursor(prompt_linenr, 0)
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
  return line('.') != unite#get_current_unite().prompt_linenr ||
        \ col('.') <= (unite#util#wcswidth(unite#get_current_unite().prompt)) ?
        \ a:lhs : a:rhs
endfunction"}}}
function! s:smart_imap2(lhs, rhs) "{{{
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
  let context.is_restart = 1
  let sources = map(deepcopy(unite.sources),
        \ 'empty(v:val.args) ? v:val.name : [v:val.name] + v:val.args')
  call unite#force_quit_session()
  call unite#start(sources, context)
endfunction"}}}
function! s:delete_backward_path() "{{{
  let cur_text =
        \ (mode() ==# 'i' ? (col('.')-1) : col('.')) >= len(getline('.')) ?
        \      getline('.') :
        \      matchstr(getline('.'),
        \         '^.*\%' . col('.') . 'c' . (mode() ==# 'i' ? '' : '.'))
  let path = matchstr(cur_text[
        \ len(unite#get_context().prompt):], '[^/]*.$')
  return repeat("\<C-h>", unite#util#strchars(path))
endfunction"}}}
function! s:normal_delete_backward_path() "{{{
  let modifiable_save = &l:modifiable
  setlocal modifiable
  call setline(unite#get_current_unite().prompt_linenr,
        \ substitute(getline(unite#get_current_unite().prompt_linenr)[
        \    len(unite#get_current_unite().prompt):],
        \                 '[^/]*.$', '', ''))
  call unite#redraw()
  let &l:modifiable = modifiable_save
endfunction"}}}
function! s:toggle_mark(map) "{{{
  if line('.') == unite#get_current_unite().prompt_linenr
    call cursor(line('.')+1, 0)
  endif

  let candidate = unite#helper#get_current_candidate()
  if empty(candidate) || get(candidate, 'is_dummy', 0)
    return
  endif

  let candidate.unite__is_marked = !candidate.unite__is_marked
  let candidate.unite__marked_time = localtime()

  call unite#view#_redraw_line()

  execute 'normal!' a:map ==# 'j' ?
        \ s:loop_cursor_down(1) :
        \ unite#mappings#loop_cursor_up_expr(1)
endfunction"}}}
function! s:toggle_mark_all_candidates() "{{{
  call s:redraw_all_candidates()
  call s:toggle_mark_candidates(0,
        \     len(unite#get_unite_candidates()) - 1)
endfunction"}}}
function! s:toggle_mark_candidates(start, end) "{{{
  if a:start < 0 || a:end >= len(unite#get_unite_candidates())
    " Ignore.
    return
  endif

  let unite = unite#get_current_unite()
  let offset = unite.prompt_linenr+1
  let cnt = a:start
  while cnt <= a:end
    let candidate = unite#get_unite_candidates()[cnt]
    let candidate.unite__is_marked = !candidate.unite__is_marked
    let candidate.unite__marked_time = localtime()

    call unite#view#_redraw_line(cnt + offset)

    let cnt += 1
  endwhile
endfunction"}}}
function! s:quick_help() "{{{
  let unite = unite#get_current_unite()

  call unite#start_temporary([['mapping', bufnr('%')]], {}, 'mapping-help')
endfunction"}}}
function! s:choose_action() "{{{
  let unite = unite#get_current_unite()
  if line('$') < (unite.prompt_linenr+1)
    " Ignore.
    return
  endif

  let candidates = unite#helper#get_marked_candidates()
  if empty(candidates)
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

  call call((has_key(context, 'vimfiler__current_directory') ?
        \ 'unite#start' : 'unite#start_temporary'),
        \ [[[unite#sources#action#define(), a:candidates]], context])
endfunction"}}}
function! s:insert_enter(key) "{{{
  setlocal modifiable

  let unite = unite#get_current_unite()
  if line('.') != unite.prompt_linenr
        \ || col('.') <= len(unite.prompt)
    return unite.prompt_linenr.'GzbA'
  endif
  return a:key
endfunction"}}}
function! s:redraw() "{{{
  call unite#clear_message()

  let unite = unite#get_current_unite()
  call unite#force_redraw()
endfunction"}}}
function! s:rotate_source(is_next) "{{{
  let unite = unite#get_current_unite()

  for source in unite#loaded_sources_list()
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
  if line('.') <= unite#get_current_unite().prompt_linenr
    " Ignore.
    return
  endif

  let candidate = unite#helper#get_current_candidate()
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
  if line('.') <= unite#get_current_unite().prompt_linenr
    " Ignore.
    return
  endif

  let candidate = unite#helper#get_current_candidate()
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

  let unite = unite#get_current_unite()

  if !has_key(quick_match_table, char)
        \ || quick_match_table[char] >= len(unite.current_candidates)
    call unite#util#print_error('Canceled.')
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
  let path = unite#substitute_path_separator(
        \ input('Input narrowing directory: ',
        \         unite#helper#get_input(), 'dir'))
  let path = path.(path == '' || path =~ '/$' ? '' : '/')
  call unite#mappings#narrowing(path)
endfunction"}}}
function! s:loop_cursor_down(is_skip_not_matched) "{{{
  let is_insert = mode() ==# 'i'
  let prompt_linenr = unite#get_current_unite().prompt_linenr

  if line('.') <= prompt_linenr && !is_insert
    return line('.') == line('$') &&
          \ empty(unite#get_unite_candidates()) ? '2G' : 'j'
  endif

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
function! unite#mappings#loop_cursor_up_call(is_skip_not_matched, mode) "{{{
  let is_insert = a:mode ==# 'i'
  let prompt_linenr = unite#get_current_unite().prompt_linenr

  if !is_insert && line('.') > prompt_linenr
    call cursor(line('.') - 1, 0)
    return
  endif

  " Loop.

  call s:redraw_all_candidates()

  if is_insert
    noautocmd startinsert
  endif

  call cursor(line('$'), 1)
endfunction"}}}
function! unite#mappings#loop_cursor_up_expr(is_skip_not_matched) "{{{
  let is_insert = mode() ==# 'i'
  let prompt_linenr = unite#get_current_unite().prompt_linenr

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
function! s:narrowing_path() "{{{
  if line('.') <= unite#get_current_unite().prompt_linenr
    " Ignore.
    return
  endif

  let candidate = unite#helper#get_current_candidate()
  call unite#mappings#narrowing(has_key(candidate, 'action__path')?
        \ candidate.action__path : candidate.word)
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
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
