function! org#fold#expr(lnum) abort
  if org#headline#checkline(a:lnum)
    return '>' . org#headline#level(a:lnum)
  elseif org#headline#checkline(a:lnum + 1)
    return '<' . org#headline#level(a:lnum + 1)
  endif
  return '='
endfunction

function! org#fold#text() abort
  " Headline level, TODO, headline, schedule, tags. foldsize and fold level?
  let l:fs = v:foldstart
  while getline(l:fs) !~# '\w'
    let l:fs = nextnonblank(l:fs + 1)
  endwhile
  if l:fs > v:foldend
    let l:line = getline(v:foldstart)
  else
    let l:line = substitute(getline(l:fs), '\t', repeat(' ', &tabstop), 'g')
  endif

  let l:w = winwidth(0) - &foldcolumn - &number * &numberwidth
  let l:foldSize = 1 + v:foldend - v:foldstart
  let l:foldSizeStr = ' ' . l:foldSize . ' lines '
  let l:foldLevelStr = repeat('  +  ', v:foldlevel)
  let l:lineCount = line('$')
  let l:expansionString = repeat(' ', l:w - strwidth(l:foldSizeStr.l:line.l:foldLevelStr))
  return l:line . l:expansionString . l:foldSizeStr . l:foldLevelStr
endfunction
