"=============================================================================
" FILE: helpers.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 11 Jun 2013.
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be included
"     in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"     OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
"     IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
"     CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
"     TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
"     SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"=============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! unite#helper#call_hook(sources, hook_name) "{{{
  let context = unite#get_context()
  if context.unite__disable_hooks
    return
  endif

  let _ = []
  for source in a:sources
    if !has_key(source.hooks, a:hook_name)
      continue
    endif

    try
      call call(source.hooks[a:hook_name],
            \ [source.args, source.unite__context], source.hooks)
    catch
      call unite#print_error(v:throwpoint)
      call unite#print_error(v:exception)
      call unite#print_error(
            \ '[unite.vim] Error occured in calling hook "' . a:hook_name . '"!')
      call unite#print_error(
            \ '[unite.vim] Source name is ' . source.name)
    endtry
  endfor
endfunction"}}}

function! unite#helper#get_substitute_input(input) "{{{
  let input = a:input

  let unite = unite#get_current_unite()
  let substitute_patterns = reverse(unite#util#sort_by(
        \ values(unite#get_profile(unite.profile_name,
        \        'substitute_patterns')),
        \ 'v:val.priority'))
  if unite.input != '' && stridx(input, unite.input) == 0
    " Substitute after input.
    let input_save = input
    let input = input_save[len(unite.input) :]
    let head = input_save[: len(unite.input)-1]
  else
    " Substitute all input.
    let head = ''
  endif

  let inputs = unite#helper#get_substitute_input_loop(input, substitute_patterns)

  return map(inputs, 'head . v:val')
endfunction"}}}
function! unite#helper#get_substitute_input_loop(input, substitute_patterns) "{{{
  if empty(a:substitute_patterns)
    return [a:input]
  endif

  let inputs = [a:input]
  for pattern in a:substitute_patterns
    let cnt = 0
    for input in inputs
      if input =~ pattern.pattern
        if type(pattern.subst) == type([])
          if len(inputs) == 1
            " List substitute.
            let inputs = []
            for subst in pattern.subst
              call add(inputs,
                    \ substitute(input, pattern.pattern, subst, 'g'))
            endfor
          endif
        else
          let inputs[cnt] = substitute(
                \ input, pattern.pattern, pattern.subst, 'g')
        endif
      endif

      let cnt += 1
    endfor
  endfor

  return inputs
endfunction"}}}

function! unite#helper#adjustments(currentwinwidth, the_max_source_name, size) "{{{
  let max_width = a:currentwinwidth - a:the_max_source_name - a:size
  if max_width < 20
    return [a:currentwinwidth - a:size, 0]
  else
    return [max_width, a:the_max_source_name]
  endif
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: foldmethod=marker
