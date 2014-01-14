"=============================================================================
" FILE: mru.vim
" AUTHOR:  Zhso Cai <caizhaoff@gmail.com>
"          Shougo Matsushita <Shougo.Matsu at gmail.com>
" Last Modified: 30 Apr 2013
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
let s:V = unite#util#get_vital()
let s:L = s:V.import("Data.List")

" The version of MRU file format.
let s:VERSION = '0.2.0'

call unite#util#set_default(
      \ 'g:unite_source_mru_do_validate', 1)
call unite#util#set_default(
      \ 'g:unite_source_mru_update_interval', 600)

call unite#util#set_default(
      \ 'g:unite_source_file_mru_time_format',
      \ '(%Y/%m/%d %H:%M:%S) ')
call unite#util#set_default(
      \ 'g:unite_source_file_mru_filename_format',
      \ ':~:.')
call unite#util#set_default(
      \ 'g:unite_source_file_mru_file',
      \ g:unite_data_directory . '/file_mru')
call unite#util#set_default(
      \ 'g:unite_source_file_mru_long_file',
      \ g:unite_data_directory . '/file_mru_long')
call unite#util#set_default(
      \ 'g:unite_source_file_mru_limit',
      \ 100)
call unite#util#set_default(
      \ 'g:unite_source_file_mru_long_limit',
      \ 1000)
call unite#util#set_default(
      \ 'g:unite_source_file_mru_ignore_pattern',
      \'\~$\|\.\%(o\|exe\|dll\|bak\|zwc\|pyc\|sw[po]\)$'
      \'\|\%(^\|/\)\.\%(hg\|git\|bzr\|svn\)\%($\|/\)'
      \'\|^\%(\\\\\|/mnt/\|/media/\|/temp/\|/tmp/\|\%(/private\)\=/var/folders/\)'
      \'\|\%(^\%(fugitive\)://\)'
      \)

call unite#util#set_default('g:unite_source_directory_mru_time_format',
      \ '(%Y/%m/%d %H:%M:%S) ')
call unite#util#set_default('g:unite_source_directory_mru_filename_format',
      \ ':~:.')
call unite#util#set_default('g:unite_source_directory_mru_file',
      \ g:unite_data_directory . '/directory_mru')
call unite#util#set_default('g:unite_source_directory_mru_long_file',
      \ g:unite_data_directory . '/directory_mru_long')
call unite#util#set_default('g:unite_source_directory_mru_limit', 100)
call unite#util#set_default('g:unite_source_directory_mru_long_limit', 1000)
call unite#util#set_default('g:unite_source_directory_mru_ignore_pattern',
      \'\%(^\|/\)\.\%(hg\|git\|bzr\|svn\)\%($\|/\)'
      \'\|^\%(\\\\\|/mnt/\|/media/\|/temp/\|/tmp/\|\%(/private\)\=/var/folders/\)')
"}}}

