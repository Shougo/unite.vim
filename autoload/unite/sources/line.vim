"=============================================================================
" FILE: line.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          t9md <taqumd at gmail.com>
" Last Modified: 10 Aug 2011.
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

call unite#util#set_default('g:unite_source_line_enable_highlight', 1)
call unite#util#set_default('g:unite_source_line_search_word_highlight', 'Search')

let s:unite_source = {
            \ 'name' : 'line',
            \ 'syntax' : 'uniteSource__Line',
            \ 'hooks' : {},
            \ 'max_candidates': 100,
            \ 'filters' :
            \    ['matcher_regexp', 'sorter_default', 'converter_default'],
            \ }

function! s:unite_source.hooks.on_init(args, context) "{{{
    execute 'highlight default link uniteSource__Line_target ' . g:unite_source_line_search_word_highlight
    syntax case ignore
    let a:context.source__path = (&l:buftype =~ 'nofile') ?
                \ expand('%:p') : bufname('%')
    let a:context.source__bufnr = bufnr('%')
    let a:context.source__linenr = line('.')
endfunction"}}}
function! s:unite_source.hooks.on_syntax(args, context) "{{{
    call s:hl_refresh(a:context)
endfunction"}}}

function! s:hl_refresh(context)
    syntax clear uniteSource__Line_target
    syntax case ignore
    if a:context.input == '' || !g:unite_source_line_enable_highlight
        return
    endif

    for word in split(a:context.input, '\\\@<! ')
        execute "syntax match uniteSource__Line_target '"
          \ . unite#escape_match(word)
          \ . "' contained containedin=uniteSource__Line"
    endfor
endfunction

let s:supported_search_direction = ['forward', 'backward', 'all']
function! s:unite_source.gather_candidates(args, context)
    let direction = get(a:args, 0, '')
    if direction == ''
        let direction = 'all'
    endif

    if index(s:supported_search_direction, direction) == -1
        let direction = 'all'
    endif

    if direction !=# 'all'
        call unite#print_message('[line] direction: ' . direction)
    endif

    let [start, end] =
                \ direction ==# 'forward' ?
                \ [a:context.source__linenr, '$'] :
                \ direction ==# 'backward' ?
                \ [1, a:context.source__linenr] :
                \ [1, '$']

    let lines = map(getbufline(a:context.source__bufnr, start, end),
                \ '{"nr": v:key+start, "val": v:val }')
    let a:context.source__format = '%' . strlen(len(lines)) . 'd: %s'

    return map(lines, '{
                \   "word": v:val.val,
                \   "action__line": v:val.nr,
                \   "action__text": v:val.val
                \ }')
endfunction

function! s:unite_source.hooks.on_post_filter(args, context)
    call s:hl_refresh(a:context)

    for l:candidate in a:context.candidates
        let l:candidate.kind = "jump_list"
        let l:candidate.abbr = printf(a:context.source__format,
                    \ l:candidate.action__line, l:candidate.action__text)
        let l:candidate.action__buffer_nr = a:context.source__bufnr
        let l:candidate.action__path = a:context.source__path
    endfor
endfunction
function! s:on_post_filter(args, context)"{{{
  let l:is_relative_path =
        \ a:context.source__directory == unite#util#substitute_path_separator(getcwd())

  if !l:is_relative_path
    let l:cwd = getcwd()
    lcd `=a:context.source__directory`
  endif

  for l:candidate in a:context.candidates
    let l:candidate.kind = 'file'
    let l:candidate.abbr = unite#util#substitute_path_separator(
          \ fnamemodify(l:candidate.action__path, ':.'))
          \ . (isdirectory(l:candidate.action__path) ? '/' : '')
    let l:candidate.action__directory = l:is_relative_path ?
          \ l:candidate.abbr :
          \ unite#util#path2directory(l:candidate.action__path)
  endfor

  if !l:is_relative_path
    lcd `=l:cwd`
  endif
endfunction"}}}

function! unite#sources#line#define() "{{{
  return s:unite_source
endfunction "}}}

" vim: expandtab:ts=4:sts=4:sw=4
