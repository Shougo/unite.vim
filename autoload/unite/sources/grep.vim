"=============================================================================
" FILE: grep.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          Tomohiro Nishimura <tomohiro68 at gmail.com>
" Last Modified: 08 Jan 2014.
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
call unite#util#set_default('g:unite_source_grep_ignore_pattern',
      \'\~$\|\.\%(o\|exe\|dll\|bak\|sw[po]\)$\|'.
      \'\%(^\|/\)\.\%(hg\|git\|bzr\|svn\)\%($\|/\)\|'.
      \'\%(^\|/\)tags\%(-\a*\)\?$')
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
      \ 'ignore_pattern' : g:unite_source_grep_ignore_pattern,
      \ 'variables' : {
      \      'command' : g:unite_source_grep_command,
      \      'default_opts' : g:unite_source_grep_default_opts,
      \      'recursive_opt' : g:unite_source_grep_recursive_opt,
      \      'search_word_highlight' : g:unite_source_grep_search_word_highlight,
      \   },
      \ }

function! s:source.hooks.on_init(args, context) "{{{
  if !unite#util#has_vimproc()
    call unite#print_source_error(
          \ 'vimproc is not installed.', s:source.name)
    return
  endif

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
          \ && a:context.input == ''
      let target = unite#util#substitute_path_separator(
            \ unite#util#input('Target: ', default, 'file'))
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
          \ 'substitute(v:val, "\\*\\+$", "", "")')
  endif

  let a:context.source__extra_opts = get(a:args, 1, '')

  let a:context.source__input = get(a:args, 2, a:context.input)
  if a:context.source__input == ''
    let a:context.source__input = unite#util#input('Pattern: ')
  endif

  let a:context.source__directory =
        \ (len(targets) == 1) ?
        \ unite#util#substitute_path_separator(
        \  unite#util#expand(targets[0])) : ''

  let a:context.source__ssh_path = ''
  if exists('b:vimfiler') &&
        \ exists('*vimfiler#get_current_vimfiler')
    if !empty(b:vimfiler)
      let vimfiler = b:vimfiler
    else
      let vimfiler = vimfiler#get_current_vimfiler()
    endif

    if get(vimfiler, 'source', '') ==# 'ssh'
      let [hostname, port, path] =
            \ unite#sources#ssh#parse_path(
            \  vimfiler.source.':'.vimfiler.current_dir)
      let a:context.source__ssh_path =
            \ printf('%s://%s:%s/', vimfiler.source, hostname, port)

      call map(a:context.source__target,
            \ "substitute(v:val, 'ssh://', '', '')")
    endif
  endif
endfunction"}}}
function! s:source.hooks.on_syntax(args, context) "{{{
  if !unite#util#has_vimproc()
    return
  endif

  syntax case ignore
  syntax region uniteSource__GrepLine
        \ start=' ' end='$'
        \ containedin=uniteSource__Grep
  syntax match uniteSource__GrepFile /^[^:]*/ contained
        \ containedin=uniteSource__GrepLine
        \ nextgroup=uniteSource__GrepSeparator
  syntax match uniteSource__GrepSeparator /:/ contained
        \ containedin=uniteSource__GrepLine
        \ nextgroup=uniteSource__GrepLineNr
  syntax match uniteSource__GrepLineNr /\d\+\ze:/ contained
        \ containedin=uniteSource__GrepLine
        \ nextgroup=uniteSource__GrepPattern
  execute 'syntax match uniteSource__GrepPattern /'
        \ . substitute(a:context.source__input, '\([/\\]\)', '\\\1', 'g')
        \ . '/ contained containedin=uniteSource__GrepLine'
  highlight default link uniteSource__GrepFile Directory
  highlight default link uniteSource__GrepLineNr LineNR
  execute 'highlight default link uniteSource__GrepPattern'
        \ unite#get_source_variables(a:context).search_word_highlight
endfunction"}}}
function! s:source.hooks.on_close(args, context) "{{{
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.kill()
  endif
endfunction "}}}
function! s:source.hooks.on_post_filter(args, context) "{{{
  for candidate in a:context.candidates
    let candidate.kind = [((a:context.source__ssh_path != '') ?
          \ 'file/ssh' : 'file'), 'jump_list']
    let candidate.action__directory =
          \ unite#util#path2directory(candidate.action__path)
    let candidate.action__col_pattern = a:context.source__input
    let candidate.is_multiline = 1
  endfor
