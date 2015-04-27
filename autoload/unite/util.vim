"=============================================================================
" FILE: util.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
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

function! unite#util#get_vital() "{{{
  if !exists('s:V')
    let s:V = vital#of('unite')
  endif
  return s:V
endfunction"}}}

function! s:get_prelude() "{{{
  if !exists('s:Prelude')
    let s:Prelude = unite#util#get_vital().import('Prelude')
  endif
  return s:Prelude
endfunction"}}}
function! s:get_list() "{{{
  if !exists('s:List')
    let s:List = unite#util#get_vital().import('Data.List')
  endif
  return s:List
endfunction"}}}
function! s:get_string() "{{{
  if !exists('s:String')
    let s:String = unite#util#get_vital().import('Data.String')
  endif
  return s:String
endfunction"}}}
function! s:get_message() "{{{
  if !exists('s:Message')
    let s:Message = unite#util#get_vital().import('Vim.Message')
  endif
  return s:Message
endfunction"}}}
function! s:get_system() "{{{
  if !exists('s:System')
    let s:System = unite#util#get_vital().import('System.File')
  endif
  return s:System
endfunction"}}}
function! s:get_process() "{{{
  if !exists('s:Process')
    let s:Process = unite#util#get_vital().import('Process')
  endif
  return s:Process
endfunction"}}}

" TODO use vital's
let s:is_windows = has('win16') || has('win32') || has('win64')

function! unite#util#truncate_smart(...)
  return call(s:get_string().truncate_skipping, a:000)
endfunction
function! unite#util#truncate(...)
  return call(s:get_string().truncate, a:000)
endfunction
function! unite#util#strchars(...)
  return call(s:get_string().strchars, a:000)
endfunction
function! unite#util#strwidthpart(...)
  return call(s:get_string().strwidthpart, a:000)
endfunction
function! unite#util#strwidthpart_reverse(...)
  return call(s:get_string().strwidthpart_reverse, a:000)
endfunction
function! unite#util#wcswidth(string)
  return strwidth(a:string)
endfunction
function! unite#util#is_win(...)
  echoerr 'unite#util#is_win() is deprecated. use unite#util#is_windows() instead.'
  return call(s:get_prelude().is_windows, a:000)
endfunction
function! unite#util#is_windows(...)
  return call(s:get_prelude().is_windows, a:000)
endfunction
function! unite#util#is_mac(...)
  return call(s:get_prelude().is_mac, a:000)
endfunction
function! unite#util#print_error(...)
  return call(s:get_message().error, a:000)
endfunction
function! unite#util#smart_execute_command(action, word)
  execute a:action . ' ' . fnameescape(a:word)
endfunction
function! unite#util#smart_open_command(action, word)
  call unite#util#smart_execute_command(a:action, a:word)

  call unite#remove_previewed_buffer_list(bufnr(a:word))
endfunction
function! unite#util#escape_file_searching(buffer_name)
  " You should not escape for buflisted() or bufnr()
  return a:buffer_name
endfunction
function! unite#util#escape_pattern(...)
  return call(s:get_prelude().escape_pattern, a:000)
endfunction
function! unite#util#set_default(var, val, ...)  "{{{
  if !exists(a:var) || type({a:var}) != type(a:val)
    let alternate_var = get(a:000, 0, '')

    let {a:var} = exists(alternate_var) ?
          \ {alternate_var} : a:val
  endif
endfunction"}}}

if unite#util#is_windows()
  function! unite#util#substitute_path_separator(...)
    return call(s:get_prelude().substitute_path_separator, a:000)
  endfunction
else
  function! unite#util#substitute_path_separator(path)
    return a:path
  endfunction
endif

function! unite#util#path2directory(...)
  return call(s:get_prelude().path2directory, a:000)
endfunction
function! unite#util#path2project_directory(...)
  return call(s:get_prelude().path2project_directory, a:000)
endfunction
function! unite#util#has_vimproc(...)
  return call(s:get_process().has_vimproc, a:000)
