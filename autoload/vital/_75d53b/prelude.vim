
" glob() wrapper which returns List.
function! s:glob(...)
    let R = call('glob', a:000)
    return split(R, '\n')
endfunction
" globpath() wrapper which returns List.
function! s:globpath(...)
    let R = call('globpath', a:000)
    return split(R, '\n')
endfunction

" Wrapper functions for type().
let [
\   s:__TYPE_NUMBER,
\   s:__TYPE_STRING,
\   s:__TYPE_FUNCREF,
\   s:__TYPE_LIST,
\   s:__TYPE_DICT,
\   s:__TYPE_FLOAT
\] = [
\   type(3),
\   type(""),
\   type(function('tr')),
\   type([]),
\   type({}),
\   type(3.14159)
\]
" Number or Float
function! s:is_numeric(Value)
    let _ = type(a:Value)
    return _ ==# s:__TYPE_NUMBER
    \   || _ ==# s:__TYPE_FLOAT
endfunction
" Number
function! s:is_integer(Value)
    return type(a:Value) ==# s:__TYPE_NUMBER
endfunction
function! s:is_number(Value)
    return type(a:Value) ==# s:__TYPE_NUMBER
endfunction
" Float
function! s:is_float(Value)
    return type(a:Value) ==# s:__TYPE_FLOAT
endfunction
" String
function! s:is_string(Value)
    return type(a:Value) ==# s:__TYPE_STRING
endfunction
" Funcref
function! s:is_funcref(Value)
    return type(a:Value) ==# s:__TYPE_FUNCREF
endfunction
" List
function! s:is_list(Value)
    return type(a:Value) ==# s:__TYPE_LIST
endfunction
" Dictionary
function! s:is_dict(Value)
    return type(a:Value) ==# s:__TYPE_DICT
endfunction

function! s:truncate_smart(str, max, footer_width, separator)"{{{
  let width = s:wcswidth(a:str)
  if width <= a:max
    let ret = a:str
  else
    let header_width = a:max - s:wcswidth(a:separator) - a:footer_width
    let ret = s:strwidthpart(a:str, header_width) . a:separator
          \ . s:strwidthpart_reverse(a:str, a:footer_width)
  endif

  return s:truncate(ret, a:max)
endfunction"}}}

function! s:truncate(str, width)"{{{
  " Original function is from mattn.
  " http://github.com/mattn/googlereader-vim/tree/master

  if a:str =~# '^[\x00-\x7f]*$'
    return len(a:str) < a:width ?
          \ printf('%-'.a:width.'s', a:str) : strpart(a:str, 0, a:width)
  endif

  let ret = a:str
  let width = s:wcswidth(a:str)
  if width > a:width
    let ret = s:strwidthpart(ret, a:width)
    let width = s:wcswidth(ret)
  endif

  if width < a:width
    let ret .= repeat(' ', a:width - width)
  endif

  return ret
endfunction"}}}

function! s:strchars(str)"{{{
  return len(substitute(a:str, '.', 'x', 'g'))
endfunction"}}}

function! s:strwidthpart(str, width)"{{{
  let ret = a:str
  let width = s:wcswidth(a:str)
  while width > a:width
    let char = matchstr(ret, '.$')
    let ret = ret[: -1 - len(char)]
    let width -= s:wcswidth(char)
  endwhile

  return ret
endfunction"}}}
function! s:strwidthpart_reverse(str, width)"{{{
  let ret = a:str
  let width = s:wcswidth(a:str)
  while width > a:width
    let char = matchstr(ret, '^.')
    let ret = ret[len(char) :]
    let width -= s:wcswidth(char)
  endwhile

  return ret
endfunction"}}}

if v:version >= 703
  " Use builtin function.
  function! s:wcswidth(str)"{{{
    return strwidth(a:str)
  endfunction"}}}
else
  function! s:wcswidth(str)"{{{
    if a:str =~# '^[\x00-\x7f]*$'
      return strlen(a:str)
    end

    let mx_first = '^\(.\)'
    let str = a:str
    let width = 0
    while 1
      let ucs = char2nr(substitute(str, mx_first, '\1', ''))
      if ucs == 0
        break
      endif
      let width += s:_wcwidth(ucs)
      let str = substitute(str, mx_first, '', '')
    endwhile
    return width
  endfunction"}}}

  " UTF-8 only.
  function! s:_wcwidth(ucs)"{{{
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

let s:is_windows = has('win16') || has('win32') || has('win64')
let s:is_cygwin = has('win32unix')
let s:is_mac = !s:is_windows && (has('mac') || has('macunix') || has('gui_macvim') || system('uname') =~? '^darwin')
function! s:is_windows()"{{{
  return s:is_windows
endfunction"}}}
function! s:is_cygwin()"{{{
  return s:is_cygwin
endfunction"}}}
function! s:is_mac()"{{{
  return s:is_mac
endfunction"}}}

