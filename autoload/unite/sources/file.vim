"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 04 Aug 2013.
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

let s:is_windows = unite#util#is_windows()

" Variables  "{{{
call unite#util#set_default('g:unite_source_file_ignore_pattern',
      \'\%(^\|/\)\.\.\?$\|\~$\|\.\%(o|exe|dll|bak|DS_Store|pyc|zwc|sw[po]\)$')
"}}}

function! unite#sources#file#define() "{{{
  return [s:source_file, s:source_file_new]
endfunction"}}}

let s:source_file = {
      \ 'name' : 'file',
      \ 'description' : 'candidates from file list',
      \ 'ignore_pattern' : g:unite_source_file_ignore_pattern,
      \ 'default_kind' : 'file',
      \ 'matchers' : [ 'matcher_default', 'matcher_hide_hidden_files' ],
      \}

function! s:source_file.change_candidates(args, context) "{{{
  if !has_key(a:context, 'source__cache') || a:context.is_redraw
        \ || a:context.is_invalidate
    " Initialize cache.
    let a:context.source__cache = {}
  endif

  let is_vimfiler = get(a:context, 'is_vimfiler', 0)

  let input = substitute(substitute(
        \ a:context.path, '\\ ', ' ', 'g'), '^\a\+:\zs\*/', '/', '')

  let path = join(a:args, ':')
  if path !=# '/' && path =~ '[\\/]$'
    " Chomp.
    let path = path[: -2]
  endif

  if !isdirectory(path) && filereadable(path)
    return [ unite#sources#file#create_file_dict(
          \      path, path !~ '^\%(/\|\a\+:/\)') ]
  endif

  if input !~ '^\%(/\|\a\+:/\)' && path != '' && path != '/'
    let input = path . '/' .  input
  endif
  let is_relative_path = input !~ '^\%(/\|\a\+:/\)' && path == ''

  " Substitute *. -> .* .
  let input = substitute(input, '\*\.', '.*', 'g')

  if input !~ '\*' && s:is_windows && getftype(input) == 'link'
    " Resolve link.
    let input = resolve(input)
  endif

  " Glob by directory name.
  let input = substitute(input, '[^/.]*$', '', '')
  let glob = input . (input =~ '\*$' ? '' : '*')

  if !has_key(a:context.source__cache, glob)
    " let files = split(unite#util#substitute_path_separator(
    "       \ glob(glob)), '\n')
    let files = unite#util#glob(glob, !is_vimfiler)

    if !is_vimfiler
      let files = sort(filter(copy(files),
            \ "v:val != '.' && isdirectory(v:val)"), 1) +
            \ sort(filter(copy(files), "!isdirectory(v:val)"), 1)
    endif

    let a:context.source__cache[glob] = map(files,
          \ 'unite#sources#file#create_file_dict(v:val, is_relative_path)')
  endif

  let candidates = copy(a:context.source__cache[glob])

  return candidates
endfunction"}}}
function! s:source_file.vimfiler_check_filetype(args, context) "{{{
  let path = s:parse_path(a:args)

  if isdirectory(path)
    let type = 'directory'
    let info = path
  elseif filereadable(path)
    let type = 'file'
    let info = [readfile(path),
          \ unite#sources#file#create_file_dict(path, 0)]
  else
    " Ignore.
    return []
  endif

  return [type, info]
endfunction"}}}
function! s:source_file.vimfiler_gather_candidates(args, context) "{{{
  let path = s:parse_path(a:args)

  if isdirectory(path)
    " let start = reltime()

    let context = deepcopy(a:context)
    let context.is_vimfiler = 1
    let context.path .= path
    let candidates = self.change_candidates(a:args, context)

    if !exists('*vimproc#readdir')
      " Add doted files.
      let context.path .= '.'
      let candidates += self.change_candidates(a:args, context)
    endif
    call filter(candidates, 'v:val.word !~ "/\\.\\.\\?$"')

    " echomsg reltimestr(reltime(start))
  elseif filereadable(path)
    let candidates = [ unite#sources#file#create_file_dict(path, 0) ]
  else
    let candidates = []
  endif

  let exts = s:is_windows ?
        \ escape(substitute($PATHEXT . ';.LNK', ';', '\\|', 'g'), '.') : ''

  let old_dir = getcwd()
  if path !=# old_dir
        \ && isdirectory(path)
    try
      lcd `=path`
    catch
      call unite#print_error('cd failed in "' . path . '"')
      return []
    endtry
  endif

  " Set vimfiler property.
  for candidate in candidates
    call unite#sources#file#create_vimfiler_dict(candidate, exts)
  endfor

  if path !=# old_dir
        \ && isdirectory(path)
    lcd `=old_dir`
  endif

  return candidates
endfunction"}}}
function! s:source_file.vimfiler_dummy_candidates(args, context) "{{{
  let path = s:parse_path(a:args)

  if path == ''
    return []
  endif

  let old_dir = getcwd()
  if path !=# old_dir
        \ && isdirectory(path)
    lcd `=path`
  endif

  let exts = s:is_windows ?
        \ escape(substitute($PATHEXT . ';.LNK', ';', '\\|', 'g'), '.') : ''

  let is_relative_path = path !~ '^\%(/\|\a\+:/\)'

  " Set vimfiler property.
  let candidates = [ unite#sources#file#create_file_dict(path, is_relative_path) ]
  for candidate in candidates
    call unite#sources#file#create_vimfiler_dict(candidate, exts)
  endfor

  if path !=# old_dir
        \ && isdirectory(path)
    lcd `=old_dir`
  endif

  return candidates
endfunction"}}}
function! s:source_file.complete(args, context, arglead, cmdline, cursorpos) "{{{
  return unite#sources#file#complete_file(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}
function! s:source_file.vimfiler_complete(args, context, arglead, cmdline, cursorpos) "{{{
  return unite#sources#file#complete_file(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}

let s:source_file_new = {
      \ 'name' : 'file/new',
      \ 'description' : 'file candidates from input',
      \ 'default_kind' : 'file',
      \ }

function! s:source_file_new.change_candidates(args, context) "{{{
  let input = substitute(substitute(
        \ a:context.path, '\\ ', ' ', 'g'), '^\a\+:\zs\*/', '/', '')
  if input == ''
    return []
  endif

  let path = join(a:args, ':')
  if path !=# '/' && path =~ '[\\/]$'
    " Chomp.
    let path = path[: -2]
  endif

  if input !~ '^\%(/\|\a\+:/\)' && path != '' && path != '/'
    let input = path . '/' .  input
  endif

  " Substitute *. -> .* .
  let input = substitute(input, '\*\.', '.*', 'g')

  if input !~ '\*' && s:is_windows && getftype(input) == 'link'
    " Resolve link.
    let input = resolve(input)
  endif

  let is_relative_path = path !~ '^\%(/\|\a\+:/\)'

  let newfile = unite#util#expand(
        \ escape(substitute(input, '[*\\]', '', 'g'), ''))
  if filereadable(newfile) || isdirectory(newfile)
    return []
  endif

  " Return newfile candidate.
  return [unite#sources#file#create_file_dict(
        \ newfile, is_relative_path, 1)]
endfunction"}}}

function! s:parse_path(args) "{{{
  let path = unite#util#substitute_path_separator(
        \ unite#util#expand(join(a:args, ':')))
  let path = unite#util#substitute_path_separator(
        \ fnamemodify(path, ':p'))

  return path
endfunction"}}}

function! unite#sources#file#create_file_dict(file, is_relative_path, ...) "{{{
  let is_newfile = get(a:000, 0, 0)

  let dict = {
        \ 'word' : a:file, 'abbr' : a:file,
        \ 'action__path' : a:file,
        \}

  let dict.vimfiler__is_directory =
        \ isdirectory(dict.action__path)

  if a:is_relative_path
    let dict.action__path = unite#util#substitute_path_separator(
        \                    fnamemodify(a:file, ':p'))
  endif

  let dict.action__directory = dict.vimfiler__is_directory ?
        \ dict.action__path : fnamemodify(dict.action__path, ':h')

  if s:is_windows
    let dict.action__directory =
          \ unite#util#substitute_path_separator(dict.action__directory)
  endif

  if dict.vimfiler__is_directory
    if a:file !~ '^\%(/\|\a\+:/\)$'
      let dict.abbr .= '/'
    endif

    let dict.kind = 'directory'
  elseif is_newfile
    if is_newfile == 1
      " New file.
      let dict.abbr = '[new file] ' . a:file
      let dict.kind = 'file'
    elseif is_newfile == 2
      " New directory.
      let dict.action__directory = a:file
      let dict.abbr = '[new directory] ' . a:file
      let dict.kind = 'directory'
    endif
  else
    let dict.kind = 'file'
  endif

  return dict
