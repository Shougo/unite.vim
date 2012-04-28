" very simple message localization library.

let s:save_cpo = &cpo
set cpo&vim

function! s:new(path)
  let obj = copy(s:Message)
  let obj.path = a:path =~# '%s' ? a:path : 'message/' . a:path . '/%s.txt'
  call obj.load(s:get_lang())
  return obj
endfunction

function! s:get_lang()
  return v:lang ==# 'C' ? 'en' : v:lang[: 1]
endfunction

let s:Message = {}
function! s:Message.get(text)
  if self.lang !=# s:get_lang()
    call self.load()
  endif
  if has_key(self.data, a:text)
    return self.data[a:text]
  endif
  let text = self.missing(a:text)
  return type(text) == type('') ? text : a:text
endfunction
function! s:Message.load(lang)
  let pattern = printf(self.path, a:lang)
  let file = get(split(globpath(&runtimepath, pattern), "\n"), 0)
  let self.lang = a:lang
  sandbox let self.data = filereadable(file) ?
  \ eval(iconv(join(readfile(file), ''), 'utf-8', &encoding))
  \ : {}
endfunction
let s:Message._ = s:Message.get
function! s:Message.missing(text)
endfunction

let &cpo = s:save_cpo
