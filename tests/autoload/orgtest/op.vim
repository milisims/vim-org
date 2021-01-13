function! orgtest#op#lowerlevelhl() abort " {{{1
  call assert_report('Test not implemented')
  let text =<< ENDFTORG
* A

** B

ENDFTORG
  call setline(1, text)
  2
  call org#op#lowerlevelhl(1, 1, 'n')
  call assert_equal(1, getcurpos()[1])
  3
  call org#op#lowerlevelhl(1, 1, 'n')
  call assert_equal(1, getcurpos()[1])
  4
  call org#op#lowerlevelhl(1, 1, 'n')
  call assert_equal(3, getcurpos()[1])
endfunction

function! orgtest#op#nexthl() abort " {{{1
  call assert_report('Test not implemented')
  1
  call org#op#nexthl(2, 1, 0, 'n')
  call assert_equal(10, getcurpos()[1])
  11call org#headline#promote(2)
  normal! v
  call org#op#nexthl(1, 1, 1, 'v')
  call assert_equal(13, getcurpos()[1])
  call assert_equal(10, getpos("'[")[1])
  call assert_equal(13, getpos("']")[1])
endfunction

