"=============================================================================
" FILE: directory.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 12 May 2012.
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

function! unite#sources#directory#define()"{{{
  return [s:source_directory, s:source_directory_new]
endfunction"}}}

let s:source_directory = {
      \ 'name' : 'directory',
      \ 'description' : 'candidates from directory list',
      \}

function! s:source_directory.change_candidates(args, context)"{{{
  if !has_key(a:context, 'source__cache') || a:context.is_redraw
        \ || a:context.is_invalidate
    " Initialize cache.
    let a:context.source__cache = {}
  endif

  let input_list = filter(split(a:context.input,
        \                     '\\\@<! ', 1), 'v:val !~ "!"')
  let input = empty(input_list) ? '' : input_list[0]
  let input = substitute(substitute(
        \ a:context.input, '\\ ', ' ', 'g'), '^\a\+:\zs\*/', '/', '')

  let path = join(a:args, ':')
  if path !=# '/' && path =~ '[\\/]$'
    " Chomp.
    let path = path[: -2]
  endif

  if input !~ '^\%(/\|\a\+:/\)' && path != '' && path != '/'
    let input = path . '/' .  input
  endif
  let is_relative_path = input !~ '^\%(/\|\a\+:/\)' && path == ''

  " Substitute *. -> .* .
  let input = substitute(input, '\*\.', '.*', 'g')

  if input !~ '\*' && unite#util#is_windows() && getftype(input) == 'link'
    " Resolve link.
    let input = resolve(input)
  endif

  " Glob by directory name.
  let input = substitute(input, '[^/.]*$', '', '')
  let glob = input . (input =~ '\*$' ? '' : '*')

  if !has_key(a:context.source__cache, glob)
    let files = sort(filter(copy(unite#util#glob(glob)),
          \ "isdirectory(v:val) && v:val !~
          \ '^\\%(/\\|\\a\\+:/\\)$\\|\\%(^\\|/\\)\\.$'"), 1)

    let a:context.source__cache[glob] = map(files,
          \ 'unite#sources#file#create_file_dict(v:val, is_relative_path)')
  endif

  let candidates = copy(a:context.source__cache[glob])

  " if !a:context.is_list_input
        " \ && input !~ '^\%(/\|\a\+:/\)$'
  if 0
    let parent = substitute(input, '[*\\]\|\.[^/]*$', '', 'g')

    if a:context.input =~ '\.$' && isdirectory(parent . '..')
      " Add .. directory.
      let file = unite#sources#file#create_file_dict(
            \              parent . '..', is_relative_path)
      let candidates = [file] + copy(candidates)
    endif
  endif

  return candidates
endfunction"}}}
function! s:source_directory.complete(args, context, arglead, cmdline, cursorpos)"{{{
  return map(filter(split(glob(a:arglead . '*'), '\n'),
        \ 'isdirectory(v:val)'), "v:val.'/'")
endfunction"}}}

let s:source_directory_new = {
      \ 'name' : 'directory/new',
      \ 'description' : 'directory candidates from input',
      \ }

function! s:source_directory_new.change_candidates(args, context)"{{{
  let input_list = filter(split(a:context.input,
        \                     '\\\@<! ', 1), 'v:val !~ "!"')
  let input = empty(input_list) ? '' : input_list[0]
  let input = substitute(substitute(
        \ a:context.input, '\\ ', ' ', 'g'), '^\a\+:\zs\*/', '/', '')
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

  if input !~ '\*' && unite#util#is_windows() && getftype(input) == 'link'
    " Resolve link.
    let input = resolve(input)
  endif

  " Glob by directory name.
  let input = substitute(input, '[^/.]*$', '', '')
  let glob = input . (input =~ '\*$' ? '' : '*')

  let is_relative_path = path !~ '^\%(/\|\a\+:/\)'

  let newfile = unite#util#expand(
        \ escape(substitute(a:context.input, '[*\\]', '', 'g'), ''))
  if filereadable(newfile) || isdirectory(newfile)
    return []
  endif

  " Return newfile candidate.
  return [unite#sources#file#create_file_dict(
        \ newfile, is_relative_path, 2)]
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
