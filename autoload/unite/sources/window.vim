"=============================================================================
" FILE: window.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
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

function! unite#sources#window#define() abort "{{{
  return s:source
endfunction"}}}

function! unite#sources#window#sorter(candidates, context) abort "{{{
  return unite#util#sort_by(a:candidates, '
  \   -get(
  \     gettabwinvar(
  \       v:val.action__tab_nr, v:val.action__window_nr,
  \       "unite_window", {}),
  \     "time", 0)
  \ ')
endfunction"}}}

let s:source = {
      \ 'name' : 'window',
      \ 'description' : 'candidates from window list',
      \ 'syntax' : 'uniteSource__Window',
      \ 'hooks' : {},
      \ 'default_kind' : 'window',
      \ 'sorters': function('unite#sources#window#sorter'),
      \}

function! s:source.hooks.on_init(args, context) abort "{{{
  let no_current = index(a:args, 'no-current') >= 0
  if index(a:args, 'all') >= 0
    let a:context.source__candidates = []
    let cur_tabnr = tabpagenr()
    for tabnr in range(1, tabpagenr('$'))
      let a:context.source__candidates +=
            \ s:get_windows(tabnr == cur_tabnr && no_current, tabnr)
    endfor
  else
    let a:context.source__candidates = s:get_windows(no_current, tabpagenr())
  endif
endfunction"}}}
function! s:source.hooks.on_syntax(args, context) abort "{{{
  syntax match uniteSource__Window_prefix /\d\+: \[.\{-}\]/
        \ contained containedin=uniteSource__Window
  highlight default link uniteSource__Window_prefix Constant
  syntax match uniteSource__Window_title / \[.\{-}\]/
        \ contained containedin=uniteSource__Window
  highlight default link uniteSource__Window_title Function
  syntax match uniteSource__Window_directory /(.\{-})/
        \ contained containedin=uniteSource__Window
  highlight default link uniteSource__Window_directory PreProc
endfunction"}}}
function! s:source.gather_candidates(args, context) abort "{{{
  return a:context.source__candidates
endfunction"}}}
function! s:source.complete(args, context, arglead, cmdline, cursorpos) abort "{{{
  return ['no-current', 'all']
endfunction"}}}

" Misc
function! s:get_windows(no_current, tabnr) abort "{{{
  let list = range(1, tabpagewinnr(a:tabnr, '$'))
  unlet list[tabpagewinnr(a:tabnr)-1]
  if !a:no_current
    " Add current window.
    call add(list, tabpagewinnr(a:tabnr))
  endif

  let buffers = tabpagebuflist(a:tabnr)
  let candidates = []
  for i in list
    let bufname = bufname(buffers[i-1])
    if empty(bufname)
      let bufname = '[No Name]'
    endif

    call add(candidates, {
          \ 'word' : bufname,
          \ 'abbr' : printf('%d: [%d/%d] %s %s',
          \      a:tabnr, i, tabpagewinnr(a:tabnr, '$'),
          \      (i == tabpagewinnr(a:tabnr) ? '%' :
          \       i == tabpagewinnr(a:tabnr, '#') ? '#' : ' '),
          \      bufname),
          \ 'action__tab_nr' : a:tabnr,
          \ 'action__window_nr' : i,
          \ })
  endfor

  return candidates
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
