" NOTE: Generally, we follow the pattern:
" let l:var = check_for_context()
" if l:var is True, then process. Otherwise return.

" NOTE:
" get/is/has
" when a function has 'direction' vs above/below -- shouldn't?

" document structure {{{
" These functions return simple information about the document or text

" }}}


" function! org#add_property() abort
"   let [l:property_drawer_start, l:property_drawer_end] = org#property_drawer_range('.')
"   let l:headline = org#headline#find('.', 0, 'bW')
"   call append(l:headline, [':PROPERTIES:', '', ':END:'])
" endfunction

" Motions and text objects {{{

function! org#motion_headline(count1, direction, same_level) abort
  normal! m`
  let l:flags = a:direction > 0 ? '' : 'b'
  let l:level = a:same_level ? org#headline#level('.') : 0
  for l:i in range(a:count1)
      execute org#headline#find('.', l:level, l:flags)
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
  let [l:start, l:end] = org#headline#range('.', a:inner)
  if l:start == 0 || line('.') < l:start || line('.') > l:end
    " Not in a headline, or inner and the headline is empty
    return
  endif
  execute 'normal! ' . l:start .  'ggV' . l:end . 'gg0'
endfunction

" TODO: pre-selected region addition only works backwards
function! org#visual_headline(inner) abort
  let [l:start, l:end] = org#headline#range('.', a:inner)
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
