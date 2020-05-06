function! org#op#keyword(up) abort " {{{1
  " let reg_save = @@ " not sure waht

  let lnum = org#headline#find('.', 0, 'nbW')
  if a:up
    while empty(org#keyword#parse(getline(lnum))) && org#headline#level(lnum) > 1
      let lnum = org#headline#find(lnum, 0, 'nbxW')
    endwhile
  endif
  if org#keyword#checktext(getline(lnum))
    normal! m`
    call cursor([lnum, 1])
    normal! wve
    if v:operator == 'd'
      normal! oho
    endif
  else
    if v:operator == 'y'
      return
    endif
    normal! m`
    call cursor([lnum, matchend(getline(lnum), '\**') + 1])
    normal! v
    if v:operator == 'c'
      call feedkeys("\<C-r>\"\<C-g>U\<Left>\<Space>")
    endif
  endif

endfunction

function! org#op#lowerlevelhl(count1, direction, mode) abort " {{{1
  if a:mode == 'n'
    normal! m`
  elseif a:mode == 'v'
    normal! gv
  endif
  let flags = a:direction > 0 ? '' : 'b'
  for i in range(a:count1)
    call org#headline#find(line('.'), org#headline#level('.') - 1, flags)
  endfor
endfunction

function! org#op#nexthl(count1, direction, same_level, mode) abort " {{{1
  if a:mode == 'n'
    normal! m`
  elseif a:mode == 'v'
    normal! gv
  endif
  let flags = a:direction > 0 ? 'x' : 'xb'
  let level = a:same_level ? org#headline#level('.') : 0
  for i in range(a:count1)
    call org#headline#find('.', level, flags)
  endfor
  normal! 0
endfunction
