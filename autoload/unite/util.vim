let s:save_cpo = &cpo
set cpo&vim

function! unite#util#get_vital() "{{{
  if !exists('s:V')
    let s:V = vital#of('unite.vim')
  endif
  return s:V
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

" TODO use vital's
let s:is_windows = has('win16') || has('win32') || has('win64')

function! unite#util#truncate_smart(...)
  return call(unite#util#get_vital().truncate_skipping, a:000)
endfunction
function! unite#util#truncate(...)
  return call(unite#util#get_vital().truncate, a:000)
endfunction
function! unite#util#strchars(...)
  return call(s:get_string().strchars, a:000)
endfunction
function! unite#util#strwidthpart(...)
  return call(unite#util#get_vital().strwidthpart, a:000)
endfunction
function! unite#util#strwidthpart_reverse(...)
  return call(unite#util#get_vital().strwidthpart_reverse, a:000)
endfunction
function! unite#util#wcswidth(...)
  return call(unite#util#get_vital().wcswidth, a:000)
endfunction
function! unite#util#wcswidth(...)
  return call(unite#util#get_vital().wcswidth, a:000)
endfunction
function! unite#util#is_win(...)
  echoerr 'unite#util#is_win() is deprecated. use unite#util#is_windows() instead.'
  return s:is_windows
endfunction
function! unite#util#is_windows(...)
  return s:is_windows
endfunction
function! unite#util#is_mac(...)
  return call(unite#util#get_vital().is_mac, a:000)
endfunction
function! unite#util#print_error(...)
  return call(unite#util#get_vital().print_error, a:000)
endfunction
function! unite#util#smart_execute_command(action, word)
  execute a:action . ' ' . fnameescape(a:word)
endfunction
function! unite#util#escape_file_searching(...)
  return call(unite#util#get_vital().escape_file_searching, a:000)
endfunction
function! unite#util#escape_pattern(...)
  return call(unite#util#get_vital().escape_pattern, a:000)
endfunction
function! unite#util#set_default(var, val, ...)  "{{{
  if !exists(a:var) || type({a:var}) != type(a:val)
    let alternate_var = get(a:000, 0, '')

    let {a:var} = exists(alternate_var) ?
          \ {alternate_var} : a:val
  endif
endfunction"}}}
function! unite#util#set_dictionary_helper(...)
  return call(unite#util#get_vital().set_dictionary_helper, a:000)
endfunction

if unite#util#is_windows()
  function! unite#util#substitute_path_separator(...)
    return call(unite#util#get_vital().substitute_path_separator, a:000)
  endfunction
else
  function! unite#util#substitute_path_separator(path)
    return a:path
  endfunction
endif

function! unite#util#path2directory(...)
  return call(unite#util#get_vital().path2directory, a:000)
endfunction
function! unite#util#path2project_directory(...)
  return call(unite#util#get_vital().path2project_directory, a:000)
endfunction
function! unite#util#has_vimproc(...)
  return call(unite#util#get_vital().has_vimproc, a:000)
endfunction
function! unite#util#has_lua()
  " Note: Disabled if_lua feature if less than 7.3.885.
  " Because if_lua has double free problem.
  return has('lua') && (v:version > 703 || v:version == 703 && has('patch885'))
endfunction
function! unite#util#system(...)
  return call(unite#util#get_vital().system, a:000)
endfunction
function! unite#util#system_passwd(...)
  return call((unite#util#has_vimproc() ?
        \ 'vimproc#system_passwd' : 'system'), a:000)
endfunction
function! unite#util#get_last_status(...)
  return call(unite#util#get_vital().get_last_status, a:000)
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
  return call(s:get_list().uniq, a:000)
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
  return call(unite#util#get_vital().iconv, a:000)
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

  if !is_force_glob && (a:pattern =~ '\*$' || a:pattern == '*')
        \ && unite#util#has_vimproc() && exists('*vimproc#readdir')
    return vimproc#readdir(a:pattern[: -2])
  else
    " Escape [.
    let glob = escape(a:pattern, '?={}[]')

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
  return unite#util#get_vital().substitute_path_separator(
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

function! unite#util#convert2list(expr) "{{{
  return type(a:expr) ==# type([]) ? a:expr : [a:expr]
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

function! unite#util#escape_match(str) "{{{
  return substitute(substitute(escape(a:str, '~\.^$[]'),
        \ '\*\@<!\*\*\@!', '[^/]*', 'g'), '\*\*\+', '.*', 'g')
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

