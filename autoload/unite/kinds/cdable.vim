"=============================================================================
" FILE: cdable.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 29 Apr 2013.
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

function! unite#kinds#cdable#define() "{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'cdable',
      \ 'action_table' : {},
      \ 'alias_table' : { 'edit' : 'narrow' },
      \}

" Actions "{{{
let s:kind.action_table.cd = {
      \ 'description' : 'change current directory',
      \ }
function! s:kind.action_table.cd.func(candidate) "{{{
  if !s:check_is_directory(a:candidate.action__directory)
    return
  endif

  if &filetype ==# 'vimfiler' || &filetype ==# 'vimshell'
    call s:external_cd(a:candidate)
  elseif a:candidate.action__directory != ''
    execute g:unite_kind_openable_cd_command '`=a:candidate.action__directory`'
  endif
endfunction"}}}

let s:kind.action_table.lcd = {
      \ 'description' : 'change window local current directory',
      \ }
function! s:kind.action_table.lcd.func(candidate) "{{{
  if !s:check_is_directory(a:candidate.action__directory)
    return
  endif

  if &filetype ==# 'vimfiler' || &filetype ==# 'vimshell'
    call s:external_cd(a:candidate)
  elseif a:candidate.action__directory != ''
    execute g:unite_kind_openable_lcd_command '`=a:candidate.action__directory`'
  endif
endfunction"}}}

let s:kind.action_table.project_cd = {
      \ 'description' : 'change current directory to project directory',
      \ }
function! s:kind.action_table.project_cd.func(candidate) "{{{
  if !s:check_is_directory(a:candidate.action__directory)
    return
  endif

  if a:candidate.action__directory == ''
    " Ignore.
    return
  endif

  let directory = unite#util#path2project_directory(
        \ a:candidate.action__directory)

  if isdirectory(directory)
    let candidate = copy(a:candidate)
    let candidate.action__directory = directory
    call s:kind.action_table.cd.func(candidate)
  endif
endfunction"}}}

let s:kind.action_table.tabnew_cd = {
      \ 'description' : 'open a new tab page here',
      \ }
function! s:kind.action_table.tabnew_cd.func(candidate) "{{{
  if !s:check_is_directory(a:candidate.action__directory)
    return
  endif

  if &filetype ==# 'vimfiler' || &filetype ==# 'vimshell'
    tabnew | call s:external_cd(a:candidate)
  elseif a:candidate.action__directory != ''
    tabnew | execute g:unite_kind_openable_cd_command '`=a:candidate.action__directory`'
  endif
endfunction"}}}

let s:kind.action_table.narrow = {
      \ 'description' : 'narrowing candidates by directory name',
      \ 'is_quit' : 0,
      \ 'is_start' : 1,
      \ }
function! s:kind.action_table.narrow.func(candidate) "{{{
  if !s:check_is_directory(a:candidate.action__directory)
    return
  endif

  call unite#start_temporary([['file'], ['file/new']])
  let directory = isdirectory(a:candidate.word) ?
        \ a:candidate.word : a:candidate.action__directory
  if directory[-1:] != '/'
    let directory .= '/'
  endif
  call unite#mappings#narrowing(directory)
endfunction"}}}

let s:kind.action_table.vimshell = {
      \ 'description' : 'open vimshell buffer here',
      \ }
function! s:kind.action_table.vimshell.func(candidate) "{{{
  if !exists(':VimShell')
    echo 'vimshell is not installed.'
    return
  endif
  if !s:check_is_directory(a:candidate.action__directory)
    return
  endif

  execute 'VimShell' escape(a:candidate.action__directory, '\ ')
endfunction"}}}

let s:kind.action_table.tabvimshell = {
      \ 'description' : 'tabopen vimshell buffer here',
      \ }
function! s:kind.action_table.tabvimshell.func(candidate) "{{{
  if !exists(':VimShellTab')
    echo 'vimshell is not installed.'
    return
  endif

  if !s:check_is_directory(a:candidate.action__directory)
    return
  endif

  execute 'VimShellTab' escape(a:candidate.action__directory, '\ ')
endfunction"}}}

let s:kind.action_table.vimfiler = {
      \ 'description' : 'open vimfiler buffer here',
      \ }
function! s:kind.action_table.vimfiler.func(candidate) "{{{
  if !exists(':VimFilerCreate')
    echo 'vimfiler is not installed.'
    return
  endif

  if !s:check_is_directory(a:candidate.action__directory)
    return
  endif

  execute 'VimFilerCreate' escape(a:candidate.action__directory, '\ ')

  if has_key(a:candidate, 'action__path')
        \ && a:candidate.action__directory !=# a:candidate.action__path
    " Move cursor.
    call vimfiler#mappings#search_cursor(a:candidate.action__path)
    call s:move_vimfiler_cursor(a:candidate)
  endif
endfunction"}}}

let s:kind.action_table.tabvimfiler = {
      \ 'description' : 'tabopen vimfiler buffer here',
      \ }
function! s:kind.action_table.tabvimfiler.func(candidate) "{{{
  if !exists(':VimFilerTab')
    echo 'vimfiler is not installed.'
    return
  endif

  if !s:check_is_directory(a:candidate.action__directory)
    return
  endif

  execute 'VimFilerTab' escape(a:candidate.action__directory, '\ ')

  if has_key(a:candidate, 'action__path')
        \ && a:candidate.action__directory !=# a:candidate.action__path
    " Move cursor.
    call vimfiler#mappings#search_cursor(a:candidate.action__path)
    call s:move_vimfiler_cursor(a:candidate)
  endif
endfunction"}}}

function! s:external_cd(candidate) "{{{
  if &filetype ==# 'vimfiler'
    call vimfiler#mappings#cd(a:candidate.action__directory)
    call s:move_vimfiler_cursor(a:candidate)
  elseif &filetype ==# 'vimshell'
    execute 'VimShell' escape(a:candidate.action__directory, '\\ ')
  endif
endfunction"}}}
function! s:move_vimfiler_cursor(candidate) "{{{
  if &filetype !=# 'vimfiler'
    return
  endif

  if has_key(a:candidate, 'action__path')
        \ && a:candidate.action__directory !=# a:candidate.action__path
    " Move cursor.
    call vimfiler#mappings#search_cursor(a:candidate.action__path)
  endif
endfunction"}}}

function! s:check_is_directory(directory)
  if !isdirectory(a:directory)
    let yesno = input(printf(
          \ 'Directory path "%s" is not exists. Create? : ', a:directory))
    redraw
    if yesno !~ '^y\%[es]$'
      echo 'Canceled.'
      return 0
    endif

    call mkdir(a:directory, 'p')
  endif

  return 1
endfunction
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
