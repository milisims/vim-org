let s:testdir = expand('<sfile>:p:h:h:h') . '/tests'

function! org#test#load() abort " {{{1
  if exists(':TestOrg')
    return
  endif
  let &runtimepath = s:testdir . ',' . &runtimepath
  runtime! plugin/orgtest.vim
  augroup orgtest
    autocmd BufEnter *.vim setlocal errorformat=%f::%l::%o::%t::%m
  augroup END
  if &filetype == 'vim'
    setlocal errorformat=%f::%l::%o::%t::%m
  endif
endfunction
