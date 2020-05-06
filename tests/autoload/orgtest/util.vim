
function! orgtest#util#search() abort " {{{1
  call orgtest#fsetup('search', range(11, 121, 11))
  " tests: x, test wrapping, lnum <= 0 && lnum > line($)
  " also, stopline, timeout
  1
  call assert_equal(2, org#util#search('.', '2', 'nx', 4))
  call assert_equal(1, getcurpos()[1])
  call assert_equal(6, org#util#search(5, '\d', 'nx', 7))
  call assert_equal(1, getcurpos()[1])
endfunction

function! orgtest#util#format() abort " {{{1
  call assert_report('Not yet implemented.')
  " call org#util#format(...)
endfunction

function! orgtest#util#seqsortfunc() abort " {{{1
  call assert_report('Not yet implemented.')
  " call org#util#seqsortfunc(properties, ...)
endfunction

