"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
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
" Version: 0.1, for Vim 7.0
"=============================================================================

" Constants"{{{

let s:FALSE = 0
let s:TRUE = !s:FALSE

let s:LNUM_STATUS = 1
let s:LNUM_PATTERN = 2

let s:INVALID_BUFNR = -2357
let s:INVALID_COLUMN = -20091017

if has('win16') || has('win32') || has('win64')  " on Microsoft Windows
  let s:unite_BUFFER_NAME = '[unite]'
else
  let s:unite_BUFFER_NAME = '*unite*'
endif
"}}}

" Variables  "{{{
" buffer number of the unite buffer
let s:unite_bufnr = s:INVALID_BUFNR
let s:unite_sources = []
"}}}

function! unite#start(...)"{{{
  " Open or create the unite buffer.
  let v:errmsg = ''
  execute 'topleft' (bufexists(s:unite_bufnr) ? 'split' : 'new')
  if v:errmsg != ''
    return s:FALSE
  endif
  if bufexists(s:unite_bufnr)
    silent execute s:unite_bufnr 'buffer'
  else
    let s:unite_bufnr = bufnr('')
    call s:initialize_unite_buffer()
  endif
  20 wincmd _
  
  " Initialize sources.
  let s:unite_sources = []
  for l:source_name in map(split(globpath(&runtimepath, 'autoload/unite/sources/*.vim'), '\n')
        \, 'fnamemodify(v:val, ":t:r")')
      let l:source = call('unite#sources#' . l:source_name . '#define', [])
      call add(s:unite_sources, l:source)
  endfor

  silent % delete _
  normal! o
  call setline(s:LNUM_STATUS, 'Sources: ')
  call setline(s:LNUM_PATTERN, '')
  execute s:LNUM_PATTERN

  let l:candidates = s:gather_candidates('')
  call append('$', l:candidates)

  call feedkeys('A', 'n')

  return s:TRUE
endfunction"}}}

function! s:gather_candidates(args)"{{{
  let l:candidates = []
  for l:source in s:unite_sources
    for l:candidate in l:source.gather_candidates(a:args)
      call add(l:candidates, l:candidate.word)
    endfor
  endfor

  echomsg string(l:candidates)
  return l:candidates
endfunction"}}}


function! s:initialize_unite_buffer()"{{{
  " The current buffer is initialized.

  " Basic settings.
  setlocal bufhidden=hide
  setlocal buftype=nofile
  setlocal nobuflisted
  setlocal noswapfile
  silent file `=s:unite_BUFFER_NAME`

  " Autocommands.
  augroup plugin-unite
    autocmd BufLeave <buffer>  call s:quit_session()
    autocmd WinLeave <buffer>  call s:quit_session()
    " autocmd TabLeave <buffer>  call s:quit_session()  " not necessary
  augroup END

  call unite#mappings#define_default_mappings()

  " User's initialization.
  setfiletype unite

  return
endfunction"}}}

function! s:quit_session()  "{{{
  close
endfunction"}}}


" vim: foldmethod=marker
