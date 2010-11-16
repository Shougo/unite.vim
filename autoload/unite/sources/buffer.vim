"=============================================================================
" FILE: buffer.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 05 Nov 2010
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
      \}

function! s:source_buffer_all.gather_candidates(args, context)"{{{
  let l:list = sort(values(filter(copy(s:buffer_list), '
        \ bufexists(v:val.action__buffer_nr) && buflisted(v:val.action__buffer_nr) && v:val.action__buffer_nr != ' . bufnr('#'))), 's:compare')

  if buflisted(bufnr('#'))
    " Add current buffer.
    let l:list = add(l:list, s:buffer_list[bufnr('#')])
  endif

  let l:candidates = map(l:list, '{
        \ "word" : s:make_abbr(v:val.action__buffer_nr),
        \ "kind" : "buffer",
        \ "source" : "buffer",
        \ "action__path" : unite#substitute_path_separator(bufname(v:val.action__buffer_nr)),
        \ "action__buffer_nr" : v:val.action__buffer_nr,
        \ "action__directory" : s:get_directory(v:val.action__buffer_nr),
        \}')

  return l:candidates
endfunction"}}}

let s:source_buffer_tab = {
      \ 'name' : 'buffer_tab',
      \}

function! s:source_buffer_tab.gather_candidates(args, context)"{{{
  let l:list = sort(values(filter(copy(s:buffer_list), '
        \ bufexists(v:val.action__buffer_nr) && buflisted(v:val.action__buffer_nr)
        \ && exists("t:unite_buffer_dictionary") && has_key(t:unite_buffer_dictionary, v:val.action__buffer_nr) && v:val.action__buffer_nr != ' . bufnr('#'))), 's:compare')

  if buflisted(bufnr('#'))
    " Add current buffer.
    let l:list = add(l:list, s:buffer_list[bufnr('#')])
  endif

  let l:candidates = map(l:list, '{
        \ "word" : s:make_abbr(v:val.action__buffer_nr),
        \ "kind" : "buffer",
        \ "source" : "buffer_tab",
        \ "action__path" : unite#substitute_path_separator(bufname(v:val.action__buffer_nr)),
        \ "action__buffer_nr" : v:val.action__buffer_nr,
        \ "action__directory" : s:get_directory(v:val.action__buffer_nr),
        \}')

  return l:candidates
endfunction"}}}

" Misc
function! s:make_abbr(bufnr)"{{{
  let l:filetype = getbufvar(a:bufnr, '&filetype')
  if l:filetype ==# 'vimfiler'
    let l:path = getbufvar(a:bufnr, 'vimfiler').current_dir
    let l:path = '*vimfiler* - ' . unite#substitute_path_separator(simplify(l:path))
  elseif l:filetype ==# 'vimshell'
    let l:path = getbufvar(a:bufnr, 'vimshell').save_dir
    let l:path = '*vimshell* - ' . unite#substitute_path_separator(simplify(l:path))
  else
    let l:path = bufname(a:bufnr) . (getbufvar(a:bufnr, '&modified') ? '[+]' : '')
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

" vim: foldmethod=marker
