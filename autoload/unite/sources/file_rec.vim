"=============================================================================
" FILE: file_rec.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 31 Oct 2010
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

function! unite#sources#file_rec#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'file_rec',
      \ 'max_candidates': 30,
      \}

function! s:source.gather_candidates(args, context)"{{{
  if !empty(a:args)
    let l:directory = unite#substitute_path_separator(a:args[0])
    if l:directory !~ '/$'
      let l:directory .= '/'
    endif

    let l:input = l:directory
  elseif isdirectory(a:context.input)
    let l:directory = a:context.input
    if l:directory !~ '/$'
      let l:directory .= '/'
    endif

    let l:input = l:directory
  else
    let l:directory = unite#substitute_path_separator(getcwd())
    if l:directory !~ '/$'
      let l:directory .= '/'
    endif

    let l:input = ''
  endif

  if l:directory =~ '^\%(\a\+:\)\?/$' ||
        \ unite#substitute_path_separator(expand(l:directory)) ==# unite#substitute_path_separator($HOME . '/')
    call unite#print_error('file_rec: Too many candidates.')
    return []
  endif
  let l:candidates = split(unite#substitute_path_separator(glob(l:input . '**')), '\n')

  if len(l:candidates) > 10000
    call unite#print_error('file_rec: Too many candidates.')
    return []
  endif

  " Remove directories.
  call filter(l:candidates, '!isdirectory(v:val)')

  if g:unite_source_file_ignore_pattern != ''
    call filter(l:candidates, 'v:val !~ ' . string(g:unite_source_file_ignore_pattern))
  endif

  return map(l:candidates, '{
        \ "word" : v:val,
        \ "source" : "file_rec",
        \ "kind" : "file",
        \ "action__path" : v:val,
        \ "action__directory" : unite#path2directory(v:val),
        \ }')
endfunction"}}}

" Add custom action table."{{{
let s:cdable_action_rec = {}

function! s:cdable_action_rec.func(candidate)
  call unite#start([['file_rec', a:candidate.action__directory]])
endfunction

call unite#custom_action('cdable', 'rec', s:cdable_action_rec)
unlet! s:cdable_action_rec
"}}}

" vim: foldmethod=marker
