scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

let g:kind = {
      \ 'name' : 'hoge',
      \ 'default_action' : 'open',
      \ 'action_table': {},
      \ }
let g:kind.action_table.open = {
      \ 'is_selectable' : 1,
      \ }
function! g:kind.action_table.open.func(candidate)
  echo 'hoge'
endfunction

let g:source = {
      \ 'name' : 'hoge',
      \ 'is_volatile' : 1,
      \ 'variables' : {'foo' : 'foo'}
      \}
function! g:source.gather_candidates(args, context) "{{{
  " Add dummy candidate.
  let g:candidates = [ a:context.input ]

  call map(g:candidates, '{
        \ "word" : v:val,
        \ "source" : "hoge",
        \ "kind" : "hoge",
        \}')

  if g:unite_source_file_ignore_pattern != ''
    call filter(g:candidates, 'v:val.word !~ ' .
          \ string(g:unite_source_file_ignore_pattern))
  endif

  return g:candidates
endfunction"}}}

Context Source.run()
  It defines kind
    Should unite#define_kind(g:kind) == 0
  End

  It defines source
    Should unite#define_source(g:source) == 0
    Should !empty(unite#get_all_sources(g:source.name))
  End

  It undefines kind
    Should unite#undef_kind(g:kind.name) == 0
  End

  It undefines source
    Should unite#undef_source(g:source.name) == 0
    Should empty(unite#get_all_sources(g:source.name))
    Should unite#define_source(g:source) == 0
  End

  It call do_candidates_action
    let g:candidates = unite#get_candidates(
          \ [['grep', fnamemodify(expand('<sfile>'), ':h'), '', 'hoge']])
  End

  It get candidates
    call unite#custom_max_candidates('file_mru', 1)
    let g:candidates = unite#get_candidates(['file_mru'])
    ShouldEqual len(g:candidates), len(readfile(
          \ unite#helper#get_data_directory() . '/file_mru'))-1

    let g:candidates = unite#get_candidates([
          \ ['grep', 'unite.vim/plugin', '', 'vim']])
    call unite#action#do_candidates('replace', g:candidates)
  End

  It check custom variables.
    call unite#custom_source('hoge', 'variables', { 'foo' : 'bar' })
    call unite#get_candidates([['hoge']])
  End
End

Fin

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
