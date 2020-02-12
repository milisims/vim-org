syntax clear
" setlocal foldmethod=syntax this should go somewhere, probably

" When several syntax items may match, these rules are used:

" 1. When multiple Match or Region items start in the same position, the item
"    defined last has priority.
" 2. A Keyword has priority over Match and Region items.
" 3. An item that starts in an earlier position has priority over items that
"    start in later positions.


" Dev-help {{{
nnoremap <buffer> <F7> :set ft=org<CR>:call SynStack()<CR>
function! SynStack()
  if !exists('*synstack')
    return
  endif
  let l:group = synIDattr(synID(line('.'), col('.'), 1), 'name')
  echo l:group map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc
" }}}

"syntax cluster orgGreaterElements contains=@orgHeadline,orgSection,orgGreaterBlock,orgDrawers

syntax cluster orgHeadline contains=orgHeadline1,orgHeadline2,orgHeadline3
syntax cluster orgHeadline add=orgHeadline4,orgHeadline5,orgHeadline6,orgHeadline7
syntax cluster orgHeadline add=orgHeadline8,orgHeadline9,orgHeadlineN

syntax match orgHeadline1 /^\*\{1}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syntax match orgHeadline2 /^\*\{2}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syntax match orgHeadline3 /^\*\{3}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syntax match orgHeadline4 /^\*\{4}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syntax match orgHeadline5 /^\*\{5}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syntax match orgHeadline6 /^\*\{6}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syntax match orgHeadline7 /^\*\{7}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syntax match orgHeadline8 /^\*\{8}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syntax match orgHeadline9 /^\*\{9}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syntax match orgHeadlineN /^\*\{10,}[^*].*$/ contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl

syntax match orgHeadlineStars contained /^\*\+/ skipwhite
      \ contains=orgHeadlineInnerStar,orgHeadlineLastStar
      \ nextgroup=orgHeadlineText,orgHeadlinePriority,orgHeadlineKeywords
syntax match orgHeadlineInnerStar contained /\*/ conceal cchar=-
      \ nextgroup=orgHeadlineInnerStar,orgHeadlineLastStar
syntax match orgHeadlineLastStar contained /\*\ze\%([^*]\|$\)/

