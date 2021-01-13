syn clear

"syntax cluster orgGreaterElements contains=@orgHeadline,orgSection,orgGreaterBlock,orgDrawers

syn cluster orgHeadline contains=orgHeadline1,orgHeadline2,orgHeadline3
syn cluster orgHeadline add=orgHeadline4,orgHeadline5,orgHeadline6,orgHeadline7
syn cluster orgHeadline add=orgHeadline8,orgHeadline9,orgHeadlineN

" syntax region orgSection start=/^\z(\*\+\)[^*]/ end=/^\ze\(\z1\*\)\@!\*\+/ fold transparent contains=@orgHeadline,orgSection

" syntax cluster orgSection contains=orgSection1,orgSection2,orgSection3,orgSection4,orgSection5,orgSection6,orgSection7,orgSection8,orgSection9
" syntax region orgSection1 start=/^\*\{1}[^*]/ end=/^\%(\*\{2}\)\@!\ze\*\+/ fold transparent contains=@orgHeadline,@orgSection
" syntax region orgSection2 start=/^\*\{2}[^*]/ end=/^\%(\*\{3}\)\@!\ze\*\+/ fold transparent contains=@orgHeadline
" syntax region orgSection3 start=/^\*\{3}[^*]/ end=/^\ze\%(\*\{4}\)\@!\*\+/ fold transparent contains=@orgHeadline
" syntax region orgSection4 start=/^\*\{4}[^*]/ end=/^\ze\%(\*\{5}\)\@!\*\+/ fold transparent contains=@orgHeadline
" syntax region orgSection5 start=/^\*\{5}[^*]/ end=/^\ze\%(\*\{6}\)\@!\*\+/ fold transparent contains=@orgHeadline
" syntax region orgSection6 start=/^\*\{6}[^*]/ end=/^\ze\%(\*\{7}\)\@!\*\+/ fold transparent contains=@orgHeadline
" syntax region orgSection7 start=/^\*\{7}[^*]/ end=/^\ze\%(\*\{8}\)\@!\*\+/ fold transparent contains=@orgHeadline
" syntax region orgSection8 start=/^\*\{8}[^*]/ end=/^\ze\%(\*\{9}\)\@!\*\+/ fold transparent contains=@orgHeadline
" syntax region orgSection9 start=/^\*\{9}[^*]/ end=/^\ze\%(\*\{10,}\)\@!\*\+/ fold transparent contains=@orgHeadline

" syntax match orgHeadline /^\*\+[^*].*$/   contains=orgHeadlines nextgroup=@orgPlanning,orgPropertyDrawer skipnl

syn match orgHeadline1 /^\*\{1}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syn match orgHeadline2 /^\*\{2}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syn match orgHeadline3 /^\*\{3}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syn match orgHeadline4 /^\*\{4}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syn match orgHeadline5 /^\*\{5}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syn match orgHeadline6 /^\*\{6}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syn match orgHeadline7 /^\*\{7}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syn match orgHeadline8 /^\*\{8}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syn match orgHeadline9 /^\*\{9}[^*].*$/   contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl
syn match orgHeadlineN /^\*\{10,}[^*].*$/ contains=orgHeadlineStars nextgroup=@orgPlanning,orgPropertyDrawer skipnl

syn match orgHeadlineStars contained /^\*\+/ skipwhite
      \ contains=orgHeadlineInnerStar,orgHeadlineLastStar
      \ nextgroup=orgHeadlineText,orgHeadlinePriority,orgHeadlineKeywords
syn match orgHeadlineInnerStar contained /\*/ conceal cchar=-
      \ nextgroup=orgHeadlineInnerStar,orgHeadlineLastStar
syn match orgHeadlineLastStar contained /\*\ze\%([^*]\|$\)/

