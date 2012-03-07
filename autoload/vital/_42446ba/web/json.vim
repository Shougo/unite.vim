let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#{expand('<sfile>:h:h:t:r')}#new()

function! s:_vital_depends()
  return ['Data.String']
endfunction

let s:string = s:V.import('Data.String')

function! s:decode(json)
  let json = iconv(a:json, "utf-8", &encoding)
  let json = substitute(json, '\n', '', 'g')
  let json = substitute(json, '\\u34;', '\\"', 'g')
  let json = substitute(json, '\\u\(\x\x\x\x\)', '\=s:string.nr2enc_char("0x".submatch(1))', 'g')
  let [null,true,false] = [0,1,0]
  sandbox let ret = eval(json)
  return ret
endfunction

function! s:encode(val)
  if type(a:val) == 0
    return a:val
  elseif type(a:val) == 1
    let json = '"' . escape(a:val, '"') . '"'
    let json = substitute(json, "\r", '\\r', 'g')
    let json = substitute(json, "\n", '\\n', 'g')
    let json = substitute(json, "\t", '\\t', 'g')
    return iconv(json, &encoding, "utf-8")
  elseif type(a:val) == 3
    return '[' . join(map(copy(a:val), 's:encode(v:val)'), ',') . ']'
  elseif type(a:val) == 4
    return '{' . join(map(keys(a:val), 's:encode(v:val).":".s:encode(a:val[v:val])'), ',') . '}'
  else
    return string(a:val)
  endif
endfunction

let &cpo = s:save_cpo