syntax match orgHeadlineText contained /\S.*$/ contains=orgHeadlineTags,@Spell transparent
syntax match orgHeadlineTags contained /:\%([[:alnum:]_@#%]*:\)\+/ contains=@NoSpell
syntax match orgHeadlinePriority contained /\[#\a\]/ nextgroup=orgHeadlineText skipwhite

syntax match orgHeadlineKeywords contained transparent /\u\+\ze /
      \ nextgroup=orgHeadlinePriority,orgHeadlineText skipwhite
" These are overriden immediately, but want to keep defaults available
syntax keyword orgTodo TODO containedin=orgHeadlineKeywords,@orgHeadline
syntax keyword orgDone DONE containedin=orgHeadlineKeywords,@orgHeadline

highlight link orgHeadline1 Statement
highlight link orgHeadline2 Function
highlight link orgHeadline3 String
highlight link orgHeadline4 Identifier
highlight link orgHeadline5 Function
highlight link orgHeadline6 String
highlight link orgHeadline7 Identifier
highlight link orgHeadline8 Function
highlight link orgHeadline9 String
highlight link orgHeadlineN Identifier

highlight link orgHeadlineInnerStar Comment
highlight link orgHeadlineLastStar Number
highlight link orgTodo Todo
highlight link orgDone Conditional

highlight link orgHeadlinePriority Error
highlight link orgHeadlineTags SpecialComment
" highlight link orgHeadlineText Normal

" TODO color different levels of headlines with matchadd?

" NOTE: empty lines belong to the largest element ending before them

" syntax region orgSection contained start=/^\s/ end=/$\_^\*/  TODO
" TODO orgSectionText is a bit of a hack.
" syntax region orgSectionText start=/^\s*\w\+/ end=/^\ze\s*\W/ contains=@Spell

syntax cluster orgPlanning contains=orgPlanDeadline,orgPlanScheduled,orgPlanClosed,orgPlanTime

syntax match orgPlanDeadline contained /^\s*DEADLINE:.*/  contains=orgTimestamp
      \ nextgroup=orgSection,orgPropertyDrawer skipnl
syntax match orgPlanScheduled contained /^\s*SCHEDULED:.*/ contains=orgTimestamp
      \ nextgroup=orgSection,orgPropertyDrawer skipnl
syntax match orgPlanClosed contained /^\s*CLOSED:.*/    contains=orgTimestamp
      \ nextgroup=orgSection,orgPropertyDrawer skipnl
syntax match orgPlanTime contained /^\s*<.*/    contains=orgTimestamp
      \ nextgroup=orgSection,orgPropertyDrawer skipnl

highlight link orgPlanDeadline Comment
highlight link orgPlanScheduled Comment
highlight link orgPlanClosed Comment
highlight link orgPlanTime Comment

" syntax region orgTimestamp oneline keepend transparent start='<'  end='>'  contains=orgDate,orgTime,orgRepeater
" syntax region orgTimestamp oneline keepend transparent start='\[' end=']'  contains=orgDate,orgTime,orgRepeater
syntax match  orgDate      contained  /\d\{4}-\d\d-\d\d\s\a\+/    transparent
syntax match  orgTime      contained  /\d\{1,2}:\d\d/                 transparent
syntax match  orgRepeater  contained  /\([+-]{1,2}\|\.+\)\d\+[hdwmy]/ transparent

highlight link orgPlanning Comment

syntax region orgListItem matchgroup=orgListLeader
      \ start=/^\z(\s*\)\zs[-+]/ start=/^\z(\s*\)\zs\(\d\+\|\a\)[.)]/ start=/^\z(\s\+\)\zs\*/
      \ end=/\ze\n\z1\S/ end=/\ze\n^$\n^$/ end=/\ze\n\z1\@!/
      \ contains=orgListItem,orgListCheck,orgListTag,@Spell keepend
syntax match orgListCheck  contained nextgroup=orgListTag              skipwhite /\(\[[xX -]\]\)/
syntax match orgListTag /\(\w\|\s\)*::/ contained
" FIXME: should be 'any character' for orglist tag -- If we just use .*, it clobbers the check

hi link orgListLeader Number
hi link orgListCheck Todo
hi link orgListTag SpecialComment

syntax region orgPropertyDrawer contained keepend matchgroup=orgPropertyDrawerEnds
      \ start=/^:PROPERTIES:$/ end=/^:END:$/ contains=orgNodeProperty,orgNodeMultiProperty
syntax region orgNodeProperty contained keepend matchgroup=orgPropertyName
      \ start=/^:\S\+[^+]:/ end=/$/ oneline
syntax region orgNodeMultiProperty contained keepend matchgroup=orgPropertyName
      \ start=/^:\S\++:/ end=/$/ oneline

hi link orgNodeProperty SpecialComment
hi link orgNodeMultiProperty SpecialComment
hi link orgPropertyDrawerEnds Comment
hi link orgPropertyName Identifier

" source block
" #+BEGIN_SRC PARAMETERS
" CONTENTS
" #+END_NAME
" FIXME _name on end is not being highlighted

" Drawers Above
" :NAME:
" CONTENTS
" :END:

" syntax match orgDrawerBegin /^:\S\+:/ contains=orgDrawerName nextgroup=orgDrawerName skipempty
" syntax match orgDrawerName /:\zs\S\+\ze:/ contained
" syntax match orgDrawerEnd /^:\zsEND\ze:/ contained
" Contents: any element except another drawer
" syntax region orgDrawerContents matchgroup=orgDrawerEnd start='^' end='' contained keepend
"             \ contains=@orgGreaterElements,@orgElements

"hi link orgDrawer Statement
"hi link orgDrawerName String
"hi link orgDrawerParameters Identifier
"hi link orgDrawerContents Number
"hi link orgDrawerBegin SpecialChar
"hi link orgDrawerEnd SpecialChar
"" }}}

" Dynamic Blocks {{{
" #+BEGIN: NAME PARAMETERS
" CONTENTS
" #+END:

"" Footnote Definitions {{{
"" [fn:LABEL] CONTENTS

"syntax match orgFootnoteDef /\[fn:[[:alnum:]-_]\+\]/ contains=orgFootnoteDefLabel
"            \ nextgroup=orgFootnoteDefContents skipwhite
"syntax match orgFootnoteDefLabel /:\zs[[:alnum:]-_]\+/ contained
"syntax region orgFootnoteDefContents contained nextgroup=orgFootnoteDef,@orgHeadline
"            \ start='.' end='\ze\n\%(^\*\|\[fn\|^$\n^$\)' keepend

"" TODO: use multi end characters
"" CONTENTS can contain any element excepted another footnote definition.
"" It ends at the next footnote definition, the next headline,
"" two consecutive empty lines or the end of buffer.

"hi link orgFootnoteDef Statement
"hi link orgFootnoteDefLabel String
"hi link orgFootnoteDefContents Identifier
"" }}}


"" }}}

"" Elements {{{
"syntax cluster orgElements contains=orgHorizontalRule,orgComment
"syntax match orgHorizontalRule /\s*-\{5,}\s*$/
syntax match orgComment /^\s*#\s\+.*$/
"syntax match orgComment /^#\s\+.*$/ contains=orgTodo
highlight link orgComment Comment
"" }}}

