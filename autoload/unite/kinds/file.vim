"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 25 Aug 2011.
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
if !exists('g:unite_kind_file_delete_file_command')
  if unite#util#is_win() && !executable('rm')
    " Can't support.
    let g:unite_kind_file_delete_file_command = ''
  else
    let g:unite_kind_file_delete_file_command = 'rm $srcs'
  endif
endif
if !exists('g:unite_kind_file_delete_directory_command')
  if unite#util#is_win() && !executable('rm')
    " Can't support.
    let g:unite_kind_file_delete_directory_command = ''
  else
    let g:unite_kind_file_delete_directory_command = 'rm -r $srcs'
  endif
endif
if !exists('g:unite_kind_file_copy_file_command')
  if unite#util#is_win() && !executable('cp')
    " Can't support.
    let g:unite_kind_file_copy_file_command = ''
  else
    let g:unite_kind_file_copy_file_command = 'cp -p $srcs $dest'
  endif
endif
if !exists('g:unite_kind_file_copy_directory_command')
  if unite#util#is_win() && !executable('cp')
    " Can't support.
    let g:unite_kind_file_copy_directory_command = ''
  else
    let g:unite_kind_file_copy_directory_command = 'cp -p -r $srcs $dest'
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

let s:System = vital#of('unite').import('System.File')

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

    call unite#remove_previewed_buffer_list(
          \ bufnr(unite#util#escape_file_searching(
          \       l:candidate.action__path)))
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview file',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate)"{{{
  let l:buflisted = buflisted(
        \ unite#util#escape_file_searching(
        \ a:candidate.action__path))
  if filereadable(a:candidate.action__path)
    call s:execute_command('pedit', a:candidate)
  endif

  if !l:buflisted
    call unite#add_previewed_buffer_list(
        \ bufnr(unite#util#escape_file_searching(
        \       a:candidate.action__path)))
  endif
endfunction"}}}

