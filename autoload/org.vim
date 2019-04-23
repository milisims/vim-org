" NOTE: Generally, we follow the pattern:
" let l:var = check_for_context()
" if l:var is True, then process. Otherwise return.

" NOTE:
" get/is/has
" when a function has 'direction' vs above/below -- shouldn't?

" util {{{

" }}}

" document structure {{{
" These functions return simple information about the document or text

function! org#has_list_header(text) abort
  return org#has_number_list_header(a:text) || org#has_bullet_list_header(a:text)
endfunction

function! org#has_number_list_header(text) abort
  return a:text =~# '^\s*\w[.)]'
endfunction

function! org#has_bullet_list_header(text) abort
  return a:text =~# '^\s*\([-+]\|\s\*\)'
endfunction

function! org#is_number_list_item(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  return org#has_number_list_header(getline(l:lnum))
endfunction

function! org#is_bullet_list_item(lnum, ...) abort
  " Two cases:
  " 1. lnum starts with [-+*]
  " 2. part of a continued list item:
  "    a. indent never <= most recent bullet point.
  "    b. never empty line (2 by definition, but skipping that for now)
  " Second argument provided means return as list:
  " [true/false lnum if true, 0 otherwise]
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  if org#has_bullet_list_header(getline(l:lnum))
    return 1
  endif
  let l:min_indent = indent(l:lnum)
  for l:lnum in range(l:lnum, 1, -1)
    if indent(l:lnum) == 0
      return 0
    elseif org#has_bullet_list_header(getline(l:lnum))
      return l:min_indent > indent(l:lnum)
    elseif indent(l:lnum) < l:min_indent
      let l:min_indent = indent(l:lnum)
    endif
  endfor
  return 0
endfunction

function! org#is_list_item(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  return org#is_bullet_list_item(l:lnum) || org#is_number_list_item(l:lnum)
endfunction

function! org#has_checkbox(text) abort
  return a:text =~# '^\s*\([-+]\|\w[.)]\|\s\*\)\s\+\(\[[xX -]\]\)'
endfunction

function! org#is_checked_box(text) abort
  return a:text =~# '^\s*\([-+]\|\w[.)]\|\s\*\)\s\+\(\[[xX]\]\)'
endfunction

function! org#is_headline(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  return org#has_headline(getline(l:lnum))
endfunction

function! org#has_headline(text) abort
  return a:text =~# '^\*'
endfunction

function! org#is_bullet_list_item(lnum, ...) abort
  " Two cases:
  " 1. lnum starts with [-+*]
  " 2. part of a continued list item:
  "    a. indent never <= most recent bullet point.
  "    b. never empty line (2 by definition, but skipping that for now)
  " Second argument provided means return as list:
  " [true/false lnum if true, 0 otherwise]
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  if org#has_bullet_list_header(getline(l:lnum))
    return 1
  endif
  let l:min_indent = indent(l:lnum)
  for l:lnum in range(l:lnum, 1, -1)
    if indent(l:lnum) == 0
      return 0
    elseif org#has_bullet_list_header(getline(l:lnum))
      return l:min_indent > indent(l:lnum)
    elseif indent(l:lnum) < l:min_indent
      let l:min_indent = indent(l:lnum)
    endif
  endfor
  return 0
endfunction


function! org#get_list_level(lnum) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  if !org#is_list_item(l:lnum)
    return 0
  endif
  let l:list_level = 1
  let l:current_indent = indent(l:lnum)
  while org#is_list_item(l:lnum - 1)
    let l:lnum -= 1
    if indent(l:lnum) < l:current_indent
      let l:current_indent = indent(l:lnum)
      let l:list_level += 1
    endif
  endwhile
  return l:list_level
endfunction

function! org#has_headline_todo_keyword(text) abort
  return a:text =~# '^\*\+\s\+\(' . join(org#get_todo_keywords(), '\|') . '\)'
endfunction

