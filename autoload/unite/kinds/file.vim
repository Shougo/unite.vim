"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 13 May 2012.
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
  if unite#util#is_windows() && !executable('rm')
    " Can't support.
    let g:unite_kind_file_delete_file_command = ''
  else
    let g:unite_kind_file_delete_file_command = 'rm $srcs'
  endif
endif
if !exists('g:unite_kind_file_delete_directory_command')
  if unite#util#is_windows() && !executable('rm')
    " Can't support.
    let g:unite_kind_file_delete_directory_command = ''
  else
    let g:unite_kind_file_delete_directory_command = 'rm -r $srcs'
  endif
endif
if !exists('g:unite_kind_file_copy_file_command')
  if unite#util#is_windows() && !executable('cp')
    " Can't support.
    let g:unite_kind_file_copy_file_command = ''
  else
    let g:unite_kind_file_copy_file_command = 'cp -p $srcs $dest'
  endif
endif
if !exists('g:unite_kind_file_copy_directory_command')
  if unite#util#is_windows() && !executable('cp')
    " Can't support.
    let g:unite_kind_file_copy_directory_command = ''
  else
    let g:unite_kind_file_copy_directory_command = 'cp -p -r $srcs $dest'
  endif
endif
if !exists('g:unite_kind_file_move_command')
  if unite#util#is_windows() && !executable('mv')
    let g:unite_kind_file_move_command = 'move /Y $srcs $dest'
  else
    let g:unite_kind_file_move_command = 'mv $srcs $dest'
  endif
endif

call unite#util#set_default('g:unite_kind_file_use_trashbox', 0)
"}}}

function! unite#kinds#file#define()"{{{
  return s:kind
endfunction"}}}

let s:System = vital#of('unite.vim').import('System.File')

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
  for candidate in a:candidates
    call s:execute_command('edit', candidate)

    call unite#remove_previewed_buffer_list(
          \ bufnr(unite#util#escape_file_searching(
          \       candidate.action__path)))
  endfor
endfunction"}}}

let s:kind.action_table.preview = {
      \ 'description' : 'preview file',
      \ 'is_quit' : 0,
      \ }
function! s:kind.action_table.preview.func(candidate)"{{{
  let buflisted = buflisted(
        \ unite#util#escape_file_searching(
        \ a:candidate.action__path))
  if filereadable(a:candidate.action__path)
    call s:execute_command('pedit', a:candidate)
  endif

  if !buflisted
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
  let dirname = input('New directory name: ', a:candidate.action__path, 'dir')

  if dirname == ''
    redraw
    echo 'Canceled.'
    return
  endif

  if !filereadable(dirname) && !isdirectory(dirname)
    call mkdir(dirname, 'p')
  endif
endfunction"}}}

let s:kind.action_table.rename = {
      \ 'description' : 'rename files',
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.rename.func(candidates)"{{{
  for candidate in a:candidates
    let filename = unite#util#substitute_path_separator(
          \ unite#util#expand(input(printf('New file name: %s -> ',
          \ candidate.action__path), candidate.action__path)))
    redraw
    if filename != '' && filename !=# candidate.action__path
      call unite#kinds#file#do_rename(candidate.action__path, filename)
    endif
  endfor
endfunction"}}}

let s:kind.action_table.wunix = {
      \ 'description' : 'write by unix fileformat',
      \ 'is_selectable' : 1,
      \ }
