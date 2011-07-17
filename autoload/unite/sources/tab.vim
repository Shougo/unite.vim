"=============================================================================
" FILE: tab.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 17 Jul 2011.
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

function! unite#sources#tab#define()"{{{
  return s:source
endfunction"}}}
function! unite#sources#tab#_append()"{{{
  if exists('*gettabvar')
    " Save tab access time.
    let t:unite_tab_access_time = localtime()
  endif
endfunction"}}}

let s:source = {
      \ 'name' : 'tab',
      \ 'description' : 'candidates from tab list',
      \}

function! s:source.gather_candidates(args, context)"{{{
  let l:list = range(1, tabpagenr('$'))
  unlet l:list[tabpagenr()-1]
  if exists('*gettabvar')
    call sort(l:list, 's:compare')
  endif
  let l:arg = get(a:args, 0, '')
  if l:arg !=# 'no-current'
    " Add current tab.
    call add(l:list, tabpagenr())
  endif

  let l:candidates = []
  for i in l:list
    let l:bufnrs = tabpagebuflist(i)
    let l:bufnr = l:bufnrs[tabpagewinnr(i) - 1]  " Get current window buffer in tabs.

    let l:bufname = unite#substitute_path_separator(fnamemodify((i == tabpagenr() ? bufname('#') : bufname(l:bufnr)), ':p'))
    if l:bufname == ''
      let l:bufname = '[No Name]'
    endif

    if exists('*gettabvar')
      " Use gettabvar().
      let l:title = gettabvar(i, 'title')
      if l:title != ''
        let l:title = '[' . l:title . ']'
      endif

      let l:cwd = unite#substitute_path_separator((i == tabpagenr() ? getcwd() : gettabvar(i, 'cwd')))
      if l:cwd !~ '/$'
        let l:cwd .= '/'
      endif
    else
      let l:title = ''
      let l:cwd = ''
    endif

    let l:abbr = i . ': ' . l:title
    if l:cwd != ''
      if stridx(l:bufname, l:cwd) == 0
        let l:bufname = l:bufname[len(l:cwd) :]
      endif
      let l:abbr .= l:bufname

      let l:abbr .= '(' . substitute(l:cwd, '.\zs/$', '', '') . ')'
    else
      let l:abbr .= l:bufname
    endif

    let l:wincount = tabpagewinnr(i, '$')
    if i == tabpagenr()
      let l:wincount -= 1
    endif
    if l:wincount > 1
      let l:abbr .= '{' . l:wincount . '}'
    endif
    let l:abbr .= getbufvar(bufnr('%'), '&modified') ? '[+]' : ''

    let l:word = exists('*gettabvar') && gettabvar(i, 'title') != '' ? gettabvar(i, 'title') : l:bufname

    call add(l:candidates, {
          \ 'word' : l:word,
          \ 'abbr' : l:abbr,
          \ 'kind' : 'tab',
          \ 'action__tab_nr' : i,
          \ 'action__directory' : l:cwd,
          \ })
  endfor

  return l:candidates
endfunction"}}}

" Misc
function! s:compare(candidate_a, candidate_b)"{{{
  return gettabvar(a:candidate_b, 'unite_tab_access_time') - gettabvar(a:candidate_a, 'unite_tab_access_time')
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
