function! org#edit#openhl(direction) abort " {{{1
  if a:direction < 0
    let [level, lnum] = org#headline#level('.', 1)
    let level = level == 0 ? 1 : level
    let next = max([lnum - 1, 0])  " 0 - 1 if headline not found
  else
    let [level, prev] = org#headline#level('.', 1)
    let level = level == 0 ? 1 : level
    let next = org#headline#find(prev, level, 'xnW')
    " If no match found, we're at end of file. Also subtract 1 so it's above the match.
    let next = next == 0 ? prevnonblank(line('$')) : next - 1
    " If the headlines are neighbors, don't add empty spaces.
  endif
  call org#headline#add(next, level, ' ')
  call cursor(next + 1, level + 2)
  startinsert!

  doautocmd User OrgFormat  " ???
endfunction
