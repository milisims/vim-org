
function! org#list#has_header(text) abort
  return org#list#has_ordered_header(a:text) || org#list#has_bullet_header(a:text)
endfunction

function! org#list#has_ordered_header(text) abort
  return a:text =~# '^\s*\(\d\+\|\a\)[.)]'
endfunction

function! org#list#has_bullet_header(text) abort
  return a:text =~# '^\s*\([-+]\|\s\*\)'
endfunction

function! org#list#has_checkbox(text) abort
  return a:text =~# '^\s*\([-+]\|\(\d\+\|\a\)[.)]\|\s\*\)\s\+\(\[[xX -]\]\)'
endfunction

function! org#list#has_check(text) abort
  return a:text =~# '^\s*\([-+]\|\(\d\+\|\a\)[.)]\|\s\*\)\s\+\(\[[xX]\]\)'
endfunction

function! org#list#is_item(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  return org#list#item_is_bullet(l:lnum) || org#list#item_is_ordered(l:lnum)
endfunction

function! org#list#parent_item_range(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let [l:start, l:end] = org#list#item_range(l:lnum)
  if l:start == 0
    return [0, 0]
  endif
  let l:search = org#util#search(l:start, '^\(' . matchstr(getline(l:start), '^\s*') . '\)\@!', 'nbW')
  if l:search == 0
    return [0, 0]
  endif
  let [l:parent_start, l:parent_end] = org#list#item_range(l:search)
  return (l:parent_start == 0 || l:start > l:parent_end) ? [0, 0] : [l:parent_start, l:parent_end]
endfunction

function! org#list#level(lnum) abort
  let [l:start, l:end] = org#list#item_range(a:lnum)
  let l:level = 0
  while l:start > 0
    let l:level += 1
    let [l:start, l:end] = org#list#parent_item_range(l:start)
  endwhile
  return l:level
endfunction

function! s:list_header_regex(text) abort
  let l:header = split(a:text)[0]
  let l:whitespace = matchstr(a:text, '^\s*')
  if l:header ==# '-'
    return [l:whitespace, '-']
  elseif l:header ==# '+'
    return [l:whitespace, '+']
  elseif l:header ==# '*'
    return [l:whitespace, '\*']
  elseif l:header =~# '\d\+)'
    return [l:whitespace, '\d\+)']
  elseif l:header =~# '\d\+\.'
    return [l:whitespace, '\d\+\.']
  elseif l:header =~# '\a)'
    return [l:whitespace, '\a)']
  elseif l:header =~# '\a\.'
    return [l:whitespace, '\a\.']
  endif
  throw 's:list_header_regex(' . a:text . ') contains no list header'
endfunction

function! org#list#item_range(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:item_start = org#list#item_start(l:lnum)
  let [l:whitespace, l:header_regex] = s:list_header_regex(getline(l:item_start))
  " 3 'ends' : double space, less indentation (don't match empty single lines),
  " == indent with differnt list marker
  let l:pattern = '^$\n^$'
  let l:pattern .= !empty(l:whitespace) ? '\|^\(' . l:whitespace . '\|$\)\@!' : ''
  let l:pattern .= '\|^' . l:whitespace . '\(\s\+\|' . l:header_regex . '\)\@!'
  let l:upper_bound = org#util#search(l:item_start, l:pattern, 'bnW')
  let l:upper_bound = l:upper_bound > 0 ? l:upper_bound : 1
  let l:lower_bound = org#util#search(l:item_start, l:pattern, 'nW')
  let l:lower_bound = l:lower_bound > 0 ? l:lower_bound : line('$')
  let l:start = org#util#search(l:upper_bound, '^' . l:whitespace . l:header_regex, 'nW')
  let l:end = org#util#search(l:lower_bound, '^' . l:whitespace . l:header_regex, 'bnW')
  let l:end = org#list#item_end(l:end)
  return [l:start, l:end]
endfunction

