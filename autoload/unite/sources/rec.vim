"=============================================================================
" FILE: rec.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 18 Nov 2013.
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

" Variables  "{{{
call unite#util#set_default(
      \ 'g:unite_source_rec_ignore_pattern',
      \'\%(^\|/\)\.$\|\~$\|\.\%(o\|exe\|dll\|bak\|DS_Store\|zwc\|pyc\|sw[po]\|class\)$'.
      \'\|\%(^\|/\)\%(\.hg\|\.git\|\.bzr\|\.svn\|tags\%(-.*\)\?\)\%($\|/\)',
      \ 'g:unite_source_file_rec_ignore_pattern')
call unite#util#set_default(
      \ 'g:unite_source_rec_min_cache_files', 100,
      \ 'g:unite_source_file_rec_min_cache_files')
call unite#util#set_default(
      \ 'g:unite_source_rec_max_cache_files', 2000,
      \ 'g:unite_source_file_rec_max_cache_files')
call unite#util#set_default('g:unite_source_rec_unit', 200)
call unite#util#set_default(
      \ 'g:unite_source_rec_async_command',
      \ (executable('ag') ?
      \  'ag --nocolor --nogroup --skip-vcs-ignores --ignore ' .
      \  '''.hg'' --ignore ''.svn'' --ignore ''.git'' --ignore ''.bzr'' --ignore ''_darcs'' --hidden -g ""' :
      \  !unite#util#is_windows() && executable('find') ? 'find' : ''),
      \ 'g:unite_source_file_rec_async_command')
"}}}

let s:Cache = unite#util#get_vital().import('System.Cache')

let s:continuation = { 'directory' : {}, 'file' : {} }

" Source rec.
let s:source_file_rec = {
      \ 'name' : 'file_rec',
      \ 'description' : 'candidates from directory by recursive',
      \ 'hooks' : {},
      \ 'default_kind' : 'file',
      \ 'max_candidates' : 50,
      \ 'ignore_pattern' : g:unite_source_rec_ignore_pattern,
      \ 'matchers' : [ 'converter_relative_word',
      \                'matcher_default', 'matcher_hide_hidden_files' ],
      \ }

function! s:source_file_rec.gather_candidates(args, context) "{{{
  let a:context.source__directory = s:get_path(a:args, a:context)

  let directory = a:context.source__directory
  if directory == ''
    " Not in project directory.
    call unite#print_source_message(
          \ 'Not in project directory.', self.name)
    let a:context.is_async = 0
    return []
  endif

  call unite#print_source_message(
        \ 'directory: ' . directory, self.name)

  call s:init_continuation(a:context, directory)

  let continuation = a:context.source__continuation

  if empty(continuation.rest) || continuation.end
    " Disable async.
    call unite#print_source_message(
          \ 'Directory traverse was completed.', self.name)
    let a:context.is_async = 0
    let continuation.end = 1
  endif

  return deepcopy(continuation.files)
endfunction"}}}

function! s:source_file_rec.async_gather_candidates(args, context) "{{{
  let continuation = a:context.source__continuation

  let [continuation.rest, files] =
        \ s:get_files(a:context, continuation.rest,
        \   1, g:unite_source_rec_unit,
        \   a:context.source.ignore_pattern)

  if empty(continuation.rest) || (
        \  g:unite_source_rec_max_cache_files > 0 &&
        \    len(continuation.files) >
        \        g:unite_source_rec_max_cache_files)
    if empty(continuation.rest)
      call unite#print_source_message(
            \ 'Directory traverse was completed.', self.name)
    else
      call unite#print_source_message(
            \ 'Too many candiates.', self.name)
    endif

    " Disable async.
    let a:context.is_async = 0
    let continuation.end = 1
  endif

  let candidates = map(files, "{
        \ 'word' : unite#util#substitute_path_separator(
        \    fnamemodify(v:val, ':p')),
        \ 'action__path' : v:val,
        \ }")

  let continuation.files += candidates
  if empty(continuation.rest)
    call s:write_cache(a:context,
          \ a:context.source__directory, continuation.files)
  endif

  return deepcopy(candidates)
endfunction"}}}

function! s:source_file_rec.hooks.on_init(args, context) "{{{
  let a:context.source__is_directory = 0
  call s:on_init(a:args, a:context)
endfunction"}}}
function! s:source_file_rec.hooks.on_post_filter(args, context) "{{{
  let directory = unite#util#substitute_path_separator(
        \ fnamemodify(a:context.source__directory, ':p'))
  for candidate in filter(a:context.candidates,
        \ "v:val.action__path !=# directory")
    let candidate.action__directory =
          \ unite#util#path2directory(candidate.action__path)
  endfor
endfunction"}}}

function! s:source_file_rec.vimfiler_check_filetype(args, context) "{{{
  let path = unite#util#substitute_path_separator(
        \ unite#util#expand(join(a:args, ':')))
  let path = unite#util#substitute_path_separator(
        \ simplify(fnamemodify(path, ':p')))

  if isdirectory(path)
    let type = 'directory'
    let lines = []
    let dict = {}
  else
    return []
  endif

  return [type, lines, dict]
endfunction"}}}
function! s:source_file_rec.vimfiler_gather_candidates(args, context) "{{{
  let path = s:get_path(a:args, a:context)

  if !isdirectory(path)
    let a:context.source__directory = path

    return []
  endif

  " Initialize.
  let candidates = copy(self.gather_candidates(a:args, a:context))
  while a:context.is_async
    " Gather all candidates.

    " User input check.
    echo 'File searching...(if press any key, will cancel.)'
    redraw
    if getchar(0)
      break
    endif

    let candidates += self.async_gather_candidates(a:args, a:context)
  endwhile
  redraw!

  let old_dir = getcwd()
  if path !=# old_dir
        \ && isdirectory(path)
    lcd `=path`
  endif

  let exts = unite#util#is_windows() ?
        \ escape(substitute($PATHEXT . ';.LNK', ';', '\\|', 'g'), '.') : ''

  " Set vimfiler property.
  for candidate in candidates
    call unite#sources#file#create_vimfiler_dict(candidate, exts)
  endfor

  if path !=# old_dir
        \ && isdirectory(path)
    lcd `=old_dir`
  endif

  return deepcopy(candidates)
endfunction"}}}
function! s:source_file_rec.vimfiler_dummy_candidates(args, context) "{{{
  let path = unite#util#substitute_path_separator(
        \ unite#util#expand(join(a:args, ':')))
  let path = unite#util#substitute_path_separator(
        \ simplify(fnamemodify(path, ':p')))

  if path == ''
    return []
  endif

  let old_dir = getcwd()
  if path !=# old_dir
        \ && isdirectory(path)
    lcd `=path`
  endif

  let exts = unite#util#is_windows() ?
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

  return deepcopy(candidates)
endfunction"}}}
function! s:source_file_rec.vimfiler_complete(args, context, arglead, cmdline, cursorpos) "{{{
  return unite#sources#file#complete_directory(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}
function! s:source_file_rec.complete(args, context, arglead, cmdline, cursorpos) "{{{
  return unite#sources#file#complete_directory(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}

" Source async.
let s:source_file_async = deepcopy(s:source_file_rec)
let s:source_file_async.name = 'file_rec/async'
let s:source_file_async.description =
      \ 'asynchronous candidates from directory by recursive'

function! s:source_file_async.gather_candidates(args, context) "{{{
  let a:context.source__directory = s:get_path(a:args, a:context)

  if !unite#util#has_vimproc()
    call unite#print_source_message(
          \ 'vimproc plugin is not installed.', self.name)
    let a:context.is_async = 0
    return []
  endif

  let directory = a:context.source__directory
  if directory == ''
    " Not in project directory.
    call unite#print_source_message(
          \ 'Not in project directory.', self.name)
    let a:context.is_async = 0
    return []
  endif

  call unite#print_source_message(
        \ 'directory: ' . directory, self.name)

  call s:init_continuation(a:context, directory)

  let continuation = a:context.source__continuation

  if empty(continuation.rest) || continuation.end
    " Disable async.
    call unite#print_source_message(
          \ 'Directory traverse was completed.', self.name)
    let a:context.is_async = 0
    let continuation.end = 1

    return deepcopy(continuation.files)
  endif

  let command = g:unite_source_rec_async_command
  if a:context.source__is_directory
    " Use find command.
    let command = 'find'
  endif

  let args = split(command)
  if empty(args) || !executable(args[0])
    call unite#print_source_message('async command : "'.
          \ command.'" is not executable.', self.name)
    let a:context.is_async = 0
    return []
  endif

  let a:context.source__proc = vimproc#pgroup_open(
        \ command . ' ' . string(directory)
        \ . (command ==# 'find' ? ' -type '.
        \    (a:context.source__is_directory ? 'd' : 'f') : ''))

  " Close handles.
  call a:context.source__proc.stdin.close()

  return []
endfunction"}}}

function! s:source_file_async.async_gather_candidates(args, context) "{{{
  let stderr = a:context.source__proc.stderr
  if !stderr.eof
    " Print error.
    let errors = filter(stderr.read_lines(-1, 100),
          \ "v:val !~ '^\\s*$'")
    if !empty(errors)
      call unite#print_source_error(errors, self.name)
    endif
  endif

  let continuation = a:context.source__continuation
  let stdout = a:context.source__proc.stdout

  let candidates = []
  for filename in map(filter(
        \ stdout.read_lines(-1, 100), 'v:val != ""'),
        \ "fnamemodify(unite#util#iconv(v:val, 'char', &encoding), ':p')")
    if filename !=# a:context.source__directory
          \ && filename !~? a:context.source.ignore_pattern
      call add(candidates, {
            \ 'word' : unite#util#substitute_path_separator(
            \    fnamemodify(filename, ':p')),
            \ 'action__path' : filename,
            \ })
    endif
  endfor

  if stdout.eof || (
        \  g:unite_source_rec_max_cache_files > 0 &&
        \    len(continuation.files) >
        \        g:unite_source_rec_max_cache_files)
    " Disable async.
    if stdout.eof
      call unite#print_source_message(
            \ 'Directory traverse was completed.', self.name)
    else
      call unite#print_source_message(
            \ 'Too many candiates.', self.name)
    endif
    let a:context.is_async = 0
    let continuation.end = 1

    call a:context.source__proc.waitpid()
  endif

  let continuation.files += candidates
  if stdout.eof
    call s:write_cache(a:context,
          \ a:context.source__directory, continuation.files)
  endif

  return deepcopy(candidates)
endfunction"}}}

function! s:source_file_async.hooks.on_init(args, context) "{{{
  let a:context.source__is_directory = 0
  call s:on_init(a:args, a:context)
endfunction"}}}
function! s:source_file_async.hooks.on_close(args, context) "{{{
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.kill()
  endif
endfunction "}}}

" Source directory.
let s:source_directory_rec = deepcopy(s:source_file_rec)
let s:source_directory_rec.name = 'directory_rec'
let s:source_directory_rec.description =
      \ 'candidates from directory by recursive'
let s:source_directory_rec.default_kind = 'directory'

function! s:source_directory_rec.hooks.on_init(args, context) "{{{
  let a:context.source__is_directory = 1
  call s:on_init(a:args, a:context)
endfunction"}}}

" Source directory/async.
let s:source_directory_async = deepcopy(s:source_file_async)
let s:source_directory_async.name = 'directory_rec/async'
let s:source_directory_async.description =
      \ 'asynchronous candidates from directory by recursive'
let s:source_directory_async.default_kind = 'directory'

function! s:source_directory_async.hooks.on_init(args, context) "{{{
  let a:context.source__is_directory = 1
  call s:on_init(a:args, a:context)
endfunction"}}}

" Misc.
function! s:get_path(args, context) "{{{
  let directory = get(
        \ filter(copy(a:args), "v:val != '!'"), 0, '')
  if directory == ''
    let directory = isdirectory(a:context.input) ?
          \ a:context.input : getcwd()
  endif

  if a:context.is_restart
    let directory = unite#util#input('Target: ',
          \ directory, 'dir', a:context.source_name)
  endif

  if get(a:args, 0, '') == '!'
    " Use project directory.
    return unite#util#path2project_directory(directory, 1)
  endif

  let directory = unite#util#substitute_path_separator(
        \ substitute(fnamemodify(directory, ':p'), '^\~',
        \ unite#util#substitute_path_separator($HOME), ''))

  if directory =~ '/$'
    let directory = directory[: -2]
  endif

  return directory
endfunction"}}}
function! s:get_files(context, files, level, max_unit, ignore_pattern) "{{{
  let continuation_files = []
  let ret_files = []
  let files_index = 0
  let ret_files_len = 0
  for file in a:files
    let files_index += 1

    if file =~ '/\.\+$' || file =~? a:ignore_pattern
      continue
    endif

    if isdirectory(file)
      if getftype(file) ==# 'link'
        let file = s:resolve(file)
        if file == ''
          continue
        endif
      endif

      if file != '/' && file =~ '/$'
        let file = file[: -2]
      endif

      if a:context.source__is_directory &&
            \ file !=# a:context.source__directory
        call add(ret_files, file)
        let ret_files_len += 1
      endif

      let child_index = 0
      let children = exists('*vimproc#readdir') ?
            \ vimproc#readdir(file) :
            \ unite#util#glob(file.'/*') + unite#util#glob(file.'/.*')
      for child in children
        let child = substitute(child, '\/$', '', '')
        let child_index += 1

        if child =~ '/\.\+$' || child =~? a:ignore_pattern
          continue
        endif

        if isdirectory(child)
          if getftype(child) ==# 'link'
            let child = s:resolve(child)
            if child == ''
              continue
            endif
          endif

          if a:context.source__is_directory
            call add(ret_files, child)
            let ret_files_len += 1
          endif

          if a:level < 5 && ret_files_len < a:max_unit
            let [continuation_files_child, ret_files_child] =
                  \ s:get_files(a:context, [child], a:level + 1,
                  \  a:max_unit - ret_files_len, a:ignore_pattern)
            let continuation_files += continuation_files_child

            if !a:context.source__is_directory
              let ret_files += ret_files_child
              let ret_files_len += len(ret_files_child)
            endif
          else
            call add(continuation_files, child)
          endif
        elseif !a:context.source__is_directory
          call add(ret_files, child)

          let ret_files_len += 1

          if ret_files_len > a:max_unit
            let continuation_files += children[child_index :]
            break
          endif
        endif
      endfor
    elseif !a:context.source__is_directory
      call add(ret_files, file)
      let ret_files_len += 1
    endif

    if ret_files_len > a:max_unit
      break
    endif
  endfor

  let continuation_files += a:files[files_index :]
  return [continuation_files, map(ret_files,
        \ "unite#util#substitute_path_separator(fnamemodify(v:val, ':p'))")]
endfunction"}}}
function! s:on_init(args, context) "{{{
  augroup plugin-unite-source-file_rec
    autocmd!
    autocmd BufEnter,BufWinEnter,BufFilePost,BufWritePost *
          \ call unite#sources#rec#_append()
  augroup END
endfunction"}}}
function! s:init_continuation(context, directory) "{{{
  let cache_dir = g:unite_data_directory . '/rec/' .
        \ (a:context.source__is_directory ? 'directory' : 'file')
  let continuation = (a:context.source__is_directory) ?
        \ s:continuation.directory : s:continuation.file

  if !has_key(continuation, a:directory)
        \ && s:Cache.filereadable(cache_dir, a:directory)
    " Use cache file.

    let files = map(s:Cache.readfile(cache_dir, a:directory), "{
          \   'word' : unite#util#substitute_path_separator(
          \      fnamemodify(v:val, ':p')),
          \   'action__path' : v:val,
          \ }")

    let continuation[a:directory] = {
          \ 'files' : files,
          \ 'rest' : [],
          \ 'directory' : a:directory, 'end' : 1,
          \ }
  elseif a:context.is_redraw
        \ || !has_key(continuation, a:directory)
    let a:context.is_async = 1

    let continuation[a:directory] = {
          \ 'files' : [], 'rest' : [a:directory],
          \ 'directory' : a:directory, 'end' : 0,
          \ }
  endif

  let a:context.source__continuation = continuation[a:directory]
  let a:context.source__continuation.files =
        \ filter(copy(a:context.source__continuation.files),
        \ (a:context.source__is_directory) ?
        \   'isdirectory(v:val.action__path)' :
        \   'filereadable(v:val.action__path)')
endfunction"}}}
function! s:write_cache(context, directory, files) "{{{
  let cache_dir = g:unite_data_directory . '/rec/' .
        \ (a:context.source__is_directory ? 'directory' : 'file')

  if g:unite_source_rec_min_cache_files > 0
        \ && len(a:files) >
        \ g:unite_source_rec_min_cache_files
    call s:Cache.writefile(cache_dir, a:directory,
          \ map(copy(a:files), 'v:val.action__path'))
  elseif s:Cache.filereadable(cache_dir, a:directory)
    " Delete old cache files.
    call s:Cache.deletefile(cache_dir, a:directory)
  endif
endfunction"}}}

function! unite#sources#rec#_append() "{{{
  let path = expand('%:p')
  if path !~ '\a\+:'
    let path = simplify(resolve(path))
  endif

  " Append the current buffer to the mru list.
  if !filereadable(path) || &l:buftype =~# 'help\|nofile'
    return
  endif

  let path = unite#util#substitute_path_separator(path)

  " Check continuation.
  let base_path = unite#util#substitute_path_separator(
        \ fnamemodify(path, ':h')) . '/'
  for continuation in values(filter(copy(s:continuation.file),
        \ "stridx(v:key.'/', base_path) == 0"))
    let continuation.files = unite#util#uniq(add(
          \ continuation.files, {
            \ 'word' : path, 'action__path' : path,
            \ }))
  endfor
endfunction"}}}

function! unite#sources#rec#define() "{{{
  let sources = [ s:source_file_rec, s:source_directory_rec ]
  let sources += [ s:source_file_async, s:source_directory_async]
  return sources
endfunction"}}}

function! s:resolve(file) "{{{
  " Detect symbolic link loop.
  let file_link = unite#util#substitute_path_separator(
        \ resolve(a:file))
  return stridx(a:file, file_link.'/') == 0 ? '' : file_link
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
