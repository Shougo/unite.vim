"=============================================================================
" FILE: mappings.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 29 Sep 2010
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
  nnoremap <silent><buffer> <Plug>(unite_do_default_action)  :<C-u>call unite#mappings#do_action('default')<CR>
  nnoremap <silent><buffer> <Plug>(unite_do_delete_action)  :<C-u>call unite#mappings#do_action('delete')<CR>
  nnoremap <silent><buffer> <Plug>(unite_do_bookmark_action)  :<C-u>call unite#mappings#do_action('bookmark')<CR>
  nnoremap <silent><buffer> <Plug>(unite_do_preview_action)  :<C-u>call unite#mappings#do_action('preview')<CR>
  nnoremap <silent><buffer> <Plug>(unite_do_narrow_action)  :<C-u>call unite#mappings#do_action('narrow')<CR>
  nnoremap <silent><buffer> <Plug>(unite_choose_action)  :<C-u>call <SID>choose_action()<CR>
  nnoremap <silent><buffer> <Plug>(unite_insert_enter)  :<C-u>call <SID>insert_enter()<CR>
  nnoremap <silent><buffer> <Plug>(unite_insert_head)  :<C-u>call <SID>insert_head()<CR>
  nnoremap <silent><buffer><expr> <Plug>(unite_append_enter)  col('.') == col('$') ? "\:<C-u>call \<SID>append_enter()\<CR>" : ":\<C-u>call \<SID>append_end()\<CR>"
  nnoremap <silent><buffer> <Plug>(unite_append_end)  :<C-u>call <SID>append_end()<CR>
  nnoremap <silent><buffer> <Plug>(unite_toggle_mark_current_candidate)  :<C-u>call <SID>toggle_mark()<CR>
  nnoremap <silent><buffer> <Plug>(unite_redraw)  :<C-u>call <SID>redraw()<CR>
  nnoremap <silent><buffer> <Plug>(unite_search_next_source)  :<C-u>call <SID>search_source(1)<CR>
  nnoremap <silent><buffer> <Plug>(unite_search_previous_source)  :<C-u>call <SID>search_source(0)<CR>
  nnoremap <silent><buffer> <Plug>(unite_print_candidate)  :<C-u>call <SID>print_candidate()<CR>
  nnoremap <buffer> <Plug>(unite_cursor_top)  2G0z.
  nnoremap <buffer><expr> <Plug>(unite_loop_cursor_down)  (line('.') == line('$'))? '2G0z.' : 'j'
  nnoremap <buffer><expr> <Plug>(unite_loop_cursor_up)  (line('.') <= 2)? 'G' : 'k'
  
  vnoremap <buffer><silent> <Plug>(unite_toggle_mark_selected_candidates)  :<C-u>call <SID>toggle_mark_candidates(getpos("'<")[1], getpos("'>")[1])<CR>
  
  inoremap <silent><buffer> <Plug>(unite_exit)  <ESC>:<C-u>call <SID>exit()<CR>
  inoremap <buffer><expr> <Plug>(unite_insert_leave)  unite#mappings#smart_imap("\<ESC>j", "\<ESC>0")
  inoremap <expr><buffer> <Plug>(unite_delete_backward_char)  col('.') <= (len(b:unite.prompt)+1) ? '' : "\<C-h>"
  inoremap <expr><buffer> <Plug>(unite_delete_backward_line)  repeat("\<C-h>", col('.')-(len(b:unite.prompt)+1))
  inoremap <expr><buffer> <Plug>(unite_delete_backward_word)  col('.') <= (len(b:unite.prompt)+1) ? '' : "\<C-w>"
  inoremap <expr><buffer> <Plug>(unite_select_next_line)  pumvisible() ? "\<C-n>" : line('.') == line('$') ? "\<C-Home>\<Down>\<Down>" : "\<Home>\<Down>"
  inoremap <expr><buffer> <Plug>(unite_select_previous_line)  pumvisible() ? "\<C-p>" : line('.') <= 3 ? "\<C-End>\<Home>" : "\<Home>\<Up>"
  inoremap <expr><buffer> <Plug>(unite_select_next_page)  pumvisible() ? "\<PageDown>" : repeat("\<Down>", winheight(0))
  inoremap <expr><buffer> <Plug>(unite_select_previous_page)  pumvisible() ? "\<PageUp>" : repeat("\<Up>", winheight(0))
  inoremap <silent><buffer> <Plug>(unite_do_default_action) <C-o>:call unite#mappings#do_action('default')<CR>
  inoremap <silent><buffer> <Plug>(unite_toggle_mark_current_candidate)  <C-o>:<C-u>call <SID>toggle_mark()<CR>
  inoremap <silent><buffer> <Plug>(unite_choose_action)  <C-o>:<C-u>call <SID>choose_action()<CR>
  inoremap <silent><buffer> <Plug>(unite_move_head)  <C-o>:<C-u>call <SID>insert_head()<CR>
  "}}}
  
  if exists('g:unite_no_default_keymappings') && g:unite_no_default_keymappings
    return
  endif
  
  " Normal mode key-mappings.
  nmap <buffer> <ESC> <Plug>(unite_exit)
  nmap <buffer> i <Plug>(unite_insert_enter)
  nmap <buffer> I <Plug>(unite_insert_head)
  nmap <buffer> a <Plug>(unite_append_enter)
  nmap <buffer> A <Plug>(unite_append_end)
  nmap <buffer> q <Plug>(unite_exit)
  nmap <buffer> <CR> <Plug>(unite_do_default_action)
  nmap <buffer> d <Plug>(unite_do_delete_action)
  nmap <buffer> b <Plug>(unite_do_bookmark_action)
  nmap <buffer> e <Plug>(unite_do_narrow_action)
  nmap <buffer> <Space> <Plug>(unite_toggle_mark_current_candidate)
  nmap <buffer> <Tab> <Plug>(unite_choose_action)
  nmap <buffer> <C-n> <Plug>(unite_search_next_source)
  nmap <buffer> <C-p> <Plug>(unite_search_previous_source)
  nmap <buffer><expr><silent> l line('.') <= 2 ? 'l' : "\<Plug>(unite_do_default_action)"
  nmap <buffer> <C-g> <Plug>(unite_print_candidate)
  nmap <buffer> p <Plug>(unite_do_preview_action)
  nmap <buffer> <C-l> <Plug>(unite_redraw)
  nmap <buffer> gg <Plug>(unite_cursor_top)
  nmap <buffer> j <Plug>(unite_loop_cursor_down)
  nmap <buffer> k <Plug>(unite_loop_cursor_up)

  " Visual mode key-mappings.
  xmap <buffer> <Space> <Plug>(unite_toggle_mark_selected_candidates)

  " Insert mode key-mappings.
  imap <buffer> <ESC>     <Plug>(unite_insert_leave)
  imap <buffer> <TAB>     <Plug>(unite_choose_action)
  imap <buffer> <S-TAB>   <Plug>(unite_select_previous_line)
  imap <buffer> <C-n>     <Plug>(unite_select_next_line)
  imap <buffer> <C-p>   <Plug>(unite_select_previous_line)
  imap <buffer> <C-f>     <Plug>(unite_select_next_page)
  imap <buffer> <C-b>   <Plug>(unite_select_previous_page)
  imap <buffer> <CR>      <Plug>(unite_do_default_action)
  imap <buffer> <C-h>     <Plug>(unite_delete_backward_char)
  imap <buffer> <BS>     <Plug>(unite_delete_backward_char)
  imap <buffer> <C-u>     <Plug>(unite_delete_backward_line)
  imap <buffer> <C-w>     <Plug>(unite_delete_backward_word)
  imap <buffer> <C-a>     <Plug>(unite_move_head)
  imap <buffer> <Home>     <Plug>(unite_move_head)
  imap <buffer><expr> <Space>  unite#mappings#smart_imap(' ', "\<Plug>(unite_toggle_mark_current_candidate)")
  inoremap <buffer><expr> /    unite#mappings#smart_imap((col('.') <= (len(b:unite.prompt)+1) ? '/' : '*/'), 
        \ "\<C-o>:\<C-u>call unite#mappings#do_action('narrow')\<CR>")
