"=============================================================================
" FILE: variables.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 28 Dec 2013.
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

if !exists('s:use_current_unite')
  let s:use_current_unite = 1
endif

function! unite#variables#current_unite() "{{{
  if !exists('s:current_unite')
    let s:current_unite = {}
  endif

  return s:current_unite
endfunction"}}}

function! unite#variables#set_current_unite(unite) "{{{
  let s:current_unite = a:unite
endfunction"}}}

function! unite#variables#use_current_unite() "{{{
  return s:use_current_unite
endfunction"}}}

function! unite#variables#enable_current_unite() "{{{
  let s:use_current_unite = 1
endfunction"}}}

function! unite#variables#disable_current_unite() "{{{
  let s:use_current_unite = 0
endfunction"}}}

function! unite#variables#static() "{{{
  if !exists('s:static')
    let s:static = {}
    let s:static.sources = {}
    let s:static.kinds = {}
    let s:static.filters = {}
  endif

  return s:static
endfunction"}}}

function! unite#variables#dynamic() "{{{
  if !exists('s:dynamic')
    let s:dynamic = {}
    let s:dynamic.sources = {}
    let s:dynamic.kinds = {}
    let s:dynamic.filters = {}
  endif

  return s:dynamic
endfunction"}}}

function! unite#variables#loaded_defaults() "{{{
  if !exists('s:loaded_defaults')
    let s:loaded_defaults = {}
  endif

  return s:loaded_defaults
endfunction"}}}

function! unite#variables#options() "{{{
  if !exists('s:options')
    let s:options = [
          \ '-buffer-name=', '-profile-name=', '-input=', '-prompt=',
          \ '-default-action=', '-start-insert',
          \ '-no-start-insert', '-no-quit',
          \ '-winwidth=', '-winheight=',
          \ '-immediately', '-no-empty',
          \ '-auto-preview', '-auto-highlight', '-complete',
          \ '-vertical', '-horizontal', '-direction=', '-no-split',
          \ '-verbose', '-auto-resize',
          \ '-toggle', '-quick-match', '-create',
          \ '-cursor-line-highlight=', '-no-cursor-line',
          \ '-update-time=', '-hide-source-names', '-hide-status-line',
          \ '-max-multi-lines=', '-here', '-silent', '-keep-focus',
          \ '-auto-quit', '-no-focus',
          \ '-long-source-names', '-short-source-names',
          \ '-multi-line', '-resume', '-wrap', '-select=', '-log',
          \ '-truncate', '-tab', '-sync',
          \]
  endif

  return s:options
endfunction"}}}

function! unite#variables#kinds(...) "{{{
  if a:0 == 0
    call unite#init#_default_scripts('kinds', [])
  else
    call unite#init#_default_scripts('kinds', [a:1])
  endif

  let kinds = unite#init#_kinds()
  return (a:0 == 0) ? kinds : get(kinds, a:1, {})
endfunction"}}}

function! unite#variables#sources(...) "{{{
  let unite = unite#get_current_unite()
  if !has_key(unite, 'sources')
    return {}
  endif

  if a:0 == 0
    return unite.sources
  endif

  return unite#util#get_name(unite.sources, a:1, {})
endfunction"}}}

function! unite#variables#all_sources(...) "{{{
  if a:0 == 0
    return unite#init#_sources()
  endif

  let unite = unite#get_current_unite()

  let all_sources = unite#init#_sources([], a:1)
  let source = get(all_sources, a:1, {})

  return empty(source) ?
        \ get(filter(copy(get(unite, 'sources', [])),
        \ 'v:val.name ==# a:1'), 0, {}) : source
endfunction"}}}

function! unite#variables#filters(...) "{{{
  if a:0 == 0
    call unite#init#_default_scripts('filters', [])
  else
    call unite#init#_default_scripts('filters', [a:1])
  endif

  let filters = unite#init#_filters()

  if a:0 == 0
    return filters
  endif

  return get(filters, a:1, {})
endfunction"}}}

function! unite#variables#loaded_sources(...) "{{{
  " Initialize load.
  let unite = unite#get_current_unite()
  return a:0 == 0 ? unite.sources :
        \ get(filter(copy(unite.sources), 'v:val.name ==# a:1'), 0, {})
endfunction"}}}

function! unite#variables#default_context() "{{{
  if !exists('s:default_context')
    let s:default_context = {
          \ 'input' : '',
          \ 'start_insert' : g:unite_enable_start_insert,
          \ 'complete' : 0,
          \ 'script' : 0,
          \ 'col' : col('.'),
          \ 'no_quit' : 0,
          \ 'buffer_name' : 'default',
          \ 'profile_name' : '',
          \ 'prompt' : g:unite_prompt,
          \ 'default_action' : 'default',
          \ 'winwidth' : g:unite_winwidth,
          \ 'winheight' : g:unite_winheight,
          \ 'immediately' : 0,
          \ 'no_empty' : 0,
          \ 'auto_preview' : 0,
          \ 'auto_highlight' : 0,
          \ 'vertical' : g:unite_enable_split_vertically,
          \ 'direction' : g:unite_split_rule,
          \ 'no_split' : 0,
          \ 'temporary' : 0,
          \ 'verbose' : 0,
          \ 'auto_resize' : 0,
          \ 'old_buffer_info' : [],
          \ 'toggle' : 0,
          \ 'quick_match' : 0,
          \ 'create' : 0,
          \ 'cursor_line_highlight' :
          \    g:unite_cursor_line_highlight,
          \ 'no_cursor_line' : 0,
          \ 'update_time' : g:unite_update_time,
          \ 'no_buffer' : 0,
          \ 'hide_source_names' : 0,
          \ 'max_multi_lines' : 5,
          \ 'here' : 0,
          \ 'silent' : 0,
          \ 'keep_focus' : 0,
          \ 'auto_quit' : 0,
          \ 'is_redraw' : 0,
          \ 'is_restart' : 0,
          \ 'is_resize' : 0,
          \ 'no_focus' : 0,
          \ 'multi_line' : 0,
          \ 'resume' : 0,
          \ 'wrap' : 0,
          \ 'select' : 0,
          \ 'log' : 0,
          \ 'truncate' : 0,
          \ 'tab' : 0,
          \ 'sync' : 0,
          \ 'execute_command' : '',
          \ 'unite__direct_switch' : 0,
          \ 'unite__is_interactive' : 1,
          \ 'unite__is_complete' : 0,
          \ 'unite__is_vimfiler' : 0,
          \ 'unite__old_winwidth' : 0,
          \ 'unite__old_winheight' : 0,
          \ 'unite__disable_hooks' : 0,
          \ 'unite__disable_max_candidates' : 0,
          \ }
  endif

  return s:default_context
endfunction"}}}

function! unite#variables#get_source_variable(source, variable, default) "{{{
  if !exists('s:source_variables')
    let s:source_variables = {}
  endif

  if !has_key(s:source_variables, a:source)
    let s:source_variables[a:source] = {}
  endif

  if !has_key(s:source_variables[a:source], a:variable)
    let s:source_variables[a:source][a:variable] = a:default
  endif

  return s:source_variables[a:source][a:variable]
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
