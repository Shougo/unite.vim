" vim:foldmethod=marker:fen:
scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}


function! s:run()
  let l:kind = {
      \ 'name' : 'hoge',
      \ 'default_action' : 'open',
      \ 'action_table': {},
        \ }
  let l:kind.action_table.open = {
        \ 'is_selectable' : 1, 
        \ }
  function! l:kind.action_table.open.func(candidate)
    echo 'hoge'
  endfunction
  
  Ok unite#define_kind(l:kind) == 0, "defined kind"
  
  let l:source = {
        \ 'name' : 'hoge',
        \ 'is_volatile' : 1,
        \}
  function! l:source.gather_candidates(args, context)"{{{
    " Add dummy candidate.
    let l:candidates = [ a:context.input ]

    call map(l:candidates, '{
          \ "word" : v:val,
          \ "source" : "hoge",
          \ "kind" : "hoge",
          \}')

    if g:unite_source_file_ignore_pattern != ''
      call filter(l:candidates, 'v:val.word !~ ' . string(g:unite_source_file_ignore_pattern))
    endif

    return l:candidates
  endfunction"}}}
  
  Ok unite#define_source(l:source) == 0, "defind source"

  let candidate = {
  \   'ku__source': unite#available_sources('hoge'),
  \   'word': 'EMPRESS',
  \ }

  silent! let _ = unite#take_action('*choose*', candidate)
  Like _ 'no such action'

  Ok unite#undef_kind(l:kind.name) == 0, "undef kind"
  Ok unite#undef_source(l:source.name) == 0, "undef source"
  
endfunction

call s:run()
Done


" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}
