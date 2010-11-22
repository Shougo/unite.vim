"=============================================================================
" FILE: util.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 22 Nov 2010
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

" Original function is from mattn.
" http://github.com/mattn/googlereader-vim/tree/master

function! unite#util#truncate_smart(str, max, footer_width, separator)"{{{
  let width = unite#util#wcswidth(a:str)
  if width <= a:max
    let ret = a:str
  else
    let header_width = a:max - unite#util#wcswidth(a:separator) - a:footer_width
    let ret = unite#util#strwidthpart(a:str, header_width) . a:separator
          \ . unite#util#strwidthpart_reverse(a:str, a:footer_width)
  endif
   
  return unite#util#truncate(ret, a:max)
endfunction"}}}

function! unite#util#truncate(str, width)"{{{
  let ret = a:str
  let width = unite#util#wcswidth(a:str)
  if width > a:width
    let ret = unite#util#strwidthpart(ret, a:width)
    let width = unite#util#wcswidth(ret)
  endif

  if width < a:width
    let ret .= repeat(' ', a:width - width)
  endif

  return ret
endfunction"}}}

function! unite#util#strchars(str)"{{{
  return len(substitute(a:str, '.', 'x', 'g'))
endfunction"}}}

if v:version >= 703
  " Use builtin function.

  function! unite#util#strwidthpart(str, width)"{{{
    let ret = a:str
    let width = strwidth(a:str)
    while width > a:width
      let char = matchstr(ret, '.$')
      let ret = ret[: -1 - len(char)]
      let width -= strwidth(char)
    endwhile

    return ret
  endfunction"}}}
  function! unite#util#strwidthpart_reverse(str, width)"{{{
    let ret = a:str
    let width = strwidth(a:str)
    while width > a:width
      let char = matchstr(ret, '^.')
      let ret = ret[len(char) :]
      let width -= strwidth(char)
    endwhile

    return ret
  endfunction"}}}

  function! unite#util#wcswidth(str)"{{{
    return strwidth(a:str)
  endfunction"}}}
else
  function! unite#util#strwidthpart(str, width)"{{{
    let ret = a:str
    let width = unite#util#wcswidth(a:str)
    while width > a:width
      let char = matchstr(ret, '.$')
      let ret = ret[: -1 - len(char)]
      let width -= s:wcwidth(char)
    endwhile

    return ret
  endfunction"}}}
  function! unite#util#strwidthpart_reverse(str, width)"{{{
    let ret = a:str
    let width = unite#util#wcswidth(a:str)
    while width > a:width
      let char = matchstr(ret, '^.')
      let ret = ret[len(char) :]
      let width -= s:wcwidth(char)
    endwhile

    return ret
  endfunction"}}}

  function! unite#util#wcswidth(str)"{{{
    let mx_first = '^\(.\)'
    let str = a:str
    let width = 0
    while 1
      let ucs = char2nr(substitute(str, mx_first, '\1', ''))
      if ucs == 0
        break
      endif
      let width += s:wcwidth(ucs)
      let str = substitute(str, mx_first, '', '')
    endwhile
    return width
  endfunction"}}}

  " UTF-8 only.
  function! s:wcwidth(ucs)"{{{
    let ucs = a:ucs
    if (ucs >= 0x1100
          \  && (ucs <= 0x115f
          \  || ucs == 0x2329
          \  || ucs == 0x232a
          \  || (ucs >= 0x2e80 && ucs <= 0xa4cf
          \      && ucs != 0x303f)
          \  || (ucs >= 0xac00 && ucs <= 0xd7a3)
          \  || (ucs >= 0xf900 && ucs <= 0xfaff)
          \  || (ucs >= 0xfe30 && ucs <= 0xfe6f)
          \  || (ucs >= 0xff00 && ucs <= 0xff60)
          \  || (ucs >= 0xffe0 && ucs <= 0xffe6)
          \  || (ucs >= 0x20000 && ucs <= 0x2fffd)
          \  || (ucs >= 0x30000 && ucs <= 0x3fffd)
          \  ))
      return 2
    endif
    return 1
  endfunction"}}}
endif

function! unite#util#is_win()"{{{
  return has('win16') || has('win32') || has('win64')
endfunction"}}}

function! unite#util#print_error(message)"{{{
  echohl WarningMsg | echomsg a:message | echohl None
endfunction"}}}

function! unite#util#smart_execute_command(action, word)
  execute a:action . ' ' . (a:word == '' ? '' : '`=a:word`')
endfunction

function! unite#util#escape_file_searching(buffer_name)"{{{
  return escape(a:buffer_name, '*[]?{},')
endfunction"}}}

function! unite#util#set_default(var, val)  "{{{
  if !exists(a:var) || type({a:var}) != type(a:val)
    let {a:var} = a:val
  endif
endfunction"}}}
function! unite#util#set_dictionary_helper(variable, keys, pattern)"{{{
  for key in split(a:keys, ',')
    if !has_key(a:variable, key)
      let a:variable[key] = a:pattern
    endif
  endfor
endfunction"}}}
function! unite#util#substitute_path_separator(path)"{{{
  return unite#util#is_win() ? substitute(a:path, '\\', '/', 'g') : a:path
endfunction"}}}
function! unite#util#path2directory(path)"{{{
  return unite#util#substitute_path_separator(isdirectory(a:path) ? a:path : fnamemodify(a:path, ':p:h'))
endfunction"}}}

" Check vimproc."{{{
try
  let s:exists_vimproc_version = vimproc#version()
catch
  let s:exists_vimproc_version = 0
endtry
"}}}
function! unite#util#system(str, ...)"{{{
  let l:command = a:str
  let l:input = a:0 >= 1 ? a:1 : ''
  if &termencoding != '' && &termencoding != &encoding
    let l:command = iconv(l:command, &encoding, &termencoding)
    let l:input = iconv(l:input, &encoding, &termencoding)
  endif

  if a:0 == 0
    let l:output = s:exists_vimproc_version ?
          \ vimproc#system(l:command) : system(l:command)
  else
    let l:output = s:exists_vimproc_version ?
          \ vimproc#system(l:command, l:input) : system(l:command, l:input)
  endif

  if &termencoding != '' && &termencoding != &encoding
    let l:output = iconv(l:output, &termencoding, &encoding)
  endif

  return l:output
endfunction"}}}
function! unite#util#get_last_status()"{{{
  return s:exists_vimproc_version ?
        \ vimproc#get_last_status() : v:shell_error
endfunction"}}}

" vim: foldmethod=marker
