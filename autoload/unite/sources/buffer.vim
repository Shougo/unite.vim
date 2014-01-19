"=============================================================================
" FILE: buffer.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 19 Jan 2014.
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

" Variables  "{{{
call unite#util#set_default(
      \ 'g:unite_source_buffer_time_format',
      \ '(%Y/%m/%d %H:%M:%S) ')
"}}}

function! unite#sources#buffer#define() "{{{
  return [s:source_buffer_all, s:source_buffer_tab]
endfunction"}}}

let s:source_buffer_all = {
      \ 'name' : 'buffer',
      \ 'description' : 'candidates from buffer list',
      \ 'syntax' : 'uniteSource__Buffer',
      \ 'hooks' : {},
      \ 'default_kind' : 'buffer',
      \}

function! s:source_buffer_all.hooks.on_init(args, context) "{{{
  let a:context.source__is_bang =
        \ (get(a:args, 0, '') ==# '!')
  let a:context.source__is_question =
        \ (get(a:args, 0, '') ==# '?')
  let a:context.source__buffer_list =
        \ s:get_buffer_list(a:context.source__is_bang,
        \                   a:context.source__is_question)
endfunction"}}}
function! s:source_buffer_all.hooks.on_syntax(args, context) "{{{
  syntax match uniteSource__Buffer_Name /[^/ \[\]]\+\s/
        \ contained containedin=uniteSource__Buffer
  highlight default link uniteSource__Buffer_Name Function
  syntax match uniteSource__Buffer_Info /\[.\{-}\] /
        \ contained containedin=uniteSource__Buffer
  highlight default link uniteSource__Buffer_Info PreProc
  syntax match uniteSource__Buffer_Modified /\[.\{-}+\]/
        \ contained containedin=uniteSource__Buffer
  highlight default link uniteSource__Buffer_Modified Statement
  syntax match uniteSource__Buffer_NoFile /\[nofile\]/
        \ contained containedin=uniteSource__Buffer
  highlight default link uniteSource__Buffer_NoFile Function
  syntax match uniteSource__Buffer_Time /(.\{-}) /
        \ contained containedin=uniteSource__Buffer
  highlight default link uniteSource__Buffer_Time Statement
endfunction"}}}
function! s:source_buffer_all.hooks.on_post_filter(args, context) "{{{
  for candidate in a:context.candidates
    let candidate.action__directory =
          \ s:get_directory(candidate.action__buffer_nr)
  endfor
endfunction"}}}

function! s:source_buffer_all.gather_candidates(args, context) "{{{
  if a:context.is_redraw
    " Recaching.
    let a:context.source__buffer_list =
          \ s:get_buffer_list(a:context.source__is_bang,
          \                   a:context.source__is_question)
  endif

  let candidates = map(a:context.source__buffer_list, "{
        \ 'word' : s:make_word(v:val.action__buffer_nr),
        \ 'abbr' : s:make_abbr(v:val.action__buffer_nr, v:val.source__flags)
        \        . s:format_time(v:val.source__time),
        \ 'action__buffer_nr' : v:val.action__buffer_nr,
        \ 'action__path' : unite#util#substitute_path_separator(
        \       fnamemodify(s:make_word(v:val.action__buffer_nr), ':p')),
        \}")

  return candidates
endfunction"}}}
function! s:source_buffer_all.complete(args, context, arglead, cmdline, cursorpos) "{{{
  return ['!', '?']
endfunction"}}}

let s:source_buffer_tab = deepcopy(s:source_buffer_all)
let s:source_buffer_tab.name = 'buffer_tab'
let s:source_buffer_tab.description =
      \ 'candidates from buffer list in current tab'

function! s:source_buffer_tab.gather_candidates(args, context) "{{{
  if a:context.is_redraw
    " Recaching.
    let a:context.source__buffer_list =
          \ s:get_buffer_list(a:context.source__is_bang,
          \                   a:context.source__is_question)
  endif

  if !exists('t:unite_buffer_dictionary')
    let t:unite_buffer_dictionary = {}
  endif

  let list = filter(copy(a:context.source__buffer_list),
        \ 'has_key(t:unite_buffer_dictionary, v:val.action__buffer_nr)')

  let candidates = map(list, "{
        \ 'word' : s:make_word(v:val.action__buffer_nr),
        \ 'abbr' : s:make_abbr(v:val.action__buffer_nr, v:val.source__flags)
        \        . s:format_time(v:val.source__time),
        \ 'action__buffer_nr' : v:val.action__buffer_nr,
        \ 'action__path' : unite#util#substitute_path_separator(
        \       fnamemodify(s:make_word(v:val.action__buffer_nr), ':p')),
        \}")

  return candidates
endfunction"}}}

" Misc
function! s:make_word(bufnr) "{{{
  let filetype = getbufvar(a:bufnr, '&filetype')
  if filetype ==# 'vimfiler'
    let path = getbufvar(a:bufnr, 'vimfiler').current_dir
    let path = printf('*vimfiler* [%s]',
          \ unite#util#substitute_path_separator(simplify(path)))
  elseif filetype ==# 'vimshell'
    let vimshell = getbufvar(a:bufnr, 'vimshell')
    let path = printf('*vimshell*: [%s]',
          \ unite#util#substitute_path_separator(simplify(vimshell.current_dir)))
  else
    let path = unite#util#substitute_path_separator(simplify(bufname(a:bufnr)))
  endif

  return path
endfunction"}}}
function! s:make_abbr(bufnr, flags) "{{{
  let bufname = fnamemodify(bufname(a:bufnr), ':t')
  if bufname == ''
    let bufname = bufname(a:bufnr)
  endif

  let filetype = getbufvar(a:bufnr, '&filetype')
  if filetype ==# 'vimfiler' || filetype ==# 'vimshell'
    if filetype ==# 'vimfiler'
      let vimfiler = getbufvar(a:bufnr, 'vimfiler')
      let path = vimfiler.current_dir
      if vimfiler.source !=# 'file'
        let path = vimfiler.source . ':' . path
      endif
    else
      let path = simplify(getbufvar(a:bufnr, 'vimshell').current_dir)
    endif

    let path = printf('%s [%s : %s]', bufname, path, filetype)
  else
    let path = bufname(a:bufnr) == '' ? 'No Name' :
          \ simplify(fnamemodify(bufname(a:bufnr), ':~:.'))
    if a:flags != ''
      " Format flags so that buffer numbers are aligned on the left.
      " example: '42 a% +' => ' 42 a%+ '
      "          '3 h +'   => '  3 h+  '
      let nowhitespace = substitute(a:flags, '\s*', '', 'g')
      let path = substitute(nowhitespace, '\v(\d+)(.*)',
            \ '\=printf("%*s %-*s", 3, submatch(1), 4, submatch(2))', 'g') . path
    endif

    if filetype != ''
      let path .= ' [' . filetype . ']'
    endif
  endif

  return (getbufvar(a:bufnr, '&buftype') =~# 'nofile' ? '[nofile] ' : '' ) .
         \ unite#util#substitute_path_separator(path) . ' '
endfunction"}}}
function! s:compare(candidate_a, candidate_b) "{{{
  return a:candidate_b.source__time - a:candidate_a.source__time
endfunction"}}}
function! s:get_directory(bufnr) "{{{
  let filetype = getbufvar(a:bufnr, '&filetype')
  if filetype ==# 'vimfiler'
    let dir = getbufvar(a:bufnr, 'vimfiler').current_dir
  elseif filetype ==# 'vimshell'
    let dir = getbufvar(a:bufnr, 'vimshell').current_dir
  else
    let path = unite#util#substitute_path_separator(bufname(a:bufnr))
    let dir = unite#path2directory(path)
  endif

  return dir
endfunction"}}}
function! s:get_buffer_list(is_bang, is_question) "{{{
  " Get :ls flags.
  redir => output
  silent! ls
  redir END

  let flag_dict = {}
  for out in map(split(output, '\n'), 'split(v:val)')
    let flag_dict[out[0]] = matchstr(join(out), '^.*\ze\s\+"')
  endfor

  " Make buffer list.
  let list = []
  let bufnr = 1
  let buffer_list = unite#sources#buffer#variables#get_buffer_list()
  while bufnr <= bufnr('$')
    if s:is_listed(a:is_bang, a:is_question, bufnr)
          \ && bufnr != bufnr('%')
      let dict = get(buffer_list, bufnr, {
            \ 'action__buffer_nr' : bufnr,
            \ 'source__time' : 0,
            \ })
      let dict.source__flags = get(flag_dict, bufnr, '')

      call add(list, dict)
    endif
    let bufnr += 1
  endwhile

  call sort(list, 's:compare')

  if s:is_listed(a:is_bang, a:is_question, bufnr('%'))
    " Add current buffer.
    let dict = get(unite#sources#buffer#variables#get_buffer_list(),
          \ bufnr('%'), {
          \ 'action__buffer_nr' : bufnr('%'),
          \ 'source__time' : 0,
          \ })
    let dict.source__flags = get(flag_dict, bufnr('%'), '')

    call add(list, dict)
  endif

  return list
endfunction"}}}

function! s:is_listed(is_bang, is_question, bufnr) "{{{
  return bufexists(a:bufnr) &&
        \ (a:is_question ? !buflisted(a:bufnr) :
        \    (a:is_bang || buflisted(a:bufnr)))
        \ && (getbufvar(a:bufnr, '&filetype') !=# 'unite'
        \      || getbufvar(a:bufnr, 'unite').buffer_name !=#
        \         unite#get_current_unite().buffer_name)
endfunction"}}}

function! s:format_time(time) "{{{
  if empty(a:time)
    return ''
  endif
  return strftime(g:unite_source_buffer_time_format, a:time)
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
