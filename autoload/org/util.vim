
function! org#util#search(lnum, pattern, flags, ...) abort
  " search({pattern} [, {flags} [, {stopline} [, {timeout}]]])
  " If starting search from end of line/end column, curpos at end of file
  "
  let l:cursor = getcurpos()[1:]
  if a:lnum >= line('$')
    call cursor(line('$'), col([line('$'), '$']))
    let l:flags = a:flags . (a:flags =~# 'b' ? '' : 'c')
  elseif a:lnum >= 0
    call cursor(a:lnum + (a:flags =~# 'b' ? 1 : 0), 1)
    let l:flags = a:flags . (a:flags =~# 'b' ? 'z' : 'c')
  endif
  let l:search = call(function('search'), extend([a:pattern, l:flags], a:000))
  if stridx(a:flags, 'n') >= 0
    call cursor(l:cursor)
  endif
  return l:search
endfunction

