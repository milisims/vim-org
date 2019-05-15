" Delete the next line to avoid the special indention of items
" if !exists('g:org_indent')
"   let g:org_indent = 0
" endif

" " Only define the function once.
" if exists('*GetOrgIndent')
"   finish
" endif

function! GetOrgIndent() abort
  " TODO check for a language, call the language's indentation
  " TODO remove following line. use v:lnum. debug line
  " let l:lnum = line('.')
  let l:lnum = v:lnum
  let l:line = getline(l:lnum)
  let l:prev_line = getline(l:lnum - 1)
  messages clear
  if l:line =~# '^\*\|^\s*#'  " if headline or #
    echom 'is.hl'
    return 0
  elseif org#is_listitem(l:lnum)
    echom 'is.li' org#has_list_header(l:line)
    let l:indent = max([org#get_list_level(l:lnum), 1]) * &shiftwidth
    return org#has_list_header(l:line) ? l:indent : l:indent + 2
  elseif org#is_listitem(l:lnum - 1)
    echom 'is.pl' . v:char
    return (org#get_list_level(l:lnum - 1) + 1) * &shiftwidth
  elseif l:prev_line =~# '^\*\+'
    echom 'is.ph'
    return 0
  elseif l:prev_line =~# '^$'
    echom 'is.pe -' . l:prev_line . '-'
    return indent(l:lnum)
  endif
  echom 'is.else'
  return indent(l:lnum - 1)
endfunction
