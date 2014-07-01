" TODO: move all comments to doc file.
"
"
" FIXME: This module name should be Vital.System ?
" But the name has been already taken.

let s:save_cpo = &cpo
set cpo&vim


" FIXME: Unfortunately, can't use s:_vital_loaded() for this purpose.
" Because these variables are used when this script file is loaded.
let s:is_windows = has('win16') || has('win32') || has('win64') || has('win95')
let s:is_unix = has('unix')


" Execute program in the background from Vim.
" Return an empty string always.
"
" If a:expr is a List, shellescape() each argument.
" If a:expr is a String, the arguments are passed as-is.
"
" Windows:
" Using :!start , execute program without via cmd.exe.
" Spawning 'expr' with 'noshellslash'
" keep special characters from unwanted expansion.
" (see :help shellescape())
"
" Unix:
" using :! , execute program in the background by shell.
function! s:spawn(expr, ...)
  let shellslash = 0
  if s:is_windows
    let shellslash = &l:shellslash
    setlocal noshellslash
  endif
  try
    if type(a:expr) is type([])
      let special = 1
      let cmdline = join(map(a:expr, 'shellescape(v:val, special)'), ' ')
    elseif type(a:expr) is type("")
      let cmdline = a:expr
      if a:0 && a:1
        " for :! command
        let cmdline = substitute(cmdline, '\([!%#]\|<[^<>]\+>\)', '\\\1', 'g')
      endif
    else
      throw 'Process.spawn(): invalid argument (value type:'.type(a:expr).')'
    endif
    if s:is_windows
      silent execute '!start' cmdline
    else
      silent execute '!' cmdline '&'
    endif
  finally
    if s:is_windows
      let &l:shellslash = shellslash
    endif
  endtry
  return ''
endfunction

" iconv() wrapper for safety.
function! s:iconv(expr, from, to)
  if a:from == '' || a:to == '' || a:from ==? a:to
    return a:expr
  endif
  let result = iconv(a:expr, a:from, a:to)
  return result != '' ? result : a:expr
endfunction

" Check vimproc.
function! s:has_vimproc()
  if !exists('s:exists_vimproc')
    try
      call vimproc#version()
      let s:exists_vimproc = 1
    catch
      let s:exists_vimproc = 0
    endtry
  endif
  return s:exists_vimproc
endfunction

" * {command} [, {input} [, {timeout}]]
" * {command} [, {dict}]
"   {dict} = {
"     use_vimproc: bool,
"     input: string,
"     timeout: bool,
"   }
function! s:system(str, ...)
  if type(a:str) is type([])
    let command = join(map(copy(a:str), 's:shellescape(v:val)'), ' ')
  elseif type(a:str) is type("")
    let command = a:str
  else
    throw 'Process.system(): invalid argument (value type:'.type(a:str).')'
  endif
  let command = s:iconv(command, &encoding, 'char')
  let input = ''
  let use_vimproc = s:has_vimproc()
  let args = [command]
  if a:0 ==# 1
    if type(a:1) is type({})
      if has_key(a:1, 'use_vimproc')
        let use_vimproc = a:1.use_vimproc
      endif
      if has_key(a:1, 'input')
        let args += [s:iconv(a:1.input, &encoding, 'char')]
      endif
      if use_vimproc && has_key(a:1, 'timeout')
        " ignores timeout unless you have vimproc.
        let args += [a:1.timeout]
      endif
    endif
  elseif a:0 >= 2
    let [input; rest] = a:000
    let input = s:iconv(a:1, &encoding, 'char')
    let args += [input] + rest
  endif

  let funcname = use_vimproc ? 'vimproc#system' : 'system'
  let output = call(funcname, args)
  let output = s:iconv(output, 'char', &encoding)

  return output
endfunction

function! s:get_last_status()
  return s:has_vimproc() ?
        \ vimproc#get_last_status() : v:shell_error
endfunction

if s:is_windows
  function! s:shellescape(command)
    return substitute(a:command, '[&()[\]{}^=;!''+,`~]', '^\0', 'g')
  endfunction
else
  function! s:shellescape(...)
    return call('shellescape', a:000)
  endfunction
endif


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
