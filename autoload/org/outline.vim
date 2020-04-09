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

function! org#outline#file(expr, ...) abort " {{{1
  " expr[, force]
  " expr can be bufnr or filename. bufnr checked first
  let force = get(a:, 1, 0)
  " kinds: h headline, l link
  let fname = resolve(fnamemodify(bufname(a:expr), ':p'))
  let mtime = getftime(fname)
  if !force && has_key(s:outlineCache, fname) && s:outlineCache[fname].mtime == mtime
    return s:outlineCache[fname]
  endif

  let fsummary = {'mtime': mtime, 'keywords': {'todo': [], 'done': []}, 'list': [], 'subtrees': [], 'lnums': {}}

  let tabnr = tabpagenr()
  execute 'noautocmd $tab split' fname
  try
    let [fsummary.keywords.todo, fsummary.keywords.done] = org#keyword#get()
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
    execute 'noautocmd normal!' tabnr . 'gt'
  endtry
  return fsummary
endfunction

function! s:add_cmd(subtree, cmd) abort " {{{2
  let [headline, subtrees] = a:subtree
  let headline.cmd = a:cmd . '/\V\^' . escape(headline.text, '/\') . '\$/'
  for st in subtrees
    call s:add_cmd(st, headline.cmd)
  endfor
endfunction

function! s:flatten(subtree) abort " {{{2
  let [headline, subtrees] = a:subtree
  let flattened = [headline]
  for st in subtrees
    call extend(flattened, s:flatten(st))
  endfor
  return flattened
endfunction
