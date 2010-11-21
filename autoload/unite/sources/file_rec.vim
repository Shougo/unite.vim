"=============================================================================
" FILE: file_rec.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 21 Nov 2010
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
if !exists('g:unite_source_file_rec_max_depth')
  let g:unite_source_file_rec_max_depth = 10
endif
"}}}

function! unite#sources#file_rec#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'file_rec',
      \ 'max_candidates': 30,
      \}

function! s:source.gather_candidates(args, context)"{{{
  if !empty(a:args)
    let l:directory = unite#substitute_path_separator(a:args[0])
  elseif isdirectory(a:context.input)
    let l:directory = a:context.input
  else
    let l:directory = unite#substitute_path_separator(getcwd())
  endif

  if l:directory =~ '/$'
    let l:directory = l:directory[: -2]
  endif

  let s:start_time = has('reltime') ? reltime() : 0
  let l:candidates = s:get_files(1, l:directory, [])

  if g:unite_source_file_ignore_pattern != ''
    call filter(l:candidates, 'v:val !~ ' . string(g:unite_source_file_ignore_pattern))
  endif

  return map(l:candidates, '{
        \ "word" : v:val,
        \ "source" : "file_rec",
        \ "kind" : "file",
        \ "action__path" : unite#util#substitute_path_separator(fnamemodify(v:val, ":p")),
        \ "action__directory" : unite#util#path2directory(fnamemodify(v:val, ":p")),
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

function! s:get_files(depth, directory, files)"{{{
  if a:depth > g:unite_source_file_rec_max_depth
        \ || (has('reltime') && str2nr(split(reltimestr(reltime(s:start_time)))[0]) >= 2)
    return []
  endif

  let l:directory_files = split(unite#substitute_path_separator(glob(a:directory . '/*')), '\n')
  let l:files = a:files
  for l:file in l:directory_files
    if isdirectory(l:file)
      " Get files in a directory.
      let l:files += s:get_files(a:depth + 1, l:file, [])
    else
      call add(l:files, l:file)
    endif
  endfor

  return l:files
endfunction"}}}

" vim: foldmethod=marker
