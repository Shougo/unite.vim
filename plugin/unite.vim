"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 19 Sep 2011.
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
" Version: 3.0, for Vim 7.0
"=============================================================================

if exists('g:loaded_unite')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Obsolute options check."{{{
if exists('g:unite_cd_command')
  echoerr 'g:unite_cd_command option does not work this version of unite.vim.'
endif
if exists('g:unite_lcd_command')
  echoerr 'g:unite_lcd_command option does not work this version of unite.vim.'
endif
"}}}
" Global options definition."{{{
if !exists('g:unite_update_time')
  let g:unite_update_time = 500
endif
if !exists('g:unite_enable_start_insert')
  let g:unite_enable_start_insert = 0
endif
if !exists('g:unite_enable_ignore_case')
  let g:unite_enable_ignore_case = &ignorecase
endif
if !exists('g:unite_enable_smart_case')
  let g:unite_enable_smart_case = &infercase
endif
if !exists('g:unite_split_rule')
  let g:unite_split_rule = 'topleft'
endif
if !exists('g:unite_enable_split_vertically')
  let g:unite_enable_split_vertically = 0
endif
if !exists('g:unite_winheight')
  let g:unite_winheight = 20
endif
if !exists('g:unite_winwidth')
  let g:unite_winwidth = 90
endif
if !exists('g:unite_quick_match_table')
  let g:unite_quick_match_table = {
        \'a' : 1, 's' : 2, 'd' : 3, 'f' : 4, 'g' : 5, 'h' : 6, 'j' : 7, 'k' : 8, 'l' : 9, ';' : 10,
        \'q' : 11, 'w' : 12, 'e' : 13, 'r' : 14, 't' : 15, 'y' : 16, 'u' : 17, 'i' : 18, 'o' : 19, 'p' : 20,
        \'1' : 21, '2' : 22, '3' : 23, '4' : 24, '5' : 25, '6' : 26, '7' : 27, '8' : 28, '9' : 29, '0' : 30,
        \}
endif
if !exists('g:unite_abbr_highlight')
  let g:unite_abbr_highlight = 'Normal'
endif
if !exists('g:unite_cursor_line_highlight')
  let g:unite_cursor_line_highlight = 'PmenuSel'
endif
if !exists('g:unite_data_directory')
  let g:unite_data_directory = expand('~/.unite')
endif
if !isdirectory(fnamemodify(g:unite_data_directory, ':p'))
  call mkdir(iconv(fnamemodify(g:unite_data_directory, ':p'), &encoding, &termencoding), 'p')
endif
"}}}

" Wrapper command.
command! -nargs=+ -complete=customlist,unite#complete_source Unite call s:call_unite_empty(<q-args>)
function! s:call_unite_empty(args)"{{{
  let [args, options] = s:parse_options_args(a:args)
  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete_source UniteWithCurrentDir call s:call_unite_current_dir(<q-args>)
function! s:call_unite_current_dir(args)"{{{
  let [args, options] = s:parse_options_args(a:args)
  if !has_key(options, 'input')
    let path = &filetype ==# 'vimfiler' ? b:vimfiler.current_dir : unite#substitute_path_separator(fnamemodify(getcwd(), ':p'))
    if path !~ '/$'
      let path .= '/'
    endif
    let options.input = escape(path, ' ')
  endif

  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete_source UniteWithBufferDir call s:call_unite_buffer_dir(<q-args>)
function! s:call_unite_buffer_dir(args)"{{{
  let [args, options] = s:parse_options_args(a:args)
  if !has_key(options, 'input')
    let path = &filetype ==# 'vimfiler' ? b:vimfiler.current_dir : unite#substitute_path_separator(fnamemodify(bufname('%'), ':p:h'))
    if path !~ '/$'
      let path .= '/'
    endif
    let options.input = escape(path, ' ')
  endif

  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete_source UniteWithCursorWord call s:call_unite_cursor_word(<q-args>)
function! s:call_unite_cursor_word(args)"{{{
  let [args, options] = s:parse_options_args(a:args)
  if !has_key(options, 'input')
    let options.input = expand('<cword>')
  endif

  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete_source UniteWithInput call s:call_unite_input(<q-args>)
function! s:call_unite_input(args)"{{{
  let [args, options] = s:parse_options_args(a:args)
  if !has_key(options, 'input')
    let options.input = escape(input('Input narrowing text: ', ''), ' ')
  endif

  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete_source UniteWithInputDirectory call s:call_unite_input_directory(<q-args>)
function! s:call_unite_input_directory(args)"{{{
  let [args, options] = s:parse_options_args(a:args)
  if !has_key(options, 'input')
    let path = unite#substitute_path_separator(input('Input narrowing directory: ', '', 'dir'))
    if isdirectory(path) && path !~ '/$'
      let path .= '/'
    endif
    let options.input = path
  endif

  call unite#start(args, options)
endfunction"}}}

command! -nargs=? -complete=customlist,unite#complete_resume UniteResume call s:call_unite_resume(<q-args>)
function! s:call_unite_resume(args)"{{{
  let [args, options] = s:parse_options(a:args)

  call unite#resume(join(args), options)
endfunction"}}}

function! s:parse_options(args)"{{{
  let args = []
  let options = {}
  for arg in split(a:args, '\%(\\\@<!\s\)\+')
    let arg = substitute(arg, '\\\( \)', '\1', 'g')

    let matched_list = filter(copy(unite#get_options()),
          \  'stridx(arg, v:val) == 0')
    for option in matched_list
      let key = substitute(substitute(option, '-', '_', 'g'), '=$', '', '')[1:]
      let options[key] = (option =~ '=$') ?
            \ arg[len(option) :] : 1
      break
    endfor

    if empty(matched_list)
      call add(args, arg)
    endif
  endfor

  return [args, options]
endfunction"}}}
function! s:parse_options_args(args)"{{{
  let _ = []
  let [args, options] = s:parse_options(a:args)
  for arg in args
    " Add source name.
    let source_name = matchstr(arg, '^[^:]*')
    let source_arg = arg[len(source_name)+1 :]
    let source_args = source_arg  == '' ? [] :
          \  map(split(source_arg, '\\\@<!:', 1),
          \      'substitute(v:val, ''\\\(.\)'', "\\1", "g")')
    call add(_, insert(source_args, source_name))
  endfor

  return [_, options]
endfunction"}}}

let g:loaded_unite = 1

let &cpo = s:save_cpo
unlet s:save_cpo

" __END__
" vim: foldmethod=marker
