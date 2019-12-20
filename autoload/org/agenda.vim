let org#agenda#cache = {}

" {absolute filepath:
"  {'mtime': time, keywords: {'todo': [todo], 'done': [done], headlines: {lnum: ...}}}}
" 'headline' key contains:
" ITEM TODO LEVEL PRIORITY TAGS LNUM PARENTLNUM FILE BUFNR HEADLINES(reference to full headlines list)
" TIMESTAMP DEADLINE CLOSED SCHEDULED
" Future:
" CATEGORY BLOCKED CLOCKSUM CLOCKSUM_T TIMESTAMP_IA ALLTAGS


function! org#agenda#build() abort " {{{1
  let qf = getqflist()  " to restore
  let startbufnr = bufnr()

  " {{{2 get modified times & files to update
  let updates = {}
  for fname in org#agenda#files()
    let fname = resolve(fnamemodify(fname, ':p'))
    let mtime = getftime(fname)
    if !has_key(g:org#agenda#cache, fname) || g:org#agenda#cache[fname].mtime < mtime
      let updates[fname] = {'mtime': mtime, 'keywords': {'todo': [], 'done': []}, 'headlines': {}}
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
    let prevLevels = {}
    for entry in getqflist()
      let fname = fnamemodify(bufname(entry.bufnr), ':p')
      " Provides: LEVEL TODO PRIORITY ITEM TAGS
      let headline = org#headline#parse(entry.text, updates[fname].keywords)
      let headline.FILE = resolve(fnamemodify(bufname(entry.bufnr), ':p'))
      let headline.BUFNR = entry.bufnr
      let headline.LNUM = entry.lnum
      call filter(prevLevels, 'v:key < ' . headline.LEVEL)

      " Parents and children
      let headline.PARENTS = values(prevLevels)  " [lnum, ... ]
      for [lvl, lnum] in items(prevLevels)
        let parent = updates[fname].headlines[prevLevels[lvl]]
        call add(parent.CHILDREN, headline.LNUM)
      endfor
      let headline.CHILDREN = []  " [lnum, lnum ...]
      let prevLevels[headline.LEVEL] = headline.LNUM

      if bufnr() != entry.bufnr
        execute 'keepjumps buffer ' . entry.bufnr
      endif
      call extend(headline, org#timestamp#get(entry.lnum))
      call extend(headline, org#property#all(entry.lnum), 'keep')
      let updates[fname].headlines[entry.lnum] = headline
    endfor
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


function! org#agenda#view() abort " {{{1
  call org#agenda#build()
  let agenda = []
  for fagenda in values(g:org#agenda#cache)
    let headlines = copy(values(fagenda.headlines))  " shallow copy works. not modifying components
    call extend(agenda, headlines)
  endfor
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
  let projects = sort(org#agenda#view(), org#util#seqsortfunc(['FILE', 'LNUM']))
  call filter(projects, get(a:, 1, {k, v -> v.LEVEL == 2}))
  let stuck = []
  for project in projects
    let cache = g:org#agenda#cache[project.FILE].headlines
    if empty(filter(project.CHILDREN, '!empty(cache[v:val].TODO)'))
      call add(stuck, project)
    endif
  endfor
  return stuck
endfunction

function! org#agenda#todo() abort " {{{1
  let agenda = filter(org#agenda#view(), {k, v -> !empty(v.TODO)})
  call sort(agenda, org#util#seqsortfunc(['FILE', 'LNUM']))
  return agenda
endfunction

function! org#agenda#daily(...) abort " {{{1
  let days = get(a:, 1, 1)
  let time = org#timestamp#parse('now')
  let agenda = filter(org#agenda#view(), {_, hl -> org#timestamp#isplanned(time, hl)})
  call sort(agenda, {a, b -> org#timestamp#tdiff(time, b) - org#timestamp#tdiff(time, a)})
  return agenda
endfunction

function! org#agenda#weekly(...) abort " {{{1
endfunction

function! org#agenda#timely(...) abort " {{{1
endfunction

" TODO refine a search?
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
        \ 'filename': a:item.FILE,
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
  let times = map(copy(a:agenda), {ix, hl -> [ix, org#timestamp#getnearest(separators[0])]})
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
