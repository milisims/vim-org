
function! org#property#add(lnum, name, value, ...) abort " {{{1
  let position = get(a:, 1, -1)
  if a:name =~? '\s'
    throw 'Property name can not contain whitespace'
  endif
  let [dstart, dend] = org#property#drawer_range(a:lnum)
  if dstart == 0
    let dstart = org#headline#at(a:lnum) + (org#timestamp#check(a:lnum) ? 1 : 0)
    call append(dstart, [':PROPERTIES:', ':END:'])
    let [dstart, dend] = [dstart + 1, dstart + 2]
  endif
  let lnum = position >= 0 ? dstart + position : dend + position
  call append(lnum, ':' . a:name . ': ' . a:value)
endfunction

function! org#property#get(lnum, name, ...) abort " {{{1
  " TODO ... get()
  let [start, end] = org#property#drawer_range(a:lnum)
  if start == 0
    throw 'No property drawer found'
  endif
  let lnum = org#util#search(start, '^:' . a:name . ':', 'nxW', end)
  if lnum > 0
    return org#property#parse(getline(lnum))[1]
  endif
  return a:1  " Property does not exist if you see this, add optional default arg
endfunction

function! org#property#parse(text) abort " {{{1
  let [name, multi, val] = matchlist(a:text, g:org#regex#property)[1:3]
  return [name, multi == '+' ? [val] : val]
endfunction

function! org#property#all(lnum, ...) abort " {{{1
  let [start, end] = org#property#drawer_range(a:lnum, 1)
  if start == 0
    return {}
  endif
  let properties = {}
  for lnum in range(start, end)
    let [name, val] = org#property#parse(getline(lnum))
    if type(val) == 3
      let old = get(properties, name, [])  " previous might not be a list
      let val = (type(old) == 3 ? old : [old]) + val
    endif
    let properties[name] = val
  endfor
  return properties
endfunction

function! org#property#remove(lnum, name) abort " {{{1
  let [start, end] = org#property#drawer_range(a:lnum)
  let lnum = org#util#search(start, '^:' . a:name . ':', 'nxW', end)
  if lnum > 0
    let cursor = getcurpos()[1:]
    execute lnum . 'delete _'
    call cursor(cursor)
  endif
endfunction

function! org#property#drawer_range(lnum, ...) abort " {{{1
  " TODO: recursive? Inner?
  let inner = get(a:, 1, 0)
  let [start, end] = org#section#range(a:lnum)
  if start == 0
    return [0, 0]
  endif
  let pstart = org#util#search(start, '^:PROPERTIES:', 'nxW', start + 1)
  let pend = org#util#search(start, '^:END:', 'nxW', end)
  if pstart == 0 || pend == 0
    return [0, 0]
  endif
  if inner
    let pstart += 1
    let pend -= 1
  endif
  return pend < pstart ? [0, 0] : [pstart, pend]
endfunction
