let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('unite.vim')
let s:List = vital#of('unite.vim').import('Data.List')

let s:is_windows = has('win16') || has('win32') || has('win64')

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
  return s:is_windows
endfunction
function! unite#util#is_windows(...)
  return s:is_windows
endfunction
function! unite#util#is_mac(...)
  return call(s:V.is_mac, a:000)
endfunction
function! unite#util#print_error(...)
  return call(s:V.print_error, a:000)
endfunction
function! unite#util#smart_execute_command(action, word)
  execute a:action . ' ' . (a:word == '' ? '' : '`=a:word`')
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

if unite#util#is_windows()
  function! unite#util#substitute_path_separator(...)
    return call(s:V.substitute_path_separator, a:000)
  endfunction
else
  function! unite#util#substitute_path_separator(path)
    return a:path
  endfunction
endif

function! unite#util#path2directory(...)
  return call(s:V.path2directory, a:000)
endfunction
function! unite#util#path2project_directory(...)
  return call(s:V.path2project_directory, a:000)
endfunction
function! unite#util#has_vimproc(...)
  return call(s:V.has_vimproc, a:000)
endfunction
function! unite#util#has_lua()
  " Note: Disabled if_lua feature if less than 7.3.885.
  " Because if_lua has double free problem.
  return has('lua') && (v:version > 703 || v:version == 703 && has('patch885'))
endfunction
function! unite#util#system(...)
  return call(s:V.system, a:000)
endfunction
function! unite#util#system_passwd(...)
  return call((unite#util#has_vimproc() ?
        \ 'vimproc#system_passwd' : 'system'), a:000)
endfunction
function! unite#util#get_last_status(...)
  return call(s:V.get_last_status, a:000)
endfunction
function! unite#util#get_last_errmsg()
  return unite#util#has_vimproc() ? vimproc#get_last_errmsg() : ''
endfunction
function! unite#util#sort_by(...)
  return call(s:List.sort_by, a:000)
endfunction
function! unite#util#uniq(...)
  return call(s:List.uniq, a:000)
endfunction
function! unite#util#input(prompt, ...) "{{{
  let context = unite#get_context()
  let default = get(a:000, 0, '')
  let completion = get(a:000, 1, '')
  let args = [a:prompt, default]
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
  return call(s:V.iconv, a:000)
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
  return exists('t:unite_buffer_dictionary') ?
        \ has_key(t:unite_buffer_dictionary, a:bufnr) && buflisted(a:bufnr) :
        \ buflisted(a:bufnr)
endfunction"}}}

function! unite#util#glob(pattern, ...) "{{{
  if a:pattern =~ "'"
    " Use glob('*').
    let cwd = getcwd()
    let base = unite#util#substitute_path_separator(
          \ fnamemodify(a:pattern, ':h'))
    lcd `=base`

    let files = map(split(unite#util#substitute_path_separator(
          \ glob('*')), '\n'), "base . '/' . v:val")

    lcd `=cwd`

    return files
  endif

  " let is_force_glob = get(a:000, 0, 0)
  let is_force_glob = get(a:000, 0, 1)

  if !is_force_glob && a:pattern =~ '^[^\\*]\+/\*'
        \ && unite#util#has_vimproc() && exists('*vimproc#readdir')
    return vimproc#readdir(a:pattern[: -2])
  else
    " Escape [.
    let glob = escape(a:pattern,
          \ unite#util#is_windows() ?  '?"={}' : '?"={}[]')

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
function! unite#util#expand(path) "{{{
  return s:V.substitute_path_separator(
        \ (a:path =~ '^\~') ? substitute(a:path, '^\~', expand('~'), '') :
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

" filter() for matchers.
function! unite#util#filter_matcher(list, expr, context) "{{{
  if a:context.unite__max_candidates <= 0 ||
        \ !a:context.unite__is_interactive ||
        \ len(a:context.input_list) > 1

    return a:expr == '' ? a:list : (a:expr ==# 'if_lua') ?
          \ unite#util#lua_matcher(a:list, a:context, &ignorecase)
          \ : filter(a:list, a:expr)
  endif

  if a:expr == ''
    return a:list[: a:context.unite__max_candidates - 1]
  endif

  let _ = []
  let len = 0

  let max = a:context.unite__max_candidates
  let offset = max*4
  for cnt in range(0, len(a:list) / offset)
    let list = a:list[cnt*offset : cnt*offset + offset]
    let list = (a:expr ==# 'if_lua') ?
          \ unite#util#lua_matcher(list, a:context, &ignorecase) :
          \ filter(list, a:expr)
    let len += len(list)
    let _ += list

    if len >= max
      break
    endif
  endfor

  return _[: max]
endfunction"}}}
function! unite#util#lua_matcher(candidates, context, ignorecase) "{{{
  if !has('lua')
    return []
  endif

  for input in a:context.input_list
    let input = substitute(input, '\\ ', ' ', 'g')
    let input = substitute(input, '\\\(.\)', '\1', 'g')
    if a:ignorecase
      let input = tolower(input)
    endif

    lua << EOF
    do
      local input = vim.eval('input')
      local candidates = vim.eval('a:candidates')
      if (vim.eval('a:ignorecase') ~= 0) then
        for i = #candidates-1, 0, -1 do
          if (string.find(string.lower(candidates[i].word), input, 1, true) == nil) then
            candidates[i] = nil
          end
        end
      else
        for i = #candidates-1, 0, -1 do
          if (string.find(candidates[i].word, input, 1, true) == nil) then
            candidates[i] = nil
          end
        end
      end
    end
EOF
  endfor

  return a:candidates
endfunction"}}}

function! unite#util#convert2list(expr) "{{{
  return type(a:expr) ==# type([]) ? a:expr : [a:expr]
endfunction"}}}
function! unite#util#msg2list(expr) "{{{
  return type(a:expr) ==# type([]) ? a:expr : split(a:expr, '\n')
endfunction"}}}

function! unite#util#truncate_wrap(str, max, footer_width, separator) "{{{
  let width = unite#util#wcswidth(a:str)
  if width <= a:max
    return unite#util#truncate(a:str, a:max)
  elseif &l:wrap
    return a:str
  endif

  let header_width = a:max - unite#util#wcswidth(a:separator) - a:footer_width
  return unite#util#strwidthpart(a:str, header_width) . a:separator
        \ . unite#util#strwidthpart_reverse(a:str, a:footer_width)
endfunction"}}}

function! unite#util#index_name(list, name) "{{{
  return index(map(copy(a:list), 'v:val.name'), a:name)
endfunction"}}}
function! unite#util#get_name(list, name, default) "{{{
  return get(a:list, unite#util#index_name(a:list, a:name), a:default)
endfunction"}}}

function! unite#util#redraw_echo(expr) "{{{
  if has('vim_starting')
    echo join(unite#util#msg2list(a:expr), "\n")
    return
  endif

  let msg = unite#util#msg2list(a:expr)
  let height = max([1, &cmdheight - 1])
  for i in range(0, len(msg), height)
    redraw
    echo join(msg[i : i+height-1], "\n")
  endfor
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

