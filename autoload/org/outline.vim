function! org#outline#complete(arglead, cmdline, curpos) abort " {{{1
  " See :h :command-completion-customlist
  " To be used with customlist, not custom. Works with spaces better, and regex are nice.
  " autocmd unlets with CmdLineLeave
  if !exists('g:org#outline#complete#cache')
    let g:org#outline#complete#cache = []
    " let outlines = get(g:, 'org#outline#complete#cache', org#outline#full())
    for fname in split(glob(org#dir() . '/**/*.org'), '\n')
      let outline = org#outline#file(fname)
      let fname = substitute(fname, resolve(fnamemodify(org#dir(), ':p')) . '/\?', '', '')
      call add(g:org#outline#complete#cache, fname)
      for toplevel in outline.subtrees
        call s:build_complcache(fname, toplevel)
      endfor
    endfor
    autocmd org_completion CmdlineLeave * ++once unlet! g:org#outline#complete#cache
    autocmd org_completion CmdlineLeave * ++once unlet! g:org#outline#complete#filter
  endif
  let filter = get(g:, 'org#outline#complete#filter', 'v:val =~? a:arglead')
  let compl = filter(copy(g:org#outline#complete#cache), filter)
  return compl
endfunction

function! s:build_complcache(str, hl) abort " {{{1
  " a.org/b/c
  let [headline, subtrees] = a:hl
  let current = a:str . '/' . headline.item
  call add(g:org#outline#complete#cache, current)
  for st in subtrees
    call s:build_complcache(current, st)
  endfor
endfunction

function! org#outline#file(fname, ...) abort " {{{1
  " expr[, force]
  " If filename, orgdir is checked unless full path is presented
  if a:fname[0] == '/'
    let fname = resolve(fnamemodify(a:fname, ':p'))
  else
    let fname = matchstr(split(glob(org#dir() . '/**/*.org'), '\n'), a:fname)
    if !empty(fname)
      let fname = resolve(fnamemodify(fname, ':p'))
    else
      throw 'Org: no file matching "' . a:fname . '"'
    endif
  endif
  let force = get(a:, 1, 0)
  let mtime = getftime(fname)
  if !force && has_key(s:outlineCache, fname) && s:outlineCache[fname].mtime == mtime
    return s:outlineCache[fname]
  endif

  let fsummary = {'mtime': mtime, 'kwmtime': mtime, 'keywords': {'todo': [], 'done': []}, 'list': [], 'subtrees': [], 'lnums': {}}

  let starttabnr = tabpagenr()
  execute 'noautocmd $tab split' fname
  try
    let fsummary.keywords = s:update_keywords()
    let lnum = org#headline#find(1, 0, 'W')
    while lnum > 0
      let subtrees = org#headline#subtree(lnum, fsummary.keywords)
      call s:add_cmd(subtrees, '')
      call add(fsummary.subtrees, subtrees)
      call extend(fsummary.list, s:flatten(subtrees))
      let lnum = org#headline#find(lnum, 1, 'Wx')
    endwhile
  finally
    quit
    execute 'noautocmd normal!' starttabnr . 'gt'
  endtry
  for hl in fsummary.list
    let fsummary.lnums[hl.lnum] = hl
  endfor
  return fsummary
endfunction

function! org#outline#full(...) abort " {{{1
  let expr = get(a:, 1, '.')
  let force = get(a:, 2, 0)
  let files = type(expr) == v:t_string ? glob(expr, 0, 1) : expr
  for fname in files
    let s:outlineCache[fname] = org#outline#file(fname, force)
  endfor
  return deepcopy(s:outlineCache)
endfunction
let s:outlineCache = {}

function! org#outline#keywords(...) abort " {{{1
  let force = get(a:, 1, 0)
  " kinds: h headline, l link
  let fname = resolve(fnamemodify(expand('%'), ':p'))
  let mtime = getftime(fname)

  if !has_key(s:outlineCache, fname)
    call org#outline#full(fname)
    call s:keyword_highlight(s:outlineCache[fname].keywords)
  elseif (force || s:outlineCache[fname].kwmtime != mtime || &modified)
    let s:outlineCache[fname].kwmtime = mtime
    let s:outlineCache[fname].keywords = s:update_keywords()
    call s:keyword_highlight(s:outlineCache[fname].keywords)
  endif
  return s:outlineCache[fname].keywords
endfunction

function! s:add_cmd(subtree, cmd) abort " {{{1
  let [headline, subtrees] = a:subtree
  let headline.cmd = a:cmd . '/\V\^' . escape(headline.text, '/\') . '\$/'
  for st in subtrees
    call s:add_cmd(st, headline.cmd)
  endfor
endfunction

function! s:flatten(subtree) abort " {{{1
  let [headline, subtrees] = a:subtree
  let flattened = [headline]
  for st in subtrees
    call extend(flattened, s:flatten(st))
  endfor
  return flattened
endfunction

function! s:keyword_highlight(kws) abort " {{{1
  silent! syntax clear orgTodo orgDone
  " TODO add user defined groups. pretty straightforward, if config scheme updated.
  " TODO make this a user autocmd for customization
  execute 'syntax keyword orgTodo ' . join(a:kws.todo) . ' containedin=orgHeadlineKeywords,@orgHeadline'
  execute 'syntax keyword orgDone ' . join(a:kws.done) . ' containedin=orgHeadlineKeywords,@orgHeadline'
endfunction

function! s:update_keywords() abort " {{{1
  " org_keywords augroup defined in plugin/org.vim, resets b:org_keywords
  let [todo, done, cursor] = [[], [], getcurpos()[1:]]
  call cursor(1, 1)
  while search('^#+TODO:', 'zcWe')
    let [t, d] = matchlist(getline('.'), g:org#regex#settings#todo)[1:2]
    let [t, d] = [split(t), split(d)]
    call extend(todo, t)
    call extend(done, d)
  endwhile
  call cursor(cursor)
  let keywords = {'todo': (empty(todo) ? ['TODO'] : todo)}
  let keywords['done'] = empty(done) ? ['DONE'] : done
  let keywords['all'] = keywords.todo + keywords.done
  return keywords
endfunction
