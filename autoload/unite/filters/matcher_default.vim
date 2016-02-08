"=============================================================================
" FILE: matcher_default.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
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

function! unite#filters#matcher_default#define() abort "{{{
  return s:matcher
endfunction"}}}

let s:matcher = {
      \ 'name' : 'matcher_default',
      \ 'description' : 'default matcher',
      \}

function! s:matcher.pattern(input) abort "{{{
  let patterns = map(filter(copy(map(copy(s:default_matchers),
        \ 'unite#get_filters(v:val)')),
        \ "v:val != self && has_key(v:val, 'pattern')"),
        \ 'v:val.pattern(a:input)')
  return join(patterns,'\|')
endfunction"}}}

function! s:matcher.filter(candidates, context) abort "{{{
  let candidates = a:candidates
  for default in s:default_matchers
    let filter = unite#get_filters(default)
    if !empty(filter)
      let candidates = filter.filter(candidates, a:context)
    endif
  endfor

  return candidates
endfunction"}}}


let s:default_matchers = ['matcher_context']
function! unite#filters#matcher_default#get() abort "{{{
  return s:default_matchers
endfunction"}}}
function! unite#filters#matcher_default#use(matchers) abort "{{{
  let s:default_matchers = unite#util#convert2list(a:matchers)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