endfunction"}}}

" key-mappings functions.
function! unite#mappings#narrowing(word)"{{{
  setlocal modifiable
  call setline(2, '>' . escape(a:word, ' *'))
  2
  startinsert!
endfunction"}}}
function! unite#mappings#do_action(action_name)"{{{
  let l:candidates = unite#get_marked_candidates()
  if empty(l:candidates)
    if line('.') <= 2
      if line('$') < 3
        " Ignore.
        return
      endif

      let l:num = 0
    else
      let l:num = line('.') - 3
    endif

    let l:candidates = [ unite#get_unite_candidates()[l:num] ]
  endif
  
  let l:is_redraw = 0
  for l:candidate in l:candidates
    let l:action_table = unite#get_action_table(l:candidate.source, l:candidate.kind)
    
    let l:action_name = 
          \ a:action_name ==# 'default' ?
          \ unite#get_default_action(l:candidate.source, l:candidate.kind)
          \ : a:action_name
    
    if has_key(l:action_table, l:action_name)
      let l:action = l:action_table[l:action_name]
      
      " Check selectable flag.
      if has_key(l:action, 'is_selectable') && !l:action.is_selectable
            \ && len(l:candidates) > 1
        " Ignore.
        echohl Error | execute 'echo' printf('"%s" isn''t selectable action.', l:action_name) | echohl None
        continue
      endif
      
      " Check quit flag.
      if !has_key(l:action, 'is_quit') || l:action.is_quit
        call unite#quit_session()
      endif
      
      call l:action.func(l:candidate)
      
      " Check invalidate cache flag.
      if has_key(l:action, 'is_invalidate_cache') && l:action.is_invalidate_cache
        call unite#invalidate_cache(l:candidate.source)
        let l:is_redraw = 1
      endif
    endif
  endfor

  if l:is_redraw
    call unite#force_redraw()
  endif
endfunction"}}}
function! unite#mappings#smart_imap(narrow_map, select_map)"{{{
  return line('.')  == 2 ? a:narrow_map : a:select_map
endfunction"}}}
function! s:exit()"{{{
  call unite#quit_session()
endfunction"}}}
function! s:toggle_mark()"{{{
  if line('.') <= 2
    " Ignore.
    return
  endif
  
  let l:candidate = unite#get_unite_candidates()[line('.') - 3]
  let l:candidate.unite__is_marked = !l:candidate.unite__is_marked
  call unite#redraw_line()
  
  normal! j
endfunction"}}}
function! s:toggle_mark_candidates(start, end)"{{{
  if a:start <= 2
    " Ignore.
    return
  endif
  
  let l:cnt = a:start
  while l:cnt <= a:end
    let l:candidate = unite#get_unite_candidates()[l:cnt - 3]
    let l:candidate.unite__is_marked = !l:candidate.unite__is_marked
    
    call unite#redraw_line(l:cnt)

    let l:cnt += 1
  endwhile
endfunction"}}}
function! s:choose_action()"{{{
  let l:candidates = unite#get_marked_candidates()
  if empty(l:candidates)
    if line('.') <= 2
      if line('$') < 3
        " Ignore.
        return
      endif

      let l:num = 0
    else
      let l:num = line('.') - 3
    endif

    let l:candidates = [ unite#get_unite_candidates()[l:num] ]
  endif
  
  echohl Statement | echo 'Candidates:' | echohl None
  
  let s:actions = {}
  for l:candidate in l:candidates
    " Print candidates.
    echo l:candidate.abbr . '('
    echohl Type | echon l:candidate.source | echohl None
    echon ')'
    
    let l:action_table = unite#get_action_table(l:candidate.source, l:candidate.kind)
    
    for [l:action_name, l:action] in items(l:action_table)
      " Check selectable flag.
      if has_key(l:action, 'is_selectable') && !l:action.is_selectable
            \ && len(l:candidates) > 1
        " Ignore.
        echohl Error | execute 'echo' printf('"%s" isn''t selectable action.', l:action_name) | echohl None
      else
        let s:actions[l:action_name] = l:action
      endif
    endfor
  endfor

  " Print action names.
  let l:width = winwidth(0)
  let l:max = l:width > 90 ? 6 : l:width > 75 ? 5 : l:width > 50 ? 4 : 3
  let l:cnt = 0
  
  echohl Identifier
  echo ''
  for l:action_name in keys(s:actions)
    echon unite#util#truncate(l:action_name, 14) . ' '
    let l:cnt += 1
    
    if l:cnt >= l:max
      echo ''
      let l:cnt = 0
    endif
  endfor
  echohl None
  
  let l:input = ''
  while 1
    " Choose action.
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
  if line('.') != 2 || col('.') == 1
    2
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
  call unite#force_redraw()
endfunction"}}}
function! s:search_source(is_next)"{{{
  let l:new_pos = getpos('.')
  
  let l:current_source = line('.') < 2 ? '' : matchstr(getline('.'), '[[:space:]]\zs[a-z_-]\+$')

  3
  let l:poses = []
  let i = 0
  let l:current_pos = -1
  for l:source in unite#available_sources_name()
    let l:pos = searchpos(l:source . '$', 'W')
    if l:pos[0] != 0
      if l:current_source ==# l:source
        let l:current_pos = len(l:poses)
      endif
      
      call add(l:poses, l:pos)
    endif

    let i += 1
  endfor
  
  if a:is_next
    if l:current_pos + 1 < len(l:poses)
      let l:new_pos[1] = l:poses[l:current_pos + 1][0]
      let l:new_pos[2] = l:poses[l:current_pos + 1][1]
    endif
  else
    if l:current_pos >= 1
      let l:new_pos[1] = l:poses[l:current_pos - 1][0]
      let l:new_pos[2] = l:poses[l:current_pos - 1][1]
    endif
  endif

  call setpos('.', l:new_pos)
  normal! 0
endfunction"}}}
function! s:print_candidate()"{{{
  if line('.') <= 2
    " Ignore.
    return
  endif

  let l:candidate = unite#get_unite_candidates()[line('.') - 3]
  echo l:candidate.word
endfunction"}}}
function! s:insert_selected_candidate()"{{{
  if line('.') <= 2
    " Ignore.
    return
  endif

  let l:candidate = unite#get_unite_candidates()[line('.') - 3]
  call unite#mappings#narrowing(l:candidate.word)
endfunction"}}}

function! unite#mappings#complete_actions(arglead, cmdline, cursorpos)"{{{
  return filter(keys(s:actions), printf('stridx(v:val, %s) == 0', string(a:arglead)))
endfunction"}}}

" vim: foldmethod=marker