function! s:kind.action_table.wunix.func(candidates)"{{{
  let current_bufnr = bufnr('%')

  for candidate in a:candidates
    let is_listed = buflisted(
          \ unite#util#escape_file_searching(candidate.action__path))
    call s:kind.action_table.open.func([candidate])
    write ++fileformat=mac
    if is_listed
      call s:kind.action_table.open.func([candidate])
    else
      let bufnr = bufnr(unite#util#escape_file_searching(candidate.action__path))
      silent execute bufnr 'bdelete'
    endif
  endfor

  execute 'buffer' current_bufnr
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
  let vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if vimfiler_current_dir != ''
    let current_dir = getcwd()
    lcd `=vimfiler_current_dir`
  endif

  try
    if g:unite_kind_file_move_command == ''
      call unite#print_error("Please install mv.exe.")
      return 1
    endif

    let context = unite#get_context()
    let dest_dir = has_key(context, 'action__directory')
          \ && context.action__directory != '' ?
          \   context.action__directory :
          \   unite#util#input_directory('Input destination directory: ')
    if dest_dir == ''
      return
    elseif isdirectory(dest_dir) && dest_dir !~ '/$'
      let dest_dir .= '/'
    endif
    let context.action__directory = dest_dir

    let dest_drive = matchstr(dest_dir, '^\a\+\ze:')

    let candidates = []
    for candidate in a:candidates
      let filename = candidate.action__path

      if isdirectory(filename) && unite#util#is_windows()
            \ && matchstr(filename, '^\a\+\ze:') !=? dest_drive
        call s:move_to_other_drive(candidate, filename)
      else
        call add(candidates, candidate)
      endif
    endfor

    if dest_dir =~ '^\h\w\+:'
      " Use protocol move method.
      let protocol = matchstr(dest_dir, '^\h\w\+:')
      call unite#sources#{protocol}#move_files(dest_dir, candidates)
    else
      call unite#kinds#file#do_action(candidates, dest_dir, 'move', '')
    endif
  finally

    if vimfiler_current_dir != ''
      lcd `=current_dir`
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
  redraw

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
  let vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if vimfiler_current_dir != ''
    let current_dir = getcwd()
    lcd `=vimfiler_current_dir`
  endif

  try
    if g:unite_kind_file_copy_file_command == ''
          \ || g:unite_kind_file_copy_directory_command == ''
      call unite#print_error("Please install cp.exe.")
      return 1
    endif

    let context = unite#get_context()
    let dest_dir = has_key(context, 'action__directory')
          \ && context.action__directory != '' ?
          \   context.action__directory :
          \   unite#util#input_directory('Input destination directory: ')
    if dest_dir == ''
      return
    elseif isdirectory(dest_dir) && dest_dir !~ '/$'
      let dest_dir .= '/'
    endif

    if dest_dir =~ '^\h\w\+:'
      " Use protocol move method.
      let protocol = matchstr(dest_dir, '^\h\w\+:')
      call unite#sources#{protocol}#copy_files(dest_dir, candidates)
    else
      call unite#kinds#file#do_action(a:candidates, dest_dir, 'copy',
            \ s:SID_PREFIX().'check_copy_func')
    endif
  finally
    if vimfiler_current_dir != ''
      lcd `=current_dir`
    endif
  endtry
endfunction"}}}
function! s:check_copy_func(filename)"{{{
  return isdirectory(a:filename) ?
        \ 'copy_directory' : 'copy_file'
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
  let vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if vimfiler_current_dir != ''
    let current_dir = getcwd()
    lcd `=vimfiler_current_dir`
  endif

  try
    if g:unite_kind_file_delete_file_command == ''
          \ || g:unite_kind_file_delete_directory_command == ''
      call unite#print_error("Please install rm.exe.")
      return 1
    endif

    call unite#kinds#file#do_action(a:candidates, '', 'delete',
          \ s:SID_PREFIX().'check_delete_func')
  finally
    if vimfiler_current_dir != ''
      lcd `=current_dir`
    endif
  endtry
endfunction"}}}
function! s:check_delete_func(filename)"{{{
  return isdirectory(a:filename) ?
        \ 'delete_directory' : 'delete_file'
endfunction"}}}

let s:kind.action_table.vimfiler__rename = {
      \ 'description' : 'rename files',
      \ 'is_quit' : 0,
      \ 'is_invalidate_cache' : 1,
      \ 'is_listed' : 0,
      \ }