function! s:print_error(message)"{{{
  echohl ErrorMsg
  for m in split(a:message, "\n")
    echomsg m
  endfor
  echohl None
endfunction"}}}

function! s:smart_execute_command(action, word)"{{{
  execute a:action . ' ' . (a:word == '' ? '' : '`=a:word`')
endfunction"}}}

function! s:escape_file_searching(buffer_name)"{{{
  return escape(a:buffer_name, '*[]?{},')
endfunction"}}}
function! s:escape_pattern(str)"{{{
  return escape(a:str, '~"\.^$[]*')
endfunction"}}}
" iconv() wrapper for safety.
function! s:iconv(expr, from, to)
  if a:from == '' || a:to == '' || a:from ==? a:to
    return a:expr
  endif
  let result = iconv(a:expr, a:from, a:to)
  return result != '' ? result : a:expr
endfunction
" Like builtin getchar() but returns string always.
function! s:getchar(...)
  let c = call('getchar', a:000)
  return type(c) == type(0) ? nr2char(c) : c
endfunction
" Like builtin getchar() but returns string always.
" and do inputsave()/inputrestore() before/after getchar().
function! s:getchar_safe(...)
  let c = s:input_helper('getchar', a:000)
  return type(c) == type("") ? c : nr2char(c)
endfunction
" Like builtin getchar() but
" do inputsave()/inputrestore() before/after input().
function! s:input_safe(...)
    return s:input_helper('input', a:000)
endfunction
" Do inputsave()/inputrestore() before/after calling a:funcname.
function! s:input_helper(funcname, args)
    let success = 0
    if inputsave() !=# success
        throw 'inputsave() failed'
    endif
    try
        return call(a:funcname, a:args)
    finally
        if inputrestore() !=# success
            throw 'inputrestore() failed'
        endif
    endtry
endfunction

function! s:set_default(var, val)  "{{{
  if !exists(a:var) || type({a:var}) != type(a:val)
    let {a:var} = a:val
  endif
endfunction"}}}
function! s:set_dictionary_helper(variable, keys, pattern)"{{{
  for key in split(a:keys, ',')
    if !has_key(a:variable, key)
      let a:variable[key] = a:pattern
    endif
  endfor
endfunction"}}}
function! s:substitute_path_separator(path)"{{{
  return s:is_windows ? substitute(a:path, '\\', '/', 'g') : a:path
endfunction"}}}
function! s:path2directory(path)"{{{
  return s:substitute_path_separator(isdirectory(a:path) ? a:path : fnamemodify(a:path, ':p:h'))
endfunction"}}}
function! s:path2project_directory(path)"{{{
  let search_directory = s:path2directory(a:path)
  let directory = ''

  " Search VCS directory.
  for d in ['.git', '.bzr', '.hg']
    let d = finddir(d, s:escape_file_searching(search_directory) . ';')
    if d != ''
      let directory = fnamemodify(d, ':p:h:h')
      break
    endif
  endfor

  " Search project file.
  if directory == ''
    for d in ['build.xml', 'prj.el', '.project', 'pom.xml', 'Makefile', 'configure', 'Rakefile', 'NAnt.build', 'tags', 'gtags']
      let d = findfile(d, s:escape_file_searching(search_directory) . ';')
      if d != ''
        let directory = fnamemodify(d, ':p:h')
        break
      endif
    endfor
  endif

  if directory == ''
    " Search /src/ directory.
    let base = s:substitute_path_separator(search_directory)
    if base =~# '/src/'
      let directory = base[: strridx(base, '/src/') + 3]
    endif
  endif

  if directory == ''
    let directory = search_directory
  endif

  return s:substitute_path_separator(directory)
endfunction"}}}
" Check vimproc."{{{
let s:exists_vimproc = globpath(&rtp, 'autoload/vimproc.vim') != ''
"}}}
function! s:has_vimproc()"{{{
  return s:exists_vimproc
endfunction"}}}
function! s:system(str, ...)"{{{
  let command = a:str
  let input = a:0 >= 1 ? a:1 : ''
  if &termencoding != '' && &termencoding != &encoding
    let command = s:iconv(command, &encoding, &termencoding)
    let input = s:iconv(input, &encoding, &termencoding)
  endif

  if a:0 == 0
    let output = s:has_vimproc() ?
          \ vimproc#system(command) : system(command)
  elseif a:0 == 1
    let output = s:has_vimproc() ?
          \ vimproc#system(command, input) : system(command, input)
  else
    " ignores 3rd argument unless you have vimproc.
    let output = s:has_vimproc() ?
          \ vimproc#system(command, input, a:2) : system(command, input)
  endif

  if &termencoding != '' && &termencoding != &encoding
    let output = s:iconv(output, &termencoding, &encoding)
  endif

  return output
endfunction"}}}
function! s:get_last_status()"{{{
  return s:has_vimproc() ?
        \ vimproc#get_last_status() : v:shell_error
endfunction"}}}
" vim: foldmethod=marker
