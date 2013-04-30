"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 30 Apr 2013.
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

" Obsolute options check. "{{{
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
let g:unite_enable_ignore_case =
      \ get(g:, 'unite_enable_ignore_case', &ignorecase)
let g:unite_enable_smart_case =
      \ get(g:, 'unite_enable_smart_case', &infercase)
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
let g:unite_force_overwrite_statusline =
      \ get(g:, 'unite_force_overwrite_statusline', 1)
let g:unite_data_directory =
      \ substitute(substitute(fnamemodify(get(
      \   g:, 'unite_data_directory', '~/.unite'),
      \  ':p'), '\\', '/', 'g'), '/$', '', '')
if !isdirectory(g:unite_data_directory)
  call mkdir(g:unite_data_directory)
endif
"}}}

" Wrapper command.
command! -nargs=+ -complete=customlist,unite#complete_source
      \ Unite
      \ call s:call_unite_empty(<q-args>)
function! s:call_unite_empty(args) "{{{
  let [args, options] = s:parse_options_args(a:args)
  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete_source
      \ UniteWithCurrentDir
      \ call s:call_unite_current_dir(<q-args>)
function! s:call_unite_current_dir(args) "{{{
  let [args, options] = s:parse_options_args(a:args)
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

command! -nargs=+ -complete=customlist,unite#complete_source
      \ UniteWithBufferDir
      \ call s:call_unite_buffer_dir(<q-args>)
function! s:call_unite_buffer_dir(args) "{{{
  let [args, options] = s:parse_options_args(a:args)
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

command! -nargs=+ -complete=customlist,unite#complete_source
      \ UniteWithCursorWord call s:call_unite_cursor_word(<q-args>)
function! s:call_unite_cursor_word(args) "{{{
  let [args, options] = s:parse_options_args(a:args)
  if !has_key(options, 'input')
    let options.input = expand('<cword>')
  endif

  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete_source
      \ UniteWithInput call s:call_unite_input(<q-args>)
function! s:call_unite_input(args) "{{{
  let [args, options] = s:parse_options_args(a:args)
  if !has_key(options, 'input')
    let options.input = input('Input narrowing text: ', '')
  endif

  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete_source
      \ UniteWithInputDirectory call s:call_unite_input_directory(<q-args>)
function! s:call_unite_input_directory(args) "{{{
  let [args, options] = s:parse_options_args(a:args)
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

command! -nargs=? -complete=customlist,unite#complete_buffer_name
      \ UniteResume call s:call_unite_resume(<q-args>)
function! s:call_unite_resume(args) "{{{
  let [args, options] = s:parse_options(a:args)

  call unite#resume(join(args), options)
endfunction"}}}

command! -nargs=1 -complete=customlist,unite#complete_buffer_name
      \ UniteClose call unite#close(<q-args>)

function! s:parse_options(args) "{{{
  let args = []
  let options = {}
  for arg in split(a:args, '\%(\\\@<!\s\)\+')
    let arg = substitute(arg, '\\\( \)', '\1', 'g')

    let arg_key = substitute(arg, '=\zs.*$', '', '')
    let matched_list = filter(copy(unite#get_options()),
          \  'v:val ==# arg_key')
    for option in matched_list
      let key = substitute(substitute(option, '-', '_', 'g'), '=$', '', '')[1:]
      let options[key] = (option =~ '=$') ?
            \ arg[len(option) :] : 1
    endfor

    if empty(matched_list)
      call add(args, arg)
    endif
  endfor

  return [args, options]
endfunction"}}}
function! s:parse_options_args(args) "{{{
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

augroup plugin-unite
  autocmd!
  autocmd CursorHold * call unite#_on_cursor_hold()
augroup END

let g:loaded_unite = 1

let &cpo = s:save_cpo
unlet s:save_cpo

" __END__
" vim: foldmethod=marker