function! s:kind.action_table.vimfiler__rename.func(candidate)"{{{
  let vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if vimfiler_current_dir != ''
    let current_dir = getcwd()
    lcd `=vimfiler_current_dir`
  endif

  try
    let context = unite#get_context()
    let filename = has_key(context, 'action__filename') ?
          \ context.action__filename :
          \ input(printf('New file name: %s -> ',
          \       a:candidate.action__path), a:candidate.action__path)

    redraw

    if filename != '' && filename !=# a:candidate.action__path
      call unite#kinds#file#do_rename(a:candidate.action__path, filename)
    endif
  finally
    if vimfiler_current_dir != ''
      lcd `=current_dir`
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
  let vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if vimfiler_current_dir != ''
    let current_dir = getcwd()
    lcd `=vimfiler_current_dir`
  endif

  try
    let filenames = input('New files name(comma separated multiple files): ',
          \               '', 'file')
    if filenames == ''
      redraw
      echo 'Canceled.'
      return
    endif

    for filename in split(filenames, ',')
      if filereadable(filename)
        redraw
        echo filename . ' is already exists.'
        continue
      endif

      let file = unite#sources#file#create_file_dict(
            \ filename, filename !~ '^\%(/\|\a\+:/\)')
      let file.source = 'file'

      call writefile([], filename)
      call unite#mappings#do_action(g:vimfiler_edit_action, [file])
    endfor
  finally
    if vimfiler_current_dir != ''
      lcd `=current_dir`
    endif
  endtry
endfunction"}}}

let s:kind.action_table.vimfiler__shell = {
      \ 'description' : 'popup shell',
      \ 'is_listed' : 0,
      \ }
function! s:kind.action_table.vimfiler__shell.func(candidate)"{{{
  let vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')

  if !exists(':VimShellPop')
    shell
    return
  endif

  execute 'VimShellPop' escape(a:candidate.action__directory, '\ ')

  let files = unite#get_context().vimfiler__files
  if !empty(files)
    call setline(line('.'), getline('.') . ' ' . join(files))
    normal! l
  endif
endfunction"}}}

let s:kind.action_table.vimfiler__shellcmd = {
      \ 'description' : 'execute shell command',
      \ 'is_listed' : 0,
      \ }
function! s:kind.action_table.vimfiler__shellcmd.func(candidate)"{{{
  let vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if vimfiler_current_dir != ''
    let current_dir = getcwd()
    lcd `=vimfiler_current_dir`
  endif

  try
    let command = unite#get_context().vimfiler__command

    echo unite#util#system(command)
  finally
    if vimfiler_current_dir != ''
      lcd `=current_dir`
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
  let vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if vimfiler_current_dir != ''
    let current_dir = getcwd()
    lcd `=vimfiler_current_dir`
  endif

  try
    let dirname = input('New directory name: ', '', 'dir')

    if dirname == ''
      redraw
      echo 'Canceled.'
      return
    endif

    let dirname = unite#util#substitute_path_separator(
          \ fnamemodify(dirname, ':p'))

    if !filereadable(dirname) && !isdirectory(dirname)
      call mkdir(dirname, 'p')
    endif
  finally
    if vimfiler_current_dir != ''
      lcd `=current_dir`
    endif
  endtry
endfunction"}}}

let s:kind.action_table.vimfiler__execute = {
      \ 'description' : 'open files with associated program',
      \ 'is_selectable' : 1,
      \ 'is_listed' : 0,
      \ }
