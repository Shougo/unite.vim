let s:suite = themis#suite('parser')
let s:assert = themis#helper('assert')

function! s:suite.before_each() abort
  let g:fuzzy_save = 20
endfunction
function! s:suite.after_each() abort
  let g:unite_matcher_fuzzy_max_input_length = g:fuzzy_save
endfunction

" vim:foldmethod=marker:fen:
