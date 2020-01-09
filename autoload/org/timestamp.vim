" Note: appointment (no deadline/schedule) shows up ONLY ON the date
" SCHEDULED shows up on AND AFTER that date
" Deadline shows up on and BEFORE that date (days defined by a variable -- name please)

let org#timestamp#month_names = get(g:, 'org#timestamp#month_names', [
      \ 'january', 'february', 'march', 'april', 'may', 'june',
      \ 'july', 'september', 'october', 'november', 'december' ])

let org#timestamp#day_names = get(g:, 'org#timestamp#day_names', ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday' ])

let org#timestamp#days = get(g:, 'org#timestamp#days', [
      \ 'monday', 'tuesday', 'wednesday', 'thursday',
      \ 'friday', 'saturday', 'sunday'])

" Read as Seconds:per.hour      seconds:per.day, etc
let s:p = {'h': 3600, 'd': 86400, 'w': 604800, 'm': 2678400, 'y': 31557600, 'ly': 31622400}
" jan: 31, feb: 28, mar: 31, apr: 30, may: 31, jun: 30
" jul: 31, aug: 31, sep: 30, oct: 31, nov: 30, dec: 31
" accumulate map ndays * 'd'

let [sgn, zhr, zmin] = matchlist(strftime('%z', 0), '\v([+-])?(\d\d)(\d\d)')[1:3]
let s:timezone = - str2nr(sgn . (zhr * s:p.h + zmin * 60))
unlet sgn zhr zmin

" BIG TODO: use \v\c everywhere, or \v\C

function! org#timestamp#parse(text, ...) abort " {{{1
  let now = get(a:, 1, localtime())
  " 12 * 3600 for noon. Prevents +/- 1 hour errors from DST for adding/subtracting weeks.
  let today = now - strftime('%H') * s:p.h - strftime('%M') * 60 - strftime('%S')
  " let year = float2nr(strftime('%Y') * 365.25) * 86400
  " let month = strftime('%m')
  " TODO checkout :h /\&
  if a:text =~? 'now'
    return localtime()
  elseif 'today' =~? a:text
    return today
  elseif 'tomorrow' =~? a:text
    return today + s:p.d
  elseif 'yesterday' =~? a:text
    return today - s:p.d
  elseif a:text =~? g:org#regex#timestamp#relative0
    let [n, t] = matchlist(a:text, g:org#regex#timestamp#relative)[1:2]
    return (t == 'h' ? localtime() : today) + s:p[t] * str2nr(n)
  elseif a:text =~? g:org#regex#timestamp#datetime0
    return org#timestamp#date2ftime(a:text)
  elseif a:text =~? '\v([-+]?[0-9]*)?\s*(\a+)'
    let [sn, t] = matchlist(a:text, '\v([-+]?[0-9]*)?\s*(\a+)')[1:2]
    let nn = str2nr(sn)
    let day = match(s:days, '\c' . t)
    if day >= 0
      let nn -= nn > 0 ? 1 : 0
      return today + ((day - strftime('%w')) % 7 + 1) * s:p.d + nn * s:p.w
    endif
  else
    return org#timestamp#date2ftime(a:text)
  endif
  return 0
endfunction

let s:months = [
      \        0,  2678400,  5097600,  7776000,
      \ 10368000, 13046400, 15638400, 18316800,
      \ 20995200, 23587200, 26265600, 28857600 ]

let s:months_ly = [
      \        0,  2678400,  5184000,  7862400,
      \ 10454400, 13132800, 15724800, 18403200,
      \ 21081600, 23673600, 26352000, 28944000 ]

function! org#timestamp#ftime2date(time, ...) abort " {{{1
  let use_time = get(a:, 1, -1)
  let timefmt = '%Y-%m-%d %a'
  if use_time > 0 || (use_time < 0 && strftime('%H:%M', a:time) != '00:00')
    let timefmt .= ' %H:%M'
  endif
  return strftime(timefmt, a:time)
endfunction


function! org#timestamp#date2ftime(date) abort " {{{1
  " Return ftime as [start, end]. start == end if not a range.
  let res = matchlist(a:date, g:org#regex#timestamp#daterange2)
  if !empty(res)
    let [start, end] = [s:parsedate(res[1]), s:parsedate(res[2])]
    return [start[0], end[1]]
  endif
  return s:parsedate(a:date)
endfunction

function! org#timestamp#date2timestamp(date) abort " {{{1
  " timestamp: { text: ..., active: bool,
  "              tstart: float, tend: float,
  "              repeater: {type: +/++/.+, val: float},
  "              delay: {type: -/--, val: float} }
  let res = matchlist(a:date, g:org#regex#timestamp#daterange2)
  if !empty(res)
    let [start, end] = [s:parsedate(res[1], 1), s:parsedate(res[2], 1)]
    return {'text': a:date,
          \ 'active': a:date =~? '<.*>',
          \ 'start': start[0],
          \ 'end': end[1],
          \ 'repeater': empty(start[2]) ? end[2] : start[2],
          \ 'delay': empty(start[3]) ? end[3] : start[3],
          \}
  endif
  let [start, end, repeater, delay] = s:parsedate(a:date, 1)
  return {'text': a:date,
        \ 'active': a:date =~? '<.*>',
        \ 'start': start,
        \ 'end': end,
        \ 'repeater': repeater,
        \ 'delay': delay,
        \}
endfunction

function! s:parsedate(date, ...) abort " {{{2
  let return_repdel = get(a:, 1, 0)
  let [date, time, repeat, delay] = matchlist(a:date, g:org#regex#timestamp#full4)[1:4]
  let [y, m, d, dow] = matchlist(date, g:org#regex#timestamp#date)[1:4]
  let [H1, M1, H2, M2] = [0, 0, '', '']
  if !empty(time)
    let [H1, M1, H2, M2] = matchlist(time, g:org#regex#timestamp#timerange4)[1:4]
  endif

  let [repeat, delay] = [{}, {}]
  if return_repdel && !empty(repeat)
    let [type, val, unit] = matchlist(repeat, g:org#regex#timestamp#repeater)[1:3]
    let repeat = {'type': type, 'val': val * s:p[unit]}
  endif
  if return_repdel && !empty(delay)
    let [type, val, unit] = matchlist(delay, g:org#regex#timestamp#delay)[1:3]
    let delay = {'type': type, 'val': val * s:p[unit]}
  endif

  let time = float2nr((y - 1970) * 365.25 + 0.25) * s:p.d
  let time += s:is_leapyear(y) ? s:months_ly[m - 1] : s:months[m - 1]
  let time += (d - 1) * s:p.d
  let start = time + H1 * s:p.h + M1 * 60 + s:timezone
  let end = start
  if !empty(H2) > 0
    let end = time + H2 * s:p.h + M2 * 60 + s:timezone
  endif
  return return_repdel ? [start, end, repeat, delay] : [start, end]
endfunction

function! s:is_leapyear(year) abort " {{{2
  return (a:year % 4 == 0 && a:year % 100 > 0) || (a:year % 400 == 0)
endfunction


function! org#timestamp#check(lnum) abort " {{{1
  let lnum = org#section#headline(a:lnum) + 1
  return getline(lnum) =~# g:org#regex#timestamp#datetime0
endfunction

function! org#timestamp#active(text) abort " {{{1
  return a:text =~# '<.*>'
endfunction

function! org#timestamp#get(lnum, ...) abort " {{{1
  " Might produce nonsense if planning is not well formatted.
  " TODO define well formatted. requires a space!
  let inheritance = get(a:, 1, {})
  let plan = {'TIMESTAMP': '', 'SCHEDULED': '', 'DEADLINE': '', 'CLOSED': ''}
  if !org#timestamp#check(a:lnum)
    return plan
  endif
  let text = split(getline(org#section#headline(a:lnum) + 1), '\v[:><[\]]\zs\s+')
  " call filter(text, '!empty(v:val)')
  let type = 'TIMESTAMP'
  for item in text
    if item =~# '\v^(SCHEDULED|DEADLINE|CLOSED):$'
      let type = item[:-2]  " Remove :
    else
      let plan[type] = {}
      let plan[type].active = (type =~# 'CLOSED') ? 0 : org#timestamp#active(item)
      let plan[type] = org#timestamp#date2timestamp(item)
      let type = 'TIMESTAMP'
    endif
  endfor

  call extend(plan, inheritance, 'keep')
  return plan
endfunction

function! org#timestamp#remove(lnum) abort " {{{1
  let lnum = org#section#headline(a:lnum)
  if org#timestamp#check(lnum)
    let cursor = getcurpos()[1:]
    execute (lnum + 1) . 'delete'
    call cursor(cursor)
  endif
endfunction

function! org#timestamp#add(lnum, timestamp) abort " {{{1
  " Assumes date has keys 'ftime', 'active', and optionally 'type'.
  " timestamp/scheduled/deadline/closed: {'ftime': float, 'active': [01]}
  " Overwrites any current timestamp.
  let lnum = org#section#headline(a:lnum)
  if lnum == 0
    throw 'No headline found'
  endif

  let type = get(a:timestamp, 'type', '')
  let timeText = !empty(type) ? type . ': ' : ''
  let timeText .= '[<'[a:timestamp.active]
  let timeText .= org#timestamp#ftime2date(a:timestamp.ftime)
  let timeText .= ']>'[a:timestamp.active]

  if org#timestamp#check(lnum)
    call setline(lnum + 1, timeText)
  else
    call append(lnum, timeText)
  endif
endfunction

function! s:add_timestamp(timestamp, ...) abort " {{{2
  let type = get(a:, 1, '')
  let timeText = !empty(type) ? type . ': ' : ''
  let timeText .= '[<'[timestamp.active]
  let timeText .= org#timestamp#ftime2date(timestamp.ftime)
  let timeText .= ']>'[timestamp.active]

endfunction

function! org#timestamp#prompt(lnum) abort " {{{1
  let lnum = org#section#headline(a:lnum)
  let dateText = input("Schedule date: ") " TODO :help input -> complete
  let ftime = org#timestamp#parse(dateText)
  if org#timestamp#check(lnum)
    call setline(lnum + 1, 'SCHEDULEDD: <' . org#timestamp#ftime2date(ftime) . '>')
  else
    call append(lnum, 'SCHEDULEDD: <' . org#timestamp#ftime2date(ftime) . '>')
  endif
endfunction

function! org#timestamp#tdiff(t1, t2) abort " {{{1
  " Difference of two timestamps or floats
  " 0 if times overlap, difference in closest start/end otherwise
  if type(a:t1) == 4 && type(a:t2) == 4 " check for dict
    if a:t1.end < a:t2.start
      return a:t1.end - a:t2.start
    elseif a:t1.start > a:t2.end
      return a:t1.start - a:t2.end
    endif
    return 0
  elseif type(a:t1) == 4
    if a:t1.end < a:t2
      return a:t1.end - a:t2
    elseif a:t1.start > a:t2
      return a:t1.start - a:t2
    endif
    return 0
  elseif type(a:t2) == 4
    if a:t1 < a:t2.start
      return a:t1 - a:t2.start
    elseif a:t1 > a:t2.end
      return a:t1 - a:t2.end
    endif
    return 0 " times overlap
  endif
  return a:t1 - a:t2  " both numbers
endfunction

