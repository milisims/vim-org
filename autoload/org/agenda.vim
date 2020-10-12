function! org#agenda#full() abort " {{{1
  " TODO: do we want a 'deepcopy' for the agenda cache? Want the subtrees etc to point at
  " the right places?
  return org#outline#multi(org#agenda#files())
endfunction

" Agenda definition {{{1
" An agenda will be defined as:
" A list of dictionaries that are each sections in the agenda. A section is:
" Required:
" title: str or funcref. If funcref, full agenda passed in as single argument.
" filter: str or funcref. str used in filter() on a list of agenda headlines.
" Optional:
" sorter: str or funcref, if str, map() used. funcref gets filtered list of headlines.
"         Default is by date schedule date then name?
" display: funcref, passed in: title, list of filtered and sorted items.
"          Items displayed as:    hl.title         :tags:
" files: list of filenames. Uses org#util#fname format

" An agenda
" window: function that creates the window, defaults to g:org#agenda#window
" Note: 'headline' is a similiar value from headline#get
" After an agenda is defined, it can be displayed with Agenda [name].
" This command creates a nomod buffer like UndoTree or NerdTree, etc
" generates titles, filters, sorts, then displays each item in a buffer
" variable to set up window generation

" let g:org#agenda#window = function('my#popupwindow')
" let g:org#agenda#views = { name :
" [
" {'title': 'Daily', 'filter': {_, hl -> org#plan#within(hl.plan, '1d')}},
" {'title': 'Weekly', 'filter': {_, hl -> org#plan#within(hl.plan, '1w')}},
" {'title': 'NEXT', 'filter': {_, hl -> org#plan#within(hl.plan, '1m')}},
" {'title': 'TODO', 'filter': {_, hl -> org#plan#within(hl.plan, '1m')}},
" {'title': 'Stuck Projects', 'filter': {_, hl -> org#plan#within(hl.plan, '1m')}},
" ]}
" }}}
" Simplified agenda definition {{{1
" An agenda will be defined as:
" A list of dictionaries that are each sections in the agenda. A section is:
" Required:
" title: str or funcref. If funcref, full agenda passed in as single argument.
" filter: str or funcref. str used in filter() on a list of agenda headlines.
" Optional:
" sorter: str or funcref, if str, map() used. funcref gets filtered list of headlines.
"         Default is by date schedule date then name?
" display: str, 'time', 'date', 'items'
" files: list of filenames. Uses org#util#fname format

" An agenda
" window: command that creates the window, defaults to g:org#agenda#window
" rebuild: if 1, force rebuild rather than searching for an agenda buffer

" }}}

function! s:getsection(section) abort  " {{{1 RENAME
  " Seriously, why isn't get() short circuited?
  let title = type(a:section.title) == v:t_string ? a:section.title : a:section.title()
  let filter = a:section.filter
  let files = has_key(a:section, 'files') ? a:section.files : org#agenda#files()
  let sorter = has_key(a:section, 'sorter') ? a:section.sorter : g:org#agenda#sorter
  " let display = has_key(a:section, 'display') ? a:section.display : g:org#agenda#display
  let outline = org#outline#multi(files)  " should be fast enough, gets cached the first time
  " let list = has_key(a:section, 'generator') ? a:section.generator(outline) : outline.list
  let items = filter(outline.list, filter)
  call sort(items, sorter)
  return items
endfunction

" Highlighting done with matchaddpos, the display function? should highlight it

let g:org#agenda#wincmd = get(g:, 'org#agenda#wincmd', 'keepalt topleft vsplit')

let s:agendabufs = {}

augroup org_agenda
  autocmd!
augroup END

" Step 1: date and block display
" step 2: customizable 'state' function, between file: headline

" TODO display format, like stl? %f -> filename, %t -> time, %p plan, etc.

