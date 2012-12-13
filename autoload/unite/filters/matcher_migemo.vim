"=============================================================================
" FILE: matcher_migemo.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 04 Sep 2012.
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

function! unite#filters#matcher_migemo#define() "{{{
  if !has('migemo') && !executable('cmigemo')
    " Not supported.
    return {}
  endif

  let s:migemodict = s:search_dict()
  if has('migemo') && (&migemodict == '' || !filereadable(&migemodict))
    let &migemodict = s:migemodict
  endif
  if s:migemodict == ''
    " Dictionary not found.
    return {}
  endif

  return s:matcher
endfunction"}}}

function! s:search_dict()
  let dict = s:search_dict2('migemo/'.&encoding.'/migemo-dict')

  if dict == ''
    let dict = s:search_dict2(&encoding.'/migemo-dict')
  endif
  if dict == ''
    let dict = s:search_dict2('migemo-dict')
  endif

  return dict
endfunction

function! s:search_dict2(name)
  let path = $VIM . ',' . &runtimepath
  let dict = globpath(path, 'dict/'.a:name)
  if dict == ''
    let dict = globpath(path, a:name)
  endif
  if dict == ''
    let dict = '/usr/local/share/migemo/'.a:name
    if !filereadable(dict)
      return ''
    endif
  endif

  return split(dict, '\n')[0]
endfunction

let s:matcher = {
      \ 'name' : 'matcher_migemo',
      \ 'description' : 'migemo matcher',
      \}

function! s:matcher.filter(candidates, context) "{{{
  if a:context.input == ''
    return a:candidates
  endif

  let candidates = a:candidates
  for input in a:context.input_list
    if input =~ '^!'
      if input == '!'
        continue
      endif
      " Exclusion match.
      let expr = 'v:val.word !~ ' .
            \ string(s:get_migemo_pattern(input[1:]))
    else
      let expr = 'v:val.word =~ ' .
            \ string(s:get_migemo_pattern(input))
    endif

    try
      let candidates = unite#util#filter_matcher(
            \ candidates, expr, a:context)
    catch
      let candidates = []
    endtry
  endfor

  return candidates
endfunction"}}}

function! s:get_migemo_pattern(input)
  if has('migemo')
    " Use migemo().
    return migemo(a:input)
  else
    " Use cmigemo.
    return vimproc#system(
          \ 'cmigemo -v -w "'.a:input.'" -d "'.s:migemodict.'"')
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
