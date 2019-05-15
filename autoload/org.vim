" NOTE: Generally, we follow the pattern:
" let l:var = check_for_context()
" if l:var is True, then process. Otherwise return.

" NOTE:
" get/is/has
" when a function has 'direction' vs above/below -- shouldn't?

" util {{{

function! s:search(lnum, pattern, flags, ...) abort
  " search({pattern} [, {flags} [, {stopline} [, {timeout}]]])
  let l:cursor = getcurpos()[1:]
  if a:lnum > 0
    call cursor(a:lnum, 1)
  endif
  " Consistent searches, I hope. Linewise only!
  let l:flags = stridx(a:flags, 'b') >= 0 ? a:flags . 'z' : a:flags
  " echom 'search' a:pattern l:flags join(a:000)
  let l:search = call(function('search'), extend([a:pattern, l:flags], a:000))
  if stridx(a:flags, 'n') >= 0
    call cursor(l:cursor)
  endif
  return l:search
endfunction

" }}}

" document structure {{{
" These functions return simple information about the document or text

function! org#has_list_header(text) abort
  return org#has_ordered_list_header(a:text) || org#has_bullet_list_header(a:text)
endfunction

function! org#has_ordered_list_header(text) abort
  return a:text =~# '^\s*\(\d\+\|\a\)[.)]'
endfunction

function! org#has_bullet_list_header(text) abort
  return a:text =~# '^\s*\([-+]\|\s\*\)'
endfunction

function! org#has_checkbox(text) abort
  return a:text =~# '^\s*\([-+]\|\(\d\+\|\a\)[.)]\|\s\*\)\s\+\(\[[xX -]\]\)'
endfunction

function! org#has_checked_box(text) abort
  return a:text =~# '^\s*\([-+]\|\(\d\+\|\a\)[.)]\|\s\*\)\s\+\(\[[xX]\]\)'
endfunction

function! org#is_headline(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  return org#has_headline(getline(l:lnum))
endfunction

function! org#has_headline(text) abort
  return a:text =~# '^\*'
endfunction

function! org#has_headline_todo_keyword(text) abort
  return a:text =~# '^\*\+\s\+\(' . join(org#get_todo_keywords(), '\|') . '\)'
endfunction

