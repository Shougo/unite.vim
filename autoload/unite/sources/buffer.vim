"=============================================================================
" FILE: buffer.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 16 Oct 2010
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
        \ 'bufnr' : l:bufnr, 'time' : localtime(),
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
        \ bufexists(v:val.bufnr) && buflisted(v:val.bufnr) && v:val.bufnr != ' . bufnr('#'))), 's:compare')

  if buflisted(bufnr('#'))
    " Add current buffer.
    let l:list = add(l:list, s:buffer_list[bufnr('#')])
  endif

  let l:candidates = map(l:list, '{
        \ "word" : bufname(v:val.bufnr),
        \ "abbr" : s:make_abbr(v:val.bufnr),
        \ "kind" : "buffer",
        \ "source" : "buffer",
        \ "unite_buffer_nr" : v:val.bufnr,
        \}')

  return l:candidates
endfunction"}}}

let s:source_buffer_tab = {
      \ 'name' : 'buffer_tab',
      \}

function! s:source_buffer_tab.gather_candidates(args, context)"{{{
  let l:list = sort(values(filter(copy(s:buffer_list), '
        \ bufexists(v:val.bufnr) && buflisted(v:val.bufnr)
        \ && exists("t:unite_buffer_dictionary") && has_key(t:unite_buffer_dictionary, v:val.bufnr) && v:val.bufnr != ' . bufnr('#'))), 's:compare')

  if buflisted(bufnr('#'))
    " Add current buffer.
    let l:list = add(l:list, s:buffer_list[bufnr('#')])
  endif

  let l:candidates = map(l:list, '{
        \ "word" : bufname(v:val.bufnr),
        \ "abbr" : s:make_abbr(v:val.bufnr),
        \ "kind" : "buffer",
        \ "source" : "buffer_tab",
        \ "unite_buffer_nr" : v:val.bufnr,
        \}')

  return l:candidates
endfunction"}}}

" Misc
function! s:make_abbr(bufnr)"{{{
  let l:filetype = getbufvar(a:bufnr, '&filetype')
  if l:filetype ==# 'vimfiler'
    let l:bufvar = getbufvar(a:bufnr, 'vimfiler')
    return '*vimfiler* - ' . l:bufvar.current_dir
  elseif l:filetype ==# 'vimshell'
    let l:bufvar = getbufvar(a:bufnr, 'vimshell')
    return '*vimshell* - ' . l:bufvar.save_dir
  else
    return bufname(a:bufnr) . (getbufvar(a:bufnr, '&modified') ? '[+]' : '')
  endif
endfunction"}}}
function! s:compare(candidate_a, candidate_b)"{{{
  return a:candidate_b.time - a:candidate_a.time
endfunction"}}}

" vim: foldmethod=marker
