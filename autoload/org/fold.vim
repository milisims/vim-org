function! org#fold#expr(lnum) abort " {{{1
  if org#headline#checkline(a:lnum)
    return '>' . org#headline#level(a:lnum)
  elseif org#headline#checkline(a:lnum + 1)
    return '<' . org#headline#level(a:lnum + 1)
  endif
  return '='
endfunction

function! org#fold#text() abort " {{{1
  " Headline level, TODO, headline, schedule, tags. foldsize and fold level?
  let fs = v:foldstart
  while getline(fs) !~# '\w'
    let fs = nextnonblank(fs + 1)
  endwhile
  if fs > v:foldend
    let line = getline(v:foldstart)
  else
    let line = substitute(getline(fs), '\t', repeat(' ', &tabstop), 'g')
  endif

  let w = winwidth(0) - &foldcolumn - &number * &numberwidth
  let foldSize = 1 + v:foldend - v:foldstart
  let foldSizeStr = ' ' . foldSize . ' lines '
  let foldLevelStr = repeat('  +  ', v:foldlevel)
  let lineCount = line('$')
  let expansionString = repeat(' ', w - strwidth(foldSizeStr.line.foldLevelStr))
  return line . expansionString . foldSizeStr . foldLevelStr
endfunction
