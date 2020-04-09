let g:org#regex#todo = '\v^#\+TODO:\s*(.{-})\s*\|\s*(.+)'
let g:org#regex#property = '\v^:([[:alnum:]_-]+)(\+)?:%(\s+|$)(.*)'

" let g:org#property#regex#drawer_start = '^:PROPERTIES:'
" let g:org#property#regex#name = '\v^:([[:alnum:]_-]+):%(\s+|$)'
" let g:org#property#regex#value = '.*'
" let g:org#property#regex#drawer_end = '^:END:'

" formats:
" <YYYY-MM-DD dow [hh:mm[-hh:mm]]>
" <YYYY-MM-DD dow [hh:mm]>--<YYYY-MM-DD dow [hh:mm]>
" <4321-12-01 dow>
" <4321-12-01 dow 12:34>
" <4321-12-01 dow 12:34-13:24>
" <1234-05-21 dow>--<1234-05-22 dow>
" <1234-05-21 dow 12:34>--<1234-05-22 dow 13:34>
" Timestamp {{{1
let g:org#regex#timestamp#date = '\v%((\d{4})-(\d{2})-(\d{2})(\s+[^]+0-9> -]+)?\s*)'
let g:org#regex#timestamp#date0 = '\v%(\d{4}-\d{2}-\d{2}%(\s+[^]+0-9> -]+)?\s*)'
let g:org#regex#timestamp#date1 = '\v%((\d{4}-\d{2}-\d{2}%(\s+[^]+0-9> -]+)?)\s*)'
let g:org#regex#timestamp#time = '\v%((\d{1,2}):(\d{2})\s*)'
let g:org#regex#timestamp#time0 = '\v%(\d{1,2}:\d{2}\s*)'
let g:org#regex#timestamp#time1 = '\v%((\d{1,2}:\d{2})\s*)'
let g:org#regex#timestamp#time2 = '\v%((\d{1,2}):(\d{2})\s*)'
let g:org#regex#timestamp#repeater = '\v%(([.+]?\+)(\d+)(\c[hdwmy])>\s*)'
let g:org#regex#timestamp#repeater0 = '\v%(%([.+]?\+)\d+\c[hdwmy]>\s*)'
let g:org#regex#timestamp#repeater1 = '\v%((%([.+]?\+)\d+\c[hdwmy])>\s*)'
let g:org#regex#timestamp#delay = '\v%((--?)(\d+)(\c[hdwmy])>\s*)'
let g:org#regex#timestamp#delay0 = '\v%(%(--?)\d+\c[hdwmy]>\s*)'
let g:org#regex#timestamp#delay1 = '\v%((%(--?)\d+\c[hdwmy])>\s*)'
let g:org#regex#timestamp#relative = '\v([-+]?[0-9]+)\s*([hdwmy])>'
let g:org#regex#timestamp#relative0 = '\v%([-+]?[0-9]+)\s*%([hdwmy])>'
" TODO should we add > to all?

let [o, c] = ['[<[]', '[>\]]']  " open and close for ranges
let g:org#regex#timestamp#repeaterdelay0 = org#regex#timestamp#repeater0 . '?' . org#regex#timestamp#delay0 . '?'
let g:org#regex#timestamp#repeaterdelay2 = org#regex#timestamp#repeater1 . '?' . org#regex#timestamp#delay1 . '?'

let g:org#regex#timestamp#timerange0 = '\v%(' . org#regex#timestamp#time0 . '%(-' . org#regex#timestamp#time0 . ')?)'
let g:org#regex#timestamp#timerange1 = '\v(' . org#regex#timestamp#time0 . '%(-' . org#regex#timestamp#time0 . ')?)'
let g:org#regex#timestamp#timerange2 = '\v%(' . org#regex#timestamp#time1 . '%(-' . org#regex#timestamp#time1 . ')?)'
let g:org#regex#timestamp#timerange4 = '\v%(' . org#regex#timestamp#time2 . '%(-' . org#regex#timestamp#time2 . ')?)'

