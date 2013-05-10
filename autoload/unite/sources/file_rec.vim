"=============================================================================
" FILE: file_rec.vim
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

" Variables  "{{{
call unite#util#set_default(
      \ 'g:unite_source_file_rec_ignore_pattern',
      \'\%(^\|/\)\.$\|\~$\|\.\%(o\|exe\|dll\|bak\|DS_Store\|zwc\|pyc\|sw[po]\|class\)$'.
      \'\|\%(^\|/\)\%(\.hg\|\.git\|\.bzr\|\.svn\|tags\%(-.*\)\?\)\%($\|/\)')
call unite#util#set_default(
      \ 'g:unite_source_file_rec_min_cache_files', 100)
call unite#util#set_default(
      \ 'g:unite_source_file_rec_max_cache_files', 1000)
call unite#util#set_default(
      \ 'g:unite_source_file_rec_async_command',
      \ executable('ag') ? 'ag --nocolor --nogroup -g ""' :
      \ !unite#util#is_windows() && executable('find') ? 'find' :
      \ '')
"}}}

let s:Cache = vital#of('unite.vim').import('System.Cache')

function! unite#sources#file_rec#define() "{{{
  return [ s:source_rec ]
        \ + [ unite#util#has_vimproc() ? s:source_async : {} ]
endfunction"}}}

let s:continuation = {}

" Source rec.
let s:source_rec = {
      \ 'name' : 'file_rec',
      \ 'description' : 'candidates from directory by recursive',
      \ 'hooks' : {},
      \ 'default_kind' : 'file',
      \ 'max_candidates' : 50,
      \ 'ignore_pattern' : g:unite_source_file_rec_ignore_pattern,
      \ 'converters' : 'converter_relative_word',
      \ 'matchers' : [ 'matcher_default', 'matcher_hide_hidden_files' ],
      \ }

function! s:source_rec.gather_candidates(args, context) "{{{
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

  let continuation = s:continuation[directory]

  if empty(continuation.rest) || continuation.end
    " Disable async.
    call unite#print_source_message(
          \ 'Directory traverse was completed.', self.name)
    let a:context.is_async = 0
    let continuation.end = 1
  endif

  return deepcopy(continuation.files)
endfunction"}}}

function! s:source_rec.async_gather_candidates(args, context) "{{{
  let continuation = s:continuation[a:context.source__directory]

  let [continuation.rest, files] =
        \ s:get_files(continuation.rest, 1, 20,
        \   a:context.source.ignore_pattern)

  if empty(continuation.rest) || len(continuation.files) >
        \                    g:unite_source_file_rec_max_cache_files
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
    call s:write_cache(a:context.source__directory,
          \ continuation.files)
  endif

  return deepcopy(candidates)
endfunction"}}}

function! s:source_rec.hooks.on_init(args, context) "{{{
  call s:on_init(a:args, a:context)
endfunction"}}}
function! s:source_rec.hooks.on_post_filter(args, context) "{{{
  call s:on_post_filter(a:args, a:context)
endfunction"}}}

function! s:source_rec.vimfiler_check_filetype(args, context) "{{{
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
function! s:source_rec.vimfiler_gather_candidates(args, context) "{{{
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
function! s:source_rec.vimfiler_dummy_candidates(args, context) "{{{
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
function! s:source_rec.vimfiler_complete(args, context, arglead, cmdline, cursorpos) "{{{
  return unite#sources#file#complete_directory(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}
function! s:source_rec.complete(args, context, arglead, cmdline, cursorpos) "{{{
  return unite#sources#file#complete_directory(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}

" Source async.
let s:source_async = {
      \ 'name' : 'file_rec/async',
      \ 'description' : 'asyncronous candidates from directory by recursive',
      \ 'hooks' : {},
      \ 'default_kind' : 'file',
      \ 'max_candidates' : 50,
      \ 'ignore_pattern' : g:unite_source_file_rec_ignore_pattern,
      \ 'matchers' : ['converter_relative_word',
      \    'matcher_default', 'matcher_hide_hidden_files'],
      \ }

function! s:source_async.gather_candidates(args, context) "{{{
  if g:unite_source_file_rec_async_command == ''
    call unite#print_source_message(
          \ 'g:unite_source_file_rec_async_command is not executable.', self.name)
    return []
  endif

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

  let continuation = s:continuation[directory]

  if empty(continuation.rest) || continuation.end
    " Disable async.
    call unite#print_source_message(
          \ 'Directory traverse was completed.', self.name)
    let a:context.is_async = 0
    let continuation.end = 1

    return deepcopy(continuation.files)
  endif

  let a:context.source__proc = vimproc#pgroup_open(
        \ g:unite_source_file_rec_async_command
        \ . ' ' . string(directory)
        \ . (g:unite_source_file_rec_async_command ==#
        \         'find' ? ' -type f' : ''))

  " Close handles.
  call a:context.source__proc.stdin.close()

  return []
