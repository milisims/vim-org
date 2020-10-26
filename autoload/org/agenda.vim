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

" Highlighting done with matchaddpos, the display function? should highlight it

let g:org#agenda#wincmd = get(g:, 'org#agenda#wincmd', 'keepalt topleft vsplit')
let g:org#agenda#jump = get(g:, 'org#agenda#jump', 'edit')

" Step 1: date and block display
" step 2: customizable 'state' function, between file: headline

" TODO display format, like stl? %f -> filename, %t -> time, %p plan, etc.

function! org#agenda#build(name) abort " {{{1
  if !has_key(g:org#agenda#views, a:name)
    throw 'Org: no agenda view with name ' . a:name . ' to build.'
  endif

  let bufname = 'Agenda_' . a:name
  let bufnum = bufnr(bufname, 1)

  if type(g:org#agenda#wincmd) == v:t_func
    call g:org#agenda#wincmd(bufname)
  else
    execute 'keepalt' g:org#agenda#wincmd bufname
  endif
  setfiletype agenda
  nnoremap <buffer> q :q<Cr>
  nnoremap <buffer> <Cr> :call <SID>jump()<Cr>
  autocmd org_agenda BufWinLeave <buffer> call clearmatches()

  let hllist = []
  for section in g:org#agenda#views[a:name]
    let title = type(section.title) == v:t_string ? section.title : section.title()
    let files = has_key(section, 'files') ? section.files : org#agenda#files()
    let items = []
    for f in values(org#outline#multi(files))
      call extend(items, f.list)
    endfor
    call filter(items, section.filter)
    if has_key(section, 'sorter')
      call sort(items, section.sorter)
    endif

    let just = get(section, 'justify', [])

    if get(section, 'display', 'block') == 'block'  " defaults to block
      let hls = s:display_section(section.title, items, {'func': function('s:block_func')})
    elseif section.display == 'datetime'
      let display = {'func': function('s:datetime_func'), 'separator': function('s:datetime_separator')}
      let hls = s:display_section(section.title, items, display)
    elseif type(section.display) == v:t_dict
      if section.display.func == 'block' || section.display.func == 'datetime'
        let section.display.func = function('s:' . section.display.func . '_func')
      endif
      let hls = s:display_section(section.title, items, section.display)
    else
      throw 'Org: no display type for ' . string(section.display)
    endif

    call extend(hllist, hls)
  endfor
  " setlocal modifiable | 1d | setlocal nomodifiable
  return hllist
  " todo: mapclear & set up mappings
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
  if empty(self.cache)
    let self.cache.date = -9999999999
    let self.cache.today = org#time#dict('today')
  endif

  let nearest = org#plan#nearest(a:hl.plan, self.cache.today, 1)
  if values(nearest)[0].start >= self.cache.date + 86400
    let self.cache.date = org#time#dict(strftime('%Y-%m-%d', values(nearest)[0].start)).start
    return [[strftime('%A, %Y-%m-%d', self.cache.date), 'orgAgendaDate']]
  endif
  return []
endfunction

" TODO :
" highlight link orgAgendaTitle Statement
" highlight link orgAgendaDate Function
" highlight link orgAgendaFile Identifier
" highlight link orgAgendaPlan Comment
" highlight link orgAgendaKeyword Todo
" highlight link orgAgendaHeadline Normal

function! s:display_section(title, items, display) abort " {{{1
  if &filetype != 'agenda'
    throw 'Org: trying to display an agenda in a non-agenda buffer'
  endif
  if len(a:items) == 0
    return [[a:title], ['orgAgendaTitle']]
  endif
  let Get_textinfo = get(a:display, 'func', function('s:block_func'))
  let text_info = map(copy(a:items), {_, hl -> Get_textinfo(hl)})
  let separator = has_key(a:display, 'separator') ? {'cache': {}, 'func': a:display.separator} : {}
  " Calc. spacing
  " Deepcopy so we don't modify the lists: [['Txt'], ['Name']] 'Txt' would be changed to a number.
  let widths = map(deepcopy(text_info), {_, hl -> map(hl[0], "len(v:val)")})
  let cols = len(text_info[0][0])
  let just = has_key(a:display, 'justify') ? a:display.justify : repeat(['l'], cols - 2) + ['', '']
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
      " TODO list of lists
      let lines = separator.func(hl)
      for [txt, groupname] in lines
        call add(all_text, txt)
        call add(highlights, [groupname, [lnum]])
        let lnum += 1
      endfor
    endif

    " Register headline to a line number for <Plug>(org-agenda-goto-headline)
    let b:to_hl[lnum] = {'filename': hl.filename, 'lnum': hl.lnum}

    " Calculate justification, if any, and column for highlighting
    let txt = '  '
    for ix in range(cols)
      let spacing = colwidth[ix] - len(text[ix])
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
  return map(highlights, 'matchaddpos(v:val[0], v:val[1])')
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
        \ [fnamemodify(a:hl.filename, ':t') . ':', plan, a:hl.keyword, a:hl.item],
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