" MRUs  "{{{
let s:MRUs = {}

" Template MRU:  "{{{2

"---------------------%>---------------------
" @candidates:
" ------------
" [[full_path, localtime()], ... ]
"
" @mtime
" ------
" the last modified time of the mru file.
" - set once when loading the short mru_file
" - update when #save()
"
" @is_loaded
" ----------
" 0: empty
" 1: short
" 2: long
" -------------------%<---------------------

let s:mru = {
      \ 'candidates'      : [],
      \ 'type'            : '',
      \ 'mtime'           : 0,
      \ 'update_interval' : g:unite_source_mru_update_interval,
      \ 'mru_file'        : {},
      \ 'limit'           : {},
      \ 'do_validate'     : g:unite_source_mru_do_validate,
      \ 'is_loaded'       : 0,
      \ 'version'         : s:VERSION,
      \ }

function! s:mru.is_a(type) "{{{
  return self.type == a:type
endfunction "}}}
function! s:mru.save(...)
    throw 'unite(mru) umimplemented method: save()!'
endfunction
function! s:mru.load()
    throw 'unite(mru) umimplemented method: load()!'
endfunction
function! s:mru.validate()
    throw 'unite(mru) umimplemented method: validate()!'
endfunction

function! s:mru.gather_candidates(args, context) "{{{
  if empty(self.candidates)
    call self.load()
  endif

  let self.candidates = unite#sources#mru#variables#get_mrus(self.type)
        \ + self.candidates
  call unite#sources#mru#variables#clear(self.type)

  if a:context.is_redraw && g:unite_source_mru_do_validate
    call filter(self.candidates,
          \ ((self.type == 'file') ?
          \ "v:val.action__path !~ '^\\a\\w\\+:'
          \       && filereadable(v:val.action__path)" :
          \ "isdirectory(v:val.action__path)"))
  endif

  if get(a:args, 0, '') =~# '\%(long\|all\|\*\|_\)'
      \ || a:context.is_redraw
    call self.load()
    return self.candidates
  else
    return self.candidates[: self.limit.short]
  endif
endfunction"}}}
function! s:mru.delete(candidates) "{{{
  for candidate in a:candidates
    call filter(self.candidates,
          \ 'v:val.action__path !=# candidate.action__path')
  endfor

  call self.save()
endfunction"}}}
function! s:mru.has_external_update() "{{{
  return self.mtime < getftime(self.mru_file.short)
      \ || self.mtime < getftime(self.mru_file.long)
endfunction"}}}

function! s:mru.save(...) "{{{
  let opts = {}
  if a:0 >= 1 && s:V.is_dict(a:1)
    call extend(opts, a:1)
  endif

  " should load all candidates
  call self.load(1)

  let self.candidates = unite#sources#mru#variables#get_mrus(self.type)
        \ + self.candidates
  call unite#sources#mru#variables#clear(self.type)

  if empty(self.candidates)
    " nothing to save, mru is not loaded
    return
  endif

  if self.has_external_update() && filereadable(self.mru_file.short)
    " only need to get the short list which contains the latest MRUs
    let [ver; items] = readfile(self.mru_file.short)
    if self.version_check(ver)
      let self.candidates = s:L.uniq_by(extend(self.candidates,
            \ s:convert2candidates(items)), 'v:val.action__path')
    endif
  endif

  if get(opts, 'event') ==# 'VimLeavePre'
    call self.validate()
  endif

  let self.candidates = s:L.uniq_by(self.candidates, 'v:val.action__path')

  call writefile([self.version] + map(copy(
      \ self.candidates[: self.limit.short - 1]),
      \ 'join(s:convert2list(v:val), "\t")'),
      \ self.mru_file.short)

  if len(self.candidates) > self.limit.short
    call writefile([self.version] + map(copy(
        \ self.candidates[self.limit.short : self.limit.long - 1]),
        \ 'join(s:convert2list(v:val), "\t")'),
        \ self.mru_file.long)
    let self.mtime = getftime(self.mru_file.long)
  else
    let self.mtime = getftime(self.mru_file.short)
  endif
endfunction"}}}

function! s:mru.load(...)  "{{{
  let is_force = get(a:000, 0, 0)

  " everything is loaded, done!
  if !is_force && self.is_loaded >= 2
    return
  endif

  " Load Order:
  " 1. (load)  short mru list
  " 2. (merge) long list on_redraw
  let mru_file = empty(self.candidates) ?
        \ self.mru_file.short : self.mru_file.long

  if !filereadable(mru_file)
    return
  endif

  let file = readfile(mru_file)
  if empty(file)
    return
  endif

  let [ver; items] = file
  if !self.version_check(ver)
    return
  endif

  " Assume properly saved and sorted. unique sort is not necessary here
  call extend(self.candidates, s:convert2candidates(items))

  if mru_file == self.mru_file.short
    let self.mtime = getftime(mru_file)
    let self.is_loaded = 1
  elseif mru_file == self.mru_file.long
    let self.is_loaded = 2
  endif
endfunction"}}}
function! s:mru.version_check(ver)  "{{{
  if str2float(a:ver) < self.version
    call unite#util#print_error(
          \ 'Sorry, the version of MRU file is old.')
    return 0
  else
    return 1
  endif
endfunction"}}}

"}}}

" File MRU:   "{{{2
"
let s:file_mru = extend(deepcopy(s:mru), {
      \ 'type'          : 'file',
      \ 'mru_file'      : {
      \   'short' : g:unite_source_file_mru_file,
      \   'long'  : g:unite_source_file_mru_long_file,
      \  },
      \ 'limit'         : {
      \   'short' : g:unite_source_file_mru_limit,
      \   'long'  : g:unite_source_file_mru_long_limit,
      \  },
      \ }
      \)
function! s:file_mru.validate()  "{{{
  if self.do_validate
    call filter(self.candidates,
          \ 'getftype(v:val.action__path) ==# "file"')
  endif
endfunction"}}}

" Directory MRU:   "{{{2
let s:directory_mru = extend(deepcopy(s:mru), {
      \ 'type'          : 'directory',
      \ 'mru_file'      : {
      \   'short' : g:unite_source_directory_mru_file,
      \   'long'  : g:unite_source_directory_mru_long_file,
      \  },
      \ 'limit'         : {
      \   'short' : g:unite_source_directory_mru_limit,
      \   'long'  : g:unite_source_directory_mru_long_limit,
      \  },
      \ }
      \)

function! s:directory_mru.validate()  "{{{
  if self.do_validate
    call filter(self.candidates,
          \ 'getftype(v:val.action__path) ==# "dir"')
  endif
endfunction"}}}
"}}}

" Public Interface:   "{{{2

let s:MRUs.file = s:file_mru
let s:MRUs.directory = s:directory_mru
function! unite#sources#mru#_save(...) "{{{
  let opts = {}
  if a:0 >= 1 && s:V.is_dict(a:1)
    call extend(opts, a:1)
  endif

  for m in values(s:MRUs)
    call m.save(opts)
  endfor
endfunction"}}}
"}}}
"}}}

" Source  "{{{

function! unite#sources#mru#define() "{{{
  return [s:file_mru_source, s:dir_mru_source]
endfunction"}}}
let s:file_mru_source = {
      \ 'name' : 'file_mru',
      \ 'description' : 'candidates from file MRU list',
      \ 'hooks' : {},
      \ 'action_table' : {},
      \ 'syntax' : 'uniteSource__FileMru',
      \ 'default_kind' : 'file',
      \ 'ignore_pattern' : g:unite_source_file_mru_ignore_pattern,
      \ 'max_candidates' : 200,
      \}

let s:dir_mru_source = {
      \ 'name' : 'directory_mru',
      \ 'description' : 'candidates from directory MRU list',
      \ 'hooks' : {},
      \ 'action_table' : {},
      \ 'syntax' : 'uniteSource__DirectoryMru',
      \ 'default_kind' : 'directory',
      \ 'ignore_pattern' :
      \    g:unite_source_directory_mru_ignore_pattern,
      \ 'alias_table' : { 'unite__new_candidate' : 'vimfiler__mkdir' },
      \ 'max_candidates' : 200,
      \}

function! s:file_mru_source.hooks.on_syntax(args, context) "{{{
  syntax match uniteSource__FileMru_Time
        \ /([^)]*)\s\+/
        \ contained containedin=uniteSource__FileMru
  highlight default link uniteSource__FileMru_Time Statement
endfunction"}}}
function! s:dir_mru_source.hooks.on_syntax(args, context) "{{{
  syntax match uniteSource__DirectoryMru_Time
        \ /([^)]*)\s\+/
        \ contained containedin=uniteSource__DirectoryMru
  highlight default link uniteSource__DirectoryMru_Time Statement
endfunction"}}}
function! s:file_mru_source.hooks.on_post_filter(args, context) "{{{
  return s:on_post_filter(a:args, a:context)
endfunction"}}}
function! s:dir_mru_source.hooks.on_post_filter(args, context) "{{{
  return s:on_post_filter(a:args, a:context)
endfunction"}}}
function! s:file_mru_source.gather_candidates(args, context) "{{{
  let mru = s:MRUs.file
  return mru.gather_candidates(a:args, a:context)
endfunction"}}}
function! s:dir_mru_source.gather_candidates(args, context) "{{{
  let mru = s:MRUs.directory
  return mru.gather_candidates(a:args, a:context)
endfunction"}}}
"}}}
" Actions "{{{
let s:file_mru_source.action_table.delete = {
      \ 'description' : 'delete from file_mru list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:file_mru_source.action_table.delete.func(candidates) "{{{
  call s:MRUs.file.delete(a:candidates)
endfunction"}}}

let s:dir_mru_source.action_table.delete = {
      \ 'description' : 'delete from directory_mru list',
      \ 'is_invalidate_cache' : 1,
      \ 'is_quit' : 0,
      \ 'is_selectable' : 1,
      \ }
function! s:dir_mru_source.action_table.delete.func(candidates) "{{{
  call s:MRUs.directory.delete(a:candidates)
endfunction"}}}
"}}}

" Filters "{{{
function! s:file_mru_source.source__converter(candidates, context) "{{{
  return s:converter(a:candidates,
        \ g:unite_source_file_mru_filename_format,
        \ g:unite_source_file_mru_time_format)
endfunction"}}}

let s:file_mru_source.converters = [ s:file_mru_source.source__converter ]

function! s:dir_mru_source.source__converter(candidates, context) "{{{
  return s:converter(a:candidates,
        \ g:unite_source_directory_mru_filename_format,
        \ g:unite_source_directory_mru_time_format)
endfunction"}}}

let s:dir_mru_source.converters = [ s:dir_mru_source.source__converter ]

"}}}

" Misc "{{{
function! s:convert2candidates(items)  "{{{
  try
    return map(a:items, 's:convert2dictionary(split(v:val, "\t"))')
  catch
    call unite#util#print_error('Sorry, MRU file is invalid.')
    return []
  endtry
endfunction"}}}
function! s:convert2dictionary(list)  "{{{
  return { 'word' : a:list[0], 'source__time' : str2nr(a:list[1]),
        \ 'action__path' : fnamemodify(a:list[0], ':p'), }
endfunction"}}}
function! s:convert2list(dict)  "{{{
  return [ fnamemodify(a:dict.action__path, ':~'), a:dict.source__time ]
endfunction"}}}
function! s:on_post_filter(args, context) "{{{
  let a:context.candidates = s:L.uniq_by(
        \ a:context.candidates, 'v:val.action__path')
  for candidate in a:context.candidates
    let candidate.action__directory =
          \ unite#util#path2directory(candidate.action__path)
    let candidate.kind =
          \ (isdirectory(candidate.action__path) ? 'directory' : 'file')

    if candidate.kind ==# 'directory' && candidate.abbr !~ '/$'
      let candidate.abbr .= '/'
    endif
  endfor
endfunction"}}}
function! s:converter(candidates, filename_format, time_format) "{{{
  for candidate in filter(copy(a:candidates),
        \ "!has_key(v:val, 'abbr')")
    let path = (a:filename_format == '') ?  candidate.action__path :
          \ unite#util#substitute_path_separator(
          \   fnamemodify(candidate.action__path, a:filename_format))
    if path == ''
      let path = candidate.action__path
    endif

    " Set default abbr.
    let candidate.abbr = (a:time_format == '' ? '' :
          \ strftime(a:time_format, candidate.source__time))
    let candidate.abbr .= path
  endfor

  return a:candidates
endfunction"}}}
"}}}
"
let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
