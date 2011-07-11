"=============================================================================
" FILE: command.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 11 Jul 2011.
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

function! unite#sources#command#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'command',
      \ 'description' : 'candidates from Ex command',
      \ 'default_action' : 'edit',
      \ 'max_candidates' : 30,
      \ }

let s:cached_result = []
function! s:source.gather_candidates(args, context)"{{{
  if !a:context.is_redraw && !empty(s:cached_result)
    return s:cached_result
  endif

  " Get command list.
  redir => l:result
  silent! command
  redir END

  let s:cached_result = []
  for line in split(l:result, '\n')[1:]
    let l:word = matchstr(line, '\a\w*')

    " Analyze prototype.
    let l:end = matchend(line, '\a\w*')
    let l:args = matchstr(line, '[[:digit:]?+*]', l:end)
    if l:args != '0'
      let l:prototype = matchstr(line, '\a\w*', l:end)

      if l:prototype == ''
        let l:prototype = 'arg'
      endif

      if l:args == '*'
        let l:prototype = '[' . l:prototype . '] ...'
      elseif l:args == '?'
        let l:prototype = '[' . l:prototype . ']'
      elseif l:args == '+'
        let l:prototype = l:prototype . ' ...'
      endif
    else
      let l:prototype = ''
    endif

    call add(s:cached_result, {
          \ 'word' : l:word,
          \ 'abbr' : printf('%-16s %s', l:word, l:prototype),
          \ 'kind' : 'command',
          \ 'action__command' : l:word,
          \})
  endfor
  let s:cached_result += s:caching_from_neocomplcache_dict()

  return s:cached_result
endfunction"}}}
function! s:source.change_candidates(args, context)"{{{
  let l:dummy = substitute(a:context.input, '[*\\]', '', 'g')
  if len(split(l:dummy)) > 1
    " Add dummy result.
    return [{
          \ 'word' : l:dummy,
          \ 'abbr' : printf('[new command] %s', l:dummy),
          \ 'kind' : 'command',
          \ 'source' : 'command',
          \ 'action__command' : l:dummy,
          \}]
  endif

  return []
endfunction"}}}

function! s:caching_from_neocomplcache_dict()"{{{
  let l:dict_files = split(globpath(&runtimepath, 'autoload/neocomplcache/sources/vim_complete/commands.dict'), '\n')
  if empty(l:dict_files)
    return []
  endif

  let l:keyword_pattern =
        \'^\%(-\h\w*\%(=\%(\h\w*\|[01*?+%]\)\?\)\?\|<\h[[:alnum:]_-]*>\?\|\h[[:alnum:]_:#\[]*\%([!\]]\+\|()\?\)\?\)'
  let l:keyword_list = []
  for line in readfile(l:dict_files[0])
    let l:word = substitute(matchstr(line, l:keyword_pattern), '[\[\]]', '', 'g')
    call add(l:keyword_list, {
          \ 'word' : l:word,
          \ 'abbr' : line,
          \ 'kind' : 'command',
          \ 'source' : 'command',
          \ 'action__command' : l:word,
          \})
  endfor

  return l:keyword_list
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
