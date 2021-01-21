
let g:org#timestamp#scheduled#time = get(g:, 'org#timestamp#scheduled#time', 3)
let g:org#timestamp#deadline#time = get(g:, 'org#timestamp#deadline#time', 3)
let g:org#dir = $HOME . '/org'
let g:org#inbox = g:org#dir . '/inbox.org'
let g:org#format#space_in_empty = get(g:, 'org#format#space_in_empty', 0)

let g:org#regex#settings#todo = '\v^#\+TODO:\s*(.{-})\s*\|\s*(.+)'
let g:org#regex#property = '\v^:([[:alnum:]_-]+)(\+)?:%(\s+|$)(.*)'

" Timestamp {{{2
" formats:
" <YYYY-MM-DD dow [hh:mm[-hh:mm]]>
" <YYYY-MM-DD dow [hh:mm]>--<YYYY-MM-DD dow [hh:mm]>
" <4321-12-01 dow>
" <4321-12-01 dow 12:34>
" <4321-12-01 dow 12:34-13:24>
" <1234-05-21 dow>--<1234-05-22 dow>
" <1234-05-21 dow 12:34>--<1234-05-22 dow 13:34>
let g:org#regex#timestamp#date = '\v%((\d{4})-(\d{1,2})-(\d{1,2})(\s+[^]+0-9> -]+)?\s*)'
let g:org#regex#timestamp#date0 = '\v%(\d{4}-\d{1,2}-\d{1,2}%(\s+[^]+0-9> -]+)?\s*)'
let g:org#regex#timestamp#date1 = '\v%((\d{4}-\d{1,2}-\d{1,2}%(\s+[^]+0-9> -]+)?)\s*)'
let g:org#regex#timestamp#time = '\v%((\d{1,2}):(\d{2})\s*)'
let g:org#regex#timestamp#time0 = '\v%(\d{1,2}:\d{2}\s*)'
let g:org#regex#timestamp#time1 = '\v%((\d{1,2}:\d{2})\s*)'
let g:org#regex#timestamp#time2 = '\v%((\d{1,2}):(\d{2})\s*)'
let g:org#regex#timestamp#repeater = '\v%(([.+]?\+)(\d+)([hdwmy])>\s*)'
let g:org#regex#timestamp#repeater0 = '\v%(%([.+]?\+)\d+[hdwmy]>\s*)'
let g:org#regex#timestamp#repeater1 = '\v%((%([.+]?\+)\d+[hdwmy])>\s*)'
let g:org#regex#timestamp#delay = '\v%((--?)(\d+)([hdwmy])>\s*)'
let g:org#regex#timestamp#delay0 = '\v%(%(--?)\d+[hdwmy]>\s*)'
let g:org#regex#timestamp#delay1 = '\v%((%(--?)\d+[hdwmy])>\s*)'
let g:org#regex#timestamp#relative = '\v%(([-+]?\d+|<)([hdwmy])>)'
let g:org#regex#timestamp#relative0 = '\v%(%([-+]?\d+|<)[hdwmy]>)'

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

" List {{{2
let g:org#regex#list#bullet#ordered   = '(\d+[.)]|\a[.)])'
let g:org#regex#list#bullet#unordered = '([-+]|\s@1<=\*)'
let g:org#regex#list#bullet           = '([-+]|\s@1<=\*|\d+[.)]|\a[.)])'
let g:org#regex#list#counter_start    = '%(\[\@%(:start:)?(\d+|\a)\])'
let g:org#regex#list#checkbox         = '(\[[ Xx-]\])'
let g:org#regex#list#checkedbox       = '(\[[Xx]\])'
let g:org#regex#list#uncheckedbox     = '(\[ \])'
let g:org#regex#list#tag              = '(%(.*)\s+::)'
let g:org#regex#list#end              = '^\s*\n\s*$'

" whitespace, bullet, counter-set, checkbox, tagtext, itemtext
let g:org#regex#listitem = '\v^(\s*)' . g:org#regex#list#bullet . '\s*' . join([g:org#regex#list#counter_start, g:org#regex#list#checkbox, g:org#regex#list#tag, '(.*)'], '?\s*')

