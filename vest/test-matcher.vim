scriptencoding utf-8

" Saving 'cpoptions' {{{
let s:save_cpo = &cpo
set cpo&vim
" }}}

Context Source.run()
  if has('lua')
    call unite#filters#matcher_fuzzy#define()

    let fuzzy_save = g:unite_matcher_fuzzy_max_input_length
    try
      let g:unite_matcher_fuzzy_max_input_length = 20

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
        ShouldEqual unite#filters#lua_fuzzy_matcher(
              \ [{'word' : 'app/code/local/Tbuy/Utils/Block/LocalCurrency.php'}],
              \ { 'input' : 'apcoltbuyutilsblockl' }, 1),
              \ [{'word' : 'app/code/local/Tbuy/Utils/Block/LocalCurrency.php'}]

        ShouldEqual unite#filters#matcher_fuzzy#get_fuzzy_input(
              \  'fooooooooooooooooooooooooooooooooo'),
              \ ['fooooooooooooooooooooooooooooooooo', '']
        ShouldEqual unite#filters#matcher_fuzzy#get_fuzzy_input(
              \  'fooooooooooooooooooooo/oooooooooooo'),
              \ ['fooooooooooooooooooooo', '/oooooooooooo']

        ShouldEqual unite#helper#paths2candidates(
              \  ['foo']), [
              \ {'word' : 'foo', 'action__path' : 'foo'},
              \ ]

        ShouldEqual unite#filters#converter_relative_word#lua([
              \  {'word' : '/foo/foo'},
              \  {'word' :
              \   unite#util#substitute_path_separator(expand('~/')).'bar'},
              \  {'word' : '/foo/foo', 'action__path' : '/foo/baz'},
              \ ], '/foo'), [
              \ {'word' : 'foo'}, {'word' : 'bar'},
              \ {'word' : 'baz', 'action__path' : '/foo/baz'}
              \ ]
    finally
      let g:unite_matcher_fuzzy_max_input_length = fuzzy_save
    endtry
    End
  endif
End

Fin

" Restore 'cpoptions' {{{
let &cpo = s:save_cpo
" }}}

" vim:foldmethod=marker:fen:
