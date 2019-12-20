
function! org#keyword#cycle(direction) abort " {{{1
  let line = getline('.')
  if !org#headline#checktext(line)
    return
  endif

  " Get current and next keywords
  let current_keyword = org#headline#keyword(line)
  let keywords = org#keyword#all('todo') + org#keyword#all('done')
  let next = index(keywords, current_keyword) + a:direction
  if next == -1 || next >= len(keywords)
    let next_keyword = ''
  elseif next == -2
    let next_keyword = keywords[-1]
  else
    let next_keyword = keywords[next]
  endif

  " Substitute, with extra stuff for edge cases
  if empty(current_keyword)
    let new_line = substitute(line, '^\*\+\s\+', '&' . next_keyword . ' ', '')
  elseif empty(next_keyword)
    let new_line = substitute(line, '\(^\*\+\s\+\)' . current_keyword . '\s\?', '\1', '')
  else
    let new_line = substitute(line, '\(^\*\+\s\+\)' . current_keyword, '\1' . next_keyword, '')
  endif
  call setline('.', new_line)
endfunction

function! org#keyword#all(...) abort " {{{1
  " 'todo' and 'done' give lists, as does 'all'. Default is a dictionary
  " TODO combine all and get -- keyword cache in agenda_cache?
  let keywords = get(b:, 'org_keywords', org#keyword#get())
  if get(a:, 1, '') =~# '\ctodo'
    let keywords = keywords[0]
  elseif get(a:, 1, '') =~# '\cdone'
    let keywords = keywords[1]
  elseif get(a:, 1, '') =~# '\call'
    let keywords = keywords[0] + keywords[1]
  endif
  return keywords
endfunction

function! org#keyword#get() abort " {{{1
  " org_keywords augroup defined in plugin/org.vim, resets b:org_keywords
  let [todo, done] = [[], []]
  let cursor = getcurpos()[1:]
  call cursor(1, 1)
  while search('^#+TODO:', 'zcWe')
    let [t, d] = org#keyword#parse(getline('.'))
    call extend(todo, t)
    call extend(done, d)
  endwhile
  call cursor(cursor)
  let b:org_keywords = [empty(todo) ? ['TODO'] : todo, empty(done) ? ['DONE'] : done]
  return b:org_keywords
endfunction

function! org#keyword#parse(text) abort " {{{1
  let [todo, done] = matchlist(a:text, g:org#regex#todo)[1:2]
  return [split(todo), split(done)]
endfunction

function! org#keyword#highlight() abort " {{{1
  let [todo, done] = org#keyword#all()
  silent! syntax clear orgTodo orgDone
  " TODO add user defined groups. pretty straightforward, if config scheme updated.
  execute 'syntax keyword orgTodo ' . join(todo) . ' containedin=orgHeadlineKeywords,@orgHeadline'
  execute 'syntax keyword orgDone ' . join(done) . ' containedin=orgHeadlineKeywords,@orgHeadline'
endfunction
