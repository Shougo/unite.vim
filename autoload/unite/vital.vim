let s:save_cpo = &cpo
set cpo&vim

function! unite#vital#truncate_smart(...)
  return call('vital#_39a315#truncate_smart', a:000)
endfunction
function! unite#vital#truncate(...)
  return call('vital#_39a315#truncate', a:000)
endfunction
function! unite#vital#strchars(...)
  return call('vital#_39a315#strchars', a:000)
endfunction
function! unite#vital#strwidthpart(...)
  return call('vital#_39a315#strwidthpart', a:000)
endfunction
function! unite#vital#strwidthpart_reverse(...)
  return call('vital#_39a315#strwidthpart_reverse', a:000)
endfunction
function! unite#vital#wcswidth(...)
  return call('vital#_39a315#wcswidth', a:000)
endfunction
function! unite#vital#wcswidth(...)
  return call('vital#_39a315#wcswidth', a:000)
endfunction
function! unite#vital#is_windows(...)
  return call('vital#_39a315#is_win', a:000)
endfunction
function! unite#vital#print_error(...)
  return call('vital#_39a315#print_error', a:000)
endfunction
endfunction
function! unite#vital#escape_file_searching(...)
  return call('vital#_39a315#escape_file_searching', a:000)
endfunction
function! unite#vital#escape_pattern(...)
  return call('vital#_39a315#escape_pattern', a:000)
endfunction
function! unite#vital#set_default(...)
  return call('vital#_39a315#set_default', a:000)
endfunction
function! unite#vital#set_dictionary_helper(...)
  return call('vital#_39a315#set_dictionary_helper', a:000)
endfunction
function! unite#vital#substitute_path_separator(...)
  return call('vital#_39a315#substitute_path_separator', a:000)
endfunction
function! unite#vital#path2directory(...)
  return call('vital#_39a315#path2directory', a:000)
endfunction
function! unite#vital#path2project_directory(...)
  return call('vital#_39a315#path2project_directory', a:000)
endfunction
function! unite#vital#has_vimproc(...)
  return call('vital#_39a315#has_vimproc', a:000)
endfunction
function! unite#vital#system(...)
  return call('vital#_39a315#system', a:000)
endfunction
function! unite#vital#get_last_status(...)
  return call('vital#_39a315#get_last_status', a:000)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
