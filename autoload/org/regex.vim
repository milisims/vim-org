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
" Timestamp {{{
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

" }}}

function! org#regex#headline(...) abort
  let keywords = join(get(a:, 1, org#keyword#all('all')), '|')
  return '\v^(\*+)\s+%((' . keywords . ')\s)?\s*%((\[#\a\])\s)?\s*(.{-})\s*(:%([[:alpha:]_@#%]+:)+)?\s*$'
endfunction
