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

function! orgtest#headline#add() abort " {{{1
  call s:setup()
  1call org#headline#add(2, 'text')
  call assert_equal('** text', getline(2))
endfunction

function! orgtest#headline#astarget() abort " {{{1
  let myd = s:setup()
  call assert_equal(myd.fname . '/A', org#headline#astarget(3))
  call assert_equal(myd.fname . '/B', org#headline#astarget(10))
  call assert_equal(myd.fname . '/C', org#headline#astarget(13))
  let b:org_dir = join(split(myd.fname, '[^\\]/', 1)[:-2], '/')
  call assert_equal(split(myd.fname)[-1] . '/C/F', org#headline#astarget(16))
endfunction

function! orgtest#headline#at() abort " {{{1
  call s:setup()
  call assert_equal(0, org#headline#at(0))
  call assert_equal(0, org#headline#at(1))
  call assert_equal(3, org#headline#at(3))
  call assert_equal(3, org#headline#at(5))
  call assert_equal(10, org#headline#at(10))
  call assert_equal(16, org#headline#at(16))
  call assert_equal(0, org#headline#at(1))
endfunction

function! orgtest#headline#checkline() abort " {{{1
  call s:setup()
  call assert_false(org#headline#checkline(1))
  call assert_false(org#headline#checkline(2))
  call assert_true(org#headline#checkline(3))
  call assert_false(org#headline#checkline(4))
  call assert_false(org#headline#checkline(5))
  call assert_false(org#headline#checkline(6))
  call assert_false(org#headline#checkline(7))
  call assert_false(org#headline#checkline(8))
  call assert_false(org#headline#checkline(9))
  call assert_true(org#headline#checkline(10))
  call assert_false(org#headline#checkline(11))
  call assert_false(org#headline#checkline(12))
  call assert_true(org#headline#checkline(13))
  call assert_false(org#headline#checkline(14))
  call assert_false(org#headline#checkline(15))
  call assert_true(org#headline#checkline(16))
endfunction

function! orgtest#headline#checktext() abort " {{{1
  call s:setup()
  call assert_true(org#headline#checktext('* a'))
  call assert_false(org#headline#checktext(' * a'))
  call assert_false(org#headline#checktext('a'))
endfunction

function! orgtest#headline#demote() abort " {{{1
  call s:setup()
  " Demote D d E F (nothing on d)
  13call org#headline#demote()
  call assert_equal('C', getline(13))
  16call org#headline#demote()
  call assert_equal('* F', getline(16))
endfunction

function! orgtest#headline#find() abort " {{{1
  call s:setup()
  call assert_equal(3, org#headline#find(1))
  call assert_equal(3, org#headline#find(3))
  call assert_equal(10, org#headline#find(5))
endfunction

function! orgtest#headline#format() abort " {{{1
  call assert_report('orgtest#headline#format not implemented')
  " call assert_equal(, org#headline#format(lnum))
endfunction


function! orgtest#headline#fromtarget() abort " {{{1
  let myd = s:setup()
  execute 'silent! write' myd.fname . '.org'
  execute 'silent! edit' myd.fname . '.org'
  " .org extension is important for target splitting.
  call assert_equal(org#headline#get(3), org#headline#fromtarget(myd.fname . '.org/A'))
  call assert_equal(org#headline#get(13), org#headline#fromtarget(myd.fname . '.org/C'))
  call assert_equal(org#headline#get(16), org#headline#fromtarget(myd.fname . '.org/C/F'))
  let b:org_dir = join(split(myd.fname, '[^\\]/', 1)[:-2], '/')
  call assert_equal(org#headline#get(10), org#headline#fromtarget(split(myd.fname)[-1] . '.org/B'))
  execute "normal! \<C-^>"
  execute 'silent bwipeout!' myd.fname . '.org'
endfunction

function! orgtest#headline#get() abort " {{{1
  call s:setup()
  let hl = org#headline#get(3)
  call assert_equal(bufnr(), hl.bufnr)
  call assert_equal(3, hl.lnum)
  call assert_equal({'active': 1, 'end': 1577854800, 'repeater': {}, 'text': '<2020-01-01 Wed>', 'start': 1577854800, 'delay': {}}, hl.plan.TIMESTAMP)
  " call assert_equal({'TIMESTAMP': '', 'SCHEDULED': '', 'DEADLINE': '', 'CLOSED': ''}, hl.plan.TIMESTAMP)
  call assert_equal({'aaa': '1', 'bbb': 'abc'}, hl.properties)
endfunction

function! orgtest#headline#level() abort " {{{1
  call s:setup()
  call assert_equal(0, org#headline#level(2))
  call assert_equal(1, org#headline#level(4))
  call assert_equal(2, org#headline#level(16))
endfunction

function! orgtest#headline#parse() abort " {{{1
  let hl = org#headline#parse('** A [#C] a /''\ b :c:d:', {'todo': ['A'], 'done': ['B'], 'all': ['A', 'B']})
  call assert_equal(2, hl.level)
  call assert_equal('A', hl.keyword)
  call assert_equal(0, hl.done)
  call assert_equal('C', hl.priority)
  call assert_equal('a /''\ b', hl.item)
  call assert_equal('** A [#C] a /''\ b :c:d:', hl.text)  " checks escaping
  call assert_equal(['c', 'd'], hl.tags)
endfunction

function! orgtest#headline#promote() abort " {{{1
  call s:setup()
  " Promote D d E F
  13,16 call org#headline#promote()
  call assert_equal(['** C', '* D', '* E', '*** F'], getline(13, 16))
endfunction

function! orgtest#headline#subtree() abort " {{{1
  call s:setup()
  let st = org#headline#subtree(13)
  " checking for properly set up tree, not for the items
  call assert_equal(org#headline#get(13), st[0])
  call assert_equal([], st[1][0][1])
  call assert_equal(org#headline#get(16), st[1][0][0])
endfunction

