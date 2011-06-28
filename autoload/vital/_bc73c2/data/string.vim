" Utilities for string.

let s:save_cpo = &cpo
set cpo&vim

" Substitute a:from => a:to by string.
" To substitute by pattern, use substitute() instead.
" Test: https://gist.github.com/984296
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
" Test: https://gist.github.com/984296
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

" Split to two elements of List. ([left, right])
" e.g.: s:split_leftright("neocomplcache", "compl") returns ["neo", "cache"]
" Test: https://gist.github.com/984356
function! s:split_leftright(haystack, needle)
    let ERROR = ['', '']
    if a:haystack ==# '' || a:needle ==# ''
        return ERROR
    endif
    let idx = stridx(a:haystack, a:needle)
    if idx ==# -1
        return ERROR
    endif
    let left  = idx ==# 0 ? '' : a:haystack[: idx - 1]
    let right = a:haystack[idx + strlen(a:needle) :]
    return [left, right]
endfunction

" Returns the number of character in a:str.
" NOTE: This returns proper value
" even if a:str contains multibyte character(s).
" s:strchars(str) {{{
if exists('*strchars')
    " TODO: Why can't I write like this?
    " let s:strchars = function('strchars')
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


let &cpo = s:save_cpo
