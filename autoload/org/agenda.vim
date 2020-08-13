function! org#agenda#full() abort " {{{1
  " TODO: do we want a 'deepcopy' for the agenda cache? Want the subtrees etc to point at
  " the right places?
  return org#outline#multi(org#agenda#files())
endfunction

function! org#agenda#daily(...) abort " {{{1
  let expr = get(a:, 1, '')
  let days = get(a:, 1, 2)
  let time = localtime()
  let agenda = filter(org#agenda#list(expr), {_, hl -> org#plan#isplanned(hl.plan, time)})
  call sort(agenda, {a, b -> org#time#diff(org#plan#nearest(a.plan, time), org#plan#nearest(a.plan, time))})
  return agenda
endfunction

function! org#agenda#toqf(agenda) abort " {{{1
  let s:lastDisplayed = a:agenda  " TODO change me to autocmds
  let qfagenda = []
  for item in a:agenda
    call add(qfagenda, {'lnum': item.lnum,
        \ 'filename': bufname(item.bufnr),
        \ 'module': fnamemodify(item.filename, ':t'),
        \ 'text': item.todo . '	' . item.target })
  endfor
  call setqflist(qfagenda)
endfunction

function! org#agenda#files(...) abort " {{{1
  return get(g:, 'org#agenda#filelist', sort(glob(org#dir() . get(a:, 1, '/**/*.org'), 0, 1)))
endfunction

function! org#agenda#late() abort " {{{1
  " let agenda = filter(, {k, hl -> !empty(hl.TODO)})
  let agenda = filter(org#agenda#list(), {k, hl -> org#plan#islate(hl.plan)})
  let agenda = filter(agenda, {k, hl -> empty(hl.done)})
  call sort(agenda, org#util#seqsortfunc(['file', 'lnum']))
  return agenda
endfunction

function! org#agenda#list(...) abort " {{{1
  " a:1 regex of matching filenames
  " TODO list of a filename
  let expr = get(a:, 1, '')
  if type(expr) == v:t_dict
    let fullAgenda = expr
  elseif type(expr) == v:t_string
    let fullAgenda = filter(org#agenda#full(), {k, v -> k =~ expr})
  else
    throw 'Org: {expr} must be a list or an agenda'
  endif

  let agendaList = []
  for agenda in values(fullAgenda)
    call extend(agendaList, agenda.list)
  endfor
  return len(agendaList) == 1 ? values(agendaList)[0] : agendaList
endfunction

function! org#agenda#refine(regex) abort " {{{1
  try
    call filter(s:lastDisplayed, {_, hl -> hl.item =~# a:regex})
    call org#agenda#display(s:lastDisplayed)
  catch /^E121.*lastDisplayed/
    echoerr 'Org: No agenda to refine'
  endtry
endfunction

function! org#agenda#stuck(...) abort " {{{1
  " A stuck project is one that has no action items. A project will be labeled as
  " default: any headline level 2 or greater that has no action items.
  " This is a flattened tree:
  let projects = get(a:, 1, filter(org#agenda#list(), {_, hl -> hl.level == 2}))
  call filter(projects, {_, hl -> !s:hasKeyword(hl)})
  return sort(projects, org#util#seqsortfunc(['FILE', 'LNUM']))
endfunction

function! org#agenda#timely(...) abort " {{{1
endfunction

function! org#agenda#todo() abort " {{{1
  let agenda = filter(org#agenda#list(), {k, v -> !empty(v.todo)})
  call sort(agenda, org#util#seqsortfunc(['FILE', 'LNUM']))
  return agenda
endfunction


function! org#agenda#tree(...) abort " {{{1
  " a:1 regex of matching filenames
  " returns {filename: {level: {lnum: headline, ...}, ...}, ...}
  let expr = get(a:, 1, '')
  let fullAgenda = filter(org#agenda#full(), {k, v -> k =~ expr})
  return fullAgenda
endfunction

function! s:hasKeyword(headline) abort " {{{1
  if !empty(a:headline.todo)
    return 1
  endif
  for st in a:headline.subtrees
    if s:hasKeyword(st)
      return 1
    endif
  endfor
  return 0
endfunction

