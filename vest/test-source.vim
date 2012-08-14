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
    call filter(candidates, 'v:val.word !~ ' .
          \ string(g:unite_source_file_ignore_pattern))
  endif

  return candidates
endfunction"}}}

let my_file_rec = {
      \ 'name': 'my/file_rec',
      \ 'description': 'my files.'
      \ }

function! my_file_rec.gather_candidates(args, context)
  return map(unite#get_candidates([['file_rec',
      \     fnamemodify(expand('<sfile>'), ':h')]]), "{
      \ 'word' : v:val.word,
      \ 'action_path': v:val.action__path,
      \ 'kind': 'file'
      \ }")
endfunction


Context Source.run()
  It defines kind
    Should unite#define_kind(kind) == 0
  End

  It defines source
    Should unite#define_source(source) == 0
    Should unite#define_source(my_file_rec) == 0
  End

  It undefines kind
    Should unite#undef_kind(kind.name) == 0
  End

  It undefines source
    Should unite#undef_source(source.name) == 0
  End

  It call do_candidates_action
    let candidates = unite#get_candidates(
          \ [['grep', fnamemodify(expand('<sfile>'), ':h'), '', 'hoge']])
  End

  It get candidates
    let candidates = unite#get_candidates([['my_file_rec']])
    Should len(filter(copy(candidates), "v:val.source ==# 'my_file'"))
          \ == len(copy(candidates))

    let candidates = unite#get_candidates(['file_mru'])
    Should len(candidates) == len(readfile(
          \ g:unite_data_directory . '/file_mru'))-1

    let candidates = unite#get_candidates([['grep', 'unite.vim', '', 'vim']])
    call unite#do_candidates_action('replace', candidates)
  End
End

Fin

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
