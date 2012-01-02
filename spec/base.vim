let s:results = {}
let s:context_stack = []

function! s:should(cond, result)
  " FIXME: validate
  let it = s:context_stack[-1][1]
  let context = s:context_stack[-2][1]
  if !has_key(s:results, context)
    let s:results[context] = []
  endif
  call add(s:results[context], a:result ? '.' :
        \ printf('It %s : %s', it, a:cond))
endfunction

function! s:_should(it, cond)
  echo a:cond
  echo eval(a:cond)
  return eval(a:cond) ? '.' : a:it
endfunction

command! -nargs=+ Context
      \ call add(s:context_stack, ['c', <q-args>])
command! -nargs=+ It
      \ call add(s:context_stack, ['i', <q-args>])
command! -nargs=+ Should
      \ call s:should(<q-args>, eval(<q-args>))
command! -nargs=0 End
      \ call remove(s:context_stack, -1) |
      \ redraw!

command! Fin
      \ echo string(s:results)
