" Note: appointment (no deadline/schedule) shows up ONLY ON the date
" SCHEDULED shows up on AND AFTER that date
" Deadline shows up on and BEFORE that date (days defined by a variable -- name please)

" Names {{{1
let org#timestamp#month_names = get(g:, 'org#timestamp#month_names', [
      \ 'january', 'february', 'march', 'april', 'may', 'june',
      \ 'july', 'september', 'october', 'november', 'december' ])

let org#timestamp#day_names = get(g:, 'org#timestamp#day_names', ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday' ])

" TODO get day of week names from strftime %A
let org#timestamp#days = get(g:, 'org#timestamp#days', [
      \ 'monday', 'tuesday', 'wednesday', 'thursday',
      \ 'friday', 'saturday', 'sunday'])

" Constants {{{1
" Read as Seconds:per.hour      seconds:per.day, etc
let s:p = {'h': 3600, 'd': 86400, 'w': 604800, 'm': 2678400, 'y': 31557600, 'ly': 31622400}
" jan: 31, feb: 28, mar: 31, apr: 30, may: 31, jun: 30
" jul: 31, aug: 31, sep: 30, oct: 31, nov: 30, dec: 31
" accumulate map ndays * 'd'

let s:months = [
      \ 2678400, 2419200, 2678400, 2592000,
      \ 2678400, 2592000, 2678400, 2678400,
      \ 2592000, 2678400, 2592000, 2678400 ]

let s:months = [
      \        0,  2678400,  5097600,  7776000,
      \ 10368000, 13046400, 15638400, 18316800,
      \ 20995200, 23587200, 26265600, 28857600 ]

let s:months_ly = [
      \        0,  2678400,  5184000,  7862400,
      \ 10454400, 13132800, 15724800, 18403200,
      \ 21081600, 23673600, 26352000, 28944000 ]

" BIG TODO: use \v\c everywhere, or \v\C

