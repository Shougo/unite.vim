"=============================================================================
" FILE: alias.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          tacroe <tacroe at gmail.com>
" Last Modified: 27 Aug 2011.
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

call unite#util#set_default('g:unite_source_alias_aliases', {})

function! unite#sources#alias#define()
  return s:make_aliases()
endfunction

function! s:make_aliases()
  let l:aliases = []
  for [l:name, l:config] in items(g:unite_source_alias_aliases)
    let l:args =
          \ (!has_key(l:config, 'args')) ? [] :
          \ (type(l:config.args) == type([])) ?
          \ l:config.args : [l:config.args]

    let l:alias = {}
    let l:alias.name = l:name
    let l:alias.description = get(l:config, 'description',
          \ s:make_default_description(l:config.source, l:args))
    let l:alias.source__config = l:config
    let l:alias.hooks = {}
    function! l:alias.hooks.on_pre_init(args, context)
      let l:config = a:context.source.source__config
      let l:original_source =
            \ (!has_key(l:config, 'source')) ? {} :
            \ deepcopy(unite#get_sources(l:config.source))
      let l:original_source.name = a:context.source.name
      let l:original_source.description = a:context.source.description

      return extend(a:context.source, l:original_source)
    endfunction

    call add(l:aliases, l:alias)
  endfor

  return l:aliases
endfunction

function! s:make_default_description(source_name, args)
  let l:desc = 'alias for "' . a:source_name
  if empty(a:args)
    return l:desc . '"'
  endif

  let l:desc .= ':' . join(a:args, ':') . '"'
  return l:desc
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
