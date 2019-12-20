" 346:(defconst org-list-end-re "^[ \t]*\n[ \t]*\n"
" 347-  "Regex matching the end of a plain list.")
" 348-
" 349:(defconst org-list-full-item-re
" 350-  (concat "^[ \t]*\\(\\(?:[-+*]\\|\\(?:[0-9]+\\|[A-Za-z]\\)[.)]\\)\\(?:[ \t]+\\|$\\)\\)"
" 351-      "\\(?:\\[@\\(?:start:\\)?\\([0-9]+\\|[A-Za-z]\\)\\][ \t]*\\)?"
" 352-      "\\(?:\\(\\[[ X-]\\]\\)\\(?:[ \t]+\\|$\\)\\)?"
" 353-      "\\(?:\\(.*\\)[ \t]+::\\(?:[ \t]+\\|$\\)\\)?")
" 354-  "Matches a list item and puts everything into groups:
" 355-group 1: bullet
" 356-group 2: counter
" 357-group 3: checkbox
" 358-group 4: description tag")

" group 1: bullet          "\v^\s*(([-+*]|(\d+|\a)[.)])(\s+|$))"
" group 2: counter-start   "\v(\[@(:start:)?(\d+|\a)\]\s*)?"
" group 3: checkbox        "\v((\[[ Xx-]\])(\s+|$))?"
" group 4: description-tag "\v((.*)\s+::(\s+|$))?"
" list end:                "^\s*\n\s*\n"

" Rules for regex: only group the components we care about potentially returning.
" Almost never whitespace.
let org#list#regex#ordered_bullet   = '\v^\s*(\d+|\a)[.)]%(\s+|$)'
let org#list#regex#unordered_bullet = '\v^\s*([-+]|\s\*)%(\s+|$)'
let org#list#regex#bullet           = '\v^\s*(%([-+*]|%(\d+|\a)[.)]))%(\s+|$)'
let org#list#regex#counter_start    = '\v(\[\@%(:start:)?(\d+|\a)\]\s*)'
let org#list#regex#checkbox         = '\v(\[[ Xx-]\]%(\s+|$))'
let org#list#regex#checkedbox       = '\v(\[[Xx]\]%(\s+|$))'
let org#list#regex#uncheckedbox     = '\v(\[[ ]\]%(\s+|$))'
let org#list#regex#tag              = '\v(%(.*)\s+::%(\s+|$))'
let org#list#regex#end              = '^\s*\n\s*\n'

" RENAME:
let org#list#regex#upto#checkbox = g:org#list#regex#bullet . g:org#list#regex#counter_start[2:]  . '?' . g:org#list#regex#checkbox[2:]
let org#list#regex#upto#checkedbox = g:org#list#regex#bullet . g:org#list#regex#counter_start[2:] . '?' . g:org#list#regex#checkedbox[2:]

let org#list#regex#decompose = [org#list#regex#bullet, org#list#regex#counter_start[2:],
      \ org#list#regex#checkbox[2:], org#list#regex#tag[2:], org#list#regex#end]
" let org#list#regex#full = join(org#list#regex#decompose, '')

function! org#list#has_bullet(text) abort " {{{1
  return a:text =~# g:org#list#regex#bullet
endfunction

function! org#list#has_ordered_bullet(text) abort " {{{1
  return a:text =~# g:org#list#regex#ordered_bullet
endfunction

function! org#list#has_unordered_bullet(text) abort " {{{1
  return a:text =~# g:org#list#regex#unordered_bullet
endfunction

function! org#list#has_checkbox(text) abort " {{{1
  return a:text =~# g:org#list#regex#upto#checkbox
endfunction

function! org#list#has_check(text) abort " {{{1
  return a:text =~? g:org#list#regex#upto#checkedbox
endfunction

function! org#list#checkline(lnum) abort " {{{1
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  return org#list#item_is_unordered(lnum) || org#list#item_is_ordered(lnum)
endfunction

function! org#list#parent_item_range(lnum) abort " {{{1
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let [start, end] = org#list#item_range(lnum)
  if start == 0
    return [0, 0]
  endif
  let search = org#util#search(start, '^\(' . matchstr(getline(start), '^\s*') . '\)\@!', 'nbW')
  if search == 0
    return [0, 0]
  endif
  let [parent_start, parent_end] = org#list#item_range(search)
  return (parent_start == 0 || start > parent_end) ? [0, 0] : [parent_start, parent_end]
endfunction

function! org#list#level(lnum) abort " {{{1
  let [start, end] = org#list#item_range(a:lnum)
  let level = 0
  while start > 0
    let level += 1
    let [start, end] = org#list#parent_item_range(start)
  endwhile
  return level
endfunction

