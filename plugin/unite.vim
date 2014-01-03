"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 03 Jan 2014.
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

if exists('g:loaded_unite')
  finish
elseif v:version < 702
  echoerr 'unite.vim does not work this version of Vim "' . v:version . '".'
  finish
elseif $SUDO_USER != '' && $USER !=# $SUDO_USER
      \ && $HOME !=# expand('~'.$USER)
      \ && $HOME ==# expand('~'.$SUDO_USER)
  echohl Error
  echomsg 'unite.vim disabled: "sudo vim" is detected and $HOME is set to '
        \.'your user''s home. '
        \.'You may want to use the sudo.vim plugin, the "-H" option '
        \.'with "sudo" or set always_set_home in /etc/sudoers instead.'
  echohl None
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Obsolete options check. "{{{
if exists('g:unite_cd_command')
  echoerr 'g:unite_cd_command option does not work this version of unite.vim.'
endif
if exists('g:unite_lcd_command')
  echoerr 'g:unite_lcd_command option does not work this version of unite.vim.'
endif
"}}}
" Global options definition. "{{{
let g:unite_update_time =
      \ get(g:, 'unite_update_time', 500)
let g:unite_prompt =
      \ get(g:, 'unite_prompt', '> ')
let g:unite_enable_start_insert =
      \ get(g:, 'unite_enable_start_insert', 0)
let g:unite_split_rule =
      \ get(g:, 'unite_split_rule', 'topleft')
let g:unite_enable_split_vertically =
      \ get(g:, 'unite_enable_split_vertically', 0)
let g:unite_winheight =
      \ get(g:, 'unite_winheight', 20)
let g:unite_winwidth =
      \ get(g:, 'unite_winwidth', 90)
let g:unite_quick_match_table =
      \ get(g:, 'unite_quick_match_table', {
      \     'a' : 0, 's' : 1, 'd' : 2, 'f' : 3, 'g' : 4, 'h' : 5, 'j' : 6, 'k' : 7, 'l' : 8, ';' : 9,
      \     'q' : 10, 'w' : 11, 'e' : 12, 'r' : 13, 't' : 14, 'y' : 15, 'u' : 16, 'i' : 17, 'o' : 18, 'p' : 19,
      \     '1' : 20, '2' : 21, '3' : 22, '4' : 23, '5' : 24, '6' : 25, '7' : 26, '8' : 27, '9' : 28, '0' : 29,
      \ })
let g:unite_abbr_highlight =
      \ get(g:, 'unite_abbr_highlight', 'Normal')
let g:unite_cursor_line_highlight =
      \ get(g:, 'unite_cursor_line_highlight', 'PmenuSel')
let g:unite_enable_short_source_names =
      \ get(g:, 'unite_enable_short_source_names', 0)
let g:unite_marked_icon =
      \ get(g:, 'unite_marked_icon', '*')
let g:unite_candidate_icon =
      \ get(g:, 'unite_candidate_icon', ' ')
let g:unite_force_overwrite_statusline =
      \ get(g:, 'unite_force_overwrite_statusline', 1)
let g:unite_data_directory =
      \ substitute(substitute(fnamemodify(get(
      \   g:, 'unite_data_directory', '~/.unite'),
      \  ':p'), '\\', '/', 'g'), '/$', '', '')
if !isdirectory(g:unite_data_directory)
  call mkdir(g:unite_data_directory, 'p')
endif
"}}}

" Wrapper command.
command! -nargs=+ -complete=customlist,unite#complete#source
      \ Unite
      \ call s:call_unite_empty(<q-args>)
function! s:call_unite_empty(args) "{{{
  let [args, options] = unite#helper#parse_options_args(a:args)
  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete#source
      \ UniteWithCurrentDir
      \ call s:call_unite_current_dir(<q-args>)
function! s:call_unite_current_dir(args) "{{{
  let [args, options] = unite#helper#parse_options_args(a:args)
  if !has_key(options, 'input')
    let path = &filetype ==# 'vimfiler' ?
          \ b:vimfiler.current_dir :
          \ unite#substitute_path_separator(fnamemodify(getcwd(), ':p'))
    if path !~ '/$'
      let path .= '/'
    endif
    let options.input = escape(path, ' ')
  endif

  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete#source
      \ UniteWithBufferDir
      \ call s:call_unite_buffer_dir(<q-args>)
function! s:call_unite_buffer_dir(args) "{{{
  let [args, options] = unite#helper#parse_options_args(a:args)
  if !has_key(options, 'input')
    let path = &filetype ==# 'vimfiler' ?
          \ b:vimfiler.current_dir :
          \ unite#substitute_path_separator(fnamemodify(bufname('%'), ':p:h'))
    if path !~ '/$'
      let path .= '/'
    endif
    let options.input = escape(path, ' ')
  endif

  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete#source
      \ UniteWithCursorWord call s:call_unite_cursor_word(<q-args>)
function! s:call_unite_cursor_word(args) "{{{
  let [args, options] = unite#helper#parse_options_args(a:args)
  if !has_key(options, 'input')
    let options.input = expand('<cword>')
  endif

  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete#source
      \ UniteWithInput call s:call_unite_input(<q-args>)
function! s:call_unite_input(args) "{{{
  let [args, options] = unite#helper#parse_options_args(a:args)
  if !has_key(options, 'input')
    let options.input = input('Input narrowing text: ', '')
  endif

  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete#source
      \ UniteWithInputDirectory call s:call_unite_input_directory(<q-args>)
function! s:call_unite_input_directory(args) "{{{
  let [args, options] = unite#helper#parse_options_args(a:args)
  if !has_key(options, 'input')
    let path = unite#substitute_path_separator(
          \ input('Input narrowing directory: ', '', 'dir'))
    if isdirectory(path) && path !~ '/$'
      let path .= '/'
    endif
    let options.input = path
  endif

  call unite#start(args, options)
endfunction"}}}

command! -nargs=? -complete=customlist,unite#complete#buffer_name
      \ UniteResume call s:call_unite_resume(<q-args>)
function! s:call_unite_resume(args) "{{{
  let [args, options] = unite#helper#parse_options(a:args)

  call unite#resume(join(args), options)
endfunction"}}}

command! -nargs=1 -complete=customlist,unite#complete#buffer_name
      \ UniteClose call unite#view#_close(<q-args>)

let g:loaded_unite = 1

let &cpo = s:save_cpo
unlet s:save_cpo

" __END__
" vim: foldmethod=marker
