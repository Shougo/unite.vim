"=============================================================================
" FILE: grep.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          Tomohiro Nishimura <tomohiro68 at gmail.com>
" Last Modified: 07 Dec 2011.
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
call unite#util#set_default('g:unite_source_grep_search_word_highlight', 'Search')
call unite#util#set_default('g:unite_source_grep_ignore_pattern',
      \'\~$\|\.\%(o\|exe\|dll\|bak\|sw[po]\)$\|'.
      \'\%(^\|/\)\.\%(hg\|git\|bzr\|svn\)\%($\|/\)\|'.
      \'\%(^\|/\)tags\%(-\a*\)\?$')
"}}}

" Actions "{{{
let s:action_grep_file = {
  \   'description': 'grep this files',
  \   'is_quit': 1,
  \   'is_invalidate_cache': 1,
  \   'is_selectable': 1,
  \ }
function! s:action_grep_file.func(candidates) "{{{
  call unite#start([['grep', map(copy(a:candidates),
        \ 'substitute(v:val.action__path, "/$", "", "g")'),
        \ g:unite_source_grep_recursive_opt]], { 'no_quit' : 1 })
endfunction "}}}

let s:action_grep_directory = {
  \   'description': 'grep this directories',
  \   'is_quit': 1,
  \   'is_invalidate_cache': 1,
  \   'is_selectable': 1,
  \ }
function! s:action_grep_directory.func(candidates) "{{{
  call unite#start([['grep', map(copy(a:candidates), 'v:val.action__directory'),
        \ g:unite_source_grep_recursive_opt]], { 'no_quit' : 1 })
endfunction "}}}
if executable(g:unite_source_grep_command) && unite#util#has_vimproc()
  call unite#custom_action('file,buffer', 'grep', s:action_grep_file)
  call unite#custom_action('file,buffer', 'grep_directory', s:action_grep_directory)
endif
" }}}

function! unite#sources#grep#define() "{{{
  return executable(g:unite_source_grep_command) && unite#util#has_vimproc() ?
        \ s:grep_source : []
endfunction "}}}

let s:grep_source = {
      \ 'name': 'grep',
      \ 'max_candidates': g:unite_source_grep_max_candidates,
      \ 'hooks' : {},
      \ 'syntax' : 'uniteSource__Grep',
      \ 'filters' : ['matcher_regexp', 'sorter_default', 'converter_default'],
      \ }

function! s:grep_source.hooks.on_init(args, context) "{{{
  if type(get(a:args, 0, '')) == type([])
    let default = join(get(a:args, 0, ''))
  else
    let default = get(a:args, 0, '')
  endif
  if default == ''
    let default = '**'
  endif

  let target = input('Target: ', default, 'file')

  if target == '%' || target == '#'
    let target = unite#util#escape_file_searching(bufname(target))
  elseif target ==# '$buffers'
    let target = join(map(filter(range(1, bufnr('$')), 'buflisted(v:val) && filereadable(bufname(v:val))'),
          \ 'unite#util#escape_file_searching(bufname(v:val))'))
  elseif target == '**'
    " Optimized.
    let target = '* ' . g:unite_source_grep_recursive_opt
  endif

  let a:context.source__target = [target]

  let a:context.source__extra_opts = get(a:args, 1, '')

  let a:context.source__input = get(a:args, 2, '')
  if a:context.source__input == ''
    let a:context.source__input = input('Pattern: ')
  endif


  let targets = map(filter(split(target), 'v:val !~ "^-"'),
        \ 'substitute(v:val, "*\\+$", "", "")')
  let a:context.source__directory =
        \ (len(targets) == 1) ?
        \ unite#util#substitute_path_separator(expand(targets[0])) : ''
endfunction"}}}
function! s:grep_source.hooks.on_syntax(args, context)"{{{
  syntax case ignore
  execute 'syntax match uniteSource__GrepPattern /:.*\zs'
        \ . substitute(a:context.source__input, '\([/\\]\)', '\\\1', 'g')
        \ . '/ contained containedin=uniteSource__Grep'
  execute 'highlight default link uniteSource__GrepPattern ' . g:unite_source_grep_search_word_highlight
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
    let a:context.is_async = 1
  endif

  let cmdline = printf('%s %s %s ''%s'' %s',
    \   g:unite_source_grep_command,
    \   g:unite_source_grep_default_opts,
    \   a:context.source__extra_opts,
    \   substitute(a:context.source__input, "'", "''", 'g'),
    \   join(a:context.source__target),
    \)
  call unite#print_message('[grep] Command-line: ' . cmdline)
  let a:context.source__proc = vimproc#pgroup_open(cmdline)

  " Close handles.
  call a:context.source__proc.stdin.close()
  call a:context.source__proc.stderr.close()

  return []
endfunction "}}}

function! s:grep_source.async_gather_candidates(args, context) "{{{
  let stdout = a:context.source__proc.stdout
  if stdout.eof
    " Disable async.
    call unite#print_message('[grep] Completed.')
    let a:context.is_async = 0
  endif

  let candidates = map(filter(map(stdout.read_lines(-1, 300),
        \ 'iconv(v:val, &termencoding, &encoding)'),
    \  'v:val =~ "^.\\+:.\\+:.\\+$"'),
    \ '[v:val, split(v:val[2:], ":")]')

  if g:unite_source_grep_ignore_pattern != ''
    call filter(candidates, 'v:val[0][:1].v:val[1][0] !~ '
          \ . string(g:unite_source_grep_ignore_pattern))
  endif

  if isdirectory(a:context.source__directory)
    let cwd = getcwd()
    lcd `=a:context.source__directory`
  endif

  return map(candidates,
    \ '{
    \   "word": unite#util#substitute_path_separator(
    \                   fnamemodify(v:val[0], ":.")),
    \   "kind": "jump_list",
    \   "action__path": unite#util#substitute_path_separator(
    \                   fnamemodify(v:val[0][:1].v:val[1][0], ":p")),
    \   "action__line": v:val[1][1],
    \   "action__text": join(v:val[1][2:], ":"),
    \ }')

  if isdirectory(a:context.source__directory)
    lcd `=cwd`
  endif
endfunction "}}}

" vim: foldmethod=marker
