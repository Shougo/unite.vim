"=============================================================================
" FILE: interactive.vim
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

let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#interactive#define() abort
  return s:source
endfunction

let s:source = {
      \ 'name' : 'interactive',
      \ 'description' : 'candidates from unite sources by interactive',
      \ 'action_table' : {},
      \ 'default_action' : 'narrow',
      \ 'is_listed' : 0,
      \ 'hooks' : {},
      \ 'syntax' : 'uniteSource__Interactive',
      \}

function! s:source.hooks.on_syntax(args, context) abort "{{{
  syntax match uniteSource__InteractiveDescriptionLine / -- .*$/
        \ contained containedin=uniteSource__Interactive
  syntax match uniteSource__InteractiveDescription /.*$/
        \ contained containedin=uniteSource__InteractiveDescriptionLine
  syntax match uniteSource__InteractiveMarker / -- /
        \ contained containedin=uniteSource__InteractiveDescriptionLine
  highlight default link uniteSource__InteractiveMarker Special
  highlight default link uniteSource__InteractiveDescription Comment
endfunction"}}}

function! s:source.change_candidates(args, context) abort "{{{
  let _ = []
  if a:context.input !~ '\s'
    let _ += map(filter(values(unite#init#_sources([], a:context.input)),
            \ 'v:val.is_listed'), "{
            \ 'word' : v:val.name,
            \ 'abbr' : unite#util#truncate(v:val.name, 25) .
            \         (v:val.description != '' ? ' -- ' . v:val.description : ''),
            \ 'source__word' : v:val.name . ' ',
            \ }")
    if exists('g:unite_source_menu_menus')
      " Add menu sources
      let _ += values(map(copy(g:unite_source_menu_menus), "{
            \ 'word' : 'menu:'.v:key,
            \ 'abbr' : unite#util#truncate('menu:'.v:key, 25) .
            \         (get(v:val, 'description') != '' ?
            \            ' -- ' . v:val.description : ''),
            \ 'source__word' : 'menu:' . v:key . ' ',
            \ }"))
    endif
  else
    let _ += map(unite#complete#source(a:context.input,
          \ 'Unite ' . a:context.input, 0), "{
          \ 'word' : v:val,
          \ 'source__word' : v:val,
          \ }")
  endif

  return _
endfunction"}}}

" Actions "{{{
let s:source.action_table.narrow = {
      \ 'description' : 'narrow source',
      \ 'is_quit' : 0,
      \ }
function! s:source.action_table.narrow.func(candidate) abort "{{{
  call unite#mappings#narrowing(a:candidate.source__word, 0)
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo
