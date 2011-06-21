" Utilities for cmdline.

let s:save_cpo = &cpo
set cpo&vim


" getchar() wrapper.
" do inputsave()/inputrestore() before/after getchar().
" and always returns String.
function! s:getchar(...) "{{{
    let c = s:input_helper('getchar', a:000)
    return type(c) == type("") ? c : nr2char(c)
endfunction "}}}

" input() wrapper.
" do inputsave()/inputrestore() before/after input().
function! s:input(...) "{{{
    return s:input_helper('input', a:000)
endfunction "}}}

" do inputsave()/inputrestore() before/after calling a:funcname.
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


let &cpo = s:save_cpo
