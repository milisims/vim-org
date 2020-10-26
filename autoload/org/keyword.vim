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
  call org#keyword#set(next)
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

function! org#keyword#get(lnum) abort " {{{1
  return org#keyword#parse(getline(a:lnum))
endfunction

function! org#keyword#set(kwd, ...) abort " {{{1
  " [force], [keywords]
  let keywords = exists('a:2') ? a:2 : org#outline#keywords()
  if !empty(a:kwd) && ! get(a:, 1, 0) && index(keywords.all, a:kwd) < 0
    throw 'Org: ' . a:kwd . ' not in keywords: ' string(keywords.all)
  endif
  let lnum = line('.')
  if !org#headline#checktext(getline(lnum))
    return
  endif
  let line = getline('.')
  let current = org#keyword#parse(getline(lnum))

  if empty(a:kwd) && !empty(current)
    let new_line = substitute(line, '\v^(\*+\s+)' . current . '\s?', '\1', '')
  elseif empty(current) && !empty(a:kwd)
    let new_line = substitute(line, '\v^\*+\s+', '&' . a:kwd . ' ', '')
  else
    let new_line = substitute(line, '\v^(\*+\s+)' . current, '\1' . a:kwd, '')
  endif

  call setline('.', new_line)
  if !exists('g:org#keyword#old')
    let g:org#keyword#old = current
    let g:org#keyword#new = a:kwd
    if index(keywords.done, a:kwd) >= 0
      doautocmd User OrgKeywordDone
    elseif !empty(a:kwd)
      doautocmd User OrgKeywordToDo
    else
      doautocmd User OrgKeywordClear
    endif
    doautocmd User OrgKeywordSet
    unlet! g:org#keyword#old g:org#keyword#new
  endif
endfunction

function! org#keyword#complete() abort " {{{1
endfunction
