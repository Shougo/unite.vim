"=============================================================================
" FILE: filters.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

" filter() for matchers.
function! unite#filters#filter_matcher(list, expr, context) abort "{{{
  if a:context.unite__max_candidates <= 0
        \ || a:expr == ''
        \ || !a:context.unite__is_interactive
        \ || len(a:context.input_list) > 1

    return a:expr == '' ? a:list : filter(a:list, a:expr)
  endif

  let _ = []
  let len = 0

  let max = a:context.unite__max_candidates * 5
  let offset = max*4
  for cnt in range(0, len(a:list) / offset)
    let list = a:list[cnt*offset : cnt*offset + offset]
    let list = filter(list, a:expr)
    let len += len(list)
    let _ += list

    if len >= max
      break
    endif
  endfor

  return _[: max]
endfunction"}}}

function! unite#filters#fuzzy_escape(string) abort "{{{
  let [head, input] = unite#filters#matcher_fuzzy#get_fuzzy_input(
        \ unite#filters#escape(a:string))
  return head . substitute(input,
        \ '\%([[:alnum:]_/-]\|%.\)\ze.', '\0.-', 'g')
endfunction"}}}

function! unite#filters#escape(string) abort "{{{
  return substitute(substitute(substitute(substitute(a:string,
        \ '\\ ', ' ', 'g'),
        \ '[%\[\]().+?^$-]', '%\0', 'g'),
        \ '\*\@<!\*\*\@!', '.*', 'g'),
        \ '\*\*\+', '.*', 'g')
endfunction"}}}

function! unite#filters#vim_filter_head(candidates, input) abort "{{{
  let input = tolower(a:input)
  return filter(a:candidates,
        \ "stridx(tolower(get(v:val, 'action__path',
        \      v:val.word)), input) == 0")
endfunction"}}}

function! unite#filters#vim_filter_pattern(candidates, pattern) abort "{{{
  return filter(a:candidates,
        \ "get(v:val, 'action__path', v:val.word) !~? a:pattern")
endfunction"}}}

function! unite#filters#filter_patterns(candidates, patterns, whites) abort "{{{
  return unite#filters#vim_filter_patterns(
          \   a:candidates, a:patterns, a:whites)
endfunction"}}}
" @vimlint(EVL102, 1, l:pattern)
function! unite#filters#vim_filter_patterns(candidates, patterns, whites) abort "{{{
  let pattern = join(a:patterns, '\|')
  let white = join(a:whites, '\|')
  return filter(a:candidates,
        \ "'./'.get(v:val, 'action__path', v:val.word) !~? pattern"
        \ .(white == "" ? "" : "|| './'.get(v:val, 'action__path', v:val.word) =~? white"))
endfunction"}}}
" @vimlint(EVL102, 0, l:pattern)

function! unite#filters#globs2patterns(globs) abort "{{{
  return unite#filters#globs2vim_patterns(a:globs)
endfunction"}}}
function! unite#filters#globs2vim_patterns(globs) abort "{{{
  return map(copy(a:globs), 's:glob2_pattern(v:val, 0)')
endfunction"}}}
function! s:glob2_pattern(glob, is_lua) abort "{{{
  let glob = a:glob

  let glob = tolower(glob)
  let glob = substitute(glob, '^\.\ze/',
        \ unite#util#substitute_path_separator(getcwd()), '')
  let glob = substitute(glob, '/\*\*/\*/$', '/**', '')
  let glob = substitute(glob, '/$', '/**', '')
  if glob !~ '^/\|^\a\+:'
    let glob = '/' . glob
  endif

  if a:is_lua
    let glob = substitute(glob, '//', '/', 'g')
    let glob = substitute(glob, '[%().+^$-]', '%\0', 'g')
    let glob = substitute(glob, '\*\@<!\*\*\@!', '[^/]*', 'g')
    let glob = substitute(glob, '\\\@<!\*\*\+', '.*', 'g')
    let glob = substitute(glob, '\\\@<!?', '[^/]', 'g')
  else
    let glob = escape(glob, '~.^$')
    let glob = substitute(glob, '//', '/', 'g')
    let glob = substitute(glob, '\*\@<!\*\*\@!', '[^/]*', 'g')
    let glob = substitute(glob, '\\\@<!\*\*\+', '.*', 'g')
    let glob = substitute(glob, '\\\@<!?', '[^/]', 'g')
  endif

  if glob !~ '/$'
    let glob .= '$'
  endif

  return glob
endfunction"}}}

function! unite#filters#uniq(list) abort "{{{
  let dict = {}
  for word in a:list
    let key = matchstr(word, '[^/]\+/\?$')
    if key == ''
      let key = word
    endif
    if !has_key(dict, key)
      let dict[key] = [word]
    else
      call add(dict[key], word)
    endif
  endfor

  " Remove the unique keys
  for key in keys(dict)
    if len(dict[key]) == 1
      call remove(dict, key)
    else
      let dict[key] = unite#filters#common_string(dict[key])
    endif
  endfor

  let uniq = []
  for word in a:list
    let key = matchstr(word, '[^/]\+/\?$')
    if key != ''
      if !has_key(dict, key)
        let word = key
      elseif dict[key] != '/' && dict[key] != ''
        let rest = split(word[len(dict[key]):], '/', 1)
        let word = '.../' . (len(rest) > 3 ?
              \ (rest[0] . '/.../' . rest[-2] . '/' . rest[-1]) :
              \ join(rest, '/'))
      endif
    endif
    call add(uniq, word)
  endfor
  return uniq
endfunction"}}}
function! unite#filters#common_string(list) abort "{{{
  if empty(a:list)
    return ''
  endif
  let splits = split(a:list[0], '/', 1)
  let common_str = join(splits[: -2], '/') . '/'
  let splits = splits[: -2]
  for word in a:list[1:]
    while common_str != '/' && stridx(word, common_str) != 0
      let common_str = join(splits[: -2], '/') . '/'
      let splits = splits[: -2]
    endwhile
  endfor

  return common_str
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
