function! org#util#search(lnum, pattern, flags, ...) abort " {{{1
  " search({pattern} [, {flags} [, {stopline} [, {timeout}]]])
  " If starting search from end of line/end column, curpos at end of file
  " TODO be explicit about exclusive vs inclusive lnum
  let cursor = getcurpos()[1:]
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let flags = a:flags
  if flags =~# 'x'
    let flags = substitute(flags, 'x', '', 'g')
    let lnum += (flags =~# 'b' ? -1 : 1)
  endif
  if lnum >= line('$')
    call cursor(line('$'), col([line('$'), '$']))
    let flags = flags . (flags =~# 'b' ? '' : 'c')
  elseif lnum >= 0
    call cursor(lnum + (flags =~# 'b' ? 1 : 0), 1)
    let flags = flags . (flags =~# 'b' ? 'z' : 'c')
  endif
  let search = call(function('search'), extend([a:pattern, flags], a:000))
  if stridx(flags, 'n') >= 0 || search == 0
    call cursor(cursor)
  endif
  return search
endfunction

function! org#util#formatexpr() abort " {{{1
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
  return
endfunction

function! org#util#get(name, default, ...) abort " {{{1
  " Not sure this will work out
  let append = get(a:, 1, 0)
  let b = get(b:, name, a:default)
  let g = get(g:, name, a:default)
  if b == g || b == a:default
    return g
  endif
  if append && type(g) == 3
     call extend(g, b)
     return g
  elseif append && type(g) == 4
    return extend(g, b)
  endif

endfunction

function! org#util#decompose(expr, pats, ...) abort " {{{1
  let strip = get(a:, 1, 0)
  let res = []
  let expr = a:expr
  for p in a:pats
    let match = matchstrpos(expr, p)
    if strip
      let match[0] = substitute(match[0], '\s*\(.*\)\s*', '\1', '')
    endif
    call add(res, match[0])
    if match[1] >= 0
      let expr = expr[match[2]:]
    endif
  endfor
  return strip ? map(): res
endfunction

function! org#util#group(text, pattern) abort " {{{1
  " Only works with very magic
  if a:pattern !~# '\v'
    throw 'Very magic only'
  endif
  let groups = []
  let count = 0
  let braces = 0
  for c in split(pattern, '\zs')
    if c == '(' || c == ')' && !escaped
      let count += c == '(' ? 1 : -1
      if count == 0
      endif
    endif
  endfor
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
