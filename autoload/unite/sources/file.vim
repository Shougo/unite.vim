"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 05 Aug 2011.
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
  if !has_key(a:context, 'source__cache') || a:context.is_redraw
        \ || a:context.is_invalidate
    " Initialize cache.
    let a:context.source__cache = {}
  endif

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
  let l:glob = l:input . (l:input =~ '\*$' ? '' : '*')
  if !has_key(a:context.source__cache, l:glob)
    let l:files = split(unite#util#substitute_path_separator(
          \ glob(l:glob)), '\n')

    if g:unite_source_file_ignore_pattern != ''
      call filter(l:files, 'v:val !~ ' . string(g:unite_source_file_ignore_pattern))
    endif

    let a:context.source__cache[l:glob] =
          \ map(sort(l:files, 's:compare_file'), 's:create_dict(v:val, l:is_relative_path)')
  endif

  let l:candidates = a:context.source__cache[l:glob]

  if a:context.input != ''
    let l:newfile = substitute(a:context.input, '[*\\]', '', 'g')
    if !filereadable(l:newfile) && !isdirectory(l:newfile)
      " Add newfile candidate.
      let l:candidates = copy(l:candidates) +
            \ [s:create_dict(l:newfile, l:is_relative_path)]
    endif

    if l:input !~ '^\%(/\|\a\+:/\)$'
      let l:parent = substitute(l:input, '[*\\]\|\.[^/]*$', '', 'g')

      if a:context.input =~ '\.$' && isdirectory(l:parent . '..')
        " Add .. directory.
        let l:candidates = [s:create_dict(l:parent . '..', l:is_relative_path)]
              \ + copy(l:candidates)
      endif
    endif
  endif

  return l:candidates
endfunction"}}}
function! s:create_dict(file, is_relative_path)"{{{
  let l:dict = {
        \ 'word' : a:file,
        \ 'abbr' : a:file, 'source' : 'file',
        \ 'action__path' : unite#util#substitute_path_separator(fnamemodify(a:file, ':p')),
        \}
  let l:dict.action__directory = a:is_relative_path ?
        \ unite#util#substitute_path_separator(
        \    fnamemodify(unite#util#path2directory(a:file), ':.')) :
        \ unite#util#path2directory(l:dict.action__path)

  if isdirectory(a:file)
    if a:file !~ '^\%(/\|\a\+:/\)$'
      let l:dict.abbr .= '/'
    endif

    let l:dict.kind = 'directory'
  else
    if !filereadable(a:file)
      " New file.
      let l:dict.abbr = '[new file]' . a:file
    endif

    let l:dict.kind = 'file'
  endif

  return l:dict
endfunction"}}}
function! s:compare_file(a, b)"{{{
  return isdirectory(a:b) - isdirectory(a:a)
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
