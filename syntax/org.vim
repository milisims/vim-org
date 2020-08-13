syntax clear

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

syntax cluster orgPlanning contains=orgPlanDeadline,orgPlanScheduled,orgPlanClosed,orgPlanTime

syntax match orgPlanDeadline  contained /\s*\zsDEADLINE:/            nextgroup=orgPlanTime skipwhite
syntax match orgPlanScheduled contained /\s*\zsSCHEDULED:/           nextgroup=orgPlanTime skipwhite
syntax match orgPlanClosed    contained /\s*\zsCLOSED:/              nextgroup=orgPlanTime skipwhite
syntax match orgPlanTime      contained /\s*\zs<.*>\(--<.*>\)\?/     nextgroup=@orgPlanning,orgPropertyDrawer skipwhite skipnl contains=@orgTimestampElements
syntax match orgPlanTime      contained /\s*\zs\[.*\]\(--\[.*\]\)\?/ nextgroup=@orgPlanning,orgPropertyDrawer skipwhite skipnl contains=@orgTimestampElements

highlight link orgPlanDeadline  Comment
highlight link orgPlanScheduled Comment
highlight link orgPlanClosed    Comment
highlight link orgPlanTime      Comment
highlight link orgPlanning      Comment

syntax cluster orgTimestampElements contains=orgDate,orgTime,orgTimeRepeat,orgTimeDelay

syntax match orgDate       contained /\d\{4}-\d\d-\d\d\s\a\+/
syntax match orgTime       contained /\d\{1,2}:\d\d/
syntax match orgTimeRepeat contained /\v[.+]?\+\d+\c[hdwmy]>\s*/
syntax match orgTimeDelay  contained /\v([+-]{1,2}|\.+)\d+[hdwmy]/

highlight link orgDate              Comment
highlight link orgTime              Comment
highlight link orgTimeRepeat        Comment
highlight link orgTimeDelay         Comment
highlight link orgTimestampElements Comment

syntax region orgListItem matchgroup=orgListLeader
      \ start=/^\z(\s*\)[-+]/ start=/^\z(\s*\)\(\d\+\|\a\)[.)]/ start=/^\z(\s\+\)\*/
      \ end=/\ze\n\z1\S/ end=/\ze\n^$\n^$/ end=/\ze\n\z1\@!/
      \ contains=orgListItem,orgListCheck,orgListTag,@Spell keepend
syntax match orgListCheck  contained nextgroup=orgListTag              skipwhite /\(\[[xX -]\]\)/
syntax match orgListTag /\(\w\|\s\)*::/ contained
" FIXME: should be 'any character' for orglist tag -- If we just use .*, it clobbers the check

hi link orgListLeader Number
hi link orgListCheck  Todo
hi link orgListTag    SpecialComment

syntax region orgPropertyDrawer contained keepend matchgroup=orgPropertyDrawerEnds start=/^\s*:PROPERTIES:$/ end=/^\s*:END:$/ contains=orgNodeProperty,orgNodeMultiProperty fold
syntax region orgNodeProperty contained keepend matchgroup=orgPropertyName start=/^\s*:\S\+[^+]:/ end=/$/ oneline
syntax region orgNodeMultiProperty contained keepend matchgroup=orgPropertyName start=/^\s*:\S\++:/ end=/$/ oneline

hi link orgNodeProperty       SpecialComment
hi link orgNodeMultiProperty  SpecialComment
hi link orgPropertyDrawerEnds Comment
hi link orgPropertyName       Identifier

syntax sync match orgSyncPropertyDrawer grouphere orgPropertyDrawer /\v^(:PROPERTIES:$)@=/
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

syntax region orgBold      start=/\(\s\|^\)\zs\*[^ \t*]/ end=/[^ \t*]\*\ze\(\s\|$\)/ containedin=ALL contains=NONE
syntax region orgItalic    start=/\(\s\|^\)\zs\/[^ \t/]/ end=/[^ \t/]\/\ze\(\s\|$\)/ containedin=ALL contains=NONE
syntax region orgUnderline start=/\(\s\|^\)\zs_[^ \t_]/  end=/[^ \t_]_\ze\(\s\|$\)/  containedin=ALL contains=NONE
syntax region orgVerbatim  start=/\(\s\|^\)\zs=[^ \t=]/  end=/[^ \t=]=\ze\(\s\|$\)/  contains=NONE

highlight orgBold      cterm=bold      gui=bold
highlight orgItalic    cterm=italic    gui=italic
highlight orgUnderline cterm=underline gui=underline
highlight link orgVerbatim Normal


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
