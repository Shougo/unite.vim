scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

Context Source.run()
  if has('lua')
    It tests sorter rank.
      for has_lua in range(2)
        ShouldEqual map(unite#filters#sorter_rank#_sort(
              \ [{'word' : 'g/vimrc.ln'}, {'word' : 'gvimrc.ln'}],
              \  'gvimr', has_lua), 'v:val.word'), ['gvimrc.ln', 'g/vimrc.ln']
        ShouldEqual map(unite#filters#sorter_rank#_sort(
              \ [{'word' : 'g/vimrc.ln'}, {'word' : 'gvimrc.ln'}],
              \  'gvimrc', has_lua), 'v:val.word'), ['gvimrc.ln', 'g/vimrc.ln']
        ShouldEqual map(unite#filters#sorter_rank#_sort(
              \ [{'word' : 'ab12345js12345tt'}, {'word' : 'ab.js.tt'}],
              \  'abjstt', has_lua), 'v:val.word'), ['ab.js.tt', 'ab12345js12345tt']
        ShouldEqual map(unite#filters#sorter_rank#_sort(
              \ [{'word' : 'source/r', 'action__path' : ''},
              \  {'word' : 'sort.vim', 'action__path' : ''}],
              \  'so', has_lua), 'v:val.word'), ['sort.vim', 'source/r']
        ShouldEqual map(unite#filters#sorter_rank#_sort(
              \ [{'word' : 'spammers.txt', 'action__path' : ''},
              \  {'word' : 'thread_parsing.py', 'action__path' : ''}],
              \  'pars', has_lua), 'v:val.word'),
              \ ['thread_parsing.py', 'spammers.txt']
      endfor
    End
  endif

  It tests group feature.
    ShouldEqual unite#candidates#_group_post_filters([
          \ {'word' : 'foo', 'group' : 'bar'},
          \ {'word' : 'bar', 'group' : 'baz'}]), [
          \ {'word' : 'bar', 'is_dummy' : 1},
          \ {'word' : 'foo', 'group' : 'bar'},
          \ {'word' : 'baz', 'is_dummy' : 1},
          \ {'word' : 'bar', 'group' : 'baz'},
          \]
  End
End

Fin

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
