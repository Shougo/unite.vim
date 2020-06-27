"=============================================================================
" FILE: converter_relative_word.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! unite#filters#converter_relative_word#define() abort "{{{
  return s:converter
endfunction"}}}

let s:converter = {
      \ 'name' : 'converter_relative_word',
      \ 'description' : 'relative path word converter',
      \}

function! s:converter.filter(candidates, context) abort "{{{
  if a:context.input =~ '^\%(/\|\a\+:/\)'
    " Use full path.
    return unite#filters#converter_full_path#define().filter(
          \ a:candidates, a:context)
  endif

  try
    let directory = unite#util#substitute_path_separator(getcwd())
    let old_dir = directory
    if has_key(a:context, 'source__directory')
      let directory = substitute(a:context.source__directory, '*', '', 'g')

      if directory !=# old_dir && isdirectory(directory)
            \ && a:context.input == ''
        call unite#util#lcd(directory)
      endif
    endif

    for candidate in a:candidates
      let candidate.word = unite#util#substitute_path_separator(
            \ fnamemodify(get(candidate, 'action__path',
            \     candidate.word), ':~:.'))
    endfor
  finally
    if has_key(a:context, 'source__directory')
          \ && directory !=# old_dir
      call unite#util#lcd(old_dir)
    endif
  endtry

  return a:candidates
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
