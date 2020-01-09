let org#agenda#cache = {}

" OLD
" {absolute filepath:
"  {'mtime': time, keywords: {'todo': [todo], 'done': [done], headlines: {lnum: ...}}}}

" NEW
" {absolute filepath:
"  {'mtime': time, keywords: {'todo': [todo], 'done': [done], subtrees: [ ... ]}}}
"  each headline is a dictionary containing keys below. One key is SUBTREES, which is a list
"  of dictionaries of headlines.

" 'headline' key contains:
" ITEM TODO LEVEL PRIORITY TAGS LNUM PARENTLNUM FILE BUFNR HEADLINES(reference to full headlines list)
" TIMESTAMP DEADLINE CLOSED SCHEDULED
" Future:
" CATEGORY BLOCKED CLOCKSUM CLOCKSUM_T TIMESTAMP_IA ALLTAGS


function! org#agenda#build(...) abort " {{{1
  let force = get(a:, 1, 0)
  let qf = getqflist()  " to restore
  let startbufnr = bufnr()

  " {{{2 get modified times & files to update
  let updates = {}
  for fname in org#agenda#files()
    let fname = resolve(fnamemodify(fname, ':p'))
    let mtime = getftime(fname)
    if force || !has_key(g:org#agenda#cache, fname) || g:org#agenda#cache[fname].mtime < mtime
      let updates[fname] = {
            \ 'mtime': mtime,
            \ 'keywords': {'todo': [], 'done': []},
            \ 'subtrees': [],
            \ 'lnums': {}
            \ }
    endif
  endfor

  if empty(updates)
    return g:org#agenda#cache
  endif

  " {{{2 get keywords per file
  try  " just ensure we eventually switch back to the starting buffer
    for fname in keys(updates)
      if bufnr(fname) >= 0
        execute 'keepjumps buffer ' . bufnr(fname)
      else
        execute 'keepjumps edit ' . fname
      endif
      let [todo, done] = org#keyword#get()
      let updates[fname].keywords.todo = todo
      let updates[fname].keywords.done = done
    endfor

  " {{{2 get headlines per file
    execute 'vimgrep /^\*/j' . join(keys(updates))
    " let prevLevels = [{'lvl': 0, 'lnum': 0}]  " to keep track of basic structure for PARENTLNUM
    for [fname, metadata] in items(updates)
      if resolve(fnamemodify(bufname(), ':p')) != fname
        execute 'keepjumps buffer ' . fname
      endif
      let tree = [metadata]
      let lnum = org#headline#find(1, 0, 'W')
      while lnum > 0
        let headline = org#headline#get(lnum, metadata.keywords)
        let headline.SUBTREES = []
        let metadata.lnums[lnum] = headline
        call filter(tree, {_, st -> st is metadata || st.LEVEL < headline.LEVEL})
        call add(tree[-1][tree[-1] is metadata ? 'subtrees' : 'SUBTREES'], headline)
        call add(tree, headline)
        let lnum = org#headline#find(lnum, 0, 'Wx')
      endwhile
    endfor

    " let prevLevels = {}
    " for entry in getqflist()
    "   let fname = fnamemodify(bufname(entry.bufnr), ':p')
    "   " Provides: LEVEL TODO PRIORITY ITEM TAGS
    "   let headline = org#headline#parse(entry.text, updates[fname].keywords)
    "   let headline.FILE = resolve(fnamemodify(bufname(entry.bufnr), ':p'))
    "   let headline.BUFNR = entry.bufnr
    "   let headline.LNUM = entry.lnum
    "   call filter(prevLevels, 'v:key < ' . headline.LEVEL)

    "   " Parents and children
    "   let headline.PARENTS = values(prevLevels)  " [lnum, ... ]
    "   for [lvl, lnum] in items(prevLevels)
    "     let parent = updates[fname].headlines[prevLevels[lvl]]
    "     call add(parent.CHILDREN, headline.LNUM)
    "   endfor
    "   let headline.CHILDREN = []  " [lnum, lnum ...]
    "   let prevLevels[headline.LEVEL] = headline.LNUM

    "   if bufnr() != entry.bufnr
    "     execute 'keepjumps buffer ' . entry.bufnr
    "   endif
    "   call extend(headline, org#timestamp#get(entry.lnum))
    "   call extend(headline, org#property#all(entry.lnum), 'keep')
    "   let updates[fname].headlines[entry.lnum] = headline
    " endfor
  finally
    execute 'keepjumps buffer ' startbufnr
  endtry

  " }}}

  call setqflist(qf)
  call extend(g:org#agenda#cache, updates, 'force')
  return g:org#agenda#cache
endfunction

function! org#agenda#files() abort " {{{1
  return sort(glob(org#dir() . '/**/*.org', 0, 1))
endfunction


function! org#agenda#list(...) abort " {{{1
  " a:1 regex of matching filenames
  let regex = get(a:, 1, '')
  let fullAgenda = filter(copy(org#agenda#build()), {k, v -> k =~ regex})

  let agendaList = []
  for agenda in values(fullAgenda)
    let headlines = sort(values(agenda.lnums), {_, hl -> hl.LNUM})
    call extend(agendaList, headlines)
  endfor
  return len(agendaList) == 1 ? values(agendaList)[0] : agendaList
endfunction

function! org#agenda#tree(...) abort " {{{1
  " a:1 regex of matching filenames
  " returns {filename: {level: {lnum: headline, ...}, ...}, ...}
  let regex = get(a:, 1, '')
  let agenda = filter(copy(org#agenda#build()), {k, v -> k =~ regex})
  return agenda
endfunction

function! org#agenda#inherit(headline, property, ...) abort " {{{1
  let val = []
  let headline = a:headline
  while 1
    call call(function(s:addifexists), extend([val, headline, property], a:000))
    if headline.PARENTLNUM <= 0
      break
    endif
    let headline = g:org#agenda#cache[headline.FILE].headlines[headline.PARENTLNUM]
  endwhile
  let headline = a:headline
  let headline['INHERITED' . property] = val
  return headline
endfunction

function! s:addifexists(list, src, name, ...) abort " {{{2
  if index(src, name) >= 0
    call add(list, src[name])
  elseif exists(a:1)
    call add(list, a:1)
  endif
endfunction

function! org#agenda#stuck(...) abort " {{{1
  " A stuck project is one that has no action items. A project will be labeled as
  " default: any headline level 2 or greater that has no action items.
  " This is a flattened tree:
  let projects = get(a:, 1, filter(org#agenda#list(), {_, hl -> hl.LEVEL == 2}))
  call filter(projects, {_, hl -> !s:hasKeyword(hl)})
  return sort(projects, org#util#seqsortfunc(['FILE', 'LNUM']))
endfunction

function! s:hasKeyword(headline) abort " {{{2
  if !empty(a:headline.TODO)
    return 1
  endif
  for st in a:headline.SUBTREES
    if s:hasKeyword(st)
      return 1
    endif
  endfor
  return 0
endfunction

function! org#agenda#todo() abort " {{{1
  let agenda = filter(org#agenda#list(), {k, v -> !empty(v.TODO)})
  call sort(agenda, org#util#seqsortfunc(['FILE', 'LNUM']))
  return agenda
endfunction

function! org#agenda#late() abort " {{{1
  " let agenda = filter(, {k, hl -> !empty(hl.TODO)})
  let agenda = filter(org#agenda#list(), {k, hl -> org#agenda#islate(hl)})
  call sort(agenda, org#util#seqsortfunc(['FILE', 'LNUM']))
  return agenda
endfunction

function! org#agenda#daily(...) abort " {{{1
  let days = get(a:, 1, 1)
  let time = org#timestamp#parse('now')
  let agenda = filter(org#agenda#list(), {_, hl -> org#agenda#isplanned(time, hl)})
  call sort(agenda, {a, b -> org#timestamp#tdiff(time, b) - org#timestamp#tdiff(time, a)})
  return agenda
endfunction

function! org#agenda#timely(...) abort " {{{1
endfunction

function! org#agenda#display(agenda, ...) abort " {{{1
  let s:lastDisplayed = a:agenda  " TODO change me to autocmds
  let Display = get(a:, 1, 0)
  if type(Display) == 1  " string
    let Display = function(Display)
  elseif type(Display) != 2  " funcref
    let Display = function('org#agenda#toqf')
  endif
  let Separator = get(a:, 2, 0)
  let qfagenda = map(copy(a:agenda), Display)
  if type(Separator) == 2  " funcref
    let qfagenda = Separator(qfagenda, a:agenda)
  endif
  call setqflist(qfagenda)
  copen
endfunction

function! org#agenda#toqf(ix, item, ...) abort " {{{1
  let opts = get(a:, 1, {})
  let qfitem = {'lnum': a:item.LNUM,
        \ 'filename': bufname(a:item.BUFNR),
        \ 'module': fnamemodify(a:item.FILE, ':t'),
        \ 'ITEM': a:item,
        \ 'text': a:item.TODO . '	' . a:item.ITEM }
  for [k, v] in items(opts)
    let qfitem[k] = get(a:item, v, v)
  endfor
  return qfitem
endfunction

function! org#agenda#daily_separator(qfagenda, agenda) abort " {{{1
  " Assumes args are sorted by time already.
  let qfa = a:qfagenda
  let separators = [[0, org#timestamp#parse('today')]]
  let times = map(copy(a:agenda), {ix, hl -> [ix, org#agenda#nearest_time(separators[0])]})
  for ix in range(len(qfa))
    if times[ix][1] > separators[0][1] + 86400
      call insert(separators, [ix, org#timestamp#parse('+' . len(separators) . 'd')])
    endif
  endfor

  for [ix, time] in times  " times is reversed
    call insert(qfa, {'text': org#timestamp#ftime2date(time, 0)}, ix)
  endfor
  return qfa
endfunction

function! org#agenda#refine(regex) abort " {{{1
  try
    call filter(s:lastDisplayed, {_, hl -> hl.ITEM =~# a:regex})
    call org#agenda#display(s:lastDisplayed)
  catch /^E121.*lastDisplayed/
    echoerr 'Org: No agenda to refine'
  endtry
endfunction
function! org#agenda#nearest_time(ts, ...) abort " {{{1
  " Allows to compute which happened first and by how far.
  " t1 should be a float, t2 should be a timestamp dict
  " Assumes one of the three exists
  let tcmp = get(a:, 1, org#timestamp#parse('now'))
  let tdiff = {}
  for plan in ['TIMESTAMP', 'SCHEDULED', 'DEADLINE']
    if !empty(a:ts[plan])
      let tdiff[plan] = org#timestamp#tdiff(tcmp, a:ts[plan])
    endif
  endfor

  if has_key(tdiff.TIMESTAMP) && tdiff.TIMESTAMP >= 0 && tdiff.TIMESTAMP <= s:p.d
    return ['TIMESTAMP', a:ts.TIMESTAMP]
  elseif has_key(tdiff.DEADLINE) && tdiff.DEADLINE <= 0 && tdiff.DEADLINE >= s:p.d * g:org#timestamp#deadline#time
    return ['DEADLINE', a:ts.DEADLINE]
  elseif has_key(tdiff.SCHEDULED) && tdiff.SCHEDULED >= 0 && tdiff.SCHEDULED <= s:p.d * g:org#timestamp#scheduled#time
    return ['SCHEDULED', a:ts.SCHEDULED]
  endif
  return [] " unplanned w.r.t now
endfunction

function! org#agenda#isplanned(ts, ...) abort " {{{1
  " There is a timestamp, schedule, or deadline in the future.
  let tcmp = get(a:, 1, org#timestamp#parse('now'))
  for plan in ['TIMESTAMP', 'SCHEDULED', 'DEADLINE']
    if !empty(a:ts[plan])
      if org#timestamp#tdiff(a:ts[plan], tcmp) >= 0
        return 1
      endif
    endif
  endfor
  return 0
endfunction

function! org#agenda#islate(ts, ...) abort " {{{1
  " There is a timestamp, schedule, or deadline in the future.
  " Not late if no planning!
  let tcmp = get(a:, 1, org#timestamp#parse('now'))
  let tdiff = {}
  for plan in ['TIMESTAMP', 'SCHEDULED', 'DEADLINE']
    if !empty(a:ts[plan])
      let tdiff[plan] = org#timestamp#tdiff(tcmp, a:ts[plan])
    endif
  endfor
  if empty(tdiff)
    return 0
  endif
  return !org#agenda#isplanned(a:ts, tcmp)
endfunction

function! org#agenda#issoon(ts, ...) abort " {{{1
  let tcmp = get(a:, 1, org#timestamp#parse('now'))
  return !empty(org#agenda#nearest_time(tcmp, ts))
endfunction