"" Objects {{{
"syntax cluster orgObjects contains=orgEntity,orgLatex,orgExportSnippet,orgFootnoteReference,orgLink
"syntax cluster orgObjects add=orgMacro,orgRadioTarget,orgTarget,@orgMarkup

"syntax region orgLatex contained keepend start=/\\\a\+{/ end=/}/ oneline
"" FIXME: next isn't quite right. Can't contain {}
"syntax region orgLatex contained keepend start=/\\\a\+\[/ end=/]/ oneline
"syntax region orgLatex contained keepend start=/\\(/ end=/\\)/
"syntax region orgLatex contained keepend start=/\\\[/ end=/\\]/
"syntax region orgLatex contained keepend start=/\\(/ end=/\\)/
"syntax region orgLatex contained keepend start=/\$\$/ end=/\$\$/
"syntax match orglatex contained  /\([^$]\|^\)\$[^ \t.,?;'"]\$\([[:punct:] ]\|$\)/
"" TODO: missing PRE$BORDER1 BODY BORDER2$POST

"syntax region orgExportSnippet contained keepend start=/@@\w\+:/ end=/@@/

"syntax match orgFootnoteReference contained /\[fn:[[:alnum:]_-]\+\]/
"syntax region orgFootnoteReference contained keepend start=/\[fn:[[:alnum:]_-]*:/ end=/\]/ contains=@orgObjects
"" Previous: inline and anonymous. If fn:LABEL is zero length, it is anonymous

"" TODO: link types: radio, protocol, plain
"" syntax match orgLink

"" TODO: separate arguments highlighting.
"syntax match orgMacro contained /{{{\a[[:alnum:]_-]*(.\{-})}}}/

"syntax match orgRadioTarget contained /<<<[^>< \t][^><]*[^>< \t]>>>/ contains=orgMarkup,orgLatex
"syntax match orgTarget contained /<<<[^>< \t][^><]*[^>< \t]>>>/
"syntax match orgStatCookie contained /\[\d*%\]/
"syntax match orgStatCookie contained /\[\d*\/\d*\]/
"" syntax match orgSubscript   contained /\S_/
"" syntax match orgSuperscript contained

"syntax cluster orgMarkup contains=orgBold,orgVerbatim,orgItalic,orgStrikethrough,orgUnderline,orgCode

"" FIXME "cannot span more than 3 lines"
"syntax region orgBold contained matchgroup=orgBoldDelimiter start=// end="\S\@<=\*\*\|\*\*\S\@=" keepend contains=orgLineStart,orgItalic,@Spell

"" TODO @spell and @nospell
"" TODO: bold should allow at start of line, but that's hard to resolve with headlines. Skipping it.
"" syntax region orgBold contained keepend start=/[ \t'"({]\*/ end=/\*\([- \t.,:!?')}"]\|$\)/
"" syntax region orgBold contained keepend start=/[ \t'"({]\*/ end=/\*\([- \t.,:!?')}"]\|$\)/

"" }}}

"syntax region orgBold      start=/\(\s\|^\)\zs\*[^ \t*]/ end=/[^ \t*]\*\ze\(\s\|$\)/ containedin=ALL contains=NONE
"syntax region orgItalic    start=/\(\s\|^\)\zs\/[^ \t/]/ end=/[^ \t/]\/\ze\(\s\|$\)/ containedin=ALL contains=NONE
"syntax region orgUnderline start=/\(\s\|^\)\zs_[^ \t_]/  end=/[^ \t_]_\ze\(\s\|$\)/  containedin=ALL contains=NONE
"syntax region orgVerbatim  start=/\(\s\|^\)\zs=[^ \t=]/  end=/[^ \t=]=\ze\(\s\|$\)/  contains=NONE

"highlight orgBold      cterm=bold      gui=bold
"highlight orgItalic    cterm=italic    gui=italic
"highlight orgUnderline cterm=underline gui=underline
"highlight link orgVerbatim Normal


"" syntax region orgCode          start=/\(\s\|^\)\zs\~\S/ end=/\S\~\ze\(\s\|$\)/ containedin=ALL
"" syntax region orgStrikethrough start=/\(\s\|^\)\zs+\S/  end=/\S+\ze\(\s\|$\)/  containedin=ALL
"" highlight orgVerbatim      cterm=italic gui=italic
"" highlight orgCode          cterm=italic gui=italic
"" highlight orgStrikethrough cterm=italic gui=italic

"" NotImplemented: {{{
"" inlinetasks
"" Tables
"" }}}
