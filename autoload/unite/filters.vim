"=============================================================================
" FILE: filters.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

" filter() for matchers.
function! unite#filters#filter_matcher(list, expr, context) abort "{{{
  if a:context.unite__max_candidates <= 0
        \ || a:expr == ''
        \ || !a:context.unite__is_interactive
        \ || len(a:context.input_list) > 1

    return a:expr == '' ? a:list :
          \ (a:expr ==# 'if_lua') ?
          \   unite#filters#lua_matcher(
          \      a:list, a:context.input_lua, &ignorecase) :
          \ (a:expr ==# 'if_lua_fuzzy') ?
          \   unite#filters#lua_fuzzy_matcher(
          \      a:list, a:context.input_lua, &ignorecase) :
          \ filter(a:list, a:expr)
  endif

  let _ = []
  let len = 0

  let max = a:context.unite__max_candidates * 5
  let offset = max*4
  for cnt in range(0, len(a:list) / offset)
    let list = a:list[cnt*offset : cnt*offset + offset]
    let list =
          \ (a:expr ==# 'if_lua') ?
          \   unite#filters#lua_matcher(
          \     list, a:context.input_lua, &ignorecase) :
          \ (a:expr ==# 'if_lua_fuzzy') ?
          \   unite#filters#lua_fuzzy_matcher(
          \     list, a:context.input_lua, &ignorecase) :
          \ filter(list, a:expr)
    let len += len(list)
    let _ += list

    if len >= max
      break
    endif
  endfor

  return _[: max]
endfunction"}}}

" @vimlint(EVL102, 1, l:input)
function! unite#filters#lua_matcher(candidates, input, ignorecase) abort "{{{
  if !has('lua')
    return []
  endif

  let input = a:ignorecase ? tolower(a:input) : a:input

  lua << EOF
do
  local input = vim.eval('input')
  local candidates = vim.eval('a:candidates')
  if (vim.eval('a:ignorecase') ~= 0) then
    for i = #candidates-1, 0, -1 do
      if (string.find(string.lower(candidates[i].word), input, 1, true) == nil) then
        candidates[i] = nil
      end
    end
  else
    for i = #candidates-1, 0, -1 do
      if (string.find(candidates[i].word, input, 1, true) == nil) then
        candidates[i] = nil
      end
    end
  end
end
EOF

  return a:candidates
endfunction"}}}
" @vimlint(EVL102, 0, l:input)

" @vimlint(EVL102, 1, l:input)
function! unite#filters#lua_fuzzy_matcher(candidates, input, ignorecase) abort "{{{
  if !has('lua')
    return []
  endif

  let input = a:ignorecase ? tolower(a:input) : a:input

  lua << EOF
do
  local pattern = vim.eval('unite#filters#fuzzy_escape(input)')
  local input = vim.eval('input')
  local candidates = vim.eval('a:candidates')
  if vim.eval('a:ignorecase') ~= 0 then
    pattern = string.lower(pattern)
    input = string.lower(input)
    for i = #candidates-1, 0, -1 do
      local word = string.lower(candidates[i].word)
      if string.find(word, pattern, 1) == nil then
        candidates[i] = nil
      end
    end
  else
    for i = #candidates-1, 0, -1 do
      local word = candidates[i].word
      if string.find(word, pattern, 1) == nil then
        candidates[i] = nil
      end
    end
  end
end
EOF

  return a:candidates
endfunction"}}}
" @vimlint(EVL102, 0, l:input)

function! unite#filters#fuzzy_escape(string) abort "{{{
  " Escape string for lua regexp.
  let [head, input] = unite#filters#matcher_fuzzy#get_fuzzy_input(
        \ unite#filters#escape(a:string))
  return head . substitute(input,
        \ '\%([[:alnum:]_/-]\|%.\)\ze.', '\0.-', 'g')
endfunction"}}}

function! unite#filters#escape(string) abort "{{{
  " Escape string for lua regexp.
  return substitute(substitute(substitute(substitute(a:string,
        \ '\\ ', ' ', 'g'),
        \ '[%\[\]().+?^$-]', '%\0', 'g'),
        \ '\*\@<!\*\*\@!', '.*', 'g'),
        \ '\*\*\+', '.*', 'g')
endfunction"}}}

function! unite#filters#lua_filter_head(candidates, input) abort "{{{
lua << EOF
do
  local input = vim.eval('tolower(a:input)')
  local candidates = vim.eval('a:candidates')
  for i = #candidates-1, 0, -1 do
    local word = candidates[i].action__path
        or candidates[i].word
    if string.find(string.lower(word), input, 1, true) ~= 1 then
      candidates[i] = nil
    end
  end
end
EOF

  return a:candidates
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
  return unite#util#has_lua()?
          \ unite#filters#lua_filter_patterns(
          \   a:candidates, a:patterns, a:whites) :
          \ unite#filters#vim_filter_patterns(
          \   a:candidates, a:patterns, a:whites)
endfunction"}}}
function! unite#filters#lua_filter_patterns(candidates, patterns, whites) abort "{{{
lua << EOF
do
  local patterns = vim.eval('a:patterns')
  local whites = vim.eval('a:whites')
  local candidates = vim.eval('a:candidates')
  for i = #candidates-1, 0, -1 do
    local word = './' .. string.lower(candidates[i].action__path
        or candidates[i].word)
    for j = #patterns-1, 0, -1 do
      if string.find(word, patterns[j]) then
        local match = nil
        -- Search from whites
        for k = #whites-1, 0, -1 do
          if string.find(word, whites[k]) then
            match = k
            break
          end
        end

        if match == nil then
          candidates[i] = nil
        end
      end
    end
  end
end
EOF

  return a:candidates
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
  return unite#util#has_lua() ?
          \ unite#filters#globs2lua_patterns(a:globs) :
          \ unite#filters#globs2vim_patterns(a:globs)
endfunction"}}}
function! unite#filters#globs2vim_patterns(globs) abort "{{{
  return map(copy(a:globs), 's:glob2_pattern(v:val, 0)')
endfunction"}}}
function! unite#filters#globs2lua_patterns(globs) abort "{{{
  return map(copy(a:globs), 's:glob2_pattern(v:val, 1)')
endfunction"}}}
function! s:glob2_pattern(glob, is_lua) abort "{{{
  let glob = a:glob

  let glob = tolower(glob)
  let glob = substitute(glob, '^\.\ze/',
        \ unite#util#substitute_path_separator(getcwd()), '')
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

  let glob .= '$'

  return glob
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
