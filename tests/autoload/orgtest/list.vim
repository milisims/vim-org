function! s:setup() abort
  let text =<< ENDFTORG
  - A
  - B
    b
  - C
    * D
  + E
  * F
* G

  1. X
     - a
       - b
     - c
  1. Y
     + a
       + b
  3. Z


  1. [@2] X
  2. Y
  3. Z

  a. W
  a. X
  a. Y

  a. Z


  A. [@B] X
  A. Y
  A. Z

ENDFTORG
  call orgtest#fsetup('headline', text)
endfunction

function! orgtest#list#checkline() abort " {{{1
  call s:setup()
  call assert_true(org#list#checkline(1))
  call assert_true(org#list#checkline(2))
  call assert_true(org#list#checkline(3))
  call assert_true(org#list#checkline(4))
  call assert_true(org#list#checkline(5))
  call assert_true(org#list#checkline(6))
  call assert_true(org#list#checkline(7))
  call assert_false(org#list#checkline(8))
endfunction

function! orgtest#list#find() abort " {{{1

  call s:setup()

  call assert_equal(5, org#list#find(1))
  call assert_equal(5, org#list#find(2))
  call assert_equal(5, org#list#find(3))
  call assert_equal(5, org#list#find(4))
  call assert_equal(6, org#list#find(5))
  call assert_equal(7, org#list#find(6))
  call assert_equal(10, org#list#find(7))
  call assert_equal(10, org#list#find(8))
  call assert_equal(10, org#list#find(9))
  call assert_equal(11, org#list#find(10))
  call assert_equal(12, org#list#find(11))
  call assert_equal(15, org#list#find(12))
  call assert_equal(15, org#list#find(13))
  call assert_equal(15, org#list#find(14))
  call assert_equal(16, org#list#find(15))
  call assert_equal(20, org#list#find(16))
  call assert_equal(20, org#list#find(17))
  call assert_equal(20, org#list#find(18))
  call assert_equal(20, org#list#find(19))
  call assert_equal(24, org#list#find(20))
  call assert_equal(24, org#list#find(21))
  call assert_equal(24, org#list#find(22))
  call assert_equal(24, org#list#find(23))
  call assert_equal(31, org#list#find(24))
  call assert_equal(31, org#list#find(25))
  call assert_equal(31, org#list#find(26))
  call assert_equal(31, org#list#find(27))
  call assert_equal(31, org#list#find(28))
  call assert_equal(31, org#list#find(29))
  call assert_equal(31, org#list#find(30))
  call assert_equal(0, org#list#find(31, 'W'))
  call assert_equal(1, org#list#find(32, 'w'))
  call assert_equal(0, org#list#find(33, 'W'))
  call assert_equal(1, org#list#find(33, 'w'))
  call assert_equal(20, org#list#find(11, 'x'))
endfunction

function! orgtest#list#is_ordered() abort " {{{1
  call s:setup()
  call assert_false(org#list#is_ordered(1))
  call assert_false(org#list#is_ordered(2))
  call assert_false(org#list#is_ordered(3))
  call assert_false(org#list#is_ordered(4))
  call assert_false(org#list#is_ordered(5))
  call assert_false(org#list#is_ordered(6))
  call assert_false(org#list#is_ordered(7))
  call assert_false(org#list#is_ordered(8))
  call assert_false(org#list#is_ordered(9))
  call assert_true(org#list#is_ordered(10))
  call assert_false(org#list#is_ordered(11))
  call assert_false(org#list#is_ordered(12))
  call assert_false(org#list#is_ordered(13))
  call assert_true(org#list#is_ordered(14))
  call assert_false(org#list#is_ordered(15))
  call assert_false(org#list#is_ordered(16))
  call assert_true(org#list#is_ordered(17))
  call assert_false(org#list#is_ordered(18))
  call assert_false(org#list#is_ordered(19))
  call assert_true(org#list#is_ordered(20))
  call assert_true(org#list#is_ordered(21))
  call assert_true(org#list#is_ordered(22))
  call assert_false(org#list#is_ordered(23))
  call assert_true(org#list#is_ordered(24))
  call assert_true(org#list#is_ordered(25))
  call assert_true(org#list#is_ordered(26))
  call assert_true(org#list#is_ordered(27))
  call assert_true(org#list#is_ordered(28))
  call assert_false(org#list#is_ordered(29))
  call assert_false(org#list#is_ordered(30))
  call assert_true(org#list#is_ordered(31))
  call assert_true(org#list#is_ordered(32))
  call assert_true(org#list#is_ordered(33))
  call assert_false(org#list#is_ordered(34))
endfunction

function! orgtest#list#is_unordered() abort " {{{1
  call s:setup()
  call assert_true(org#list#is_unordered(1))
  call assert_true(org#list#is_unordered(2))
  call assert_true(org#list#is_unordered(3))
  call assert_true(org#list#is_unordered(4))
  call assert_true(org#list#is_unordered(5))
  call assert_true(org#list#is_unordered(6))
  call assert_true(org#list#is_unordered(7))
  call assert_false(org#list#is_unordered(8))
  call assert_false(org#list#is_unordered(9))
  call assert_false(org#list#is_unordered(10))
  call assert_true(org#list#is_unordered(11))
  call assert_true(org#list#is_unordered(12))
  call assert_true(org#list#is_unordered(13))
  call assert_false(org#list#is_unordered(14))
  call assert_true(org#list#is_unordered(15))
  call assert_true(org#list#is_unordered(16))
  call assert_false(org#list#is_unordered(17))
  call assert_false(org#list#is_unordered(18))
  call assert_false(org#list#is_unordered(19))
  call assert_false(org#list#is_unordered(20))
  call assert_false(org#list#is_unordered(21))
  call assert_false(org#list#is_unordered(22))
  call assert_false(org#list#is_unordered(23))
  call assert_false(org#list#is_unordered(24))
  call assert_false(org#list#is_unordered(25))
  call assert_false(org#list#is_unordered(26))
  call assert_false(org#list#is_unordered(27))
  call assert_false(org#list#is_unordered(28))
  call assert_false(org#list#is_unordered(29))
  call assert_false(org#list#is_unordered(30))
  call assert_false(org#list#is_unordered(31))
  call assert_false(org#list#is_unordered(32))
  call assert_false(org#list#is_unordered(33))
  call assert_false(org#list#is_unordered(34))
endfunction

function! orgtest#list#level() abort " {{{1
  call s:setup()
  call assert_equal(1, org#list#level(1))
  call assert_equal(1, org#list#level(2))
  call assert_equal(1, org#list#level(3))
  call assert_equal(1, org#list#level(4))
  call assert_equal(2, org#list#level(5))
  call assert_equal(1, org#list#level(6))
  call assert_equal(1, org#list#level(7))
  call assert_equal(0, org#list#level(8))
endfunction

function! orgtest#list#linesperitem() abort " {{{1
  call s:setup()
  call assert_equal([[1, 1], [2, 3], [4, 5]], org#list#linesperitem(1))
  call assert_equal([[1, 1], [2, 3], [4, 5]], org#list#linesperitem(2))
  call assert_equal([[1, 1], [2, 3], [4, 5]], org#list#linesperitem(4))
  call assert_equal([[5, 5]], org#list#linesperitem(5))
  call assert_equal([[10, 13], [14, 16], [17, 17]], org#list#linesperitem(10))
  call assert_equal([[20, 20], [21, 21], [22, 22]], org#list#linesperitem(20))
  call assert_equal([[24, 24], [25, 25], [26, 27], [28, 28]], org#list#linesperitem(24))
  call assert_equal([[31, 31], [32, 32], [33, 33]], org#list#linesperitem(31))
endfunction

function! orgtest#list#range() abort " {{{1
  call s:setup()
  call assert_equal([1, 5], org#list#range(1))
  call assert_equal([1, 5], org#list#range(2))
  call assert_equal([1, 5], org#list#range(3))
  call assert_equal([1, 5], org#list#range(4))
  call assert_equal([5, 5], org#list#range(5))
  call assert_equal([6, 6], org#list#range(6))
  call assert_equal([7, 7], org#list#range(7))
  call assert_equal([0, 0], org#list#range(8))
  call assert_equal([0, 0], org#list#range(9))
  call assert_equal([10, 17], org#list#range(10))
  call assert_equal([11, 13], org#list#range(11))
  call assert_equal([12, 12], org#list#range(12))
  call assert_equal([11, 13], org#list#range(13))
  call assert_equal([10, 17], org#list#range(14))
  call assert_equal([15, 16], org#list#range(15))
  call assert_equal([16, 16], org#list#range(16))
  call assert_equal([10, 17], org#list#range(17))
  call assert_equal([0 , 0] , org#list#range(18))
  call assert_equal([0 , 0] , org#list#range(19))
  call assert_equal([20, 22], org#list#range(20))
  call assert_equal([20, 22], org#list#range(21))
  call assert_equal([20, 22], org#list#range(22))
  call assert_equal([0 , 0] , org#list#range(23))
  call assert_equal([24, 28], org#list#range(24))
  call assert_equal([24, 28], org#list#range(25))
  call assert_equal([24, 28], org#list#range(26))
  call assert_equal([24, 28], org#list#range(27))
  call assert_equal([24, 28], org#list#range(28))
  call assert_equal([0 , 0] , org#list#range(29))
  call assert_equal([0 , 0] , org#list#range(30))
  call assert_equal([31, 33], org#list#range(31))
  call assert_equal([31, 33], org#list#range(32))
  call assert_equal([31, 33], org#list#range(33))
  call assert_equal([0 , 0] , org#list#range(34))

endfunction

function! orgtest#list#reorder() abort " {{{1
  call s:setup()
  10call org#list#reorder()
  20call org#list#reorder()
  24call org#list#reorder()
  31call org#list#reorder()
  call assert_equal('  1. X', getline(10))
  call assert_equal('  2. Y', getline(14))
  call assert_equal('  3. Z', getline(17))
  call assert_equal('  2. [@2] X', getline(20))
  call assert_equal('  3. Y', getline(21))
  call assert_equal('  4. Z', getline(22))
  call assert_equal('  a. W', getline(24))
  call assert_equal('  b. X', getline(25))
  call assert_equal('  c. Y', getline(26))
  call assert_equal('  d. Z', getline(28))
  call assert_equal('  B. [@B] X', getline(31))
  call assert_equal('  C. Y', getline(32))
  call assert_equal('  D. Z', getline(33))
  21,22call org#list#reorder()
  call assert_equal('  1. Y', getline(21))
  call assert_equal('  2. Z', getline(22))
endfunction
