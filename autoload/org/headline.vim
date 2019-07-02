
function! org#headline#checkline(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  return org#headline#checktext(getline(l:lnum))
endfunction

function! org#headline#checktext(text) abort
  return a:text =~# '^\*'
endfunction

function! org#headline#has_keyword(text) abort
  return a:text =~# '^\*\+\s\+\(' . join(org#get_todo_keywords(), '\|') . '\)'
endfunction

" TODO: this is inconsistent? parse?
function! org#headline#keyword(text) abort
  return matchstr(a:text, '^\*\+\s\+\zs\(' . join(org#get_todo_keywords(), '\|') . '\)')
endfunction

function! org#headline#find(lnum, ...) abort
  " lnum, level or lower or 0 for any, search flags: 'bwW'
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:level = get(a:, '1', 0)
  let l:flags = get(a:, '2', '') . 'n'
  " let l:lnum = l:flags =~# 'b' ? l:lnum : l:lnum + 1
  let l:pattern = l:level > 0 ? ('^\*\{1,' . l:level . '}\(\s\+\|$\)') : '^\*\+\s*'
  return org#util#search(l:lnum, l:pattern, l:flags)
endfunction

function! org#headline#level(lnum, ...) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:return_lnum = get(a:, '1', 0)
  let l:lnum = org#headline#find(l:lnum, 0, 'bW')
  let l:headline_level = max([0, matchend(getline(l:lnum), '^\*\+')])
  return l:return_lnum ? [l:headline_level, l:lnum] : l:headline_level
endfunction

" TODO rename to org#section#range maybe
function! org#headline#range(lnum, ...) abort
  " first return value (start) is zero if failed to find headline.
  " end is undefined in that case.
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:inner = get(a:, '1', 0)
  let l:start = org#headline#find(l:lnum, 0, 'bW')
  let l:end = org#headline#find(l:lnum + 1, org#headline#level(l:lnum), 'W')
  let l:end = l:end > 0 ? l:end - 1 : l:start
  " let l:end = l:end < l:start ? line('$') : l:end
  if l:inner
    if l:start == l:end && org#headline#checkline(l:start)
      " Empty headline section, nothing to select
      return [0, 0]
    endif
    let l:start += 1
    let l:end = prevnonblank(l:end)
  endif
  return [l:start, l:end]
endfunction

function! s:open_headline(direction) abort
  if a:direction > 0
    let [l:headline_level, l:headline_lnum] = org#headline#level('.', 1)
    let l:headline_level = l:headline_level == 0 ? 1 : l:headline_level
    let l:next_headline = max([l:headline_lnum - 1, 0])  " 0 - 1 if headline not found
  else
    let [l:headline_level, l:prev_headline] = org#headline#level('.', 1)
    let l:headline_level = l:headline_level == 0 ? 1 : l:headline_level
    let l:next_headline = org#headline#find(l:prev_headline + 1, l:headline_level, 'W')
    " If no match found, we're at end of file. Also subtract 1 so it's above the match.
    let l:next_headline = l:next_headline == 0 ? prevnonblank(line('$')) : l:next_headline - 1
    " If the headlines are neighbors, don't add empty spaces.
  endif
  call append(l:next_headline, repeat('*', l:headline_level) . ' ')

  " TODO call formatting function
  let l:added_lines = 1
  if !org#headline#checktext(getline(l:next_headline)) && l:next_headline > 0
    if !empty(getline(l:next_headline))
      let l:added_lines += 1
      call append(l:next_headline, '')
    endif
    if !empty(getline(l:next_headline + l:added_lines + 1))
      call append(l:next_headline + l:added_lines, '')
    endif
  endif
  call cursor(l:next_headline + l:added_lines, l:headline_level + 1)
  startinsert!
endfunction

function! org#headline#open_above() abort
  call s:open_headline(1)
endfunction

function! org#headline#open_below() abort
    call s:open_headline(-1)
endfunction

function! org#headline#cycle_keyword(direction) abort
  let l:line = getline('.')
  if !org#headline#checktext(l:line)
    return
  endif

  " Get current and next keywords
  let l:current_keyword = org#headline#keyword(l:line)
  let l:next = index(org#get_todo_keywords(), l:current_keyword) + a:direction
  if l:next == -1 || l:next >= len(org#get_todo_keywords())
    let l:next_keyword = ''
  elseif l:next == -2
    let l:next_keyword = org#get_todo_keywords()[-1]
  else
    let l:next_keyword = org#get_todo_keywords()[l:next]
  endif

  echo l:current_keyword l:next_keyword
  " Substitute, with extra stuff for edge cases
  if empty(l:current_keyword)
    let l:new_line = substitute(l:line, '^\*\+\s\+', '&' . l:next_keyword . ' ', '')
  elseif empty(l:next_keyword)
    let l:new_line = substitute(l:line, '\(^\*\+\s\+\)' . l:current_keyword . '\s\?', '\1', '')
  else
    let l:new_line = substitute(l:line, '\(^\*\+\s\+\)' . l:current_keyword, '\1' . l:next_keyword, '')
  endif
  call setline('.', l:new_line)
endfunction

