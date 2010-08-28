"=============================================================================
" FILE: mappings.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 28 Aug 2010
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
  inoremap <silent><buffer> <Plug>(unite_exit)  :<C-u>call <SID>exit()<CR>
  inoremap <buffer><expr> <Plug>(unite_insert_leave)  line('.') == 2 ? "\<ESC>j" : "\<ESC>0"
  inoremap <expr><buffer> <Plug>(unite_delete_backward_char)  col('.') == 2 ? '' : "\<C-h>"
  inoremap <expr><buffer> <Plug>(unite_delete_backward_line)  repeat("\<C-h>", col('.')-2)
  inoremap <expr><buffer> <Plug>(unite_delete_backward_word)  col('.') == 2 ? '' : "\<C-w>"
  inoremap <expr><buffer> <Plug>(unite_select_next_line)  pumvisible() ? "\<C-n>" : "\<Down>"
  inoremap <expr><buffer> <Plug>(unite_select_previous_line)  pumvisible() ? "\<C-p>" : "\<Up>"
  inoremap <expr><buffer> <Plug>(unite_select_next_page)  pumvisible() ? "\<PageDown>" : repeat("\<Down>", winheight(0))
  inoremap <expr><buffer> <Plug>(unite_select_previous_page)  pumvisible() ? "\<PageUp>" : repeat("\<Up>", winheight(0))
  inoremap <silent><expr><buffer> <Plug>(unite_enter) line('.') <= 2 ?
        \ "\<ESC>2G:call \<SID>do_action('default')\<CR>"
        \ : "\<ESC>:\<C-u>call \<SID>insert_selected_candidate()\<CR>"
  
  nnoremap <silent><buffer> <Plug>(unite_exit)  :<C-u>call <SID>exit()<CR>
  nnoremap <silent><buffer> <Plug>(unite_do_default_action)  :<C-u>call <SID>do_action('default')<CR>
  nnoremap <silent><buffer> <Plug>(unite_do_delete_action)  :<C-u>call <SID>do_action('d')<CR>
  nnoremap <silent><buffer> <Plug>(unite_choose_action)  :<C-u>call <SID>choose_action()<CR>
  nnoremap <silent><buffer> <Plug>(unite_insert_enter)  :<C-u>call <SID>insert_enter()<CR>
  nnoremap <silent><buffer> <Plug>(unite_insert_head)  :<C-u>call <SID>insert_head()<CR>
  nnoremap <silent><buffer><expr> <Plug>(unite_append_enter)  col('.') == col('$') ? "\:<C-u>call \<SID>append_enter()\<CR>" : ":\<C-u>call \<SID>append_end()\<CR>"
  nnoremap <silent><buffer> <Plug>(unite_append_end)  :<C-u>call <SID>append_end()<CR>
  nnoremap <silent><buffer> <Plug>(unite_toggle_mark_current_file)  :<C-u>call <SID>toggle_mark()<CR>
  nnoremap <silent><buffer> <Plug>(unite_redraw)  :<C-u>call <SID>redraw()<CR>
  nnoremap <silent><buffer> <Plug>(unite_search_next_source)  :<C-u>call <SID>search_source(1)<CR>
  nnoremap <silent><buffer> <Plug>(unite_search_previous_source)  :<C-u>call <SID>search_source(0)<CR>
  nnoremap <silent><buffer> <Plug>(unite_print_candidate)  :<C-u>call <SID>print_candidate()<CR>
  nnoremap <silent><expr><buffer> <Plug>(unite_edit_candidate) line('.') <= 2 ?
        \ ":\<C-u>call \<SID>insert_enter()\<CR>" : ":\<C-u>call \<SID>insert_selected_candidate()\<CR>"
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
  nmap <buffer> <Space> <Plug>(unite_toggle_mark_current_file)
  nmap <buffer> <Tab> <Plug>(unite_choose_action)
  nmap <buffer> <C-n> <Plug>(unite_search_next_source)
  nmap <buffer> <C-p> <Plug>(unite_search_previous_source)
  nmap <buffer><expr><silent> l line('.') <= 2 ? 'l' : "\<Plug>(unite_do_default_action)"
  nmap <buffer><expr><silent> h line('.') <= 2 ? 'h' : "i../\<ESC>"
  nmap <buffer> <silent> ~ i<Plug>(unite_delete_backward_line)~/<ESC>
  nmap <buffer> <C-g> <Plug>(unite_print_candidate)
  nmap <buffer> e <Plug>(unite_edit_candidate)

  " Insert mode key-mappings.
  inoremap <buffer> <expr> /    getline(2) == '>' ? '/' : '*/'
  imap <buffer> <ESC>     <Plug>(unite_insert_leave)
  imap <buffer> <TAB>     <Plug>(unite_select_next_line)
  imap <buffer> <S-TAB>   <Plug>(unite_select_previous_line)
  imap <buffer> <C-n>     <Plug>(unite_select_next_line)
  imap <buffer> <C-p>   <Plug>(unite_select_previous_line)
  imap <buffer> <C-f>     <Plug>(unite_select_next_page)
  imap <buffer> <C-b>   <Plug>(unite_select_previous_page)
  imap <buffer> <CR>      <Plug>(unite_enter)
  imap <buffer> <C-h>     <Plug>(unite_delete_backward_char)
  imap <buffer> <BS>     <Plug>(unite_delete_backward_char)
  imap <buffer> <C-u>     <Plug>(unite_delete_backward_line)
  imap <buffer> <C-w>     <Plug>(unite_delete_backward_word)
endfunction"}}}

" key-mappings functions.
function! s:exit()"{{{
  call unite#quit_session()
endfunction"}}}
function! s:do_action(key)"{{{
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
  for l:candidate in l:candidates
    let l:source = unite#available_sources(l:candidate.source)
    if has_key(l:source.key_table, a:key)
      call l:source.action_table[l:source.key_table[a:key]](l:candidate)
    endif
  endfor

  call unite#redraw()
endfunction"}}}
function! s:toggle_mark()"{{{
  if line('.') <= 2
    " Ignore.
    return
  endif
  
  let l:candidate = unite#get_unite_candidates()[line('.') - 3]
  let l:candidate.is_marked = !l:candidate.is_marked
  call unite#redraw_current_line()
  
  normal! j
endfunction"}}}
function! s:choose_action()"{{{
endfunction"}}}
function! s:insert_enter()"{{{
  startinsert
endfunction"}}}
function! s:insert_head()"{{{
  normal! 0
  normal! l
  startinsert
endfunction"}}}
function! s:append_enter()"{{{
  startinsert
  normal! l
endfunction"}}}
function! s:append_end()"{{{
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
        echomsg len(l:poses)
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

  setlocal modifiable
  let l:candidate = unite#get_unite_candidates()[line('.') - 3]
  if has_key(l:candidate, 'is_directory') && l:candidate.is_directory
    call setline(2, '>' . escape(l:candidate.word . '/', ' *'))
    2
    startinsert!
  else
    " Do default action.
    call s:do_action('default')
  endif
endfunction"}}}

" vim: foldmethod=marker
