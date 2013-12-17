scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

Context Source.run()
  if has('lua')
    It tests sorter rank.
      ShouldEqual map(unite#filters#sorter_rank#_sort(
            \ [{'word' : 'g/vimrc.ln'}, {'word' : 'gvimrc.ln'}],
            \  'gvimr', 0), 'v:val.word'), ['gvimrc.ln', 'g/vimrc.ln']
      ShouldEqual map(unite#filters#sorter_rank#_sort(
            \ [{'word' : 'g/vimrc.ln'}, {'word' : 'gvimrc.ln'}],
            \  'gvimrc', 0), 'v:val.word'), ['gvimrc.ln', 'g/vimrc.ln']
      ShouldEqual map(unite#filters#sorter_rank#_sort(
            \ [{'word' : 'g/vimrc.ln'}, {'word' : 'gvimrc.ln'}],
            \  'gvimr', 1), 'v:val.word'), ['gvimrc.ln', 'g/vimrc.ln']
      ShouldEqual map(unite#filters#sorter_rank#_sort(
            \ [{'word' : 'g/vimrc.ln'}, {'word' : 'gvimrc.ln'}],
            \  'gvimrc', 1), 'v:val.word'), ['gvimrc.ln', 'g/vimrc.ln']
      End
  endif
End

Fin

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
