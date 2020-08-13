let s:outlineCache = {}

function! org#outline#complete(arglead, cmdline, curpos) abort " {{{1
  " See :h :command-completion-customlist
  " To be used with customlist, not custom. Works with spaces better, and regex are nice.
  " autocmd unlets with CmdLineLeave
  if !exists('g:org#outline#complete#cache')
    if !exists('g:org#outline#complete#targets')
      let targets = []
      for [fname, outline] in items(org#outline#multi())
        call add(targets, fnamemodify(fname, ':t'))
        call extend(targets, map(outline.list, 'v:val.target'))
      endfor
    elseif type(g:org#outline#complete#targets[0]) == v:t_dict
      let targets = map(g:org#outline#complete#targets, 'v:val.target')
    elseif type(g:org#outline#complete#targets[0]) == v:t_string
      let targets = g:org#outline#complete#targets
    else
      throw 'Org: elements of g:org#outline#complete#targets must be outline dicts or target strings'
    endif
    let g:org#outline#complete#cache = sort(targets)
    autocmd org_completion CmdlineLeave,CompleteDone,InsertEnter * ++once unlet! g:org#outline#complete#cache
    autocmd org_completion CmdlineLeave,CompleteDone,InsertEnter * ++once unlet! g:org#outline#complete#filter
    autocmd org_completion CmdlineLeave,CompleteDone,InsertEnter * ++once unlet! g:org#outline#complete#targets
  endif
  if !empty(a:arglead)
    " TODO Not sure if I want to keep this filter
    let filter = get(g:, 'org#outline#complete#filter', 'v:val =~ glob2regpat(a:arglead)[1:-2]')
    return filter(copy(g:org#outline#complete#cache), filter)
  endif
  return g:org#outline#complete#cache
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
    return s:copy(s:outlineCache[fname])
  endif

  let fsummary = {'mtime': mtime, 'kwmtime': mtime, 'keywords': {'todo': [], 'done': []}, 'subtrees': [], 'lnums': {}}
  let shortname = substitute(fname, resolve(fnamemodify(org#dir(), ':p')) . '/\?', '', '')

  let starttabnr = tabpagenr()
  execute 'noautocmd $tab split' fname
  try
    let fsummary.keywords = s:update_keywords()
    let lnum = org#headline#find(1, 0, 'W')
    while lnum > 0
      let subtrees = org#headline#subtree(lnum, fsummary.keywords)
      call s:add_cmd(subtrees, {'target': shortname, 'cmd': '0'})
      call add(fsummary.subtrees, subtrees)
      " call extend(fsummary.list, s:flatten(subtrees))
      let lnum = org#headline#find(lnum, 1, 'Wx')
    endwhile
  finally
    quit
    execute 'noautocmd normal!' starttabnr . 'gt'
  endtry
  let s:outlineCache[fname] = fsummary
  return s:copy(fsummary)
endfunction

function! org#outline#multi(...) abort " {{{1
  " TODO what is this? vs org#agenda"
  let files = get(a:, 1, org#dir() . '/**/*.org')
  if type(files) == v:t_string
    let files = glob(files, 0, 1)
  elseif type(files) != v:t_list
    throw 'org: org#outline#multi arg 1 must be a glob string or list of files'
  endif
  let force = get(a:, 2, 0)
  " TODO fix this glob
  let outline = {}
  for fname in files
    let outline[fname] = org#outline#file(fname, force)
  endfor
  return outline
endfunction

function! org#outline#keywords(...) abort " {{{1
  let force = get(a:, 1, 0)
  " kinds: h headline, l link
  let fname = resolve(fnamemodify(expand('%'), ':p'))
  let mtime = getftime(fname)

  if !has_key(s:outlineCache, fname)
    call org#outline#file(fname)
    call s:keyword_highlight(s:outlineCache[fname].keywords)
  elseif (force || s:outlineCache[fname].kwmtime != mtime || &modified)
    let s:outlineCache[fname].kwmtime = mtime
    let s:outlineCache[fname].keywords = s:update_keywords()
    call s:keyword_highlight(s:outlineCache[fname].keywords)
  endif
  return s:outlineCache[fname].keywords
endfunction

function! s:add_cmd(subtree, parent) abort " {{{1
  let [headline, subtrees] = a:subtree
  let headline.target = a:parent.target . '/' . headline.item
  " escaping '/' as the delimiter
  let headline.cmd = a:parent.cmd . '/\V\^' . escape(headline.text, '/\') . '\$/'
  for st in subtrees
    call s:add_cmd(st, headline)
  endfor
endfunction

function! s:copy(cache) abort " {{{1
  " 'list', 'lnums', 'subtrees', 'mtime', 'keywords', 'kwmtime'
  let ccopy = copy(a:cache)  " shallow
  let ccopy.subtrees = deepcopy(a:cache.subtrees)
  let ccopy.list = s:flatten(ccopy.subtrees) " linked
  for hl in ccopy.list
    let ccopy.lnums[hl.lnum] = hl
  endfor
  return ccopy
endfunction

" TODO make a version of this available
function! s:flatten(subtree) abort " {{{1
  let flattened = []
  for st in a:subtree
    call add(flattened, st[0])
    call extend(flattened, s:flatten(st[1]))
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
