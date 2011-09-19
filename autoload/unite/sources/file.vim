"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 19 Sep 2011.
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

  let input_list = filter(split(a:context.input,
        \                     '\\\@<! ', 1), 'v:val !~ "!"')
  let input = empty(input_list) ? '' : input_list[0]
  let input = substitute(substitute(a:context.input, '\\ ', ' ', 'g'), '^\a\+:\zs\*/', '/', '')

  let path = get(a:args, 0, '')
  if path !=# '/' && path =~ '[\\/]$'
    " Chomp.
    let path = path[: -2]
  endif

  if path == '/'
    let input = path . input
  elseif input !~ '^\%(/\|\a\+:/\)' && path != '' && path != '/'
    let input = path . '/' .  input
  endif
  let is_relative_path = input !~ '^\%(/\|\a\+:/\)' && path == ''

  " Substitute *. -> .* .
  let input = substitute(input, '\*\.', '.*', 'g')

  if input !~ '\*' && unite#is_win() && getftype(input) == 'link'
    " Resolve link.
    let input = resolve(input)
  endif

  " Glob by directory name.
  let input = substitute(input, '[^/.]*$', '', '')
  let glob = input . (input =~ '\*$' ? '' : '*')
  if !has_key(a:context.source__cache, glob)
    let files = split(unite#util#substitute_path_separator(
          \ glob(glob)), '\n')

    if g:unite_source_file_ignore_pattern != ''
      call filter(files, 'v:val !~ ' . string(g:unite_source_file_ignore_pattern))
    endif

    let files = sort(filter(copy(files), 'isdirectory(v:val)'), 1) +
          \ sort(filter(copy(files), '!isdirectory(v:val)'), 1)

    let a:context.source__cache[glob] =
          \ map(files, 'unite#sources#file#create_file_dict(v:val, is_relative_path)')
  endif

  let candidates = a:context.source__cache[glob]

  if a:context.input != ''
    let newfile = substitute(a:context.input, '[*\\]', '', 'g')
    if !filereadable(newfile) && !isdirectory(newfile)
      " Add newfile candidate.
      let candidates = copy(candidates) +
            \ [unite#sources#file#create_file_dict(newfile, is_relative_path)]
    endif

    if input !~ '^\%(/\|\a\+:/\)$'
      let parent = substitute(input, '[*\\]\|\.[^/]*$', '', 'g')

      if a:context.input =~ '\.$' && isdirectory(parent . '..')
        " Add .. directory.
        let candidates = [unite#sources#file#create_file_dict(
              \              parent . '..', is_relative_path)]
              \ + copy(candidates)
      endif
    endif
  endif

  return candidates
endfunction"}}}
function! s:source.vimfiler_check_filetype(args, context)"{{{
  let path = expand(get(a:args, 0, ''))

  if isdirectory(path)
    let type = 'directory'
    let info = path
  elseif filereadable(path)
    let type = 'file'
    let info = [readfile(path),
          \ unite#sources#file#create_file_dict(path, 0)]
  else
    return []
  endif

  return [type, info]
endfunction"}}}
function! s:source.vimfiler_gather_candidates(args, context)"{{{
  let path = expand(get(a:args, 0, ''))

  if isdirectory(path)
    let candidates = self.change_candidates(a:args, a:context)

    " Add doted files.
    let context = deepcopy(a:context)
    let context.input .= '.'
    let candidates += filter(self.change_candidates(a:args, context),
          \ 'v:val.word !~ "/\.\.$"')
  elseif filereadable(path)
    let candidates = [ unite#sources#file#create_file_dict(path, 0) ]
  else
    return []
  endif

  let old_dir = getcwd()
  if path !=# old_dir
        \ && isdirectory(path)
    lcd `=path`
  endif

  let exts = unite#util#is_win() ?
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
function! s:source.vimfiler_dummy_candidates(args, context)"{{{
  let path = expand(get(a:args, 0, ''))

  if path == ''
    return []
  endif

  let old_dir = getcwd()
  if path !=# old_dir
        \ && isdirectory(path)
    lcd `=path`
  endif

  let exts = unite#util#is_win() ?
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
function! s:source.vimfiler_complete(args, context, arglead, cmdline, cursorpos)"{{{
  return split(glob(a:arglead . '*'), '\n')
endfunction"}}}

function! unite#sources#file#create_file_dict(file, is_relative_path)"{{{
  let dict = {
        \ 'word' : a:file, 'abbr' : a:file,
        \ 'action__path' : unite#util#substitute_path_separator(
        \ fnamemodify(a:file, ':p')),
        \}
  let dict.action__directory = a:is_relative_path ?
        \ unite#util#substitute_path_separator(
        \    fnamemodify(unite#util#path2directory(a:file), ':.')) :
        \ unite#util#path2directory(dict.action__path)

  if isdirectory(a:file)
    if a:file !~ '^\%(/\|\a\+:/\)$'
      let dict.abbr .= '/'
    endif

    let dict.kind = 'directory'
  else
    if !filereadable(a:file)
      " New file.
      let dict.abbr = '[new file]' . a:file
    endif

    let dict.kind = 'file'
  endif

  return dict
endfunction"}}}
function! unite#sources#file#create_vimfiler_dict(candidate, exts)"{{{
  let a:candidate.vimfiler__filename =
        \ unite#util#substitute_path_separator(
        \       fnamemodify(a:candidate.word, ':t'))
  let a:candidate.vimfiler__abbr =
        \ unite#util#substitute_path_separator(
        \       fnamemodify(a:candidate.action__path, ':.'))
  if getcwd() == '/'
    " Remove /.
    let a:candidate.vimfiler__abbr = a:candidate.vimfiler__abbr[1:]
  endif

  let a:candidate.vimfiler__is_directory =
        \ isdirectory(a:candidate.action__path)
  let a:candidate.vimfiler__is_executable =
        \ unite#util#is_win() ?
        \ ('.'.fnamemodify(a:candidate.vimfiler__filename, ':e') =~? a:exts) :
        \ executable(a:candidate.action__path)
  let a:candidate.vimfiler__filesize = getfsize(a:candidate.action__path)
  let a:candidate.vimfiler__filetime = getftime(a:candidate.action__path)
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
