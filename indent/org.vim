" " Only define the function once.
" if exists('*GetOrgIndent')
"   finish
" endif

function! GetOrgIndent(...) abort " {{{1
  let lnum = exists('a:1') ? a:1 : v:lnum
  let prefix = get(g:, 'org#indent#to_hllevel', 0) ? org#headline#level(lnum) : 0
  if getline(lnum) =~# '^\*\|^\s*#'  " if headline or #
    return 0
  elseif org#list#checkline(lnum)
    let indent = max([org#list#level(lnum), 1]) * &shiftwidth
    return org#list#has_header(getline(lnum)) ? indent : indent + 2
  elseif org#list#checkline(lnum - 1)
    return (org#list#level(lnum - 1) + 1) * &shiftwidth
  elseif getline(lnum - 1) =~# '^\*\+'
    return 0
  elseif prev_line =~# '^$'
    return indent(lnum)
  endif
  return indent(lnum - 1)
endfunction
