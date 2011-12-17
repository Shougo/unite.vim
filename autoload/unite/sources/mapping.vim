"=============================================================================
" FILE: mapping.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 17 Oct 2011.
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

" Variables  "{{{
"}}}

call unite#util#set_default('g:unite_source_mapping_max_candidates', 30)
function! unite#sources#mapping#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'mapping',
      \ 'description' : 'candidates from Vim mappings',
      \ 'max_candidates' : g:unite_source_mapping_max_candidates,
      \ 'hooks' : {},
      \ }

let s:cached_result = []
function! s:source.hooks.on_init(args, context)"{{{
  " Get buffer number.
  let bufnr = get(a:args, 0, bufnr('%'))
  let oldnr = bufnr('%')
  if bufnr != bufnr('%')
    let oldnr = bufnr('%')
    execute 'buffer' bufnr
  endif

  " Get mapping list.
  redir => redir
  silent! nmap
  redir END

  if oldnr != bufnr('%')
    execute 'buffer' oldnr
  endif

  let s:cached_result = []
  for line in map(split(redir, '\n'),
        \ "substitute(v:val, '<NL>', '<C-J>', 'g')")
    let map = matchstr(line, '^\a*\s*\zs\S\+')
    if map =~ '^<SNR>'
      continue
    endif
    let map = substitute(map, '<NL>', '<C-j>', 'g')
    let map = substitute(map, '\(<.*>\)', '\\\1', 'g')

    call add(s:cached_result, {
          \ 'word' : line,
          \ 'kind' : 'command',
          \ 'action__command' : 'execute "normal ' . map . '"',
          \ })
  endfor
endfunction"}}}
function! s:source.gather_candidates(args, context)"{{{
  return s:cached_result
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