function! org#list#find(lnum, ...) abort
  " lnum, same type of list item + level (bool), search flags: 'bwW'
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:same = get(a:, '1', 0)
  let l:flags = get(a:, '2', '') . 'nW'
  if !l:same
    return org#util#search(l:lnum, '\v(\s*([-+]|(\d+|\a)[.)])|\s+\*)', l:flags)
  endif
  let l:start = org#list#item_start(l:lnum)
  let l:flags .= stridx(l:flags, 'b') >= 0 ? 'z' : ''

  let [l:whitespace, l:header_regex] = s:list_header_regex(getline(l:start))
  let l:next = org#util#search(l:lnum, '^' . l:whitespace . l:header_regex, l:flags)
  " No double spaces,

  " 3 'ends' : double space, less indentation (don't match empty single lines),
  " == indent with differnt list marker
  let l:pattern = '^$\n^$'
  let l:pattern .= !empty(l:whitespace) ? '\|^\(' . l:whitespace . '\|$\)\@!' : ''
  let l:pattern .= '\|^' . l:whitespace . '\(\s\+\|' . l:header_regex . '\)\@!'

  " let l:pattern = '^$\n^$'
  " let l:pattern .= '\|^' . l:whitespace . '\(\s\+\|' . l:header_regex . '\)\@!'
  " let l:pattern .= !empty(l:whitespace) ? '\|^\(' . l:whitespace . '\|$\)\@!' : ''

  let l:stop = org#util#search(l:start, l:pattern, l:flags)
  if l:stop == 0 && (stridx(l:flags, 'b') == -1)
    let l:stop = line('$')
  endif
  if stridx(l:flags, 'b') >= 0
    return l:next > l:stop ? l:next : 0
  else
    return l:next < l:stop ? l:next : 0
  endif
endfunction

" TODO reorder_listitem

" checkbox functions {{{

function! org#list#checkbox_add() abort
  let l:line = getline('.')
  if !org#list#has_header(l:line) || org#list#has_checkbox(l:line)
    return
  endif
  call setline('.', substitute(l:line, '^\s*\([-+]\|\(\d\+\|\a\)[.)]\|\s\*\)\s\+', '&[ ] ', ''))
endfunction

function! org#list#checkbox_remove() abort
  let l:line = getline('.')
  if !org#list#has_header(l:line) || !org#list#has_checkbox(l:line)
    return
  endif
  call setline('.', substitute(l:line, '^\s*\([-+]\|\(\d\+\|\a\)[.)]\|\s\*\)\s*\zs\s\(\[[xX -]\]\)', '', ''))
endfunction

function! org#list#checkbox_toggle() abort
  let l:line = getline('.')
  if !org#list#has_header(l:line)
    return
  endif
  if org#list#has_checkbox(l:line)
    call org#list#checkbox_remove()
  else
    call org#list#checkbox_add()
  endif
endfunction

function! org#list#check_toggle() abort
  let l:line = getline('.')
  if !org#list#has_checkbox(l:line)
    return
  endif
  if org#list#has_check(l:line)
    call setline('.', substitute(l:line, '\[[xX]\]', '[ ]', ''))
  else
    call setline('.', substitute(l:line, '\[ \]', '[X]', ''))
  endif
  " TODO: if sublist, do the thing
endfunction


" }}}

function! s:listitem_start_regex(lnum, ...) abort
  let l:whitespace = matchstr(getline(a:lnum), '^\s*')
  let l:regex = ''
  if !empty(l:whitespace) && !org#list#has_header(getline(a:lnum))
    let l:regex .= '^\(' . l:whitespace . '\)\@!'
  endif
  let l:type = get(a:, 1, 'any')
  if l:type ==? 'b'
    let l:regex .= '\v(\s*[-+]|\s+\*)'
  elseif l:type ==? 'o'
    let l:regex .= '\v(\s*(\d+|\a)[.)])'
  else
    let l:regex .= '\v(\s*([-+]|(\d+|\a)[.)])|\s+\*)'
  endif
  return l:regex
endfunction

function! s:listitem_end_regex(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:whitespace = matchstr(getline(l:lnum), '^\s*')
  let l:endmatch = '\n^$\n^$'
  let l:endmatch .= '\|\n' . l:whitespace . '\S'
  if !empty(l:whitespace)
    let l:endmatch .= '\|\n\(' . l:whitespace . '\)\@!'
  endif
  return l:endmatch
endfunction

function! org#list#item_range(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:start = org#util#search(l:lnum, s:listitem_start_regex(l:lnum), 'nbW')
  let l:end = org#util#search(l:start, s:listitem_end_regex(l:start), 'nW')
  return (l:start == 0 || l:lnum > l:end) ? [0, 0] : [l:start, l:end]
endfunction

function! org#list#item_start(lnum) abort
  return org#list#item_range(a:lnum)[0]
endfunction

function! org#list#item_end(lnum) abort
  return org#list#item_range(a:lnum)[1]
endfunction

function! org#list#item_is_ordered(lnum) abort
  return org#list#has_ordered_header(getline(org#list#item_start(a:lnum)))
endfunction

function! org#list#item_is_bullet(lnum) abort
  return org#list#has_bullet_header(getline(org#list#item_start(a:lnum)))
endfunction

