function! org#property#add(props, ...) abort " {{{1
  " Get properties
  " Replace non-list existing props
  " Add multiple for lists
  " Add properties properly otherwise
  let properties = org#property#all('.')
  if !org#headline#at('.')
    " throw 'org: trying to add property with no headline'
    return
  endif
  let rn = s:makedrawer()

  let new = []
  let set = {}
  for [name, val] in items(a:props)
    if name !~? '\v[[:alnum:]_-]+'
      throw 'org: property poorly named. Name must match: ''\v[[:alnum:]_-]+'''
    endif
    if name !~ '+$' && has_key(properties, name)
      let lnum = org#util#search(rn[0], '^:' . name . ':', 'nxW', rn[1])
      let set[lnum] = ':' . name . ': ' . val
    elseif name =~ '+$' && type(val) == v:t_list
      call extend(new, map(copy(val), '":" . name . ": " . v:val'))
    else
      call add(new, ':' . name . ': ' . val)
    endif
  endfor

  call map(set, 'setline(v:key, v:val)')
  let position = exists('a:1') ? (a:1 + rn[0]) : rn[1]
  let position = min([rn[1] - 1, max([0, position])])
  call append(position, new)
endfunction

function! org#property#set(props) abort " {{{1
  " TODO rename and redo makedrawer
  " FIXME Merge with #add

  let [dstart, dend] = org#property#drawer_range('.')
  if dstart > 0
    call deletebufline(bufnr(), dstart, dend)
  endif
  let hl = org#headline#get('.')
  let lnum = hl.lnum + !empty(hl.plan)

  let text = []
  for [name, val] in items(a:props)
    if name !~? '\v[[:alnum:]_-]+'
      throw 'org: property poorly named. Name must match: ''\v[[:alnum:]_-]+'''
    endif
    if name =~ '+$' && type(val) == v:t_list
      call extend(text, map(copy(val), '":" . name . ": " . v:val'))
    else
      call add(text, ':' . name . ': ' . val)
    endif
  endfor
  if len(text) > 0
    let text = [':PROPERTIES:'] + text + [':END:']
    call append(lnum, text)
  endif
endfunction

function! org#property#all(lnum, ...) abort " {{{1
  let [start, end] = org#property#drawer_range(a:lnum, 1)
  if start == 0
    return {}
  endif
  return org#property#fromtext(getline(start, end))
endfunction

function! org#property#fromtext(text) abort " {{{1
  let properties = {}
  for item in a:text
    try
      let [name, val] = org#property#parse(item)
      if type(val) == v:t_list
        let old = get(properties, name, [])  " previous might not be a list
        let val = (type(old) == v:t_list ? old : [old]) + val
      endif
      let properties[name] = val
    catch /Org/
    endtry
  endfor
  return properties
endfunction

function! org#property#drawer_range(lnum, ...) abort " {{{1
  " TODO: recursive? Inner?
  let inner = get(a:, 1, 0)
  let [start, end] = org#section#range(a:lnum)
  if start == 0
    return [0, 0]
  endif
  let pstart = org#util#search(start, '^:PROPERTIES:', 'nxW', start + 2)
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

function! org#property#get(lnum, name, ...) abort " {{{1
  " TODO ... get()
  " TODO merge with #all
  let [start, end] = org#property#drawer_range(a:lnum)
  if start == 0
    throw 'No property drawer found'
  endif
  let lnum = org#util#search(start, '^:' . a:name . ':', 'nxW', end)
  if lnum > 0
    return org#property#parse(getline(lnum))[1]
  endif
  return a:1  " Property does not exist
endfunction

function! org#property#isindrawer(lnum) abort " {{{1
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let [lstart, lend] = org#property#drawer_range(lnum)
  return lnum >= lstart && lnum <= lend
endfunction

function! org#property#parse(text) abort " {{{1
  try
    let [name, multi, val] = matchlist(a:text, g:org#regex#property)[1:3]
    return [name, multi == '+' ? [val] : val]
  catch /^Vim\%((\a\+)\)\=:E688/
    echoerr 'Org: failed to parse property "' . a:text . '"'
  endtry
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

function! s:makedrawer() abort " {{{1
  let [dstart, dend] = org#property#drawer_range('.')
  if dstart == 0
    let dstart = org#headline#at('.') + (org#plan#checkline('.') ? 1 : 0)
    call append(dstart, [':PROPERTIES:', ':END:'])
    let [dstart, dend] = [dstart + 1, dstart + 2]
  endif
  return [dstart, dend]
endfunction

