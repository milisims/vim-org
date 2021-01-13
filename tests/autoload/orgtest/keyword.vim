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
  let kw = {'todo': ['X'], 'done': ['Y'], 'all': ['X', 'Y']}
  call assert_equal('X', org#keyword#parse('* X A', kw))
  call assert_equal('Y', org#keyword#parse('* Y A', kw))
  call assert_equal('', org#keyword#parse('* A', kw))
  call assert_equal('', org#keyword#parse('X A', kw))
endfunction

function! orgtest#keyword#cycle() abort " {{{1
  call setline(1, ['* A'])
  let kw = {'todo': ['X'], 'done': ['Y'], 'all': ['X', 'Y']}
  1call org#keyword#cycle(-1)
  call assert_equal('* Y A', getline(1))
  1call org#keyword#cycle(1)
  call assert_equal('* A', getline(1))
  1call org#keyword#cycle(1)
  call assert_equal('* X A', getline(2))
  1call org#keyword#cycle(2)
  call assert_equal('* A', getline(2))
endfunction
