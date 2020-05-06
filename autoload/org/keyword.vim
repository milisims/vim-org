function! org#keyword#checktext(text, ...) abort " {{{1
  let keywords = exists('a:1') ? a:1 : org#outline#keywords()
  return a:text =~# '^\*\+\s\+\(' . join(keywords, '\|') . '\)'
endfunction

function! org#keyword#cycle(count, ...) abort " {{{1
  let line = getline('.')
  if !org#headline#checktext(line)
    return
  endif
  let keywords = exists('a:1') ? a:1 : org#outline#keywords()
  let current = org#keyword#parse(line, keywords)
  let keywords = [''] + keywords
  let next = keywords[(index(keywords, current) + a:count) % len(keywords)]

  if empty(current)
    let new_line = substitute(line, '\v^\*+\s+', '&' . next . ' ', '')
  elseif empty(next)
    let new_line = substitute(line, '\v^(\*+\s+)' . current . '\s?', '\1', '')
  else
    let new_line = substitute(line, '\v^(\*+\s+)' . current, '\1' . next, '')
  endif
  call setline('.', new_line)
endfunction

function! org#keyword#parse(text, ...) abort " {{{1
  let keywords = exists('a:1') ? a:1 : org#outline#keywords()
  return matchstr(a:text, '^\*\+\s\+\zs\(' . join(keywords, '\|') . '\)')
endfunction
