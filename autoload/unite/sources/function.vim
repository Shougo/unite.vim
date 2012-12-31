"=============================================================================
" FILE: function.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 31 Dec 2012.
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

function! unite#sources#function#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'function',
      \ 'description' : 'candidates from functions',
      \ 'default_action' : 'call',
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
  silent! function
  redir END

  let s:cached_result = []
  for line in split(result, '\n')[1:]
    let line = line[9:]
    if line =~ '^<SNR>'
      continue
    endif
    let orig_line = line

    let word = matchstr(line, '\h[[:alnum:]_:#.]*\ze()\?')
    if word == ''
      continue
    endif

    let dict = {
          \ 'word' : word  . '(',
          \ 'abbr' : line,
          \ 'action__description' : line,
          \ 'action__function' : word,
          \ 'action__text' : word . '(',
          \ }
    let dict.action__description = dict.abbr

    call add(s:cached_result, dict)
  endfor
  let s:cached_result += s:caching_from_neocomplcache_dict()

  let s:cached_result = unite#util#sort_by(
        \ s:cached_result, 'tolower(v:val.word)')

  return s:cached_result
endfunction"}}}

function! s:caching_from_neocomplcache_dict() "{{{
  let dict_files = split(globpath(&runtimepath,
        \ 'autoload/neocomplcache/sources/vim_complete/functions.dict'), '\n')
  if empty(dict_files)
    return []
  endif

  let keyword_pattern = '^[[:alnum:]_]\+'
  let keyword_list = []
  for line in readfile(dict_files[0])
    let word = matchstr(line, keyword_pattern)
    call add(keyword_list, {
          \ 'word' : line,
          \ 'action__description' : line,
          \ 'action__function' : word,
          \ 'action__text' : word . '(',
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
    execute 'help' a:candidate.action__function.'()'
    normal! zv
    normal! zt
    setlocal previewwindow
    setlocal winfixheight
  catch /^Vim\%((\a\+)\)\?:E149/
    " Ignore
  endtry

  execute winnr.'wincmd w'
endfunction"}}}
let s:source.action_table.call = {
      \ 'description' : 'call the function and print result',
      \ }
function! s:source.action_table.call.func(candidate) "{{{
  if has_key(a:candidate, 'action__description')
    " Print description.

    " For function.
    let prototype_name = matchstr(
          \ a:candidate.action__description, '[^(]*')
    echohl Identifier | echon prototype_name | echohl None
    if prototype_name != a:candidate.action__description
      echon substitute(a:candidate.action__description[
            \ len(prototype_name) :], '^\s\+', ' ', '')
    endif
  endif

  let args = unite#util#input('call ' .
        \ a:candidate.action__function.'(', '', 'expression')
  if args != '' && args =~ ')$'
    redraw
    execute 'echo' a:candidate.action__function . '(' . args
  endif
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
