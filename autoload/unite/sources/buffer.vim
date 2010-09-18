"=============================================================================
" FILE: buffer.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 18 Sep 2010
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
  return s:source
endfunction"}}}
function! unite#sources#buffer#_append()"{{{
  " Append the current buffer.
  let s:buffer_list[bufnr('%')] = {
        \ 'bufnr' : bufnr('%'), 'time' : localtime()
        \ }
endfunction"}}}

let s:source = {
      \ 'name' : 'buffer',
      \}

function! s:source.gather_candidates(args)"{{{
  let l:list = values(filter(copy(s:buffer_list), 'bufexists(v:val.bufnr) && buflisted(v:val.bufnr) && v:val.bufnr != ' . bufnr('#')))
  let l:candidates = map(l:list, '{
        \ "word" : bufname(v:val.bufnr),
        \ "abbr" : s:make_abbr(v:val.bufnr),
        \ "kind" : "buffer",
        \ "source" : "buffer",
        \ "unite_buffer_nr" : v:val.bufnr,
        \ "time" : v:val.time,
        \}')

  return sort(l:candidates, 's:compare')
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
