"=============================================================================
" FILE: grep.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          Tomohiro Nishimura <tomohiro68 at gmail.com>
" Last Modified: 22 Apr 2012.
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
call unite#util#set_default('g:unite_source_grep_default_opts', '-iHn')
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
  call unite#start([
        \ ['grep', map(copy(a:candidates),
        \ 'string(substitute(v:val.action__path, "/$", "", "g"))'),
        \ ]], { 'no_quit' : 1 })
endfunction "}}}

let s:action_grep_directory = {
  \   'description': 'grep this directories',
  \   'is_quit': 1,
  \   'is_invalidate_cache': 1,
  \   'is_selectable': 1,
  \ }
function! s:action_grep_directory.func(candidates) "{{{
  call unite#start([
        \ ['grep', map(copy(a:candidates), 'string(v:val.action__directory)'),
        \ ]], { 'no_quit' : 1 })
endfunction "}}}
if executable(g:unite_source_grep_command) && unite#util#has_vimproc()
  call unite#custom_action('file,buffer', 'grep', s:action_grep_file)
  call unite#custom_action('file,buffer', 'grep_directory', s:action_grep_directory)
endif
" }}}

function! unite#sources#grep#define() "{{{
  return executable(g:unite_source_grep_command) && unite#util#has_vimproc() ?
        \ s:source : []
endfunction "}}}

let s:source = {
      \ 'name': 'grep',
      \ 'max_candidates': g:unite_source_grep_max_candidates,
      \ 'hooks' : {},
      \ 'syntax' : 'uniteSource__Grep',
      \ 'filters' : ['matcher_regexp', 'sorter_default', 'converter_default'],
      \ }

function! s:source.hooks.on_init(args, context) "{{{
  if type(get(a:args, 0, '')) == type([])
    let a:context.source__target = a:args[0]
    let targets = a:context.source__target
  else
    let default = get(a:args, 0, '')

    if default == ''
      let default = '.'
    endif

    if type(get(a:args, 0, '')) == type('')
          \ && get(a:args, 0, '') == ''
      let target = unite#util#substitute_path_separator(
            \ input('Target: ', default, 'file'))
    else
      let target = default
    endif

    if target == '%' || target == '#'
      let target = unite#util#escape_file_searching(bufname(target))
    elseif target ==# '$buffers'
      let target = join(map(filter(range(1, bufnr('$')),
            \ 'buflisted(v:val) && filereadable(bufname(v:val))'),
            \ 'unite#util#escape_file_searching(bufname(v:val))'))
    elseif target == '**'
      " Optimized.
      let target = '.'
    else
      " Escape filename.
      let target = escape(target, ' ')
    endif

    let a:context.source__target = [target]

    let targets = map(filter(split(target), 'v:val !~ "^-"'),
          \ 'substitute(v:val, "*\\+$", "", "")')
  endif

  let a:context.source__extra_opts = get(a:args, 1, '')

  let a:context.source__input = get(a:args, 2, '')
  if a:context.source__input == ''
    let a:context.source__input = input('Pattern: ')
  endif

  let a:context.source__directory =
        \ (len(targets) == 1) ?
        \ unite#util#substitute_path_separator(
        \  unite#util#expand(targets[0])) : ''
endfunction"}}}
function! s:source.hooks.on_syntax(args, context)"{{{
  syntax case ignore
  execute 'syntax match uniteSource__GrepPattern /:.*\zs'
        \ . substitute(a:context.source__input, '\([/\\]\)', '\\\1', 'g')
        \ . '/ contained containedin=uniteSource__Grep'
  execute 'highlight default link uniteSource__GrepPattern'
        \ g:unite_source_grep_search_word_highlight
endfunction"}}}
function! s:source.hooks.on_close(args, context) "{{{
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.waitpid()
  endif
endfunction "}}}

function! s:source.gather_candidates(args, context) "{{{
  if empty(a:context.source__target)
        \ || a:context.source__input == ''
    let a:context.is_async = 0
    call unite#print_message('[grep] Completed.')
    return []
  endif

  if a:context.is_redraw
    let a:context.is_async = 1
  endif

  let cmdline = printf('%s %s %s %s %s %s',
    \   g:unite_source_grep_command,
    \   g:unite_source_grep_default_opts,
    \   g:unite_source_grep_recursive_opt,
    \   a:context.source__extra_opts,
    \   string(a:context.source__input),
    \   join(map(a:context.source__target,
    \           "substitute(v:val, '/$', '', '')")),
    \)
  call unite#print_message('[grep] Command-line: ' . cmdline)
  let a:context.source__proc = vimproc#plineopen3(cmdline, 1)

  return []
endfunction "}}}

function! s:source.async_gather_candidates(args, context) "{{{
  let stderr = a:context.source__proc.stderr
  if !stderr.eof
    " Print error.
    let errors = filter(stderr.read_lines(-1, 300), "v:val !~ '^\\s*$'")
    if !empty(errors)
      call unite#print_error(map(errors, "'[grep] '.v:val"))
    endif
  endif

  let stdout = a:context.source__proc.stdout
  if stdout.eof
    " Disable async.
    call unite#print_message('[grep] Completed.')
    let a:context.is_async = 0
  endif

  let candidates = map(filter(map(stdout.read_lines(-1, 300),
        \ "iconv(v:val, 'char', &encoding)"),
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

  let _ = []
  for candidate in candidates
    let dict = {
          \   'kind': 'jump_list',
          \   'action__path': unite#util#substitute_path_separator(
          \                   fnamemodify(candidate[0][:1].candidate[1][0], ':p')),
          \   'action__line': candidate[1][1],
          \   'action__text': join(candidate[1][2:], ':'),
          \ }
    let dict.word = unite#util#substitute_path_separator(
          \ fnamemodify(dict.action__path, ':.')) . ': ' . dict.action__text

    call add(_, dict)
  endfor

  if isdirectory(a:context.source__directory)
    lcd `=cwd`
  endif

  return _
endfunction "}}}

function! s:source.complete(args, context, arglead, cmdline, cursorpos)"{{{
  return ['%', '#', '$buffers'] + unite#sources#file#complete_directory(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}

" vim: foldmethod=marker
