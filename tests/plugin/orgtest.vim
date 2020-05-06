let s:testdir = expand('<sfile>:p:h:h')

function! s:toerf(ix, error) abort " {{{1
  " Return value matches efm=%f::%o::%l::%t::%m
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
  return join([fname, fnn[7:], line, type, txt], '::')
endfunction

function! s:testargs(...) abort " {{{1
  let regex = '\%(' . join(map(copy(a:000), 'glob2regpat(v:val)'), '\|') . '\)'
  let regex = substitute(regex, '[$^]', '', 'g')

  let tabsv = tabpagenr()
  augroup orgtest
    autocmd!
  augroup END

  runtime! autoload/orgtest/**/*.vim
  call map(glob(s:testdir . '/autoload/**/*.vim', 1, 1), 'execute("source " . v:val)')

  let errors = []
  let alltests = split(execute('function /^orgtest'), '\n')
  let alltests = map(alltests, "matchstr(v:val, 'orgtest#.*()')")
  let alltests = filter(alltests, "!empty(v:val)")
  let tests = sort(filter(copy(alltests), 'v:val =~? regex'))
  for test in tests
    let v:errors = []
    try
      execute 'call ' . test
    catch /^.*/
      call add(v:errors,  v:throwpoint . ': ' . v:exception)
    endtry
    call extend(errors, sort(map(v:errors, function('s:toerf'))))
    doautocmd orgtest User OrgTestTeardown
  endfor
  call map(alltests, 'execute("delfunction " . v:val[:-3])')

"   echo
"   for e in errors
"     echo e
"   endfor
"   return
  let fout = get(g:, 'orgtest#errfile', tempname())
  call writefile(errors, fout, 's')

  " If it looks --clean, quit. Otherwise, open qflist
  if empty($MYVIMRC)
    execute len(errors) > 0 ? 'cquit!' : 'qall!'
  endif

  execute 'tabnext' tabsv
  if len(errors) > 0
    execute 'cfile' fout
    copen
  else
    call setqflist([])
    echom 'Ran ' . len(tests) . ' test' . (len(tests) > 1 ? 's' : '') . ' without failure.'
  endif
endfunction " }}}

let s:testfiles = {}
function! orgtest#fsetup(name, text) abort " {{{1
  if !has_key(s:testfiles, a:name)
    let s:testfiles[a:name] = {'fname': tempname()}
    execute 'tabedit' s:testfiles[a:name].fname
    call setline(1, a:text)
    silent write
    let s:testfiles[a:name].bufn = bufnr()
    setfiletype org
    execute 'autocmd orgtest User OrgTestTeardown call orgtest#fteardown("' . a:name . '")'
  endif
  return s:testfiles[a:name]
endfunction

function! orgtest#fteardown(name) abort " {{{1
  if has_key(s:testfiles, a:name)
    execute 'silent! bwipeout!' s:testfiles[a:name].bufn
    unlet! s:testfiles[a:name]
  endif
endfunction " }}}

command! -nargs=* TestOrg call s:testargs(<f-args>)
