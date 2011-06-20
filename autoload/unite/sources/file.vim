"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 20 Jun 2011.
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
call unite#util#set_default('g:unite_source_file_ignore_pattern',
      \'^\%(/\|\a\+:/\)$\|\%(^\|/\)\.\.\?$\|\~$\|\.\%(o|exe|dll|bak|sw[po]\)$')
"}}}

function! unite#sources#file#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'file',
      \ 'description' : 'candidates from file list',
      \}

function! s:source.change_candidates(args, context)"{{{
  let l:input_list = filter(split(a:context.input,
        \                     '\\\@<! ', 1), 'v:val !~ "!"')
  let l:input = empty(l:input_list) ? '' : l:input_list[0]
  let l:input = substitute(substitute(a:context.input, '\\ ', ' ', 'g'), '^\a\+:\zs\*/', '/', '')

  if l:input !~ '^\%(/\|\a\+:/\)' && get(a:args, 0) != ''
    let l:input = a:args[0] . '/' .  l:input
  endif
  let l:is_relative_path = l:input !~ '^\%(/\|\a\+:/\)' && get(a:args, 0) == ''

  " Substitute *. -> .* .
  let l:input = substitute(l:input, '\*\.', '.*', 'g')

  if l:input !~ '\*' && unite#is_win() && getftype(l:input) == 'link'
    " Resolve link.
    let l:input = resolve(l:input)
  endif

  " Glob by directory name.
  let l:input = substitute(l:input, '[^/.]*$', '', '')
  let l:candidates = split(unite#util#substitute_path_separator(glob(l:input . (l:input =~ '\*$' ? '' : '*'))), '\n')

  if a:context.input != ''
    let l:newfile = substitute(a:context.input, '[*\\]', '', 'g')
    " if (!filereadable(l:newfile) && !isdirectory(l:newfile) && isdirectory(fnamemodify(l:newfile, ':h')))
    if !filereadable(l:newfile) && !isdirectory(l:newfile)
      " Add newfile candidate.
      call add(l:candidates, l:newfile)
    endif
  endif

  if g:unite_source_file_ignore_pattern != ''
    call filter(l:candidates, 'v:val !~ ' . string(g:unite_source_file_ignore_pattern))
  endif

  if l:input !~ '^\%(/\|\a\+:/\)$'
    let l:parent = substitute(l:input, '[*\\]\|\.[^/]*$', '', 'g')

    " if (l:input == '' || isdirectory(l:input)) && isdirectory(l:parent . '..')
    if a:context.input =~ '\.$' && isdirectory(l:parent . '..')
      " Add .. directory.
      call insert(l:candidates, l:parent . '..')
    endif
  endif

  let l:candidates_dir = []
  let l:candidates_file = []
  for l:file in l:candidates
    let l:dict = {
          \ 'word' : l:file,
          \ 'abbr' : l:file, 'source' : 'file',
          \ 'action__path' : unite#util#substitute_path_separator(fnamemodify(l:file, ':p')),
          \}
    let l:dict.action__directory = l:is_relative_path ?
          \ unite#util#substitute_path_separator(
          \    fnamemodify(unite#util#path2directory(l:file), ':.')) :
          \ unite#util#path2directory(l:dict.action__path)

    if isdirectory(l:file)
      if l:file !~ '^\%(/\|\a\+:/\)$'
        let l:dict.abbr .= '/'
      endif

      let l:dict.kind = 'directory'

      call add(l:candidates_dir, l:dict)
    else
      if !filereadable(l:file)
        " New file.
        let l:dict.abbr = '[new file]' . l:file
      endif

      let l:dict.kind = 'file'

      call add(l:candidates_file, l:dict)
    endif
  endfor

  return l:candidates_dir + l:candidates_file
endfunction"}}}

" Add custom action table."{{{
let s:cdable_action_file = {
      \ 'description' : 'open this directory by file source',
      \}

function! s:cdable_action_file.func(candidate)
  call unite#start([['file', a:candidate.action__directory]])
endfunction

call unite#custom_action('cdable', 'file', s:cdable_action_file)
unlet! s:cdable_action_file
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
