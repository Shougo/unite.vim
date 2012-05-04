"=============================================================================
" FILE: file_rec.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 04 May 2012.
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
      \'\%(^\|/\)\.$\|\~$\|\.\%(o\|exe\|dll\|bak\|sw[po]\|class\)$'.
      \'\|\%(^\|/\)\.\%(hg\|git\|bzr\|svn\)\%($\|/\)')
call unite#util#set_default(
      \ 'g:unite_source_file_rec_min_cache_files', 100)
"}}}

let s:Cache = vital#of('unite.vim').import('System.Cache')

function! unite#sources#file_rec#define()"{{{
  return [ s:source_rec ]
        \ + [ executable('find')
        \   && unite#util#has_vimproc() ? s:source_async : {} ]
endfunction"}}}

let s:continuation = {}

" Source rec.
let s:source_rec = {
      \ 'name' : 'file_rec',
      \ 'description' : 'candidates from directory by recursive',
      \ 'hooks' : {},
      \ 'max_candidates' : 50,
      \ }

function! s:source_rec.gather_candidates(args, context)"{{{
  let a:context.source__directory = s:get_path(a:args, a:context)

  let directory = a:context.source__directory
  if directory == ''
    " Not in project directory.
    call unite#print_source_message(
          \ 'Not in project directory.', s:source_rec.name)
    let a:context.is_async = 0
    return []
  endif

  call unite#print_source_message(
        \ 'directory: ' . directory, s:source_rec.name)

  call s:init_continuation(a:context, directory)

  let continuation = s:continuation[directory]

  if empty(continuation.rest) || continuation.end
    " Disable async.
    call unite#print_source_message(
          \ 'Directory traverse was completed.', s:source_rec.name)
    let a:context.is_async = 0
    let continuation.end = 1
  endif

  return continuation.files
endfunction"}}}

function! s:source_rec.async_gather_candidates(args, context)"{{{
  let continuation = s:continuation[a:context.source__directory]

  let [continuation.rest, files] =
        \ s:get_files(continuation.rest, 1, 20)

  if empty(continuation.rest)
    call unite#print_source_message(
          \ 'Directory traverse was completed.', s:source_rec.name)

    " Disable async.
    let a:context.is_async = 0
    let continuation.end = 1
  endif

  let is_relative_path =
        \ a:context.source__directory ==
        \   unite#util#substitute_path_separator(getcwd())

  if !is_relative_path
    let cwd = getcwd()
    lcd `=a:context.source__directory`
  endif

  let candidates = map(files, "{
        \ 'word' : unite#util#substitute_path_separator(
        \    fnamemodify(v:val, ':.')),
        \ 'action__path' : v:val,
        \ }")

  if !is_relative_path
    lcd `=cwd`
  endif

  let continuation.files += candidates
  if empty(continuation.rest)
        \ && g:unite_source_file_rec_min_cache_files > 0
        \ && len(continuation.files) >
        \ g:unite_source_file_rec_min_cache_files
    let cache_dir = g:unite_data_directory . '/file_rec'

    call s:Cache.writefile(cache_dir, a:context.source__directory,
          \ map(copy(continuation.files), 'v:val.action__path'))
  endif

  return candidates
endfunction"}}}

function! s:source_rec.hooks.on_pre_filter(args, context)"{{{
  call s:on_pre_filter(a:args, a:context)
endfunction"}}}
function! s:source_rec.hooks.on_post_filter(args, context)"{{{
  call s:on_post_filter(a:args, a:context)
endfunction"}}}

function! s:source_rec.vimfiler_check_filetype(args, context)"{{{
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
function! s:source_rec.vimfiler_gather_candidates(args, context)"{{{
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

  return candidates
endfunction"}}}
function! s:source_rec.vimfiler_dummy_candidates(args, context)"{{{
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

  return candidates
endfunction"}}}
function! s:source_rec.vimfiler_complete(args, context, arglead, cmdline, cursorpos)"{{{
  return unite#sources#file#complete_directory(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}
function! s:source_rec.complete(args, context, arglead, cmdline, cursorpos)"{{{
  return unite#sources#file#complete_directory(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}

" Source async.
let s:source_async = {
      \ 'name' : 'file_rec/async',
      \ 'description' : 'asyncronous candidates from directory by recursive',
      \ 'hooks' : {},
      \ 'max_candidates' : 50,
      \ }

