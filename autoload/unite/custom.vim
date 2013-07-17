"=============================================================================
" FILE: custom.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 17 Jul 2013.
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

function! unite#custom#get() "{{{
  if !exists('s:custom')
    let s:custom = {}
    let s:custom.sources = {}
    let s:custom.sources._ = {}
    let s:custom.actions = {}
    let s:custom.default_actions = {}
    let s:custom.aliases = {}
    let s:custom.profiles = {}
  endif

  return s:custom
endfunction"}}}

function! unite#custom#source(source_name, option_name, value) "{{{
  return s:custom_base('sources', a:source_name, a:option_name, a:value)
endfunction"}}}

function! unite#custom#alias(kind, name, action) "{{{
  call s:custom_base('aliases', a:kind, a:name, a:action)
endfunction"}}}

function! unite#custom#default_action(kind, default_action) "{{{
  let custom = unite#custom#get()

  let custom = unite#custom#get().default_actions
  for key in split(a:kind, '\s*,\s*')
    if !has_key(custom, key)
      let custom[key] = {}
    endif

    let custom[key] = a:default_action
  endfor
endfunction"}}}

function! unite#custom#action(kind, name, action) "{{{
  return s:custom_base('actions', a:kind, a:name, a:action)
endfunction"}}}

function! unite#custom#profile(profile_name, option_name, value) "{{{
  let profile_name =
        \ (a:profile_name == '' ? 'default' : a:profile_name)
  let custom = unite#custom#get()

  for key in split(profile_name, '\s*,\s*')
    if !has_key(custom.profiles, key)
      let custom.profiles[key] = {
            \ 'substitute_patterns' : {},
            \ 'filters' : [],
            \ 'context' : {},
            \ 'ignorecase' : &ignorecase,
            \ 'smartcase' : &smartcase,
            \ 'unite__save_pos' : {},
            \ 'unite__inputs' : {},
            \ }
    endif

    if a:option_name ==# 'substitute_patterns'
      let substitute_patterns = custom.profiles[key].substitute_patterns

      if has_key(substitute_patterns, a:value.pattern)
            \ && empty(a:value.subst)
        call remove(substitute_patterns, a:value.pattern)
      else
        let substitute_patterns[a:value.pattern] = {
              \ 'pattern' : a:value.pattern,
              \ 'subst' : a:value.subst, 'priority' : a:value.priority,
              \ }
      endif
    else
      let custom.profiles[key][a:option_name] = a:value
    endif
  endfor
endfunction"}}}
function! unite#custom#get_profile(profile_name, option_name) "{{{
  let profile_name =
        \ (a:profile_name == '' ? 'default' : a:profile_name)
  let custom = unite#custom#get()

  if !has_key(custom.profiles, profile_name)
    let custom.profiles[profile_name] = {
          \ 'substitute_patterns' : {},
          \ 'filters' : [],
          \ 'context' : {},
          \ 'ignorecase' : &ignorecase,
          \ 'smartcase' : &smartcase,
          \ 'unite__save_pos' : {},
          \ 'unite__inputs' : {},
          \ }
  endif

  return custom.profiles[profile_name][a:option_name]
endfunction"}}}

function! unite#custom#substitute(profile, pattern, subst, ...) "{{{
  let priority = get(a:000, 0, 0)
  call unite#custom#profile(a:profile, 'substitute_patterns', {
        \ 'pattern': a:pattern,
        \ 'subst': a:subst,
        \ 'priority': priority,
        \ })
endfunction"}}}

function! s:custom_base(key, kind, name, value) "{{{
  let custom = unite#custom#get()[a:key]

  for key in split(a:kind, '\s*,\s*')
    if !has_key(custom, key)
      let custom[key] = {}
    endif

    let custom[key][a:name] = a:value
  endfor
endfunction"}}}

" Default customs  "{{{
call unite#custom#profile('files', 'substitute_patterns', {
      \ 'pattern' : '^\~',
      \ 'subst' : substitute(substitute($HOME, '\\', '/', 'g'),
      \ ' ', '\\\\ ', 'g'),
      \ 'priority' : -100,
      \ })
call unite#custom#profile('files', 'substitute_patterns', {
      \ 'pattern' : '\.\{2,}\ze[^/]',
      \ 'subst' : "\\=repeat('../', len(submatch(0))-1)",
      \ 'priority' : 10000,
      \ })
call unite#custom#profile('files', 'smartcase', 0)
call unite#custom#profile('files', 'ignorecase', 1)
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
