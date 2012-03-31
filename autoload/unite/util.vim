let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('unite.vim')
call s:V.load('Data.List')
function! unite#util#truncate_smart(...)
  return call(s:V.truncate_smart, a:000)
endfunction
function! unite#util#truncate(...)
  return call(s:V.truncate, a:000)
endfunction
function! unite#util#strchars(...)
  return call(s:V.strchars, a:000)
endfunction
function! unite#util#strwidthpart(...)
  return call(s:V.strwidthpart, a:000)
endfunction
function! unite#util#strwidthpart_reverse(...)
  return call(s:V.strwidthpart_reverse, a:000)
endfunction
function! unite#util#wcswidth(...)
  return call(s:V.wcswidth, a:000)
endfunction
function! unite#util#wcswidth(...)
  return call(s:V.wcswidth, a:000)
endfunction
function! unite#util#is_win(...)
  return call(s:V.is_windows, a:000)
endfunction
function! unite#util#is_windows(...)
  return call(s:V.is_windows, a:000)
endfunction
function! unite#util#is_mac(...)
  return call(s:V.is_mac, a:000)
endfunction
function! unite#util#print_error(...)
  return call(s:V.print_error, a:000)
endfunction
function! unite#util#smart_execute_command(...)
  return call(s:V.smart_execute_command, a:000)
endfunction
function! unite#util#escape_file_searching(...)
  return call(s:V.escape_file_searching, a:000)
endfunction
function! unite#util#escape_pattern(...)
  return call(s:V.escape_pattern, a:000)
endfunction
function! unite#util#set_default(...)
  return call(s:V.set_default, a:000)
endfunction
function! unite#util#set_dictionary_helper(...)
  return call(s:V.set_dictionary_helper, a:000)
endfunction
function! unite#util#substitute_path_separator(...)
  return call(s:V.substitute_path_separator, a:000)
endfunction
function! unite#util#path2directory(...)
  return call(s:V.path2directory, a:000)
endfunction
function! unite#util#path2project_directory(...)
  return call(s:V.path2project_directory, a:000)
endfunction
function! unite#util#has_vimproc(...)
  return call(s:V.has_vimproc, a:000)
endfunction
function! unite#util#system(...)
  return call(s:V.system, a:000)
endfunction
function! unite#util#get_last_status(...)
  return call(s:V.get_last_status, a:000)
endfunction
function! unite#util#get_last_errmsg()
  return unite#util#has_vimproc() ? vimproc#get_last_errmsg() : ''
endfunction
function! unite#util#sort_by(...)
  return call(s:V.Data.List.sort_by, a:000)
endfunction
function! unite#util#uniq(...)
  return call(s:V.Data.List.uniq, a:000)
endfunction
function! unite#util#input_yesno(message)"{{{
  let yesno = input(a:message . ' [yes/no] : ')
  while yesno !~? '^\%(y\%[es]\|n\%[o]\)$'
    redraw
    if yesno == ''
      echo 'Canceled.'
      break
    endif

    " Retry.
    call unite#print_error('Invalid input.')
    let yesno = input(a:message . ' [yes/no] : ')
  endwhile

  return yesno =~? 'y\%[es]'
endfunction"}}}
function! unite#util#input_directory(message)"{{{
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

function! unite#util#alternate_buffer()"{{{
  if bufnr('%') != bufnr('#') && s:buflisted(bufnr('#'))
    buffer #
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
function! unite#util#is_cmdwin()"{{{
  try
    noautocmd wincmd p
  catch /^Vim\%((\a\+)\)\=:E11:/
    return 1
  endtry

  silent! noautocmd wincmd p
  call unite#_resize_window()
  return 0
endfunction"}}}
function! s:buflisted(bufnr)"{{{
  return exists('t:unite_buffer_dictionary') ?
        \ has_key(t:unite_buffer_dictionary, a:bufnr) && buflisted(a:bufnr) :
        \ buflisted(a:bufnr)
endfunction"}}}

function! unite#util#glob(pattern, ...)"{{{
  " let is_force_glob = get(a:000, 0, 0)
  let is_force_glob = get(a:000, 0, 1)

  if !is_force_glob && a:pattern =~ '^[^\\*]\+/\*'
        \ && unite#util#has_vimproc() && exists('*vimproc#readdir')
    return vimproc#readdir(a:pattern[: -2])
  else
    " Escape [.
    let glob = escape(a:pattern, unite#util#is_windows() ?  '?"={}' : '?"={}[]')

    return split(unite#util#substitute_path_separator(glob(glob)), '\n')
  endif
endfunction"}}}
function! unite#util#command_with_restore_cursor(command)
  let pos = getpos('.')
  let current = winnr()

  execute a:command
  let next = winnr()

  " Restore cursor.
  execute current 'wincmd w'
  call setpos('.', pos)

  execute next 'wincmd w'
endfunction
function! unite#util#expand(path)"{{{
  return s:V.substitute_path_separator(
        \ (a:path =~ '^\~') ? substitute(a:path, '^\~', expand('~'), '') :
        \ (a:path =~ '^\$\h\w*') ? substitute(a:path,
        \               '^\$\h\w*', '\=eval(submatch(0))', '') :
        \ a:path)
endfunction"}}}
function! unite#util#set_default_dictionary_helper(variable, keys, value)"{{{
  for key in split(a:keys, '\s*,\s*')
    if !has_key(a:variable, key)
      let a:variable[key] = a:value
    endif
  endfor
endfunction"}}}
function! unite#util#set_dictionary_helper(variable, keys, value)"{{{
  for key in split(a:keys, '\s*,\s*')
    let a:variable[key] = a:value
  endfor
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

