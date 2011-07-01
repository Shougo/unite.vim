"=============================================================================
" FILE: file_rec.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 01 Jul 2011.
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
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'file_rec',
      \ 'description' : 'candidates from directory by recursive',
      \ 'max_candidates' : 50,
      \ }

let s:continuation = {}

function! s:source.gather_candidates(args, context)"{{{
  if !empty(a:args)
    let l:directory = a:args[0]
  elseif isdirectory(a:context.input)
    let l:directory = a:context.input
  else
    let l:directory = getcwd()
  endif
  let l:directory = unite#util#substitute_path_separator(
        \ substitute(l:directory, '^\~', unite#util#substitute_path_separator($HOME), ''))

  call unite#print_message('[file_rec] directory: ' . l:directory)

  let a:context.source__directory = l:directory
  if a:context.is_redraw || !has_key(s:continuation, l:directory)
        \ || len(s:continuation[l:directory].cached) < 50
    let a:context.is_async = 1

    " Initialize continuation.
    let s:continuation[l:directory] = {
          \ 'files' : [l:directory],
          \ 'cached' : [],
          \ }
  endif

  let l:continuation = s:continuation[a:context.source__directory]

  if empty(l:continuation.files)
    " Disable async.
    call unite#print_message('[file_rec] Directory traverse was completed.')
    let a:context.is_async = 0
  endif

  return l:continuation.cached
endfunction"}}}

function! s:source.async_gather_candidates(args, context)"{{{
  let l:continuation = s:continuation[a:context.source__directory]
  let [l:continuation.files, l:files] = s:get_files(l:continuation.files, 1, 30)

  if empty(l:continuation.files)
    call unite#print_message('[file_rec] Directory traverse was completed.')

    " Disable async.
    let a:context.is_async = 0
  endif

  let l:is_relative_path =
        \ a:context.source__directory == unite#util#substitute_path_separator(getcwd())

  let l:candidates = []
  for l:file in l:files
    let l:dict = {
        \ 'word' : unite#util#substitute_path_separator(fnamemodify(l:file, ':p')),
        \ 'abbr' : unite#util#substitute_path_separator(fnamemodify(l:file, ':.')),
        \ 'kind' : 'file',
        \ }
    let l:dict.action__path = l:dict.word
    let l:dict.action__directory = l:is_relative_path ?
          \ fnamemodify(unite#util#path2directory(l:file), ':.') :
          \ unite#util#path2directory(l:dict.action__path)

    call add(l:candidates, l:dict)
  endfor

  let l:continuation.cached += l:candidates

  return l:candidates
endfunction"}}}

" Add custom action table."{{{
let s:cdable_action_rec = {
      \ 'description' : 'open this directory by file_rec source',
      \}

function! s:cdable_action_rec.func(candidate)
  call unite#start([['file_rec', a:candidate.action__directory]])
endfunction

call unite#custom_action('cdable', 'rec', s:cdable_action_rec)
unlet! s:cdable_action_rec
"}}}

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
      continue
    endif

    if isdirectory(l:file) && getftype(l:file) !=# 'link'
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
          continue
        endif

        if isdirectory(l:child) && getftype(l:file) !=# 'link'
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
        endif

        let l:ret_files_len += 1

        if l:ret_files_len > a:max_len
          let l:continuation_files += l:childs[l:child_index :]
          break
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
  return [l:continuation_files, l:ret_files]
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
