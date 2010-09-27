"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 27 Sep 2010
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
call unite#set_default('g:unite_source_file_ignore_pattern', 
      \'\~$\|\.\%(o|exe|dll|bak|sw[po]\)$\|\%(^\|[/\\]\)\.\%(hg\|git\|bzr\|svn\)\%($\|[/\\]\)')
"}}}

function! unite#sources#file#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'file',
      \ 'is_volatile' : 1,
      \}

function! s:source.gather_candidates(args)"{{{
  let l:input = substitute(substitute(a:args.input, '\\ ', ' ', 'g'), '^\a\+:\zs\*/', '/', '')
  
  if l:input !~ '\*'
    " Resolve link.
    let l:input = resolve(l:input)
  endif
  " Glob by directory name.
  let l:input = substitute(l:input, '/\?\zs[^/]*$', '', '')
  let l:candidates = split(substitute(glob(l:input . (l:input =~ '\*$' ? '' : '*')), '\\', '/', 'g'), '\n')

  if empty(l:candidates) && a:args.input !~ '\*'
    " Add dummy candidate.
    let l:candidates = [ a:args.input ]
  endif
  
  call map(l:candidates, '{
        \ "word" : v:val,
        \ "abbr" : v:val . (isdirectory(v:val) ? "/" : ""),
        \ "source" : "file",
        \ "kind" : (isdirectory(v:val) ? "directory" : "file"),
        \}')
  
  if g:unite_source_file_ignore_pattern != ''
    call filter(l:candidates, 'v:val.word !~ ' . string(g:unite_source_file_ignore_pattern))
  endif

  return l:candidates
endfunction"}}}

" vim: foldmethod=marker
