"=============================================================================
" FILE: line.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          t9md <taqumd at gmail.com>
" Last Modified: 24 Aug 2012.
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

call unite#util#set_default('g:source_line_enable_highlight', 1)
call unite#util#set_default('g:source_line_search_word_highlight', 'Search')

function! unite#sources#line#define() "{{{
  let s:last_result = {
        \ 'direction' : '',
        \ 'bufnr' : -1,
        \ 'lines' : [],
        \ }

  return s:source
endfunction "}}}

let s:source = {
      \ 'name' : 'line',
      \ 'syntax' : 'uniteSource__Line',
      \ 'hooks' : {},
      \ 'max_candidates': 100,
      \ }

function! s:source.hooks.on_init(args, context) "{{{
  execute 'highlight default link uniteSource__Line_target '
        \ . g:source_line_search_word_highlight
  syntax case ignore
  let a:context.source__path = unite#util#substitute_path_separator(
        \ (&buftype =~ 'nofile') ? expand('%:p') : bufname('%'))
  let a:context.source__bufnr = bufnr('%')
  let a:context.source__linenr = line('.')
  let a:context.source__is_bang =
        \ (get(a:args, 0, '') ==# '!')

  call unite#print_source_message('Target: ' . a:context.source__path, s:source.name)
endfunction"}}}
function! s:source.hooks.on_syntax(args, context) "{{{
  call s:hl_refresh(a:context)
endfunction"}}}

function! s:hl_refresh(context)
  syntax clear uniteSource__Line_target
  syntax case ignore
  if a:context.input == '' || !g:source_line_enable_highlight
    return
  endif

  for word in split(a:context.input, '\\\@<! ')
    execute "syntax match uniteSource__Line_target "
          \ . string(unite#escape_match(word))
          \ . " contained containedin=uniteSource__Line"
  endfor
endfunction

let s:supported_search_direction = ['forward', 'backward', 'all']
function! s:source.gather_candidates(args, context)
  call s:hl_refresh(a:context)

  let direction = get(filter(copy(a:args),
        \ "v:val != '!'"), 0, '')
  if direction == ''
    let direction = 'all'
  endif

  if index(s:supported_search_direction, direction) == -1
    let direction = 'all'
  endif

  if direction !=# 'all'
    call unite#print_source_message('direction: ' . direction, s:source.name)
  endif

  if a:context.source__is_bang
        \ && s:last_result.bufnr == a:context.source__bufnr
        \ && s:last_result.direction ==# direction
        \ && !a:context.is_redraw
    " Use last lines.
    let _ = s:last_result.lines
  else
    let lines = (direction ==# 'forward' || direction ==# 'backward') ?
          \ s:get_lines(a:context, direction) :
          \ (s:get_lines(a:context, 'forward')
          \  + s:get_lines(a:context, 'backward')[: -2])

    let _ = map(lines, "{
          \ 'word' : v:val[1],
          \ 'is_multiline' : 1,
          \ 'action__line' : v:val[0],
          \ 'action__text' : v:val[1],
          \ }")
    if a:context.source__is_bang
      let s:last_result = {
            \ 'direction' : direction,
            \ 'bufnr' : a:context.source__bufnr,
            \ 'lines' : _,
            \ }
    endif
  endif

  let a:context.source__format = '%' . strlen(len(_)) . 'd: %s'

  return _
endfunction

function! s:get_lines(context, direction)"{{{
  let [start, end] =
        \ a:direction ==# 'forward' ?
        \ [a:context.source__linenr, '$'] :
        \ [1, a:context.source__linenr]

  let _ = []
  let linenr = start
  for line in getbufline(a:context.source__bufnr, start, end)
    call add(_, [linenr, line])

    let linenr += 1
  endfor

  return _
endfunction"}}}

function! s:source.hooks.on_post_filter(args, context)
  for candidate in a:context.candidates
    let candidate.kind = 'jump_list'
    let candidate.action__buffer_nr = a:context.source__bufnr
  endfor
endfunction

function! s:source.complete(args, context, arglead, cmdline, cursorpos)"{{{
  return ['all', 'forward', 'backward']
endfunction"}}}

" Filters.
function! s:source.source__converter(candidates, context)"{{{
  for candidate in a:candidates
    let candidate.abbr = printf(a:context.source__format,
          \ candidate.action__line, candidate.action__text)
  endfor

  return a:candidates
endfunction"}}}

let s:source.filters =
      \ ['matcher_regexp', 'sorter_default',
      \      s:source.source__converter]

" vim: expandtab:ts=2:sts=2:sw=2
