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
call unite#util#set_default('g:unite_source_grep_max_candidates', 100)
call unite#util#set_default('g:unite_source_grep_search_word_highlight', 'Search')
call unite#util#set_default('g:unite_source_grep_encoding', 'char')
"}}}

function! unite#sources#grep#define() "{{{
  return s:source
endfunction "}}}

let s:source = {
      \ 'name': 'grep',
      \ 'max_candidates': g:unite_source_grep_max_candidates,
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

function! s:source.hooks.on_init(args, context) "{{{
  if !unite#util#has_vimproc()
    call unite#print_source_error(
          \ 'vimproc is not installed.', s:source.name)
    return
  endif

  let args = unite#helper#parse_project_bang(a:args)

  let default = get(args, 0, '')

  if default == ''
    let default = '.'
  endif

  if get(args, 0, '') == '' && a:context.input == ''
    let target = unite#util#substitute_path_separator(
          \ unite#util#input('Target: ', default, 'file'))
    if target == ''
      let a:context.source__target = []
      let a:context.source__input = ''
      return
    endif
  else
    let target = default
  endif

  let targets = split(target, "\n")
  if target == '%' || target == '#'
    let targets = [bufname(target)]
  elseif target ==# '$buffers'
    let targets = map(filter(range(1, bufnr('$')),
          \ 'buflisted(v:val) && filereadable(bufname(v:val))'),
          \ 'bufname(v:val)')
  elseif target == '**'
    " Optimized.
    let targets = ['.']
  endif

  if target != '' && target != '.'
    call unite#print_source_message('Target: ' . target, s:source.name)
  endif

  let a:context.source__target =
        \ map(targets, 'substitute(v:val, "\\*\\+$", "", "")')

  let a:context.source__extra_opts = get(args, 1, '')

  let a:context.source__input = get(args, 2, a:context.input)
  if a:context.source__input == '' || a:context.unite__is_restart
    let a:context.source__input = unite#util#input('Pattern: ',
          \ a:context.source__input)
  endif

  call unite#print_source_message('Pattern: '
        \ . a:context.source__input, s:source.name)

  let a:context.source__directory =
        \ (len(a:context.source__target) == 1) ?
        \ unite#util#substitute_path_separator(
        \  unite#util#expand(a:context.source__target[0])) : ''
endfunction"}}}
function! s:source.hooks.on_syntax(args, context) "{{{
  if !unite#util#has_vimproc()
    return
  endif

  syntax case ignore
  syntax match uniteSource__GrepFile /[^:]*: / contained
        \ containedin=uniteSource__Grep
        \ nextgroup=uniteSource__GrepLineNR
  syntax match uniteSource__GrepLineNR /\d\+:/ contained
        \ containedin=uniteSource__Grep
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
function! s:source.hooks.on_close(args, context) "{{{
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.kill()
  endif
endfunction "}}}
function! s:source.hooks.on_post_filter(args, context) "{{{
  for candidate in a:context.candidates
    let candidate.kind = ['file', 'jump_list']
    let candidate.action__col_pattern = a:context.source__input
    let candidate.is_multiline = 1
    let candidate.action__line = candidate.source__info[1]
    let candidate.action__text = candidate.source__info[2]
  endfor
endfunction"}}}

function! s:source.gather_candidates(args, context) "{{{
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

  if empty(a:context.source__target)
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
    \   join(map(copy(a:context.source__target),
    \           "unite#util#escape_shell(substitute(v:val, '/$', '', ''))"))
    \)

  call unite#print_source_message('Command-line: ' . cmdline, s:source.name)

  let save_term = $TERM
  try
    " Disable colors.
    let $TERM = 'dumb'

    let a:context.source__proc = vimproc#plineopen3(
          \ vimproc#util#iconv(cmdline, &encoding, 'char'), 1)
  finally
    let $TERM = save_term
  endtry

  return self.async_gather_candidates(a:args, a:context)
endfunction "}}}

function! s:source.async_gather_candidates(args, context) "{{{
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

  let candidates = map(unite#util#read_lines(stdout, 1000),
          \ "unite#util#iconv(v:val, g:unite_source_grep_encoding, &encoding)")
  if default_opts =~ '^-[^-]*l'
        \ || a:context.source__extra_opts =~ '^-[^-]*l'
    let candidates = map(filter(candidates,
          \ 'v:val != ""'),
          \ '[v:val, [v:val[2:], 0]]')
  else
    let candidates = map(filter(candidates,
          \  'v:val =~ "^.\\+:.\\+$"'),
          \ '[v:val, split(v:val[2:], ":", 1)]')
  endif

  let _ = []
  for candidate in candidates
    if len(candidate[1]) <= 1 || candidate[1][1] !~ '^\d\+$'
      let path = a:context.source__target[0]
      if len(candidate[1]) <= 1
        let line = candidate[0][:1][0]
        let text = candidate[1][0]
      else
        let line = candidate[0][:1].candidate[1][0]
        let text = join(candidate[1][1:], ':')
      endif
    else
      let path = candidate[0][:1].candidate[1][0]
      let line = candidate[1][1]
      let text = join(candidate[1][2:], ':')
    endif

    call add(_, {
          \ 'word' : printf('%s: %s: %s', path, line, text),
          \ 'action__path' :
          \ unite#util#substitute_path_separator(
          \   fnamemodify(path, ':p')),
          \ 'source__info' : [path, line, text]
          \ })
  endfor

  return _
endfunction "}}}

function! s:source.complete(args, context, arglead, cmdline, cursorpos) "{{{
  return ['%', '#', '$buffers'] + unite#sources#file#complete_directory(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}

" vim: foldmethod=marker
