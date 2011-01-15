"=============================================================================
" FILE: command.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 16 Jan 2011.
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
"}}}

function! unite#sources#command#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'command',
      \ 'description' : 'candidates from Ex command',
      \ 'default_action' : { 'command' : 'edit' },
      \ 'required_pattern_length' : 1,
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
          \ 'source' : 'command',
          \ 'action__command' : l:word,
          \})
  endfor

  return s:cached_result
endfunction"}}}

" vim: foldmethod=marker
