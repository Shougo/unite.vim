"=============================================================================
" FILE: undo.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
" Last Modified: 21 Aug 2013.
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

function! unite#sources#undo#define()
  return s:has_undotree() ? s:source : []
endfunction

let s:source = {
      \ 'name' : 'undo',
      \ 'description' : 'candidates from undo list',
      \ 'sorters' : 'sorter_nothing',
      \ 'hooks' : {},
      \ 'action_table' : {},
      \ 'default_action' : 'undo',
      \}

function! s:source.hooks.on_syntax(args, context) "{{{
endfunction"}}}

function! s:make_candidates(tree, current) "{{{
  let dict = {}
  for item in a:tree
    let saved = get(item, 'save', '')
    let current = (item.seq == a:current) ? 'current' : ''
    let text = ''
    if saved != ''
      let text .= ' save'
    endif
    if current != ''
      let current .= ' current'
    endif
    let dict[item.seq] = {
          \ 'seq' : item.seq,
          \ 'number' : item.time,
          \ 'time' : s:get_time(item.time),
          \ 'text' : text,
          \ }
    if has_key(item, 'alt')
      call extend(dict, s:make_candidates(item.alt, a:current))
    endif
  endfor

  return dict
endfunction"}}}

function! s:compare(a, b)
  return a:b.seq - a:a.seq
endfunction

function! s:get_time(num) "{{{
  let time = localtime() - a:num
  let [min, hour, day, week, month, year] =
        \ [time/60, time/3600, time/86400,
        \  time/604800, time/259200, time/31536000]

  if year > 1
    return year . ' years ago'
  elseif month > 1
    return month . ' months ago'
  elseif week > 1
    return week . ' weeks ago'
  elseif day > 1
    return day . ' days ago'
  elseif hour > 1
    return hour . ' hour ago'
  elseif min > 1
    return min . ' minutes ago'
  elseif time == 1
    return time .  ' second ago'
  else
    return time .  ' seconds ago'
  endif
endfunction"}}}

function! s:source.gather_candidates(args, context) "{{{
  let tree = undotree()
  if empty(tree.entries)
    return []
  endif

  let dict = s:make_candidates(tree.entries, tree.seq_cur)
  let candidates = sort(values(dict), 's:compare')

  return map(candidates, "{
        \ 'word' : printf('%s : [%s]%s',
        \     v:val.time, v:val.seq, v:val.text),
        \ 'action__source_seq' : v:val.seq,
        \ }")
endfunction"}}}

function! s:has_undotree() "{{{
  return exists('*undotree') && (v:version > 703
        \ || v:version == 703 && has('patch005'))
endfunction"}}}

" Actions "{{{
let s:source.action_table.undo = {
      \ 'description' : 'undo',
      \ }
function! s:source.action_table.undo.func(candidate) "{{{
  execute 'undo' a:candidate.action__source_seq
endfunction"}}}
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo
