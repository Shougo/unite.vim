" Utilities for output cache.

let s:save_cpo = &cpo
set cpo&vim

let s:is_windows = has('win16') || has('win32') || has('win64')
let s:is_cygwin = has('win32unix')
let s:is_mac = !s:is_windows && !s:is_cygwin
      \ && (has('mac') || has('macunix') || has('gui_macvim') ||
      \   (!executable('xdg-open') && system('uname') =~? '^darwin'))

function! s:getfilename(cache_dir, filename)
  let cache_name = s:_encode_name(a:cache_dir, a:filename)
  return cache_name
endfunction
function! s:filereadable(cache_dir, filename)
  let cache_name = s:_encode_name(a:cache_dir, a:filename)
  return filereadable(cache_name)
endfunction
function! s:readfile(cache_dir, filename)
  let cache_name = s:_encode_name(a:cache_dir, a:filename)
  return filereadable(cache_name) ? readfile(cache_name) : []
endfunction
function! s:writefile(cache_dir, filename, list)
  let cache_name = s:_encode_name(a:cache_dir, a:filename)

  call writefile(a:list, cache_name)
endfunction
function! s:delete(cache_dir, filename)
  let cache_name = s:_encode_name(a:cache_dir, a:filename)
  return delete(cache_name)
endfunction
function! s:_encode_name(cache_dir, filename)
  " Check cache directory.
  if !isdirectory(a:cache_dir)
    call mkdir(a:cache_dir, 'p')
  endif
  let cache_dir = a:cache_dir
  if cache_dir !~ '/$'
    let cache_dir .= '/'
  endif

  return cache_dir . s:create_hash(cache_dir, a:filename)
endfunction
function! s:check_old_cache(cache_dir, filename)
  " Check old cache file.
  let cache_name = s:_encode_name(a:cache_dir, a:filename)
  let ret = getftime(cache_name) == -1
        \ || getftime(cache_name) <= getftime(a:filename)
  if ret && filereadable(cache_name)
    " Delete old cache.
    call delete(cache_name)
  endif

  return ret
endfunction

" Check md5.
try
  call md5#md5()
  let s:exists_md5 = 1
catch
  let s:exists_md5 = 0
endtry

function! s:create_hash(dir, str)
  if len(a:dir) + len(a:str) < 150
    let hash = substitute(substitute(
          \ a:str, ':', '=-', 'g'), '[/\\]', '=+', 'g')
  elseif s:exists_md5
    " Use md5.vim.
    let hash = md5#md5(a:str)
  else
    " Use simple hash.
    let sum = 0
    for i in range(len(a:str))
      let sum += char2nr(a:str[i]) * (i + 1)
    endfor

    let hash = printf('%x', sum)
  endif

  return hash
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
