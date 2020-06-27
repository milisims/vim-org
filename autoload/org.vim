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

function! org#capture() range abort " {{{1
  if !exists('g:org#capture#templates')
    echoerr 'No capture templates see :h g:org#capture#templates'
    return
  endif
  if type(g:org#capture#templates) == v:t_dict
    let order = copy(get(g:, 'org#capture#order', sort(keys(g:org#capture#templates))))
    let order = filter(order, 'has_key(g:org#capture#templates, v:val)')
    let templates = map(order, {_, k -> extend(g:org#capture#templates[k], {'key': k})})
  elseif type(g:org#capture#templates) == v:t_list
    let templates = copy(g:org#capture#templates)
  else
    throw 'Org: g:org#capture#templates must be a list or dictionary.'
  endif

  let templates = filter(templates, {_, t -> !has_key(t, 'context') || (type(t.context) == 1 ? eval(t.context) : t.context())})
  let capture = org#capture#window(templates)
  if empty(capture) | return | endif
  call org#capture#do(capture)
endfunction

function! org#daily() abort " {{{1
  call setqflist(map(org#agenda#daily('', 3), 'org#agenda#toqf(v:val)'))
  copen
endfunction

function! org#dir() abort " {{{1
  return get(g:, 'org#dir', get(b:, 'org_dir', '~/org'))
endfunction

function! org#format() abort " {{{1
  " The |v:lnum|  variable holds the first line to be formatted.
  " The |v:count| variable holds the number of lines to be formatted.
  " The |v:char|  variable holds the character that is going to be
  "       inserted if the expression is being evaluated due to
  "       automatic formatting.  This can be empty.  Don't insert
  "       it yet!
  " for each header block in region
  " if empty, behave like:
  " * h1
  " ** h2
  " *** h3
  " ** h2.2
  "                                 <-------- this empty line is removed
  "                                 <-------- this empty line is removed
  " ** h2.3
  "
  " if not:
  " * h1
  "                                 <-------- this empty line is removed
  " ** h2
  " something
  "                                 <-------- this empty line is added
  " ** any other header
  "
  " no other formatting
  if exists('a:2')
    let [lnum, end] = [a:1, a:2]
  elseif exists('a:1')
    let [lnum, end] = [a:1, a:1]
  else
    let [lnum, end] = [v:lnum, v:lnum + v:count]
  endif
  let lnum = org#headline#find(lnum, 0, 'nbW')
  while lnum <= end && lnum > 0
    call org#headline#format(lnum)
    " FIXME This won't work for ranges properly, modifying text as we go
    let lnum = org#headline#find(lnum, 0, 'nxW')
  endwhile

  " Format lists
  return
endfunction

function! org#late() abort " {{{1
  let agenda = filter(org#agenda#list(), {k, hl -> org#plan#islate(hl)})
  call sort(agenda, org#util#seqsortfunc(['file', 'lnum']))
  call map(agenda, {ix, hl -> org#agenda#toqf(ix, hl)})
  call setqflist(agenda)
  copen
endfunction

function! org#parsedate() abort " {{{1
  let text = matchstr(getline(line('.'))[: col('.') - 1], '\v(\[.{-}]|\<.{-}\>).?$')
  " if
  " Necessary for imap expression usage
  return ''
endfunction

function! org#plan(expr) abort " {{{1
  let current = org#plan#get(a:lnum)
  redraw
  let prompt = "Planning:\n"
  let prompt .= getline(org#headline#at(a:lnum)) . "\n"
  let ts = getline(org#plan#at(a:lnum)) . "\n"
  let prompt .= org#plan#checkline(a:lnum) ? ts  . "\n": ''
  let prompt .= '> '
  let time = input(prompt, '')
  " let time = input(prompt, '', 'customlist,org#time#completion')
  let [plantype; datetime] = split(time)
  " let timestamp = org#time#from_text(join(datetime), current)
  let timestamp = org#time#dict(join(datetime))
  let timestamp.active = plantype != 'CLOSED'
  call org#plan#set(a:lnum, timestamp)
endfunction

function! org#refile(destination) abort " {{{1
  " Does not distinguish between two identical headlines.
  " TODO? define behavior for a/b/c? or require.org ?

  " TODO remove this
  let src = exists('a:1') ? a:destination : '.'
  let dest = exists('a:1') ? a:1 : a:destination

  if line(src) > 0
    let src = org#headline#get(org#headline#at(line(src)))
  elseif type(src) == v:t_string
    let src = org#headline#fromtarget(src)
  endif

  if type(dest) == v:t_string
    let dest = org#headline#fromtarget(dest)
  elseif type(dest) == v:t_string
    let dest = org#headline#get(dest)
  endif
  let [g:org#refile#source, g:org#refile#destination] = [src, dest]
  doautocmd User OrgRefilePre

  " Find range of source and remove text we're filing
  let destination = g:org#refile#destination
  let [st, end] = org#section#range(g:org#refile#source.lnum)
  let refile_level = org#headline#level(st)
  let text = getline(st, end)
  execute st . ',' . end . 'd _'

  " Find destination line number and add lines
  if resolve(fnamemodify(destination.filename, ':p')) != resolve(expand('%:p'))
    " TODO use tag? so it will use switchbuf?
    execute 'edit' destination.filename
  endif
  let lnum = org#section#range(destination.lnum)[1]
  call append(lnum, text)

  " shift headlines to make sense
  if !has_key(destination, 'level')  " just a file
    let destination.level = 0
  endif
  let shift = destination.level == refile_level ? 1 : destination.level + 1 - refile_level
  let range = lnum + 1 . ',' . (lnum + 1 + end - st)
  execute range . 'call org#shift(' . shift . ', "n")'

  let g:org#refile#last = org#headline#get(lnum + 1)

  doautocmd User OrgRefilePost
  unlet! g:org#refile#last
  unlet! g:org#refile#source
  unlet! g:org#refile#destination
endfunction

function! org#shift(count, mode) range abort " {{{1
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
      if a:count > 0
        call org#headline#promote(a:count)
      else
        call org#headline#demote(a:count)
      endif
      let lnum = org#headline#find(lnum, 0, 'nxW')
    endwhile
    if a:mode == 'i'
      call feedkeys(a:count > 0 ? "\<C-g>U\<Right>" : "\<C-g>U\<Left>", 'n')
    endif
    return
  elseif org#list#checkline(a:firstline) " {{{2
    " TODO reorder and bullet cycling
    let lnum = org#listitem#start(a:firstline)
    let items = []
    let range = [0, 0]
    while lnum >= a:firstline && lnum <= a:lastline || empty(items)
      if range[1] < lnum
        call add(items, lnum)
        let range = org#listitem#range(lnum)
      endif
      let lnum = org#list#find(lnum, 'nxW')
    endwhile

    for lnum in items
      " TODO format me after indenting
      " FIXME if a list with sub items is visually selected, the sublists are moved twice
      call cursor(lnum, 1)
      call org#listitem#indent(a:count)
      " if org#listitem#get_bullet(lnum) == org#listitem#get_bullet(org#listitem#parent_range(lnum)[0])
      "   if org#listitem#is_unordered(lnum)
      "     call org#listitem#bullet_cycle(lnum, 1)  " a:count)
      "   endif
      "   if org#listitem#is_ordered(lnum)
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
