"=============================================================================
" FILE: find.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
" Last Modified: 21 Sep 2011.
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
call unite#util#set_default('g:unite_source_find_command', 'find')
call unite#util#set_default('g:unite_source_find_max_candidates', 100)
"}}}

" Actions "{{{
let s:action_find = {
  \   'description': 'find this directory',
  \   'is_quit': 1,
  \   'is_invalidate_cache': 1,
  \ }
function! s:action_find.func(candidates) "{{{
  call unite#start([['find', 'v:val.action__directory']])
endfunction "}}}
if executable(g:unite_source_find_command) && unite#util#has_vimproc()
  call unite#custom_action('file,buffer', 'find', s:action_find)
endif
" }}}

function! unite#sources#find#define() "{{{
  return executable(g:unite_source_find_command) && unite#util#has_vimproc() ?
        \ s:find_source : []
endfunction "}}}

let s:find_source = {
      \ 'name': 'find',
      \ 'max_candidates': g:unite_source_find_max_candidates,
      \ 'hooks' : {},
      \ 'filters' : ['matcher_regexp', 'sorter_default', 'converter_relative'],
      \ }

function! s:find_source.hooks.on_init(args, context) "{{{
  let a:context.source__target = get(a:args, 0, '')
  if a:context.source__target == ''
    let a:context.source__target = input('Target: ', '.', 'dir')
  endif

  let a:context.source__input = get(a:args, 1, '')
  if a:context.source__input == ''
    let a:context.source__input = input('Command-line: ')
  endif
endfunction"}}}
function! s:find_source.hooks.on_close(args, context) "{{{
  if has_key(a:context, 'source__proc')
    call a:context.source__proc.waitpid()
  endif
endfunction "}}}

function! s:find_source.gather_candidates(args, context) "{{{
  if empty(a:context.source__target)
        \ || a:context.source__input == ''
    let a:context.is_async = 0
    call unite#print_message('[find] Completed.')
    return []
  endif

  if a:context.is_redraw
    let a:context.is_async = 1
  endif

  let cmdline = printf('%s %s %s', g:unite_source_find_command,
    \   a:context.source__target, a:context.source__input)
  call unite#print_message('[find] Command-line: ' . cmdline)
  let a:context.source__proc = vimproc#pgroup_open(cmdline)

  " Close handles.
  call a:context.source__proc.stdin.close()
  call a:context.source__proc.stderr.close()

  return []
endfunction "}}}

function! s:find_source.async_gather_candidates(args, context) "{{{
  let stdout = a:context.source__proc.stdout
  if stdout.eof
    " Disable async.
    call unite#print_message('[find] Completed.')
    let a:context.is_async = 0
  endif

  let candidates = map(stdout.read_lines(-1, 300),
        \ 'fnamemodify(iconv(v:val, &termencoding, &encoding), ":p")')

  if isdirectory(a:context.source__target)
    let cwd = getcwd()
    lcd `=a:context.source__target`
  endif

  call map(candidates,
    \ '{
    \   "word": v:val,
    \   "abbr": fnamemodify(v:val, ":."),
    \   "kind": "file",
    \   "action__path" : unite#util#substitute_path_separator(v:val),
    \   "action__directory": unite#util#path2directory(v:val),
    \ }')

  if isdirectory(a:context.source__target)
    lcd `=cwd`
  endif

  return candidates
endfunction "}}}

" vim: foldmethod=marker
