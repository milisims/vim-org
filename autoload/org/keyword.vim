function! org#keyword#checktext(text, ...) abort " {{{1
  let keywords = exists('a:1') ? a:1 : org#outline#keywords()
  return a:text =~# '^\*\+\s\+\(' . join(keywords, '\|') . '\)'
endfunction

function! org#keyword#cycle(count, ...) abort " {{{1
  let line = getline('.')
  if !org#headline#checktext(line)
    return
  endif
  " TODO cycle through keyword groups
  let keywords = exists('a:1') ? a:1 : org#outline#keywords()
  let current = org#keyword#parse(line, keywords)
  let keywords = [''] + keywords.all
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
  return matchstr(a:text, '^\*\+\s\+\zs\(' . join(keywords.all, '\|') . '\)')
endfunction

function! org#keyword#remove() abort " {{{1
  let lnum = org#headline#at('.')
  let current_kwd = org#keyword#parse(getline(lnum))
  if !empty(current_kwd)
    call setline(lnum, join(split(getline(lnum), ' ' . current_kwd), ''))
  endif
endfunction

function! org#keyword#set(kwd) abort " {{{1
  " let keywords = exists('a:1') ? a:1 : org#outline#keywords()
  " if index(keywords, kwd) < 0
  "   throw 'Org: ' . a:kwd . ' not in keywords: ' string(keywords)
  " endif
  let lnum = org#headline#at('.')
  let current_kwd = org#keyword#parse(getline(lnum))
  if !empty(current_kwd)
    let [stars, text] = split(getline(lnum), current_kwd)
  else
    let [stars; text] = split(getline(lnum), ' ', 1)
    let stars .= ' '
    let text = ' ' . join(text)
  endif
  call setline(lnum, stars . a:kwd . text)
endfunction

function! org#keyword#complete() abort " {{{1
endfunction