endfunction"}}}

function! s:source_async.async_gather_candidates(args, context) "{{{
  let stderr = a:context.source__proc.stderr
  if !stderr.eof
    " Print error.
    let errors = filter(stderr.read_lines(-1, 100),
          \ "v:val !~ '^\\s*$'")
    if !empty(errors)
      call unite#print_source_error(errors, self.name)
    endif
  endif

  let continuation = s:continuation[a:context.source__directory]

  let stdout = a:context.source__proc.stdout
  if stdout.eof || len(continuation.files) >
        \        g:unite_source_file_rec_max_cache_files
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
  endif

  let candidates = []
  for filename in map(filter(
        \ stdout.read_lines(-1, 100), 'v:val != ""'),
        \ "fnamemodify(unite#util#iconv(v:val, 'char', &encoding), ':p')")
    if !isdirectory(filename) && filename !~? a:context.source.ignore_pattern
      call add(candidates, {
            \ 'word' : unite#util#substitute_path_separator(
            \    fnamemodify(filename, ':p')),
            \ 'action__path' : filename,
            \ })
    endif
  endfor

  let continuation.files += candidates
  if stdout.eof
    call s:write_cache(a:context.source__directory,
          \ continuation.files)
  endif

  return deepcopy(candidates)
endfunction"}}}

function! s:source_async.hooks.on_init(args, context) "{{{
  call s:on_init(a:args, a:context)
endfunction"}}}
function! s:source_async.hooks.on_close(args, context) "{{{
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.waitpid()
  endif
endfunction "}}}
function! s:source_async.hooks.on_post_filter(args, context) "{{{
  call s:on_post_filter(a:args, a:context)
endfunction"}}}

function! s:source_async.complete(args, context, arglead, cmdline, cursorpos) "{{{
  return unite#sources#file#complete_directory(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}

" Add custom action table. "{{{
let s:cdable_action_rec = {
      \ 'description' : 'open this directory by file_rec source',
      \ 'is_start' : 1,
      \}

function! s:cdable_action_rec.func(candidate)
  call unite#start_script([['file_rec', a:candidate.action__directory]])
endfunction

let s:cdable_action_rec_parent = {
      \ 'description' : 'open parent directory by file_rec source',
      \ 'is_start' : 1,
      \}

function! s:cdable_action_rec_parent.func(candidate)
  call unite#start_script([['file_rec', unite#util#substitute_path_separator(
        \ fnamemodify(a:candidate.action__directory, ':h'))
        \ ]])
endfunction

let s:cdable_action_rec_project = {
      \ 'description' : 'open project directory by file_rec source',
      \ 'is_start' : 1,
      \}

function! s:cdable_action_rec_project.func(candidate)
  call unite#start_script([['file_rec', unite#util#substitute_path_separator(
        \ unite#util#path2project_directory(a:candidate.action__directory))
        \ ]])
endfunction

let s:cdable_action_rec_async = {
      \ 'description' : 'open this directory by file_rec/async source',
      \ 'is_start' : 1,
      \}

function! s:cdable_action_rec_async.func(candidate)
  call unite#start_script([['file_rec/async', a:candidate.action__directory]])
endfunction

let s:cdable_action_rec_parent_async = {
      \ 'description' : 'open parent directory by file_rec/async source',
      \ 'is_start' : 1,
      \}

function! s:cdable_action_rec_parent_async.func(candidate)
  call unite#start_script([['file_rec/async', unite#util#substitute_path_separator(
        \ fnamemodify(a:candidate.action__directory, ':h'))
        \ ]])
endfunction

let s:cdable_action_rec_project_async = {
      \ 'description' : 'open project directory by file_rec/async source',
      \ 'is_start' : 1,
      \}

function! s:cdable_action_rec_project_async.func(candidate)
  call unite#start_script([['file_rec/async', unite#util#substitute_path_separator(
        \ unite#util#path2project_directory(a:candidate.action__directory))
        \ ]])
endfunction

