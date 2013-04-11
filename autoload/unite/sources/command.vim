"=============================================================================
" FILE: command.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 11 Apr 2013.
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
"}}}

function! unite#sources#command#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'command',
      \ 'description' : 'candidates from Ex command',
      \ 'default_action' : 'edit',
      \ 'max_candidates' : 200,
      \ 'action_table' : {},
      \ 'matchers' : 'matcher_regexp',
      \ }

let s:cached_result = []
function! s:source.gather_candidates(args, context) "{{{
  if !a:context.is_redraw && !empty(s:cached_result)
    return s:cached_result
  endif

  " Get command list.
  redir => result
  silent! command
  redir END

  let s:cached_result = []
  for line in split(result, '\n')[1:]
    let word = matchstr(line, '\a\w*')

    " Analyze prototype.
    let end = matchend(line, '\a\w*')
    let args = matchstr(line, '[[:digit:]?+*]', end)
    if args != '0'
      let prototype = matchstr(line, '\a\w*', end)

      if prototype == ''
        let prototype = 'arg'
      endif

      if args == '*'
        let prototype = '[' . prototype . '] ...'
      elseif args == '?'
        let prototype = '[' . prototype . ']'
      elseif args == '+'
        let prototype = prototype . ' ...'
      endif
    else
      let prototype = ''
    endif

    let dict = {
          \ 'word' : word,
          \ 'abbr' : printf('%-16s %s', word, prototype),
          \ 'kind' : 'command',
          \ 'action__command' : word . ' ',
          \ 'source__command' : ':'.word,
          \ }
    let dict.action__description = dict.abbr

    call add(s:cached_result, dict)
  endfor
  let s:cached_result += s:caching_from_neocomplcache_dict()

  let s:cached_result = unite#util#sort_by(
        \ s:cached_result, 'tolower(v:val.word)')

  return s:cached_result
endfunction"}}}
function! s:source.change_candidates(args, context) "{{{
  let dummy = substitute(a:context.input, '[*\\]', '', 'g')
  if len(split(dummy)) > 1
    " Add dummy result.
    return [{
          \ 'word' : dummy,
          \ 'abbr' : printf('[new command] %s', dummy),
          \ 'kind' : 'command',
          \ 'source' : 'command',
          \ 'action__command' : dummy,
          \}]
  endif

  return []
endfunction"}}}

function! s:caching_from_neocomplcache_dict() "{{{
  let dict_files = split(globpath(&runtimepath,
        \ 'autoload/neocomplcache/sources/vim_complete/commands.dict'), '\n')
  if empty(dict_files)
    return []
  endif

  let keyword_pattern =
        \'^\%(-\h\w*\%(=\%(\h\w*\|[01*?+%]\)\?\)\?\|'
        \'<\h[[:alnum:]_-]*>\?\|\h[[:alnum:]_:#\[]*\%([!\]]\+\|()\?\)\?\)'
  let keyword_list = []
  for line in readfile(dict_files[0])
    let word = substitute(
          \ matchstr(line, keyword_pattern), '[\[\]]', '', 'g')
    call add(keyword_list, {
          \ 'word' : line,
          \ 'kind' : 'command',
          \ 'action__command' : word . ' ',
          \ 'action__description' : line,
          \ 'source__command' : ':'.word,
          \})
  endfor

  return keyword_list
endfunction"}}}

" Actions "{{{
let s:source.action_table.preview = {
      \ 'description' : 'view the help documentation',
      \ 'is_quit' : 0,
      \ }
function! s:source.action_table.preview.func(candidate) "{{{
  let winnr = winnr()

  try
    execute 'help' a:candidate.source__command
    normal! zv
    normal! zt
    setlocal previewwindow
    setlocal winfixheight
  catch /^Vim\%((\a\+)\)\?:E149/
    " Ignore
  endtry

  execute winnr.'wincmd w'
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
