"=============================================================================
" FILE: alias.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          tacroe <tacroe at gmail.com>
" Last Modified: 09 Sep 2011.
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
    let l:alias.source__args = l:args
    let l:alias.hooks = {}

    function! l:alias.hooks.on_pre_init(args, context)
      let l:config = a:context.source.source__config
      let l:original_source =
            \ (!has_key(l:config, 'source') ||
            \  l:config.source ==# a:context.source.name) ? {} :
            \ deepcopy(unite#get_all_sources(l:config.source))
      let l:alias_source = deepcopy(a:context.source)

      if has_key(l:original_source, 'hooks')
            \ && has_key(l:original_source.hooks, 'on_pre_init')
        " Call pre init hook.
        call l:original_source.hooks.on_pre_init(
              \ a:context.source.source__args + a:args,
              \ { 'source' : l:original_source })
      endif

      let l:source = extend(a:context.source,
            \ filter(copy(l:original_source),
            \ 'type(v:val) != type(function("type"))'))
      let l:source.name = l:alias_source.name
      let l:source.description = l:alias_source.description
      let l:source.hooks = {}
      let l:source.source__original_source = l:original_source

      " Overwrite hooks.
      if has_key(l:original_source, 'hooks')
        for l:func in filter(keys(l:original_source.hooks),
              \ 'v:val !=# "on_pre_init"')
          let l:define_function = join([
                \ 'function! l:source.hooks.' . l:func . '(args, context)',
                \ '  let l:args = a:context.source.source__args + a:args',
                \ '  return a:context.source.source__original_source.hooks.'
                \                    . l:func . '(l:args, a:context)',
                \ 'endfunction'], "\n")
          execute l:define_function
        endfor
      endif

      " Overwrite functions.
      for l:func in keys(filter(copy(l:original_source),
            \ 'type(v:val) == type(function("type"))'))
        let l:define_function = join([
              \ 'function! l:source.' . l:func . '(args, context)',
              \ '  let l:args = a:context.source.source__args + a:args',
              \ '  return a:context.source.source__original_source.'
              \                    . l:func . '(l:args, a:context)',
              \ 'endfunction'], "\n")
        execute l:define_function
      endfor
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
