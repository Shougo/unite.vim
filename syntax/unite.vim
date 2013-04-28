"=============================================================================
" FILE: syntax/unite.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 28 Apr 2013.
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

if version < 700
  syntax clear
elseif exists('b:current_syntax')
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

syntax match uniteQuickMatchLine /^.|.*/
      \ contains=uniteQuickMatchTrigger,uniteCandidateSourceName,uniteCandidateAbbr
syntax region uniteNonMarkedLine start=/^- / end='$' keepend
      \ contains=uniteCandidateMarker,uniteCandidateSourceName,uniteCandidateAbbr
syntax match uniteCandidateMarker /^- / contained
syntax match uniteQuickMatchTrigger /^.|/ contained

highlight default link uniteError  Error

highlight default link uniteQuickMatchTrigger  Special
highlight default link uniteMarkedLine  Statement
highlight default link uniteCandidateSourceName  Type
highlight default link uniteCandidateMarker  Special
highlight default link uniteCandidateInputKeyword  Function

" The following definitions are for <Plug>(unite-choose-action).
highlight default link uniteChooseAction  NONE
highlight default link uniteChooseCandidate  NONE
highlight default link uniteChooseKey  SpecialKey
highlight default link uniteChooseMessage  NONE
highlight default link uniteChoosePrompt  uniteSourcePrompt
highlight default link uniteChooseSource  uniteSourceNames

highlight default link uniteInputPrompt  Identifier
highlight default link uniteInputPromptError  Error
highlight default link uniteInputSpecial  Special

let b:current_syntax = 'unite'

call unite#set_highlight()

let &cpo = s:save_cpo
unlet s:save_cpo

