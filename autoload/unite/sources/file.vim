"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 14 Sep 2010
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

function! unite#sources#file#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'file',
      \ 'is_volatile' : 1,
      \}

function! s:source.gather_candidates(args)"{{{
  let l:cur_text = substitute(substitute(a:args.cur_text, '\*$\|\*\*', '', 'g'), '^\a\+:\zs\*/', '/', '')
  let l:cur_text = substitute(l:cur_text, '\\ ', ' ', 'g')
  let l:candidates = split(substitute(glob(l:cur_text . '*'), '\\', '/', 'g'), '\n')

  if empty(l:candidates) && a:args.cur_text !~ '\*'
    " Add dummy candidate.
    let l:candidates = [ a:args.cur_text ]
  endif
  
  call map(l:candidates, '{
        \ "word" : v:val,
        \ "abbr" : v:val . (isdirectory(v:val) ? "/" : ""),
        \ "source" : "file",
        \ "kind" : (isdirectory(v:val) ? "directory" : "file"),
        \}')

  return l:candidates
endfunction"}}}

" vim: foldmethod=marker
