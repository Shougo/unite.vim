"=============================================================================
" FILE: file.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 16 Nov 2010
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

" Variables  "{{{
call unite#util#set_default('g:unite_source_file_ignore_pattern', 
      \'\%(^\|/\)\.$\|\~$\|\.\%(o|exe|dll|bak|sw[po]\)$')
"}}}

function! unite#sources#file#define()"{{{
  return s:source
endfunction"}}}

let s:source = {
      \ 'name' : 'file',
      \ 'is_volatile' : 1,
      \}

function! s:source.gather_candidates(args, context)"{{{
  let l:input = substitute(substitute(a:context.input, '\\ ', ' ', 'g'), '^\a\+:\zs\*/', '/', '')

  " Substitute *. -> .* .
  let l:input = substitute(l:input, '\*\.', '.*', 'g')

  if l:input !~ '\*' && unite#is_win() && getftype(l:input) == 'link'
    " Resolve link.
    let l:input = resolve(l:input)
  endif

  " Glob by directory name.
  let l:input = substitute(l:input, '[^/.]*$', '', '')
  let l:candidates = split(unite#substitute_path_separator(glob(l:input . (l:input =~ '\*$' ? '' : '*'))), '\n')

  if a:context.input != ''
    let l:dummy = substitute(a:context.input, '[*\\]', '', 'g')
    if (!filereadable(l:dummy) && !isdirectory(l:dummy) && isdirectory(fnamemodify(l:dummy, ':h')))
          \ || l:dummy =~ '^\%(/\|\a\+:/\)$'
      " Add dummy candidate.
      call add(l:candidates, l:dummy)
    endif
  endif

  if g:unite_source_file_ignore_pattern != ''
    call filter(l:candidates, 'v:val !~ ' . string(g:unite_source_file_ignore_pattern))
  endif

  let l:candidates_dir = []
  let l:candidates_file = []
  for l:file in l:candidates
    let l:file_path = unite#util#substitute_path_separator(fnamemodify(l:file, ':p'))
    let l:dict = {
          \ 'word' : l:file, 'abbr' : l:file, 'source' : 'file', 'action__path' : l:file_path,
          \ 'action__directory' : unite#path2directory(l:file_path),
          \}

    if isdirectory(l:file)
      if l:file !~ '^\%(/\|\a\+:/\)$'
        let l:dict.abbr .= '/'
      endif

      let l:dict.kind = 'directory'

      call add(l:candidates_dir, l:dict)
    else
      if !filereadable(l:file)
        " Dummy.
        let l:dict.abbr = '[new file]' . l:file
      endif

      let l:dict.kind = 'file'

      call add(l:candidates_file, l:dict)
    endif
  endfor

  return l:candidates_dir + l:candidates_file
endfunction"}}}

" vim: foldmethod=marker
