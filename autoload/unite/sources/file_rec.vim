"=============================================================================
" FILE: file_rec.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 07 Aug 2011.
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
call unite#util#set_default('g:unite_source_file_rec_ignore_pattern',
      \'\%(^\|/\)\.$\|\~$\|\.\%(o|exe|dll|bak|sw[po]\)$\|\%(^\|/\)\.\%(hg\|git\|bzr\|svn\)\%($\|/\)')
call unite#util#set_default('g:unite_source_file_rec_min_cache_files', 50)
"}}}

function! unite#sources#file_rec#define()"{{{
  return [ s:source_rec ]
        \ + [ executable('ls') && unite#util#has_vimproc() ? s:source_async : {} ]
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
  let l:directory = s:get_path(a:args, a:context)

  call unite#print_message('[file_rec] directory: ' . l:directory)

  call s:init_continuation(a:context, l:directory)

  let l:continuation = s:continuation[l:directory]

  let a:context.source__directory = l:directory

  if empty(l:continuation.rest) || l:continuation.end
    " Disable async.
    call unite#print_message('[file_rec] Directory traverse was completed.')
    let a:context.is_async = 0
  endif

  return l:continuation.files
endfunction"}}}

function! s:source_rec.async_gather_candidates(args, context)"{{{
  let l:continuation = s:continuation[a:context.source__directory]

  let [l:continuation.rest, l:files] = s:get_files(l:continuation.rest, 1, 20)

  if empty(l:continuation.rest)
    call unite#print_message('[file_rec] Directory traverse was completed.')

    " Disable async.
    let a:context.is_async = 0
    let l:continuation.end = 1
  endif

  let l:candidates = map(l:files, '{
        \ "word" : v:val, "action__path" : v:val,
        \ }')

  let l:continuation.files += l:candidates

  return l:candidates
endfunction"}}}

function! s:source_rec.hooks.on_post_filter(args, context)"{{{
  call s:on_post_filter(a:args, a:context)
endfunction"}}}

" Source async.
let s:source_async = {
      \ 'name' : 'file_rec/async',
      \ 'description' : 'asyncronous candidates from directory by recursive',
      \ 'hooks' : {},
      \ 'max_candidates' : 50,
      \ }

function! s:source_async.gather_candidates(args, context)"{{{
  let l:directory = s:get_path(a:args, a:context)

  call unite#print_message('[file_rec/async] directory: ' . l:directory)

  call s:init_continuation(a:context, l:directory)

  let l:continuation = s:continuation[l:directory]

  let a:context.source__directory = l:directory

  if empty(l:continuation.rest) || l:continuation.end
    " Disable async.
    call unite#print_message('[file_rec/async] Directory traverse was completed.')
    let a:context.is_async = 0

    return l:continuation.files
  endif

  let a:context.source__proc = vimproc#pgroup_open('ls -R1 '
        \ . escape(l:directory, ' '))

  " Close handles.
  call a:context.source__proc.stdin.close()
  call a:context.source__proc.stderr.close()

  return []
endfunction"}}}

function! s:source_async.async_gather_candidates(args, context)"{{{
  let l:continuation = s:continuation[a:context.source__directory]

  let l:stdout = a:context.source__proc.stdout
  if l:stdout.eof
    " Disable async.
    call unite#print_message('[file_rec] Directory traverse was completed.')
    let a:context.is_async = 0
    let l:continuation.end = 1
  endif

  let l:candidates = []
  for l:line in map(l:stdout.read_lines(-1, 300),
        \ 'iconv(v:val, &termencoding, &encoding)')
    if l:line =~ ':$'
      " Directory name.
      let l:continuation.directory = l:line[: -2]
      if l:continuation.directory !~ '/$'
        let l:continuation.directory .= '/'
      endif
    elseif l:line != ''
          \ && (g:unite_source_file_rec_ignore_pattern == ''
          \      || l:line !~ g:unite_source_file_rec_ignore_pattern)
      call add(l:candidates, {
            \ 'word' : l:continuation.directory . l:line,
            \ 'action__path' : l:continuation.directory . l:line,
            \ })
    endif
  endfor

  let l:continuation.files += l:candidates

  return l:candidates
endfunction"}}}

function! s:source_async.hooks.on_close(args, context) "{{{
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.waitpid()
  endif
endfunction "}}}
function! s:source_async.hooks.on_post_filter(args, context)"{{{
  call s:on_post_filter(a:args, a:context)
endfunction"}}}

