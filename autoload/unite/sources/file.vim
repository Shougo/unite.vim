"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 07 Aug 2010
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

let s:source = {
      \ 'name' : 'file',
      \ 'key_table': {
      \      'default' : 'open',
      \    },
      \ 'action_table': {},
      \}

function! s:source.gather_candidates(args)"{{{
  let l:candidates = split(glob(a:args.cur_text.'*'), '\n')

  call map(l:candidates, '{
        \ "word" : v:val,
        \ "abbr" : v:val . (isdirectory(v:val) ? "/" : ""),
        \ "source" : "file",
        \}')

  return l:candidates
endfunction"}}}

function! s:source.action_table.open(candidate)"{{{
  return s:open('', a:candidate)
endfunction"}}}
function! s:source.action_table.open_x(candidate)"{{{
  return s:open('!', a:candidate)
endfunction"}}}

function! unite#sources#file#define()"{{{
  return s:source
endfunction"}}}

function! s:open(bang, candidate)"{{{
  let v:errmsg = ''

  call unite#leave_buffer()
  edit `=a:candidate.word`

  return v:errmsg == '' ? 0 : v:errmsg
endfunction"}}}

" vim: foldmethod=marker