function! s:kind.action_table.vimfiler__execute.func(candidates)"{{{
  let vimfiler_current_dir =
        \ get(unite#get_context(), 'vimfiler__current_directory', '')
  if vimfiler_current_dir != ''
    let current_dir = getcwd()
    lcd `=vimfiler_current_dir`
  endif

  try
    for candidate in a:candidates
      let path = candidate.action__path
      if unite#util#is_windows() && path =~ '^//'
        " substitute separator for UNC.
        let path = substitute(path, '/', '\\', 'g')
      endif

      call s:System.open(path)
    endfor
  finally
    if vimfiler_current_dir != ''
      lcd `=current_dir`
    endif
  endtry
endfunction"}}}

let s:kind.action_table.vimfiler__write = {
      \ 'description' : 'save file',
      \ 'is_listed' : 0,
      \ }
function! s:kind.action_table.vimfiler__write.func(candidate)"{{{
  let context = unite#get_context()
  let lines = getline(context.vimfiler__line1, context.vimfiler__line2)

  if context.vimfiler__eventname ==# 'FileAppendCmd'
    " Append.
    let lines = readfile(a:candidate.action__path) + lines
  endif
  call writefile(lines, a:candidate.action__path)
endfunction"}}}
"}}}

function! s:execute_command(command, candidate)"{{{
  let dir = unite#util#path2directory(a:candidate.action__path)
  " Auto make directory.
  if dir !~ '^\a\+:' && !isdirectory(dir) && unite#util#input_yesno(
        \   printf('"%s" does not exist. Create?', dir))
    call mkdir(dir, 'p')
  endif

  call unite#util#smart_execute_command(a:command, a:candidate.action__path)
endfunction"}}}
function! s:external(command, dest_dir, src_files)"{{{
  let dest_dir = a:dest_dir
  if dest_dir =~ '[^:]/$'
    " Delete last /.
    let dest_dir = dest_dir[: -2]
  endif

  let src_files = map(a:src_files, 'substitute(v:val, "[^:]\zs/$", "", "")')
  let command_line = g:unite_kind_file_{a:command}_command

  " Substitute pattern.
  let command_line = substitute(command_line,
        \'\$srcs\>', escape(join(
        \   map(src_files, '''"''.v:val.''"''')), '&'), 'g')
  let command_line = substitute(command_line,
        \'\$dest\>', escape('"'.dest_dir.'"', '&'), 'g')

  " echomsg command_line
  let output = unite#util#system(command_line)

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
  let method = ''
  while method !~? '^\%(f\%[orce]\|t\%[ime]\|u\%[nderbar]\|n\%[o]\|r\%[ename]\)$'
    " Retry.
    let method = input('f[orce]/t[ime]/u[nderbar]/n[o]/r[ename] : ',
        \ '', 'customlist,unite#kinds#file#complete_overwrite_method')
  endwhile

  redraw

  return method
endfunction"}}}
function! unite#kinds#file#complete_overwrite_method(arglead, cmdline, cursorpos)"{{{
  return filter(['force', 'time', 'underbar', 'no', 'rename'],
        \ 'stridx(v:val, a:arglead) == 0')
endfunction"}}}
function! s:move_to_other_drive(candidate, filename)"{{{
  " move command doesn't supported directory over drive move in Windows.
  if g:unite_kind_file_copy_file_command == ''
        \ || g:unite_kind_file_copy_directory_command == ''
    call unite#print_error("Please install cp.exe.")
    return 1
  elseif g:unite_kind_file_delete_file_command == ''
          \ || g:unite_kind_file_delete_directory_command == ''
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
  let is_reset_method = a:is_reset_method
  let dest_filename = a:dest_dir . fnamemodify(a:filename, ':t')
  let is_continue = 0
  let filename = fnamemodify(a:filename, ':t')
  let overwrite_method = a:overwrite_method

  if filereadable(dest_filename) || isdirectory(dest_filename)"{{{
    if overwrite_method == ''
      let overwrite_method =
            \ s:input_overwrite_method(dest_filename, a:filename)
      if overwrite_method =~ '^\u'
        " Same overwrite.
        let is_reset_method = 0
      endif
    endif

    if overwrite_method =~? '^f'
      " Ignore.
    elseif overwrite_method =~? '^t'
      if getftime(a:filename) <= getftime(dest_filename)
        let is_continue = 1
      endif
    elseif overwrite_method =~? '^u'
      let filename .= '_'
    elseif overwrite_method =~? '^n'
      if is_reset_method
        let overwrite_method = ''
      endif

      let is_continue = 1
    elseif overwrite_method =~? '^r'
      let filename =
            \ input(printf('New name: %s -> ', filename), filename, 'file')
    endif

    if is_reset_method
      let overwrite_method = ''
    endif
  endif"}}}

  let dest_filename = a:dest_dir . fnamemodify(filename, ':t')

  if dest_filename ==#
        \ a:dest_dir . fnamemodify(a:filename, ':t')
    let dest_filename = a:dest_dir
  endif

  return [dest_filename, overwrite_method, is_reset_method, is_continue]