let g:org#regex#timestamp#datetime0 = org#regex#timestamp#date0 . org#regex#timestamp#timerange0 . '?'
let g:org#regex#timestamp#datetime2 = org#regex#timestamp#date1 . org#regex#timestamp#timerange1 . '?'
let g:org#regex#timestamp#full0 = org#regex#timestamp#datetime0 . org#regex#timestamp#repeaterdelay0
let g:org#regex#timestamp#full4 = org#regex#timestamp#datetime2 . org#regex#timestamp#repeaterdelay2
let g:org#regex#timestamp#daterange0 = '\v'.o. org#regex#timestamp#full0 .c. '--' .o. org#regex#timestamp#full0 .c
let g:org#regex#timestamp#daterange2 = '\v'.o. '(' . org#regex#timestamp#full0 . ')' .c. '--' .o. '(' . org#regex#timestamp#full0 . ')' .c

unlet o c

" List {{{1

" 346:(defconst org-list-end-re "^[ \t]*\n[ \t]*\n"
" 347-  "Regex matching the end of a plain list.")
" 348-
" 349:(defconst org-list-full-item-re
" 350-  (concat "^[ \t]*\\(\\(?:[-+*]\\|\\(?:[0-9]+\\|[A-Za-z]\\)[.)]\\)\\(?:[ \t]+\\|$\\)\\)"
" 351-      "\\(?:\\[@\\(?:start:\\)?\\([0-9]+\\|[A-Za-z]\\)\\][ \t]*\\)?"
" 352-      "\\(?:\\(\\[[ X-]\\]\\)\\(?:[ \t]+\\|$\\)\\)?"
" 353-      "\\(?:\\(.*\\)[ \t]+::\\(?:[ \t]+\\|$\\)\\)?")
" 354-  "Matches a list item and puts everything into groups:
" 355-group 1: bullet
" 356-group 2: counter
" 357-group 3: checkbox
" 358-group 4: description tag")

" group 1: bullet          "\v^\s*(([-+*]|(\d+|\a)[.)])(\s+|$))"
" group 2: counter-start   "\v(\[@(:start:)?(\d+|\a)\]\s*)?"
" group 3: checkbox        "\v((\[[ Xx-]\])(\s+|$))?"
" group 4: description-tag "\v((.*)\s+::(\s+|$))?"
" list end:                "^\s*\n\s*\n"

" Rules for regex: only group the components we care about potentially returning.
" Almost never whitespace.
let g:org#regex#list#ordered_bullet   = '\v^\s*(\d+|\a)[.)]%(\s+|$)'
let g:org#regex#list#unordered_bullet = '\v^\s*([-+]|\s\*)%(\s+|$)'
let g:org#regex#list#bullet           = '\v^\s*(%([-+*]|%(\d+|\a)[.)]))%(\s+|$)'
let g:org#regex#list#counter_start    = '\v(\[\@%(:start:)?(\d+|\a)\]\s*)'
let g:org#regex#list#checkbox         = '\v(\[[ Xx-]\]%(\s+|$))'
let g:org#regex#list#checkedbox       = '\v(\[[Xx]\]%(\s+|$))'
let g:org#regex#list#uncheckedbox     = '\v(\[[ ]\]%(\s+|$))'
let g:org#regex#list#tag              = '\v(%(.*)\s+::%(\s+|$))'
let g:org#regex#list#end              = '^\s*\n\s*\n'

" RENAME:

let g:org#regex#list#upto#checkbox = g:org#regex#list#bullet . g:org#regex#list#counter_start[2:]  . '?' . g:org#regex#list#checkbox[2:]
let g:org#regex#list#upto#checkedbox = g:org#regex#list#bullet . g:org#regex#list#counter_start[2:] . '?' . g:org#regex#list#checkedbox[2:]

let g:org#regex#list#decompose = [org#regex#list#bullet, org#regex#list#counter_start[2:],
      \ org#regex#list#checkbox[2:], org#regex#list#tag[2:], org#regex#list#end]
" let org#regex#list#full = join(org#regex#list#decompose, '')

" others {{{1

function! org#regex#headline(...) abort
  let keywords = join(get(a:, 1, org#keyword#all('all')), '|')
  return '\v^(\*+)\s+%((' . keywords . ')\s)?\s*%((\[#\a\])\s)?\s*(.{-})\s*(:%([[:alpha:]_@#%]+:)+)?\s*$'
endfunction
