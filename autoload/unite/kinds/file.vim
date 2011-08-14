"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 15 Aug 2011.
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
if !exists('g:unite_kind_file_delete_command')
  if unite#util#is_win() && !executable('rm')
    " Can't support.
    let g:unite_kind_file_delete_command = ''
  else
    let g:unite_kind_file_delete_command = 'rm -r $srcs'
  endif
endif
if !exists('g:unite_kind_file_copy_command')
  if unite#util#is_win() && !executable('cp')
    " Can't support.
    let g:unite_kind_file_copy_command = ''
  else
    let g:unite_kind_file_copy_command = 'cp -p -r $srcs $dest'
  endif
endif
if !exists('g:unite_kind_file_move_command')
  if unite#util#is_win() && !executable('mv')
    let g:unite_kind_file_move_command = 'move /Y $srcs $dest'
  else
    let g:unite_kind_file_move_command = 'mv $srcs $dest'
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
      \ 'alias_table' : {
      \   'vimfiler__rename' : 'rename',
      \   'copy'   : 'vimfiler__copy',
      \   'move' : 'vimfiler__move',
      \   'vimfiler__execute' : 'start',
      \ },
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
    let l:filename = input(printf('New file name: %s -> ', l:candidate.action__path), l:candidate.action__path)
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
  if g:unite_kind_file_move_command == ''
    call unite#print_error("Please install mv.exe.")
    return 1
  endif

  let l:yes = unite#util#input_yesno('Really move files?')

  if !l:yes
    redraw
    echo 'Canceled.'
    return
  endif

  let l:context = unite#get_context()
  let l:dest_dir = has_key(l:context, 'vimfiler__dest_directory') ?
        \ l:context.vimfiler__dest_directory :
        \ unite#util#input_directory('Input destination directory: ')
  if l:dest_dir !~ '/'
    let l:dest_dir .= '/'
  endif

  let l:dest_drive = matchstr(l:dest_dir, '^\a\+\ze:')
  let l:overwrite_method = ''
  let l:is_reset_method = 1
  for l:candidate in a:candidates
    " Overwrite check.
    let l:filename = l:candidate.action__path
    let l:dest_filename = l:dest_dir . fnamemodify(l:filename, ':t')
    if filereadable(l:dest_filename) || isdirectory(l:dest_filename)"{{{
      if l:overwrite_method == ''
        let l:overwrite_method =
              \ s:input_overwrite_method(l:dest_filename, l:filename)
        if l:overwrite_method =~ '^\u'
          " Same overwrite.
          let l:is_reset_method = 0
        endif
      endif

      if l:overwrite_method =~? '^f'
        " Ignore.
      elseif l:overwrite_method =~? '^t'
        if getftime(l:filename) <= getftime(l:dest_filename)
          continue
        endif
      elseif l:overwrite_method =~? '^u'
        let l:filename .= '_'
      elseif l:overwrite_method =~? '^n'
        if l:is_reset_method
          let l:overwrite_method = ''
        endif

        continue
      elseif l:overwrite_method =~? '^r'
        let l:filename = input(printf('New name: %s -> ', l:filename), l:filename)
      endif

      if l:is_reset_method
        let l:overwrite_method = ''
      endif
    endif"}}}

    if isdirectory(l:filename) && unite#util#is_win()
          \ && matchstr(l:filename, '^\a\+\ze:') !=? l:dest_drive
      " move command doesn't supported directory over drive move in Windows.
      if g:unite_kind_file_copy_command == ''
        call unite#print_error("Please install cp.exe.")
        return 1
      elseif g:unite_kind_file_delete_command == ''
        call unite#print_error("Please install rm.exe.")
        return 1
      endif

      let l:ret = s:kind.action_table.vimfiler__copy.func([l:candidate])
      if l:ret
        call unite#print_error('Failed file move: ' . l:filename)
        return 1
      endif

      let l:ret = s:kind.action_table.vimfiler__delete.func([l:candidate])
      if l:ret
        call unite#print_error('Failed file delete: ' . l:filename)
        return 1
      endif
    else
      let l:ret = s:external('move', l:dest_dir, [l:filename])
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
function! s:kind.action_table.vimfiler__copy.func(candidates)"{{{
  if g:unite_kind_file_copy_command == ''
    call unite#print_error("Please install cp.exe.")
    return 1
  endif

  let l:context = unite#get_context()
  let l:dest_dir = has_key(l:context, 'vimfiler__dest_directory') ?
        \ l:context.vimfiler__dest_directory :
        \ unite#util#input_directory('Input destination directory: ')
  if l:dest_dir !~ '/'
    let l:dest_dir .= '/'
  endif

  let l:overwrite_method = ''
  let l:is_reset_method = 1
  for l:candidate in a:candidates
    " Overwrite check.
    let l:filename = l:candidate.action__path
    let l:dest_filename = l:dest_dir . fnamemodify(l:filename, ':t')
    if filereadable(l:dest_filename) || isdirectory(l:dest_filename)"{{{
      if l:overwrite_method == ''
        let l:overwrite_method =
              \ s:input_overwrite_method(l:dest_filename, l:filename)
        if l:overwrite_method =~ '^\u'
          " Same overwrite.
          let l:is_reset_method = 0
        endif
      endif

      if l:overwrite_method =~? '^f'
        " Ignore.
      elseif l:overwrite_method =~? '^t'
        if getftime(l:filename) <= getftime(l:dest_filename)
          continue
        endif
      elseif l:overwrite_method =~? '^u'
        let l:filename .= '_'
      elseif l:overwrite_method =~? '^n'
        if l:is_reset_method
          let l:overwrite_method = ''
        endif

        continue
      elseif l:overwrite_method =~? '^r'
        let l:filename = input(printf('New name: %s -> ', l:filename), l:filename)
      endif

      if l:is_reset_method
        let l:overwrite_method = ''
      endif
    endif"}}}

    let l:ret = s:external('copy', l:dest_dir, [l:filename])
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
  if g:unite_kind_file_delete_command == ''
    call unite#print_error("Please install rm.exe.")
    return 1
  endif

  let l:yes = unite#util#input_yesno('Really force delete files?')

  if !l:yes
    redraw
    echo 'Canceled.'
    return
  endif

  " Execute force delete.
  for l:candidate in a:candidates
    let l:ret = s:external('delete', '', [l:candidate.action__path])

    if l:ret
      call unite#print_error('Failed file delete: ' . l:candidate.action__path)
    endif
  endfor
