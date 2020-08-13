function! org#listitem#append(lnum, text, ...) abort " {{{1
  " Default will not reorder list, but will add a checkbox if the previous item has one
  let reorder = get(a:, 1, 0)
  let checkbox = get(a:, 2, -1)
  if org#listitem#checkline(a:lnum)
    let [start, end] = org#listitem#range(a:lnum)
    let [whitespace, bullet] = matchlist(getline(start), '\v^(\s*)' . g:org#regex#list#bullet)[1:2]
    if checkbox < 0
      let checkbox = org#checklist#hasbox(getline(start))
    endif
    if bullet =~# '\v\d+|\a'
      let bullet = (bullet =~# '\a' ? nr2char(char2nr(bullet) + 1) : str2nr(bullet) + 1) . bullet[-1:]
    endif
  else
    " TODO getme from options
    let [end, whitespace, bullet] = [a:lnum, '  ', '-']
    if checkbox < 0
      let checkbox = 0
    endif
    let reorder = 0
  endif
  if type(a:text) == v:t_list  " list
    let bws = whitespace . '  '
    let bullet = bullet . (checkbox ? ' [ ] ' : ' ')
    let text = [whitespace . bullet . a:text[0]] + map(a:text[1:], 'bws . v:val')
  else  " assume string
    let bullet = bullet . (checkbox ? ' [ ] ' : ' ')
    let text = whitespace . bullet . a:text
  endif
  call append(end, text)
  if reorder
    execute a:lnum . 'call org#list#reorder()'
  endif
endfunction

function! org#listitem#bullet_cycle(lnum, direction) abort " {{{1
  " TODO get global/buffer var
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let bullets = get(g:, 'org#list#bullet_order', ['-', '+', '*'])
  let bullet = org#listitem#get_bullet(lnum)
  let index = index(bullets, bullet)
  if index >= 0
    let next = bullets[(index + a:direction) % len(bullets)]
    call setline(lnum, substitute(getline(lnum), bullet, next, ''))
  endif
endfunction

function! org#listitem#checkline(lnum) abort " {{{1
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  return org#listitem#is_unordered(lnum) || org#listitem#is_ordered(lnum)
endfunction

function! org#listitem#end(lnum) abort " {{{1
  return org#listitem#range(a:lnum)[1]
endfunction

function! org#listitem#find(lnum, ...) abort " {{{1
  " This should find *starts* of lists.
  " Also, flag for same level or lower, like hl#find
  let same = get(a:, 1, '') " in_list
  let flags = get(a:, 2, '')
  if !same
    return org#util#search(a:lnum, '\v^\s*' . g:org#regex#list#bullet, flags)
  endif
  let range = org#list#range(a:lnum)
  return org#util#search(a:lnum, org#listitem#regex(a:lnum), flags, range[flags =~# 'b' ? 0 : 1])
  " let lnum = org#util#search(a:lnum, org#listitem#regex(getline(a:lnum)), flags)
  " return (lnum >= range[0] && lnum <= range[1]) ? lnum : 0
endfunction

function! org#listitem#get_bullet(lnum) abort " {{{1
  return matchstr(getline(a:lnum), '\v^\s*(\zs[-+]|\zs(\d+|\a)[.)]|\s\zs\*)')
endfunction

function! org#listitem#has_bullet(text) abort " {{{1
  return a:text =~# '\v^\s*' . g:org#regex#list#bullet
endfunction

function! org#listitem#has_ordered_bullet(text) abort " {{{1
  return a:text =~# '\v^\s*' . g:org#regex#list#bullet#ordered
endfunction

function! org#listitem#has_unordered_bullet(text) abort " {{{1
  return a:text =~# '\v^\s*' . g:org#regex#list#bullet#unordered
endfunction

function! org#listitem#indent(direction) abort range " {{{1
  let count = abs(a:direction)
  if a:firstline == a:lastline
    call s:doindent(a:firstline, a:direction, count)
    return
  endif

  let lnum = org#listitem#start(a:firstline)
  let lnum = (lnum ? lnum : a:firstline) - 1
  while lnum > 0 && lnum < a:lastline
    let lnum = org#util#search(lnum, '\v^\s*' . g:org#regex#list#bullet, 'xnW')
    let lnum = s:doindent(lnum, a:direction, count)
  endwhile
endfunction

function! org#listitem#is_ordered(lnum) abort " {{{1
  let lstart = org#listitem#start(a:lnum)
  return lstart < 0 ? 0 : org#listitem#has_ordered_bullet(getline(lstart))
endfunction

function! org#listitem#is_unordered(lnum) abort " {{{1
  let lstart = org#listitem#start(a:lnum)
  return lstart < 0 ? 0 : org#listitem#has_unordered_bullet(getline(lstart))
endfunction

function! org#listitem#level(lnum) abort " {{{1
  let lnum = org#listitem#start(a:lnum)
  let level = 0
  while lnum > 0
    let level += 1
    let lnum = org#listitem#parent(lnum)
  endwhile
  return level
endfunction

function! org#listitem#parent(lnum, ...) abort " {{{1
  let toplevel = get(a:, 1, 0)
  let itemstart = org#listitem#start(a:lnum)
  if itemstart == 0
    return 0
    " return toplevel ? a:lnum : 0
  endif

  let [ws, bl] = [matchstr(getline(itemstart), '^\s*'), g:org#regex#list#bullet]
  let search = org#util#search(itemstart, '\v^%(' . ws . '\s*' . bl . ')@!\s*' . bl, 'nbW')

  let [parent_start, parent_end] = org#listitem#range(search)
  if (parent_start == 0 || itemstart > parent_end)
    return 0
  endif
  if toplevel
    let parent = org#listitem#parent(parent_start, 1)
    return parent ? parent : parent_start
  endif
  return parent_start
endfunction

function! org#listitem#range(lnum) abort " {{{1
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let start = org#util#search(lnum, g:org#regex#listitem, 'bnW')
  if start == 0
    return [0, 0]
  endif
  let regex = '\v^(' . matchstr(getline(start), '^\s*') . '\s+)@!(^$)@!|\n\s*\n\s*\n'
  let end = org#util#search(start, regex, 'nxW') - 1
  if end < 0
    let end = prevnonblank(line('$'))
  elseif getline(end) =~ '^\s*$' && getline(end - 1) =~ '^\s*$'
    let end = prevnonblank(end)
  elseif getline(end) =~ '^\s*$' && getline(end + 1) !~ org#listitem#regex(start)
    let end = prevnonblank(end)
  endif
  return start <= lnum && lnum <= end ? [start, end] : [0, 0]
endfunction


function! org#listitem#regex(lnum, ...) abort " {{{1
  let verymagic = get(a:, 1, 1)
  let [whitespace, bullet] = matchlist(getline(a:lnum), '\v^(\s*)' . g:org#regex#list#bullet)[1:2]
  let opts = ['-', '\*', '+', '\d\+)', '\d\+\.', '\a)', '\a\.']
  if verymagic
    let opts[2:5] = ['\+', '\d+\)', '\d+\.', '\a\)']
  endif
  let bl = 'bullet =~# ' . (verymagic ? '''\v''.' : '') . 'v:val'
  let blre = filter(opts, bl)[0]
  let [o, c] = verymagic ? ['(', ')'] : ['\(', '\)']
  return (verymagic ? '\v^' : '^') . o . whitespace . blre . c
endfunction
function! org#listitem#start(lnum) abort " {{{1
  return org#listitem#range(a:lnum)[0]
endfunction

function! org#listitem#text(lnum) abort " {{{1
  let rn = org#listitem#range(a:lnum)
  if rn[0] == 0
    return ''
  endif
" whitespace, bullet, counter-set, checkbox, tagtext, itemtext
  let [ws, _, _, _, _, text] = matchlist(getline(rn[0]), g:org#regex#listitem)[1:6]
  if rn[0] == rn[1]
    return text
  endif
  let ws .= '  ' " FIXME use indent from settings
  return [text] + map(getline(rn[0]+1, rn[1]), 'matchstr(v:val, ''^''.ws.''\zs.*'')')
endfunction

function! s:doindent(lnum, direction, count) abort " {{{2
  " Specifically for org#listitem#indent. Does indent, returns last line
  let range = org#listitem#range(a:lnum)
  for i in range(a:count)
    if range[0] > 0 && ! (a:direction < 0 && indent(range[0]) == 0)
      execute 'silent!' join(range, ',') . (a:direction > 0 ? '>' : '<')
    endif
  endfor
  return range[1]
endfunction

function! s:listitem_end_regex(lnum) abort " {{{1
  " lnum assumed to be the list item start
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let whitespace = matchstr(getline(lnum), '^\s*')
  let endmatch = '\n^$\n^$'
  let endmatch .= '\|\n' . whitespace . '\S'
  if !empty(whitespace)
    let endmatch .= '\|\n\(' . whitespace . '\)\@!'
  endif
  return endmatch
endfunction

function! s:listitem_start_regex(text, ...) abort " {{{1
  " Construct a regex for searching upward to find the start of the item at lnum
  let whitespace = matchstr(a:text, '^\s*')
  let regex = ''
  if !org#listitem#has_bullet(a:text)
    if !empty(whitespace)
      let regex .= '^\(' . whitespace . '\)\@!'
    else
      return ''
    endif
  endif
  let type = get(a:, 1, 'any')
  if type ==? '^u'
    let regex .= '\v(\s*[-+]|\s+\*)'
  elseif type ==? '^o'
    let regex .= '\v(\s*(\d+|\a)[.)])'
  else
    let regex .= '\v(\s*([-+]|(\d+|\a)[.)])|\s+\*)'
  endif
  return regex
endfunction
