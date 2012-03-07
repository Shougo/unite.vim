let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#{expand('<sfile>:h:h:t:r')}#new()

function! s:_vital_depends()
  return ['Data.String']
endfunction

let s:string = s:V.import('Data.String')

function! s:__urlencode_char(c)
  let utf = iconv(a:c, &encoding, "utf-8")
  if utf == ""
    let utf = a:c
  endif
  let s = ""
  for i in range(strlen(utf))
    let s .= printf("%%%02X", char2nr(utf[i]))
  endfor
  return s
endfunction

function! s:decodeURI(str)
  let ret = a:str
  let ret = substitute(ret, '+', ' ', 'g')
  let ret = substitute(ret, '%\(\x\x\)', '\=printf("%c", str2nr(submatch(1), 16))', 'g')
  return ret
endfunction

function! s:escape(str)
  return substitute(a:str, '[^a-zA-Z0-9_.~/-]', '\=s:__urlencode_char(submatch(0))', 'g')
endfunction

function! s:encodeURI(items)
  let ret = ''
  if type(a:items) == 4
    for key in sort(keys(a:items))
      if strlen(ret) | let ret .= "&" | endif
      let ret .= key . "=" . s:encodeURI(a:items[key])
    endfor
  elseif type(a:items) == 3
    for item in sort(a:items)
      if strlen(ret) | let ret .= "&" | endif
      let ret .= item
    endfor
  else
    let ret = substitute(a:items, '[^a-zA-Z0-9_.~-]', '\=s:__urlencode_char(submatch(0))', 'g')
  endif
  return ret
endfunction

function! s:encodeURIComponent(items)
  let ret = ''
  if type(a:items) == 4
    for key in sort(keys(a:items))
      if strlen(ret) | let ret .= "&" | endif
      let ret .= key . "=" . s:encodeURIComponent(a:items[key])
    endfor
  elseif type(a:items) == 3
    for item in sort(a:items)
      if strlen(ret) | let ret .= "&" | endif
      let ret .= item
    endfor
  else
    let items = iconv(a:items, &enc, "utf-8")
    let len = strlen(items)
    let i = 0
    while i < len
      let ch = items[i]
      if ch =~# '[0-9A-Za-z-._~!''()*]'
        let ret .= ch
      elseif ch == ' '
        let ret .= '+'
      else
        let ret .= '%' . substitute('0' . s:string.nr2hex(char2nr(ch)), '^.*\(..\)$', '\1', '')
      endif
      let i = i + 1
    endwhile
  endif
  return ret
endfunction

function! s:get(url, ...)
  let getdata = a:0 > 0 ? a:000[0] : {}
  let headdata = a:0 > 1 ? a:000[1] : {}
  let url = a:url
  let getdatastr = s:encodeURI(getdata)
  if strlen(getdatastr)
    let url .= "?" . getdatastr
  endif
  if executable('curl')
    let command = 'curl -L -s -k -i '
    let quote = &shellxquote == '"' ?  "'" : '"'
    for key in keys(headdata)
      if has('win32')
        let command .= " -H " . quote . key . ": " . substitute(headdata[key], '"', '"""', 'g') . quote
      else
        let command .= " -H " . quote . key . ": " . headdata[key] . quote
	  endif
    endfor
    let command .= " ".quote.url.quote
    let res = system(command)
  elseif executable('wget')
    let command = 'wget -O- --save-headers --server-response -q -L '
    let quote = &shellxquote == '"' ?  "'" : '"'
    for key in keys(headdata)
      if has('win32')
        let command .= " --header=" . quote . key . ": " . substitute(headdata[key], '"', '"""', 'g') . quote
      else
        let command .= " --header=" . quote . key . ": " . headdata[key] . quote
	  endif
    endfor
    let command .= " ".quote.url.quote
    let res = system(command)
  endif
  if res =~ '^HTTP/1.\d 3' || res =~ '^HTTP/1\.\d 200 Connection established'
    let pos = stridx(res, "\r\n\r\n")
    if pos != -1
      let res = res[pos+4:]
    else
      let pos = stridx(res, "\n\n")
      let res = res[pos+2:]
    endif
  endif
  let pos = stridx(res, "\r\n\r\n")
  if pos != -1
    let content = res[pos+4:]
  else
    let pos = stridx(res, "\n\n")
    let content = res[pos+2:]
  endif
  return {
  \ "header" : split(res[0:pos], '\r\?\n'),
  \ "content" : content
  \}
endfunction

function! s:post(url, ...)
  let postdata = a:0 > 0 ? a:000[0] : {}
  let headdata = a:0 > 1 ? a:000[1] : {}
  let method = a:0 > 2 ? a:000[2] : "POST"
  let url = a:url
  if type(postdata) == 4
    let postdatastr = s:encodeURI(postdata)
  else
    let postdatastr = postdata
  endif
  if executable('curl')
    let command = 'curl -L -s -k -i -X '.method
    let quote = &shellxquote == '"' ?  "'" : '"'
    for key in keys(headdata)
      if has('win32')
        let command .= " -H " . quote . key . ": " . substitute(headdata[key], '"', '"""', 'g') . quote
      else
        let command .= " -H " . quote . key . ": " . headdata[key] . quote
	  endif
    endfor
    let command .= " ".quote.url.quote
    let file = tempname()
    call writefile(split(postdatastr, "\n"), file, "b")
    let res = system(command . " --data-binary @" . quote.file.quote)
  elseif executable('wget')
    let command = 'wget -O- --save-headers --server-response -q -L '
    let headdata['X-HTTP-Method-Override'] = method
    let quote = &shellxquote == '"' ?  "'" : '"'
    for key in keys(headdata)
      if has('win32')
        let command .= " --header=" . quote . key . ": " . substitute(headdata[key], '"', '"""', 'g') . quote
      else
        let command .= " --header=" . quote . key . ": " . headdata[key] . quote
	  endif
    endfor
    let command .= " ".quote.url.quote
    let file = tempname()
    call writefile(split(postdatastr, "\n"), file, "b")
    let res = system(command . " --post-data @" . quote.file.quote)
  endif
  call delete(file)
  if res =~ '^HTTP/1.\d 3' || res =~ '^HTTP/1\.\d 200 Connection established'
    let pos = stridx(res, "\r\n\r\n")
    if pos != -1
      let res = res[pos+4:]
    else
      let pos = stridx(res, "\n\n")
      let res = res[pos+2:]
    endif
  endif
  let pos = stridx(res, "\r\n\r\n")
  if pos != -1
    let content = res[pos+4:]
  else
    let pos = stridx(res, "\n\n")
    let content = res[pos+2:]
  endif
  return {
  \ "header" : split(res[0:pos], '\r\?\n'),
  \ "content" : content
  \}
endfunction

let &cpo = s:save_cpo
