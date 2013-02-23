" Utilities for string.

let s:save_cpo = &cpo
set cpo&vim

function! s:_vital_loaded(V)
  let s:V = a:V
  let s:L = s:V.import('Data.List')
endfunction

function! s:_vital_depends()
  return ['Data.List']
endfunction

" Substitute a:from => a:to by string.
" To substitute by pattern, use substitute() instead.
function! s:replace(str, from, to)
  if a:str ==# '' || a:from ==# ''
    return a:str
  endif
  let str = a:str
  let idx = stridx(str, a:from)
  while idx !=# -1
    let left  = idx ==# 0 ? '' : str[: idx - 1]
    let right = str[idx + strlen(a:from) :]
    let str = left . a:to . right
    let idx = stridx(str, a:from)
  endwhile
  return str
endfunction

" Substitute a:from => a:to only once.
" cf. s:replace()
function! s:replace_once(str, from, to)
  if a:str ==# '' || a:from ==# ''
    return a:str
  endif
  let idx = stridx(a:str, a:from)
  if idx ==# -1
    return a:str
  else
    let left  = idx ==# 0 ? '' : a:str[: idx - 1]
    let right = a:str[idx + strlen(a:from) :]
    return left . a:to . right
  endif
endfunction

function! s:scan(str, pattern)
  let list = []
  let pos = 0
  let len = len(a:str)
  while 0 <= pos && pos < len
    let matched = matchstr(a:str, a:pattern, pos)
    let pos = matchend(a:str, a:pattern, pos)
    if !empty(matched)
      call add(list, matched)
    endif
  endwhile
  return list
endfunction

function! s:reverse(str)
  return join(reverse(split(a:str, '.\zs')), '')
endfunction

function! s:common_head(strs)
  if empty(a:strs)
    return ''
  endif
  let head = a:strs[0]
  for str in a:strs[1 :]
    let pat = substitute(str, '.', '[\0]', 'g')
    let head = matchstr(head, '^\%[' . pat . ']')
    if head ==# ''
      break
    endif
  endfor
  return head
endfunction

" Split to two elements of List. ([left, right])
" e.g.: s:split3('neocomplcache', 'compl') returns ['neo', 'compl', 'cache']
function! s:split_leftright(expr, pattern)
  let [left, _, right] = s:split3(a:expr, a:pattern)
  return [left, right]
endfunction

function! s:split3(expr, pattern)
  let ERROR = ['', '', '']
  if a:expr ==# '' || a:pattern ==# ''
    return ERROR
  endif
  let begin = match(a:expr, a:pattern)
  if begin is -1
    return ERROR
  endif
  let end   = matchend(a:expr, a:pattern)
  let left  = begin <=# 0 ? '' : a:expr[: begin - 1]
  let right = a:expr[end :]
  return [left, a:expr[begin : end-1], right]
endfunction

" Slices into strings determines the number of substrings.
" e.g.: s:splitn("neo compl cache", 2, '\s') returns ['neo', 'compl cache']
function! s:nsplit(expr, n, ...)
  let pattern = get(a:000, 0, '\s')
  let keepempty = get(a:000, 1, 1)
  let ret = []
  let expr = a:expr
  if a:n <= 1
    return [expr]
  endif
  while 1
    let pos = match(expr, pattern)
    if pos == -1
      if expr !~ pattern || keepempty
        call add(ret, expr)
      endif
      break
    elseif pos >= 0
      let left = pos > 0 ? expr[:pos-1] : ''
      if pos > 0 || keepempty
        call add(ret, left)
      endif
      let ml = len(matchstr(expr, pattern))
      if pos == 0 && ml == 0
        let pos = 1
      endif
      let expr = expr[pos+ml :]
    endif
    if len(expr) == 0
      break
    endif
    if len(ret) == a:n - 1
      call add(ret, expr)
      break
    endif
  endwhile
  return ret
endfunction

" Returns the number of character in a:str.
" NOTE: This returns proper value
" even if a:str contains multibyte character(s).
" s:strchars(str) {{{
if exists('*strchars')
  function! s:strchars(str)
    return strchars(a:str)
  endfunction
else
  function! s:strchars(str)
    return strlen(substitute(copy(a:str), '.', 'x', 'g'))
  endfunction
endif "}}}

" Remove last character from a:str.
" NOTE: This returns proper value
" even if a:str contains multibyte character(s).
function! s:chop(str) "{{{
  return substitute(a:str, '.$', '', '')
endfunction "}}}

" wrap() and its internal functions
" * _split_by_wcswitdh_once()
" * _split_by_wcswitdh()
" * _concat()
" * wrap()
"
" NOTE _concat() is just a copy of Data.List.concat().
" FIXME don't repeat yourself
function! s:_split_by_wcswitdh_once(body, x)
  return [
        \ s:V.strwidthpart(a:body, a:x),
        \ s:V.strwidthpart_reverse(a:body, s:V.wcswidth(a:body) - a:x)]
endfunction

function! s:_split_by_wcswitdh(body, x)
  let memo = []
  let body = a:body
  while s:V.wcswidth(body) > a:x
    let [tmp, body] = s:_split_by_wcswitdh_once(body, a:x)
    call add(memo, tmp)
  endwhile
  call add(memo, body)
  return memo
endfunction

function! s:wrap(str)
  return s:L.concat(
        \ map(split(a:str, '\r\?\n'), 's:_split_by_wcswitdh(v:val, &columns - 1)'))
endfunction

function! s:nr2byte(nr)
  if a:nr < 0x80
    return nr2char(a:nr)
  elseif a:nr < 0x800
    return nr2char(a:nr/64+192).nr2char(a:nr%64+128)
  else
    return nr2char(a:nr/4096%16+224).nr2char(a:nr/64%64+128).nr2char(a:nr%64+128)
  endif
endfunction

function! s:nr2enc_char(charcode)
  if &encoding == 'utf-8'
    return nr2char(a:charcode)
  endif
  let char = s:nr2byte(a:charcode)
  if strlen(char) > 1
    let char = strtrans(iconv(char, 'utf-8', &encoding))
  endif
  return char
endfunction

function! s:nr2hex(nr)
  let n = a:nr
  let r = ""
  while n
    let r = '0123456789ABCDEF'[n % 16] . r
    let n = n / 16
  endwhile
  return r
endfunction

" If a ==# b, returns -1.
" If a !=# b, returns first index of diffrent character.
function! s:diffidx(a, b)
  let [a, b] = [split(a:a, '\zs'), split(a:b, '\zs')]
  let [al, bl] = [len(a), len(b)]
  let l = max([al, bl])
  for i in range(l)
    " if `i` is out of range, a[i] returns empty string.
    if i >= al || i >= bl || a[i] !=# b[i]
      return i > 0 ? strlen(join(a[:i-1], '')) : 0
    endif
  endfor
  return -1
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
