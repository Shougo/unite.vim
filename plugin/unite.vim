"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 24 Sep 2010
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
" Version: 1.0, for Vim 7.0
"=============================================================================

if exists('g:loaded_unite')
  finish
endif

" Global options definition."{{{
if !exists('g:unite_update_time')
  let g:unite_update_time = 400
endif
if !exists('g:unite_enable_start_insert')
  let g:unite_enable_start_insert = 0
endif
if !exists('g:unite_enable_ignore_case')
  let g:unite_enable_ignore_case = &ignorecase
endif
if !exists('g:unite_enable_smart_case')
  let g:unite_enable_smart_case = &infercase
endif
if !exists('g:unite_split_rule')
  let g:unite_split_rule = 'topleft'
endif
if !exists('g:unite_enable_split_vertically')
  let g:unite_enable_split_vertically = 0
endif
if !exists('g:unite_data_directory')
  let g:unite_data_directory = expand('~/.unite')
endif
if !isdirectory(fnamemodify(g:unite_data_directory, ':p'))
  call mkdir(fnamemodify(g:unite_data_directory, ':p'), 'p')
endif
"}}}

" Wrapper command.
command! -nargs=+ -complete=customlist,unite#complete_source Unite call s:call_unite_empty(<q-args>)
function! s:call_unite_empty(args)"{{{
  let [l:args, l:options] = s:parse_options(split(a:args, '\\\@<! '))
  call unite#start(l:args, l:options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete_source UniteWithCurrentDir call s:call_unite_current_dir(<q-args>)
function! s:call_unite_current_dir(args)"{{{
  let [l:args, l:options] = s:parse_options(split(a:args, '\\\@<! '))
  if !has_key(l:options, 'input')
    let l:path = &filetype ==# 'vimfiler' ? b:vimfiler.current_dir : substitute(fnamemodify(getcwd(), ':p'), '\\', '/', 'g')
    let l:options.input = escape(l:path.(l:path =~ '[\\/]$' ? '' : '/'), ' ')
  endif
  
  call unite#start(l:args, l:options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete_source UniteWithBufferDir call s:call_unite_buffer_dir(<q-args>)
function! s:call_unite_buffer_dir(args)"{{{
  let [l:args, l:options] = s:parse_options(split(a:args, '\\\@<! '))
  if !has_key(l:options, 'input')
    let l:path = &filetype ==# 'vimfiler' ? b:vimfiler.current_dir : substitute(fnamemodify(bufname('%'), ':p:h'), '\\', '/', 'g')
    let l:options.input = escape(l:path.(l:path =~ '[\\/]$' ? '' : '/'), ' ')
  endif
  
  call unite#start(l:args, l:options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete_source UniteWithCursorWord call s:call_unite_cursor_word(<q-args>)
function! s:call_unite_cursor_word(args)"{{{
  let [l:args, l:options] = s:parse_options(split(a:args, '\\\@<! '))
  if !has_key(l:options, 'input')
    let l:options.input = expand('<cword>')
  endif
  
  call unite#start(l:args, l:options)
endfunction"}}}

function! s:parse_options(args)"{{{
  let l:args = []
  let l:options = {}
  for l:arg in a:args
    if l:arg =~# '^-buffer-name='
      let l:options['buffer_name'] = matchstr(l:arg, '^-buffer-name=\zs.*')
    elseif l:arg =~# '^-input='
      let l:options['input'] = matchstr(l:arg, '^-input=\zs.*')
    else
      call add(l:args, l:arg)
    endif
  endfor
  
  return [l:args, l:options]
endfunction"}}}

let g:loaded_unite = 1

" __END__
" vim: foldmethod=marker
