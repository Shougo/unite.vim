scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

let kind = {
      \ 'name' : 'hoge',
      \ 'default_action' : 'open',
      \ 'action_table': {},
      \ }
let kind.action_table.open = {
      \ 'is_selectable' : 1,
      \ }
function! kind.action_table.open.func(candidate)
  echo 'hoge'
endfunction

let source = {
      \ 'name' : 'hoge',
      \ 'is_volatile' : 1,
      \ 'variables' : {'foo' : 'foo'}
      \}
function! source.gather_candidates(args, context) "{{{
  echomsg string(unite#get_source_variables(a:context))
  Should unite#get_source_variables(a:context).foo == 'bar'

  " Add dummy candidate.
  let candidates = [ a:context.input ]

  call map(candidates, '{
        \ "word" : v:val,
        \ "source" : "hoge",
        \ "kind" : "hoge",
        \}')

  if g:unite_source_file_ignore_pattern != ''
    call filter(candidates, 'v:val.word !~ ' .
          \ string(g:unite_source_file_ignore_pattern))
  endif

  return candidates
endfunction"}}}

Context Source.run()
  It defines kind
    Should unite#define_kind(kind) == 0
  End

  It defines source
    Should unite#define_source(source) == 0
    Should !empty(unite#get_all_sources(source.name))
  End

  It undefines kind
    Should unite#undef_kind(kind.name) == 0
  End

  It undefines source
    Should unite#undef_source(source.name) == 0
    Should empty(unite#get_all_sources(source.name))
    Should unite#define_source(source) == 0
  End

  It call do_candidates_action
    let candidates = unite#get_candidates(
          \ [['grep', fnamemodify(expand('<sfile>'), ':h'), '', 'hoge']])
  End

  It get candidates
    call unite#custom_max_candidates('file_mru', 1)
    let candidates = unite#get_candidates(['file_mru'])
    ShouldEqual len(candidates), len(readfile(
          \ g:unite_data_directory . '/file_mru'))-1

    let candidates = unite#get_candidates([
          \ ['grep', 'unite.vim/plugin', '', 'vim']])
    call unite#action#do_candidates('replace', candidates)
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
