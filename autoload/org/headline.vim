function! org#headline#add(level, text, ...) abort " {{{1
  " level <= 0 for previous.
  " Do we say lnum = .. - 1, or append at -1? Difference is where level is calculated.
  " TODO keyword? Maybe have lnum act like index? allow negative numbers
  " let keyword = get(a:, 1, 0)
  let level = a:level > 0 ? a:level : org#headline#level('.')
  if level == 0
    let level = 1
  endif
  " If whitespace, just the whitespace. if text, space + text. If empty, no space.
  let text = empty(a:text) ? '' : (a:text =~? '\S' ? ' ' . a:text : a:text)
  call append('.', repeat('*', level) . text)
endfunction

function! org#headline#addtag(tag) abort " {{{1
  let lnum = org#headline#at('.')
  let current = matchlist(getline(lnum), org#headline#regex())[5]
  if empty(current)
    call setline(lnum, substitute(getline(lnum), '\s\+$', '', '') . ' :' . a:tag . ':')
  elseif index(split(current, ':'), a:tag) < 0
    call setline(lnum, substitute(getline(lnum), '\s\+$', '', '') . a:tag . ':')
  endif
endfunction

function! org#headline#gettags(lnum) abort " {{{1
  let lnum = org#headline#at(lnum)
  return org#headline#parse(getline(lnum)).tags
endfunction

function! org#headline#astarget(expr) abort " {{{1
  if type(a:expr) == v:t_number || type(a:expr) == v:t_string
    let lnum = org#headline#find(a:expr, 0, 'nbW')
  elseif type(a:expr) == v:t_dict
    let lnum = a:expr.lnum
  else
    throw 'org#headline#astarget expr must be str, nr, or dict (from org#headilne#get)'
  endif
  let target = []
  while lnum > 0
    let hl = org#headline#get(lnum)
    call insert(target, hl.item)
    let lnum = hl.level == 1 ? 0 : org#headline#find(hl.lnum, hl.level - 1, 'nWbx')
  endwhile
  let odir = '^\V' . fnamemodify(org#dir(), ':p')
  let ftarget = substitute(fnamemodify(expand('%'), ':p'), odir, '', '')
  return ftarget . (empty(target) ? '' : ('/' . join(target, '/')))
endfunction

function! org#headline#at(lnum) abort " {{{1
  return org#headline#find(a:lnum, 0, 'bnW')
endfunction

function! org#headline#checkline(lnum) abort " {{{1
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  return org#headline#checktext(getline(lnum))
endfunction

function! org#headline#checktext(text) abort " {{{1
  return a:text =~# '^\*'
endfunction

function! org#headline#demote(...) abort " {{{1
  if org#headline#checkline('.')
    let level = org#headline#level('.')
    let count = get(a:, 1, 1) > level ? level : get(a:, 1, 1)
    call setline('.', matchstr(getline('.'), '^\*\{' . count . '}\s*\zs.*$'))
  endif
endfunction

function! org#headline#find(lnum, ...) abort " {{{1
  " lnum, level or lower or 0 for any, search flags: 'bwW'
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let level = get(a:, 1, 0)
  let flags = get(a:, 2, '')
  " let pattern = level > 0 ? ('^\*\{1,' . level . '}\(\s\+\|$\)') : '^\*\+\s*'
  let pattern = '\v^\*' . (level > 0 ? '{1,' . level . '}' : '+') . '(\s+|$)'
  return org#util#search(lnum, pattern, flags)
endfunction

function! org#headline#format() abort " {{{1
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

function! org#headline#fromtarget(target, ...) abort " {{{1
  " file.org/hl1/headline 2/hl3/he.*line4/headline6
  " optional arg = true if make missing target headlines. Will use text literally.
  let make = get(a:, 1, 0)
  if type(a:target) == v:t_string
    let fspl = split(a:target, '\.org\zs/')
    if len(fspl) == 1
      let fname = resolve(fnamemodify(a:target[0] == '/' ? a:target : org#dir() . '/' . a:target, ':p'))
      return {'filename': fname, 'lnum': 0, 'bufnr': bufnr(fname)}
    endif
    let [fname, headlines] = fspl
    let headlines = split(headlines, '/')
  elseif type(a:target) == v:t_list
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
    let range = [0, line('$')]
    for ix in range(len(headlines))
      let lnum = org#util#search(range[0], prefix . headlines[ix] . suffix, 'nx', range[1])
      if lnum == 0
        let level = ix == 0 ? 1 : max([org#headline#get(range[0]).level + 1, ix + 1])
        execute range[1] 'call org#headline#add(level, headlines[ix])'
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

function! org#headline#get(lnum, ...) abort " {{{1
  " returns a dict: a headline object
  " {level: n, keyword: text, priority: char, title: text, tags: []}
  " a1 can be a list: ['TODO', 'DONE'] or a dict: {'todo': ['TODO'], 'done': ['DONE']}
  " FIXME: if no headline or invalid number, return an empty dictionary
  " Get is not short circuited, but ternary expressions are.
  let keywords = exists('a:1') ? a:1 : org#outline#keywords()
  let lnum = org#headline#at(a:lnum)
  let info = org#headline#parse(getline(lnum), keywords)
  " :h tag-function: name, filename, cmd, kind, user_data?
  let info.filename = resolve(fnamemodify(bufname(), ':p'))
  let info.bufnr = bufnr()
  let info.lnum = lnum
  let info.plan = org#plan#get(lnum)
  let info.properties = org#property#all(lnum)
  return info
endfunction

function! org#headline#level(lnum, ...) abort " {{{1
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let return_lnum = get(a:, 1, 0)
  let lnum = org#headline#find(lnum, 0, 'nbW')
  let headline_level = max([0, matchend(getline(lnum), '^\*\+')])
  return return_lnum ? [headline_level, lnum] : headline_level
endfunction

function! org#headline#parse(text, ...) abort " {{{1
  " returns a dict:
  " {level: n, keyword: text, priority: char, title: text, tags: []}
  " a1 must be a dict: {'todo': ['TODO'], 'done': ['DONE']}
  let keywords = exists('a:1') ? a:1 : org#outline#keywords()
  let [n, k, p, t, g] = matchlist(a:text, org#headline#regex(keywords))[1:5]
  let p = matchstr(p, '\a')
  let d = index(keywords.done, k) >= 0 ? k : ''
  let k = index(keywords.todo, k) >= 0 ? k : ''
  let tgs = filter(split(g, ':'), '!empty(v:val)')
  return {'level': len(n), 'todo': k, 'done': d, 'priority': p, 'item': t, 'text': a:text, 'tags': tgs}
endfunction

function! org#headline#promote(...) abort " {{{1
  let text = org#list#checkline('.') ? org#listitem#text('.') : getline('.')
  call setline('.', repeat('*', get(a:, 1, 1)) . (org#headline#checkline('.') ? '' : ' ') . text)
endfunction

function! org#headline#regex(...) abort " {{{1
  " stars, keyword, priority, text, tags
  let keywords = join(exists('a:1') ? a:1.all : org#outline#keywords().all, '|')
  return '\v^(\*+)\s+%((' . keywords . ')\s)?\s*%((\[#\a\])\s)?\s*(.{-})\s*(:%([[:alnum:]_@#%]+:)+)?\s*$'
endfunction

function! org#headline#set(text) abort " {{{1
  let lnum = org#headline#at('.')
  let current = matchlist(getline(lnum), org#headline#regex())[4]
  let current = escape(current, '\')
  if empty(current)
    throw 'NYI set empty text'
  endif
  call setline(lnum, substitute(getline(lnum), '\V' . escape(current, '\'), a:text, ''))
endfunction

function! org#headline#settag(tag) abort " {{{1
  let lnum = org#headline#at('.')
  call setline(lnum, substitute(getline(lnum), '\v\s?(:%([[:alnum:]_@#%]+:)+)?\s*$', ' :' . a:tag . ':', ''))
endfunction

function! org#headline#subtree(lnum, ...) abort " {{{1
  let keywords = exists('a:1') ? a:1 : org#outline#keywords()
  let headline = org#headline#get(a:lnum, keywords)

  let [lnum, end] = org#section#range(headline.lnum)
  let lnum = org#headline#find(lnum, 0, 'nWx')
  let subtree = []
  while lnum > 0 && lnum <= end
    call add(subtree, org#headline#subtree(lnum, keywords))
    let lnum = org#headline#find(lnum, 0, 'nWx')
  endwhile
  return [headline, subtree]
endfunction