function! s:source_async.gather_candidates(args, context)"{{{
  let a:context.source__directory = s:get_path(a:args, a:context)

  let directory = a:context.source__directory
  if directory == ''
    " Not in project directory.
    call unite#print_source_message(
          \ 'Not in project directory.', s:source_async.name)
    let a:context.is_async = 0
    return []
  endif

  call unite#print_source_message(
        \ 'directory: ' . directory, s:source_async.name)

  call s:init_continuation(a:context, directory)

  let continuation = s:continuation[directory]

  if empty(continuation.rest) || continuation.end
    " Disable async.
    call unite#print_source_message(
          \ 'Directory traverse was completed.', s:source_async.name)
    let a:context.is_async = 0
    let continuation.end = 1

    return continuation.files
  endif

  let a:context.source__proc = vimproc#pgroup_open(
        \ printf('find ''%s'' -type f', directory))

  " Close handles.
  call a:context.source__proc.stdin.close()

  return []
endfunction"}}}

function! s:source_async.async_gather_candidates(args, context)"{{{
  let stderr = a:context.source__proc.stderr
  if !stderr.eof
    " Print error.
    let errors = filter(stderr.read_lines(-1, 100),
          \ "v:val !~ '^\\s*$'")
    if !empty(errors)
      call unite#print_source_error(errors, s:source_async.name)
    endif
  endif

  let continuation = s:continuation[a:context.source__directory]

  let stdout = a:context.source__proc.stdout
  if stdout.eof
    " Disable async.
    call unite#print_source_message(
          \ 'Directory traverse was completed.', s:source_async.name)
    let a:context.is_async = 0
    let continuation.end = 1
  endif

  let is_relative_path =
        \ a:context.source__directory ==
        \   unite#util#substitute_path_separator(getcwd())

  if !is_relative_path
    let cwd = getcwd()
    lcd `=a:context.source__directory`
  endif

  let candidates = []
  for filename in map(filter(
        \ stdout.read_lines(-1, 100), 'v:val != ""'),
        \ "fnamemodify(iconv(v:val, 'char', &encoding), ':p')")
    if (g:unite_source_file_rec_ignore_pattern == ''
          \ || filename !~ g:unite_source_file_rec_ignore_pattern)
      call add(candidates, {
            \ 'word' : unite#util#substitute_path_separator(
            \    fnamemodify(filename, ':.')),
            \ 'action__path' : filename,
            \ })
    endif
  endfor

  if !is_relative_path
    lcd `=cwd`
  endif

  let continuation.files += candidates
  if stdout.eof
        \ && g:unite_source_file_rec_min_cache_files > 0
        \ && len(continuation.files) >
        \ g:unite_source_file_rec_min_cache_files
    let cache_dir = g:unite_data_directory . '/file_rec'

    call s:Cache.writefile(cache_dir, a:context.source__directory,
          \ map(copy(continuation.files), 'v:val.action__path'))
  endif

  return candidates
endfunction"}}}

function! s:source_async.hooks.on_close(args, context) "{{{
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.waitpid()
  endif
endfunction "}}}
function! s:source_async.hooks.on_pre_filter(args, context)"{{{
  call s:on_pre_filter(a:args, a:context)
endfunction"}}}
function! s:source_async.hooks.on_post_filter(args, context)"{{{
  call s:on_post_filter(a:args, a:context)
endfunction"}}}

function! s:source_async.complete(args, context, arglead, cmdline, cursorpos)"{{{
  return unite#sources#file#complete_directory(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}

" Add custom action table."{{{
let s:cdable_action_rec = {
      \ 'description' : 'open this directory by file_rec source',
      \}

function! s:cdable_action_rec.func(candidate)
  call unite#start([['file_rec', a:candidate.action__directory]])
endfunction

let s:cdable_action_rec_parent = {
      \ 'description' : 'open parent directory by file_rec source',
      \}

function! s:cdable_action_rec_parent.func(candidate)
  call unite#start([['file_rec', unite#util#substitute_path_separator(
        \ fnamemodify(a:candidate.action__directory, ':h'))
        \ ]])
endfunction

let s:cdable_action_rec_async = {
      \ 'description' : 'open this directory by file_rec/async source',
      \}

function! s:cdable_action_rec_async.func(candidate)
  call unite#start([['file_rec/async', a:candidate.action__directory]])
endfunction

let s:cdable_action_rec_parent_async = {
      \ 'description' : 'open parent directory by file_rec/async source',
      \}

