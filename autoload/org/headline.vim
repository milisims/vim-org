function! org#headline#parse(text, ...) abort " {{{1
  " returns a dict:
  " {level: n, keyword: text, priority: char, title: text, tags: []}
  " a1 must be a dict: {'todo': ['TODO'], 'done': ['DONE']}
  let keywords = get(a:, 1, org#keyword#all())
  let todo = keywords['todo']
  let done = keywords['done']
  if type(keywords) == 4
    let keywords = keywords.todo + keywords.done
  endif
  let [n, k, p, t, g] = matchlist(a:text, org#regex#headline(keywords))[1:5]
  let p = matchstr(p, '\a')
  let d = index(done, k) >= 0 ? k : ''
  let k = index(todo, k) >= 0 ? '' : k
  return {'LEVEL': len(n), 'TODO': k, 'DONE': d, 'PRIORITY': p, 'ITEM': t, 'TAGS': split(g, ':')}
endfunction

function! org#headline#get(lnum, ...) abort " {{{1
  " returns a dict: a headline object
  " {level: n, keyword: text, priority: char, title: text, tags: []}
  " a1 can be a list: ['TODO', 'DONE'] or a dict: {'todo': ['TODO'], 'done': ['DONE']}
  " FIXME: if no headline or invalid number, return an empty dictionary
  let keywords = get(a:, 1, org#keyword#all())
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let info = org#headline#parse(getline(lnum), keywords)
  let info.FILE = resolve(fnamemodify(bufname(), ':p'))
  let info.BUFNR = bufnr()
  let info.LNUM = lnum
  let info.PARENTLNUM = info.LEVEL > 1 ? org#headline#find(info.LNUM, info.LEVEL - 1, 'nbW') : 0
  call extend(info, org#timestamp#get(info.LNUM))
  call extend(info, org#property#all(info.LNUM), 'keep')
  return info
endfunction

function! org#headline#update(orig, modified) abort " {{{1
  " TODO get info from 'orig' and convert to 'modified'
endfunction

function! org#headline#checkline(lnum) abort " {{{1
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  return org#headline#checktext(getline(lnum))
endfunction

function! org#headline#checktext(text) abort " {{{1
  return a:text =~# '^\*'
endfunction

function! org#headline#promote(...) abort " {{{1
  let text = org#list#checkline('.') ? org#list#item_text('.') : getline('.')
  call setline('.', repeat('*', get(a:, 1, 1)) . (org#headline#checkline('.') ? '' : ' ') . text)
endfunction

function! org#headline#demote() abort " {{{1
  if org#headline#checkline('.')
    call setline('.', matchstr(getline('.'), '^\*\s*\zs.*$'))
  endif
endfunction

function! org#headline#find(lnum, ...) abort " {{{1
  " lnum, level or lower or 0 for any, search flags: 'bwW'
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let level = get(a:, 1, 0)
  let flags = get(a:, 2, '')
  let pattern = level > 0 ? ('^\*\{1,' . level . '}\(\s\+\|$\)') : '^\*\+\s*'
  return org#util#search(lnum, pattern, flags)
endfunction

function! org#headline#at(lnum) abort " {{{1
  return org#headline#find(a:lnum, 0, 'bnW')
endfunction

function! org#headline#level(lnum, ...) abort " {{{1
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let return_lnum = get(a:, 1, 0)
  let lnum = org#headline#find(lnum, 0, 'nbW')
  let headline_level = max([0, matchend(getline(lnum), '^\*\+')])
  return return_lnum ? [headline_level, lnum] : headline_level
endfunction

function! org#headline#add(lnum, level, text, ...) abort " {{{1
  " level <= 0 for previous.
  " Do we say lnum = .. - 1, or append at -1? Difference is where level is calculated.
  " TODO keyword? Maybe have lnum act like index? allow negative numbers
  " let keyword = get(a:, 1, 0)
  let level = a:level > 0 ? a:level : org#headline#level(a:lnum)
  if level == 0
    let level = 1
  endif
  " If whitespace, just the whitespace. if text, space + text. If empty, no space.
  let text = empty(a:text) ? '' : (a:text =~? '\S' ? ' ' . a:text : a:text)
  call append(a:lnum, repeat('*', level) . text)
endfunction

function! org#headline#remove(lnum, ...) abort " {{{1
  let range = join(org#section#range(a:lnum))
  if range == '0,0'
    return
  endif
  execute range . 'delete _'
endfunction

function! org#headline#open(direction) abort " {{{1
  if a:direction < 0
    let [level, lnum] = org#headline#level('.', 1)
    let level = level == 0 ? 1 : level
    let next = max([lnum - 1, 0])  " 0 - 1 if headline not found
  else
    let [level, prev] = org#headline#level('.', 1)
    let level = level == 0 ? 1 : level
    let next = org#headline#find(prev + 1, level, 'nW')
    " If no match found, we're at end of file. Also subtract 1 so it's above the match.
    let next = next == 0 ? prevnonblank(line('$')) : next - 1
    " If the headlines are neighbors, don't add empty spaces.
  endif
  call org#headline#add(next + 1, level, ' ')
  call cursor(next + 1, level + 2)
  startinsert!

  doautocmd User OrgFormat  " ???
endfunction

function! org#headline#jump(count1, direction, same_level, mode) abort " {{{1
  if a:mode == 'n'
    normal! m`
  elseif a:mode == 'v'
    normal! gv
  endif
  let flags = a:direction > 0 ? 'x' : 'xb'
  let level = a:same_level ? org#headline#level('.') : 0
  for i in range(a:count1)
    call org#headline#find('.', level, flags)
  endfor
  normal! 0
endfunction

function! org#headline#lower(count1, direction, mode) abort " {{{1
  if a:mode == 'n'
    normal! m`
  elseif a:mode == 'v'
    normal! gv
  endif
  let flags = a:direction > 0 ? '' : 'b'
  for i in range(a:count1)
    call org#headline#find(line('.'), org#headline#level('.') - 1, flags)
  endfor
endfunction

function! org#headline#has_keyword(text) abort " {{{1
  return a:text =~# '^\*\+\s\+\(' . join(org#keyword#all('all'), '\|') . '\)'
endfunction

function! org#headline#keyword(text) abort " {{{1
  return matchstr(a:text, '^\*\+\s\+\zs\(' . join(org#keyword#all('all'), '\|') . '\)')
endfunction

function! org#headline#astarget(lnum) abort " {{{1
  let hl = org#headline#get(a:lnum)
  let target = []
  while !empty(hl)
    call insert(target, hl.ITEM)
    let hl = org#headline#get(hl.PARENTLNUM)
  endwhile
  return fnamemodify(expand('%'), ':t') + join(target, '/')
endfunction

function! org#headline#fromtarget(target, ...) abort " {{{1
  " file.org/hl1/headline 2/hl3/he.*line4/headline6
  " optional arg = true if make missing target headlines. Will use text literally.
  let make = get(a:, 1, 0)
  if type(a:target) == 1
    let fspl = split(a:target, '\.org\zs/')
    if len(fspl) == 1
      return {'FILE': a:target, 'LNUM': 0, 'BUFNR': bufnr()}
    endif
    let [fname, headlines] = fspl
    let headlines = split(headlines, '/')
  elseif type(a:target) == 3
    let [fname; headlines] = a:target
  else
    throw "Org: target must be str or list"
  endif
  let fname = resolve(fnamemodify(fname[0] == '/' ? fname : org#dir() . '/' . fname, ':p'))
  let startbufnr = bufnr()
  " FIXME use regexes from the regex source
  let [prefix, suffix] = ['\v^\*+\s*\w*\s+', '\v\s*(:%([[:alpha:]_@#%]+:)+)?\s*$']
  try
    if startbufnr != bufnr(fname)
      execute 'split' fname
      let winnr = winnr()
    endif
    let range = [1, line('$')]
    for ix in range(len(headlines))
      let lnum = org#util#search(range[0], prefix . headlines[ix] . suffix, '', range[1])
      if lnum == 0
        let level = ix == 0 ? 1 : max([org#headline#get(range[0]).LEVEL + 1, ix + 1])
        call org#headline#add(range[1], level, headlines[ix])
        let lnum = range[1] + 1
      endif
      let range = org#section#range(lnum)
    endfor
    let target = org#headline#get(lnum)
  finally
    if startbufnr != bufnr()
      execute winnr . 'wincmd c'
    endif
  endtry
  return target
endfunction

function! org#headline#format(lnum) abort " {{{1
  " TODO property drawer
  let [start, end] = org#section#range(a:lnum)
  if [start, end] == [1, line('$')] || start == end
    return
  endif
  if end - prevnonblank(end) > 1  " too many spaces
    execute prevnonblank(end) + 2 . ',' end . 'delete _'
  elseif end == prevnonblank(end)
    call append(end, '')
  endif
endfunction
