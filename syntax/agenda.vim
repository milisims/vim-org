" syntax match orgAgendaTitle /^\S.*$/ nextgroup=orgAgendaBlockFile skipnl
" syntax match orgAgendaBlockFile /^\s\+\S\+/ contained nextgroup=orgAgendaBlockPlan skipwhite
" syntax match orgAgendaBlockPlan /\S\+/ contained nextgroup=orgAgendaBlockKeyword,orgAgendaBlockHeadline
" syntax match orgAgendaBlockHeadline /.*$/ contained nextgroup=orgAgendaBlockFile skipnl
" syntax match orgAgendaBlockKeyword /\s\u*/ contained nextgroup=orgAgendaBlockHeadline skipwhite
" " keyword after headline for priority

" hi link orgAgendaTitle Statement
" hi link orgAgendaBlockFile Function
" hi link orgAgendaBlockPlan Comment
" hi link orgAgendaBlockKeyword Todo
" " hi link orgAgendaBlockHeadline Identifier