" Add custom action table."{{{
let s:cdable_action_rec = {
      \ 'description' : 'open this directory by file_rec source',
      \}

function! s:cdable_action_rec.func(candidate)
  call unite#start([['file_rec', a:candidate.action__directory]])
endfunction

let s:cdable_action_rec_async = {
      \ 'description' : 'open this directory by file_rec/async source',
      \}

function! s:cdable_action_rec_async.func(candidate)
  call unite#start([['file_rec/async', a:candidate.action__directory]])
endfunction

call unite#custom_action('cdable', 'rec', s:cdable_action_rec)
call unite#custom_action('cdable', 'rec/async', s:cdable_action_rec_async)
unlet! s:cdable_action_rec
unlet! s:cdable_action_rec_async
"}}}

" Misc.
function! s:get_path(args, context)"{{{
  let l:directory = get(a:args, 0, '')
  if l:directory == ''
    let l:directory = isdirectory(a:context.input) ?
          \ a:context.input : getcwd()
  endif

  return unite#util#substitute_path_separator(
        \ substitute(fnamemodify(l:directory, ':p'), '^\~',
        \ unite#util#substitute_path_separator($HOME), ''))
endfunction"}}}
function! s:get_files(files, level, max_len)"{{{
  let l:continuation_files = []
  let l:ret_files = []
  let l:files_index = 0
  let l:ret_files_len = 0
  for l:file in a:files
    let l:files_index += 1

    if l:file =~ '/\.\+$'
          \ || (g:unite_source_file_rec_ignore_pattern != '' &&
          \     l:file =~ g:unite_source_file_rec_ignore_pattern)
          \ || isdirectory(l:file) && getftype(l:file) ==# 'link'
      continue
    endif

    if isdirectory(l:file)
      if l:file != '/' && l:file =~ '/$'
        let l:file = l:file[: -2]
      endif

      let l:child_index = 0
      let l:childs = split(unite#util#substitute_path_separator(glob(l:file . '/*')), '\n')
            \ + split(unite#util#substitute_path_separator(glob(l:file . '/.*')), '\n')
      for l:child in l:childs
        let l:child_index += 1

        if l:child =~ '/\.\+$'
              \ ||(g:unite_source_file_rec_ignore_pattern != '' &&
              \     l:child =~ g:unite_source_file_rec_ignore_pattern)
              \ || isdirectory(l:child) && getftype(l:child) ==# 'link'
          continue
        endif

        if isdirectory(l:child)
          if a:level < 5 && l:ret_files_len < a:max_len
            let [l:continuation_files_child, l:ret_files_child] =
                  \ s:get_files([l:child], a:level + 1, a:max_len - l:ret_files_len)
            let l:continuation_files += l:continuation_files_child
            let l:ret_files += l:ret_files_child
          else
            call add(l:continuation_files, l:child)
          endif
        else
          call add(l:ret_files, l:child)

          let l:ret_files_len += 1

          if l:ret_files_len > a:max_len
            let l:continuation_files += l:childs[l:child_index :]
            break
          endif
        endif
      endfor
    else
      call add(l:ret_files, l:file)
      let l:ret_files_len += 1
    endif

    if l:ret_files_len > a:max_len
      break
    endif
  endfor

  let l:continuation_files += a:files[l:files_index :]
  return [l:continuation_files, map(l:ret_files,
        \ 'unite#util#substitute_path_separator(fnamemodify(v:val, ":p"))')]
endfunction"}}}
function! s:on_post_filter(args, context)"{{{
  let l:is_relative_path =
        \ a:context.source__directory == unite#util#substitute_path_separator(getcwd())

  if !l:is_relative_path
    let l:cwd = getcwd()
    lcd `=a:context.source__directory`
  endif

  for l:candidate in a:context.candidates
    let l:candidate.kind = 'file'
    let l:candidate.abbr = unite#util#substitute_path_separator(
          \ fnamemodify(l:candidate.action__path, ':.'))
          \ . (isdirectory(l:candidate.action__path) ? '/' : '')
    let l:candidate.action__directory = l:is_relative_path ?
          \ l:candidate.abbr :
          \ unite#util#path2directory(l:candidate.action__path)
  endfor

  if !l:is_relative_path
    lcd `=l:cwd`
  endif
endfunction"}}}
function! s:init_continuation(context, directory)"{{{
  if a:context.is_redraw
        \ || !has_key(s:continuation, a:directory)
        \ || len(s:continuation[a:directory].files)
        \      < g:unite_source_file_rec_min_cache_files
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
