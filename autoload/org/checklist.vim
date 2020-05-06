function! org#checklist#addbox() abort " {{{1
  let line = getline('.')
  if !org#listitem#has_bullet(line) || org#checklist#hasbox(line)
    return
  endif
  let regex = '\v^(\s*)' . g:org#regex#list#bullet . '\s*' . g:org#regex#list#counter_start . '?\s*'
  call setline('.', substitute(line, regex, '&[ ] ', ''))
endfunction

function! org#checklist#is_checked(text) abort " {{{1
  let item = matchlist(a:text, g:org#regex#listitem)
  return !empty(item) && item[4] =~ '[xX]'
endfunction

function! org#checklist#hasbox(text) abort " {{{1
  let item = matchlist(a:text, g:org#regex#listitem)
  return !empty(item) && !empty(item[4])
endfunction

function! org#checklist#rmbox() abort " {{{1
  let line = getline('.')
  if !org#listitem#has_bullet(line) || !org#checklist#hasbox(line)
    return
  endif
  let regex = '\v^(\s*)' . g:org#regex#list#bullet . '\s*' . g:org#regex#list#counter_start . '?\s*\zs' . g:org#regex#list#checkbox . '\s*'
  call setline('.', substitute(line, regex, '', ''))
endfunction

function! org#checklist#toggle() abort " {{{1
  let line = getline('.')
  if !org#checklist#hasbox(line)
    return
  endif
  if org#checklist#is_checked(line)
    call setline('.', substitute(line, '\[[xX]\]', '[ ]', ''))
  else
    call setline('.', substitute(line, '\[ \]', '[X]', ''))
  endif
  " TODO if sublist, do the thing
endfunction

function! org#checklist#check() abort " {{{1
  let line = getline('.')
  if org#checklist#hasbox(line) && !org#checklist#is_checked(line)
    call setline('.', substitute(line, '\[ \]', '[X]', ''))
  endif
endfunction

function! org#checklist#uncheck() abort " {{{1
  let line = getline('.')
  if org#checklist#hasbox(line) && org#checklist#is_checked(line)
    call setline('.', substitute(line, '\[[xX]\]', '[ ]', ''))
  endif
endfunction

function! org#checklist#togglebox() abort " {{{1
  let line = getline('.')
  if !org#listitem#has_bullet(line)
    return
  endif
  if org#checklist#hasbox(line)
    call org#checklist#rmbox()
  else
    call org#checklist#addbox()
  endif
endfunction
