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

function! org#timestamp#parsetext(text, ...) abort " {{{1
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
    return org#timestamp#text2ftime(a:text)
  elseif a:text =~ '\v([-+]?[0-9]*)?\s*(\a+)'
    let [sn, day] = matchlist(a:text, '\v([-+]?[0-9]*)?\s*(\a+)')[1:2]
    let day = matchstrpos(g:org#timestamp#day_names, day)[1]
    if day == -1
      throw 'org: Unable to parse ' . a:text
    endif
    let nn = max([str2nr(sn) - 1, 0])
    return today + ((day - strftime('%w')) % 7 + 1) * s:p.d + nn * s:p.w
  endif
  throw 'org: Unable to parse ' . a:text
endfunction

function! org#timestamp#ftime2text(time, ...) abort " {{{1
  " time can be an ftime or a dict with keys 'start' and 'end'
  " fmt can include '[tT]?D?' or empty
  let use_time = get(a:, 1, '') =~? 't' ? (get(a:, 1) =~# 't') : -1
  let use_day = ! get(a:, 2, '') =~# 'D'

    let timefmt = '%Y-%m-%d' . (use_day ? ' %a' : '')
    if use_time > 0 || (use_time < 0 && strftime('%H:%M', a:time) != '00:00')
      let timefmt .= ' %H:%M'
    endif
    return strftime(timefmt, a:time)
endfunction

function! org#timestamp#date2text(datetime, ...) abort " {{{1
  " time can be an ftime or a dict with keys 'start' and 'end'
  " fmt can include '[tT]?D?' or empty
  let opts = get(a:, 1, 'd')
  let use_time = opts =~? 't' ? (opts =~# 't') : -1
  let use_day = !(opts =~# 'D')
  let timefmt = '%Y-%m-%d' . (use_day ? ' %a' : '')

  " example ftime: <2019-09-30 Mon 1:00>
  if type(a:datetime) != v:t_dict  " is not a dict
    let active = !(opts =~# 'A')
    let [o, c] = ['[<'[active], ']>'[active]]
    if use_time > 0 || (use_time < 0 && strftime('%H:%M', a:datetime) != '00:00')
      let timefmt .= ' %H:%M'
    endif
    return o . strftime(timefmt, a:datetime) . c
  endif

  let active = opts =~? 'a' ? (opts =~# 'a') : get(a:datetime, 'active', 1)
  let [o, c] = ['[<'[active], ']>'[active]]

  if a:datetime.start == a:datetime.end
    return org#timestamp#date2text(a:datetime.start, 'Aa'[active])
  endif

  " example range: <2019-09-30 Mon 1:00-2:00>
  if strftime('%d', a:datetime.start) == strftime('%d', a:datetime.end)
    let timefmt .= ' %H:%M-'
    return o . strftime(timefmt, a:datetime.start) . strftime('%H:%M', a:datetime.end) . c
  endif

  " example ftime: <2019-09-30 Mon>--<2019-10-01 Tue>
  if use_time > 0 || (use_time < 0 && strftime('%H:%M', a:datetime.start) != '00:00')
    let timefmt .= ' %H:%M'
  endif
  return o . strftime(timefmt, a:datetime.start) . c . '--'
        \ . o . strftime(timefmt, a:datetime.end) . c
endfunction

function! org#timestamp#text2ftime(text) abort " {{{1
  " Return ftime as [start, end]. start == end if not a range.
  let res = matchlist(a:text, g:org#regex#timestamp#daterange2)
  if !empty(res)
    let [start, end] = [s:parsedate(res[1]), s:parsedate(res[2])]
    return [start[0], end[1]]
  endif
  return s:parsedate(a:text)
endfunction

function! org#timestamp#from_ftime(ftime, ...) abort " {{{1
  " timestamp:
  " Defaults : active: 1, repeater: '', delay '', text ftime2date(start)
  let start = a:ftime
  let end = get(a:, 1, a:ftime)
  let options = get(a:, 2, {})
  return {'text': org#timestamp#ftime2text(start),
        \ 'active': 1,
        \ 'start': start,
        \ 'end': end,
        \ 'repeater': '',
        \ 'delay': '',
        \}
endfunction

function! org#timestamp#from_text(datetime, ...) abort " {{{1
  " timestamp: { text: ..., active: bool,
  "              tstart: float, tend: float,
  "              repeater: {type: +/++/.+, val: float},
  "              delay: {type: -/--, val: float} }
  let options = get(a:, 1, {})
  let res = matchlist(a:datetime, g:org#regex#timestamp#daterange2)
  if !empty(res)
    let [start, end] = [s:parsedate(res[1], 1), s:parsedate(res[2], 1)]
    let ts = {'text': a:datetime,
          \ 'active': a:datetime =~? '<.*>',
          \ 'start': start[0],
          \ 'end': end[1],
          \ 'repeater': empty(start[2]) ? end[2] : start[2],
          \ 'delay': empty(start[3]) ? end[3] : start[3],
          \}
  else
    let [start, end, repeater, delay] = s:parsedate(a:datetime, 1)
    let ts = {'text': a:datetime,
          \ 'active': a:datetime =~? '<.*>',
          \ 'start': start,
          \ 'end': end,
          \ 'repeater': repeater,
          \ 'delay': delay,
          \}
  endif
  return s:extendopts(ts, options)
endfunction

function! s:extendopts(timestamp, options) abort " {{{2
  " Assumes timestamp is properly created with only
  let ts = a:timestamp
  for opt in keys(a:options)
    if has_key(ts)
      let ts[opt] = a:options[opt]
    endif
  endfor
  return ts
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

let s:months = [
      \        0,  2678400,  5097600,  7776000,
      \ 10368000, 13046400, 15638400, 18316800,
      \ 20995200, 23587200, 26265600, 28857600 ]

let s:months_ly = [
      \        0,  2678400,  5184000,  7862400,
      \ 10454400, 13132800, 15724800, 18403200,
      \ 21081600, 23673600, 26352000, 28944000 ]

function! s:is_leapyear(year) abort " {{{2
  return (a:year % 4 == 0 && a:year % 100 > 0) || (a:year % 400 == 0)
endfunction


function! org#timestamp#checkline(lnum, ...) abort " {{{1
  let plan = get(a:, 1, 'any')
  let lnum = org#section#headline(a:lnum) + 1
  return getline(lnum) =~# g:org#regex#timestamp#datetime0
endfunction

function! org#timestamp#active(text) abort " {{{1
  return a:text =~# '<.*>'
endfunction

function! org#timestamp#at(lnum) abort " {{{1
  " Might produce nonsense if planning is not well formatted.
  " TODO define well formatted. requires a space!
  let lnum = org#section#headline(a:lnum) + 1
  return org#timestamp#checkline(lnum) ? lnum : 0
endfunction

function! org#timestamp#get(lnum, ...) abort " {{{1
  " Might produce nonsense if planning is not well formatted.
  " TODO define well formatted. requires a space!
  let inheritance = get(a:, 1, {})
  let plan = {'TIMESTAMP': '', 'SCHEDULED': '', 'DEADLINE': '', 'CLOSED': ''}
  if !org#timestamp#checkline(a:lnum)
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
      let plan[type] = org#timestamp#from_text(item)
      let type = 'TIMESTAMP'
    endif
  endfor

  call extend(plan, inheritance, 'keep')
  return plan
endfunction

function! org#timestamp#remove(lnum) abort " {{{1
  let lnum = org#section#headline(a:lnum)
  if org#timestamp#checkline(lnum)
    let cursor = getcurpos()[1:]
    execute (lnum + 1) . 'delete'
    call cursor(cursor)
  endif
endfunction

function! org#timestamp#add(lnum, timestamp, ...) abort " {{{1
  " Assumes date has keys 'ftime', 'active', and optionally 'type'.
  " timestamp/scheduled/deadline/closed: {'ftime': float, 'active': [01]}
  " Overwrites any current timestamp.
  let lnum = org#section#headline(a:lnum)
  if lnum == 0
    throw 'No headline found'
  endif
  let only_this = get(a:, 1, 0)
  let plantype = 'TIMESTAMP'
  if exists('a:1')
    let plantype = matchstr(['CLOSED', 'SCHEDULED', 'DEADLINE', 'TIMESTAMP'], a:1)
  endif
  let text = plantype =~# 'TIMESTAMP' ? '' : plantype . ': '
  let text .= org#timestamp#date2text(a:timestamp)

  let ts = org#timestamp#get(a:lnum, {a:timestamp})

  if org#timestamp#checkline(lnum, plantype)
    call setline(lnum + 1, timeText)
  else
    call append(lnum, timeText)
  endif
endfunction

function! org#timestamp#set(lnum, timestamp, ...) abort " {{{1
  " Assumes date has keys 'ftime', 'active', and optionally 'type'.
  " timestamp/scheduled/deadline/closed: {'ftime': float, 'active': [01]}
  " Overwrites any current timestamp.
  let lnum = org#section#headline(a:lnum)
  let ts = extend(copy(get(a:, 1, {})), a:timestamp, 'force') " empty vs has_key for timestamps
  echo ts
  if lnum == 0
    throw 'No headline found'
  endif
  let only_this = get(a:, 1, 0)
  let text = ''
  for type in ['CLOSED', 'TIMESTAMP', 'SCHEDULED', 'DEADLINE']
    if has_key(ts, type) && !empty(ts[type])
      let text .= type =~# 'TIMESTAMP' ? '' : type . ': '
      let text .= org#timestamp#date2text(ts[type]) . ' '
    endif
  endfor
  let text = substitute(text, '\s\+$', '', '')

  if org#timestamp#checkline(lnum)
    call setline(lnum + 1, text)
  else
    call append(lnum, text)
  endif
endfunction



function! org#timestamp#tdiff(t1, t2) abort " {{{1
  " Difference of two timestamps or floats
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

function! org#timestamp#nearest_plan(ts, ...) abort " {{{1
  " Allows to compute which happened first and by how far.
  " t1 should be a float, t2 should be a timestamp dict
  " Assumes one of the three exists
  let tcmp = get(a:, 1, org#timestamp#parsetext('now'))
  let tdiff = {}
  let nopes = {'TIMESTAMP': -1, 'SCHEDULED': -1, 'DEADLINE': 1}
  for plan in ['TIMESTAMP', 'SCHEDULED', 'DEADLINE']
    let tdiff[plan] = !empty(a:ts[plan]) ? org#timestamp#tdiff(tcmp, a:ts[plan]) : nopes[plan]
  endfor

  if tdiff.TIMESTAMP >= 0 && tdiff.TIMESTAMP <= s:p.d
    return ['TIMESTAMP', a:ts.TIMESTAMP]
  elseif tdiff.DEADLINE <= 0 && tdiff.DEADLINE >= -s:p.d * g:org#timestamp#deadline#time
    return ['DEADLINE', a:ts.DEADLINE]
  elseif tdiff.SCHEDULED >= 0 && tdiff.SCHEDULED <= s:p.d * g:org#timestamp#scheduled#time
    return ['SCHEDULED', a:ts.SCHEDULED]
  endif
  return [] " unplanned w.r.t now
endfunction

function! org#timestamp#isplanned(ts, ...) abort " {{{1
  " This timestamp object has a timestamp, schedule, or deadline in the future.
  " FIXME
  let tcmp = get(a:, 1, org#timestamp#parsetext('now'))
  for plan in ['TIMESTAMP', 'SCHEDULED', 'DEADLINE']
    if !empty(a:ts[plan])
      if org#timestamp#tdiff(a:ts[plan], tcmp) >= 0
        return 1
      endif
    endif
  endfor
  return 0
endfunction

function! org#timestamp#islate(ts, ...) abort " {{{1
  " Not late if no planning! True if time/schedule/deadline is in the past, schedule must
  " be farther than g:org#timestamp#scheduled#time away
  let tcmp = get(a:, 1, org#timestamp#parsetext('now'))
  let tdiff = {}
  for plan in ['TIMESTAMP', 'SCHEDULED', 'DEADLINE']
    if !empty(a:ts[plan])
      let tdiff[plan] = org#timestamp#tdiff(tcmp, a:ts[plan])
    endif
  endfor
  if empty(tdiff)
    return 0
  endif
  return !org#timestamp#isplanned(a:ts, tcmp)
endfunction

function! org#timestamp#issoon(ts, ...) abort " {{{1
  " Yes if today is the timestamp, within schedule range, or within the deadline range
  let tcmp = get(a:, 1, org#timestamp#parsetext('now'))
  return !empty(org#timestamp#nearest_plan(tcmp, ts))
endfunction


function! org#timestamp#completion(arglead, cmdline, curpos) abort " {{{1
  let splt = split(a:cmdline, ' ', 1)
  if len(splt) <= 2
    return s:complete_plan(a:arglead)
  elseif len(splt) == 3
    return s:complete_date(a:arglead)
  elseif len(splt) == 4
    return s:complete_time(a:arglead)
  endif
endfunction

function! s:complete_plan(arglead) abort " {{{2
  let plantypes = ['TIMESTAMP', 'SCHEDULED', 'DEADLINE', 'CLOSED']
  if empty(a:arglead)
    return plantypes
  endif
  let pt = match(plantypes, '^' . a:arglead)
  return pt >= 0 ? [plantypes[pt]] : plantypes
endfunction

function! s:complete_date(arglead) abort " {{{2
  try
    return [org#timestamp#ftime2text(org#timestamp#parsetext(a:arglead), 0, 0)]
  catch /^E605.*org/
  endtry
  return a:arglead
endfunction

function! s:complete_time(arglead) abort " {{{2
  let times = []
  for hh in range(23)
    for mm in [0, 15, 30, 45]
      call add(times, printf('%02d:%02d', hh, mm))
    endfor
  endfor
  return filter(times, 'v:val =~ a:arglead')
endfunction


