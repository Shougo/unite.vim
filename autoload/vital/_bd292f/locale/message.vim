" very simple message localization library.

let s:save_cpo = &cpo
set cpo&vim

function! s:new(plugin)
  let obj = copy(s:Message)
  let obj.plugin = a:plugin
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
  let text = get(self.data, a:text, a:text)
  return text !=# '' ? text : a:text
endfunction
function! s:Message.load(lang)
  let pattern = printf('message/%s/%s.txt', self.plugin, a:lang)
  let file = get(split(globpath(&runtimepath, pattern), "\n"), 0, '')
  let self.lang = a:lang
  sandbox let self.data = filereadable(file) ?
  \ eval(iconv(join(readfile(file), ''), 'utf-8', &encoding))
  \ : {}
endfunction
let s:Message._ = s:Message.get

let &cpo = s:save_cpo
