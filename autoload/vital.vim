function! vital#of(name)
  let files = globpath(&runtimepath, 'autoload/vital/' . a:name . '.vital')
  let file = split(files, "\n")
  if empty(file)
    throw 'vital: version file not found: ' . a:name
  endif
  let ver = readfile(file[0])
  if empty(ver)
    throw 'vital: invalid version file: ' . a:name
  endif
  return vital#_{ver[0]}#new()
endfunction