function! org#get_headline_todo_keyword(text) abort
  return matchstr(a:text, '^\*\+\s\+\zs\(' . join(org#get_todo_keywords(), '\|') . '\)')
endfunction

function! org#get_next_headline(lnum, ...) abort
  let l:same_level = get(a:, '1', 0)
  if !l:same_level
    return search('^\*', 'zn')
  endif
  let [l:level, l:lnum] = org#get_headline_level(a:lnum, 1)
  let l:next_lnum = search('^\*\{1,' . l:level . '}\([^*]\|$\)', 'nW')
  return org#get_headline_level(l:next_lnum) == l:level ? l:next_lnum : l:lnum
endfunction

function! org#get_prev_headline(lnum, ...) abort
  let l:same_level = get(a:, '1', 0)
  if !l:same_level
    return search('^\*', 'bzn')
  endif
  let [l:level, l:lnum] = org#get_headline_level(a:lnum, 1)
  let l:next_lnum = search('^\*\{1,' . l:level . '}\([^*]\|$\)', 'bznW')
  return org#get_headline_level(l:next_lnum) == l:level ? l:next_lnum : l:lnum
endfunction

function! org#get_headline_level(lnum, ...) abort
  let l:lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let l:return_lnum = get(a:, '1', 0)
  let l:lnum = org#is_headline(l:lnum) ? l:lnum : search('^\*', 'bnW')
  let l:headline_level = max([0, matchend(getline(l:lnum), '^\*\+')])
  return l:return_lnum ? [l:headline_level, l:lnum] : l:headline_level
endfunction

" }}}

function! org#renumber_list() abort
  if !is_number_list_item('.')
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
  call setline('.', substitute(l:line, '^\s*\([-+]\|\w[.)]\|\s\*\)\s\+', '&[ ] ', ''))
endfunction

function! org#remove_checkbox() abort
  let l:line = getline('.')
  if !org#has_list_header(l:line) || !org#has_checkbox(l:line)
    return
  endif
  call setline('.', substitute(l:line, '^\s*\([-+]\|\w[.)]\|\s\*\)\s*\zs\s\(\[[xX -]\]\)', '', ''))
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
  if org#is_checked_box(l:line)
    call setline('.', substitute(l:line, '\[[xX]\]', '[ ]', ''))
  else
    call setline('.', substitute(l:line, '\[ \]', '[X]', ''))
  endif
  " TODO: if sublist, do the thing
endfunction

" }}}

" headline functions {{{

function! org#open_headline_above() abort
  let [l:headline_level, l:headline_lnum] = org#get_headline_level('.', 1)
  let l:headline_level = l:headline_level == 0 ? 1 : l:headline_level
  let l:next_headline = max([l:headline_lnum - 1, 0]) " 0 - 1 if headline not found
  call append(l:next_headline, ['', repeat('*', l:headline_level) . ' ', ''])
  execute (l:next_headline + 2)
  startinsert!
endfunction

function! org#open_headline_below() abort
  let [l:headline_level, l:headline_lnum] = org#get_headline_level('.', 1)
  let l:headline_level = l:headline_level == 0 ? 1 : l:headline_level
  let l:next_headline = search('^\*\{1,' . l:headline_level . '}\([^*]\|$\)', 'znW')
  " If no match found, we're at end of file
  let l:next_headline = l:next_headline == 0 ? prevnonblank(line('$')) + 1 : l:next_headline
  call append(l:next_headline - 1, ['', repeat('*', l:headline_level) . ' ', ''])
  execute (l:next_headline + 1)
  startinsert!
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

" Motions and text objects {{{

function! org#headline(count1, direction, same) abort
  normal! m`
  messages clear
  for l:i in range(a:count1)
    if a:direction >= 0
      let l:lnum = org#get_next_headline('.', a:same)
    else
      let l:lnum = org#get_prev_headline('.', a:same)
    endif
    execute l:lnum
  endfor
  normal! 0
endfunction

" }}}

" Todo keywords {{{

function! org#get_todo_keywords() abort
  " TODO multiple types of states, and 'fast access'? completion?
  return get(b:, 'org_keywords', get(g:, 'org_keywords', ['TODO', 'DONE']))
endfunction

function! org#build_keyword_cache() abort
  " Not sure if m` is necessary or if gg sets it always
  let b:org_keywords = []
  normal! m`gg
  while search('^#+TODO:\s*', 'W')
    call extend(b:org_keywords, org#parse_todo_keywords(getline('.')))
  endwhile
  normal! ``
endfunction

function! org#parse_todo_keywords(line) abort
  let l:line = matchstr(getline('.'), '^#+TODO:\s*\zs.*')
  let l:line = substitute(l:line, '[ |\t]\+', ' ', 'g')
  return split(l:line)
endfunction

" get(g:, 'org_dir', $HOME . '/org')
" }}}

