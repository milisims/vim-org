function! org#fold#expr(lnum) abort " {{{1
  if org#headline#checkline(a:lnum)
    return '>' . org#headline#level(a:lnum)
  elseif org#headline#checkline(a:lnum + 1)
    return '<' . org#headline#level(a:lnum + 1)
  elseif getline(a:lnum) =~# '^\s*:PROPERTIES:$'
    return 'a1'
  elseif getline(a:lnum) =~# '^\s*:END:$'
    return 's1'
  endif
  return '='
endfunction

function! org#fold#text() abort " {{{1
  " TODO : schedule?
  if winwidth(0) < 10
    return getline(v:foldstart)
  endif

  if org#headline#checkline(v:foldstart)
    return s:headline_text()
  elseif org#property#isindrawer(v:foldstart)
    return s:propertydrawer_text()
  endif
  return getline(v:foldstart)
endfunction

function! s:headline_text() abort " {{{1
  " TODO use org#agenda (rename to org#tree?)
  let [maintext, tagstr] = matchlist(getline(v:foldstart), '\v^(\*+.{-})\s*(:%([[:alpha:]_@#%]+:)+)?\s*$')[1:2]
  let level = matchend(maintext, '^\**')
  let maintext = repeat('-', level - 1) . maintext[level - 1 :]
  let linestr = ' ' . (1 + v:foldend - v:foldstart) . ' lines '
  let linestr_len = max([strwidth(linestr) + 1, 10])
  let linestr_spacing = repeat(' ', linestr_len - strwidth(linestr))

  let timestr = ''
  let plan = (hl)
  if !empty(plan)
    let timestr = (plan[0] =~# '^T' ? '' : plan[0][0]) . plan[1].text
  endif

  let width = winwidth(0) - &foldcolumn - &number * &numberwidth - 2
  let maxlen = width - strwidth(tagstr . timestr) - linestr_len - 5

  if strwidth(maintext) > maxlen
    let maintext = split(maintext, '\s\zs')
    let hltext = remove(maintext, 0)
    while !empty(maintext) && strwidth(hltext) + strwidth(maintext[0]) <= maxlen
      let hltext .= remove(maintext, 0)
    endwhile
    let maintext = hltext . ' ...'
  else
    let maintext = maintext . ' ...'
  endif

  let mid_space = repeat(' ', width - linestr_len - strwidth(maintext . tagstr . timestr))
  return maintext . mid_space . tagstr . timestr . linestr_spacing . linestr
endfunction

function! s:propertydrawer_text() abort " {{{1
  let [lstart, lend] = org#property#drawer_range(v:foldstart)
  let propstr = (lend - lstart - 1)
  let propstr .= ' propert' . (propstr == 1 ? 'y' : 'ies')
  let width = winwidth(0) - &foldcolumn - &number * &numberwidth - 2
  let spacer = repeat(' ', width - 17 - strwidth(propstr) - 1)
  return ':PROPERTIES:  ...' . spacer . propstr . ' '
endfunction
