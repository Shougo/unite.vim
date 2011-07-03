"=============================================================================
" FILE: line.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          t9md <taqumd at gmail.com>
" Last Modified: 03 Jul 2011.
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

let s:unite_source = {}
let s:unite_source.syntax = 'uniteSource__Line'
let s:unite_source.hooks = {}
let s:unite_source.name = 'line'
call unite#custom_filters('line', ['matcher_regexp', 'sorter_default', 'converter_default'])

function! s:unite_source.hooks.on_init(args, context) "{{{
    execute 'highlight default link uniteSource__Line_target ' . g:unite_source_line_search_word_highlight
    syntax case ignore
    let a:context.source__path = expand('%:p')
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
    let direction = len(a:args) > 0 ? a:args[0] : 'all'
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

    let format = '%' . strlen(len(lines)) . 'd: %s'
    return map(lines, '{
                \   "word": v:val.val,
                \   "abbr": printf(format, v:val.nr, v:val.val),
                \   "kind": "jump_list",
                \   "action__path": a:context.source__path,
                \   "action__line": v:val.nr,
                \   "action__text": v:val.val
                \ }')
endfunction

function! s:unite_source.hooks.on_post_filter(args, context)
    call s:hl_refresh(a:context)
endfunction

function! unite#sources#line#define() "{{{
  return s:unite_source
endfunction "}}}

" vim: expandtab:ts=4:sts=4:sw=4
