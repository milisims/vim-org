function! org#list#checkline(lnum) abort " {{{1
  return org#listitem#checkline(a:lnum)
endfunction

function! org#list#find(lnum, ...) abort " {{{1
  " This should find *starts* of lists.
  " 'x' should be "find next list that this line is not a part of at all"
  " TODO flags
  let flags = get(a:, 1, '')
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let range = org#list#range(lnum)

  if !org#list#checkline(lnum) " No list, find first one we see.
    return org#listitem#find(lnum, 0, flags)
  elseif flags =~# 'x'  " Find first list that doesn't have any shared parents with lnum
    let flags = substitute(flags, 'x', '', 'g')
    let lnum = org#listitem#parent(lnum, 1)
    let [_, lnum] = org#list#range(lnum)
    return org#listitem#find(lnum, 0, flags)
  endif

  if flags =~# 'n'
    let curpos = getcurpos()[1:]
  else
    let flags = flags . 'n'
  endif
  " Find next list start.
  let lnum = org#listitem#start(lnum)
  " TODO use search() over org#util#search in loops.
  let lnum = org#util#search(lnum, org#listitem#regex(lnum) . '@!', 'x' . flags)
  let lnum = org#util#search(lnum, g:org#regex#listitem, flags)
  while lnum > 0 && lnum != org#list#range(lnum)[0]
    let lnum = org#listitem#start(lnum)
    let lnum = org#util#search(lnum, org#listitem#regex(lnum) . '@!', 'x' . flags)
    let lnum = org#util#search(lnum, g:org#regex#listitem, flags)
  endwhile
  if exists('curpos')
    call cursor(curpos)
  endif
  return lnum
endfunction

function! org#list#is_ordered(lnum) abort " {{{1
  return org#listitem#is_ordered(a:lnum)
endfunction

function! org#list#is_unordered(lnum) abort " {{{1
  return org#listitem#is_unordered(a:lnum)
endfunction

function! org#list#level(lnum) abort " {{{1
  return org#listitem#level(a:lnum)
endfunction

function! org#list#linesperitem(lnum) abort " {{{1
  let [lnum, lower_bound] = org#list#range(a:lnum)
  let regex = '^' . join(s:list_bullet_regex(getline(lnum)), '')
  let items = []
  while lnum > 0
    call add(items, org#listitem#range(lnum))
    let lnum = org#util#search(lnum + 1, regex, 'nW', lower_bound)
  endwhile
  return items
endfunction

function! org#list#range(lnum) abort " {{{1
  " FIXME: no idea what this is doing.
  " let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let item_start = org#listitem#start(a:lnum)
  if item_start == 0
    return [0, 0]
  endif

  let [whitespace, bullet_regex] = s:list_bullet_regex(getline(item_start))
  " 3 'ends' : double space, less indentation (don't match empty single lines),
  " == indent with differnt list marker
  let pattern = '^$\n^$'
  let pattern .= empty(whitespace) ? '' : '\|^\(' . whitespace . '\|$\)\@!'
  let pattern .= '\|^' . whitespace . '\(\s\+\|' . bullet_regex . '\)\@!'
  let upper_bound = org#util#search(item_start, pattern, 'bnW')
  let lower_bound = org#util#search(item_start, pattern, 'nW')
  let upper_bound = upper_bound > 0 ? upper_bound : 1
  let lower_bound = lower_bound > 0 ? lower_bound : line('$')
  let start = org#util#search(upper_bound, '^' . whitespace . bullet_regex, 'nW')
  let end = org#util#search(lower_bound, '^' . whitespace . bullet_regex, 'bnW')
  let end = org#listitem#end(end)
  return [start, end]
endfunction

function! org#list#reorder() abort range " {{{1
  if a:firstline == a:lastline
    let [lnum, lower_bound] = org#list#range(a:firstline)
  else
    let lnum = org#listitem#start(a:firstline)
    let lower_bound = a:lastline
  endif
  let [ws, bl, cs, _, _, _] = matchlist(getline(lnum), g:org#regex#listitem)[1:6]
  let regex = org#listitem#regex(lnum)
  " If alpha bullets, check for upper/lowercase
  if empty(cs)
    let char = bl[0] =~# '\a'
    let count = char ? (getline(lnum) =~# '\s*\l' ? 97 : 65) : 1
  else
    let char = cs =~# '\a'
    let count = char ? char2nr(cs) : str2nr(cs)
  endif
  let dot = bl[-1:]
  while lnum > 0
    let text = ws . (char ? nr2char(count) : count) . dot
    call setline(lnum, substitute(getline(lnum), regex, text, ''))
    let count += 1
    let lnum = org#util#search(lnum + 1, regex, 'nW', lower_bound)
  endwhile
endfunction

function! s:list_bullet_regex(text) abort " {{{1
  " TODO should this use very magic expressions?
  let bullet = split(a:text)[0]
  let whitespace = matchstr(a:text, '^\s*')
  if bullet =~# '\d\+)'
    return [whitespace, '\d\+)']
  elseif bullet =~# '\d\+\.'
    return [whitespace, '\d\+\.']
  elseif bullet =~# '\a)'
    return [whitespace, '\a)']
  elseif bullet =~# '\a\.'
    return [whitespace, '\a\.']
  elseif bullet =~# '\*'
    return [whitespace, '\*']
  endif
  return [whitespace, bullet]
endfunction
