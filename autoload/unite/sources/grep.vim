"=============================================================================
" FILE: grep.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          Tomohiro Nishimura <tomohiro68 at gmail.com>
" Last Modified: 10 Aug 2011.
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
call unite#util#set_default('g:unite_source_grep_command', 'grep')
call unite#util#set_default('g:unite_source_grep_default_opts', '-Hn')
call unite#util#set_default('g:unite_source_grep_recursive_opt', '-R')
call unite#util#set_default('g:unite_source_grep_max_candidates', 100)
"}}}

" Actions "{{{
let s:action_grep_file = {
  \   'description': 'grep this files',
  \   'is_quit': 1,
  \   'is_invalidate_cache': 1,
  \   'is_selectable': 1,
  \ }
function! s:action_grep_file.func(candidates) "{{{
  call unite#start([['grep', map(copy(a:candidates), 'v:val.action__path')]])
endfunction "}}}

let s:action_grep_directory = {
  \   'description': 'grep this directories',
  \   'is_quit': 1,
  \   'is_invalidate_cache': 1,
  \   'is_selectable': 1,
  \ }
function! s:action_grep_directory.func(candidates) "{{{
  call unite#start([['grep', map(copy(a:candidates), 'v:val.action__directory'), g:unite_source_grep_recursive_opt]])
endfunction "}}}
if executable(g:unite_source_grep_command) && unite#util#has_vimproc()
  call unite#custom_action('file,buffer', 'grep', s:action_grep_file)
  call unite#custom_action('file,buffer', 'grep_directory', s:action_grep_directory)
endif
" }}}

function! unite#sources#grep#define() "{{{
  if !exists('*unite#version') || unite#version() <= 100
    echoerr 'Your unite.vim is too old.'
    echoerr 'Please install unite.vim Ver.1.1 or above.'
    return []
  endif

  return executable(g:unite_source_grep_command) && unite#util#has_vimproc() ? s:grep_source : []
endfunction "}}}

let s:grep_source = {
      \ 'name': 'grep',
      \ 'max_candidates': g:unite_source_grep_max_candidates,
      \ 'hooks' : {},
      \ 'syntax' : 'uniteSource__Grep',
      \ 'filters' : ['matcher_regexp', 'sorter_default', 'converter_default'],
      \ }

function! s:grep_source.hooks.on_init(args, context) "{{{
  let l:target  = get(a:args, 0, '')
  if type(l:target) != type([])
    if l:target == ''
      let l:target = input('Target: ', '**', 'file')
    endif

    if l:target == '%' || l:target == '#'
      let l:target = unite#util#escape_file_searching(bufname(l:target))
    elseif l:target ==# '$buffers'
      let l:target = join(map(filter(range(1, bufnr('$')), 'buflisted(v:val)'),
            \ 'unite#util#escape_file_searching(bufname(v:val))'))
    elseif l:target == '**'
      " Optimized.
      let l:target = '* ' . g:unite_source_grep_recursive_opt
    endif

    let a:context.source__target = [l:target]
  else
    let a:context.source__target = l:target
  endif

  let a:context.source__extra_opts = get(a:args, 1, '')

  let a:context.source__input = get(a:args, 2, '')
  if a:context.source__input == ''
    let a:context.source__input = input('Pattern: ')
  endif

  call unite#print_message('[grep] Target: ' . join(a:context.source__target))
  call unite#print_message('[grep] Pattern: ' . a:context.source__input)
endfunction"}}}
function! s:grep_source.hooks.on_syntax(args, context)"{{{
  syntax case ignore
  execute 'syntax match uniteSource__GrepPattern /:.*\zs'
        \ . substitute(a:context.source__input, '\([/\\]\)', '\\\1', 'g')
        \ . '/ contained containedin=uniteSource__Grep'
  highlight default link uniteSource__GrepPattern Search
endfunction"}}}
function! s:grep_source.hooks.on_close(args, context) "{{{
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.waitpid()
  endif
endfunction "}}}

function! s:grep_source.gather_candidates(args, context) "{{{
  if empty(a:context.source__target)
        \ || a:context.source__input == ''
    let a:context.is_async = 0
    call unite#print_message('[grep] Completed.')
    return []
  endif

  if a:context.is_redraw
    call unite#print_message('[grep] Target: ' . join(a:context.source__target))
    call unite#print_message('[grep] Pattern: ' . a:context.source__input)
    let a:context.is_async = 1
  endif

  let l:cmdline = printf('%s %s ''%s'' %s %s',
    \   g:unite_source_grep_command,
    \   g:unite_source_grep_default_opts,
    \   substitute(a:context.source__input, "'", "''", 'g'),
    \   join(a:context.source__target),
    \   a:context.source__extra_opts)
  call unite#print_message('[grep] Command-line: ' . l:cmdline)
  let a:context.source__proc = vimproc#pgroup_open(l:cmdline)
  " let a:context.source__proc = vimproc#popen3(l:cmdline)

  " Close handles.
  call a:context.source__proc.stdin.close()
  call a:context.source__proc.stderr.close()

  return []
endfunction "}}}

function! s:grep_source.async_gather_candidates(args, context) "{{{
  let l:stdout = a:context.source__proc.stdout
  if l:stdout.eof
    " Disable async.
    call unite#print_message('[grep] Completed.')
    let a:context.is_async = 0
  endif

  let l:candidates = map(filter(map(l:stdout.read_lines(-1, 300),
        \ 'iconv(v:val, &termencoding, &encoding)'),
    \  'v:val =~ "^.\\+:.\\+:.\\+$"'),
    \ '[v:val, split(v:val[2:], ":")]')

  return map(l:candidates,
    \ '{
    \   "word": v:val[0],
    \   "kind": "jump_list",
    \   "action__path": unite#util#substitute_path_separator(
    \                   fnamemodify(v:val[0][:1].v:val[1][0], ":p")),
    \   "action__line": v:val[1][1],
    \   "action__text": join(v:val[1][2:], ":"),
    \ }')
endfunction "}}}

" vim: foldmethod=marker
