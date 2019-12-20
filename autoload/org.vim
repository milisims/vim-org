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
    while lnum >= a:firstline && lnum <= a:lastline || empty(items)
      call add(items, lnum)
      let lnum = org#list#find(lnum, 2, 'nxW')
    endwhile

    for lnum in items
      call cursor(lnum, 1)
      call org#list#item_indent(a:direction)
      if org#list#get_bullet(lnum) == org#list#get_bullet(org#list#parent_item_range(lnum)[0])
        if org#list#item_is_unordered(lnum)
          call org#list#bullet_cycle(lnum, 1)  " a:direction)
        endif
        if org#list#item_is_ordered(lnum)
          call org#list#reorder()
        endif
      endif
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

function! org#refile(item) abort
endfunction

function! org#daily() abort
  let agenda = org#agenda#daily(3)
  let now = org#timestamp#parse('today')
  let TimeMod = {hl -> {'module': org#timestamp#ftime2date(org#timestamp#getnearest(now, hl)[1])}}
  call map(agenda, {ix, hl -> org#agenda#toqf(ix, hl, TimeMod(hl))})
  call setqflist(agenda)
  copen
endfunction

function! org#process_inbox() abort " {{{1
  let agenda = org#agenda#view()
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

function! s:getprompt(headline) abort " {{{2
  let prompt = "Item: "
  let prompt .= a:headline.TODO . a:headline.ITEM . "\n"
  let prompt .= "Options:\n"
  let prompt .= "r: Refile to file [additional args for under subheadings]\n"
  let prompt .= "t: Refile item then add timestamp\n"
  let prompt .= "s: Skip item\n"
  let prompt .= "d: Delete item\n"
  let prompt .= "> "
  return prompt
endfunction
