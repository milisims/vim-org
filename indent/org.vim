" Delete the next line to avoid the special indention of items
" if !exists('g:org_indent')
"   let g:org_indent = 0
" endif

" " Only define the function once.
" if exists('*GetOrgIndent')
"   finish
" endif

function! GetOrgIndent() abort " {{{1
  " TODO check for a language, call the language's indentation
  " TODO remove following line. use v:lnum. debug line
  " let l:lnum = line('.')
  let l:lnum = v:lnum
  let l:line = getline(l:lnum)
  let l:prev_line = getline(l:lnum - 1)
  if l:line =~# '^\*\|^\s*#'  " if headline or #
    return 0
  elseif org#list#checkline(l:lnum)
    let l:indent = max([org#list#level(l:lnum), 1]) * &shiftwidth
    return org#list#has_header(l:line) ? l:indent : l:indent + 2
  elseif org#list#checkline(l:lnum - 1)
    return (org#list#level(l:lnum - 1) + 1) * &shiftwidth
  elseif l:prev_line =~# '^\*\+'
    return 0
  elseif l:prev_line =~# '^$'
    return indent(l:lnum)
  endif
  return indent(l:lnum - 1)
endfunction
