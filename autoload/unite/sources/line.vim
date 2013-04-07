"=============================================================================
" FILE: line.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          t9md <taqumd at gmail.com>
" Last Modified: 07 Apr 2013.
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

" original verion is http://d.hatena.ne.jp/thinca/20101105/1288896674

call unite#util#set_default(
      \ 'g:source_line_enable_highlight', 1)
call unite#util#set_default(
      \ 'g:source_line_search_word_highlight', 'Search')

let s:supported_search_direction = ['forward', 'backward', 'all']

function! unite#sources#line#define() "{{{
  return [s:source_line, s:source_line_fast]
endfunction "}}}

" line source. "{{{
let s:source_line = {
      \ 'name' : 'line',
      \ 'syntax' : 'uniteSource__Line',
      \ 'hooks' : {},
      \ 'max_candidates': 100,
      \ 'default_kind' : 'jump_list',
      \ 'matchers' : 'matcher_regexp',
      \ 'sorters' : 'sorter_nothing',
      \ }

function! s:source_line.hooks.on_init(args, context) "{{{
  call s:on_init(a:args, a:context)

  call unite#print_source_message(
        \ 'Target: ' . a:context.source__path, s:source_line.name)
endfunction"}}}
function! s:source_line.hooks.on_syntax(args, context) "{{{
  call s:hl_refresh(a:context)
  call s:on_syntax(a:args, a:context)
endfunction"}}}

function! s:source_line.gather_candidates(args, context) "{{{
  call s:hl_refresh(a:context)

  let direction = a:context.source__direction
  let start = a:context.source__linenr
  let lines = (direction ==# 'forward' || direction ==# 'backward') ?
        \ s:get_lines(a:context, direction, start, 0) :
        \ (s:get_lines(a:context, 'forward', start, 0)
        \  + s:get_lines(a:context, 'backward', start-1, 0))

  let _ = map(lines, "{
        \ 'word' : v:val[1],
        \ 'is_multiline' : 1,
        \ 'action__line' : v:val[0],
        \ 'action__text' : v:val[1],
        \ }")

  let a:context.source__format = '%' . strlen(len(_)) . 'd: %s'

  return direction ==# 'backward' ? reverse(_) : _
endfunction"}}}

function! s:source_line.hooks.on_post_filter(args, context) "{{{
  call s:post_filter(a:args, a:context)
endfunction"}}}

function! s:source_line.complete(args, context, arglead, cmdline, cursorpos) "{{{
  return s:supported_search_direction
endfunction"}}}

function! s:source_line.source__converter(candidates, context) "{{{
  return s:converter(a:candidates, a:context)
endfunction"}}}

let s:source_line.converters = [s:source_line.source__converter]
"}}}

" line/fast source. "{{{
let s:source_line_fast = deepcopy(s:source_line)
let s:source_line_fast.name = 'line/fast'
let s:source_line_fast.syntax = 'uniteSource__LineFast'
let s:source_line_fast.is_volatile = 1

function! s:source_line_fast.hooks.on_init(args, context) "{{{
  call s:on_init(a:args, a:context)

  call unite#print_source_message(
        \ 'Target: ' . a:context.source__path, s:source_line_fast.name)
endfunction"}}}
function! s:source_line_fast.gather_candidates(args, context) "{{{
  call s:hl_refresh(a:context)

  let direction = a:context.source__direction
  let start = a:context.source__linenr
  let offset = 500

  let _ = s:on_gather_candidates(direction, a:context, start, offset)
  if direction ==# 'all'
    let _ = s:on_gather_candidates('forward', a:context, start, offset)

    if len(_) <= a:context.unite__max_candidates
      let _ += s:on_gather_candidates('backward', a:context, start-1, offset)
    endif
  else
    let _ = s:on_gather_candidates(direction, a:context, start, offset)
  endif

  let a:context.source__format = '%' . strlen(len(_)) . 'd: %s'

  return direction ==# 'backward' ? reverse(_) : _
endfunction"}}}
"}}}

" Misc. "{{{
function! s:on_init(args, context) "{{{
  execute 'highlight default link uniteSource__LineFast_target '
        \ . g:source_line_search_word_highlight
  syntax case ignore
  let a:context.source__path = unite#util#substitute_path_separator(
        \ (&buftype =~ 'nofile') ? expand('%:p') : bufname('%'))
  let a:context.source__bufnr = bufnr('%')
  let a:context.source__linenr = line('.')
  let a:context.source__is_bang =
        \ (get(a:args, 0, '') ==# '!')

  let direction = get(filter(copy(a:args),
        \ "v:val != '!'"), 0, '')
  if direction == ''
    let direction = 'all'
  endif

  if index(s:supported_search_direction, direction) == -1
    let direction = 'all'
  endif

  if direction !=# 'all'
    call unite#print_source_message(
          \ 'direction: ' . direction, s:source_line.name)
  endif

  let a:context.source__direction = direction
endfunction"}}}
function! s:on_syntax(args, context) "{{{
  syntax match uniteSource__LineFast_LineNr
        \ '\(^- *+\? *\)\@<=\<\d\+\>'
        \ contained containedin=uniteSource__LineFast
  highlight default link uniteSource__LineFast_LineNr LineNr
  syntax match uniteSource__Line_LineNr
        \ '\(^- *+\? *\)\@<=\<\d\+\>'
        \ contained containedin=uniteSource__Line
  highlight default link uniteSource__Line_LineNr LineNr
endfunction"}}}
function! s:on_gather_candidates(direction, context, start, offset) "{{{
  let _ = []
  let start = a:start
  let len = 0
  while 1
    let lines = map(s:get_lines(a:context, a:direction, start, a:offset), "{
          \ 'word' : v:val[1],
          \ 'is_multiline' : 1,
          \ 'action__line' : v:val[0],
          \ 'action__text' : v:val[1],
          \ }")
    if empty(lines) || start < 0
      return _
    endif

    " Check match.
    for input in a:context.input_list
      let expr = unite#filters#matcher_regexp#get_expr(input)
      if expr !=# 'if_lua'
        call filter(lines, expr)
      endif
    endfor

    let _ += lines
    let len += len(lines)

    if len >= a:context.unite__max_candidates
      return _
    endif

    if a:direction ==# 'forward'
      let start += a:offset
    else
      let start -= a:offset
    endif
  endwhile
endfunction"}}}
function! s:get_lines(context, direction, start, offset) "{{{
  let [start, end] =
        \ a:direction ==# 'forward' ?
        \ [a:start, (a:offset == 0 ? '$' : a:start + a:offset)] :
        \ [(a:offset == 0 ? 1 : a:start - a:offset), a:start]
  if start <= 0
    let start = 0
  endif

  let _ = []
  let linenr = start
  for line in getbufline(a:context.source__bufnr, start, end)
    if line != ''
      call add(_, [linenr, line])
    endif

    let linenr += 1
  endfor

  return _
endfunction"}}}

function! s:hl_refresh(context) "{{{
  silent! syntax clear uniteSource__Line_target
  syntax case ignore
  if a:context.input == '' || !g:source_line_enable_highlight
    return
  endif

  for word in split(a:context.input, '\\\@<! ')
    execute "syntax match uniteSource__Line_target "
          \ . string(unite#escape_match(word))
          \ . " contained containedin=uniteSource__Line"
  endfor
endfunction"}}}

function! s:converter(candidates, context) "{{{
  for candidate in a:candidates
    let candidate.abbr = printf(a:context.source__format,
          \ candidate.action__line, candidate.action__text)
  endfor

  return a:candidates
endfunction"}}}
function! s:post_filter(args, context) "{{{
  for candidate in a:context.candidates
    let candidate.action__buffer_nr = a:context.source__bufnr
  endfor
endfunction"}}}
"}}}

" vim: foldmethod=marker
