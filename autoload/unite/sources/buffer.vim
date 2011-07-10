"=============================================================================
" FILE: buffer.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 10 Jul 2011.
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

" Variables  "{{{
let s:buffer_list = {}
"}}}

function! unite#sources#buffer#define()"{{{
  return [s:source_buffer_all, s:source_buffer_tab]
endfunction"}}}
function! unite#sources#buffer#_append()"{{{
  " Append the current buffer.
  let l:bufnr = bufnr('%')
  let s:buffer_list[l:bufnr] = {
        \ 'action__buffer_nr' : l:bufnr, 'source__time' : localtime(),
        \ }

  if !exists('t:unite_buffer_dictionary')
    let t:unite_buffer_dictionary = {}
  endif

  if exists('*gettabvar')
    " Delete same buffer in other tab pages.
    for l:tabnr in range(1, tabpagenr('$'))
      let l:buffer_dict = gettabvar(l:tabnr, 'unite_buffer_dictionary')
      if type(l:buffer_dict) == type({}) && has_key(l:buffer_dict, l:bufnr)
        call remove(l:buffer_dict, l:bufnr)
      endif
      unlet l:buffer_dict
    endfor
  endif

  let t:unite_buffer_dictionary[l:bufnr] = 1
endfunction"}}}

let s:source_buffer_all = {
      \ 'name' : 'buffer',
      \ 'description' : 'candidates from buffer list',
      \ 'syntax' : 'uniteSource__Buffer',
      \ 'hooks' : {},
      \}

function! s:source_buffer_all.hooks.on_init(args, context)"{{{
  let a:context.source__buffer_list = s:get_buffer_list()
endfunction"}}}
function! s:source_buffer_all.hooks.on_syntax(args, context)"{{{
  syntax match uniteSource__Buffer_Directory /\[.*\]/ contained containedin=uniteSource__Buffer
  highlight default link uniteSource__Buffer_Directory PreProc
endfunction"}}}

function! s:source_buffer_all.gather_candidates(args, context)"{{{
  if a:context.is_redraw
    " Recaching.
    let a:context.source__buffer_list = s:get_buffer_list()
  endif

  let l:candidates = map(copy(a:context.source__buffer_list), '{
        \ "word" : s:make_word(v:val.action__buffer_nr),
        \ "abbr" : s:make_abbr(v:val.action__buffer_nr),
        \ "kind" : "buffer",
        \ "action__path" : unite#substitute_path_separator(bufname(v:val.action__buffer_nr)),
        \ "action__buffer_nr" : v:val.action__buffer_nr,
        \ "action__directory" : s:get_directory(v:val.action__buffer_nr),
        \}')

  return l:candidates
endfunction"}}}

let s:source_buffer_tab = {
      \ 'name' : 'buffer_tab',
      \ 'description' : 'candidates from buffer list in current tab',
      \ 'syntax' : 'uniteSource__BufferTab',
      \ 'hooks' : {},
      \}

function! s:source_buffer_tab.hooks.on_init(args, context)"{{{
  let a:context.source__buffer_list = s:get_buffer_list()
endfunction"}}}
function! s:source_buffer_tab.hooks.on_syntax(args, context)"{{{
  syntax match uniteSource__BufferTab_Directory /\[.*\]/ containedin=uniteSource__BufferTab
  highlight default link uniteSource__BufferTab_Directory PreProc
endfunction"}}}

function! s:source_buffer_tab.gather_candidates(args, context)"{{{
  if a:context.is_redraw
    " Recaching.
    let a:context.source__buffer_list = s:get_buffer_list()
  endif

  if !exists('t:unite_buffer_dictionary')
    let t:unite_buffer_dictionary = {}
  endif

  let l:list = filter(copy(a:context.source__buffer_list), 'has_key(t:unite_buffer_dictionary, v:val.action__buffer_nr)')

  let l:candidates = map(l:list, '{
        \ "word" : s:make_word(v:val.action__buffer_nr),
        \ "abbr" : s:make_abbr(v:val.action__buffer_nr),
        \ "kind" : "buffer",
        \ "action__path" : unite#substitute_path_separator(bufname(v:val.action__buffer_nr)),
        \ "action__buffer_nr" : v:val.action__buffer_nr,
        \ "action__directory" : s:get_directory(v:val.action__buffer_nr),
        \}')

  return l:candidates
endfunction"}}}

" Misc
function! s:make_word(bufnr)"{{{
  let l:filetype = getbufvar(a:bufnr, '&filetype')
  if l:filetype ==# 'vimfiler'
    let l:path = getbufvar(a:bufnr, 'vimfiler').current_dir
    let l:path = printf('*vimfiler* [%s]', unite#substitute_path_separator(simplify(l:path)))
  elseif l:filetype ==# 'vimshell'
    let l:vimshell = getbufvar(a:bufnr, 'vimshell')
    let l:path = printf('*vimshell*: [%s]',
          \ unite#substitute_path_separator(simplify(l:vimshell.save_dir)))
  else
    let l:path = unite#substitute_path_separator(simplify(bufname(a:bufnr)))
  endif

  return l:path
endfunction"}}}
function! s:make_abbr(bufnr)"{{{
  let l:filetype = getbufvar(a:bufnr, '&filetype')
  if l:filetype ==# 'vimfiler'
    let l:path = getbufvar(a:bufnr, 'vimfiler').current_dir
    let l:path = printf('*vimfiler* [%s]', unite#substitute_path_separator(simplify(l:path)))
  elseif l:filetype ==# 'vimshell'
    let l:vimshell = getbufvar(a:bufnr, 'vimshell')
    let l:path = printf('*vimshell*: %s [%s]',
          \ (has_key(l:vimshell, 'cmdline') ? l:vimshell.cmdline : ''),
          \ unite#substitute_path_separator(simplify(l:vimshell.save_dir)))
  else
    let l:path = fnamemodify(bufname(a:bufnr), ':~:.') . (getbufvar(a:bufnr, '&modified') ? '[+]' : '')
    let l:path = unite#substitute_path_separator(simplify(l:path))
  endif

  return l:path
endfunction"}}}
function! s:compare(candidate_a, candidate_b)"{{{
  return a:candidate_b.source__time - a:candidate_a.source__time
endfunction"}}}
function! s:get_directory(bufnr)"{{{
  let l:filetype = getbufvar(a:bufnr, '&filetype')
  if l:filetype ==# 'vimfiler'
    let l:dir = getbufvar(a:bufnr, 'vimfiler').current_dir
  elseif l:filetype ==# 'vimshell'
    let l:dir = getbufvar(a:bufnr, 'vimshell').save_dir
  else
    let l:path = unite#substitute_path_separator(bufname(a:bufnr))
    let l:dir = unite#path2directory(l:path)
  endif

  return l:dir
endfunction"}}}
function! s:get_buffer_list()"{{{
  " Make buffer list.
  let l:list = []
  let l:bufnr = 1
  while l:bufnr <= bufnr('$')
    if buflisted(l:bufnr) && l:bufnr != bufnr('%')
      if has_key(s:buffer_list, l:bufnr)
        call add(l:list, s:buffer_list[l:bufnr])
      else
        call add(l:list,
              \ { 'action__buffer_nr' : l:bufnr, 'source__time' : 0 })
      endif
    endif
    let l:bufnr += 1
  endwhile

  call sort(l:list, 's:compare')

  if buflisted(bufnr('%'))
    " Add current buffer.
    if has_key(s:buffer_list, bufnr('%'))
      call add(l:list, s:buffer_list[bufnr('%')])
    else
      call add(l:list,
            \ { 'action__buffer_nr' : bufnr('%'), 'source__time' : 0 })
    endif
  endif

  return l:list
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
