syntax clear
" setlocal foldmethod=syntax this should go somewhere, probably

" PRIORITY						*:syn-priority*

" When several syntax items may match, these rules are used:

" 1. When multiple Match or Region items start in the same position, the item
"    defined last has priority.
" 2. A Keyword has priority over Match and Region items.
" 3. An item that starts in an earlier position has priority over items that
"    start in later positions.


syntax cluster orgGreaterElements contains=@orgHeadline,orgSection,orgGreaterBlock,orgDrawers

" TODO: if not a headline, starting with stars must start with a comma

" NOTE: empty lines belong to the largest element ending before them

" headlines {{{


" syntax region orgSection contained start=/^\s/ end=/$\_^\*/

syntax cluster orgTodoKeywords contains=orgTodo,orgNext,orgDone
syntax keyword orgTodo TODO contained
" TODO this should be not default
syntax keyword orgNext NEXT contained
syntax keyword orgDone DONE contained
" TODO: Matchadd user defined keywords on write
" STARS KEYWORD PRIORITY TITLE TAGS
" **** TODO [#A] COMMENT Title :tag:a2%:
" FIXME this one is a comment!


syntax cluster orgHeadlineItems    contains=orgHeadlineStars,orgHeadlinePriority,orgHeadlineTags,orgHeadlineConcealedStars
syntax cluster orgHeadline contains=orgHeadline1,orgHeadline2,orgHeadline3,orgHeadlineN

syntax region orgHeadline1
      \ matchgroup=orgHeadlineStars start=/^\*\{1}/ end=/$/
      \ contains=@orgHeadlineItems,@orgTodoKeywords nextgroup=orgPlanning,orgPropertyDrawer,orgSection
      \ keepend skipnl

syntax region orgHeadline2
      \ matchgroup=orgHeadlineStars start=/^\*\{2}/ end=/$/
      \ contains=@orgHeadlineItems,@orgTodoKeywords nextgroup=orgPlanning,orgPropertyDrawer,orgSection
      \ keepend skipnl

syntax region orgHeadline3
      \ matchgroup=orgHeadlineStars start=/^\*\{3}/ end=/$/
      \ contains=@orgHeadlineItems,@orgTodoKeywords nextgroup=orgPlanning,orgPropertyDrawer,orgSection
      \ keepend skipnl

syntax region orgHeadlineN
      \ matchgroup=orgHeadlineStars start=/^\*\{4,}/ end=/$/
      \ contains=@orgHeadlineItems,@orgTodoKeywords nextgroup=orgPlanning,orgPropertyDrawer,orgSection
      \ keepend skipnl

" syntax cluster orgHeadline contains=orgHeadline1,orgHeadline2,orgHeadline3,orgHeadlineN
" syntax cluster orgHeadlineItems    contains=orgHeadlineStars,orgHeadlinePriority,orgHeadlineTags,orgHeadlineConcealedStars

" Almost working:
" syntax match orgHeadline1 /\(^\*\)\@=.*/
"       \ contains=@orgHeadlineItems,@orgTodoKeywords nextgroup=orgPlanning,orgPropertyDrawer,orgSection
"       \ keepend skipnl

" syntax match orgHeadline2 /\(^\*\*\)\@=.*/
"       \ contains=@orgHeadlineItems,@orgTodoKeywords nextgroup=orgPlanning,orgPropertyDrawer,orgSection
"       \ keepend skipnl

" syntax match orgHeadline3 /\(^\*\*\*\)\@=.*/
"       \ contains=@orgHeadlineItems,@orgTodoKeywords nextgroup=orgPlanning,orgPropertyDrawer,orgSection
"       \ keepend skipnl

" syntax match orgHeadlineN /\(^\*\)\@=.*/
"       \ matchgroup=orgHeadlineStars start=/^\*\{4,}/ end=/$/
"       \ contains=@orgHeadlineItems,@orgTodoKeywords nextgroup=orgPlanning,orgPropertyDrawer,orgSection
"       \ keepend skipnl

