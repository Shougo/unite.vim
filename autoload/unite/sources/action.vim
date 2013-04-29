"=============================================================================
" FILE: action.vim
" AUTHOR:  Shougo Matsushita <Shougo.Matsu at gmail.com>
" Last Modified: 29 Apr 2013.
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

function! unite#sources#action#define()
  return s:source
endfunction

let s:source = {
      \ 'name' : 'action',
      \ 'description' : 'candidates from unite action',
      \ 'action_table' : {},
      \ 'hooks' : {},
      \ 'default_action' : 'do',
      \ 'syntax' : 'uniteSource__Action',
      \ 'is_listed' : 0,
      \}

function! s:source.hooks.on_syntax(args, context) "{{{
  syntax match uniteSource__ActionDescriptionLine / -- .*$/
        \ contained containedin=uniteSource__Action
  syntax match uniteSource__ActionDescription /.*$/
        \ contained containedin=uniteSource__ActionDescriptionLine
  syntax match uniteSource__ActionMarker / -- /
        \ contained containedin=uniteSource__ActionDescriptionLine
  highlight default link uniteSource__ActionMarker Special
  highlight default link uniteSource__ActionDescription Comment
endfunction"}}}

function! s:source.gather_candidates(args, context) "{{{
  if empty(a:args)
    return
  endif

  let candidates = copy(a:args[0])

  " Print candidates.
  call unite#print_source_message(map(copy(candidates),
        \ "'candidates: '.v:val.unite__abbr.'('.v:val.source.')'"), self.name)

  " Print default action.
  let default_actions = []
  for candidate in candidates
    let default_action = unite#get_default_action(
          \ candidate.source, candidate.kind)
    if default_action != ''
      call add(default_actions, default_action)
    endif
  endfor
  let default_actions = unite#util#uniq(default_actions)
  if len(default_actions) == 1
    call unite#print_source_message(
          \ 'default_action: ' . default_actions[0], self.name)
  endif

  " Process Alias.
  let actions = s:get_actions(candidates,
        \ a:context.source__sources)

  " Uniq.
  let uniq_actions = {}
  for action in values(actions)
    if !has_key(action, action.name)
      let uniq_actions[action.name] = action
    endif
  endfor

  let max = max(map(values(actions), 'len(v:val.name)'))

  let sources = map(copy(candidates), 'v:val.source')

  return sort(map(filter(values(uniq_actions), 'v:val.is_listed'), "{
        \   'word' : v:val.name,
        \   'abbr' : printf('%-" . max . "s %s -- %s',
        \          v:val.name, (v:val.is_quit ? '!' : ' '), v:val.description),
        \   'source__candidates' : candidates,
        \   'action__action' : v:val,
        \   'source__context' : a:context,
        \   'source__source_names' : sources,
        \ }"), 's:compare_word')
endfunction"}}}

function! s:compare_word(i1, i2)
  return (a:i1.word ># a:i2.word) ? 1 : -1
endfunction

" Actions "{{{
let s:source.action_table.do = {
      \ 'description' : 'do action',
      \ }
function! s:source.action_table.do.func(candidate) "{{{
  let context = a:candidate.source__context

  if !empty(context.old_buffer_info)
    " Restore buffer_name and profile_name.
    let buffer_name =
          \ get(get(context.old_buffer_info, 0, {}), 'buffer_name', '')
    if buffer_name != ''
      let context.buffer_name = buffer_name
    endif
    let profile_name =
          \ get(get(context.old_buffer_info, 0, {}), 'profile_name', '')
    if profile_name != ''
      let context.profile_name = profile_name
    endif
  endif

  if a:candidate.action__action.is_quit &&
        \ !a:candidate.action__action.is_start
    call unite#all_quit_session(0)
  endif

  call unite#mappings#do_action(a:candidate.word,
   \ a:candidate.source__candidates, context, context.source__sources)

  " Check quit flag.
  if !a:candidate.action__action.is_quit
        \ && context.temporary
    call unite#resume_from_temporary(context)

    " Check invalidate cache flag.
    if a:candidate.action__action.is_invalidate_cache
      for source_name in a:candidate.source__source_names
        call unite#invalidate_cache(source_name)
      endfor

      call unite#force_redraw()
    endif
  endif
endfunction"}}}
"}}}

function! s:get_actions(candidates, sources) "{{{
  let Self = unite#get_self_functions()[-1]

  let actions = unite#mappings#_get_candidate_action_table(
        \ a:candidates[0], a:sources)

  for candidate in a:candidates[1:]
    let action_table = unite#mappings#_get_candidate_action_table(
          \ candidate, a:sources)
    " Filtering unique items and check selectable flag.
    call filter(actions, 'has_key(action_table, v:key)
          \ && action_table[v:key].is_selectable')
  endfor

  return actions
endfunction"}}}

let &cpo = s:save_cpo
unlet s:save_cpo