endfunction"}}}

function! s:source.gather_candidates(args, context) "{{{
  let variables = unite#get_source_variables(a:context)
  if !executable(variables.command)
    call unite#print_source_message(printf(
          \ 'command "%s" is not executable.',
          \    variables.command), s:source.name)
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

  let cmdline = printf('%s %s %s %s %s %s',
    \   unite#util#substitute_path_separator(variables.command),
    \   variables.default_opts,
    \   variables.recursive_opt,
    \   a:context.source__extra_opts,
    \   string(a:context.source__input),
    \   join(map(a:context.source__target,
    \           "substitute(v:val, '/$', '', '')")),
    \)
  if a:context.source__ssh_path != ''
    " Use ssh command.
    let [hostname, port, path] =
          \ unite#sources#ssh#parse_path(a:context.source__ssh_path)
    let cmdline = substitute(substitute(
          \ g:unite_kind_file_ssh_command . ' ' . cmdline,
          \   '\<HOSTNAME\>', hostname, 'g'), '\<PORT\>', port, 'g')
  endif

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
  let variables = unite#get_source_variables(a:context)

  if !has_key(a:context, 'source__proc')
    let a:context.is_async = 0
    call unite#print_source_message('Completed.', s:source.name)
    return []
  endif

  let stderr = a:context.source__proc.stderr
  if !stderr.eof
    " Print error.
    let errors = filter(stderr.read_lines(-1, 100),
          \ "v:val !~ '^\\s*$'")
    if !empty(errors)
      call unite#print_source_error(errors, s:source.name)
    endif
  endif

  let stdout = a:context.source__proc.stdout
  if stdout.eof
    " Disable async.
    let a:context.is_async = 0
    call unite#print_source_message('Completed.', s:source.name)

    call a:context.source__proc.waitpid()
  endif

  let candidates = map(stdout.read_lines(-1, 100),
          \ "unite#util#iconv(v:val, g:unite_source_grep_encoding, &encoding)")
  if variables.default_opts =~ '^-[^-]*l'
        \ || a:context.source__extra_opts =~ '^-[^-]*l'
    let candidates = map(filter(candidates,
          \ 'v:val != ""'),
          \ '[v:val, [v:val[2:], 0]]')
  else
    let candidates = map(filter(candidates,
          \  'v:val =~ "^.\\+:.\\+$"'),
          \ '[v:val, split(v:val[2:], ":", 1)]')
  endif

  if a:context.source__ssh_path != ''
    " Use ssh command.
    let [hostname, port, path] = unite#sources#ssh#parse_path(
          \     a:context.source__ssh_path)
  endif

  let _ = []
  for candidate in candidates
    if len(candidate[1]) <= 1 || candidate[1][1] !~ '^\d\+$'
      let dict = {
            \   'action__path' : a:context.source__target[0],
            \ }
      if len(candidate[1]) <= 1
        let dict.action__line = candidate[0][:1][0]
        let dict.action__text = candidate[1][0]
      else
        let dict.action__line = candidate[0][:1].candidate[1][0]
        let dict.action__text = join(candidate[1][1:], ':')
      endif
    else
      let dict = {
            \   'action__path' : candidate[0][:1].candidate[1][0],
            \   'action__line' : candidate[1][1],
            \   'action__text' : join(candidate[1][2:], ':'),
            \ }
    endif

    if a:context.source__ssh_path != ''
      let dict.action__path =
            \ a:context.source__ssh_path . dict.action__path
    else
      let dict.action__path =
            \ unite#util#substitute_path_separator(
            \   fnamemodify(dict.action__path, ':p'))
    endif

    let dict.word = printf('%s:%s:%s',
          \  unite#util#substitute_path_separator(
          \     fnamemodify(dict.action__path, ':.')),
          \ dict.action__line, dict.action__text)

    call add(_, dict)
  endfor

  return _
endfunction "}}}

function! s:source.complete(args, context, arglead, cmdline, cursorpos) "{{{
  return ['%', '#', '$buffers'] + unite#sources#file#complete_directory(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}

" vim: foldmethod=marker