endfunction"}}}
function! unite#sources#file#create_vimfiler_dict(candidate, exts) "{{{
  try
    if len(a:candidate.action__path) > 200
      " Convert to relative path.
      let current_dir_save = getcwd()
      lcd `=a:candidate.action__directory`

      let filename = unite#util#substitute_path_separator(
            \ fnamemodify(a:candidate.action__path, ':.'))
    else
      let filename = a:candidate.action__path
    endif

    let a:candidate.vimfiler__ftype = getftype(filename)
  finally
    if exists('current_dir_save')
      " Restore path.
      lcd `=current_dir_save`
    endif
  endtry

  let a:candidate.vimfiler__filename =
        \       fnamemodify(a:candidate.action__path, ':t')
  let a:candidate.vimfiler__abbr = a:candidate.vimfiler__filename

  if !a:candidate.vimfiler__is_directory
    let a:candidate.vimfiler__is_executable =
          \ s:is_windows ?
          \ ('.'.fnamemodify(a:candidate.vimfiler__filename, ':e') =~? a:exts) :
          \ executable(a:candidate.action__path)

    let a:candidate.vimfiler__filesize =
          \ getfsize(a:candidate.action__path)
    if !s:is_windows
      let a:candidate.vimfiler__is_writable =
            \ filewritable(a:candidate.action__path)
    endif
  elseif !s:is_windows
    let a:candidate.vimfiler__is_writable =
          \ filewritable(a:candidate.action__path)
  endif

  let a:candidate.vimfiler__filetime =
        \ s:get_filetime(a:candidate.action__path)
