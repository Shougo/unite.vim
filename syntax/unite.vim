"=============================================================================
" FILE: syntax/unite.vim
" AUTHOR: Shougo Matsushita <Shougo.Matsu@gmail.com>
" Last Modified: 31 Jul 2010
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

syntax match UniteStatusLine /\%1l.*/
\            contains=UniteSourcePrompt,UniteSourceSeparator,UniteSourceNames
syntax match UniteSourcePrompt /^Sources/ contained nextgroup=UniteSourceSeparator
syntax match UniteSourceSeparator /: / contained nextgroup=UniteSourceNames
syntax match UniteSourceNames /[a-z/-]\+/ contained

syntax match UniteInputLine /\%2l.*/ contains=UniteInputPrompt
syntax match UniteInputPrompt /^>/ contained nextgroup=UniteInputPattern
syntax match UniteInputPattern /.*/ contained


highlight default link UniteSourceNames  Type
highlight default link UniteSourcePrompt  Statement
highlight default link UniteSourceSeparator  NONE

highlight default link UniteInputPrompt  Identifier
highlight default link UniteInputPattern  NONE

" The following definitions are for <Plug>(unite-choose-action).
highlight default link UniteChooseAction  NONE
highlight default link UniteChooseCandidate  NONE
highlight default link UniteChooseKey  SpecialKey
highlight default link UniteChooseMessage  NONE
highlight default link UniteChoosePrompt  UniteSourcePrompt
highlight default link UniteChooseSource  UniteSourceNames

let b:current_syntax = 'unite'
