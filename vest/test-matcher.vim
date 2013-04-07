scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

Context Source.run()
  if has('lua')
    It tests lua matcher.
      ShouldEqual unite#util#lua_matcher(
            \ [{'word' : 'foo'}], 'foo', 0), [{'word' : 'foo'}]
      ShouldEqual unite#util#lua_matcher(
            \ [{'word' : 'foo'}], 'bar', 0), []
      ShouldEqual unite#util#lua_matcher(
            \ [{'word' : 'Foo'}], 'foo', 0), []
      ShouldEqual unite#util#lua_matcher(
            \ [{'word' : 'Foo'}], 'foo', 1), [{'word' : 'Foo'}]
      ShouldEqual unite#util#lua_matcher(
            \ [{'word' : 'Foo'}, {'word' : 'Bar'}], 'foo', 1), [{'word' : 'Foo'}]
      ShouldEqual unite#util#lua_matcher(
            \ [{'word' : 'foo'}, {'word' : 'bar'},
            \  {'word' : 'foobar'}, {'word' : 'baz'}],
            \ 'foo', 0), [{'word' : 'foo'}, {'word' : 'foobar'}]
      End
  endif
End

Fin

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