endfunction
function! unite#util#has_lua()
  " Note: Disabled if_lua feature if less than 7.3.885.
  " Because if_lua has double free problem.
  " Note: Cannot use lua interface in Windows environment if encoding is not utf-8.
  " https://github.com/Shougo/unite.vim/issues/466
  return has('lua') && (v:version > 703 || v:version == 703 && has('patch885'))
        \ && (!unite#util#is_windows() ||
        \     &encoding ==# 'utf-8' || &encoding ==# 'latin1')
endfunction
function! unite#util#system(...)
  return call(s:get_process().system, a:000)
endfunction
function! unite#util#system_passwd(...)
  return call((unite#util#has_vimproc() ?
        \ 'vimproc#system_passwd' : 'system'), a:000)
endfunction
function! unite#util#get_last_status(...)
  return call(s:get_process().get_last_status, a:000)
endfunction
function! unite#util#get_last_errmsg()
  return unite#util#has_vimproc() ? vimproc#get_last_errmsg() : ''
endfunction
function! unite#util#sort_by(...)
  return call(s:get_list().sort_by, a:000)
endfunction
function! unite#util#uniq(...)
  return call(s:get_list().uniq, a:000)
endfunction
function! unite#util#uniq_by(...)
  return call(s:get_list().uniq_by, a:000)
endfunction
function! unite#util#input(prompt, ...) "{{{
  let context = unite#get_context()
  let prompt = a:prompt
  let default = get(a:000, 0, '')
  let completion = get(a:000, 1, '')
  let source_name = get(a:000, 2, '')
  if source_name != ''
    let prompt = printf('[%s] %s', source_name, prompt)
  endif

  let args = [prompt, default]
  if completion != ''
    call add(args, completion)
  endif

  return context.unite__is_interactive ? call('input', args) : default
endfunction"}}}
function! unite#util#input_yesno(message) "{{{
  let yesno = input(a:message . ' [yes/no]: ')
  while yesno !~? '^\%(y\%[es]\|n\%[o]\)$'
    redraw
    if yesno == ''
      echo 'Canceled.'
      break
    endif

    " Retry.
    call unite#print_error('Invalid input.')
    let yesno = input(a:message . ' [yes/no]: ')
  endwhile

  redraw

  return yesno =~? 'y\%[es]'
endfunction"}}}
function! unite#util#input_directory(message) "{{{
  echo a:message
  let dir = unite#util#substitute_path_separator(
        \ unite#util#expand(input('', '', 'dir')))
  while !isdirectory(dir)
    redraw
    if dir == ''
      echo 'Canceled.'
      break
    endif

    " Retry.
    call unite#print_error('Invalid path.')
    echo a:message
    let dir = unite#util#substitute_path_separator(
          \ unite#util#expand(input('', '', 'dir')))
  endwhile

  return dir
endfunction"}}}
function! unite#util#iconv(...)
  return call(s:get_process().iconv, a:000)
endfunction

function! unite#util#alternate_buffer() "{{{
  let unite = unite#get_current_unite()
  if s:buflisted(unite.prev_bufnr)
    execute 'buffer' unite.prev_bufnr
    return
  endif

  let listed_buffer_len = len(filter(range(1, bufnr('$')),
        \ 's:buflisted(v:val) && getbufvar(v:val, "&filetype") !=# "unite"'))
  if listed_buffer_len <= 1
    enew
    return
  endif

  let cnt = 0
  let pos = 1
  let current = 0
  while pos <= bufnr('$')
    if s:buflisted(pos)
      if pos == bufnr('%')
        let current = cnt
      endif

      let cnt += 1
    endif

    let pos += 1
  endwhile

  if current > cnt / 2
    bprevious
  else
    bnext
  endif
endfunction"}}}
function! unite#util#is_cmdwin() "{{{
  return bufname('%') ==# '[Command Line]'
endfunction"}}}
function! s:buflisted(bufnr) "{{{
  return (getbufvar(a:bufnr, '&bufhidden') == '' || buflisted(a:bufnr)) &&
        \ (exists('t:tabpagebuffer') ?
        \   has_key(t:tabpagebuffer, a:bufnr) && bufloaded(a:bufnr) :
        \   bufloaded(a:bufnr))
endfunction"}}}

function! unite#util#glob(pattern, ...) "{{{
  let is_force_glob = get(a:000, 0, 1)

  if !is_force_glob && (a:pattern =~ '\*$' || a:pattern == '*')
        \ && unite#util#has_vimproc() && exists('*vimproc#readdir')
    return vimproc#readdir(a:pattern[: -2])
  else
    " Escape [.
    let glob = escape(a:pattern, '?={}[]')
    let glob2 = escape(substitute(a:pattern,
          \ '[^/]*$', '', '') . '.*', '?={}[]')

    return unite#util#uniq(split(unite#util#substitute_path_separator(glob(glob)), '\n')
          \ + split(unite#util#substitute_path_separator(glob(glob2)), '\n'))
  endif
endfunction"}}}
function! unite#util#command_with_restore_cursor(command) "{{{
  let pos = getpos('.')
  let current = winnr()

  execute a:command
  let next = winnr()

  " Restore cursor.
  execute current 'wincmd w'
  call setpos('.', pos)

  execute next 'wincmd w'
endfunction"}}}
function! unite#util#expand(path) "{{{
  return s:get_prelude().substitute_path_separator(
        \ (a:path =~ '^\~') ? fnamemodify(a:path, ':p') :
        \ (a:path =~ '^\$\h\w*') ? substitute(a:path,
        \               '^\$\h\w*', '\=eval(submatch(0))', '') :
        \ a:path)
endfunction"}}}
function! unite#util#set_default_dictionary_helper(variable, keys, value) "{{{
  for key in split(a:keys, '\s*,\s*')
    if !has_key(a:variable, key)
      let a:variable[key] = a:value
    endif
  endfor
endfunction"}}}
function! unite#util#set_dictionary_helper(variable, keys, value) "{{{
  for key in split(a:keys, '\s*,\s*')
    let a:variable[key] = a:value
  endfor
endfunction"}}}

function! unite#util#convert2list(expr) "{{{
  return type(a:expr) ==# type([]) ? a:expr : [a:expr]
endfunction"}}}

function! unite#util#truncate_wrap(str, max, footer_width, separator) "{{{
  let width = strwidth(a:str)
  if width <= a:max
    return unite#util#truncate(a:str, a:max)
  elseif &l:wrap
    return a:str
  endif

  let header_width = a:max - strwidth(a:separator) - a:footer_width
  return unite#util#strwidthpart(a:str, header_width) . a:separator
        \ . unite#util#strwidthpart_reverse(a:str, a:footer_width)
endfunction"}}}

function! unite#util#index_name(list, name) "{{{
  return index(map(copy(a:list), 'v:val.name'), a:name)
endfunction"}}}
function! unite#util#get_name(list, name, default) "{{{
  return get(a:list, unite#util#index_name(a:list, a:name), a:default)
endfunction"}}}

function! unite#util#escape_match(str) "{{{
  return substitute(substitute(escape(a:str, '~\.^$[]'),
        \ '\*\@<!\*\*\@!', '[^/]*', 'g'), '\*\*\+', '.*', 'g')
endfunction"}}}

function! unite#util#escape_shell(str) "{{{
  return '"' . a:str . '"'
endfunction"}}}

function! unite#util#open(path) "{{{
  return s:get_system().open(a:path)
endfunction"}}}

function! unite#util#move(src, dest) "{{{
  return s:get_system().move(a:src, a:dest)
endfunction"}}}

function! unite#util#read_lines(source, ...) "{{{
  let timeout = get(a:000, 0, -1)
  if timeout < 0
    return a:source.read_lines(-1, timeout)
  endif

  let lines = []
  for _ in range(timeout / 100)
    let lines += a:source.read_lines(-1, 100)
  endfor
  return lines
endfunction"}}}

function! unite#util#is_sudo() "{{{
  return $SUDO_USER != '' && $USER !=# $SUDO_USER
        \ && $HOME !=# expand('~'.$USER)
        \ && $HOME ==# expand('~'.$SUDO_USER)
endfunction"}}}

function! unite#util#lcd(dir) "{{{
  if isdirectory(a:dir)
    execute 'lcd' fnameescape(a:dir)
  endif
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

