" " Only define the function once.
" if exists('*GetOrgIndent')
"   finish
" endif

function! GetOrgIndent(...) abort " {{{1
  let lnum = get(a:, 1, v:lnum)
  let prefix = get(g:, 'org#indent#to_hllevel', 0) ? org#headline#level(lnum) : 0
  if getline(lnum) =~# '^\*\|^\s*#'  " if headline or #
    return 0
  elseif org#list#checkline(lnum)
    if org#list#level(lnum) == 1 && org#listitem#has_bullet(getline(lnum))
      return &shiftwidth
    endif
    let baselnum = org#listitem#{org#listitem#has_bullet(getline(lnum)) ? 'parent' : 'start'}(lnum)
    return matchend(getline(baselnum), '\v\s*' . g:org#regex#list#bullet . ' ')
  elseif org#list#checkline(line(lnum) - 1)
    return (org#list#level(line(lnum) - 1) + 1) * &shiftwidth
  elseif getline(line(lnum) - 1) =~# '^\*\+'
    return 0
  elseif getline(line(lnum) - 1) =~# '^$'
    return indent(lnum)
  endif
  return indent(line(lnum) - 1)
endfunction