endfunction"}}}
"}}}

function! s:execute_command(command, candidate)"{{{
  let l:dir = unite#util#path2directory(a:candidate.action__path)
  " Auto make directory.
  if !isdirectory(l:dir) && unite#util#input_yesno(
        \   printf('"%s" does not exist. Create? [y/N]', l:dir))
    call mkdir(iconv(l:dir, &encoding, &termencoding), 'p')
  endif

  silent call unite#util#smart_execute_command(a:command, a:candidate.action__path)
endfunction"}}}
function! s:external(command, dest_dir, src_files)"{{{
  let l:command_line = g:unite_kind_file_{a:command}_command

  " Substitute pattern.
  let l:command_line = substitute(l:command_line,
        \'\$srcs\>', join(map(a:src_files, '''"''.v:val.''"''')), 'g')
  let l:command_line = substitute(l:command_line,
        \'\$dest\>', '"'.a:dest_dir.'"', 'g')

  let l:output = unite#util#system(l:command_line)

  echon l:output

  return unite#util#get_last_status()
endfunction"}}}
function! s:input_overwrite_method(dest, src)"{{{
  redraw
  echo 'File is already exists!'
  echo printf('dest: %s %d bytes %s', a:dest, getfsize(a:dest),
        \ strftime('%y/%m/%d %H:%M', getftime(a:dest)))
  echo printf('src:  %s %d bytes %s', a:src, getfsize(a:src),
        \ strftime('%y/%m/%d %H:%M', getftime(a:src)))

  echo 'Please select overwrite method(Upper case is all).'
  let l:method = input('f[orce]/t[ime]/u[nder]/n[o]/r[ename] : ')
  while l:method !~? '^\%(f\%[orce]\|t\%[ime]\|u\%[nder]\|n\%[o]\|r\%[ename]\)$'
    " Retry.
    let l:method = input('[force/time/under/no/rename] : ')
  endwhile

  return l:method
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
