" You should check the following related builtin functions.
" fnamemodify()
" resolve()
" simplify()

let s:save_cpo = &cpo
set cpo&vim

let s:path_sep_pattern = (exists('+shellslash') ? '[\\/]' : '/') . '\+'

" Get the path separator.
function! s:separator()
  return !exists('+shellslash') || &shellslash ? '/' : '\'
endfunction

" Convert all path separators to "/".
function! s:unify_separator(path)
  return substitute(a:path, s:path_sep_pattern, '/', 'g')
endfunction

" Split the path with path separator.
" Note that this includes the drive letter of MS Windows.
function! s:split(path)
  return split(a:path, s:path_sep_pattern)
endfunction

" Join the paths.
" join('foo', 'bar')            => 'foo/bar'
" join('foo/', 'bar')           => 'foo/bar'
" join('/foo/', ['bar', 'buz/']) => '/foo/bar/buz/'
function! s:join(...)
  let sep = s:separator()
  let path = ''
  for part in a:000
    let path .= sep .
    \ (type(part) is type([]) ? call('s:join', part) :
    \                           part)
    unlet part
  endfor
  return substitute(path[1 :], s:path_sep_pattern, sep, 'g')
endfunction

" Check if the path is absolute path.
if has('win16') || has('win32') || has('win64') || has('win95')
  function! s:is_absolute(path)
    return a:path =~? '^[a-z]:[/\]'
  endfunction
else
  function! s:is_absolute(path)
    return a:path[0] ==# '/'
  endfunction
endif

" Return the parent directory of the path.
" NOTE: fnamemodify(path, ':h') does not return the parent directory
" when path[-1] is the separator.
function! s:dirname(path)
  let path = a:path
  let orig = a:path

  let path = s:remove_last_separator(path)
  if path == ''
    return orig    " root directory
  endif

  let path = fnamemodify(path, ':h')
  return path
endfunction

" Remove the separator at the end of a:path.
function! s:remove_last_separator(path) "{{{
  let sep = s:separator()
  let pat = (sep == '\' ? '\\' : '/') . '\+$'
  return substitute(a:path, pat, '', '')
endfunction "}}}


let &cpo = s:save_cpo
