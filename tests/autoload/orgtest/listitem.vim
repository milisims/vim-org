function! s:setup() abort
  let text =<< ENDFTORG
  + A
    a

  - B
    * B.1
  - [ ] D

  1. E
    - E.1
    - E.2
  2. [ ] F
  3. [X] G
  4. [x] H

ENDFTORG
  return orgtest#fsetup('listitem', text)
endfunction

function! orgtest#listitem#append() abort " {{{1
  call s:setup()
  call org#listitem#append(14, 'Z') " new list
  call assert_equal('  - Z', getline(15))
  call org#listitem#append(12, 'G.a')  " default checkbox as previous.
  call assert_equal('  3. [X] G',   getline(12))
  call assert_equal('  4. [ ] G.a', getline(13))
  call assert_equal('  4. [x] H',   getline(14))
  call org#listitem#append(9, 'E.1.a')  " sublist
  call assert_equal('    - E.1',   getline(9))
  call assert_equal('    - E.1.a', getline(10))
  call assert_equal('    - E.2',   getline(11))
  call org#listitem#append(8, 'E.a', 1) " reorder & placement after full item
  call assert_equal('  1. E',       getline(8))
  call assert_equal('    - E.1',    getline(9))
  call assert_equal('    - E.1.a',  getline(10))
  call assert_equal('    - E.2',    getline(11))
  call assert_equal('  2. E.a',     getline(12))
  call assert_equal('  3. [ ] F',   getline(13))
  call assert_equal('  4. [X] G',   getline(14))
  call assert_equal('  5. [ ] G.a', getline(15))
  call assert_equal('  6. [x] H',   getline(16))
  call org#listitem#append(2, 'A.a') " add to item lines should still pick up list type
  call assert_equal('    a', getline(2))
  call assert_equal('  + A.a', getline(3))
endfunction

function! orgtest#listitem#bullet_cycle() abort " {{{1
  call s:setup()
  call org#listitem#bullet_cycle(1, -1)
  call assert_equal('  - A', getline(1))
  call org#listitem#bullet_cycle(4, 2)
  call assert_equal('  * B', getline(4))
  call org#listitem#bullet_cycle(4, 1)
  call assert_equal('  - B', getline(4))
endfunction

function! orgtest#listitem#checkline() abort " {{{1
  call s:setup()
  call assert_true(org#listitem#checkline(1))
  call assert_true(org#listitem#checkline(2))
  call assert_false(org#listitem#checkline(3))
  call assert_true(org#listitem#checkline(4))
  call assert_true(org#listitem#checkline(5))
  call assert_true(org#listitem#checkline(6))
  call assert_false(org#listitem#checkline(7))
  call assert_true(org#listitem#checkline(8))
  call assert_true(org#listitem#checkline(9))
  call assert_true(org#listitem#checkline(10))
  call assert_true(org#listitem#checkline(11))
  call assert_true(org#listitem#checkline(12))
  call assert_true(org#listitem#checkline(13))
  call assert_false(org#listitem#checkline(14))
endfunction

function! orgtest#listitem#end() abort " {{{1
  call s:setup()
  call assert_equal(2, org#listitem#end(1))
  call assert_equal(2, org#listitem#end(2))
  call assert_equal(0, org#listitem#end(3))
  call assert_equal(5, org#listitem#end(4))
  call assert_equal(5, org#listitem#end(5))
  call assert_equal(6, org#listitem#end(6))
  call assert_equal(0, org#listitem#end(7))
  call assert_equal(10, org#listitem#end(8))
  call assert_equal(9, org#listitem#end(9))
  call assert_equal(10, org#listitem#end(10))
  call assert_equal(11, org#listitem#end(11))
  call assert_equal(12, org#listitem#end(12))
  call assert_equal(13, org#listitem#end(13))
  call assert_equal(0, org#listitem#end(14))
endfunction

function! orgtest#listitem#get_bullet() abort " {{{1
  call s:setup()
  call assert_equal('+', org#listitem#get_bullet(1))
  call assert_equal('', org#listitem#get_bullet(2))
  call assert_equal('', org#listitem#get_bullet(3))
  call assert_equal('-', org#listitem#get_bullet(4))
  call assert_equal('*', org#listitem#get_bullet(5))
  call assert_equal('-', org#listitem#get_bullet(6))
  call assert_equal('1.', org#listitem#get_bullet(8))
  call assert_equal('-', org#listitem#get_bullet(9))
  call assert_equal('-', org#listitem#get_bullet(10))
  call assert_equal('2.', org#listitem#get_bullet(11))
endfunction

function! orgtest#listitem#has_bullet() abort " {{{1
  call assert_true(org#listitem#has_bullet('- A'))
  call assert_true(org#listitem#has_bullet('+ A'))
  call assert_true(org#listitem#has_bullet(' * A'))
  call assert_false(org#listitem#has_bullet('* A'))
  call assert_true(org#listitem#has_bullet('A.'))
  call assert_false(org#listitem#has_bullet(' A'))
  call assert_true(org#listitem#has_bullet('3. A'))
  call assert_true(org#listitem#has_bullet('c. A'))
  call assert_true(org#listitem#has_bullet('C. A'))
endfunction

function! orgtest#listitem#has_ordered_bullet() abort " {{{1
  call assert_false(org#listitem#has_ordered_bullet('-. A'))
  call assert_false(org#listitem#has_ordered_bullet('- A'))
  call assert_true(org#listitem#has_ordered_bullet('3. A'))
  call assert_true(org#listitem#has_ordered_bullet('c. A'))
  call assert_true(org#listitem#has_ordered_bullet('C. A'))
endfunction

function! orgtest#listitem#has_unordered_bullet() abort " {{{1
  call assert_true(org#listitem#has_unordered_bullet('- A'))
  call assert_true(org#listitem#has_unordered_bullet('+ A'))
  call assert_true(org#listitem#has_unordered_bullet(' * A'))
  call assert_false(org#listitem#has_unordered_bullet('* A'))
endfunction

function! orgtest#listitem#indent() abort " {{{1
  call s:setup()
  1call org#listitem#indent(1)
  call assert_equal('    + A', getline(1))
  call assert_equal('      a', getline(2))
  1call org#listitem#indent(-3)
  call assert_equal('+ A', getline(1))
  call assert_equal('  a', getline(2))
  " undo changes so 3 is not part of a list
  normal! u
  3,9call org#listitem#indent(-1)
  call assert_equal(''          , getline(3))
  call assert_equal('- B'       , getline(4))
  call assert_equal('  * B.1'   , getline(5))
  call assert_equal('- [ ] D'   , getline(6))
  call assert_equal(''          , getline(7))
  call assert_equal('1. E'      , getline(8))
  call assert_equal('  - E.1'   , getline(9))
  call assert_equal('  - E.2'   , getline(10))
  call assert_equal('  2. [ ] F', getline(11))
endfunction

function! orgtest#listitem#is_ordered() abort " {{{1
  call s:setup()
  call assert_false(org#listitem#is_ordered(1))
  call assert_false(org#listitem#is_ordered(2))
  call assert_false(org#listitem#is_ordered(3))
  call assert_false(org#listitem#is_ordered(4))
  call assert_false(org#listitem#is_ordered(5))
  call assert_false(org#listitem#is_ordered(6))
  call assert_false(org#listitem#is_ordered(7))
  call assert_true(org#listitem#is_ordered(8))
  call assert_false(org#listitem#is_ordered(9))
  call assert_false(org#listitem#is_ordered(10))
  call assert_true(org#listitem#is_ordered(11))
  call assert_true(org#listitem#is_ordered(12))
  call assert_true(org#listitem#is_ordered(13))
  call assert_false(org#listitem#is_ordered(14))
endfunction

function! orgtest#listitem#is_unordered() abort " {{{1
  call s:setup()
  call assert_true(org#listitem#is_unordered(1))
  call assert_true(org#listitem#is_unordered(2))
  call assert_false(org#listitem#is_unordered(3))
  call assert_true(org#listitem#is_unordered(4))
  call assert_true(org#listitem#is_unordered(5))
  call assert_true(org#listitem#is_unordered(6))
  call assert_false(org#listitem#is_unordered(7))
  call assert_false(org#listitem#is_unordered(8))
  call assert_true(org#listitem#is_unordered(9))
  call assert_true(org#listitem#is_unordered(10))
  call assert_false(org#listitem#is_unordered(11))
  call assert_false(org#listitem#is_unordered(12))
  call assert_false(org#listitem#is_unordered(13))
  call assert_false(org#listitem#is_unordered(14))
endfunction

function! orgtest#listitem#level() abort " {{{1
  call s:setup()
  call assert_equal(1, org#listitem#level(1))
  call assert_equal(1, org#listitem#level(2))
  call assert_equal(0, org#listitem#level(3))
  call assert_equal(1, org#listitem#level(4))
  call assert_equal(2, org#listitem#level(5))
  call assert_equal(1, org#listitem#level(6))
  call assert_equal(0, org#listitem#level(7))
  call assert_equal(1, org#listitem#level(8))
  call assert_equal(2, org#listitem#level(9))
  call assert_equal(2, org#listitem#level(10))
  call assert_equal(1, org#listitem#level(11))
  call assert_equal(1, org#listitem#level(12))
  call assert_equal(1, org#listitem#level(13))
  call assert_equal(0, org#listitem#level(14))
endfunction

function! orgtest#listitem#parent() abort " {{{1
  call s:setup()
  call assert_equal(0, org#listitem#parent(1))
  call assert_equal(0, org#listitem#parent(2))
  call assert_equal(0, org#listitem#parent(3))
  call assert_equal(0, org#listitem#parent(4))
  call assert_equal(4, org#listitem#parent(5))
  call assert_equal(0, org#listitem#parent(6))
  call assert_equal(0, org#listitem#parent(7))
  call assert_equal(0, org#listitem#parent(8))
  call assert_equal(8, org#listitem#parent(9))
  call assert_equal(8, org#listitem#parent(10))
  call assert_equal(0, org#listitem#parent(11))
  call assert_equal(0, org#listitem#parent(12))
  call assert_equal(0, org#listitem#parent(13))
  call assert_equal(0, org#listitem#parent(14))
endfunction

function! orgtest#listitem#range() abort " {{{1
  call s:setup()
  call assert_equal([1, 2], org#listitem#range(1))
  call assert_equal([1, 2], org#listitem#range(2))
  call assert_equal([0, 0], org#listitem#range(3))
  call assert_equal([4, 5], org#listitem#range(4))
  call assert_equal([5, 5], org#listitem#range(5))
  call assert_equal([6, 6], org#listitem#range(6))
  call assert_equal([0, 0], org#listitem#range(7))
  call assert_equal([8, 10], org#listitem#range(8))
  call assert_equal([9, 9], org#listitem#range(9))
  call assert_equal([10, 10], org#listitem#range(10))
  call assert_equal([11, 11], org#listitem#range(11))
  call assert_equal([12, 12], org#listitem#range(12))
  call assert_equal([13, 13], org#listitem#range(13))
  call assert_equal([0, 0], org#listitem#range(14))

  call append(2, ['', '    a', '', '    a'])
  call assert_equal([1, 6], org#listitem#range(1))
  call assert_equal([1, 6], org#listitem#range(2))
  call assert_equal([1, 6], org#listitem#range(3))
  call assert_equal([1, 6], org#listitem#range(4))
  call assert_equal([1, 6], org#listitem#range(5))
  call assert_equal([1, 6], org#listitem#range(6))

endfunction

function! orgtest#listitem#start() abort " {{{1
  call s:setup()
  call assert_equal(1, org#listitem#start(1))
  call assert_equal(1, org#listitem#start(2))
  call assert_equal(0, org#listitem#start(3))
  call assert_equal(4, org#listitem#start(4))
  call assert_equal(5, org#listitem#start(5))
endfunction

function! orgtest#listitem#text() abort " {{{1
  call s:setup()
  call assert_equal(['A', 'a'], org#listitem#text(1))
  call assert_equal(['A', 'a'], org#listitem#text(2))
  call assert_equal('', org#listitem#text(3))
  call assert_equal(['B', '* B.1'], org#listitem#text(4))
  call assert_equal('B.1', org#listitem#text(5))
  call assert_equal('D', org#listitem#text(6))
  call assert_equal(['E', '- E.1', '- E.2'], org#listitem#text(8))
  call assert_equal('E.1', org#listitem#text(9))
  call assert_equal('E.2', org#listitem#text(10))
  call assert_equal('F', org#listitem#text(11))
  call assert_equal('G', org#listitem#text(12))
  call assert_equal('H', org#listitem#text(13))
endfunction
