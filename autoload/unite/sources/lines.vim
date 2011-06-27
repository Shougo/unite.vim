"=============================================================================
" FILE: lines.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
"          t9md <taqumd at gmail.com>
" Last Modified: 26 Jun 2011.
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

call unite#util#set_default('g:unite_source_lines_enable_highlight', 1)
call unite#util#set_default('g:unite_source_lines_search_word_highlight', 'Search')

let s:unite_source = {}
let s:unite_source.syntax = 'uniteSource__Lines'
let s:unite_source.hooks = {}
let s:unite_source.name = 'lines'

function! s:unite_source.hooks.on_init(args, context) "{{{
    execute 'highlight default link uniteSource__Lines_target ' . g:unite_source_lines_search_word_highlight
    syntax case ignore
endfunction"}}}
function! s:unite_source.hooks.on_syntax(args, context) "{{{
    call s:hl_refresh(a:context)
endfunction"}}}

function! s:hl_refresh(context)
    syntax clear uniteSource__Lines_target
    syntax case ignore
    if a:context.input == '' || !g:unite_source_lines_enable_highlight
        return
    endif

    for word in split(a:context.input, '\\\@<! ')
        execute "syntax match uniteSource__Lines_target '"
          \ . unite#escape_match(word)
          \ . "' contained containedin=uniteSource__Lines"
    endfor
endfunction

function! s:unite_source.gather_candidates(args, context)
    let path = expand('%:p')
    let lines = getbufline('%', 1, '$')
    let format = '%' . strlen(len(lines)) . 'd: %s'
    return map(lines, '{
                \   "word": printf("%s", v:val),
                \   "abbr": printf(format, v:key + 1, v:val),
                \   "kind": "jump_list",
                \   "action__path": path,
                \   "action__line": v:key + 1,
                \ }')
endfunction

function! s:unite_source.hooks.on_post_filter(args, context)
    call s:hl_refresh(a:context)
endfunction

function! unite#sources#lines#define() "{{{
  return s:unite_source
endfunction "}}}

" vim: expandtab:ts=4:sts=4:sw=4
