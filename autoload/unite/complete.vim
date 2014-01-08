"=============================================================================
" FILE: complete.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 08 Jan 2014.
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

function! unite#complete#source(arglead, cmdline, cursorpos) "{{{
  let [ret, options] = unite#helper#parse_options_args(a:cmdline)
  let source_name = ret[-1][0]
  let source_args = ret[-1][1:]

  let _ = []

  if a:arglead !~ ':'
    " Option names completion.
    let _ +=  copy(unite#variables#options())

    " Source name completion.
    if mode() ==# 'c' || unite#util#is_cmdwin()
      let _ += keys(filter(unite#init#_sources([], a:arglead),
            \ 'v:val.is_listed'))
    endif
    if exists('*neobundle#get_unite_sources')
      let _ += neobundle#get_unite_sources()
    endif
  else
    " Add "{source-name}:".
    let _  = map(_, 'source_name.":".v:val')
  endif

  if source_name != '' && (mode() ==# 'c' || unite#util#is_cmdwin())
    " Source args completion.
    let args = source_name . ':' . join(source_args[: -2], ':')
    if args !~ ':$'
      let args .= ':'
    endif
    let _ += map(unite#args_complete(
          \ [insert(copy(source_args), source_name)],
          \ join(source_args, ':'), a:cmdline, a:cursorpos),
          \ "args.escape(v:val, ':')")
  endif

  return sort(filter(_, 'stridx(v:val, a:arglead) == 0'))
endfunction"}}}

function! unite#complete#buffer_name(arglead, cmdline, cursorpos) "{{{
  let _ = map(filter(range(1, bufnr('$')), '
        \ getbufvar(v:val, "&filetype") ==# "unite"),
        \ 'getbufvar(v:val, "unite").buffer_name')
  let _ += unite#variables#options()

  return filter(_, printf('stridx(v:val, %s) == 0', string(a:arglead)))
endfunction"}}}

function! unite#complete#vimfiler(sources, arglead, cmdline, cursorpos) "{{{
  let context = {}
  let context = unite#init#_context(context,
        \ unite#helper#get_source_names(a:sources))
  let context.unite__is_interactive = 0
  let context.unite__is_complete = 1

  try
    call unite#init#_current_unite(a:sources, context)
  catch /^unite.vim: Invalid /
    return
  endtry

  let _ = []
  for source in unite#loaded_sources_list()
    if has_key(source, 'vimfiler_complete')
      let _ += source.vimfiler_complete(
            \ source.args, context, a:arglead, a:cmdline, a:cursorpos)
    endif
  endfor

  return _
endfunction"}}}

function! unite#complete#args(sources, arglead, cmdline, cursorpos) "{{{
  let context = {}
  let context = unite#init#_context(context,
        \ unite#helper#get_source_names(a:sources))
  let context.unite__is_interactive = 0
  let context.unite__is_complete = 1

  try
    call unite#init#_current_unite(a:sources, context)
  catch /^unite.vim: Invalid /
    return []
  endtry

  let _ = []
  for source in unite#loaded_sources_list()
    if has_key(source, 'complete')
      let _ += source.complete(
            \ source.args, context, a:arglead, a:cmdline, a:cursorpos)
    endif
  endfor

  return _
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
