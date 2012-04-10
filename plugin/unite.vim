"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 10 Apr 2012.
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
" Version: 3.1, for Vim 7.2
"=============================================================================

if exists('g:loaded_unite')
  finish
elseif v:version < 702
  echoerr 'unite.vim does not work this version of Vim "' . v:version . '".'
  finish
elseif $SUDO_USER != '' && $USER !=# $SUDO_USER
      \ && $HOME !=# expand('~'.$USER)
  echoerr '"sudo vim" and $HOME is not same to /root are detected.'
        \.'Please use sudo.vim plugin instead of sudo command or set always_set_home in sudoers.'
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
let g:unite_update_time =
      \ get(g:, 'unite_update_time', 500)
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
      \     'a' : 1, 's' : 2, 'd' : 3, 'f' : 4, 'g' : 5, 'h' : 6, 'j' : 7, 'k' : 8, 'l' : 9, ';' : 10,
      \     'q' : 11, 'w' : 12, 'e' : 13, 'r' : 14, 't' : 15, 'y' : 16, 'u' : 17, 'i' : 18, 'o' : 19, 'p' : 20,
      \     '1' : 21, '2' : 22, '3' : 23, '4' : 24, '5' : 25, '6' : 26, '7' : 27, '8' : 28, '9' : 29, '0' : 30,
      \ })
let g:unite_abbr_highlight =
      \ get(g:, 'unite_abbr_highlight', 'Normal')
let g:unite_cursor_line_highlight =
      \ get(g:, 'unite_cursor_line_highlight', 'PmenuSel')
let g:unite_data_directory =
      \ substitute(fnamemodify(get(
      \   g:, 'unite_data_directory', '~/.unite'),
      \  ':p'), '\\', '/', 'g')
if !isdirectory(g:unite_data_directory)
  call mkdir(g:unite_data_directory)
endif
"}}}

" Wrapper command.
command! -nargs=+ -complete=customlist,unite#complete_source Unite
      \ call s:call_unite_empty(<q-args>)
function! s:call_unite_empty(args)"{{{
  let [args, options] = s:parse_options_args(a:args)
  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete_source UniteWithCurrentDir
      \ call s:call_unite_current_dir(<q-args>)
function! s:call_unite_current_dir(args)"{{{
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

command! -nargs=+ -complete=customlist,unite#complete_source UniteWithBufferDir
      \ call s:call_unite_buffer_dir(<q-args>)
function! s:call_unite_buffer_dir(args)"{{{
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
function! s:call_unite_cursor_word(args)"{{{
  let [args, options] = s:parse_options_args(a:args)
  if !has_key(options, 'input')
    let options.input = expand('<cword>')
  endif

  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete_source
      \ UniteWithInput call s:call_unite_input(<q-args>)
function! s:call_unite_input(args)"{{{
  let [args, options] = s:parse_options_args(a:args)
  if !has_key(options, 'input')
    let options.input = input('Input narrowing text: ', '')
  endif

  call unite#start(args, options)
endfunction"}}}

command! -nargs=+ -complete=customlist,unite#complete_source
      \ UniteWithInputDirectory call s:call_unite_input_directory(<q-args>)
function! s:call_unite_input_directory(args)"{{{
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

command! -nargs=? -complete=customlist,unite#complete_buffer_name UniteResume call s:call_unite_resume(<q-args>)
function! s:call_unite_resume(args)"{{{
  let [args, options] = s:parse_options(a:args)

  call unite#resume(join(args), options)
endfunction"}}}

command! -nargs=1 -complete=customlist,unite#complete_buffer_name UniteClose call unite#close(<q-args>)

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

augroup plugin-unite
  autocmd!
  autocmd CursorHold * call unite#_on_cursor_hold()
augroup END

let g:loaded_unite = 1

let &cpo = s:save_cpo
unlet s:save_cpo

" __END__
" vim: foldmethod=marker
