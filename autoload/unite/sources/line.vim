"=============================================================================
" FILE: line.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          t9md <taqumd at gmail.com>
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

" original verion is http://d.hatena.ne.jp/thinca/20101105/1288896674

call unite#util#set_default(
      \ 'g:unite_source_line_enable_highlight', 1)
call unite#util#set_default(
      \ 'g:unite_source_line_search_word_highlight', 'Search')

let s:supported_search_direction = ['forward', 'backward', 'all']

function! unite#sources#line#define() "{{{
  return s:source_line
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
endfunction"}}}
function! s:source_line.hooks.on_syntax(args, context) "{{{
  call s:hl_refresh(a:context)
  call s:on_syntax(a:args, a:context)
endfunction"}}}

function! s:source_line.gather_candidates(args, context) "{{{
  call s:hl_refresh(a:context)

  let direction = a:context.source__direction
  let start = a:context.source__linenr

  let _ = s:get_context_lines(a:context, direction, start)

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

" Misc. "{{{
function! s:on_init(args, context) "{{{
  execute 'highlight default link uniteSource__Line_target '
        \ . g:unite_source_line_search_word_highlight
  syntax case ignore
  let a:context.source__path = unite#util#substitute_path_separator(
        \ (&buftype =~ 'nofile') ? expand('%:p') : bufname('%'))
  let a:context.source__bufnr = bufnr('%')
  let a:context.source__linenr = line('.')
  let a:context.source__linemax = line('$')
  let a:context.source__is_bang =
        \ (get(a:args, 0, '') ==# '!')

  let options = filter(copy(a:args), "v:val != '!'")
  let direction = get(options, 0, '')
  if direction == ''
    let direction = 'all'
  endif
  let a:context.source__wrap = get(options, 1,
        \ (&wrapscan ? 'wrap' : 'nowrap')) ==# 'wrap'
  if direction == ''
    let direction = 'all'
  endif

  if index(s:supported_search_direction, direction) == -1
    let direction = 'all'
  endif

  let a:context.source__input = a:context.input
  if a:context.source__linemax > 10000 && a:context.source__input == ''
    " Note: In huge buffer, you must input narrowing text.
    let a:context.source__input = unite#util#input('Narrowing text: ', '')
  endif

  if direction !=# 'all'
    call unite#print_source_message(
          \ 'Direction: ' . direction, s:source_line.name)
  endif

  call unite#print_source_message(
        \ 'Target: ' . a:context.source__path, s:source_line.name)

  if a:context.source__input != ''
    call unite#print_source_message(
          \ 'Narrowing text: ' . a:context.source__input,
          \ s:source_line.name)
  endif

  let a:context.source__direction = direction
endfunction"}}}
function! s:on_syntax(args, context) "{{{
  syntax match uniteSource__Line_LineNr
        \ '\(^- *+\? *\)\@<=\<\d\+\>'
        \ contained containedin=uniteSource__Line
  highlight default link uniteSource__Line_LineNr LineNr
endfunction"}}}
function! s:on_gather_candidates(direction, context, start, max) "{{{
  return map(s:get_lines(a:context, a:direction, a:start, a:max), "{
        \ 'word' : v:val[1],
        \ 'is_multiline' : 1,
        \ 'action__line' : v:val[0],
        \ 'action__text' : v:val[1],
        \ }")
endfunction"}}}
function! s:get_lines(context, direction, start, max) "{{{
  let [start, end] =
        \ a:direction ==# 'forward' ?
        \ [a:start, (a:max == 0 ? '$' : a:start + a:max - 1)] :
        \ [((a:max == 0 || a:start == a:max) ?
        \    1 : a:start - a:max), a:start]

  let _ = []
  let linenr = start
  let input = tolower(a:context.source__input)
  let is_expr = input =~ '[~\\.^$\[\]*]'
  for line in getbufline(a:context.source__bufnr, start, end)
    if input == ''
          \ || (!is_expr && stridx(tolower(line), input) >= 0)
          \ || line =~ input
      call add(_, [linenr, line])
    endif

    let linenr += 1
  endfor

  return _
endfunction"}}}

function! s:hl_refresh(context) "{{{
  silent! syntax clear uniteSource__Line_target
  syntax case ignore
  if a:context.input == '' || !g:unite_source_line_enable_highlight
    return
  endif

  for word in split(a:context.input, '\\\@<! ')
    execute "syntax match uniteSource__Line_target "
          \ . string(unite#util#escape_match(word))
          \ . " contained containedin=uniteSource__Line"
  endfor
endfunction"}}}

function! s:converter(candidates, context) "{{{
  for candidate in a:candidates
    let candidate.abbr = printf(a:context.source__format,
          \ candidate.action__line, candidate.action__text)
    let candidate.action__col_pattern = a:context.source__input
  endfor

  return a:candidates
endfunction"}}}
function! s:post_filter(args, context) "{{{
  for candidate in a:context.candidates
    let candidate.action__buffer_nr = a:context.source__bufnr
  endfor
endfunction"}}}
function! s:get_context_lines(context, direction, start) "{{{
  if a:direction ==# 'all'
    let lines = s:on_gather_candidates('forward', a:context, 1, 0)
  else
    let lines = s:on_gather_candidates(a:direction, a:context, a:start, 0)

    if a:context.source__wrap
      let start = ((a:direction ==# 'forward') ?
            \       1 : a:context.source__linemax)
      let max = ((a:direction ==# 'forward') ?
            \       a:context.source__linenr-1 :
            \       a:context.source__linemax-a:context.source__linenr-1)
      if max != 0
        let lines += s:on_gather_candidates(a:direction, a:context, start, max)
      endif
    endif
  endif

  return lines
endfunction"}}}
"}}}

" vim: foldmethod=marker
