"=============================================================================
" FILE: mappings.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 18 Jul 2010
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
  inoremap <silent> <Plug>(unite_exit)  <ESC>:<C-u>call <SID>exit()<CR>
  
  nnoremap <silent> <Plug>(unite_exit)  <ESC>:<C-u>call <SID>exit()<CR>
  "}}}
  
  if exists('g:unite_no_default_keymappings') && g:unite_no_default_keymappings
    return
  endif
  
  " Normal mode key-mappings.
  nmap <buffer> <ESC> <Plug>(unite_exit)

  " Insert mode key-mappings.
  imap <buffer> <ESC>     <Plug>(unite_exit)
  imap <buffer> <CR>     :<ESC>j
  imap <buffer> <TAB>     :<ESC>j
endfunction"}}}

" key-mappings functions.
function! s:exit()"{{{
  close
endfunction"}}}

" vim: foldmethod=marker
