" Utilities for file copy/move/mkdir/etc.

let s:save_cpo = &cpo
set cpo&vim

let s:is_windows = has('win16') || has('win32') || has('win64')
let s:is_cygwin = has('win32unix')
let s:is_mac = !s:is_windows
      \ && (has('mac') || has('macunix') || has('gui_macvim') ||
      \   (!executable('xdg-open') && system('uname') =~? '^darwin'))

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
    call system(printf('%s %s &', 'kioclien exec',
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
" Dispatch s:move_file_exe() or s:move_file_pure().
function! s:move_file(src, dest) "{{{
    if executable('mv')
        return s:move_file_exe(a:src, a:dest)
    else
        return s:move_file_pure(a:src, a:dest)
    endif
endfunction "}}}

" Move a file.
" Implemented by 'mv' executable.
" TODO: Support non-*nix like system.
function! s:move_file_exe(src, dest)
    if !executable('mv') | return 0 | endif
    silent execute '!mv' shellescape(a:src) shellescape(a:dest)
    if v:shell_error
        return 0
    endif
    return 1
endfunction

" Move a file.
" Implemented by pure vimscript.
function! s:move_file_pure(src, dest) "{{{
    return !rename(a:src, a:dest)
endfunction "}}}

" Copy a file.
" Dispatch s:copy_file_exe() or s:copy_file_pure().
function! s:copy_file(src, dest) "{{{
    if executable('cp')
        return s:copy_file_exe(a:src, a:dest)
    else
        return s:copy_file_pure(a:src, a:dest)
    endif
endfunction "}}}

" Copy a file.
" Implemented by 'cp' executable.
" TODO: Support non-*nix like system.
function! s:copy_file_exe(src, dest)
    if !executable('cp') | return 0 | endif
    silent execute '!cp' shellescape(a:src) shellescape(a:dest)
    if v:shell_error
        return 0
    endif
    return 1
endfunction

" Copy a file.
" Implemented by pure vimscript.
function! s:copy_file_pure(src, dest) "{{{
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
    try
        call call('mkdir', a:000)
        return 1
    catch
        return 0
    endtry
endfunction "}}}


" rmdir recursively.
function! s:rmdir(path, ...)
  let flags = a:0 ? a:1 : ''
  if exists("*rmdir")
    return call('rmdir', [a:path] + a:000)
  elseif has("unix")
    let option = ''
    let option .= flags =~ 'f' ? ' -f' : ''
    let option .= flags =~ 'r' ? ' -r' : ''
    let ret = system("/bin/rm" . option . ' ' . shellescape(a:path) . ' 2>&1')
  elseif has("win32") || has("win95") || has("win64") || has("win16")
    let option = ''
    if &shell =~? "sh$"
      let option .= flags =~ 'f' ? ' -f' : ''
      let option .= flags =~ 'r' ? ' -r' : ''
      let ret = system("/bin/rm" . option . ' ' . shellescape(a:path) . ' 2>&1')
    else
      let option .= flags =~ 'f' ? ' /Q' : ''
      let option .= flags =~ 'r' ? ' /S' : ''
      let ret = system("rmdir " . option . ' "' . a:path . '" 2>&1')
    endif
  endif
  if v:shell_error
    throw substitute(iconv(ret, 'char', &encoding), '\n', '', 'g')
  endif
endfunction


let &cpo = s:save_cpo
