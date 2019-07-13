function! org#section#headline(lnum) abort
  return org#headline#find(a:lnum, 0, 'bW')
endfunction

function! org#section#range(lnum, ...) abort
  " first return value (start) is zero if failed to find headline.
  " end is undefined in that case.
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:headline_included = get(a:, '1', 0)
  let l:start = org#headline#find(l:lnum, 0, 'bW')
  let l:end = org#headline#find(l:lnum + 1, org#headline#level(l:lnum), 'W')
  let l:end = l:end > 0 ? l:end - 1 : l:start
  " let l:end = l:end < l:start ? line('$') : l:end
  if ! l:headline_included
    if l:start == l:end && org#headline#checkline(l:start)
      " Empty headline section, nothing to select
      return [0, 0]
    endif
    let l:start += 1
    let l:end = prevnonblank(l:end)
  endif
  return [l:start, l:end]
endfunction