function! s:list_bullet_regex(text) abort " {{{1
  " let [whitespace, bullet] = ['\s*', '\v(([-+*]|([0-9]+|[A-Za-z])[.)])']
  " TODO should s:list_bullet_regex use very magic expressions?
  let bullet = split(a:text)[0]
  let whitespace = matchstr(a:text, '^\s*')
  if bullet =~# '\d\+)'
    return [whitespace, '\d\+)']
  elseif bullet =~# '\d\+\.'
    return [whitespace, '\d\+\.']
  elseif bullet =~# '\a)'
    return [whitespace, '\a)']
  elseif bullet =~# '\a\.'
    return [whitespace, '\a\.']
  elseif bullet =~# '\*'
    return [whitespace, '\*']
  endif
  return [whitespace, bullet]
endfunction

" function! s:list_bullet_regex(text) abort " {{{1
"   let [whitespace, bullet] = ['\s*', '[[:alnum:]*+-]']
"   let bullet = split(a:text)[0]
"   let whitespace = matchstr(a:text, '^\s*')
"   if bullet ==# '-'
"     return [whitespace, '-']
"   elseif bullet ==# '+'
"     return [whitespace, '+']
"   elseif bullet ==# '*'
"     return [whitespace, '\*']
"   elseif bullet =~# '\d\+)'
"     return [whitespace, '\d\+)']
"   elseif bullet =~# '\d\+\.'
"     return [whitespace, '\d\+\.']
"   elseif bullet =~# '\a)'
"     return [whitespace, '\a)']
"   elseif bullet =~# '\a\.'
"     return [whitespace, '\a\.']
"   endif
"   return white
"   throw 's:list_bullet_regex(' . a:text . ') contains no list bullet'
" endfunction

function! org#list#item_range(lnum) abort " {{{1
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let regex = s:listitem_start_regex(a:lnum)
  let max = org#headline#find(a:lnum, 0, 'nbW')
  let start = org#util#search(a:lnum, regex, 'bnW', max)
  " TODO: Find a better solution to text starting at col 0 with no whitespace and not a list leader
  if start == 0 || regex == ''
    return [0, 0]
  endif
  let regex = s:listitem_end_regex(start)
  let end = org#util#search(start, regex, 'nW')
  return lnum > end ? [0, 0] : [start, end > 0 ? end : line('$')]
endfunction

function! s:listitem_start_regex(lnum, ...) abort " {{{2
  " Construct a regex for searching upward to find the start of the item at lnum
  let whitespace = matchstr(getline(a:lnum), '^\s*')
  let regex = ''
  if !org#list#has_bullet(getline(a:lnum))
    if !empty(whitespace)
      let regex .= '^\(' . whitespace . '\)\@!'
    else
      return ''
    endif
  endif
  let type = get(a:, 1, 'any')
  if type ==? '^u'
    let regex .= '\v(\s*[-+]|\s+\*)'
  elseif type ==? '^o'
    let regex .= '\v(\s*(\d+|\a)[.)])'
  else
    let regex .= '\v(\s*([-+]|(\d+|\a)[.)])|\s+\*)'
  endif
  return regex
endfunction

function! s:listitem_end_regex(lnum) abort " {{{2
  " lnum assumed to be the list item start
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let whitespace = matchstr(getline(lnum), '^\s*')
  let endmatch = '\n^$\n^$'
  let endmatch .= '\|\n' . whitespace . '\S'
  if !empty(whitespace)
    let endmatch .= '\|\n\(' . whitespace . '\)\@!'
  endif
  return endmatch
endfunction

function! org#list#range(lnum) abort " {{{1
  " FIXME: no idea what this is doing.
  " let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let lnum = org#list#item_start(a:lnum)[0]
  if lnum == 0
    return [0, 0]
  endif
  let regex = s:listitem_start_regex(a:lnum)
  let max = org#headline#find(a:lnum, 0, 'nbW')
  let item_start = org#util#search(a:lnum, regex, 'bnW', max)
  let [whitespace, bullet_regex] = s:list_bullet_regex(getline(item_start))
  " 3 'ends' : double space, less indentation (don't match empty single lines),
  " == indent with differnt list marker
  let pattern = '^$\n^$'
  let pattern .= empty(whitespace) ? '' : '\|^\(' . whitespace . '\|$\)\@!'
  let pattern .= '\|^' . whitespace . '\(\s\+\|' . bullet_regex . '\)\@!'
  let upper_bound = org#util#search(item_start, pattern, 'bnW')
  let lower_bound = org#util#search(item_start, pattern, 'nW')
  let upper_bound = upper_bound > 0 ? upper_bound : 1
  let lower_bound = lower_bound > 0 ? lower_bound : line('$')
  let start = org#util#search(upper_bound, '^' . whitespace . bullet_regex, 'nW')
  let end = org#util#search(lower_bound, '^' . whitespace . bullet_regex, 'bnW')
  let end = org#list#item_end(end)
  return [start, end]
endfunction


function! org#list#item_lines(lnum) abort " {{{1 RENAME
  let [lnum, lower_bound] = org#list#range(a:lnum)
  let regex = '^' . join(s:list_bullet_regex(getline(lnum)), '')
  let items = []
  while lnum > 0
    call add(items, org#list#item_range(lnum))
    let lnum = org#util#search(lnum + 1, regex, 'nW', lower_bound)
  endwhile
  return items
endfunction

function! org#list#find(lnum, ...) abort " {{{1
  let flags = get(a:, 1, '')
  return org#util#search(a:lnum, g:org#list#regex#bullet, flags)
endfunction

function! org#list#find_same(lnum, ...) abort " {{{1
  " used as part of a list to find next/prev item of that list
  let flags = get(a:, 1, '')
  let [upper_bound, lower_bound] = org#list#range(a:lnum)
  if upper_bound == 0
    return 0
  endif

  let pattern = '^' . join(s:list_bullet_regex(getline(upper_bound)), '')
  let bound = flags =~# 'b' ? upper_bound : lower_bound
  return org#util#search(a:lnum, pattern, flags, bound)
endfunction

function! org#list#item_indent(direction) abort " {{{1
  let range = org#list#item_range('.')
  if range[0] + range[1] > 0 && ! (a:direction < 0 && indent(range[0]) == 0)
    execute 'silent!' join(range, ',') . (a:direction > 0 ? '>' : '<')
  endif
endfunction

function! org#list#reorder() abort " {{{1
endfunction " TODO reorder_listitem

function! org#list#checkbox_add() abort " {{{1
  let line = getline('.')
  if !org#list#has_bullet(line) || org#list#has_checkbox(line)
    return
  endif
  call setline('.', substitute(line, '^\s*\([-+]\|\(\d\+\|\a\)[.)]\|\s\*\)\s\+', '&[ ] ', ''))
endfunction

function! org#list#checkbox_remove() abort " {{{1
  let line = getline('.')
  if !org#list#has_bullet(line) || !org#list#has_checkbox(line)
    return
  endif
  call setline('.', substitute(line, '^\s*\([-+]\|\(\d\+\|\a\)[.)]\|\s\*\)\s*\zs\s\(\[[xX -]\]\)', '', ''))
endfunction

function! org#list#checkbox_toggle() abort " {{{1
  let line = getline('.')
  if !org#list#has_bullet(line)
    return
  endif
  if org#list#has_checkbox(line)
    call org#list#checkbox_remove()
  else
    call org#list#checkbox_add()
  endif
endfunction

function! org#list#check_toggle() abort " {{{1
  let line = getline('.')
  if !org#list#has_checkbox(line)
    return
  endif
  if org#list#has_check(line)
    call setline('.', substitute(line, '\[[xX]\]', '[ ]', ''))
  else
    call setline('.', substitute(line, '\[ \]', '[X]', ''))
  endif
  " TODO: if sublist, do the thing
endfunction

function! org#list#item_decompose(lnum) abort " {{{1
  " For now, undefined results on non list items.
  " Whitespace, bullet,
  " FIXME: Should also decompose recursively
  let [start, end] = org#list#item_range(a:lnum)
  let item = {'complete': join(getline(start, end))}
  let [bullet, text] = split(item.complete, '\v^\s*([-+*]|(\d+|\a)[.)])\zs\s*\ze')
  let [item.whitespace, item.bullet] = split(bullet, '\s*\zs\ze')
  " Messy: that last argument
  let [item.checkbox, item.contents] = split(text, '\v^(\[[ xX-]])?\zs\s*\ze.*', !(text =~? '^\[[ X]]'))
  return item
endfunction

function! org#list#item_start(lnum) abort " {{{1
  return org#list#item_range(a:lnum)[0]
endfunction

function! org#list#item_end(lnum) abort " {{{1
  return org#list#item_range(a:lnum)[1]
endfunction

function! org#list#item_is_ordered(lnum) abort " {{{1
  let lstart = org#list#item_start(a:lnum)
  return lstart < 0 ? 0 : org#list#has_ordered_bullet(getline(lstart))
endfunction

function! org#list#item_is_unordered(lnum) abort " {{{1
  let lstart = org#list#item_start(a:lnum)
  return lstart < 0 ? 0 : org#list#has_unordered_bullet(getline(lstart))
endfunction

function! org#list#bullet_cycle(lnum, direction) abort " {{{1
  " TODO get global/buffer var
  let lnum = line(a:lnum) > 0 ? line(a:lnum) : a:lnum
  let bullets = get(g:, 'org#list#bullet_order', ['-', '+', '*'])
  let bullet = org#list#get_bullet(lnum)
  let index = index(bullets, bullet)
  if index >= 0
    let next = bullets[(index + a:direction) % len(bullets)]
    call setline(lnum, substitute(getline(lnum), bullet, next, ''))
  endif
endfunction

function! org#list#get_bullet(lnum) abort " {{{1
  return matchstr(getline(a:lnum), '\v^\s*(\zs[-+]|\zs(\d+|\a)[.)]|\s\zs\*)')
endfunction
