function! org#fold#expr(lnum) abort " {{{1
  if org#headline#checkline(a:lnum)
    return '>' . org#headline#level(a:lnum)
  elseif org#headline#checkline(a:lnum + 1)
    return '<' . org#headline#level(a:lnum + 1)
  elseif getline(a:lnum) =~# '^:PROPERTIES:$'
    return '>' . (org#headline#level(a:lnum) + 1)
  elseif getline(a:lnum) =~# '^:END:$' && org#property#drawer_range(a:lnum)[1] == line(a:lnum)
    return '<' . (org#headline#level(a:lnum) + 1)
  endif
  return '='
endfunction

function! org#fold#text(...) abort " {{{1
  " TODO : schedule?
  let fold = {'start': get(a:, 1, v:foldstart), 'end': get(a:, 2, v:foldend), 'level': get(a:, 3, v:foldlevel)}
  if winwidth(0) < 10
    return getline(foldstart)
  endif

  if org#headline#checkline(fold.start)
    return s:headline_text(fold)
  elseif org#property#isindrawer(fold.start)
    return s:propertydrawer_text(fold)
  endif
  return getline(fold.start)
endfunction

function! s:headline_text(fold) abort " {{{2
  " TODO use org#agenda (rename to org#tree?)
  let [maintext, tagstr] = matchlist(getline(a:fold.start), '\v^(\*+.{-})\s*(:%([[:alpha:]_@#%]+:)+)?\s*$')[1:2]
  let linestr = ' ' . (1 + a:fold.end - a:fold.start) . ' lines '
  let linestr_len = max([strwidth(linestr) + 1, 10])
  let linestr_spacing = repeat(' ', linestr_len - strwidth(linestr))

  let timestr = ''
  let plan = org#timestamp#nearest_plan(hl)
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
  endif

  let mid_space = repeat(' ', width - linestr_len - strwidth(maintext . tagstr . timestr))
  return maintext . mid_space . tagstr . timestr . linestr_spacing . linestr
endfunction

function! s:propertydrawer_text(fold) abort " {{{2
  let [lstart, lend] = org#property#drawer_range(a:fold.start)
  let propstr = (lend - lstart - 2) . ' properties'
  let width = winwidth(0) - &foldcolumn - &number * &numberwidth - 2
  let spacer = repeat(' ', width - 17 - strwidth(propstr) - 1)
  return ':PROPERTIES:  ...' . spacer . propstr
endfunction
