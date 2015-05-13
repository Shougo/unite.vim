"=============================================================================
" FILE: vimgrep.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
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
call unite#util#set_default(
      \ 'g:unite_source_vimgrep_search_word_highlight', 'Search')
"}}}

function! unite#sources#vimgrep#define() "{{{
  return s:source
endfunction "}}}

let s:source = {
      \ 'name': 'vimgrep',
      \ 'max_candidates': 100,
      \ 'hooks' : {},
      \ 'syntax' : 'uniteSource__Vimgrep',
      \ 'matchers' : 'matcher_regexp',
      \ 'ignore_globs' : [
      \         '*~', '*.o', '*.exe', '*.bak',
      \         'DS_Store', '*.pyc', '*.sw[po]', '*.class',
      \         '.hg/**', '.git/**', '.bzr/**', '.svn/**',
      \ ],
      \ }

function! s:source.hooks.on_init(args, context) "{{{
  let args = unite#helper#parse_project_args(a:args)

  let target = get(args, 0, '')
  if target == ''
    let target = unite#helper#parse_source_path(
      \ unite#util#substitute_path_separator(
        \ unite#util#input('Target: ', '**', 'file')))
  endif

  if target == '%'
    let target = unite#util#substitute_path_separator(
          \ bufname(unite#get_current_unite().prev_bufnr))
  endif

  let a:context.source__targets = split(target, "\n")

  let a:context.source__input = get(args, 1, '')
  if a:context.source__input == '' || a:context.unite__is_restart
    let a:context.source__input = unite#util#input('Pattern: ',
          \ a:context.source__input)
  endif

  let a:context.source__directory =
        \ (len(a:context.source__targets) == 1) ?
        \ unite#util#substitute_path_separator(
        \  unite#util#expand(a:context.source__targets[0])) : ''
endfunction"}}}
function! s:source.hooks.on_syntax(args, context) "{{{
  syntax case ignore
  syntax region uniteSource__VimgrepLine
        \ start=' ' end='$'
        \ containedin=uniteSource__Vimgrep
  syntax match uniteSource__VimgrepFile /^[^:]*/ contained
        \ containedin=uniteSource__VimgrepLine
        \ nextgroup=uniteSource__VimgrepSeparator
  syntax match uniteSource__VimgrepSeparator /:/ contained
        \ containedin=uniteSource__VimgrepLine
        \ nextgroup=uniteSource__VimgrepLineNr
  syntax match uniteSource__VimgrepLineNr /\d\+\ze:/ contained
        \ containedin=uniteSource__VimgrepLine
        \ nextgroup=uniteSource__VimgrepPattern
  execute 'syntax match uniteSource__VimgrepPattern /'
        \ . substitute(a:context.source__input, '\([/\\]\)', '\\\1', 'g')
        \ . '/ contained containedin=uniteSource__VimgrepLine'
  highlight default link uniteSource__VimgrepFile Directory
  highlight default link uniteSource__VimgrepLineNr LineNR
  execute 'highlight default link uniteSource__VimgrepPattern'
        \ g:unite_source_vimgrep_search_word_highlight
endfunction"}}}
function! s:source.hooks.on_post_filter(args, context) "{{{
  for candidate in a:context.candidates
    let candidate.kind = ['file', 'jump_list']
    let candidate.action__col_pattern = a:context.source__input
    let candidate.is_multiline = 1
  endfor
endfunction"}}}

function! s:source.gather_candidates(args, context) "{{{
  if empty(a:context.source__targets)
        \ || a:context.source__input == ''
    return []
  endif

  let cmdline = printf('vimgrep /%s/j %s',
    \   escape(a:context.source__input, '/'),
    \   join(a:context.source__targets))

  call unite#print_source_message(
        \ 'Command-line: ' . cmdline, s:source.name)

  let buffers = range(1, bufnr('$'))

  let _ = []
  try
    execute cmdline
    let qflist = getqflist()

    let cwd = getcwd()
    if isdirectory(a:context.source__directory)
      call unite#util#lcd(a:context.source__directory)
    endif

    for qf in filter(qflist,
          \ "v:val.bufnr != '' && bufname(v:val.bufnr) != ''")
      let dict = {
            \   'action__path' : unite#util#substitute_path_separator(
            \       fnamemodify(bufname(qf.bufnr), ':p')),
            \   'action__text' : qf.text,
            \   'action__line' : qf.lnum,
            \ }
      let dict.word = printf('%s:%s:%s',
            \  unite#util#substitute_path_separator(
            \     fnamemodify(dict.action__path, ':.')),
            \ dict.action__line, dict.action__text)

      call add(_, dict)
    endfor

    if isdirectory(a:context.source__directory)
      call unite#util#lcd(cwd)
    endif
  catch /^Vim\%((\a\+)\)\?:E480/
    " Ignore.
    return []
  finally
    " Delete unlisted buffers.
    for bufnr in filter(range(1, bufnr('$')),
          \ '!buflisted(v:val) && bufexists(v:val)
          \   && index(buffers, v:val) < 0')
      silent! execute 'bwipeout' bufnr
    endfor

    " Clear qflist.
    call setqflist([])

    cclose
  endtry

  return _
endfunction "}}}

function! s:source.complete(args, context, arglead, cmdline, cursorpos) "{{{
  return unite#sources#file#complete_directory(
        \ a:args, a:context, a:arglead, a:cmdline, a:cursorpos)
endfunction"}}}

" vim: foldmethod=marker
