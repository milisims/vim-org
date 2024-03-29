let g:org#agenda#wincmd = get(g:, 'org#agenda#wincmd', 'keepalt topleft vsplit')
let g:org#agenda#jump = get(g:, 'org#agenda#jump', 'edit')

function! s:make_buffer(name) abort " {{{1
  let bufnum = bufnr(a:name, 1) " creates buffer
  if type(g:org#agenda#wincmd) == v:t_func
    call g:org#agenda#wincmd(a:name)
  else
    execute 'keepalt' g:org#agenda#wincmd a:name
  endif
  " TODO org.view ?
  setfiletype agenda
  let b:agenda_name = a:name
  nnoremap <buffer> <Plug>(org-agenda-goto-headline) :call <SID>jump()<Cr>
  autocmd org_agenda BufWinLeave <buffer> call clearmatches()
endfunction

function! org#agenda#build(name) abort " {{{1
  if !has_key(g:org#agenda#views, a:name)
    throw 'Org: no agenda view with name ' . a:name . ' to build.'
  endif

  call s:make_buffer('Agenda_' . a:name)
  doautocmd User OrgAgendaBuildPre

  for section in g:org#agenda#views[a:name]
    let title = type(section.title) == v:t_string ? section.title : section.title()
    if has_key(section, 'generator')
      let items = function(section.generator)()
    elseif has_key(section, 'files')
      let items = org#agenda#items(section.files)
    else
      let items = org#agenda#items()
    endif

    try
      if type(section.filter) == v:t_string
        call filter(items, org#agenda#filter(section.filter))
      elseif type(section.filter) == v:t_func
        call filter(items, section.filter)
      endif
    catch /^Vim\%((\a\+)\)\=:E716/
      if !has_key(section, 'generator')
        echoerr 'Agenda sections need either a generator or a filter.'
      endif
    endtry

    if has_key(section, 'sorter')
      " let items = org#agenda#sort(items, section.sorter)
      if type(section.sorter) == v:t_string
        call sort(items, org#agenda#sorter(section.sorter))
      elseif type(section.sorter) == v:t_func
        call sort(items, section.sorter)
      else
        try
          echoerr 'Agenda sorter must be string or funcref'
        endtry
      endif
    endif


    let Display = get(section, 'display', 'block')
    if type(Display) == v:t_string && Display == 'block'
      let Display = function('s:block_func')
      let Separator = {}
    elseif type(Display) == v:t_string && Display == 'datetime'
      let Display = function('s:datetime_func')
      let Separator = function('s:datetime_separator')
    else
      try
        let Display = function(Display)
      catch  " FIXME E700 ?
        echoerr 'Org: display in agenda section "' . title . '" is not a function name or funcref.'
      endtry
      let Separator = {}
    endif
    try
      let Separator = has_key(section, 'separator') ? function(section.separator) : Separator
    catch
      echoerr 'Org: separator in agenda section "' . title . '" is not a function name or funcref.'
    endtry

    let justify = get(section, 'justify', [])
    call s:display_section(section.title, items, Display, Separator, justify)
  endfor
endfunction

function! org#agenda#view(filterstr) abort " {{{1
  call s:make_buffer('View')
  let b:items = org#agenda#items()
  call org#agenda#filterview(a:filterstr)
endfunction

function! org#agenda#filterview(filterstr) abort " {{{1
  try
    let b:items = filter(b:items, org#agenda#filter(a:filterstr))
  catch /^Vim\%((\a\+)\)\=:E716/
    echoerr 'No items to filter, create a :View first, and be in the buffer'
  endtry
  setlocal modifiable
  call deletebufline(bufnr(), 1, '$')
  setlocal nomodifiable
  call s:display_section('', b:items, function('s:block_func'), {}, [])
endfunction

function! org#agenda#sortview(sortstr) abort " {{{1
  try
    call sort(b:items, org#agenda#sorter(a:sortstr))
  catch /^Vim\%((\a\+)\)\=:E716/
    echoerr 'No items to sort, create a :View first, and be in the buffer'
  endtry
  call s:display_section('', b:items, function('s:block_func'), {}, [])
endfunction

function! org#agenda#files(...) abort " {{{1
  return map(get(g:, 'org#agenda#filelist', sort(glob(org#dir() . get(a:, 1, '/**/*.org'), 0, 1))), 'org#util#fname(v:val)' )
endfunction

function! org#agenda#items(...) abort " {{{1
  let files = exists('a:1') ? a:1 : org#agenda#files()
  let items = []
  for f in values(org#outline#multi(files))
    call extend(items, f.list)
  endfor
  return items
endfunction

function! org#agenda#sort(items, sorter) abort " {{{1
  let items = a:items
  if type(a:sorter) == v:t_string
    return sort(items, s:make_sorter(a:sorter))
  elseif type(a:sorter) == v:t_func
    return sort(items, a:sorter)
  endif
  try
    echoerr 'Agenda sorter must be string or funcref'
  endtry
endfunction

function! org#agenda#toqf(agenda) abort " {{{1
  let s:lastDisplayed = a:agenda  " TODO change me to autocmds
  let qfagenda = []
  for item in a:agenda
    let fname = fnamemodify(item.filename, ':t')
    call add(qfagenda, {'lnum': item.lnum,
        \ 'filename': bufname(item.bufnr),
        \ 'module': fname,
        \ 'text': item.todo . '	' . item.target[len(fname) + 1:] })
  endfor
  call setqflist(qfagenda)
endfunction

function! s:jump() abort " {{{1
  if !has_key(b:to_hl, line('.'))
    echohl Error | echo 'No headline associated with line ' . line('.') | echohl None
  endif

  execute g:org#agenda#jump b:to_hl[line('.')].filename .'|'. b:to_hl[line('.')].lnum
  if empty(&filetype)
    setfiletype org
  endif
endfunction

function! s:datetime_separator(hl) abort dict " {{{1
  if !has_key(self, 'date')
    let self.date = -9999999999
    let self.today = org#time#dict('today')
  endif

  let nearest = org#plan#nearest(a:hl.plan, self.today, 1)
  if values(nearest)[0].start >= self.date + 86400
    let self.date = org#time#dict(strftime('%Y-%m-%d', values(nearest)[0].start)).start
    return [[strftime('%A, %Y-%m-%d', self.date), 'orgAgendaDate']]
  endif
  return []
endfunction

function! s:display_section(title, items, display, separator, justify) abort " {{{1
  if &filetype != 'agenda'
    throw 'Org: trying to display an agenda in a non-agenda buffer'
  endif
  if len(a:items) == 0
    return [[a:title], ['orgAgendaTitle']]
  endif
  let text_info = map(copy(a:items), {_, hl -> a:display(hl)})
  let separator = type(a:separator) == v:t_func ? {'func': a:separator} : {}
  " Calc. spacing
  " Deepcopy so we don't modify the lists: [['Txt'], ['Name']] 'Txt' would be changed to a number.
  let widths = map(deepcopy(text_info), {_, hl -> map(hl[0], "len(v:val)")})
  let cols = len(text_info[0][0])
  let just = !empty(a:justify) ? a:justify : repeat(['l'], cols - 2) + ['', '']
  if len(just) != cols
    throw 'Org: justification spec length must equal display function length'
  endif
  let colwidth = []
  for ix in range(cols)
    let width = empty(just[ix]) ? 0 : 1 + max(map(copy(widths), 'v:val[ix]'))
    call add(colwidth, width)
  endfor

  " Display, highlight, and associate headlines with lnums in agenda
  let lnum = line('$') + 2
  let all_text = [a:title]
  let highlights = [['orgAgendaTitle', [lnum - 1]]]
  let b:to_hl = get(b:, 'to_hl', {})
  for jx in range(len(a:items))
    let [text, hlgroups, hl] = [text_info[jx][0], text_info[jx][1], a:items[jx]]

    " Calculate separator lines
    if !empty(separator)
      let lines = separator.func(hl)
      for [txt, groupname; link] in lines
        call add(all_text, txt)
        call add(highlights, [groupname, [lnum]])
        if !empty(link)
          let b:to_hl[lnum] = link[0]
        endif
        let lnum += 1
      endfor
    endif

    " Register headline to a line number
    let b:to_hl[lnum] = hl

    " Calculate justification, if any, and column for highlighting
    let txt = '  '
    for ix in range(cols)
      let spacing = colwidth[ix] - strdisplaywidth(text[ix])
      if just[ix] == 'l'
        if txt[len(txt) - 1] != ' '
          let txt .= ' '
        endif
        let col = len(txt)
        let txt .= text[ix] . repeat(' ', spacing)
      elseif just[ix] == 'r'
        let txt .= repeat(' ', spacing)
        let col = len(txt)
        let txt .= text[ix]
      elseif just[ix] == 'c'
        let txt .= repeat(' ', spacing / 2)
        let col = len(txt)
        let txt .= text[ix] . repeat(' ', spacing / 2)
      elseif len(text[ix]) == 0  " not justified, and no text = skip it
        continue
      else
        if txt[len(txt) - 1] != ' '
          let txt .= ' '
        endif
        let col = len(txt)
        let txt .= text[ix]
      endif
      call add(highlights, [hlgroups[ix], [[lnum, col + 1, strlen(text[ix])]]])
    endfor

    call add(all_text, substitute(txt, ' \+$', '', ''))
    let lnum += 1

  endfor
  setlocal modifiable
  call append('$', all_text)
  setlocal nomodifiable
  call map(highlights, 'matchaddpos(v:val[0], v:val[1])')
endfunction

function! s:block_func(hl) abort " {{{1
  let nearest = org#plan#nearest(a:hl.plan, org#time#dict('today'), 1)
  let plan = empty(nearest) ? '---' : keys(nearest)[0] . ':'
  if empty(nearest)
    let plan = '---'
  else
    let [name, time] = items(nearest)[0]
    let plan = (name =~# '^T' ? '' : name[0] . ':') . time.totext('dTR')
  endif
  return [
        \ [matchstr(a:hl.target, '[^/]*\.org.*\ze/[^/]\{-}') . ':', plan, a:hl.keyword, a:hl.item],
        \ ['orgAgendaFile', 'orgAgendaPlan', 'orgAgendaKeyword', 'orgAgendaHeadline'],
        \ ]
endfunction

function! s:datetime_func(hl) abort " {{{1
  let time = strftime('%R', values(org#plan#nearest(a:hl.plan, org#plan#nearest(a:hl.plan, org#time#dict('today'), 1), 1))[0].start)
  let time = (time == '00:00' ? '' : time) . '...'
  return [
        \ [fnamemodify(a:hl.filename, ':t') . ':', time, a:hl.keyword, a:hl.item],
        \ ['orgAgendaFile', 'orgAgendaPlan', 'orgAgendaKeyword', 'orgAgendaHeadline'],
        \ ]
endfunction

function! org#agenda#filter(str) abort " {{{1
  if has_key(s:filter_cache, a:str)
    return s:filter_cache[a:str]
  endif
  if count(a:str, "'") % 2 > 0
    try
      echoerr 'Unbalanced single quotes in search string: "' . a:str . '"'
    endtry
  endif
  let filterstr = [[]]
  let keywords = []
  call map(values(org#outline#multi(org#agenda#files())), 'extend(keywords, v:val.keywords.all)')
  let keywords = uniq(sort(keywords))

  " Get rid of spaces outside of quotes, and then loop through each item.
  let str = substitute(a:str, '\v \ze%(%([^'']*''[^'']*'')*[^'']*$)', '', 'g')
  let options = split(str, '\v\ze[-+|&]%(%([^'']*''[^'']*'')*[^'']*$)')
  for fl in filter(options, '!empty(v:val)')
    if fl[0] == '|'
      let fl = fl[1:]
      call add(filterstr, [])
      if empty(fl)
        continue
      endif
    endif

    let [incl, name, comparison, value] = matchlist(fl, '\v^([-+])?(.{-})%(([!=]?[=~][#?]?|[<>]\=?)(.*))?$')[1:4]
    let included = incl != '-'
    let name = substitute(name, "'", '', 'g')
    let value = substitute(value, "'", '', 'g')

    if index(['TIMESTAMP', 'DEADLINE', 'SCHEDULED', 'CLOSED'], name) >= 0
      " Check if it has name plan at all
      " If has comparison, compare.
      let fs = 'has_key(v:val.plan, "' . name . '")'
      if !empty(comparison)
        let value = org#time#dict(value)
        let value = {'start': value.start, 'end': value.end}
        let fs = fs . ' && org#time#diff(v:val.plan.' . name . ', ' . string(value) . ')'
        let fs = '(' . fs . ' ' . comparison . ' 0)'
      endif
      let fs = (included ? '' : '!') . fs . ''

    elseif name == 'PLAN'
      if !empty(comparison)
        let value = org#time#dict(value)
        let value = {'start': value.start, 'end': value.end}
        let fs = 'org#plan#within(v:val.plan, ' . string(value) .  ')'
      else
        let fs = 'org#plan#isplanned(v:val.plan)'
      endif
      let fs = (included ? '' : '!') . fs

    elseif name == 'LATE'
      let fs = (included ? '' : '!') . 'org#plan#islate(v:val.plan)'

    elseif name == 'DONE'
      let fs = (included ? '' : '!' ) . 'v:val.done'

    elseif name == 'KEYWORD'
      let fs = (included ? '!' : '' ) . 'empty(v:val.keyword)'

    elseif !empty(comparison) " is property or timestamp
      " +-, propname, comparison, value
      if name == '' " plan
        let value = org#time#dict(value)
        let fs = "v:val.properties['" . name . "'] " . comparison . ' ' . value
      else
        if value =~ '^<.*>$'
          let value = org#time#dict(value)
        endif
        let fs = "v:val.properties['" . name . "'] " . comparison . ' ' . value
      endif
      let fs = (included ? '(' : '!(') . fs . ')'

    elseif index(keywords, name) >= 0
      let fs = 'v:val.keyword ' . (included ? '=' : '!') . "= '" . name . "'"

    elseif !empty(name)
      let fs = "index(v:val.tags, '" . name . "') " . (included ? '>=' : '<') . ' 0'

    else
      try
        echoerr 'Unable to parse "' . fl . '" in search "' . a:str . '"'
      endtry
    endif

    call add(filterstr[-1], fs)

  endfor
  call filter(filterstr, '!empty(v:val)')
  if empty(filterstr)
    return '1'
  endif
  let s:filter_cache[a:str] = '(' . join(map(filterstr, 'join(v:val, " && " )'), ') || (') . ')'
  return s:filter_cache[a:str]
endfunction
let s:filter_cache = {}

function! org#agenda#sorter(str) abort " {{{1
  " + is ascending, - is descending. Assume property, items without property do what?
  " Must be +A-b-c+d, no other options. Just: sort based on A, then b, then c, then d.
  if has_key(s:Sorter_cache, a:str)
    return s:Sorter_cache[a:str]
  endif
  if count(a:str, "'") % 2 > 0
    try
      echoerr 'Unbalanced single quotes in search string: "' . a:str . '"'
    endtry
  endif
  let sortlist = []

  " Get rid of spaces outside of quotes, and then loop through each item.
  let str = substitute(a:str, '\v \ze%(%([^'']*''[^'']*'')*[^'']*$)', '', 'g')
  let options = split(str, '\v\ze[-+]%(%([^'']*''[^'']*'')*[^'']*$)')
  " Construct a lambda, will be like {hl1, hl2 -> string}
  for fl in filter(options, '!empty(v:val)')

    let [ace, name] = matchlist(fl, '\v^([-+])?(.{-})$')[1:2]
    let [a, b] = ace != '-' ? ['hl1', 'hl2'] : ['hl2', 'hl1']
    let name = substitute(name, "'", '', 'g')

    if index(['TIMESTAMP', 'DEADLINE', 'SCHEDULED', 'CLOSED'], name) >= 0
      let sortstr = 'org#time#diff(' . a . '.plan.' . name . ', ' . b . '.plan.' . name . ')'
    elseif name == 'PLAN'
      let sortstr = 'org#time#diff(org#plan#nearest(' . a . '.plan), org#plan#nearest(' . b . '.plan))'
    else
      let sortstr = a . '.properties.' . name . ' - ' . b . '.properties.' . name
    endif

    call add(sortlist, sortstr)

  endfor

  if len(sortlist) == 1
    let s:Sorter_cache[a:str] = eval('{hl1, hl2 -> ' . sortlist[0] . '}')
  else
    function s:sorter{len(s:Sorter_cache)}(hl1, hl2) closure
      let [hl1, hl2] = [a:hl1, a:hl2]
      for sorter in sortlist
        let diff = eval(sorter)
        if diff != 0
          return diff
        endif
      endfor
      return 0
    endfunction
    let s:Sorter_cache[a:str] = funcref('s:sorter' . len(s:Sorter_cache))
  endif

  return s:Sorter_cache[a:str]
endfunction
let s:Sorter_cache = {}

