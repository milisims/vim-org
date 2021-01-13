function! orgtest#headline#add() abort " {{{1
  call setline(1, [1, 2, 3, 4, 5])
  3call org#headline#add(2, 'text')
  call assert_equal('** text', getline(4))
endfunction

function! orgtest#headline#astarget() abort " {{{1
  " if get(g:, 'orgtest#stdout', 0)
  "   call assert_report('Unable to test: org#headline#astarget uses org#dir & filenames')
  "   return
  " endif
  let fname = tempname() . '.org'
  execute 'write' fname
  call setline(1, ['* A', '** B', '*** C', '* D'])
  call assert_equal(fname . '/A',     org#headline#astarget(1))
  call assert_equal(fname . '/A/B',   org#headline#astarget(2))
  call assert_equal(fname . '/A/B/C', org#headline#astarget(3))
  call assert_equal(fname . '/D',     org#headline#astarget(4))
  let b:org_dir = join(split(fname, '[^\\]\zs/', 1)[:-2], '/')
  call assert_equal(split(fname, '/')[-1] . '/A' , org#headline#astarget(1))
  " Cleanup
  call delete(fname)
endfunction

function! orgtest#headline#at() abort " {{{1
  call setline(1, ['', '* A', '', '** B'])
  call assert_equal(0, org#headline#at(0))
  call assert_equal(0, org#headline#at(1))
  call assert_equal(2, org#headline#at(2))
  call assert_equal(2, org#headline#at(3))
  call assert_equal(4, org#headline#at(4))
endfunction

function! orgtest#headline#checkline() abort " {{{1
  call setline(1, ['', '* A', '', '** B'])
  call assert_false(org#headline#checkline(1))
  call assert_true(org#headline#checkline(2))
  call assert_false(org#headline#checkline(3))
  call assert_true(org#headline#checkline(4))
endfunction

function! orgtest#headline#checktext() abort " {{{1
  call assert_true(org#headline#checktext('* a'))
  call assert_false(org#headline#checktext(' * a'))
  call assert_false(org#headline#checktext('a'))
endfunction

function! orgtest#headline#demote() abort " {{{1
  call setline(1, ['* A', '** B'])
  1call org#headline#demote()
  call assert_equal('A', getline(1))
  2call org#headline#demote()
  call assert_equal('* B', getline(2))
endfunction

function! orgtest#headline#find() abort " {{{1
  call setline(1, ['', '* A', '', '** B', '* C'])
  call assert_equal(2, org#headline#find(1))
  call assert_equal(5, org#headline#find(3, 1))
endfunction

function! orgtest#headline#format() abort " {{{1
  call assert_report('orgtest#headline#format not implemented')
  " call assert_equal(, org#headline#format(lnum))
endfunction

function! orgtest#headline#fromtarget() abort " {{{1
  let fname = tempname() . '.org'
  execute 'write' fname
  call setline(1, ['* A', '** B', '*** C', '* D'])
  call assert_equal(getline(3), org#headline#fromtarget(fname . '/A/B/C').text)
  let b:org_dir = join(split(fname, '[^\\]\zs/', 1)[:-2], '/')
  call assert_equal(getline(3), org#headline#fromtarget(split(fname, '/')[-1] . '/A/B/C').text)
  " Cleanup
  call delete(fname)
endfunction

function! orgtest#headline#get() abort " {{{1
  call setline(1, ['* DONE A', '<2020-01-01 Wed>', ':PROPERTIES:', ':aaa: 1', ':bbb: abc', ':END:'])
  let fname = tempname() . '.org'
  execute 'write' fname
  let hl = org#headline#get(1, {'todo': ['TODO'], 'done': ['DONE'], 'all': ['TODO', 'DONE']})
  call assert_equal(bufnr(), hl.bufnr)
  call assert_equal(1, hl.lnum)

  call assert_equal(1,                  hl.plan.TIMESTAMP.active)
  call assert_equal(1577854800,         hl.plan.TIMESTAMP.start)
  call assert_equal(1577854800,         hl.plan.TIMESTAMP.end)
  call assert_equal({},                 hl.plan.TIMESTAMP.delay)
  call assert_equal({},                 hl.plan.TIMESTAMP.repeater)
  call assert_equal({'aaa': '1', 'bbb': 'abc'}, hl.properties)

  call delete(fname)
endfunction

function! orgtest#headline#level() abort " {{{1
  call setline(1, ['* A', '** B', '*** C', '** D'])
  call assert_equal(1, org#headline#level(1))
  call assert_equal(2, org#headline#level(2))
  call assert_equal(3, org#headline#level(3))
  call assert_equal(2, org#headline#level(4))
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
  call setline(1, ['* A', 'B', 'C', '** D'])
  1,4call org#headline#promote()
  call assert_equal(getline(1, 4), ['** A', '* B', '* C', '*** D'])
endfunction