function! org#time#dict(text, ...) abort " {{{1
  " Accepts formats:
  " int
  " All timestamp formats
  " Relative keywords: today/tomorrow/yesterday/now
  " Relative times: +- h/d/w/m/y
  " Optionally in text:
  " time (if in relative times)
  " repeater/delay strings
  " Optional argument: time relative to when? accepts same arg types.

  if type(a:text) == v:t_dict
    return a:text
  endif
  let tdict = {'active': a:text !~ '\[.*\]', 'totext': function('s:totext'), 'repeater': {}, 'delay': {}}

  " Check if a simple number
  if type(a:text) == v:t_number
    let tdict.start = a:text
    let tdict.end = a:text
    return tdict
  elseif a:text =~? '[[<]\d\+[\]>]'
    let tdict.start = str2nr(a:text[1:-2])
    let tdict.end = tdict.start
    return tdict
  endif

  " Check for well defined matches first, probably most common
  if a:text =~? g:org#regex#timestamp#datetime0
    let res = matchlist(a:text, g:org#regex#timestamp#daterange2)
    if !empty(res)
      let rd1 = s:parse_full(res[1])
      let rd2 = s:parse_full(res[2])
      let rd1.end = rd2.end
      call extend(rd1.repeater, rd2.repeater, 'force')
      call extend(rd1.delay, rd2.delay, 'force')
    else
      let rd1 = s:parse_full(a:text)
    endif
    return extend(tdict, rd1)
  endif

  " If there are no well defined matches, then look for relative date, time, repeaters, delays
  " Undefined if doesn't match: <relative time> [time] [repeater] [delay]
  let [date; remainder] = split(a:text)
  try
    let tdict.start = s:parse_relative(date, get(a:, 1, localtime()))
    let tdict.end = tdict.start
  catch /^Vim\%((\a\+)\)\=:E121/ " variable doesn't exist, ftime. Don't know how to parse it
    echoerr 'Unable to parse ''' . a:text . ''' as datetime, must start with a relative date.'
  endtry

  let remainder = join(remainder)
  try
    let dt = s:parse_time(remainder)
    let tdict.start += dt.start
    let tdict.end += dt.end
  catch /^Vim\%((\a\+)\)\=:E688/ " Not enough list items -- didn't match
  endtry

  let tdict.repeater = s:parse_repeater(remainder)
  let tdict.delay = s:parse_delay(remainder)

  return tdict
endfunction

function! org#time#diff(t1, t2) abort " {{{1
  " Difference of two times or floats
  " 0 if times overlap, difference in closest start/end otherwise
  if type(a:t1) == v:t_dict && type(a:t2) == v:t_dict
    if a:t1.end < a:t2.start
      return a:t1.end - a:t2.start
    elseif a:t1.start > a:t2.end
      return a:t1.start - a:t2.end
    endif
    return 0

  elseif type(a:t1) == v:t_dict
    if a:t1.end < a:t2
      return a:t1.end - a:t2
    elseif a:t1.start > a:t2
      return a:t1.start - a:t2
    endif
    return 0

  elseif type(a:t2) == v:t_dict
    if a:t1 < a:t2.start
      return a:t1 - a:t2.start
    elseif a:t1 > a:t2.end
      return a:t1 - a:t2.end
    endif
    return 0 " times overlap
  endif

  return a:t1 - a:t2  " both numbers
endfunction

function! org#time#modify(time, mod) abort " {{{1 RENAME
  " time dict or string, then modify it
  let time = type(a:time) == v:t_dict ? copy(a:time) : org#time#dict(a:time)
  if type(a:mod) == v:t_string
    let a:mod = 1
  endif
  " let [n, t] = matchlist(a:mod, g:org#regex#timestamp#relative)[1:2]
  " let dt = s:p[t] * str2nr(n)
  let time.start += a:mod
  let time.end += a:mod
  return time
endfunction

function! org#time#repeat(time) abort " {{{1
  let time = type(a:time) == v:t_dict ? copy(a:time) : org#time#dict(a:time)
  if empty(time.repeater)
    return time
  endif
  if time.repeater.type == '.+'  " .+1m marks the date to one month after 'today'
    let today = s:parse_date(strftime('%Y-%m-%d'))
    let timestart = strftime('%R', time.start)
    let timeend = strftime('%R', time.end)
    if timestart != '00:00' || timeend != '00:00'
      let [dts, dte] = [s:parse_time(timestart).start, s:parse_time(timeend).end]
      " FIXME for <time>--<time> ?
      let [time.start, time.end] = [today + dts, today + dte]
    else
      let [time.start, time.end] = [today, today]
    endif
    let time = org#time#modify(time, time.repeater.val)
  elseif time.repeater.type == '++'  " ++1m adds 1 month at a time until it is in the future
    let now = localtime()
    let time = org#time#modify(time, time.repeater.val)
    while time.start < now
      let time = org#time#modify(time, time.repeater.val)
    endwhile
  else " +1m adds one month
    let time = org#time#modify(time, time.repeater.val)
  endif
  return time
endfunction


function! s:parse_date(date) abort " {{{1
  let [y, m, d, dow] = matchlist(a:date, g:org#regex#timestamp#date)[1:4]
  let time = float2nr((y - 1970) * 365.25 + 0.25) * s:p.d
  " Check if it's a leapyear
  let time += ((y % 4 == 0 && y % 100 > 0) || (y % 400 == 0)) ? s:months_ly[m - 1] : s:months[m - 1]
  let time += (d - 1) * s:p.d
  " timezone calc
  let [sgn, zhr, zmin] = matchlist(strftime('%z', time), '\v([+-])?(\d\d)(\d\d)')[1:3]
  let tz = (sgn == '-' ? -1 : 1) * (zhr * s:p.h + zmin * 60)
  return time - tz
endfunction

function! s:parse_delay(text) abort " {{{1
  let dmatch = matchlist(a:text, g:org#regex#timestamp#delay)
  if !empty(dmatch)
    return {'type': dmatch[1], 'val': dmatch[2] * s:p[dmatch[3]], 'text': dmatch[0]}
  endif
  return {}
endfunction

function! s:parse_full(date) abort " {{{1
  let [date, time, repeater, delay] = matchlist(a:date, g:org#regex#timestamp#full4)[1:4]
  let ftime = s:parse_date(date)
  if !empty(time)
    let tdict = s:parse_time(time)
  else
    let tdict = {'start': 0, 'end': 0}
  endif
  let [tdict.start, tdict.end] = [tdict.start + ftime, tdict.end + ftime]
  let tdict.repeater = s:parse_repeater(repeater)
  let tdict.delay = s:parse_delay(delay)
  return tdict
endfunction

function! s:parse_relative(text, relatime) abort " {{{1
  let relatime = a:relatime
  if type(relatime) == v:t_dict
    let relatime = relatime.start
  elseif type(relatime) == v:t_string
    let relatime = org#time#dict(relatime).start
  endif

  if a:text =~? '\<n\%[ow]\>'  " Keyword parsing
    return relatime
  endif
  let today = s:parse_date(strftime('%Y-%m-%d', relatime))
  if a:text =~? '\<tom\%[orrow]\>'
    return today + s:p.d
  elseif a:text =~? '\<t\%[oday]\>'  " t and to default to 'today'
    return today
  elseif a:text =~? '\<y\%[esterday]\>'
    return today - s:p.d

  elseif a:text =~? (g:org#regex#timestamp#relative0)  " relative time parsing (+1d)
    let [n, t] = matchlist(a:text, g:org#regex#timestamp#relative)[1:2]
    return (t == 'h' ? localtime() : today) + s:p[t] * str2nr(n)

  elseif a:text =~ '\v([-+]?[0-9]*)?\s*(\a+)'  " relative day of week. +2 mon for example.
    let [signnum, day] = matchlist(a:text, '\v([-+]?[0-9]*)?\s*(\a+)')[1:2]
    let day = match(g:org#timestamp#days, day)
    if day == -1
      throw 'org: Unable to parse ' . a:text
    endif
    " The logic here is a bit odd. Calc the day difference first: day - (strftime(%u) - 1)
    " For example, Tue -> Thu is +2, and Thu -> Tue should be +5, so take above and add 7 and mod 7
    " Giving us (8 + day - strftime('%u', relatime)) % 7
    " To calc. the number of weeks, just convert signnum (empty, +, -, +num, -num) to a nr. Empty
    " + and - go to zero, since we're going to 'the next DAY' by default, subtract 1 from the num
    " if positive, and subtract an additional week if sign is negative.
    let nweeks = str2nr(signnum) - 1
    if signnum !~ '^-'
      let nweeks = max([nweeks, 0])
    endif
    return today + ((8 + day - strftime('%u', relatime)) % 7) * s:p.d + nweeks * s:p.w
  endif
  return ftime
endfunction

function! s:parse_repeater(text) abort " {{{1
  let rmatch = matchlist(a:text, g:org#regex#timestamp#repeater) " type, value, unit
  if !empty(rmatch)
    return {'type': rmatch[1], 'val': rmatch[2] * s:p[rmatch[3]], 'text': rmatch[0]}
  endif
  return {}
endfunction

function! s:parse_time(time) abort " {{{1
  let [H1, M1, H2, M2] = matchlist(a:time, g:org#regex#timestamp#timerange4)[1:4]
  let start = H1 * s:p.h + M1 * 60
  let end = start
  if !empty(H2) > 0
    let end = H2 * s:p.h + M2 * 60
  endif
  return {'start': start, 'end': end}
endfunction

function! s:totext(...) abort dict " {{{1
  " time can be an ftime or a dict with keys 'start' and 'end'
  " fmt can include '[tT]?D?' or empty
  let opts = get(a:, 1, '')
  let time = opts =~# 't'
        \ || (opts !~# 'T'
        \ && strftime('%R', self.start) != '00:00'
        \ && strftime('%R', self.end) != '00:00')
  let day = opts =~# 'd' || opts !~# 'D'
  let brackets = opts =~# 'b' || opts !~# 'B'
  let repeaterdelay = opts =~# 'r' || opts !~# 'R'

  if brackets
    let [o, c] = ['[<'[self.active], ']>'[self.active]]
  else
    let [o, c] = ['', '']
  endif

  " If start & end are different, but the same day, we want [date %R-%R]"
  let timefmt = '%Y-%m-%d' . (day ? ' %a' : '') . (time ? ' %R' : '')
  if self.start == self.end " no range
    let timetext = strftime(timefmt, self.start)
  elseif time && strftime('%Y-%m-%d', self.start) == strftime('%Y-%m-%d', self.end)  " time range
    let timetext = strftime(timefmt, self.start) . strftime('-%R', self.end)
  else   " date range
    let timetext = strftime(timefmt, self.start) . c . '--' . o . strftime(timefmt, self.end)
  endif
  let timetext .= repeaterdelay && !empty(self.repeater) ? ' ' . self.repeater.text : ''
  let timetext .= repeaterdelay && !empty(self.delay) ? ' ' . self.delay.text : ''

  return o . timetext . c
endfunction

