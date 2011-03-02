"=============================================================================
" FILE: file_rec.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 02 Mar 2011.
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

" Variables  "{{{
call unite#util#set_default('g:unite_source_file_rec_ignore_pattern', 
      \'\%(^\|/\)\.$\|\~$\|\.\%(o|exe|dll|bak|sw[po]\)$\|\%(^\|/\)\.\%(hg\|git\|bzr\|svn\)\%($\|/\)')
"}}}

function! unite#sources#file_rec#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'file_rec',
      \ 'description' : 'candidates from directory by recursive',
      \ 'max_candidates' : 50,
      \ }

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

  " Initialize continuation.
  let a:context.source__continuation = {
        \ 'files' : [l:directory],
        \ }

  return []
endfunction"}}}

function! s:source.async_gather_candidates(args, context)"{{{
  if empty(a:context.source__continuation.files)
    return []
  endif

  let [a:context.source__continuation.files, l:candidates] =
        \ s:get_files(a:context.source__continuation.files)

  if empty(a:context.source__continuation.files)
    call unite#print_message('[file_rec] Directory traverse was completed.')
  endif

  return map(l:candidates, '{
        \ "word" : unite#util#substitute_path_separator(fnamemodify(v:val, ":p")),
        \ "abbr" : unite#util#substitute_path_separator(fnamemodify(v:val, ":.")),
        \ "source" : "file_rec",
        \ "kind" : "file",
        \ "action__path" : unite#util#substitute_path_separator(fnamemodify(v:val, ":p")),
        \ "action__directory" : unite#util#path2directory(v:val),
        \ }')
endfunction"}}}

" Add custom action table."{{{
let s:cdable_action_rec = {
      \ 'description' : 'open this directory by file_rec',
      \}

function! s:cdable_action_rec.func(candidate)
  call unite#start([['file_rec', a:candidate.action__directory]])
endfunction

call unite#custom_action('cdable', 'rec', s:cdable_action_rec)
unlet! s:cdable_action_rec
"}}}

function! s:get_files(files)"{{{
  let l:continuation_files = []
  let l:ret_files = []
  let l:max_len = 20
  let l:files_index = 0
  let l:ret_files_len = 0
  for l:file in a:files
    let l:files_index += 1

    if g:unite_source_file_rec_ignore_pattern != '' &&
          \ l:file =~ g:unite_source_file_rec_ignore_pattern
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

        if l:child =~ '/\.\%(\.\|$\)'
              \ ||(g:unite_source_file_rec_ignore_pattern != '' &&
              \     l:child =~ g:unite_source_file_rec_ignore_pattern)
          continue
        endif

        call add(isdirectory(l:child) ? l:continuation_files : l:ret_files, l:child)
        let l:ret_files_len += 1

        if l:ret_files_len > l:max_len
          let l:continuation_files += l:childs[l:child_index :]
          break
        endif
      endfor
    else
      call add(l:ret_files, l:file)
      let l:ret_files_len += 1
    endif

    if l:ret_files_len > l:max_len
      break
    endif
  endfor

  let l:continuation_files += a:files[l:files_index :]
  return [l:continuation_files, l:ret_files]
endfunction"}}}

" vim: foldmethod=marker
