let s:testdir = expand('<sfile>:p:h:h')

function! s:toerf(ix, error) abort " {{{1
  " set errorformat=%f::%l::%o::%t::%m makeprg=./run_tests.sh
  " Return value matches efm=%f::%l::%o::%t::%m
  let [fnn, lnn, txt] = matchlist(a:error, '\v.{-}\.\.(orgtest#.{-}),? line (\d+): (.*)')[1:3]
  let type = txt =~# '^Vim' ? 'X' : 'E'

  if type == 'X'
    let fnn = fnn . '[' . lnn . ']'
    let [test; chain] = split(fnn, '\.\.')
    let [fnn, lnn] = matchlist(test, '\v(orgtest.*)\[(\d+)\]')[1:2]
    let txt .= ': ' . join(chain, '..')
    let type = 'E'
  endif

  let line = split(execute('verbose function ' . fnn), '\n')[1]
  let [fname, line] = matchlist(line, '\v\s*Last set from (.*) line (\d+)')[1:2]
  let line += lnn
  let fname = fnamemodify(fname, ':p')
  return join([fname, line, fnn[7:], type, txt], '::')
endfunction

function! s:fixbuf(stdinbuf) abort " {{{2
  let ft = &ft
  let text = getline(1, '$')
  bwipeout!
  execute 'buffer' a:stdinbuf
  %delete _
  call setline(1, text)
  execute 'setfiletype' &ft
endfunction

function! s:testargs(stdout, ...) abort " {{{1

  if a:stdout
    augroup orgtest
      autocmd!
      " WARNING: No buffers can be created!
      " This function deletes a new buffer, copying its filetype and
      " contents to the original buffer.
      " As a result, we can run :make from vim to run tests!
      execute 'autocmd BufEnter * call s:fixbuf(' bufnr() ')'
    augroup END
  endif

  " - Run tests ----------------------------------------------------

  let regex = map(copy(a:000), 'glob2regpat(v:val)')
  call map(regex, 'substitute(v:val, ''^\^\|\$$'', "", "g")')
  let regex = '\%(' . join(regex, '\|') . '\)'

  runtime! autoload/orgtest/**/*.vim

  let errors = []
  let alltests = split(execute('function /^orgtest'), '\n')
  let alltests = map(alltests, "matchstr(v:val, 'orgtest#.*()')")
  let alltests = filter(alltests, "!empty(v:val)")
  let tests = sort(filter(copy(alltests), 'v:val =~? regex'))

  for test in tests
    let v:errors = []
    if a:stdout
      %d _
    else
      new
    endif
    setfiletype org
    try
      execute 'call ' . test
    catch /^.*/
      call add(v:errors,  v:throwpoint . ': ' . v:exception)
    endtry
    call extend(errors, sort(map(v:errors, function('s:toerf'))))
    if !a:stdout
      bwipeout!
    endif
  endfor
  call map(alltests, 'execute("delfunction " . v:val[:-3])')

  " - Output -------------------------------------------------------
  if a:stdout
    %d _
    call setline(1, errors + ['Testing complete.'])
    %print
    quitall!
  endif

  let fname = tempname()
  call writefile(errors, fname)
  " Errorformat set in org#test#load
  execute 'cfile' fname

endfunction " }}}

" Bang should be used only with run_tests
command! -bang -nargs=* TestOrg call s:testargs(<bang>0, <f-args>)