" TODO: this is inconsistent? parse?
function! org#get_headline_todo_keyword(text) abort
  return matchstr(a:text, '^\*\+\s\+\zs\(' . join(org#get_todo_keywords(), '\|') . '\)')
endfunction

function! org#get_(text) abort
  return matchstr(a:text, '^\*\+\s\+\zs\(' . join(org#get_todo_keywords(), '\|') . '\)')
endfunction

function! org#find_headline(lnum, ...) abort
  " lnum, level or lower or 0 for any, search flags: 'bwW'
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:level = get(a:, '1', 0)
  let l:flags = get(a:, '2', '') . 'n'
  let l:pattern = l:level > 0 ? ('^\*\{1,' . l:level . '}\(\s\+\|$\)') : '^\*\+\s*'
  " echom l:lnum l:level l:pattern
  return s:search(l:lnum, l:pattern, l:flags)
endfunction

function! org#get_headline_level(lnum, ...) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:return_lnum = get(a:, '1', 0)
  let l:lnum = org#is_headline(l:lnum) ? l:lnum : org#find_headline(l:lnum, 0, 'bW')
  let l:headline_level = max([0, matchend(getline(l:lnum), '^\*\+')])
  return l:return_lnum ? [l:headline_level, l:lnum] : l:headline_level
endfunction

" TODO: inner starting on a headline doesn't work. not sure if want or not
function! org#get_headline_range(lnum, ...) abort
  " first return value (start) is zero if failed to find headline.
  " end is undefined in that case.
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:inner = get(a:, '1', 0)
  let l:start = org#is_headline(l:lnum) ? l:lnum : org#find_headline(l:lnum, 0, 'bW')
  let l:end = org#find_headline(l:lnum, org#get_headline_level(l:lnum), 'W')
  let l:end = l:end > 0 ? l:end - 1 : l:start
  " let l:end = l:end < l:start ? line('$') : l:end
  if l:inner
    if l:start == l:end && org#is_headline(l:start)
      " Empty headline section, nothing to select
      return [0, 0]
    endif
    let l:start += 1
    let l:end = prevnonblank(l:end)
  endif
  return [l:start, l:end]
endfunction

function! s:listitem_start_regex(lnum, ...) abort
  let l:whitespace = matchstr(getline(a:lnum), '^\s*')
  let l:regex = ''
  if !empty(l:whitespace) && !org#has_list_header(getline(a:lnum))
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

function! org#get_listitem_range(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:start = s:search(l:lnum, s:listitem_start_regex(l:lnum), 'nbW')
  let l:end = s:search(l:start, s:listitem_end_regex(l:start), 'nW')
  return (l:start == 0 || l:lnum > l:end) ? [0, 0] : [l:start, l:end]
endfunction

function! org#get_listitem_start(lnum) abort
  return org#get_listitem_range(a:lnum)[0]
endfunction

function! org#get_listitem_end(lnum) abort
  return org#get_listitem_range(a:lnum)[1]
endfunction

function! org#is_ordered_listitem(lnum) abort
  return org#has_ordered_list_header(getline(org#get_listitem_start(a:lnum)))
endfunction

function! org#is_bullet_listitem(lnum) abort
  return org#has_bullet_list_header(getline(org#get_listitem_start(a:lnum)))
endfunction

function! org#is_listitem(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  return org#is_bullet_listitem(l:lnum) || org#is_ordered_listitem(l:lnum)
endfunction

function! org#get_listitem_parent_range(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let [l:start, l:end] = org#get_listitem_range(l:lnum)
  if l:start == 0
    return [0, 0]
  endif
  let l:search = s:search(l:start, '^\(' . matchstr(getline(l:start), '^\s*') . '\)\@!', 'nbW')
  if l:search == 0
    return [0, 0]
  endif
  let [l:parent_start, l:parent_end] = org#get_listitem_range(l:search)
  return (l:parent_start == 0 || l:start > l:parent_end) ? [0, 0] : [l:parent_start, l:parent_end]
endfunction

function! org#get_list_level(lnum) abort
  let [l:start, l:end] = org#get_listitem_range(a:lnum)
  let l:level = 0
  while l:start > 0
    let l:level += 1
    let [l:start, l:end] = org#get_listitem_parent_range(l:start)
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

function! org#get_list_range(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:item_start = org#get_listitem_start(l:lnum)
  let [l:whitespace, l:header_regex] = s:list_header_regex(getline(l:item_start))
  " 3 'ends' : double space, less indentation (don't match empty single lines),
  " == indent with differnt list marker
  let l:pattern = '^$\n^$'
  let l:pattern .= !empty(l:whitespace) ? '\|^\(' . l:whitespace . '\|$\)\@!' : ''
  let l:pattern .= '\|^' . l:whitespace . '\(\s\+\|' . l:header_regex . '\)\@!'
  let l:upper_bound = s:search(l:item_start, l:pattern, 'bnW')
  let l:upper_bound = l:upper_bound > 0 ? l:upper_bound : 1
  let l:lower_bound = s:search(l:item_start, l:pattern, 'nW')
  let l:lower_bound = l:lower_bound > 0 ? l:lower_bound : line('$')
  let l:start = s:search(l:upper_bound, '^' . l:whitespace . l:header_regex, 'nW')
  let l:end = s:search(l:lower_bound, '^' . l:whitespace . l:header_regex, 'bnW')
  let l:end = org#get_listitem_end(l:end)
  messages clear
  echom l:upper_bound l:lower_bound l:start l:end
  return [l:start, l:end]
endfunction

function! org#find_listitem(lnum, ...) abort
  " lnum, same type of list item + level (bool), search flags: 'bwW'
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:same = get(a:, '1', 0)
  let l:flags = get(a:, '2', '') . 'nW'
  if !l:same
    return s:search(l:lnum, '\v(\s*([-+]|(\d+|\a)[.)])|\s+\*)', l:flags)
  endif
  let l:start = org#get_listitem_start(l:lnum)
  let l:flags .= stridx(l:flags, 'b') >= 0 ? 'z' : ''

  messages clear
  let [l:whitespace, l:header_regex] = s:list_header_regex(getline(l:start))
  let l:next = s:search(l:lnum, '^' . l:whitespace . l:header_regex, l:flags)
  echom l:next '^' . l:whitespace . l:header_regex
  " No double spaces,

  " 3 'ends' : double space, less indentation (don't match empty single lines),
  " == indent with differnt list marker
  let l:pattern = '^$\n^$'
  let l:pattern .= !empty(l:whitespace) ? '\|^\(' . l:whitespace . '\|$\)\@!' : ''
  let l:pattern .= '\|^' . l:whitespace . '\(\s\+\|' . l:header_regex . '\)\@!'

  " let l:pattern = '^$\n^$'
  " let l:pattern .= '\|^' . l:whitespace . '\(\s\+\|' . l:header_regex . '\)\@!'
  " let l:pattern .= !empty(l:whitespace) ? '\|^\(' . l:whitespace . '\|$\)\@!' : ''

  let l:stop = s:search(l:start, l:pattern, l:flags)
  if l:stop == 0 && (stridx(l:flags, 'b') == -1)
    let l:stop = line('$')
  endif
  echom l:stop l:pattern
  if stridx(l:flags, 'b') >= 0
    return l:next > l:stop ? l:next : 0
  else
    return l:next < l:stop ? l:next : 0
  endif
endfunction

" }}}

function! org#reorder_list() abort
  if !is_ordered_listitem('.')
    return
  endif
  " TODO: too easy to use g<C-a> for me to care right now.
endfunction

" checkbox functions {{{

function! org#add_checkbox() abort
  let l:line = getline('.')
  if !org#has_list_header(l:line) || org#has_checkbox(l:line)
    return
  endif
  call setline('.', substitute(l:line, '^\s*\([-+]\|\(\d\+\|\a\)[.)]\|\s\*\)\s\+', '&[ ] ', ''))
endfunction

function! org#remove_checkbox() abort
  let l:line = getline('.')
  if !org#has_list_header(l:line) || !org#has_checkbox(l:line)
    return
  endif
  call setline('.', substitute(l:line, '^\s*\([-+]\|\(\d\+\|\a\)[.)]\|\s\*\)\s*\zs\s\(\[[xX -]\]\)', '', ''))
endfunction

function! org#add_or_remove_checkbox() abort
  let l:line = getline('.')
  if !org#has_list_header(l:line)
    return
  endif
  if org#has_checkbox(l:line)
    call org#remove_checkbox()
  else
    call org#add_checkbox()
  endif
endfunction

function! org#toggle_check() abort
  let l:line = getline('.')
  if !org#has_checkbox(l:line)
    return
  endif
  if org#has_checked_box(l:line)
    call setline('.', substitute(l:line, '\[[xX]\]', '[ ]', ''))
  else
    call setline('.', substitute(l:line, '\[ \]', '[X]', ''))
  endif
  " TODO: if sublist, do the thing
endfunction

" }}}

" headline functions {{{

function! s:open_headline(direction) abort
  if a:direction > 0
    let [l:headline_level, l:headline_lnum] = org#get_headline_level('.', 1)
    let l:headline_level = l:headline_level == 0 ? 1 : l:headline_level
    let l:prev_headline = org#find_headline(l:headline_lnum, 0, 'bW')
    let l:next_headline = max([l:headline_lnum - 1, 0])  " 0 - 1 if headline not found
  else
    let [l:headline_level, l:prev_headline] = org#get_headline_level('.', 1)
    let l:headline_level = l:headline_level == 0 ? 1 : l:headline_level
    let l:next_headline = org#find_headline(l:prev_headline, l:headline_level, 'W')
    " If no match found, we're at end of file. Also subtract 1 so it's above the match.
    let l:next_headline = l:next_headline == 0 ? prevnonblank(line('$')) : l:next_headline - 1
    " If the headlines are neighbors, don't add empty spaces.
  endif
  call append(l:next_headline, repeat('*', l:headline_level) . ' ')

  let l:added_lines = 1
  if !org#has_headline(getline(l:next_headline)) && l:next_headline > 0
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

function! org#open_headline_above() abort
  call s:open_headline(1)
endfunction

function! org#open_headline_below() abort
    call s:open_headline(-1)
endfunction

function! org#cycle_todo_keyword(direction) abort
  let l:line = getline('.')
  if !org#has_headline(l:line)
    return
  endif

  " Get current and next keywords
  let l:current_keyword = org#get_headline_todo_keyword(l:line)
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

" }}}

" function! org#add_property() abort
"   let [l:property_drawer_start, l:property_drawer_end] = org#property_drawer_range('.')
"   let l:headline = org#find_headline('.', 0, 'bW')
"   call append(l:headline, [':PROPERTIES:', '', ':END:'])
" endfunction

" Motions and text objects {{{

function! org#motion_headline(count1, direction, same_level) abort
  normal! m`
  for l:i in range(a:count1)
    if a:direction >= 0
      let l:lnum = org#get_next_headline('.', a:same_level)
    else
      let l:lnum = org#get_prev_headline('.', a:same_level)
    endif
    execute l:lnum
  endfor
  normal! 0
endfunction

function! org#motion_listitem(count1, direction, same_level) abort
  for l:i in range(a:count1)
    if a:direction >= 0
      let l:lnum = org#get_next_listitem('.', a:same_level)
    else
      let l:lnum = org#get_prev_listitem('.', a:same_level)
    endif
    execute l:lnum
  endfor
endfunction

" a list: complete list
" inner list: current sub-list with header item

function! org#operator_headline(inner) abort
  let [l:start, l:end] = org#get_headline_range('.', a:inner)
  if l:start == 0 || line('.') < l:start || line('.') > l:end
    " Not in a headline, or inner and the headline is empty
    return
  endif
  execute 'normal! ' . l:start .  'ggV' . l:end . 'gg0'
endfunction

" TODO: pre-selected region addition only works backwards
function! org#visual_headline(inner) abort
  let [l:start, l:end] = org#get_headline_range('.', a:inner)
  if l:start == 0 || line('.') < l:start || line('.') > l:end
    " Not in a headline, or inner and the headline is empty
    normal! gv
    return
  endif
  let l:start = line("'<") < l:start ? line("'<") : l:start
  let l:end = line("'>") > l:end ? line("'>") : l:end
  execute 'normal! ' . l:start .  'ggV' . l:end . 'gg0'
endfunction

function! org#operator_list() abort
  return
endfunction





" }}}

" Todo keywords {{{

function! org#get_todo_keywords() abort
  " TODO multiple types of states, and 'fast access'? completion?
  return org#build_keyword_cache()
  " if !exists('b:org_keywords')
  "   call org#build_keyword_cache()
  " endif
  " return b:org_keywords
endfunction

function! org#build_keyword_cache() abort
  let l:keywords = []
  let l:cursor = getcurpos()[1:]
  call cursor(1, 1)
  while search('^#+TODO:\s*', 'zcWe')
    normal! $
    call extend(l:keywords, org#parse_todo_keywords('.'))
  endwhile
  call cursor(l:cursor)
  return empty(l:keywords) ? ['TODO', 'DONE'] : l:keywords
endfunction

" function! org#build_keyword_cache() abort
"   " Not sure if m` is necessary or if gg sets it always
"   messages clear
"   let l:keywords = []
"   for l:lnum in range(1, line('$'))
"     " TODO: regex get working
"     if getline(l:lnum) =~# '^#+TODO:\s*'
"       echom l:lnum
"       echom join(org#parse_todo_keywords(l:lnum))
"       call extend(l:keywords, org#parse_todo_keywords(l:lnum))
"     endif
"   endfor
"   return l:keywords
" endfunction

function! org#parse_todo_keywords(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:line = matchstr(getline(l:lnum), '^#+TODO:\s*\zs.*')
  let l:line = substitute(l:line, '[ |\t]\+', ' ', 'g')
  return split(l:line)
endfunction

" get(g:, 'org_dir', $HOME . '/org')
" }}}

" Misc {{{

function! org#formatexpr() abort
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

" }}}
