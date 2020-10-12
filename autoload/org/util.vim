function! org#util#search(lnum, pattern, flags, ...) abort " {{{1
  " org#util#search is a wrapper for search() which allows a lnum to search for, and adds the 'x'
  " flag: exclusive search from the start line.
  let cursor = getcurpos()[1:]
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let flags = a:flags
  " this really needs to be cleaned up.
  if lnum == line('$') && flags =~# 'x' && flags =~# 'W' && flags !~# 'b'
    return 0
  endif
  if flags =~# 'x'
    let flags = substitute(flags, 'x', '', 'g')
    let lnum += (flags =~# 'b' ? -1 : 1)
  endif
  if lnum >= line('$')
    call cursor(line('$'), flags =~# 'b' ? col([line('$'), '$']) : 1)
    let flags = flags . (flags =~# 'b' ? '' : 'c')
  elseif lnum >= 0
    call cursor(lnum + (flags =~# 'b' ? 1 : 0), 1)
    let flags = flags . (flags =~# 'b' ? 'z' : 'c')
  endif
  " search({pattern} [, {flags} [, {stopline} [, {timeout}]]])
  let search = call(function('search'), extend([a:pattern, flags], a:000))
  if stridx(flags, 'n') >= 0 || search == 0
    call cursor(cursor)
  endif
  return search
endfunction

function! org#util#seqsortfunc(properties, ...) abort " {{{1
  " Creates a comparison function that sequentially compares the items provided
  " assumes the comparison is a list
  let direction = get(a:, 1, '')
  function! s:seqsortf(i1, i2) closure
    for property in a:properties
      if a:i1[property] != a:i2[property]
        return a:i1[property] > a:i2[property] ? 1 : -1
      endif
    endfor
    return 0
  endfunction
  return funcref('s:seqsortf')
endfunction

function! org#util#complete(arglead, cmdline, curpos) abort " {{{1
  " See :h :command-completion-customlist
  " To be used with customlist, not custom. Works with spaces better, and regex are nice.
  " autocmd unlets with CmdLineLeave
  if exists('g:org#complete#repeat') " FIXME fix for vim bug
    let pt = split(a:arglead, ' ', 1)[-1]
  else
    let pt = a:arglead
  endif
  return filter(copy(g:org#complete#list), 'v:val =~ pt')
endfunction

function! org#util#fname(expr) abort " {{{1
  " if bufname exists, return it. Otherwise check for relative file, then 
  if !empty(bufname(a:expr))
    return bufname(a:expr)
  elseif filereadable(a:expr) || a:expr[0] =~ '[/~]'
    let bn = a:expr
  else
    let bn = bufadd(org#dir() . '/' . a:expr)
  endif
  return resolve(fnamemodify(bn, ':p'))
  " let bn = resolve(fnamemodify(bn, ':p'))
  " return bufname(bn)
endfunction