call unite#custom_action('cdable', 'rec', s:cdable_action_rec)
call unite#custom_action('cdable', 'rec_parent', s:cdable_action_rec_parent)
call unite#custom_action('cdable', 'rec_project', s:cdable_action_rec_project)
call unite#custom_action('cdable', 'rec/async', s:cdable_action_rec_async)
call unite#custom_action('cdable', 'rec_parent/async', s:cdable_action_rec_parent_async)
call unite#custom_action('cdable', 'rec_project/async', s:cdable_action_rec_project_async)
unlet! s:cdable_action_rec
unlet! s:cdable_action_rec_async
unlet! s:cdable_action_rec_project
unlet! s:cdable_action_rec_project_async
unlet! s:cdable_action_rec_parent
unlet! s:cdable_action_rec_parent_async
"}}}

" Misc.
function! s:get_path(args, context) "{{{
  let directory = get(
        \ filter(copy(a:args), "v:val != '!'"), 0, '')
  if directory == ''
    let directory = isdirectory(a:context.input) ?
          \ a:context.input : getcwd()
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
function! s:get_files(files, level, max_len, ignore_pattern) "{{{
  let continuation_files = []
  let ret_files = []
  let files_index = 0
  let ret_files_len = 0
  for file in a:files
    let files_index += 1

    if file =~ '/\.\+$' || file =~? a:ignore_pattern
          \ || (isdirectory(file) && getftype(file) ==# 'link')
      continue
    endif

    if isdirectory(file)
      if file != '/' && file =~ '/$'
        let file = file[: -2]
      endif

      let child_index = 0
      let children = exists('*vimproc#readdir') ?
            \ vimproc#readdir(file) :
            \ unite#util#glob(file.'/*') + unite#util#glob(file.'/.*')
      for child in children
        let child = substitute(child, '\/$', '', '')
        let child_index += 1

        if child =~ '/\.\+$' || child =~? a:ignore_pattern
              \ || (isdirectory(child) && getftype(child) ==# 'link')
          continue
        endif

        if isdirectory(child)
          if a:level < 5 && ret_files_len < a:max_len
            let [continuation_files_child, ret_files_child] =
                  \ s:get_files([child], a:level + 1,
                  \  a:max_len - ret_files_len, a:ignore_pattern)
            let continuation_files += continuation_files_child
            let ret_files += ret_files_child
          else
            call add(continuation_files, child)
          endif
        else
          call add(ret_files, child)

          let ret_files_len += 1

          if ret_files_len > a:max_len
            let continuation_files += children[child_index :]
            break
          endif
        endif
      endfor
    else
      call add(ret_files, file)
      let ret_files_len += 1
    endif

    if ret_files_len > a:max_len
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
          \ call unite#sources#file_rec#_append()
  augroup END
endfunction"}}}
function! s:on_post_filter(args, context) "{{{
  for candidate in a:context.candidates
    let candidate.action__directory =
          \ unite#util#path2directory(candidate.action__path)
  endfor
endfunction"}}}
function! s:init_continuation(context, directory) "{{{
  let cache_dir = g:unite_data_directory . '/file_rec'
  if !has_key(s:continuation, a:directory)
        \ && s:Cache.filereadable(cache_dir, a:directory)
    " Use cache file.

    let files = map(s:Cache.readfile(cache_dir, a:directory), "{
          \   'word' : unite#util#substitute_path_separator(
          \      fnamemodify(v:val, ':p')),
          \   'action__path' : v:val,
          \ }")

    let s:continuation[a:directory] = {
          \ 'files' : files,
          \ 'rest' : [],
          \ 'directory' : a:directory, 'end' : 1,
          \ }
  elseif a:context.is_redraw
        \ || !has_key(s:continuation, a:directory)
    let a:context.is_async = 1

    let s:continuation[a:directory] = {
          \ 'files' : [], 'rest' : [a:directory],
          \ 'directory' : a:directory, 'end' : 0,
          \ }
  endif

  let s:continuation[a:directory].files =
        \ filter(unite#util#uniq(s:continuation[a:directory].files),
        \ 'filereadable(v:val.action__path)')
endfunction"}}}
function! s:write_cache(directory, files) "{{{
  let cache_dir = g:unite_data_directory . '/file_rec'

  if g:unite_source_file_rec_min_cache_files > 0
        \ && len(a:files) >
        \ g:unite_source_file_rec_min_cache_files
    call s:Cache.writefile(cache_dir, a:directory,
          \ map(copy(a:files), 'v:val.action__path'))
  elseif s:Cache.filereadable(cache_dir, a:directory)
    " Delete old cache files.
    call s:Cache.delete(cache_dir, a:directory)
  endif
endfunction"}}}

function! unite#sources#file_rec#_append() "{{{
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
  for continuation in values(filter(copy(s:continuation),
        \ "stridx(v:key.'/', base_path) == 0"))
    let continuation.files = unite#util#uniq(add(
          \ continuation.files, {
            \ 'word' : path, 'action__path' : path,
            \ }))
  endfor
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
