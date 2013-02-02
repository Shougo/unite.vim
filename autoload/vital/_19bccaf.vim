let s:self_version = expand('<sfile>:t:r')

let s:loaded = {}

function! s:import(name, ...)
  let target = {}
  let functions = []
  for a in a:000
    if type(a) == type({})
      let target = a
    elseif type(a) == type([])
      let functions = a
    endif
    unlet a
  endfor
  let module = s:_import(a:name, s:_scripts())
  if empty(functions)
    call extend(target, module, 'keep')
  else
    for f in functions
      if has_key(module, f) && !has_key(target, f)
        let target[f] = module[f]
      endif
    endfor
  endif
  return target
endfunction

function! s:load(...) dict
  let scripts = s:_scripts()
  for arg in a:000
    let [name; as] = type(arg) == type([]) ? arg[: 1] : [arg, arg]
    let target = split(join(as, ''), '\W\+')
    let dict = self
    while 1 <= len(target)
      let ns = remove(target, 0)
      if !has_key(dict, ns)
        let dict[ns] = {}
      endif
      if type(dict[ns]) == type({})
        let dict = dict[ns]
      else
        unlet dict
        break
      endif
    endwhile

    if exists('dict')
      call extend(dict, s:_import(name, scripts))
    endif
    unlet arg
  endfor
  return self
endfunction

function! s:unload()
  let s:loaded = {}
endfunction

function! s:_import(name, scripts)
  if type(a:name) == type(0)
    return s:_build_module(a:name)
  endif
  if a:name =~# '^[^A-Z]' || a:name =~# '\W[^A-Z]'
    throw 'vital: module name must start with capital letter: ' . a:name
  endif
  let target = a:name ==# '' ? '' : '/' . substitute(a:name, '\W\+', '/', 'g')
  let target = substitute(target, '\l\zs\ze\u', '_', 'g') " OrderedSet -> Ordered_Set
  let target = substitute(target, '[/_]\zs\u', '\l\0', 'g') " Ordered_Set -> ordered_set
  let tailpath = printf('autoload/vital/%s%s.vim', s:self_version, target)

  " Note: The extra argument to globpath() was added in Patch 7.2.051.
  if v:version > 702 || v:version == 702 && has('patch51')
    let paths = split(globpath(&runtimepath, tailpath, 1), "\n")
  else
    let paths = split(globpath(&runtimepath, tailpath), "\n")
  endif
  let path = s:_unify_path(get(paths, 0, ''))
  let sid = get(a:scripts, path, 0)
  if !sid
    try
      execute 'source' fnameescape(path)
    catch /^Vim\%((\a\+)\)\?:E484/
      throw 'vital: module not found: ' . a:name
    catch /^Vim\%((\a\+)\)\?:E127/
      " Ignore.
    endtry

    let sid = len(a:scripts) + 1  " We expect that the file newly read is +1.
    let a:scripts[path] = sid
  endif
  return s:_build_module(sid)
endfunction

function! s:_scripts()
  let scripts = {}
  for line in split(s:_redir('scriptnames'), "\n")
    let list = matchlist(line, '^\s*\(\d\+\):\s\+\(.\+\)\s*$')
    if !empty(list)
      let scripts[s:_unify_path(list[2])] = list[1] - 0
    endif
  endfor
  return scripts
endfunction

if filereadable(expand('<sfile>:r') . '.VIM')
  function! s:_unify_path(path)
    " Note: On windows, vim can't expand path names from 8.3 formats.
    " So if getting full path via <sfile> and $HOME was set as 8.3 format,
    " vital load duplicated scripts. Below's :~ avoid this issue.
    return tolower(fnamemodify(resolve(fnamemodify(
    \              a:path, ':p:gs?[\\/]\+?/?')), ':~'))
  endfunction
else
  function! s:_unify_path(path)
    return resolve(fnamemodify(a:path, ':p:gs?[\\/]\+?/?'))
  endfunction
endif

function! s:_build_module(sid)
  if has_key(s:loaded, a:sid)
    return copy(s:loaded[a:sid])
  endif
  let prefix = '<SNR>' . a:sid . '_'
  let funcs = s:_redir('function')
  let filter_pat = '^\s*function ' . prefix
  let map_pat = prefix . '\zs\w\+'
  let functions = map(filter(split(funcs, "\n"), 'v:val =~# filter_pat'),
  \          'matchstr(v:val, map_pat)')

  let module = {}
  for func in functions
    let module[func] = function(prefix . func)
  endfor
  if has_key(module, '_vital_loaded')
    let V = vital#{s:self_version}#new()
    if has_key(module, '_vital_depends')
      call call(V.load, module._vital_depends(), V)
    endif
    try
      call module._vital_loaded(V)
    catch
      " FIXME: Show an error message for debug.
    endtry
  endif
  if !get(g:, 'vital_debug', 0)
    call filter(module, 'v:key =~# "^\\a"')
  endif
  let s:loaded[a:sid] = module
  return copy(module)
endfunction

function! s:_redir(cmd)
  let oldverbosefile = &verbosefile
  set verbosefile=
  redir => res
    silent! execute a:cmd
  redir END
  let &verbosefile = oldverbosefile
  return res
endfunction

function! vital#{s:self_version}#new()
  return s:_import('', s:_scripts()).load(['Prelude', ''])
endfunction
