"=============================================================================
" FILE: unite.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
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
elseif v:version < 703
  echoerr 'unite.vim does not work this version of Vim "' . v:version . '".'
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

" Wrapper command.
command! -nargs=* -range -complete=customlist,unite#complete#source
      \ Unite
      \ call s:call_unite('Unite', <q-args>, <line1>, <line2>)

command! -nargs=* -range -complete=customlist,unite#complete#source
      \ UniteWithCurrentDir
      \ call s:call_unite('UniteWithCurrentDir', <q-args>, <line1>, <line2>)

command! -nargs=* -range -complete=customlist,unite#complete#source
      \ UniteWithBufferDir
      \ call s:call_unite('UniteWithBufferDir', <q-args>, <line1>, <line2>)

command! -nargs=* -range -complete=customlist,unite#complete#source
      \ UniteWithProjectDir
      \ call s:call_unite('UniteWithProjectDir', <q-args>, <line1>, <line2>)

command! -nargs=* -range -complete=customlist,unite#complete#source
      \ UniteWithInputDirectory
      \ call s:call_unite('UniteWithInputDirectory', <q-args>, <line1>, <line2>)

command! -nargs=* -range -complete=customlist,unite#complete#source
      \ UniteWithCursorWord
      \ call s:call_unite('UniteWithCursorWord', <q-args>, <line1>, <line2>)

command! -nargs=* -range -complete=customlist,unite#complete#source
      \ UniteWithInput
      \ call s:call_unite('UniteWithInput', <q-args>, <line1>, <line2>)

command! -nargs=* -complete=customlist,unite#complete#buffer_name
      \ UniteResume
      \ call s:call_unite_resume(<q-args>)

command! -nargs=? -bar -complete=customlist,unite#complete#buffer_name
      \ UniteClose call unite#view#_close(<q-args>)

command! -count=1 -bar -nargs=? -complete=customlist,unite#complete#buffer_name
      \ UniteNext call unite#start#_pos(<q-args>, 'next', expand('<count>'))
command! -count=1 -bar -nargs=? -complete=customlist,unite#complete#buffer_name
      \ UnitePrevious call unite#start#_pos(<q-args>, 'previous', expand('<count>'))
command! -nargs=? -bar -complete=customlist,unite#complete#buffer_name
      \ UniteFirst call unite#start#_pos(<q-args>, 'first', 1)
command! -nargs=? -bar -complete=customlist,unite#complete#buffer_name
      \ UniteLast call unite#start#_pos(<q-args>, 'last', 1)

function! s:call_unite(command, args, line1, line2) abort "{{{
  let [args, context] = unite#helper#parse_options_user(a:args)
  if a:command ==# 'UniteWithCurrentDir'
        \ && !has_key(context, 'path')
    let path = &filetype ==# 'vimfiler' ?
          \ b:vimfiler.current_dir :
          \ unite#util#substitute_path_separator(fnamemodify(getcwd(), ':p'))
    let context.path = path
  elseif a:command ==# 'UniteWithBufferDir'
        \ && !has_key(context, 'path')
    let context.path = unite#helper#get_buffer_directory(bufnr('%'))
  elseif a:command ==# 'UniteWithProjectDir'
        \ && !has_key(context, 'path')
    let path = &filetype ==# 'vimfiler' ?
          \ b:vimfiler.current_dir :
          \ unite#util#substitute_path_separator(getcwd())
    let context.path = unite#util#path2project_directory(path)
  elseif a:command ==# 'UniteWithInputDirectory'
        \ && !has_key(context, 'path')
    let context.path = unite#helper#parse_source_path(
          \ input('Input narrowing directory: ', '', 'dir'))
  elseif a:command ==# 'UniteWithCursorWord'
        \ && !has_key(context, 'input')
    let context.input = expand('<cword>')
  elseif a:command ==# 'UniteWithInput'
        \ && !has_key(context, 'input')
    let context.input = input('Input narrowing text: ', '')
  endif

  let context.firstline = a:line1
  let context.lastline = a:line2
  let context.bufnr = bufnr('%')

  call unite#start(args, context)
endfunction"}}}
function! s:call_unite_resume(args) abort "{{{
  let [args, context] = unite#helper#parse_options(a:args)

  call unite#resume(join(args), context)
endfunction"}}}

let g:loaded_unite = 1

let &cpo = s:save_cpo
unlet s:save_cpo

" __END__
" vim: foldmethod=marker