syntax match orgHeadlineConcealedStars contained /^\**\zs\*\ze\*/ conceal cchar= 
" syntax match orgHeadlineStars    contained /^\*\+/ contains=orgConcealedStars
" https://stackoverflow.com/questions/49932880/replace-concealed-characters-with-a-space
" syntax match orgConcealedStars   contained /^\*\+/me=e-1
syntax match orgHeadlinePriority contained /\(\[#\a\]\)/
syntax match orgHeadlineTags     contained /:\%([[:alnum:]_@#%]*:\)\+/

" TODO: get headline nextgroup to work here
syntax match orgPlanning contained /^\s*DEADLINE:.*/  contains=orgTimestamp nextgroup=orgSection,orgPropertyDrawer skipnl
syntax match orgPlanning contained /^\s*SCHEDULED:.*/ contains=orgTimestamp nextgroup=orgSection,orgPropertyDrawer skipnl
syntax match orgPlanning contained /^\s*CLOSED:.*/    contains=orgTimestamp nextgroup=orgSection,orgPropertyDrawer skipnl

" TODO: all these. Add default
highlight link orgHeadline1 Statement
highlight link orgHeadline2 Function
highlight link orgHeadline3 String
highlight link orgHeadlineStars Number
highlight link orgHeadlinePriority Error
highlight link orgHeadlineTags SpecialComment
highlight link orgTodo Todo
highlight link orgNext SpecialComment
highlight link orgDone Conditional
highlight link orgPlanning Comment
" highlight link orgHeadline Comment
" }}}

syntax cluster orgStartElements contains=orgAffiliatedKeywordStart,orgGreaterBlockStart,orgDynamicBlockStart
syntax cluster orgSeparators contains=orgAttrSeparator,orgAttrValSeparator
syntax cluster orgElements contains=empty

" affiliated keywords {{{
" TODO: just above the element considered, no blank line allowed, add some indicator?

" syntax keyword orgAffKeyword HEADER NAME PLOT CAPTION RESULTS DATE TITLE AUTHOR contained
" syntax match orgAffKeywordLine /^\s*#+.*/ contains=orgAffKeyword,orgAffKeywordOptional,orgAffKeywordValue
syntax match orgAffiliatedKeywordStart '^#+' nextgroup=orgAffiliatedKeyword
syntax match orgAffiliatedKeyword /\u\+\%(\[.*\]\)\?\ze:/ contained
            \ contains=orgAffiliatedKeywordOptional nextgroup=orgAttrValSeparator
syntax match orgAffiliatedKeywordOptional /\[\zs[[:alnum:]-_]\+\ze\]/ contained
syntax match orgAttrBackendKeyword /ATTR/ contained nextgroup=orgAttrSeparator
syntax match orgAttrSeparator '_' contained nextgroup=orgAttrBackend
syntax match orgAttrBackend /[[:alnum:]-_]\+\ze:/ nextgroup=orgAttrValSeparator skipwhite contained
syntax match orgAttrValSeparator ':' contained nextgroup=orgKeywordValue skipwhite
syntax match orgKeywordValue /.*\ze$/ contained

" TODO: all these. Add default?
highlight link orgAffiliatedKeyword SpecialChar
highlight link orgAffiliatedKeywordOptional SpecialComment
highlight link orgAttrBackendKeyword SpecialChar
highlight link orgAttrBackend SpecialComment
highlight link orgKeywordValue Number
" }}}

" Greater Elements {{{
"TODO: Make sure :
" Greater elements
" Unless specified otherwise, greater elements can contain directly any other element or greater element excepted:
" elements of their own type,
" node properties, which can only be found in property drawers,
" items, which can only be found in plain lists.

" Greater Blocks {{{
" #+BEGIN_NAME PARAMETERS
" CONTENTS
" #+END_NAME
" FIXME _name on end is not being highlighted

syntax match orgGreaterBlockStart /^#+BEGIN/ contains=orgGreaterBlockBegin nextgroup=orgGreaterBlockSeparator
syntax match orgGreaterBlockBegin /BEGIN/ contained
syntax match orgGreaterBlockSeparator /_/ contained nextgroup=orgGreaterBlockName
syntax match orgGreaterBlockName /\S\+/ contained nextgroup=orgGreaterBlockParameters skipwhite
syntax match orgGreaterBlockParameters /.*$/ contained " nextgroup=orgGreaterBlockContents skipempty
" syntax region orgGreaterBlockContents matchgroup=orgGreaterBlockEndStart start='^' end='^#+' contained
            " \ contains=@orgElements nextgroup=orgGreaterBlockEnd
syntax match orgGreaterBlockStop /^#+END/ contains=orgGreaterBlockEnd nextgroup=orgGreaterBlockSeparator
syntax match orgGreaterBlockEnd /END/ contained
" Contents: Any element except an #+END_NAME on its own. Lines beginning with
" STARS must be quoted with a comma

hi link orgGreaterBlock Statement
hi link orgGreaterBlockName String
hi link orgGreaterBlockParameters Identifier
hi link orgGreaterBlockContents Number
hi link orgGreaterBlockBegin SpecialChar
hi link orgGreaterBlockEnd SpecialChar
" }}}

" Drawers {{{
" :NAME:
" CONTENTS
" :END:

" syntax match orgDrawerBegin /^:\S\+:/ contains=orgDrawerName nextgroup=orgDrawerName skipempty
" syntax match orgDrawerName /:\zs\S\+\ze:/ contained
" syntax match orgDrawerEnd /^:\zsEND\ze:/ contained
" Contents: any element except another drawer
" syntax region orgDrawerContents matchgroup=orgDrawerEnd start='^' end='' contained keepend
"             \ contains=@orgGreaterElements,@orgElements

hi link orgDrawer Statement
hi link orgDrawerName String
hi link orgDrawerParameters Identifier
hi link orgDrawerContents Number
hi link orgDrawerBegin SpecialChar
hi link orgDrawerEnd SpecialChar
" }}}

" Dynamic Blocks {{{
" #+BEGIN: NAME PARAMETERS
" CONTENTS
" #+END:

syntax match orgDynamicBlockStart /^#+BEGIN:/ contains=orgDynamicBlockBegin,orgDynamicBlockSeparator
            \ nextgroup=orgDynamicBlockName skipwhite
syntax match orgDynamicBlockBegin /BEGIN/ contained
syntax match orgDynamicBlockSeparator /:/ contained skipwhite
syntax match orgDynamicBlockName /\S\+/ contained nextgroup=orgDynamicBlockParameters skipwhite
syntax match orgDynamicBlockParameters /.*$/ contained " nextgroup=orgDynamicBlockContents skipempty
" syntax region orgDynamicBlockContents matchgroup=orgDynamicBlockEndStart start='^' end='^#+' contained
            " \ contains=@orgElements nextgroup=orgDynamicBlockEnd
" Contents: == vim called functions -- or python if defined? TODO
syntax match orgDynamicBlockStop /^#+END/ contains=orgDynamicBlockEnd nextgroup=orgDynamicBlockSeparator
syntax match orgDynamicBlockEnd /END/ contained nextgroup=orgDynamicBlockSeparator

hi link orgDynamicBlock Statement
hi link orgDynamicBlockName String
hi link orgDynamicBlockParameters Identifier
hi link orgDynamicBlockContents Number
hi link orgDynamicBlockBegin SpecialChar
hi link orgDynamicBlockEnd SpecialChar
" }}}

" Footnote Definitions {{{
" [fn:LABEL] CONTENTS

syntax match orgFootnoteDef /\[fn:[[:alnum:]-_]\+\]/ contains=orgFootnoteDefLabel
            \ nextgroup=orgFootnoteDefContents skipwhite
syntax match orgFootnoteDefLabel /:\zs[[:alnum:]-_]\+/ contained
syntax region orgFootnoteDefContents contained nextgroup=orgFootnoteDef,@orgHeadline
            \ start='.' end='\ze\n\%(^\*\|\[fn\|^$\n^$\)' keepend
" TODO: use multi end characters
" CONTENTS can contain any element excepted another footnote definition.
" It ends at the next footnote definition, the next headline,
" two consecutive empty lines or the end of buffer.

hi link orgFootnoteDef Statement
hi link orgFootnoteDefLabel String
hi link orgFootnoteDefContents Identifier
" }}}

" Lists Definitions {{{

" TODO nest greater elements and inlinetasks

syntax region orgListItem matchgroup=orgListLeader
      \ start=/^\z(\s*\)\zs[-+]/ start=/^\z(\s*\)\zs\(\d\+\|\a\)[.)]/ start=/^\z(\s\+\)\zs\*/
      \ end=/\ze\n\z1\S/ end=/\ze\n^$\n^$/ end=/\ze\n\z1\@!/
      \ contains=orgListItem,orgListCheck,orgListTag keepend
syntax match orgListCheck  contained nextgroup=orgListTag              skipwhite /\(\[[xX -]\]\)/
syntax match orgListTag /\(\w\|\s\)*::/ contained
" FIXME: should be 'any character' for orglist tag -- If we just use .*, it clobbers the check

" hi link orgListItem String
hi link orgListLeader Number
hi link orgListCheck Todo
hi link orgListTag SpecialComment
" }}}

" Property Drawers {{{
" :PROPERTIES:
" CONTENTS
" :END:
syntax region orgPropertyDrawer contained keepend matchgroup=orgPropertyDrawerEnds start=/^:PROPERTIES:$/ end=/^:END:$/ contains=orgNodeProperty
syntax region orgNodeProperty   contained keepend matchgroup=orgPropertyName       start=/^:\S\+[^+]:/    end=/$/       oneline

" hi link orgNodeProperty SpecialComment
hi link orgPropertyDrawerEnds Comment
hi link orgPropertyName Identifier
" }}}

" }}}

" Elements {{{
syntax cluster orgElements contains=orgHorizontalRule,orgComment
syntax match orgHorizontalRule /\s*-\{5,}\s*$/
syntax match orgComment /^#$/
syntax match orgComment /^#\s\+.*$/ contains=orgTodo
highlight link orgComment Comment
" }}}

" Objects {{{
syntax cluster orgObjects contains=orgEntity,orgLatex,orgExportSnippet,orgFootnoteReference,orgLink
syntax cluster orgObjects add=orgMacro,orgRadioTarget,orgTarget,@orgMarkup

syntax region orgLatex contained keepend start=/\\\a\+{/ end=/}/ oneline
" FIXME: next isn't quite right. Can't contain {}
syntax region orgLatex contained keepend start=/\\\a\+\[/ end=/]/ oneline
syntax region orgLatex contained keepend start=/\\(/ end=/\\)/
syntax region orgLatex contained keepend start=/\\\[/ end=/\\]/
syntax region orgLatex contained keepend start=/\\(/ end=/\\)/
syntax region orgLatex contained keepend start=/\$\$/ end=/\$\$/
syntax match orglatex contained  /\([^$]\|^\)\$[^ \t.,?;'"]\$\([[:punct:] ]\|$\)/
" TODO: missing PRE$BORDER1 BODY BORDER2$POST

syntax region orgExportSnippet contained keepend start=/@@\w\+:/ end=/@@/

syntax match orgFootnoteReference contained /\[fn:[[:alnum:]_-]\+\]/
syntax region orgFootnoteReference contained keepend start=/\[fn:[[:alnum:]_-]*:/ end=/\]/ contains=@orgObjects
" Previous: inline and anonymous. If fn:LABEL is zero length, it is anonymous

" TODO: link types: radio, protocol, plain
" syntax match orgLink

" TODO: separate arguments highlighting.
syntax match orgMacro contained /{{{\a[[:alnum:]_-]*(.\{-})}}}/

syntax match orgRadioTarget contained /<<<[^>< \t][^><]*[^>< \t]>>>/ contains=orgMarkup,orgLatex
syntax match orgTarget contained /<<<[^>< \t][^><]*[^>< \t]>>>/
syntax match orgStatCookie contained /\[\d*%\]/
syntax match orgStatCookie contained /\[\d*\/\d*\]/
" syntax match orgSubscript   contained /\S_/
" syntax match orgSuperscript contained

syntax region orgTimestamp oneline keepend transparent start='<'  end='>'  contains=orgDate,orgTime,orgRepeater
syntax region orgTimestamp oneline keepend transparent start='\[' end=']'  contains=orgDate,orgTime,orgRepeater
syntax match  orgDate      contained  /\d\{4}-\d\d-\d\d\s\a\+/    transparent
syntax match  orgTime      contained  /\d\{1,2}:\d\d/                 transparent
syntax match  orgRepeater  contained  /\([+-]{1,2}\|\.+\)\d\+[hdwmy]/ transparent

syntax cluster orgMarkup contains=orgBold,orgVerbatim,orgItalic,orgStrikethrough,orgUnderline,orgCode

" FIXME "cannot span more than 3 lines"
syntax region orgBold contained matchgroup=orgBoldDelimiter start=// end="\S\@<=\*\*\|\*\*\S\@=" keepend contains=orgLineStart,orgItalic,@Spell

" TODO @spell and @nospell
" TODO: bold should allow at start of line, but that's hard to resolve with headlines. Skipping it.
" syntax region orgBold contained keepend start=/[ \t'"({]\*/ end=/\*\([- \t.,:!?')}"]\|$\)/
" syntax region orgBold contained keepend start=/[ \t'"({]\*/ end=/\*\([- \t.,:!?')}"]\|$\)/

" }}}

" NotImplemented: {{{
" inlinetasks
" Tables
" }}}

" Dev-help {{{
nnoremap <F7> :set ft=org<CR>:call <SID>SynStack()<CR>
function! <SID>SynStack()
  if !exists('*synstack')
    return
  endif
  let l:group = synIDattr(synID(line('.'), col('.'), 1), 'name')
  echo l:group map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc
" }}}
