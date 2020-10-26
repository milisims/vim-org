" Note: appointment (no deadline/schedule) shows up ONLY ON the date
" SCHEDULED shows up on AND AFTER that date
" Deadline shows up on and BEFORE that date (days defined by a variable -- name please)

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
  try
    if string(str2nr(a:text)) == a:text
      return s:dict_from_ftime(a:text)
    endif
  catch
  endtry

  let relatime = get(a:, 1, localtime())
  if type(relatime) == v:t_dict
    let relatime = relatime.start
  elseif type(relatime) == v:t_string
    let relatime = org#time#dict(relatime).start
  endif

  let opts = {'active': a:text !~ '\[.*\]'}
  let [text; repdel] = split(split(a:text, opts.active ? '[><]' : '[\[\]]')[0])

  if text =~? '\<n\%[ow]\>'  " Keyword parsing
    let ftime = relatime
  elseif text =~? '\<tom\%[orrow]\>'
    let ftime = s:text2ftimerange(strftime('%Y-%m-%d', relatime))[0][0] + s:p.d
  elseif text =~? '\<t\%[oday]\>'  " t and to default to 'today'
    let ftime = s:text2ftimerange(strftime('%Y-%m-%d', relatime))[0][0]
  elseif text =~? '\<y\%[esterday]\>'
    let ftime = s:text2ftimerange(strftime('%Y-%m-%d', relatime))[0][0] - s:p.d

  elseif text =~? g:org#regex#timestamp#relative0  " relative time parsing (+1d)
    let [n, t] = matchlist(text, g:org#regex#timestamp#relative)[1:2]
    let ftime = t == 'h' ? localtime() : s:text2ftimerange(strftime('%Y-%m-%d', relatime))[0][0]
    let ftime += s:p[t] * str2nr(n)

  elseif a:text =~? g:org#regex#timestamp#datetime0  " date parsing. Want a:text here.
    let res = matchlist(a:text, g:org#regex#timestamp#daterange2)
    " ftime is a list here, handled in dict_from_ftime
    if !empty(res)
      let [r1ftime, rd1] = s:text2ftimerange(res[1])
      let [r2ftime, rd2] = s:text2ftimerange(res[2])
      let ftime = [r1ftime[0], r2ftime[1]]
      let repdel = extend(rd1, rd2, 'force')
    else
      let [ftime, repdel] = s:text2ftimerange(a:text)
    endif
    call extend(opts, repdel, 'force')

  elseif text =~ '\v([-+]?[0-9]*)?\s*(\a+)'  " relative day of week. +2 mon for example.
    let [sn, day] = matchlist(text, '\v([-+]?[0-9]*)?\s*(\a+)')[1:2]
    let day = matchstrpos(g:org#timestamp#days, day)[1]
    if day == -1
      throw 'org: Unable to parse ' . a:text
    endif
    let nn = max([str2nr(sn) - 1, 0])
    if day == strftime('%u') - 1
    endif
    let today = s:text2ftimerange(strftime('%Y-%m-%d', relatime))[0][0]
    " TODO option %u vs %w
    if day == strftime('%u') - 1
      let nn += nn >= 0 ? 1 : -1
    endif
    let ftime = today + ((day - strftime('%u') + 1) % 7) * s:p.d + nn * s:p.w
  endif

  " Except in the case of date parsing, process 'opts'
  if type(repdel) == v:t_list
    for rd in repdel
      let dmatch = matchlist(rd, g:org#regex#timestamp#delay)
      if !empty(dmatch)
        let opts.delay = {'type': dmatch[1], 'val': dmatch[2] * s:p[dmatch[3]], 'text': rd}
        continue
      endif

      let rmatch = matchlist(rd, g:org#regex#timestamp#repeater) " type, value, unit
      if !empty(rmatch)
        let opts.repeater = {'type': rmatch[1], 'val': rmatch[2] * s:p[rmatch[3]], 'text': rd}
      endif
    endfor
  endif

  if !exists('ftime')
    throw 'org: Unable to parse ' . a:text
  endif
  return s:dict_from_ftime(ftime, opts)
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

function! s:text2ftimerange(date, ...) abort " {{{1

  let [date, time, repeat, delay] = matchlist(a:date, g:org#regex#timestamp#full4)[1:4]
  let [y, m, d, dow] = matchlist(date, g:org#regex#timestamp#date)[1:4]
  let [H1, M1, H2, M2] = [0, 0, '', '']
  if !empty(time)
    let [H1, M1, H2, M2] = matchlist(time, g:org#regex#timestamp#timerange4)[1:4]
  endif

  let repdel = {}
  let rmatch = matchlist(repeat, g:org#regex#timestamp#repeater) " type, value, unit
  if !empty(rmatch)
    let repdel.repeater = {'type': rmatch[1], 'val': rmatch[2] * s:p[rmatch[3]], 'text': repeat}
  endif
  let dmatch = matchlist(delay, g:org#regex#timestamp#delay)
  if !empty(dmatch)
    let repdel.delay = {'type': dmatch[1], 'val': dmatch[2] * s:p[dmatch[3]], 'text': delay}
  endif

  let time = float2nr((y - 1970) * 365.25 + 0.25) * s:p.d
  " Check if it's a leapyear
  let time += ((y % 4 == 0 && y % 100 > 0) || (y % 400 == 0)) ? s:months_ly[m - 1] : s:months[m - 1]
  let time += (d - 1) * s:p.d
  " timezone calc
  let [sgn, zhr, zmin] = matchlist(strftime('%z', time), '\v([+-])?(\d\d)(\d\d)')[1:3]
  let tz = (sgn == '-' ? -1 : 1) * (zhr * s:p.h + zmin * 60)
  let start = time + H1 * s:p.h + M1 * 60 - tz
  let end = start
  if !empty(H2) > 0
    let end = time + H2 * s:p.h + M2 * 60 - tz
  endif
  return [[start, end], repdel]
endfunction

function! org#time#modify(time, mod) abort " {{{1 RENAME
  " time dict or string, then modify it
  let time = type(a:time) == v:t_dict ? a:time : org#time#dict(a:time)
  if type(a:mod) == v:t_string
    let a:mod = 1
  endif
  let [n, t] = matchlist(a:mod, g:org#regex#timestamp#relative)[1:2]
  let dt = s:p[t] * str2nr(n)
  let time.start += dt
  let time.end += dt
  return time
endfunction

function! s:dict_from_ftime(ftime, ...) abort " {{{1
  " Defaults : active: 1, repeater: '', delay '', text ftime2date(start)
  let [start, end] = type(a:ftime) == v:t_list ? a:ftime : [a:ftime, a:ftime]
  let opts = get(a:, 1, {})

  return extend({'totext': function('s:totext'),
        \ 'active': 1,
        \ 'start': start,
        \ 'end': end,
        \ 'repeater': {},
        \ 'delay': {},
        \}, opts, 'force')
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
  let repeaterdelay = opts =~# 'r' || opts !~# 'R'

  let [o, c] = ['[<'[self.active], ']>'[self.active]]

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

