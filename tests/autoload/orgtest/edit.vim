function! s:setup() abort
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
endfunction

function! orgtest#edit#openhl() abort " {{{1
  " TODO should this test specifically a function call? or just refactor it out of the api?
  " Probably the latter.
  call feedkeys("14gg\<Plug>(org-headline-open-below)abc\<Esc>")
  call feedkeys("16gg\<Plug>(org-headline-open-above)def\<Esc>")
  call assert_equal('* def', getline(16))
  call assert_equal('* abc', getline(17))
endfunction
