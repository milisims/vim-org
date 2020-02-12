function! org#fold#expr(lnum) abort " {{{1
  if org#headline#checkline(a:lnum)
    return '>' . org#headline#level(a:lnum)
  elseif org#headline#checkline(a:lnum + 1)
    return '<' . org#headline#level(a:lnum + 1)
  endif
  return '='
endfunction


function! org#fold#text(...) abort " {{{1
  " TODO : schedule?
  let foldstart = get(a:, 1, v:foldstart)
  let foldend = get(a:, 2, v:foldend)
  let foldlevel = get(a:, 3, v:foldlevel)
  if winwidth(0) < 10
    return getline(foldstart)
  endif

  let hl = org#headline#get(foldstart)

  let tagstr = empty(hl.TAGS) ? '' : ':' . join(hl.TAGS, ':') . ':'
  let linestr = ' ' . (1 + foldend - foldstart) . ' lines '
  let linestr_len = max([strwidth(linestr) + 1, 10])
  let linestr_spacing = repeat(' ', linestr_len - strwidth(linestr))

  let timestr = ''
  let plan = org#timestamp#nearest_plan(hl)
  if !empty(plan)
    let timestr = (plan[0] =~# '^T' ? '' : plan[0][0]) . plan[1].text
  endif

  let width = winwidth(0) - &foldcolumn - &number * &numberwidth - 2
  let maxlen = width - strwidth(tagstr . timestr) - linestr_len - 5

  let maintext = matchstr(getline(foldstart), '\v^\*+.{-}\ze%(:%([[:alpha:]_@#%]+:)+)?\s*$')
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
