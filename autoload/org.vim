" NOTE: Generally, we follow the pattern:
" let var = check_for_context()
" if var is True, then process. Otherwise return.

" NOTE:
" get/is/has
" when a function has 'direction' vs above/below -- shouldn't?

" function! org#add_property() abort
"   let [property_drawer_start, property_drawer_end] = org#property_drawer_range('.')
"   let headline = org#headline#find('.', 0, 'bW')
"   call append(headline, [':PROPERTIES:', '', ':END:'])
" endfunction

function! org#shift(direction, mode) range abort " {{{1
  " Move things around attempting to preserving structure of selected components
  " FIXME:
  " dedent and indent:
  "   - line a
  "   line b
  let lnum = a:firstline
  let cursor = getcurpos()[1:]
  if org#headline#checkline(a:firstline) " {{{2
    while lnum >= a:firstline && lnum <= a:lastline
      call cursor(lnum, 0)
      if a:direction > 0
        call org#headline#promote()
      else
        call org#headline#demote()
      endif
      let lnum = org#headline#find(lnum, 0, 'nxW')
    endwhile
    if a:mode == 'i'
      call feedkeys(a:direction > 0 ? "\<C-g>U\<Right>" : "\<C-g>U\<Left>", 'n')
    endif
    return
  elseif org#list#checkline(a:firstline) " {{{2
    " TODO reorder and bullet cycling
    let lnum = org#list#item_start(a:firstline)
    let items = []
    let range = [0, 0]
    while lnum >= a:firstline && lnum <= a:lastline || empty(items)
      if range[1] < lnum
        call add(items, lnum)
        let range = org#list#item_range(lnum)
      endif
      let lnum = org#list#find(lnum, 'nxW')
    endwhile

    for lnum in items
      " TODO format me after indenting
      " FIXME if a list with sub items is visually selected, the sublists are moved twice
      call cursor(lnum, 1)
      call org#list#item_indent(a:direction)
      " if org#list#get_bullet(lnum) == org#list#get_bullet(org#list#parent_item_range(lnum)[0])
      "   if org#list#item_is_unordered(lnum)
      "     call org#list#bullet_cycle(lnum, 1)  " a:direction)
      "   endif
      "   if org#list#item_is_ordered(lnum)
      "     call org#list#reorder()
      "   endif
      " endif
    endfor

  else " plain text for now {{{2
    " FIXME: fails in insert mode
    execute a:firstline.','.a:lastline . (a:direction > 0 ? '>' : '<')
  endif " }}}

  if a:mode == 'i'
    let cursor[1] += a:direction * &shiftwidth
  endif
  call cursor(cursor)

endfunction

function! org#dir() abort " {{{1
  return get(g:, 'org#dir', get(b:, 'org#dir', '~/org'))
endfunction

function! org#refile(lnum, ...) abort " {{{1
  " Does not distinguish between two identical headlines.
  " TODO? define behavior for a/b/c? or require.org ?
  let copy = get(a:, 1, 0)
  let [st, end] = org#section#range(a:lnum)
  let refile_level = org#headline#level(a:lnum)
  let text = getline(st, end)
  if !copy
    execute st . ',' . end . 'd _'
  endif

  let agenda = org#agenda#list()
  let startbufnr = bufnr()
  let prompt = 'Refile> '
  let destination = input(prompt, '', 'customlist,org#agenda#completion')

  try
    let target = org#headline#maketarget(destination)
    execute 'split' target.FILE
    let winnr = winnr()
    call append(target.LNUM, text)  " FIXME will not preserve timestamps/properties
    let shift = target.LEVEL - refile_level
    for i in range(abs(shift))
      execute lnum . ',' lnum + (end - st) 'call org#shift(' . shift > 0 ? 1 : -1 . ', "v")'
    endfor

    if startbufnr != bufnr(fname)
      write
    endif

  finally
    execute winnr . 'wincmd c'
  endtry

endfunction

function! org#plan(lnum) abort " {{{1
  let current = org#timestamp#get(a:lnum)
  redraw
  let prompt = "Planning:\n"
  let prompt .= getline(org#headline#at(a:lnum)) . "\n"
  let ts = getline(org#timestamp#at(a:lnum)) . "\n"
  let prompt .= org#timestamp#checkline(a:lnum) ? ts  . "\n": ''
  let prompt .= '> '
  let time = input(prompt, '', 'customlist,org#timestamp#completion')
  let [plantype; datetime] = split(time)
  let timestamp = org#timestamp#from_text(join(datetime), current)
  let timestamp.active = plantype != 'CLOSED'
  call org#timestamp#set(a:lnum, timestamp)
endfunction

function! org#daily() abort " {{{1
  let agenda = org#agenda#daily(3)
  let now = org#timestamp#parsetext('today')
  let TimeMod = {hl -> {'module': org#timestamp#ftime2text(org#timestamp#getnearest(now, hl)[1])}}
  call map(agenda, {ix, hl -> org#agenda#toqf(ix, hl, (hl))})
  call setqflist(agenda)
  copen
endfunction

function! org#late() abort " {{{1
  let agenda = filter(org#agenda#list(), {k, hl -> org#timestamp#islate(hl)})
  call sort(agenda, org#util#seqsortfunc(['FILE', 'LNUM']))
  call map(agenda, {ix, hl -> org#agenda#toqf(ix, hl)})
  call setqflist(agenda)
  copen
endfunction

function! org#process_inbox() abort " {{{1
  let agenda = org#agenda#list()
  let inbox = resolve(fnamemodify(g:org#inbox, ':p'))
  call filter(agenda, {_, hl -> hl.FILE == inbox})
  call filter(agenda, {_, hl -> hl.LEVEL == 1})
  call sort(agenda, {a, b -> a.LNUM - b.LNUM})
  " call map(agenda, {ix, hl -> org#agenda#toqf(ix, hl)})
  " call setqflist(agenda)

  while !empty(agenda)
    let item = remove(agenda, 0)
    let process = input(s:getprompt(item), '')  " TODO check out completion
    " TODO process the items
    if empty(process)     " if bad input after processing
      call insert(agenda, item)  " put it back
    endif
  endwhile
  " return agenda
endfunction


function! org#capture() range abort " {{{1
  if !exists('g:org#capture#templates')
    echoerr 'No capture templates see :h g:org#capture#templates'
    return
  endif
  if type(g:org#capture#templates) == 4
    let order = copy(get(g:, 'org#capture#order', sort(keys(g:org#capture#templates))))
    let order = filter(order, 'has_key(g:org#capture#templates, v:val)')
    let templates = map(order, {_, k -> extend(g:org#capture#templates[k], {'key': k})})
  elseif type(g:org#capture#templates) == 3
    let templates = copy(g:org#capture#templates)
  else
    throw 'Org: g:org#capture#templates must be a list or dictionary.'
  endif

  let templates = filter(templates, {_, t -> !has_key(t, 'context') || t.context()})
  let capture = org#capture#window(templates)
  if empty(capture) | return | endif
  call org#capture#do(capture)
endfunction


