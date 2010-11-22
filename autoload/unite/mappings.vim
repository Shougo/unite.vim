"=============================================================================
" FILE: mappings.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 22 Nov 2010
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

" Define default mappings.
function! unite#mappings#define_default_mappings()"{{{
  " Plugin keymappings"{{{
  nnoremap <silent><buffer> <Plug>(unite_exit)  :<C-u>call <SID>exit()<CR>
  nnoremap <silent><buffer> <Plug>(unite_choose_action)  :<C-u>call <SID>choose_action()<CR>
  nnoremap <silent><buffer> <Plug>(unite_insert_enter)  :<C-u>call <SID>insert_enter()<CR>
  nnoremap <silent><buffer> <Plug>(unite_insert_head)  :<C-u>call <SID>insert_head()<CR>
  nnoremap <silent><buffer><expr> <Plug>(unite_append_enter)  col('.') == col('$') ? "\:<C-u>call \<SID>append_enter()\<CR>" : ":\<C-u>call \<SID>append_end()\<CR>"
  nnoremap <silent><buffer> <Plug>(unite_append_end)  :<C-u>call <SID>append_end()<CR>
  nnoremap <silent><buffer> <Plug>(unite_toggle_mark_current_candidate)  :<C-u>call <SID>toggle_mark()<CR>
  nnoremap <silent><buffer> <Plug>(unite_redraw)  :<C-u>call <SID>redraw()<CR>
  nnoremap <silent><buffer> <Plug>(unite_rotate_next_source)  :<C-u>call <SID>rotate_source(1)<CR>
  nnoremap <silent><buffer> <Plug>(unite_rotate_previous_source)  :<C-u>call <SID>rotate_source(0)<CR>
  nnoremap <silent><buffer> <Plug>(unite_print_candidate)  :<C-u>call <SID>print_candidate()<CR>
  nnoremap <buffer><expr> <Plug>(unite_cursor_top)  b:unite.prompt_linenr.'G0z.'
  nnoremap <buffer><expr> <Plug>(unite_loop_cursor_down)  (line('.') == line('$'))? b:unite.prompt_linenr.'G0z.' : 'j'
  nnoremap <buffer><expr> <Plug>(unite_loop_cursor_up)  (line('.') <= b:unite.prompt_linenr)? 'G' : 'k'
  nnoremap <silent><buffer> <Plug>(unite_quick_match_default_action)  :<C-u>call <SID>quick_match()<CR>
  nnoremap <silent><buffer> <Plug>(unite_input_directory)   :<C-u>call <SID>input_directory()<CR>
  nnoremap <silent><buffer><expr> <Plug>(unite_do_default_action)   unite#do_action(b:unite.context.default_action)

  vnoremap <buffer><silent> <Plug>(unite_toggle_mark_selected_candidates)  :<C-u>call <SID>toggle_mark_candidates(getpos("'<")[1], getpos("'>")[1])<CR>

  inoremap <silent><buffer> <Plug>(unite_exit)  <ESC>:<C-u>call <SID>exit()<CR>
  inoremap <buffer><expr> <Plug>(unite_insert_leave)  unite#smart_map("\<ESC>j0", "\<ESC>0")
  inoremap <silent><expr><buffer> <Plug>(unite_delete_backward_char)  col('.') <= (len(b:unite.prompt)+1) ? "\<C-o>:\<C-u>call \<SID>exit()\<Cr>" : "\<C-h>"
  inoremap <expr><buffer> <Plug>(unite_delete_backward_line)  repeat("\<C-h>", col('.')-(len(b:unite.prompt)+1))
  inoremap <expr><buffer> <Plug>(unite_delete_backward_word)  col('.') <= (len(b:unite.prompt)+1) ? '' : "\<C-w>"
  inoremap <expr><buffer> <Plug>(unite_delete_backward_path)  col('.') <= (len(b:unite.prompt)+1) ? '' : <SID>delete_backward_path()
  inoremap <expr><buffer> <Plug>(unite_select_next_line)  pumvisible() ? "\<C-n>" : line('.') == line('$') ? "\<C-Home>\<End>".repeat("\<Down>", b:unite.prompt_linenr-1)
        \ : line('.') == b:unite.prompt_linenr ? "\<Home>\<Down>\<Down>" : "\<Home>\<Down>"
  inoremap <expr><buffer> <Plug>(unite_select_previous_line)  pumvisible() ? "\<C-p>" : line('.') == b:unite.prompt_linenr ? "\<C-End>\<Home>"
        \ : line('.') == (b:unite.prompt_linenr+2) ? "\<End>\<Up>\<Up>" : "\<Home>\<Up>"
  inoremap <expr><buffer> <Plug>(unite_select_next_page)  pumvisible() ? "\<PageDown>" : repeat("\<Down>", winheight(0))
  inoremap <expr><buffer> <Plug>(unite_select_previous_page)  pumvisible() ? "\<PageUp>" : repeat("\<Up>", winheight(0))
  inoremap <silent><buffer> <Plug>(unite_toggle_mark_current_candidate)  <C-o>:<C-u>call <SID>toggle_mark()<CR>
  inoremap <silent><buffer> <Plug>(unite_choose_action)  <C-o>:<C-u>call <SID>choose_action()<CR>
  inoremap <silent><buffer> <Plug>(unite_move_head)  <C-o>:<C-u>call <SID>insert_head()<CR>
  inoremap <silent><buffer> <Plug>(unite_quick_match_default_action)  <C-o>:<C-u>call <SID>quick_match()<CR>
  inoremap <silent><buffer> <Plug>(unite_input_directory)   <C-o>:<C-u>call <SID>input_directory()<CR>
  inoremap <silent><buffer><expr> <Plug>(unite_do_default_action)   unite#do_action(b:unite.context.default_action)
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

  nnoremap <buffer><expr> d   unite#smart_map('d', unite#do_action('delete'))
  nnoremap <buffer><expr> b   unite#smart_map('b', unite#do_action('bookmark'))
  nnoremap <buffer><expr> e   unite#smart_map('e', unite#do_action('narrow'))
  nnoremap <buffer><expr> l   unite#smart_map('l', unite#do_action(b:unite.context.default_action))
  nnoremap <buffer><expr> p   unite#smart_map('p', unite#do_action('preview'))
  nmap <buffer><expr> x       unite#smart_map('x', "\<Plug>(unite_quick_match_default_action)")

  " Visual mode key-mappings.
  xmap <buffer> <Space>   <Plug>(unite_toggle_mark_selected_candidates)

  " Insert mode key-mappings.
  imap <buffer> <ESC>     <Plug>(unite_insert_leave)
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

  inoremap <buffer><expr> d         unite#smart_map('d', unite#do_action('delete'))
  inoremap <buffer><expr> /         unite#smart_map('/', unite#do_action('narrow'))
  imap <buffer><expr> <Space>       unite#smart_map(' ', "\<Plug>(unite_toggle_mark_current_candidate)")
  imap <buffer><expr> x             unite#smart_map('x', "\<Plug>(unite_quick_match_default_action)")
endfunction"}}}

function! unite#mappings#narrowing(word)"{{{
  setlocal modifiable
  let b:unite.input = escape(a:word, ' *')
  call setline(b:unite.prompt_linenr, b:unite.prompt . b:unite.input)
  execute b:unite.prompt_linenr
  startinsert!
endfunction"}}}
function! unite#mappings#do_action(action_name, ...)"{{{
  let l:candidates = unite#get_marked_candidates()

  if empty(l:candidates)
    let l:num = a:0 > 0 ? a:1 : line('.') <= b:unite.prompt_linenr ? 0 : line('.') - (b:unite.prompt_linenr+1)

    if line('$')-(b:unite.prompt_linenr+1) < l:num
      " Ignore.
      return
    endif

    let l:candidates = [ unite#get_unite_candidates()[l:num] ]
  endif

  " Check action.
  let l:action_tables = []
  let Self = unite#get_self_functions()[-1]
  for l:candidate in l:candidates
    let l:action_table = unite#get_action_table(l:candidate.source, l:candidate.kind, Self)

    let l:action_name =
          \ a:action_name ==# 'default' ?
          \ unite#get_default_action(l:candidate.source, l:candidate.kind)
          \ : a:action_name

    if !has_key(l:action_table, l:action_name)
      call unite#util#print_error(l:candidate.abbr . '(' . l:candidate.source . ')')
      call unite#util#print_error('No such action : ' . l:action_name)
      return
    endif

    let l:action = l:action_table[l:action_name]

    " Check selectable flag.
    if !l:action.is_selectable && len(l:candidates) > 1
      call unite#util#print_error(l:candidate.abbr . '(' . l:candidate.source . ')')
      call unite#util#print_error('Not selectable action : ' . l:action_name)
      return
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

  " Execute action.
  let l:is_redraw = 0
  for l:table in l:action_tables
    " Check quit flag.
    if l:table.action.is_quit
      call unite#quit_session()
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
  endif
endfunction"}}}

" key-mappings functions.
function! s:exit()"{{{
  call unite#force_quit_session()
endfunction"}}}
function! s:delete_backward_path()"{{{
  let l:input = getline(b:unite.prompt_linenr)[len(b:unite.prompt):]
  return repeat("\<C-h>", len(matchstr(l:input, '[^/]*.$')))
endfunction"}}}
function! s:toggle_mark()"{{{
  if line('.') <= b:unite.prompt_linenr
    " Ignore.
    return
  endif

  let l:candidate = unite#get_unite_candidates()[line('.') - (b:unite.prompt_linenr+1)]
  let l:candidate.unite__is_marked = !l:candidate.unite__is_marked
  let l:candidate.unite__marked_time = localtime()
  call unite#redraw_line()

  normal! j
endfunction"}}}
function! s:toggle_mark_candidates(start, end)"{{{
  if a:start <= b:unite.prompt_linenr
    " Ignore.
    return
  endif

  let l:cnt = a:start
  while l:cnt <= a:end
    let l:candidate = unite#get_unite_candidates()[l:cnt - (b:unite.prompt_linenr+1)]
    let l:candidate.unite__is_marked = !l:candidate.unite__is_marked
    let l:candidate.unite__marked_time = localtime()

    call unite#redraw_line(l:cnt)

    let l:cnt += 1
  endwhile
endfunction"}}}
function! s:choose_action()"{{{
  if line('$') < (b:unite.prompt_linenr+1)
    " Ignore.
    return
  endif

  let l:candidates = unite#get_marked_candidates()
  if empty(l:candidates)
    let l:num = line('.') <= b:unite.prompt_linenr ? 0 : line('.') - (b:unite.prompt_linenr+1)

    let l:candidates = [ unite#get_unite_candidates()[l:num] ]
  endif

  echohl Statement | echo 'Candidates:' | echohl None

  let Self = unite#get_self_functions()[-1]
  let s:actions = unite#get_action_table(l:candidates[0].source, l:candidates[0].kind, Self)
  if len(l:candidates) > 1
    for l:candidate in l:candidates
      let l:action_table = unite#get_action_table(l:candidate.source, l:candidate.kind, Self)
      " Filtering unique items and check selectable flag.
      call filter(s:actions, 'has_key(l:action_table, v:key)
            \ && l:action_table[v:key].is_selectable')
    endfor
  endif

  if empty(s:actions)
    call unite#util#print_error('No actions.')
    return
  endif

  " Print candidates.
  for l:candidate in l:candidates
    " Print candidates.
    echo l:candidate.abbr . '('
    echohl Type | echon l:candidate.source | echohl None
    echon ')'
  endfor

  " Print action names.
  let l:max = max(map(keys(s:actions), 'len(v:val)'))
  for [l:action_name, l:action] in items(s:actions)
    echohl Identifier
    echo unite#util#truncate(l:action_name, l:max)
    if l:action.description != ''
      echohl Special | echon ' -- '
      echohl Comment
      echon l:action.description
    endif
  endfor
  echohl None

  " Choose action.
  let l:input = ''
  while 1
    let l:input = input('What action? ', l:input, 'customlist,unite#mappings#complete_actions')

    if l:input == ''
      " Cancel.
      return
    endif

    " Check action candidates.
    let l:actions = filter(keys(s:actions), printf('stridx(v:val, %s) == 0', string(l:input)))
    if empty(l:actions)
      echohl Error | echo 'Invalid action.' | echohl None
    elseif len(l:actions) > 1
      echohl Error | echo 'Too match action.' | echohl None
    else
      break
    endif

    echo ''
  endwhile

  " Execute action.
  call unite#mappings#do_action(l:actions[0])
endfunction"}}}
function! s:insert_enter()"{{{
  if line('.') != b:unite.prompt_linenr || col('.') == 1
    execute b:unite.prompt_linenr
    startinsert!
  else
    startinsert
  endif
endfunction"}}}
function! s:insert_head()"{{{
  normal! 0l
  call s:insert_enter()
endfunction"}}}
function! s:append_enter()"{{{
  call s:insert_enter()
  normal! l
endfunction"}}}
function! s:append_end()"{{{
  call s:insert_enter()
  startinsert!
endfunction"}}}
function! s:redraw()"{{{
  let b:unite.context.is_redraw = 1
  call unite#force_redraw()
  let b:unite.context.is_redraw = 0
endfunction"}}}
function! s:rotate_source(is_next)"{{{
  let l:max = len(unite#loaded_sources_list()) - 1
  for l:source in unite#loaded_sources_list()
    let l:source.unite__number = a:is_next ?
          \ (l:source.unite__number - 1) : (l:source.unite__number + 1)
    if l:source.unite__number < 0
      let l:source.unite__number = l:max
    elseif l:source.unite__number > l:max
      let l:source.unite__number = 0
    endif
  endfor

  call unite#redraw_status()
  call unite#redraw_candidates()
endfunction"}}}
function! s:print_candidate()"{{{
  if line('.') <= b:unite.prompt_linenr
    " Ignore.
    return
  endif

  let l:candidate = unite#get_unite_candidates()[line('.') - (b:unite.prompt_linenr+1)]
  echo l:candidate.word
endfunction"}}}
function! s:insert_selected_candidate()"{{{
  if line('.') <= b:unite.prompt_linenr
    " Ignore.
    return
  endif

  let l:candidate = unite#get_unite_candidates()[line('.') - (b:unite.prompt_linenr+1)]
  call unite#mappings#narrowing(l:candidate.word)
endfunction"}}}
function! s:quick_match()"{{{
  if line('$') < (b:unite.prompt_linenr+1)
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

  call unite#force_redraw()

  if has_key(g:unite_quick_match_table, l:char)
        \ && g:unite_quick_match_table[l:char] < len(b:unite.candidates)
    call unite#mappings#do_action(b:unite.context.default_action,
          \ g:unite_quick_match_table[l:char])
  else
    call unite#util#print_error('Invalid quick match key.')
  endif
endfunction"}}}
function! s:input_directory()"{{{
  let l:path = unite#substitute_path_separator(input('Input narrowing directory: ', unite#get_input(), 'dir'))
  let l:path = l:path.(l:path == '' || l:path =~ '/$' ? '' : '/')
  call unite#mappings#narrowing(l:path)
endfunction"}}}

function! unite#mappings#complete_actions(arglead, cmdline, cursorpos)"{{{
  return filter(keys(s:actions), printf('stridx(v:val, %s) == 0', string(a:arglead)))
endfunction"}}}

" vim: foldmethod=marker
