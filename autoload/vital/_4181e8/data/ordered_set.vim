function! s:version() "{{{
  return '0.0.0dev'
endfunction "}}}

function! s:new(...) "{{{
    let obj = deepcopy(s:ordered_set)
    if a:0 && type(a:1) == type({})
        call extend(obj, a:1, 'force')
    endif
    return obj
endfunction "}}}


let s:ordered_set = {
\   '_array': [],
\   '_dict': {},
\   '_origin_pos': 0,
\   'Fn_identifier': 'string',
\}

function s:ordered_set.push(elem) "{{{
    let id = call(self.Fn_identifier, [a:elem])
    if !has_key(self._dict, id)
        let self._dict[id] = len(self._array) - self._origin_pos
        call add(self._array, a:elem)
    endif
endfunction "}}}

function! s:ordered_set.unshift(elem) "{{{
    let id = call(self.Fn_identifier, [a:elem])
    if !has_key(self._dict, id)
        let self._origin_pos += 1
        let self._dict[id] = -self._origin_pos
        call insert(self._array, a:elem)
    endif
endfunction "}}}

function! s:ordered_set.empty() "{{{
    return empty(self._array)
endfunction "}}}

function! s:ordered_set.size() "{{{
    return len(self._array)
endfunction "}}}

function! s:ordered_set.to_list() "{{{
    return copy(self._array)
endfunction "}}}

function! s:ordered_set.has(elem) "{{{
    let id = call(self.Fn_identifier, [a:elem])
    return has_key(self._dict, id)
endfunction "}}}

function! s:ordered_set.has_id(id) "{{{
    return has_key(self._dict, a:id)
endfunction "}}}

function! s:ordered_set.clear() "{{{
    let self._array = []
    let self._dict  = {}
    let self._origin_pos = 0
endfunction "}}}

function! s:ordered_set.remove(elem) "{{{
    let id = call(self.Fn_identifier, [a:elem])
    if has_key(self._dict, id)
        let idx = self._origin_pos + self._dict[id]
        unlet self._array[idx]
        if idx < self._origin_pos
            let self._origin_pos -= 1
        endif
        unlet self._dict[id]
    endif
endfunction "}}}
