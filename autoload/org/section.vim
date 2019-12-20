function! org#section#headline(lnum) abort " {{{1
  return org#headline#find(a:lnum, 0, 'nbW')
endfunction

function! org#section#range(lnum, ...) abort " {{{1
  " first return value (start) is zero if failed to find headline.
  " end is undefined in that case.
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let inner = get(a:, 1, 0)
  let start = org#headline#at(lnum)
  let end = org#headline#find(lnum, org#headline#level(start), 'nxW')
  let end = end > 0 ? end - 1 : line('$')
  if inner
    if start == end && org#headline#checkline(start)
      return [0, 0]  " Empty headline section, nothing to select
    endif
    return [start + 1, prevnonblank(end)]
  endif
  return [start == 0 ? 1 : start, end]
endfunction

function! org#section#textobject(count, inner, mode) abort " {{{1
  let [start, end] = org#section#range('.', a:inner)
  if start == 0 || line('.') < start || line('.') > end
    if a:mode == 'v'
      normal! gv
    endif
    return
  endif
  echo line("'>") end
  if a:mode == 'v'
    let start = line("'<") < start ? line("'<") : start
    let end = line("'>") > end ? line("'>") : end
  endif
  execute 'normal! ' . start . 'GV' . end . 'G0'
endfunction