function! s:cdable_action_rec_parent_async.func(candidate)
  call unite#start([['file_rec/async', unite#util#substitute_path_separator(
        \ fnamemodify(a:candidate.action__directory, ':h'))
        \ ]])
endfunction

call unite#custom_action('cdable', 'rec', s:cdable_action_rec)
call unite#custom_action('cdable', 'rec_parent', s:cdable_action_rec_parent)
call unite#custom_action('cdable', 'rec/async', s:cdable_action_rec_async)
call unite#custom_action('cdable', 'rec_parent/async', s:cdable_action_rec_parent_async)
unlet! s:cdable_action_rec
unlet! s:cdable_action_rec_async
"}}}

" Misc.
function! s:get_path(args, context)"{{{
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

  return unite#util#substitute_path_separator(
        \ substitute(fnamemodify(directory, ':p'), '^\~',
        \ unite#util#substitute_path_separator($HOME), ''))
endfunction"}}}
function! s:get_files(files, level, max_len)"{{{
  let continuation_files = []
  let ret_files = []
  let files_index = 0
  let ret_files_len = 0
  for file in a:files
    let files_index += 1

    if file =~ '/\.\+$'
          \ || (g:unite_source_file_rec_ignore_pattern != '' &&
          \     file =~ g:unite_source_file_rec_ignore_pattern)
          \ || isdirectory(file) && getftype(file) ==# 'link'
      continue
    endif

    if isdirectory(file)
      if file != '/' && file =~ '/$'
        let file = file[: -2]
      endif

      let child_index = 0
      let childs = unite#util#glob(file.'/*') + unite#util#glob(file.'/.*')
      for child in childs
        let child_index += 1

        if child =~ '/\.\+$'
              \ ||(g:unite_source_file_rec_ignore_pattern != '' &&
              \     child =~ g:unite_source_file_rec_ignore_pattern)
              \ || isdirectory(child) && getftype(child) ==# 'link'
          continue
        endif

        if isdirectory(child)
          if a:level < 5 && ret_files_len < a:max_len
            let [continuation_files_child, ret_files_child] =
                  \ s:get_files([child], a:level + 1, a:max_len - ret_files_len)
            let continuation_files += continuation_files_child
            let ret_files += ret_files_child
          else
            call add(continuation_files, child)
          endif
        else
          call add(ret_files, child)

          let ret_files_len += 1

          if ret_files_len > a:max_len
            let continuation_files += childs[child_index :]
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
function! s:on_post_filter(args, context)"{{{
  let is_relative_path =
        \ a:context.source__directory ==
        \   unite#util#substitute_path_separator(getcwd())

  for candidate in a:context.candidates
    let candidate.kind = 'file'
    let candidate.abbr = candidate.word .
          \ (isdirectory(candidate.word) ? '/' : '')
    let candidate.action__directory = is_relative_path ?
          \ candidate.abbr :
          \ unite#util#path2directory(candidate.action__path)
  endfor
endfunction"}}}
function! s:on_pre_filter(args, context)"{{{
  let a:context.candidates = unite#call_filter(
        \ 'matcher_hide_hidden_files', a:context.candidates, a:context)
endfunction"}}}
function! s:init_continuation(context, directory)"{{{
  let cache_dir = g:unite_data_directory . '/file_rec'
  if !has_key(s:continuation, a:directory)
        \ && s:Cache.filereadable(cache_dir, a:directory)
    " Use cache file.

    let is_relative_path =
          \ a:context.source__directory ==
          \   unite#util#substitute_path_separator(getcwd())

    if !is_relative_path
      let cwd = getcwd()
      lcd `=a:context.source__directory`
    endif

    let files = map(s:Cache.readfile(cache_dir, a:directory), "{
          \ 'word' : unite#util#substitute_path_separator(
          \    fnamemodify(v:val, ':.')),
          \ 'action__path' : v:val,
          \ }")

    let s:continuation[a:directory] = {
          \ 'files' : files,
          \ 'rest' : [],
          \ 'directory' : a:directory, 'end' : 1,
          \ }

    if !is_relative_path
      lcd `=cwd`
    endif
  endif

  if a:context.is_redraw
        \ || !has_key(s:continuation, a:directory)
    let a:context.is_async = 1

    let s:continuation[a:directory] = {
          \ 'files' : [], 'rest' : [a:directory],
          \ 'directory' : a:directory, 'end' : 0,
          \ }
  endif
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
