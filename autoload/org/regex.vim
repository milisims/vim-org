let org#regex#todo = '\v^#\+TODO:\s*(.{-})\s*\|\s*(.+)'
let org#regex#property = '\v^:([[:alnum:]_-]+)(\+)?:%(\s+|$)(.*)'

" let org#property#regex#drawer_start = '^:PROPERTIES:'
" let org#property#regex#name = '\v^:([[:alnum:]_-]+):%(\s+|$)'
" let org#property#regex#value = '.*'
" let org#property#regex#drawer_end = '^:END:'

" Timestamp {{{
let org#regex#timestamp#date = '\v%((\d{4})-(\d{2})-(\d{2})(\s+[^]+0-9> -]+)?\s*)'
let org#regex#timestamp#date0 = '\v%(\d{4}-\d{2}-\d{2}%(\s+[^]+0-9> -]+)?\s*)'
let org#regex#timestamp#date1 = '\v%((\d{4}-\d{2}-\d{2}%(\s+[^]+0-9> -]+)?)\s*)'
let org#regex#timestamp#time = '\v%((\d{1,2}):(\d{2})\s*)'
let org#regex#timestamp#time0 = '\v%(\d{1,2}:\d{2}\s*)'
let org#regex#timestamp#time1 = '\v%((\d{1,2}:\d{2})\s*)'
let org#regex#timestamp#repeaterdelay = '\v%(([.+]?\+|--?)(\d+)(\c[hdwmy])\s*)'
let org#regex#timestamp#repeaterdelay0 = '\v%(%([.+]?\+|--?)\d+\c[hdwmy]\s*)'
let org#regex#timestamp#repeaterdelay1 = '\v%((%([.+]?\+|--?)\d+\c[hdwmy])\s*)'
let org#regex#timestamp#relative = '\v([-+]?[0-9]+)\s*([hdwmy])'
let org#regex#timestamp#relative0 = '\v%([-+]?[0-9]+)\s*%([hdwmy])'

let org#regex#timestamp#date_parse = '\v%(%((\d\d|\d{4})[^[:alnum:]]*)?(\d\d?|\a+)[^[:alnum:]]*)?(\d\d?|\a+)'
let org#regex#timestamp#time_parse = ''
let org#regex#timestamp#datetime_parse = org#regex#timestamp#date_parse . org#regex#timestamp#time_parse

let org#regex#timestamp#datetime  = org#regex#timestamp#date . org#regex#timestamp#time . '?' . org#regex#timestamp#repeaterdelay . '?'
let org#regex#timestamp#datetime0 = org#regex#timestamp#date0 . org#regex#timestamp#time0 . '?' . org#regex#timestamp#repeaterdelay0 . '?'
let org#regex#timestamp#datetime1 = '\v(' . org#regex#timestamp#date0 . org#regex#timestamp#time0 . '?' . org#regex#timestamp#repeaterdelay0 . '?)'
let org#regex#timestamp#datetime3 = org#regex#timestamp#date1 . org#regex#timestamp#time1 . '?' . org#regex#timestamp#repeaterdelay1 . '?'

let org#regex#timestamp#time_range = org#regex#timestamp#time . '-' . org#regex#timestamp#time
let org#regex#timestamp#time_range0 = org#regex#timestamp#time0 . '-' . org#regex#timestamp#time0
let org#regex#timestamp#time_range1 = org#regex#timestamp#time1 . '-' . org#regex#timestamp#time1

let org#regex#timestamp#datetimerange0 = org#regex#timestamp#date0 . org#regex#timestamp#time0 . '-' . org#regex#timestamp#time0 . org#regex#timestamp#repeaterdelay0 . '?'
let org#regex#timestamp#datetimerange8 = org#regex#timestamp#date . org#regex#timestamp#time . '-' . org#regex#timestamp#time . org#regex#timestamp#repeaterdelay1 . '?'

let [o, c] = ['[<[]', '[>\]]']  " open and close for ranges
let org#regex#timestamp#daterange0 = '\v' . o . org#regex#timestamp#datetime0 . c . '--' . o . org#regex#timestamp#datetime0 . c
let org#regex#timestamp#daterange2 = '\v' . o . org#regex#timestamp#datetime1 . c . '--' . o . org#regex#timestamp#datetime1 . c
let org#regex#timestamp#range0 = '\v' . o . org#regex#timestamp#datetimerange0 . c .'|' . org#regex#timestamp#daterange0
let org#regex#timestamp#plan0 = '\v%(SCHEDULED|DEADLINE|CLOSED): ' . o . org#regex#timestamp#range0 . c

unlet o c

" }}}

function! org#regex#headline(...) abort
  let keywords = join(get(a:, 1, org#keyword#all('all')), '|')
  return '\v^(\*+)\s+%((' . keywords . ')\s)?\s*%((\[#\a\])\s)?\s*(.{-})\s*(:%([[:alpha:]_@#%]+:)+)?\s*$'
endfunction
