function! org#agenda#build(...) abort " {{{1
  " TODO: do we want a 'deepcopy' for the agenda cache? Want the subtrees etc to point at
  " the right places?
  return org#outline#full(org#agenda#files())
endfunction

function! org#agenda#files() abort " {{{1
  return sort(glob(org#dir() . '/**/*.org', 0, 1))
endfunction


function! org#agenda#list(...) abort " {{{1
  " a:1 regex of matching filenames
  " TODO list of a filename
  let expr = get(a:, 1, '')
  if type(expr) == v:t_dict
    let fullAgenda = expr
  elseif type(expr) == v:t_string
    let fullAgenda = filter(org#agenda#build(), {k, v -> k =~ expr})
  else
    throw 'Org: {expr} must be a list or an agenda'
  endif

  let agendaList = []
  for agenda in values(fullAgenda)
    let headlines = sort(values(agenda.lnums), {a, b -> a.lnum - b.lnum})
    call extend(agendaList, headlines)
  endfor
  return len(agendaList) == 1 ? values(agendaList)[0] : agendaList
endfunction

function! org#agenda#tree(...) abort " {{{1
  " a:1 regex of matching filenames
  " returns {filename: {level: {lnum: headline, ...}, ...}, ...}
  let expr = get(a:, 1, '')
  let fullAgenda = filter(org#agenda#build(), {k, v -> k =~ expr})
  return fullAgenda
endfunction

function! org#agenda#stuck(...) abort " {{{1
  " A stuck project is one that has no action items. A project will be labeled as
  " default: any headline level 2 or greater that has no action items.
  " This is a flattened tree:
  let projects = get(a:, 1, filter(org#agenda#list(), {_, hl -> hl.level == 2}))
  call filter(projects, {_, hl -> !s:hasKeyword(hl)})
  return sort(projects, org#util#seqsortfunc(['FILE', 'LNUM']))
endfunction

function! s:hasKeyword(headline) abort " {{{2
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

function! org#agenda#todo() abort " {{{1
  let agenda = filter(org#agenda#list(), {k, v -> !empty(v.todo)})
  call sort(agenda, org#util#seqsortfunc(['FILE', 'LNUM']))
  return agenda
endfunction

function! org#agenda#late() abort " {{{1
  " let agenda = filter(, {k, hl -> !empty(hl.TODO)})
  let agenda = filter(org#agenda#list(), {k, hl -> org#timestamp#islate(hl)})
  let agenda = filter(agenda, {k, hl -> empty(hl.done)})
  call sort(agenda, org#util#seqsortfunc(['file', 'lnum']))
  return agenda
endfunction

function! org#agenda#daily(...) abort " {{{1
  let days = get(a:, 1, 1)
  let time = org#timestamp#parsetext('now')
  let agenda = filter(org#agenda#list(), {_, hl -> org#timestamp#isplanned(time, hl)})
  call sort(agenda, {a, b -> org#timestamp#tdiff(time, b) - org#timestamp#tdiff(time, a)})
  return agenda
endfunction

function! org#agenda#timely(...) abort " {{{1
endfunction

function! org#agenda#display(agenda, ...) abort " {{{1
  let s:lastDisplayed = a:agenda  " TODO change me to autocmds
  let Display = get(a:, 1, 0)
  if type(Display) == v:t_string
    let Display = function(Display)
  elseif type(Display) != v:t_func
    let Display = function('org#agenda#toqf')
  endif
  let Separator = get(a:, 2, 0)
  let qfagenda = map(copy(a:agenda), Display)
  if type(Separator) == v:t_func
    let qfagenda = Separator(qfagenda, a:agenda)
  endif
  call setqflist(qfagenda)
  copen
endfunction

function! org#agenda#toqf(ix, item, ...) abort " {{{1
  let opts = get(a:, 1, {})
  let qfitem = {'lnum': a:item.lnum,
        \ 'filename': bufname(a:item.bufnr),
        \ 'module': fnamemodify(a:item.filename, ':t'),
        \ 'item': a:item,
        \ 'text': a:item.todo . '	' . a:item.item }
  for [k, v] in items(opts)
    let qfitem[k] = get(a:item, v, v)
  endfor
  return qfitem
endfunction

function! org#agenda#refine(regex) abort " {{{1
  try
    call filter(s:lastDisplayed, {_, hl -> hl.item =~# a:regex})
    call org#agenda#display(s:lastDisplayed)
  catch /^E121.*lastDisplayed/
    echoerr 'Org: No agenda to refine'
  endtry
endfunction

function! org#agenda#completion(arglead, cmdline, curpos) abort " {{{1
  " See :h :command-completion-customlist
  " To be used with customlist, not custom. Works with spaces better, and regex are nice.
  " autocmd unlets with CmdLineLeave
  if !exists('g:org#agenda#complcache')
    let compl = []
    for [fname, outline] in items(org#agenda#build())
      let fname = substitute(fname, resolve(fnamemodify(org#dir(), ':p')), '', '')
      let names = map(keys(outline.lnums), 's:parent_names(outline.lnums, v:val)')
      call map(names, 'fname . "/" . v:val')
      call add(compl, fname)
      call extend(compl, names)
    endfor
    call map(compl, 'v:val[:]')
    let g:org#agenda#complcache = compl
    autocmd org_completion CmdlineLeave * ++once silent! unlet g:org#agenda#complcache
  endif
  let compl = filter(copy(g:org#agenda#complcache), 'v:val =~? a:arglead')
  return compl
endfunction

function! s:parent_names(lnums, ln) abort " {{{2
  " return a string like hl1/hl2/hl3
  let [name, ln] = ['', a:ln]
  while ln > 0
    let name = a:lnums[ln].item . '/' . name
    let ln = a:lnums[ln].parentlnum
  endwhile
  return name
endfunction