syn match orgHeadlineText contained /\S.*$/ contains=orgHeadlineTags,@Spell transparent
syn match orgHeadlineTags contained /:\%([[:alnum:]_@#%]*:\)\+/ contains=@NoSpell
syn match orgHeadlinePriority contained /\[#\a\]/ nextgroup=orgHeadlineText skipwhite

syn match orgHeadlineKeywords contained transparent /\u\+\ze\>/
      \ nextgroup=orgHeadlinePriority,orgHeadlineText skipwhite
syn keyword orgTodo TODO containedin=orgHeadlineKeywords,@orgHeadline
syn keyword orgDone DONE containedin=orgHeadlineKeywords,@orgHeadline

hi link orgHeadline1 Statement
hi link orgHeadline2 Function
hi link orgHeadline3 String
hi link orgHeadline4 Identifier
hi link orgHeadline5 Function
hi link orgHeadline6 String
hi link orgHeadline7 Identifier
hi link orgHeadline8 Function
hi link orgHeadline9 String
hi link orgHeadlineN Identifier

hi link orgHeadlineInnerStar Comment
hi link orgHeadlineLastStar Number
hi link orgTodo Todo
hi link orgDone Conditional

hi link orgHeadlinePriority Error
hi link orgHeadlineTags SpecialComment
" highlight link orgHeadlineText Normal

" TODO color different levels of headlines with matchadd?

" NOTE: empty lines belong to the largest element ending before them

syn cluster orgPlanning contains=orgPlanDeadline,orgPlanScheduled,orgPlanClosed,orgPlanTime

syn match orgPlanDeadline  contained /\s*\zsDEADLINE:/            nextgroup=orgPlanTime skipwhite
syn match orgPlanScheduled contained /\s*\zsSCHEDULED:/           nextgroup=orgPlanTime skipwhite
syn match orgPlanClosed    contained /\s*\zsCLOSED:/              nextgroup=orgPlanTime skipwhite
syn match orgPlanTime      contained /\s*\zs<\d\{4}.*>\(--<.*>\)\?/     nextgroup=@orgPlanning,orgPropertyDrawer skipwhite skipnl contains=@orgTimestampElements
syn match orgPlanTime      contained /\s*\zs\[\d\{4}.*\]\(--\[.*\]\)\?/ nextgroup=@orgPlanning,orgPropertyDrawer skipwhite skipnl contains=@orgTimestampElements

hi link orgPlanDeadline  Comment
hi link orgPlanScheduled Comment
hi link orgPlanClosed    Comment
hi link orgPlanTime      Comment
hi link orgPlanning      Comment

syn cluster orgTimestampElements contains=orgDate,orgTime,orgTimeRepeat,orgTimeDelay

syn match orgDate       contained /\d\{4}-\d\d-\d\d\s\a\+/
syn match orgTime       contained /\d\{1,2}:\d\d/
syn match orgTimeRepeat contained /\v[.+]?\+\d+\c[hdwmy]>\s*/
syn match orgTimeDelay  contained /\v([+-]{1,2}|\.+)\d+[hdwmy]/

hi link orgDate              Comment
hi link orgTime              Comment
hi link orgTimeRepeat        Comment
hi link orgTimeDelay         Comment
hi link orgTimestampElements Comment

syn region orgListItem matchgroup=orgListLeader
      \ start=/^\z(\s*\)[-+]/ start=/^\z(\s*\)\(\d\+\|\a\)[.)]/ start=/^\z(\s\+\)\*/
      \ end=/\ze\n\z1\S/ end=/\ze\n^$\n^$/ end=/\ze\n\z1\@!/
      \ contains=orgListItem,orgListCheck,orgListTag,@Spell keepend
syn match orgListCheck  contained nextgroup=orgListTag              skipwhite /\(\[[xX -]\]\)/
syn match orgListTag /\(\w\|\s\)*::/ contained
" FIXME: should be 'any character' for orglist tag -- If we just use .*, it clobbers the check

hi link orgListLeader Number
hi link orgListCheck  Todo
hi link orgListTag    SpecialComment

syn region orgPropertyDrawer contained keepend matchgroup=orgPropertyDrawerEnds start=/^\s*:PROPERTIES:$/ end=/^\s*:END:$/ contains=orgNodeProperty,orgNodeMultiProperty fold
syn region orgNodeProperty contained keepend matchgroup=orgPropertyName start=/^\s*:\S\+[^+]:/ end=/$/ oneline
syn region orgNodeMultiProperty contained keepend matchgroup=orgPropertyName start=/^\s*:\S\++:/ end=/$/ oneline

hi link orgNodeProperty       SpecialComment
hi link orgNodeMultiProperty  SpecialComment
hi link orgPropertyDrawerEnds Comment
hi link orgPropertyName       Identifier

syn sync match orgSyncPropertyDrawer grouphere orgPropertyDrawer /\v^(:PROPERTIES:$)@=/
" syntax sync match orgSync grouphere orgSection /\v^%(\*+)@=/

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
syn match orgComment /^\s*#\s\+.*$/
"syntax match orgComment /^#\s\+.*$/ contains=orgTodo
hi link orgComment Comment
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

syn region orgBold      start=/\(\s\|^\)\zs\*[^ \t*]/ end=/[^ \t*]\*\ze\(\s\|$\)/ containedin=ALL contains=NONE
syn region orgItalic    start=/\(\s\|^\)\zs\/[^ \t/]/ end=/[^ \t/]\/\ze\(\s\|$\)/ containedin=ALL contains=NONE
syn region orgUnderline start=/\(\s\|^\)\zs_[^ \t_]/  end=/[^ \t_]_\ze\(\s\|$\)/  containedin=ALL contains=NONE
syn region orgVerbatim  start=/\(\s\|^\)\zs=[^ \t=]/  end=/[^ \t=]=\ze\(\s\|$\)/  contains=NONE

hi orgBold      cterm=bold      gui=bold
hi orgItalic    cterm=italic    gui=italic
hi orgUnderline cterm=underline gui=underline
hi link orgVerbatim Normal


"" syntax region orgCode          start=/\(\s\|^\)\zs\~\S/ end=/\S\~\ze\(\s\|$\)/ containedin=ALL
"" syntax region orgStrikethrough start=/\(\s\|^\)\zs+\S/  end=/\S+\ze\(\s\|$\)/  containedin=ALL
"" highlight orgVerbatim      cterm=italic gui=italic
"" highlight orgCode          cterm=italic gui=italic
"" highlight orgStrikethrough cterm=italic gui=italic

"" NotImplemented: {{{
"" inlinetasks
"" Tables
"" }}}

let b:current_syntax = "org"
