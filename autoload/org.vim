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
  return fnamemodify(get(b:, 'org_dir', get(g:, 'org#dir', '~/org')), ':p')
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

function! org#plan(planstr) abort " {{{1
  let [kind; plan] = split(a:planstr)
  if kind =~? 's\%[cheduled]'
    let kind = 'SCHEDULED'
  elseif kind =~? 'd\%[eadline]'
    let kind = 'DEADLINE'
  elseif kind =~? 'c\%[losed]'
    let kind = 'CLOSED'
  elseif kind =~? 't\%[imestamp]'
    let kind = 'TIMESTAMP'
  else
    let plan = [kind] + plan
    let kind = 'TIMESTAMP'
  endif
  let plan = join(plan)
  call org#plan#set({kind : plan})
endfunction

function! org#refile(destination) abort " {{{1
  " Does not distinguish between two identical headlines.
  " TODO? define behavior for a/b/c? or require.org ?

  let [src, dest] = ['.', a:destination]
  let src = org#headline#get(org#headline#at(line('.')))
  let dest = org#headline#fromtarget(a:destination)

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
  let curlen = col('$')
  if org#headline#checkline(a:firstline) " {{{2
    while lnum >= a:firstline && lnum <= a:lastline
      call cursor(lnum, 0)
      call org#headline#{a:count > 0 ? 'promote' : 'demote'}(a:count)
      let lnum = org#headline#find(lnum, 0, 'nxW')
    endwhile
  elseif org#list#checkline(a:firstline) " {{{2
    let lnum = org#listitem#start(a:firstline)
    let items = []
    " empty check is to make sure indenting from a multi-line item
    while empty(items) || (lnum > 0 && lnum >= a:firstline && lnum <= a:lastline)
      call add(items, lnum)
      let lnum = org#listitem#find(org#listitem#range(lnum)[1], 0, 'nxW')
    endwhile

    " Indent
    for lnum in items
      call cursor(lnum, 1)
      call org#listitem#indent(a:count)
    endfor

    " " FIXME reorder / cycle where necessary check bullet regex or something
    " for lnum in items
    "   if org#listitem#get_bullet(lnum) == org#listitem#get_bullet(org#listitem#parent_range(lnum)[0])
    "     if org#listitem#is_unordered(lnum)
    "       call org#listitem#bullet_cycle(lnum, 1)  " a:count)
    "     endif
    "     if org#listitem#is_ordered(lnum)
    "       call org#list#reorder()
    "     endif
    "   endif
    " endif

  else " plain text for now {{{2
    " FIXME: fails in insert mode
    execute a:firstline.','.a:lastline . (a:count > 0 ? '>' : '<')
  endif " }}}

  if a:mode == 'i'
    let cursor[1] += col('$') - curlen
  endif
  call cursor(cursor)
endfunction
