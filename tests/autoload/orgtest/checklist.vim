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
  " Setup
  call setline(1, ['- [ ] A', '- B'])
  " Execution
  1,2call org#checklist#addbox()
  " Validation
  call assert_equal('- [ ] A', getline(1))
  call assert_equal('- [ ] B', getline(2))
  " Teardown automatic
endfunction

function! orgtest#checklist#is_checked() abort " {{{1
  call assert_false(org#checklist#is_checked('- A'))
  call assert_false(org#checklist#is_checked('- [ ] A'))
  call assert_false(org#checklist#is_checked('- [-] A'))
  call assert_true(org#checklist#is_checked('- [x] A'))
  call assert_true(org#checklist#is_checked('- [X] A'))
endfunction

function! orgtest#checklist#hasbox() abort " {{{1
  call assert_false(org#checklist#hasbox('* [ ] A'))
  call assert_true(org#checklist#hasbox(' * [ ] A'))
  call assert_false(org#checklist#hasbox(' * A'))
  call assert_false(org#checklist#hasbox('* A'))
  call assert_true(org#checklist#hasbox(' * [ ] A'))
endfunction

function! orgtest#checklist#rmbox() abort " {{{1
  " Setup
  call setline(1, ['- [ ] A', '- B'])
  " Execution
  1,2call org#checklist#rmbox()
  " Validation
  call assert_equal('- A', getline(1))
  call assert_equal('- B', getline(2))
  " Teardown automatic
endfunction

function! orgtest#checklist#toggle() abort " {{{1
  call setline(1, ['- [ ] A', '- B', '- [x] C'])
  1,3call org#checklist#toggle()
  call assert_equal('- [X] A', getline(1))
  call assert_equal('- B', getline(2))
  call assert_equal('- [ ] C', getline(3))
endfunction

function! orgtest#checklist#check() abort " {{{1
  call setline(1, ['- [ ] A'])
  1call org#checklist#check()
  call assert_equal('- [X] A', getline(1))
  let g:org#check#lowercase = 1
  call setline(1, ['- [ ] A'])
  1call org#checklist#check()
  call assert_equal('- [x] A', getline(1))
  " Teardown
  unlet g:org#check#lowercase
endfunction

function! orgtest#checklist#uncheck() abort " {{{1
  call setline(1, ['- [x] A', '- [ ] B'])
  1,2call org#checklist#uncheck()
  call assert_equal('- [ ] A', getline(1))
  call assert_equal('- [ ] B', getline(2))
endfunction

function! orgtest#checklist#togglebox() abort " {{{1
  call setline(1, ['- [ ] A', '- B', '- [x] C'])
  1,3call org#checklist#togglebox()
  call assert_equal('- A', getline(1))
  call assert_equal('- [ ] B', getline(2))
  call assert_equal('- C', getline(3))
endfunction