let s:kind.action_table.mkdir = {
      \ 'description' : 'make this directory and parents directory',
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

" For vimfiler.
let s:kind.action_table.vimfiler__move = {
      \ 'description' : 'move files',
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ 'is_selectable' : 1,
      \ 'is_listed' : 0,
      \ }
function! s:kind.action_table.vimfiler__move.func(candidates)"{{{
  let l:vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if l:vimfiler_current_dir != ''
    let l:current_dir = getcwd()
    lcd `=l:vimfiler_current_dir`
  endif

  try
    if g:unite_kind_file_move_command == ''
      call unite#print_error("Please install mv.exe.")
      return 1
    endif

    let l:context = unite#get_context()
    let l:dest_dir = has_key(l:context, 'action__directory')
          \ && l:context.action__directory != '' ?
          \   l:context.action__directory :
          \   unite#util#input_directory('Input destination directory: ')
    if l:dest_dir !~ '/'
      let l:dest_dir .= '/'
    endif

    let l:dest_drive = matchstr(l:dest_dir, '^\a\+\ze:')
    let l:overwrite_method = ''
    let l:is_reset_method = 1
    for l:candidate in a:candidates
      let l:filename = l:candidate.action__path

      if isdirectory(l:filename) && unite#util#is_win()
            \ && matchstr(l:filename, '^\a\+\ze:') !=? l:dest_drive
        call s:move_to_other_drive(l:candidate, l:filename)
        continue
      endif

      " Overwrite check.
      let [l:dest_filename, l:filename,
            \ l:overwrite_method, l:is_reset_method, l:is_continue] =
            \ s:check_over_write(l:dest_dir, l:filename, l:overwrite_method,
            \                    l:is_reset_method)
      if l:is_continue
        continue
      endif

      if s:external('move', l:dest_filename, [l:filename])
        call unite#print_error('Failed file move: ' . l:filename)
      endif
    endfor
  finally
    if l:vimfiler_current_dir != ''
      lcd `=l:current_dir`
    endif
  endtry
endfunction"}}}

let s:kind.action_table.move = deepcopy(s:kind.action_table.vimfiler__move)
let s:kind.action_table.move.is_listed = 1
function! s:kind.action_table.move.func(candidates)"{{{
  if !unite#util#input_yesno('Really move files?')
    redraw
    echo 'Canceled.'
    return
  endif

  return s:kind.action_table.vimfiler__move.func(a:candidates)
endfunction"}}}

let s:kind.action_table.vimfiler__copy = {
      \ 'description' : 'copy files',
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ 'is_selectable' : 1,
      \ 'is_listed' : 0,
      \ }
function! s:kind.action_table.vimfiler__copy.func(candidates)"{{{
  let l:vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if l:vimfiler_current_dir != ''
    let l:current_dir = getcwd()
    lcd `=l:vimfiler_current_dir`
  endif

  try
    if g:unite_kind_file_copy_file_command == ''
          \ || g:unite_kind_file_copy_directory_command == ''
      call unite#print_error("Please install cp.exe.")
      return 1
    endif

    let l:context = unite#get_context()
    let l:dest_dir = has_key(l:context, 'action__directory')
          \ && l:context.action__directory != '' ?
          \   l:context.action__directory :
          \   unite#util#input_directory('Input destination directory: ')
    if l:dest_dir !~ '/'
      let l:dest_dir .= '/'
    endif

    let l:overwrite_method = ''
    let l:is_reset_method = 1
    for l:candidate in a:candidates
      " Overwrite check.
      let l:filename = l:candidate.action__path
      let l:dest_filename = l:dest_dir . fnamemodify(l:filename, ':t')
      " Overwrite check.
      let [l:dest_filename, l:filename,
            \ l:overwrite_method, l:is_reset_method, l:is_continue] =
            \ s:check_over_write(l:dest_dir, l:filename, l:overwrite_method,
            \                    l:is_reset_method)
      if l:is_continue
        continue
      endif

      if s:external(isdirectory(l:filename) ?
            \ 'copy_directory' : 'copy_file', l:dest_filename, [l:filename])
        call unite#print_error('Failed file copy: ' . l:filename)
      endif
    endfor
  finally
    if l:vimfiler_current_dir != ''
      lcd `=l:current_dir`
    endif
  endtry
endfunction"}}}

let s:kind.action_table.copy = deepcopy(s:kind.action_table.vimfiler__copy)
let s:kind.action_table.copy.is_listed = 1
function! s:kind.action_table.copy.func(candidates)"{{{
  return s:kind.action_table.vimfiler__copy.func(a:candidates)
endfunction"}}}

let s:kind.action_table.vimfiler__delete = {
      \ 'description' : 'delete files',
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ 'is_selectable' : 1,
      \ 'is_listed' : 0,
      \ }
function! s:kind.action_table.vimfiler__delete.func(candidates)"{{{
  let l:vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if l:vimfiler_current_dir != ''
    let l:current_dir = getcwd()
    lcd `=l:vimfiler_current_dir`
  endif

  try
    if g:unite_kind_file_delete_file_command == ''
          \ || g:unite_kind_file_delete_directory_command == ''
      call unite#print_error("Please install rm.exe.")
      return 1
    endif

    " Execute force delete.
    for l:candidate in a:candidates
      let l:filename = l:candidate.action__path
      if s:external(isdirectory(l:filename) ?
            \ 'delete_directory' : 'delete_file', '', [l:filename])
        call unite#print_error('Failed file delete: ' . l:filename)
      endif
    endfor
  finally
    if l:vimfiler_current_dir != ''
      lcd `=l:current_dir`
    endif
  endtry
endfunction"}}}

let s:kind.action_table.vimfiler__rename = {
      \ 'description' : 'rename files',
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ 'is_listed' : 0,
      \ }
function! s:kind.action_table.vimfiler__rename.func(candidate)"{{{
  let l:vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if l:vimfiler_current_dir != ''
    let l:current_dir = getcwd()
    lcd `=l:vimfiler_current_dir`
  endif

  try
    let l:context = unite#get_context()
    let l:filename = has_key(l:context, 'action__filename') ?
          \ l:context.action__filename :
          \ input(printf('New file name: %s -> ',
          \       a:candidate.action__path), a:candidate.action__path)

    if l:filename != '' && l:filename !=# a:candidate.action__path
      call rename(a:candidate.action__path, l:filename)
    endif
  finally
    if l:vimfiler_current_dir != ''
      lcd `=l:current_dir`
    endif
  endtry
endfunction"}}}

let s:kind.action_table.vimfiler__newfile = {
      \ 'description' : 'make this file',
      \ 'is_quit' : 1,
      \ 'is_invalidate_cache' : 1,
      \ 'is_listed' : 0,
      \ }
function! s:kind.action_table.vimfiler__newfile.func(candidate)"{{{
  let l:vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if l:vimfiler_current_dir != ''
    let l:current_dir = getcwd()
    lcd `=l:vimfiler_current_dir`
  endif

  try
    let l:filenames = input('New files name(comma separated multiple files): ',
          \               '', 'file')
    if l:filenames == ''
      redraw
      echo 'Canceled.'
      return
    endif

    for l:filename in split(l:filenames, ',')
      let l:filename = a:candidate.action__path
      if filereadable(l:filename)
        redraw
        echo l:filename . ' is already exists.'
        return
      endif

      call writefile([], l:filename)
      call unite#mappings#do_action('open', [a:candidate])
    endfor
  finally
    if l:vimfiler_current_dir != ''
      lcd `=l:current_dir`
    endif
  endtry
endfunction"}}}

let s:kind.action_table.vimfiler__shell = {
      \ 'description' : 'popup shell',
      \ 'is_listed' : 0,
      \ }
function! s:kind.action_table.vimfiler__shell.func(candidate)"{{{
  let l:vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if l:vimfiler_current_dir != ''
    let l:current_dir = getcwd()
    lcd `=l:vimfiler_current_dir`
  endif

  try
    if !exists(':VimShellPop')
      shell
      return
    endif

    VimShellPop `=a:candidate.action__directory`

    let l:files = unite#get_context().vimfiler__files
    if !empty(l:files)
      call setline(line('.'), getline('.') . ' ' . join(l:files))
      normal! l
    endif
  finally
    if l:vimfiler_current_dir != ''
      lcd `=l:current_dir`
    endif
  endtry
endfunction"}}}

let s:kind.action_table.vimfiler__shellcmd = {
      \ 'description' : 'execute shell command',
      \ 'is_listed' : 0,
      \ }
function! s:kind.action_table.vimfiler__shellcmd.func(candidate)"{{{
  let l:vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if l:vimfiler_current_dir != ''
    let l:current_dir = getcwd()
    lcd `=l:vimfiler_current_dir`
  endif

  try
    let l:command = unite#get_context().vimfiler__command

    echo unite#util#system(l:command)
  finally
    if l:vimfiler_current_dir != ''
      lcd `=l:current_dir`
    endif
  endtry
endfunction"}}}

let s:kind.action_table.vimfiler__mkdir = {
      \ 'description' : 'make this directory and parents directory',
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ 'is_listed' : 0,
      \ }
function! s:kind.action_table.vimfiler__mkdir.func(candidate)"{{{
  let l:vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if l:vimfiler_current_dir != ''
    let l:current_dir = getcwd()
    lcd `=l:vimfiler_current_dir`
  endif

  try
    let l:dirname = input('New directory name: ', '', 'dir')

    if l:dirname == ''
      redraw
      echo 'Canceled.'
      return
    endif

    if &termencoding != '' && &termencoding != &encoding
      let l:dirname = iconv(l:dirname, &encoding, &termencoding)
    endif

    if !filereadable(l:dirname)
      call mkdir(l:dirname, 'p')
    endif
  finally
    if l:vimfiler_current_dir != ''
      lcd `=l:current_dir`
    endif
  endtry
endfunction"}}}

let s:kind.action_table.vimfiler__execute = {
      \ 'description' : 'open files with associated program',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.vimfiler__execute.func(candidates)"{{{
  let l:vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if l:vimfiler_current_dir != ''
    let l:current_dir = getcwd()
    lcd `=l:vimfiler_current_dir`
  endif

  try
    for l:candidate in a:candidates
      call s:System.open(l:candidate.action__path)
    endfor
  finally
    if l:vimfiler_current_dir != ''
      lcd `=l:current_dir`
    endif
  endtry
endfunction"}}}

let s:kind.action_table.vimfiler__write = {
      \ 'description' : 'save file',
      \ }
function! s:kind.action_table.vimfiler__write.func(candidate)"{{{
  let l:lines = unite#get_context().action__lines
  call writefile(l:lines, a:candidate.action__path)
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

  " echomsg l:command_line
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
function! s:move_to_other_drive(candidate, filename)"{{{
  " move command doesn't supported directory over drive move in Windows.
  if g:unite_kind_file_copy_command == ''
    call unite#print_error("Please install cp.exe.")
    return 1
  elseif g:unite_kind_file_delete_command == ''
    call unite#print_error("Please install rm.exe.")
    return 1
  endif

  if s:kind.action_table.vimfiler__copy.func([a:candidate])
    call unite#print_error('Failed file move: ' . a:filename)
    return 1
  endif

  if s:kind.action_table.vimfiler__delete.func([a:candidate])
    call unite#print_error('Failed file delete: ' . a:filename)
    return 1
  endif
endfunction"}}}
function! s:check_over_write(dest_dir, filename, overwrite_method, is_reset_method)"{{{
  let l:is_reset_method = a:is_reset_method
  let l:dest_filename = a:dest_dir . fnamemodify(a:filename, ':t')
  let l:is_continue = 0
  let l:filename = a:filename
  let l:overwrite_method = a:overwrite_method

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
        let l:is_continue = 1
      endif
    elseif l:overwrite_method =~? '^u'
      let l:filename .= '_'
    elseif l:overwrite_method =~? '^n'
      if l:is_reset_method
        let l:overwrite_method = ''
      endif

      let l:is_continue = 1
    elseif l:overwrite_method =~? '^r'
      let l:dest_filename = input(printf('New name: %s -> ', l:filename), l:filename)
    endif

    if l:is_reset_method
      let l:overwrite_method = ''
    endif
  endif"}}}

  return [l:dest_filename, l:filename,
        \ l:overwrite_method, l:is_reset_method, l:is_continue]
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
