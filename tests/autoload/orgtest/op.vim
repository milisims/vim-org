function! orgtest#op#lowerlevelhl() abort " {{{1
  let text =<< ENDFTORG
#+TODO: X Y | Z

* A
<2020-01-01 Wed>
:PROPERTIES:
:aaa: 1
:bbb: abc
:END:

* X B
Hi.

* C
D
- E
** F
ENDFTORG
  return orgtest#fsetup('headline', text)
  6
  call org#op#lowerlevelhl(1, 1, 'n')
  call assert_equal(3, getcurpos()[1])
  16
  call org#op#lowerlevelhl(1, 1, 'n')
  call assert_equal(13, getcurpos()[1])
endfunction

function! orgtest#op#nexthl() abort " {{{1
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

