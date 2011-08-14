"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 14 Aug 2011.
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

" Global options definition."{{{
" External commands.
if !exists('g:vimfiler_external_delete_command')
  if vimfiler#iswin() && !executable('rm')
    let g:vimfiler_external_delete_command = 'system rmdir /Q /S $srcs'
  else
    let g:vimfiler_external_delete_command = 'rm -r $srcs'
  endif
endif
if !exists('g:vimfiler_external_copy_file_command')
  if vimfiler#iswin() && !executable('cp')
    " Can't support.
    let g:vimfiler_external_copy_file_command = ''
  else
    let g:vimfiler_external_copy_file_command = 'cp -p $src $dest'
  endif
endif
if !exists('g:vimfiler_external_copy_directory_command')
  if vimfiler#iswin() && !executable('cp')
    " Can't support.
    let g:vimfiler_external_copy_directory_command = ''
  else
    let g:vimfiler_external_copy_directory_command = 'cp -p -r $src $dest'
  endif
endif
if !exists('g:vimfiler_external_move_command')
  if vimfiler#iswin() && !executable('mv')
    let g:vimfiler_external_move_command = 'move /Y $srcs $dest'
  else
    let g:vimfiler_external_move_command = 'mv $srcs $dest'
  endif
endif
"}}}

function! unite#kinds#file#define()"{{{
  return s:kind
endfunction"}}}

let s:kind = {
      \ 'name' : 'file',
      \ 'default_action' : 'open',
      \ 'action_table' : {},
      \ 'parents' : ['openable', 'cdable', 'uri'],
      \}

" Actions"{{{
let s:kind.action_table.open = {
      \ 'description' : 'open files',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.open.func(candidates)"{{{
  for l:candidate in a:candidates
    call s:execute_command('edit', l:candidate)
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview file',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate)"{{{
  if filereadable(a:candidate.action__path)
    call s:execute_command('pedit', a:candidate)
  endif
endfunction"}}}

let s:kind.action_table.mkdir = {
      \ 'description' : 'make this directory or parents directory',
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ }
function! s:kind.action_table.mkdir.func(candidate)"{{{
  if !filereadable(a:candidate.action__path)
    call mkdir(iconv(a:candidate.action__path, &encoding, &termencoding), 'p')
  endif
endfunction"}}}

let s:kind.action_table.rename = {
      \ 'description' : 'rename files',
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.rename.func(candidates)"{{{
  for l:candidate in a:candidates
    let l:filename = input(printf('New buffer name: %s -> ', l:candidate.action__path), l:candidate.action__path)
    if l:filename != '' && l:filename !=# l:candidate.action__path
      call rename(l:candidate.action__path, l:filename)
    endif
  endfor
endfunction"}}}

let s:kind.action_table.vimfiler__move = {
      \ 'description' : 'move files',
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.vimfiler__move.func(candidates)"{{{
  let l:context = unite#get_context()
  let l:dest_dir = has_key(a:context, 'vimfiler__dest_directory') ?
        \ a:context.vimfiler__dest_directory :
        \ unite#util#input_directory('Input destination directory: ')

  let l:dest_drive = matchstr(l:dest_dir, '^\a\+\ze:')
  for l:candidate in a:candidates
    let l:filename = l:candidate.action__path
    if isdirectory(l:filename) && vimfiler#iswin()
          \ && matchstr(l:filename, '^\a\+\ze:') !=? l:dest_drive
      " rename() doesn't supported directory over drive move in Windows.
      if g:vimfiler_external_copy_directory_command == ''
        call unite#print_error(
              \ "Directory move is not supported in this platform. Please install cp.exe.")
      else
        let l:ret = s:external('copy_directory', a:dest_dir, [l:filename])
        if l:ret
          call unite#print_error('Failed file move: ' . l:filename)
        else
          let l:ret = s:external('delete', '', [l:filename])
          if l:ret
            call unite#print_error('Failed file delete: ' . l:filename)
          endif
        endif
      endif
    else
      let l:ret = rename(l:filename, a:dest_dir . fnamemodify(l:file, ':t'))
      if l:ret
        call unite#print_error('Failed file move: ' . l:filename)
      endif
    endif
  endfor
endfunction"}}}

let s:kind.action_table.vimfiler__copy = {
      \ 'description' : 'copy files',
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.vimfiler__copy.func(dest_dir, src_files)"{{{
  if g:vimfiler_external_copy_directory_command == ''
        \ || g:vimfiler_external_copy_file_command == ''
    call unite#print_error(
          \ "Copy is not supported in this platform. Please install cp.exe.")
    return
  endif

  let l:dest_dir = has_key(a:context, 'vimfiler__dest_directory') ?
        \ a:context.vimfiler__dest_directory :
        \ unite#util#input_directory('Input destination directory: ')

  for l:candidate in a:candidates
    let l:filename = l:candidate.action__path
    let l:ret = isdirectory(l:filename) ?
          \ s:external('copy_directory', a:dest_dir, [l:filename]) :
          \ s:external('copy_file', a:dest_dir, [l:filename])
    if l:ret
      call unite#print_error('Failed file copy: ' . l:filename)
    endif
  endfor
endfunction"}}}

let s:kind.action_table.vimfiler__delete = {
      \ 'description' : 'delete files',
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.vimfiler__delete.func(candidates)"{{{
  let l:yes = unite#util#input_yesno('Really force delete files?')

  if !l:yes
    redraw
    echo 'Canceled.'
    return
  endif

  " Execute force delete.
  for l:candidate in a:candidates
    let l:ret = s:external('delete', '', [l:file.action__path])

    if l:ret
      call unite#print_error('Failed file delete: ' . l:file)
    endif
  endfor
endfunction"}}}
"}}}

function! s:execute_command(command, candidate)"{{{
  let l:dir = unite#util#path2directory(a:candidate.action__path)
  " Auto make directory.
  if !isdirectory(l:dir) &&
        \ input(printf('"%s" does not exist. Create? [y/N]', l:dir)) =~? '^y\%[es]$'
    call mkdir(iconv(l:dir, &encoding, &termencoding), 'p')
  endif

  silent call unite#util#smart_execute_command(a:command, a:candidate.action__path)
endfunction"}}}
function! s:external(command, dest_dir, src_files)"{{{
  let l:command_line = g:vimfiler_external_{a:command}_command

  if l:command_line =~# '\$src\>'
    for l:src in a:src_files
      let l:command_line = g:vimfiler_external_{a:command}_command

      let l:command_line = substitute(l:command_line, 
            \'\$src\>', '"'.l:src.'"', 'g') 
      let l:command_line = substitute(l:command_line, 
            \'\$dest\>', '"'.a:dest_dir.'"', 'g')

      if vimfiler#iswin() && l:command_line =~# '^system '
        let l:output = vimfiler#force_system(l:command_line[7:])
      else
        let l:output = vimfiler#system(l:command_line)
      endif
    endfor
  else
    let l:command_line = substitute(l:command_line, 
          \'\$srcs\>', join(map(a:src_files, '''"''.v:val.''"''')), 'g') 
    let l:command_line = substitute(l:command_line, 
          \'\$dest\>', '"'.a:dest_dir.'"', 'g')

    if vimfiler#iswin() && l:command_line =~# '^system '
      let l:output = vimfiler#force_system(l:command_line[7:])
    else
      let l:output = vimfiler#system(l:command_line)
    endif

    echon l:output
  endif

  return vimfiler#get_system_error()
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
