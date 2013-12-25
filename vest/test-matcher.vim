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
      ShouldEqual unite#filters#lua_fuzzy_matcher(
            \ [{'word' : '/Users/core.cljs'}, {'word' : '/Users/core.js'}],
            \ { 'input' : 'cl' }, 0), [{'word' : '/Users/core.cljs'}]
      ShouldEqual unite#filters#lua_fuzzy_matcher(
            \ [{'word' : '/Users/core.cljs'}, {'word' : '/Users/core.js'}],
            \ { 'input' : 'co' }, 0), [{'word' : '/Users/core.cljs'}, {'word' : '/Users/core.js'}]
      ShouldEqual unite#filters#lua_fuzzy_matcher(
            \ [{'word' : '/Users/core.cljs'}, {'word' : '/Users/core.js'}],
            \ { 'input' : '/U' }, 0), [{'word' : '/Users/core.cljs'}, {'word' : '/Users/core.js'}]
      ShouldEqual unite#filters#lua_fuzzy_matcher(
            \ [{'word' : '/Users/core.cljs'}, {'word' : '/Users/core.js'}],
            \ { 'input' : '/Us' }, 0), [{'word' : '/Users/core.cljs'}, {'word' : '/Users/core.js'}]
      ShouldEqual unite#filters#lua_fuzzy_matcher(
            \ [{'word' : '/unite/sources/find.vim'}],
            \ { 'input' : '/u/s/f' }, 0), [{'word' : '/unite/sources/find.vim'}]
      End
  endif
End

Fin

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
