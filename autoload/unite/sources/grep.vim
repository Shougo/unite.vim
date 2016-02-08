"=============================================================================
" FILE: grep.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          Tomohiro Nishimura <tomohiro68 at gmail.com>
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
" Set from grepprg.
call unite#util#set_default(
      \ 'g:unite_source_grep_command', 'grep')
call unite#util#set_default(
      \ 'g:unite_source_grep_default_opts', '-inH')

call unite#util#set_default('g:unite_source_grep_recursive_opt', '-r')
call unite#util#set_default('g:unite_source_grep_search_word_highlight', 'Search')
call unite#util#set_default('g:unite_source_grep_encoding', 'char')
"}}}

function! unite#sources#grep#define() abort "{{{
  return s:source
endfunction "}}}

let s:source = {
      \ 'name': 'grep',
      \ 'max_candidates': 100,
      \ 'hooks' : {},
      \ 'syntax' : 'uniteSource__Grep',
      \ 'matchers' : 'matcher_regexp',
      \ 'sorters' : 'sorter_nothing',
      \ 'ignore_globs' : [
      \         '*~', '*.o', '*.exe', '*.bak',
      \         'DS_Store', '*.pyc', '*.sw[po]', '*.class',
      \         '.hg/**', '.git/**', '.bzr/**', '.svn/**',
      \         'tags', 'tags-*'
      \ ],
      \ }

function! s:source.hooks.on_init(args, context) abort "{{{
  if !unite#util#has_vimproc()
    call unite#print_source_error(
          \ 'vimproc is not installed.', s:source.name)
    return
  endif

  let target = get(a:args, 0, '')

  if target ==# ''
    let target = isdirectory(a:context.path) ?
      \ a:context.path :
      \ unite#util#input('Target: ', '.', 'file')
  endif

  if target ==# ''
    let a:context.source__targets = []
    let a:context.source__input = ''
    return
  endif

  let targets = split(target, "\n")
  if target ==# '%' || target ==# '#'
    let targets = [bufname(target)]
  elseif target ==# '$buffers'
    let targets = map(filter(range(1, bufnr('$')),
          \ 'buflisted(v:val) && filereadable(bufname(v:val))'),
          \ 'bufname(v:val)')
  elseif target ==# '**'
    " Optimized.
    let targets = ['.']
  endif

  let targets = map(targets, 'substitute(v:val, "\\*\\+$", "", "")')
  let a:context.source__targets =
        \ map(targets, 'unite#helper#parse_source_path(v:val)')

  let a:context.source__extra_opts = get(a:args, 1, '')

  let a:context.source__input = get(a:args, 2, a:context.input)
  if a:context.source__input == '' || a:context.unite__is_restart
    let a:context.source__input = unite#util#input('Pattern: ',
          \ a:context.source__input,
          \ 'customlist,unite#helper#complete_search_history')
  endif

  call unite#print_source_message('Pattern: '
        \ . a:context.source__input, s:source.name)

  let a:context.source__directory =
        \ (len(a:context.source__targets) == 1) ?
        \ unite#util#substitute_path_separator(
        \  unite#util#expand(a:context.source__targets[0])) : ''
endfunction"}}}
function! s:source.hooks.on_syntax(args, context) abort "{{{
  if !unite#util#has_vimproc()
    return
  endif

  syntax case ignore
  syntax match uniteSource__GrepHeader /[^:]*: \d\+: \(\d\+: \)\?/ contained
        \ containedin=uniteSource__Grep
  syntax match uniteSource__GrepFile /[^:]*: / contained
        \ containedin=uniteSource__GrepHeader
        \ nextgroup=uniteSource__GrepLineNR
  syntax match uniteSource__GrepLineNR /\d\+: / contained
        \ containedin=uniteSource__GrepHeader
        \ nextgroup=uniteSource__GrepPattern
  execute 'syntax match uniteSource__GrepPattern /'
        \ . substitute(a:context.source__input, '\([/\\]\)', '\\\1', 'g')
        \ . '/ contained containedin=uniteSource__Grep'
  syntax match uniteSource__GrepSeparator /:/ contained conceal
        \ containedin=uniteSource__GrepFile,uniteSource__GrepLineNR
  highlight default link uniteSource__GrepFile Comment
  highlight default link uniteSource__GrepLineNr LineNR
  execute 'highlight default link uniteSource__GrepPattern'
        \ get(a:context, 'custom_grep_search_word_highlight',
        \ g:unite_source_grep_search_word_highlight)
endfunction"}}}
function! s:source.hooks.on_close(args, context) abort "{{{
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.kill()
  endif
endfunction "}}}
function! s:source.hooks.on_post_filter(args, context) abort "{{{
  for candidate in a:context.candidates
    let candidate.kind = ['file', 'jump_list']
    let candidate.action__col_pattern = a:context.source__input
    let candidate.is_multiline = 1
    let candidate.action__line = candidate.source__info[1]
    let candidate.action__text = candidate.source__info[2]
  endfor
