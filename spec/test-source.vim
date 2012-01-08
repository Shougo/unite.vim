scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

source spec/base.vim

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
      \}
function! source.gather_candidates(args, context)"{{{
  " Add dummy candidate.
  let candidates = [ a:context.input ]

  call map(candidates, '{
        \ "word" : v:val,
        \ "source" : "hoge",
        \ "kind" : "hoge",
        \}')

  if g:unite_source_file_ignore_pattern != ''
    call filter(candidates, 'v:val.word !~ ' . string(g:unite_source_file_ignore_pattern))
  endif

  return candidates
endfunction"}}}

Context Source.run()
  It defines kind
    Should unite#define_kind(kind) == 0
  End

  It defines source
    Should unite#define_source(source) == 0
  End

  It undefines kind
    Should unite#undef_kind(kind.name) == 0
  End

  It undefines source
    Should unite#undef_source(source.name) == 0
  End

  let candidates = unite#get_candidates([['grep', '**', '', 'vim']])
  It call do_candidates_action
    call unite#do_candidates_action('replace', candidates)
  End
End

Fin

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
