function! s:setup() abort
  if !exists('g:orgtest#headline#fname')
    let g:orgtest#fname = tempname()
    execute 'edit' g:orgtest#fname
    let g:orgtest#bufn = bufnr()
    setfiletype org
    augroup orgtest
      autocmd!
      autocmd User OrgTestFinish ++once execute 'bwipeout!' g:orgtest#bufn | call delete(g:orgtest#fname)
    augroup END
  endif

  1,$d_
  call setline(1, [
        \ '#+TODO: X Y | Z',
        \ '* A',
        \ ])
  write
  execute 'buffer' g:orgtest#bufn
endfunction

function! orgtest#keyword#checktext() abort " {{{1
  call assert_true(org#keyword#checktext('* A B', ['A']))
  call assert_false(org#keyword#checktext('* C B', ['A']))
  call assert_false(org#keyword#checktext('A B', ['A']))
endfunction

function! orgtest#keyword#parse() abort " {{{1
  call assert_equal('A', org#keyword#parse('* A B', ['A']))
  call assert_equal('', org#keyword#parse('* C B', ['A']))
  call assert_equal('', org#keyword#parse('A B', ['A']))
endfunction

function! orgtest#keyword#cycle() abort " {{{1
  call s:setup()
  2call org#keyword#cycle(1)
  call assert_equal('* X A', getline(2))
  2call org#keyword#cycle(-1)
  call assert_equal('* A', getline(2))
  2call org#keyword#cycle(-1)
  call assert_equal('* Z A', getline(2))
  2call org#keyword#cycle(-2)
  call assert_equal('* X A', getline(2))
endfunction

function! orgtest#keyword#op() abort " {{{1
  call assert_report('Not yet implemented.')
  " call org#op#keyword(up)
endfunction

function! orgtest#keyword#infile() abort " {{{1
  call assert_report('Not yet implemented.')
  " call org#outline#keywords()
endfunction

function! orgtest#keyword#highlight() abort " {{{1
  call assert_report('Not yet implemented.')
  " call org#keyword#highlight()
endfunction

