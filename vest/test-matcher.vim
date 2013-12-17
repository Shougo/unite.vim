scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

Context Source.run()
  if has('lua')
    It tests lua matcher.
      ShouldEqual unite#filters#lua_matcher(
            \ [{'word' : 'foo'}], { 'input' : 'foo' }, 0), [{'word' : 'foo'}]
      ShouldEqual unite#filters#lua_matcher(
            \ [{'word' : 'foo'}], { 'input' : 'bar' }, 0), []
      ShouldEqual unite#filters#lua_matcher(
            \ [{'word' : 'Foo'}], { 'input' : 'foo'}, 0), []
      ShouldEqual unite#filters#lua_matcher(
            \ [{'word' : 'Foo'}], { 'input' : 'foo'}, 1), [{'word' : 'Foo'}]
      ShouldEqual unite#filters#lua_matcher(
            \ [{'word' : 'Foo'}, {'word' : 'Bar'}], { 'input' : 'foo' }, 1), [{'word' : 'Foo'}]
      ShouldEqual unite#filters#lua_matcher(
            \ [{'word' : 'foo'}, {'word' : 'bar'},
            \  {'word' : 'foobar'}, {'word' : 'baz'}],
            \ { 'input' : 'foo' }, 0), [{'word' : 'foo'}, {'word' : 'foobar'}]
      End
  endif
End

Fin

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
