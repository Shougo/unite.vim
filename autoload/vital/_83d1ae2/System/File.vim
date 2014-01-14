" Utilities for file copy/move/mkdir/etc.

let s:save_cpo = &cpo
set cpo&vim

let s:is_unix = has('unix')
let s:is_windows = has('win16') || has('win32') || has('win64') || has('win95')
let s:is_cygwin = has('win32unix')
let s:is_mac = !s:is_windows && !s:is_cygwin
      \ && (has('mac') || has('macunix') || has('gui_macvim') ||
      \   (!isdirectory('/proc') && executable('sw_vers')))

" Open a file.
function! s:open(filename) "{{{
  let filename = fnamemodify(a:filename, ':p')

  " Detect desktop environment.
  if s:is_windows
    " For URI only.
    let filename = iconv(filename, &encoding, 'char')
    silent execute '!start rundll32 url.dll,FileProtocolHandler' filename
  elseif s:is_cygwin
    " Cygwin.
    call system(printf('%s %s', 'cygstart',
          \ shellescape(filename)))
  elseif executable('xdg-open')
    " Linux.
    call system(printf('%s %s &', 'xdg-open',
          \ shellescape(filename)))
  elseif exists('$KDE_FULL_SESSION') && $KDE_FULL_SESSION ==# 'true'
    " KDE.
    call system(printf('%s %s &', 'kioclient exec',
          \ shellescape(filename)))
  elseif exists('$GNOME_DESKTOP_SESSION_ID')
    " GNOME.
    call system(printf('%s %s &', 'gnome-open',
          \ shellescape(filename)))
  elseif executable('exo-open')
    " Xfce.
    call system(printf('%s %s &', 'exo-open',
          \ shellescape(filename)))
  elseif s:is_mac && executable('open')
    " Mac OS.
    call system(printf('%s %s &', 'open',
          \ shellescape(filename)))
  else
    " Give up.
    throw 'Not supported.'
  endif
endfunction "}}}


" Move a file.
" Dispatch s:move_exe() or s:move_vim().
function! s:move(src, dest) "{{{
  if s:_has_move_exe()
    return s:move_exe(a:src, a:dest)
  else
    return s:move_vim(a:src, a:dest)
  endif
endfunction "}}}

if s:is_unix
  function! s:_has_move_exe()
    return executable('mv')
  endfunction
elseif s:is_windows
  function! s:_has_move_exe()
    return 1
  endfunction
else
  function! s:_has_move_exe()
    throw 'vital: System.File._has_move_exe(): your platform is not supported'
  endfunction
endif

" Move a file.
" Implemented by external program.
if s:is_unix
  function! s:move_exe(src, dest)
    if !s:_has_move_exe() | return 0 | endif
    let [src, dest] = [a:src, a:dest]
    silent execute '!mv' shellescape(src) shellescape(dest)
    return !v:shell_error
  endfunction
elseif s:is_windows
  function! s:move_exe(src, dest)
    if !s:_has_move_exe() | return 0 | endif
    let [src, dest] = [a:src, a:dest]
    let src  = substitute(src, '/', '\', 'g')
    let dest = substitute(dest, '/', '\', 'g')
    silent execute '!cmd /c move' src dest
    return !v:shell_error
  endfunction
else
  function! s:move_exe()
    throw 'vital: System.File.move_exe(): your platform is not supported'
  endfunction
endif

" Move a file.
" Implemented by pure Vim script.
function! s:move_vim(src, dest) "{{{
  return !rename(a:src, a:dest)
endfunction "}}}

" Copy a file.
" Dispatch s:copy_exe() or s:copy_vim().
function! s:copy(src, dest) "{{{
  if s:_has_copy_exe()
    return s:copy_exe(a:src, a:dest)
  else
    return s:copy_vim(a:src, a:dest)
  endif
endfunction "}}}

if s:is_unix
  function! s:_has_copy_exe()
    return executable('cp')
  endfunction
elseif s:is_windows
  function! s:_has_copy_exe()
    return 1
  endfunction
else
  function! s:_has_copy_exe()
    throw 'vital: System.File._has_copy_exe(): your platform is not supported'
  endfunction
endif

" Copy a file.
" Implemented by external program.
if s:is_unix
  function! s:copy_exe(src, dest)
    if !s:_has_copy_exe() | return 0 | endif
    let [src, dest] = [a:src, a:dest]
    silent execute '!cp' shellescape(src) shellescape(dest)
    return !v:shell_error
  endfunction
elseif s:is_windows
  function! s:copy_exe(src, dest)
    if !s:_has_copy_exe() | return 0 | endif
    let [src, dest] = [a:src, a:dest]
    let src  = substitute(src, '/', '\', 'g')
    let dest = substitute(dest, '/', '\', 'g')
    silent execute '!cmd /c copy' src dest
    return !v:shell_error
  endfunction
else
  function! s:copy_exe()
    throw 'vital: System.File.copy_exe(): your platform is not supported'
  endfunction
endif

" Copy a file.
" Implemented by pure Vim script.
function! s:copy_vim(src, dest) "{{{
  let ret = writefile(readfile(a:src, "b"), a:dest, "b")
  if ret == -1
    return 0
  endif
  return 1
endfunction "}}}

" mkdir() but does not throw an exception.
" Returns true if success.
" Returns false if failure.
function! s:mkdir_nothrow(...) "{{{
  silent! return call('mkdir', a:000)
endfunction "}}}


" Delete a file/directory.
if s:is_unix
  function! s:rmdir(path, ...)
    let flags = a:0 ? a:1 : ''
    let cmd = flags =~# 'r' ? 'rm -r' : 'rmdir'
    let cmd .= flags =~# 'f' && cmd ==# 'rm -r' ? ' -f' : ''
    let ret = system(cmd . ' ' . shellescape(a:path))
    if v:shell_error
      throw substitute(iconv(ret, 'char', &encoding), '\n', '', 'g')
    endif
  endfunction

elseif s:is_windows
  function! s:rmdir(path, ...)
    let flags = a:0 ? a:1 : ''
    if &shell =~? "sh$"
      let cmd = flags =~# 'r' ? 'rm -r' : 'rmdir'
      let cmd .= flags =~# 'f' && cmd ==# 'rm -r' ? ' -f' : ''
      let ret = system(cmd . ' ' . shellescape(a:path))
    else
      " 'f' flag does not make sense.
      let cmd = 'rmdir /Q'
      let cmd .= flags =~# 'r' ? ' /S' : ''
      let ret = system(cmd . ' "' . a:path . '"')
    endif
    if v:shell_error
      throw substitute(iconv(ret, 'char', &encoding), '\n', '', 'g')
    endif
  endfunction

else
  function! s:rmdir(path, ...)
    throw 'vital: System.File.rmdir(): your platform is not supported'
  endfunction
endif


let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set et ts=2 sts=2 sw=2 tw=0:
