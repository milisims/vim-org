function! s:setup() abort
  let text =<< ENDFTORG
  - A
  - B
    b
  - [x] C
  - [X] D
  - [ ] E

ENDFTORG
  return orgtest#fsetup('listitem', text)
endfunction



function! orgtest#checklist#addbox() abort " {{{1
  call s:setup()
  1,7call org#checklist#addbox()
  call assert_equal('  - [ ] A', getline(1))
  call assert_equal('  - [ ] B', getline(2))
  call assert_equal('    b', getline(3))
  call assert_equal('  - [x] C', getline(4))
  call assert_equal('  - [X] D', getline(5))
  call assert_equal('  - [ ] E', getline(6))
  call assert_equal('', getline(7))
endfunction

function! orgtest#checklist#is_checked() abort " {{{1
  call assert_false(org#checklist#is_checked('- A'))
  call assert_false(org#checklist#is_checked('- [ ] A'))
  call assert_false(org#checklist#is_checked('- [-] A'))
  call assert_true(org#checklist#is_checked('- [x] A'))
  call assert_true(org#checklist#is_checked('- [X] A'))
endfunction

function! orgtest#checklist#hasbox() abort " {{{1
  call s:setup()
  call assert_false(org#checklist#hasbox('* [ ] A'))
  call assert_true(org#checklist#hasbox(' * [ ] A'))
  call assert_false(org#checklist#hasbox(' * A'))
  call assert_false(org#checklist#hasbox('* A'))
  call assert_true(org#checklist#hasbox(' * [ ] A'))
endfunction

function! orgtest#checklist#rmbox() abort " {{{1
  call s:setup()
  1,7call org#checklist#rmbox()
  call assert_equal('  - A', getline(1))
  call assert_equal('  - B', getline(2))
  call assert_equal('    b', getline(3))
  call assert_equal('  - C', getline(4))
  call assert_equal('  - D', getline(5))
  call assert_equal('  - E', getline(6))
  call assert_equal('', getline(7))
endfunction

function! orgtest#checklist#toggle() abort " {{{1
  call s:setup()
  1,7call org#checklist#toggle()
  call assert_equal('  - A', getline(1))
  call assert_equal('  - B', getline(2))
  call assert_equal('    b', getline(3))
  call assert_equal('  - [ ] C', getline(4))
  call assert_equal('  - [ ] D', getline(5))
  call assert_equal('  - [X] E', getline(6))
  call assert_equal('', getline(7))
endfunction

function! orgtest#checklist#check() abort " {{{1
  call s:setup()
  6call org#checklist#check()
  call assert_equal('  - [X] E', getline(6))
  call assert_report('Test for off item-start')
  call assert_report('No option for how it is checked')
endfunction

function! orgtest#checklist#uncheck() abort " {{{1
  call s:setup()
  4call org#checklist#uncheck()
  call assert_equal('  - [ ] C', getline(4))
  call assert_report('Test for off item-start')
endfunction

function! orgtest#checklist#togglebox() abort " {{{1
  call s:setup()
  1,7call org#checklist#togglebox()
  call assert_equal('  - [ ] A', getline(1))
  call assert_equal('  - [ ] B', getline(2))
  call assert_equal('    b', getline(3))
  call assert_equal('  - C', getline(4))
  call assert_equal('  - D', getline(5))
  call assert_equal('  - E', getline(6))
  call assert_equal('', getline(7))
endfunction