endfunction"}}}

function! s:source.gather_candidates(args, context) abort "{{{
  let command = get(a:context, 'custom_grep_command',
        \ g:unite_source_grep_command)
  let default_opts = get(a:context, 'custom_grep_default_opts',
        \ g:unite_source_grep_default_opts)
  let recursive_opt = get(a:context, 'custom_grep_recursive_opt',
        \ g:unite_source_grep_recursive_opt)

  if !executable(command)
    call unite#print_source_message(printf(
          \ 'command "%s" is not executable.', command), s:source.name)
    let a:context.is_async = 0
    return []
  endif

  if !unite#util#has_vimproc()
    call unite#print_source_message(
          \ 'vimproc plugin is not installed.', self.name)
    let a:context.is_async = 0
    return []
  endif

  if empty(a:context.source__targets)
        \ || a:context.source__input == ''
    call unite#print_source_message('Canceled.', s:source.name)
    let a:context.is_async = 0
    return []
  endif

  if a:context.is_redraw
    let a:context.is_async = 1
  endif

  let cmdline = printf('"%s" %s %s %s %s %s',
    \   unite#util#substitute_path_separator(command),
    \   default_opts,
    \   recursive_opt,
    \   a:context.source__extra_opts,
    \   string(a:context.source__input),
    \   unite#helper#join_targets(a:context.source__targets)
    \)

  call unite#add_source_message('Command-line: ' . cmdline, s:source.name)

  let save_term = $TERM
  try
    " Disable colors.
    let $TERM = 'dumb'

    let a:context.source__proc = vimproc#plineopen3(
          \ vimproc#util#iconv(cmdline, &encoding,
          \ g:unite_source_grep_encoding),
          \ unite#helper#is_pty(command))
  finally
    let $TERM = save_term
  endtry

  return self.async_gather_candidates(a:args, a:context)
endfunction "}}}

function! s:source.async_gather_candidates(args, context) abort "{{{
  let default_opts = get(a:context, 'custom_grep_default_opts',
        \ g:unite_source_grep_default_opts)

  if !has_key(a:context, 'source__proc')
    let a:context.is_async = 0
    return []
  endif

  let stderr = a:context.source__proc.stderr
  if !stderr.eof
    " Print error.
    let errors = filter(unite#util#read_lines(stderr, 200),
          \ "v:val !~ '^\\s*$'")
    if !empty(errors)
      call unite#print_source_error(errors, s:source.name)
    endif
  endif

  let stdout = a:context.source__proc.stdout
  if stdout.eof
    " Disable async.
    let a:context.is_async = 0
    call a:context.source__proc.waitpid()
  endif

  let lines = map(unite#util#read_lines(stdout, 1000),
          \ "unite#util#iconv(v:val, g:unite_source_grep_encoding, &encoding)")
  if default_opts =~ '^-[^-]*l'
        \ || a:context.source__extra_opts =~ '^-[^-]*l'
    let lines = map(filter(lines, 'v:val != ""'),
          \ '[v:val, [v:val[2:], 0]]')
  else
    let lines = map(filter(lines, 'v:val =~ "^.\\+:.\\+$"'),
          \ '[v:val, split(v:val[2:], ":", 1)]')
  endif

  let candidates = []
  for [line, fields] in lines
    let col = 0

    if len(fields) <= 1 || fields[1] !~ '^\d\+$'
      let path = a:context.source__targets[0]
      if len(fields) <= 1
        let linenr = line[:1][0]
        let text = fields[0]
      else
        let linenr = line[:1] . fields[0]
        let text = join(fields[1:], ':')
      endif
    else
      let path = line[:1] . fields[0]
      let linenr = fields[1]
      let text = join(fields[2:], ':')
      if text =~ '^\d\+:'
        let col = matchstr(text, '^\d\+')
        let text = text[len(col)+1 :]
      endif
    endif

    if path ==# '.'
      call unite#print_source_error(
            \ 'Your grep configuration is wrong.'
            \ . ' Please check ":help unite-source-grep" example.',
            \ s:source.name)
      break
    endif

    call add(candidates, {
          \ 'word' : printf('%s: %s: %s', path,
          \                 linenr . (col != 0 ? ': '.col : ''), text),
          \ 'action__path' :
          \ unite#util#substitute_path_separator(
          \   fnamemodify(path, ':p')),
          \ 'action__col' : col,
          \ 'source__info' : [path, linenr, text]
          \ })
  endfor

  return candidates
endfunction "}}}

function! s:source.complete(args, context, arglead, cmdline, cursorpos) abort "{{{
  return ['%', '#', '$buffers'] + unite#sources#file#complete_directory(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}

" vim: foldmethod=marker