endfunction"}}}
function! unite#kinds#file#do_rename(old_filename, new_filename)"{{{
  if a:old_filename ==# a:new_filename
    return
  endif

  if a:old_filename !=? a:new_filename &&
        \ (filereadable(a:new_filename) || isdirectory(a:new_filename))
    " Failed.
    call unite#print_error(
          \ printf('file: "%s" is already exists!', a:new_filename))
    return
  endif

  " Convert to relative path.
  let old_filename = substitute(fnamemodify(a:old_filename, ':p'),
        \ '[/\\]$', '', '')
  let directory = unite#util#substitute_path_separator(
        \ fnamemodify(old_filename, ':h'))
  let current_dir_save = getcwd()
  lcd `=directory`

  try
    let old_filename = unite#util#substitute_path_separator(
          \ fnamemodify(a:old_filename, ':.'))
    let new_filename = unite#util#substitute_path_separator(
          \ fnamemodify(a:new_filename, ':.'))

    let bufnr = bufnr(unite#util#escape_file_searching(old_filename))
    if bufnr > 0
      " Buffer rename.
      let bufnr_save = bufnr('%')
      execute 'buffer' bufnr
      saveas! `=new_filename`
      execute 'buffer' bufnr_save
    endif

    if rename(old_filename, new_filename)
      call unite#print_error(
            \ printf('Failed file rename: "%s" to "%s".',
            \   a:old_filename, a:new_filename))
    endif
  finally
    " Restore path.
    lcd `=current_dir_save`
  endtry
endfunction"}}}
function! s:filename2candidate(filename)"{{{
  return {
        \ 'action__directory' :
        \       unite#util#path2directory(a:filename),
        \ 'action__path' : a:filename,
        \ }
endfunction"}}}

function! unite#kinds#file#do_action(candidates, dest_dir, action_name, command_func)"{{{
  let overwrite_method = ''
  let is_reset_method = 1

  let cnt = 1
  let max = len(a:candidates)

  echo ''
  redraw

  for candidate in a:candidates
    let filename = candidate.action__path

    if a:action_name == 'move' || a:action_name == 'copy'
      " Overwrite check.
      let [dest_filename, overwrite_method, is_reset_method, is_continue] =
            \ s:check_over_write(a:dest_dir, filename, overwrite_method,
            \                    is_reset_method)
      if is_continue
        let cnt += 1
        continue
      endif
    else
      let dest_filename = ''
    endif

    " Print progress.
    echo printf('%d%% %s %s%s',
          \ ((cnt*100) / max), a:action_name,
          \ (dest_filename == '' ? '' : dest_filename  . ' -> '),
          \ filename)
    redraw

    if a:action_name == 'delete'
          \ && g:unite_kind_file_use_trashbox
      " Environment check.
      if unite#util#is_windows()
            \ && unite#util#has_vimproc() && exists('*vimproc#delete_trash')
        let ret = vimproc#delete_trash(filename)
        if ret
          call unite#print_error(printf('Failed file %s: %s',
                \ a:action_name, filename))
          call unite#print_error(printf('Error code is %d', ret))
        endif
      else
        call unite#util#print_error(
              \ 'Your environment is not supported vimproc#delete_trash().')
        break
      endif
    else
      let command = a:command_func == '' ?
            \ a:action_name : call(a:command_func, [filename])
      if s:external(command, dest_filename, [filename])
        call unite#print_error(printf('Failed file %s: %s',
              \ a:action_name, filename))
      endif
    endif

    let cnt += 1
  endfor

  echo ''
  redraw
endfunction"}}}

function! s:SID_PREFIX()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeSID_PREFIX$')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