endfunction"}}}

function! unite#sources#file#complete_file(args, context, arglead, cmdline, cursorpos) "{{{
  let files = unite#util#glob(a:arglead . '*')
  if a:arglead =~ '^\~'
    let home_pattern = '^'.
          \ unite#util#substitute_path_separator(expand('~')).'/'
    call map(files, "substitute(v:val, home_pattern, '~/', '')")
  endif
  call map(files, "isdirectory(v:val) ? v:val.'/' : v:val")
  call map(files, "escape(v:val, ' \\')")
  return files
endfunction"}}}
function! unite#sources#file#complete_directory(args, context, arglead, cmdline, cursorpos) "{{{
  let files = unite#util#glob(a:arglead . '*')
  let files = filter(files, 'isdirectory(v:val)')
  if a:arglead =~ '^\~'
    let home_pattern = '^'.
          \ unite#util#substitute_path_separator(expand('~')).'/'
    call map(files, "substitute(v:val, home_pattern, '~/', '')")
  endif
  call map(files, "escape(v:val, ' \\')")
  return files
endfunction"}}}

function! unite#sources#file#copy_files(dest, srcs) "{{{
  return unite#kinds#file#do_action(a:srcs, a:dest, 'copy')
endfunction"}}}
function! unite#sources#file#move_files(dest, srcs) "{{{
  return unite#kinds#file#do_action(a:srcs, a:dest, 'move')
endfunction"}}}
function! unite#sources#file#delete_files(srcs) "{{{
  return unite#kinds#file#do_action(a:srcs, '', 'delete')
endfunction"}}}

" Add custom action table. "{{{
let s:cdable_action_file = {
      \ 'description' : 'open this directory by file source',
      \ 'is_start' : 1,
      \}

function! s:cdable_action_file.func(candidate)
  call unite#start_script([['file', a:candidate.action__directory]])
endfunction

call unite#custom_action('cdable', 'file', s:cdable_action_file)
unlet! s:cdable_action_file
"}}}

function! s:get_filetime(filename) "{{{
  let filetime = getftime(a:filename)
  if !has('python3')
    return filetime
  endif

  if filetime < 0 && getftype(a:filename) !=# 'link' "{{{
    " Use python3 interface.
python3 <<END
import os
import os.path
import vim
os.stat_float_times(False)
try:
  ftime = os.path.getmtime(vim.eval(\
    'unite#util#iconv(a:filename, &encoding, "char")'))
except:
  ftime = -1
vim.command('let filetime = ' + str(ftime))
END
  endif"}}}

  return filetime
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