function! org#agenda#build(name) abort " {{{1
  if index(g:org#agenda#views, a:name) < 0
    throw 'Org: no agenda view with name ' . a:name . ' to build.'
  endif
  let bufname = 'Agenda_' . a:name
  let bufnum = bufnr(bufname, 1)
  if type(g:org#agenda#wincmd) == v:t_func
    call g:org#agenda#wincmd(bufname)
  else
    execute g:org#agenda#wincmd bufname
  endif
  setfiletype agenda

  " execute 'autocmd org_agenda BufDelete <buffer> unlet! s:agendabufs[expand(' . a:name . ')]'
  " let s:agendabufs[a:name] = bufnr()

  for aview in g:org#agenda#views[a:name]
    try
      call g:org#agenda#display[aview.display](s:getsection(g:org#agenda#views))
    catch /^Vim\%((\a\+)\)\=:E716/
      echohl Error
      echo 'Org: No way to display ' . aview.display . ', check g:org#agenda#display'
      echohl None
    endtry
  endfor
endfunction

function! org#agenda#datetime(title, items) abort " {{{1
  " Title
  " Date
  "   file:     9:00...... Scheduled: NEXT do a thing
  "   file:    15:00...... Scheduled: TODO do a thing

  if &filetype != 'agenda'
    throw 'Org: trying to display an agenda in a non-agenda buffer'
  endif

  let today = org#time#dict('today')
  let items = sort(copy(a:items), {a, b -> org#time#diff(values(a.plan)[0], values(b.plan)[0])})
  let fname_width = max(map(copy(items), 'len(fnamemodify(v:val.filename, ":t"))')) + 2
  let [time_width, plan_width] = [10, 12]
  let all_text = empty(a:title) ? [] : [a:title]

  let date = -9999999999
  let lnum = line('$') + 1
  let links = {}
  for hl in items
    let nearest = org#plan#nearest(hl.plan, today, 1)
    if values(nearest)[0].start >= date + 86400
      let date = org#time#dict(strftime('%Y-%m-%d', values(nearest)[0].start)).start
      call add(all_text, strftime('%A, %Y-%m-%d', date))
      let lnum += 1
    endif
    let lnum += 1
    let links[lnum] = hl
    let fname = fnamemodify(hl.filename, ':t')
    let text = repeat(' ', fname_width - len(fname)) . fname
    let nearest = org#plan#nearest(hl.plan, today, 1)
    let time = strftime('%R', values(nearest)[0].start)
    let text .= repeat(' ', time_width - len(time)) . time . '...'
    " let plan = empty(nearest) ? '---' : keys(nearest)[0] . ':'
    " let text .= repeat(' ', plan_width - len(plan)) . plan
    let text .= ' ' . hl.keyword . ' ' .  hl.item
    call add(all_text, text)
  endfor

  setlocal modifiable
  call append('$', all_text)
  setlocal nomodifiable

  return links
endfunction

function! org#agenda#block(title, items) abort " {{{1
  " Title
  "   file:  Scheduled: NEXT do a thing
  "   file:  Scheduled: TODO do a thing
  if &filetype != 'agenda'
    throw 'Org: trying to display an agenda in a non-agenda buffer'
  endif
  let today = org#time#dict('today')
  let fname_width = max(map(copy(a:items), 'len(fnamemodify(v:val.filename, ":t"))')) + 2
  let plan_width = 12
  let all_text = empty(a:title) ? [] : [a:title]
  for hl in a:items
    let fname = fnamemodify(hl.filename, ':t')
    let text = repeat(' ', fname_width - len(fname)) . fname
    let nearest = org#plan#nearest(hl.plan, today, 1)
    let plan = empty(nearest) ? '---' : keys(nearest)[0] . ':'
    let text .= repeat(' ', plan_width - len(plan)) . plan
    let text .= ' ' . hl.keyword . ' ' .  hl.item
    call add(all_text, text)
  endfor
  setlocal modifiable
  call append('$', all_text)
  setlocal nomodifiable
endfunction

function! s:get_block_text(hl, today) abort " {{{1
  " \ 'keyword': empty(a:hl.done) ? a:hl.todo : a:hl.done,
  return {'filename': fnamemodify(a:hl.filename, ':t'),
        \ 'plan': org#plan#nearest(a:hl.plan, a:today, 1),
        \ 'keyword': a:hl.keyword,
        \ 'item': a:hl.item,
        \ 'tags': a:hl.tags}
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

function! org#agenda#files(...) abort " {{{1
  return get(g:, 'org#agenda#filelist', sort(glob(org#dir() . get(a:, 1, '/**/*.org'), 0, 1)))
endfunction

function! org#agenda#late() abort " {{{1
  " let agenda = filter(, {k, hl -> !empty(hl.TODO)})
  let agenda = filter(org#agenda#list(), {k, hl -> !hl.done && org#plan#islate(hl.plan)})
  call sort(agenda, org#util#seqsortfunc(['file', 'lnum']))
  return agenda
endfunction

function! org#agenda#todo() abort " {{{1
  let agenda = filter(org#agenda#list(), {k, v -> !v.done && !empty(v.keyword)})
  call sort(agenda, org#util#seqsortfunc(['FILE', 'LNUM']))
  return agenda
endfunction


