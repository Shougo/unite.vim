let s:suite = themis#suite('parser')
let s:assert = themis#helper('assert')

function! s:suite.common_string() abort
  call s:assert.equals(unite#filters#common_string([]), '')
  call s:assert.equals(unite#filters#common_string(
        \ [ '/foo/bar' ]), '/foo/')
  call s:assert.equals(unite#filters#common_string(
        \ [ '/foo/bar', '/bar/bar' ]), '/')
  call s:assert.equals(unite#filters#common_string(
        \ [ '/foo/bar', '/foo/bar' ]), '/foo/')
  call s:assert.equals(unite#filters#common_string(
        \ [ '/bar', '/bar' ]), '/')
endfunction

function! s:suite.uniq() abort
  call s:assert.equals(unite#filters#uniq(
        \ [ '/foo/bar' ]), ['bar'])
  call s:assert.equals(unite#filters#uniq(
        \ [ '/foo/bar', '/bar/bar' ]), ['/foo/bar', '/bar/bar'])
  call s:assert.equals(unite#filters#uniq(
        \ [ '/foo/baz/bar', '/foo/bar/bar' ]), ['.../baz/bar', '.../bar/bar'])
endfunction

" vim:foldmethod=marker:fen:
