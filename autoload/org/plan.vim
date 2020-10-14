function! org#plan#at(lnum) abort " {{{1
  " Might produce nonsense if planning is not well formatted.
  " TODO define well formatted. requires a space!
  let lnum = org#section#headline(a:lnum) + 1
  return org#plan#checkline(lnum) ? lnum : 0
endfunction

function! org#plan#checkline(lnum, ...) abort " {{{1
  let plan = get(a:, 1, 'any')
  let lnum = org#section#headline(a:lnum) + 1
  return getline(lnum) =~# g:org#regex#timestamp#datetime0
endfunction

function! org#plan#diff(p1, p2, ...) abort " {{{1
  let tcmp = get(a:, 1, localtime())
endfunction

function! org#plan#islate(plan, ...) abort " {{{1
  " Not late if no planning! True if time/schedule/deadline is in the past, schedule must
  " be farther than g:org#timestamp#scheduled#time away
  let tcmp = get(a:, 1, localtime())
  return len(filter(copy(a:plan), 'v:key != "CLOSED"')) > 0 ? !org#plan#isplanned(a:plan, tcmp) : 0
endfunction

function! org#plan#isplanned(plan, ...) abort " {{{1
  let tcmp = get(a:, 1, localtime())
  if has_key(a:plan, 'CLOSED')
    return 0
  endif
  for [plan, time] in items(a:plan)
    if org#time#diff(time, tcmp) >= 0
      return 1
    endif
  endfor
  return 0
endfunction

function! org#plan#issoon(plan, ...) abort " {{{1
  " Yes if today is the timestamp, within schedule range, or within the deadline range
  let tcmp = get(a:, 1, localtime())
  " TODO should these use org#time#dict?
  return !empty(org#plan#nearest(tcmp, a:plan))
endfunction

function! org#plan#within(plan, t1, ...) abort " {{{1
  " Yes if today is the timestamp, within schedule range, or within the deadline range
  if exists('a:1')
    let tcmp = org#time#dict(a:t1)
    let tcmp.end = org#time#dict(a:1).start
  else
    " TODO should 'today' depend on the range provided? or just be 'now'? variable?
    let tcmp = org#time#dict('today')
    let tcmp.end = org#time#dict(a:t1).start
  endif
  return !empty(org#plan#nearest(a:plan, tcmp))
endfunction

function! org#plan#nearest(plan, ...) abort " {{{1
  " Allows to compute which happened first and by how far.
  " t1 should be a float, t2 should be a timestamp dict
  let tcmp = get(a:, 1, localtime())
  let retplan = get(a:, 2, 0)
  if empty(a:plan) || has_key(a:plan, 'CLOSED')
    return {}
  elseif len(a:plan) == 1
    return retplan ? copy(a:plan) : values(a:plan)[0]
  endif
  let tdiff = map(copy(a:plan), org#time#diff(tcmp, v:val))

  if has_key(tdiff, 'TIMESTAMP') >= 0 && tdiff.TIMESTAMP <= s:p.d
    return retplan ? {'TIMESTAMP': a:plan.TIMESTAMP} : a:plan.TIMESTAMP
  elseif has_key(tdiff, 'DEADLINE') <= 0 && tdiff.DEADLINE >= -s:p.d * g:org#timestamp#deadline#time
    return retplan ? {'DEADLINE': a:plan.DEADLINE} : a:plan.DEADLINE
  elseif has_key(tdiff, 'SCHEDULED') >= 0 && tdiff.SCHEDULED <= s:p.d * g:org#timestamp#scheduled#time
    return retplan ? {'SCHEDULED': a:plan.SCHEDULED} : a:plan.SCHEDULED
  endif
  return retname ? '' : {} " unplanned w.r.t now
endfunction

function! org#plan#remove(lnum) abort " {{{1
  let lnum = org#section#headline(a:lnum)
  if org#plan#checkline(lnum)
    let cursor = getcurpos()[1:]
    execute (lnum + 1) . 'delete'
    call cursor(cursor)
  endif
endfunction

function! org#plan#add(plan) abort " {{{1
  let plan = type(a:plan) == v:t_string ? org#plan#fromtext(a:plan) : a:plan
  if type(plan) != v:t_dict
    throw 'Org: {plan} must be type string or dict'
  endif
  let plan = extend(org#plan#get('.'), plan)
  call org#plan#set(plan)
endfunction

function! org#plan#set(plan) abort " {{{1
  " Assumes date has keys 'ftime', 'active', and optionally 'type'.
  " timestamp/scheduled/deadline/closed: {'ftime': float, 'active': [01]}
  " Overwrites any current timestamp.
  let lnum = org#section#headline('.')
  if lnum == 0
    throw 'No headline found'
  endif

  let plan = a:plan
  if type(plan) == v:t_string
    let plan = org#plan#fromtext(plan)
  elseif type(plan) != v:t_dict
    throw 'Org: {plan} must be type string or dict'
  endif

  let text = []
  for [kind, time] in items(plan)
    call add(text, kind =~# 'TIMESTAMP' ? '' : kind . ': ')
    let text[-1] .= type(time) != v:t_dict ? org#time#dict(time).totext() : time.totext()
  endfor
  let text = join(text)

  if org#plan#checkline(lnum)
    call setline(lnum + 1, text)
  else
    call append(lnum, text)
  endif
endfunction

function! org#plan#get(lnum, ...) abort " {{{1
  " Might produce nonsense if planning is not well formatted.
  " TODO define well formatted. requires a space!
  let inheritance = get(a:, 1, {})
  let plan = org#plan#fromtext(getline(org#section#headline(a:lnum) + 1))
  return extend(plan, inheritance, 'keep')
endfunction

function! org#plan#fromtext(text) abort " {{{1
  if a:text !~# g:org#regex#timestamp#datetime0
    return {}
  endif
  let text = split(a:text, '\v[:><[\]]\zs\s+')
  let plan = {}
  let kind = 'TIMESTAMP'
  for item in text
    if item =~# '\v^(SCHEDULED|DEADLINE|CLOSED):$'
      let kind = item[:-2]  " Remove :
    else
      let time = org#time#dict(item)
      let plan[kind] = time
      if time.active && (kind != 'CLOSED')
        let plan[kind].active = 0
      endif
      let kind = 'TIMESTAMP'
    endif
  endfor
  return plan
endfunction
