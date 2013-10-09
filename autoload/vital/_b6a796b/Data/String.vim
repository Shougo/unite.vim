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
  return s:_replace(a:str, a:from, a:to, 'g')
endfunction

" Substitute a:from => a:to only once.
" cf. s:replace()
function! s:replace_first(str, from, to)
  return s:_replace(a:str, a:from, a:to, '')
endfunction

" implement of replace() and replace_first()
function! s:_replace(str, from, to, flags)
  return substitute(a:str, '\V'.escape(a:from, '\'), escape(a:to, '\'), a:flags)
endfunction

function! s:scan(str, pattern)
  let list = []
  call substitute(a:str, a:pattern, '\=add(list, submatch(0)) == [] ? "" : ""', 'g')
  return list
endfunction

function! s:reverse(str)
  return join(reverse(split(a:str, '.\zs')), '')
endfunction

function! s:common_head(strs)
  if empty(a:strs)
    return ''
  endif
  let len = len(a:strs)
  if len == 1
    return a:strs[0]
  endif
  let strs = len == 2 ? a:strs : sort(copy(a:strs))
  let pat = substitute(strs[0], '.', '[\0]', 'g')
  return pat == '' ? '' : matchstr(strs[-1], '^\%[' . pat . ']')
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
" e.g.: s:nsplit("neo compl cache", 2, '\s') returns ['neo', 'compl cache']
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

" Returns the bool of contains any multibyte character in s:str
function! s:contains_multibyte(str) "{{{
  return strlen(a:str) != s:strchars(a:str)
endfunction "}}}

" Remove last character from a:str.
" NOTE: This returns proper value
" even if a:str contains multibyte character(s).
function! s:chop(str) "{{{
  return substitute(a:str, '.$', '', '')
endfunction "}}}

" Remove last \r,\n,\r\n from a:str.
function! s:chomp(str) "{{{
  return substitute(a:str, '\%(\r\n\|[\r\n]\)$', '', '')
endfunction "}}}

" wrap() and its internal functions
" * _split_by_wcswidth_once()
" * _split_by_wcswidth()
" * _concat()
" * wrap()
"
" NOTE _concat() is just a copy of Data.List.concat().
" FIXME don't repeat yourself
function! s:_split_by_wcswidth_once(body, x)
  let fst = s:V.strwidthpart(a:body, a:x)
  let snd = s:V.strwidthpart_reverse(a:body, s:V.wcswidth(a:body) - s:V.wcswidth(fst))
  return [fst, snd]
endfunction

function! s:_split_by_wcswidth(body, x)
  let memo = []
  let body = a:body
  while s:V.wcswidth(body) > a:x
    let [tmp, body] = s:_split_by_wcswidth_once(body, a:x)
    call add(memo, tmp)
  endwhile
  call add(memo, body)
  return memo
endfunction

function! s:trim(str)
  return matchstr(a:str,'^\s*\zs.\{-}\ze\s*$')
endfunction

function! s:wrap(str,...)
  let _columns = a:0 > 0 ? a:1 : &columns
  return s:L.concat(
        \ map(split(a:str, '\r\n\|[\r\n]'), 's:_split_by_wcswidth(v:val, _columns - 1)'))
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
  return a:a ==# a:b ? -1 : strlen(s:common_head([a:a, a:b]))
endfunction

function! s:substitute_last(expr, pat, sub)
  return substitute(a:expr, printf('.*\zs%s', a:pat), a:sub, '')
endfunction

function! s:dstring(expr)
  let x = substitute(string(a:expr), "^'\\|'$", '', 'g')
  let x = substitute(x, "''", "'", 'g')
  return printf('"%s"', escape(x, '"'))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
