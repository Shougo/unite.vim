"=============================================================================
" FILE: output.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 02 Mar 2013.
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

function! unite#sources#output#define() "{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'output',
      \ 'description' : 'candidates from Vim command output',
      \ 'default_action' : 'yank',
      \ 'default_kind' : 'word',
      \ 'syntax' : 'uniteSource__Output',
      \ 'hooks' : {},
      \ }

function! s:source.gather_candidates(args, context) "{{{
  if type(get(a:args, 0, '')) == type([])
    " Use args directly.
    let result = a:args[0]
  else
    let command = join(a:args, ' ')
    if command == ''
      let command = unite#util#input(
            \ 'Please input Vim command: ', '', 'command')
    endif

    redir => output
    silent! execute command
    redir END

    let result = split(output, '\r\n\|\n')
  endif

  return map(result, "{
        \ 'word' : v:val,
        \ 'is_multiline' : 1,
        \ }")
endfunction"}}}
function! s:source.complete(args, context, arglead, cmdline, cursorpos) "{{{
  if !exists('*neocomplcache#sources#vim_complete#helper#command')
    return []
  endif

  let pattern = '\.\%(\h\w*\)\?$\|' . neocomplcache#get_keyword_pattern_end('vim')
  let [cur_keyword_pos, cur_keyword_str] = neocomplcache#match_word(a:arglead, pattern)
  return map(neocomplcache#sources#vim_complete#helper#command(
        \ a:arglead, cur_keyword_str), 'v:val.word')
endfunction"}}}
function! s:source.hooks.on_syntax(args, context) "{{{
  let save_current_syntax = get(b:, 'current_syntax', '')
  unlet! b:current_syntax

  try
    syntax include @Vim syntax/vim.vim
    syntax region uniteSource__OutputVim
          \ start=' ' end='$' contains=@Vim containedin=uniteSource__Output
  finally
    let b:current_syntax = save_current_syntax
  endtry
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
