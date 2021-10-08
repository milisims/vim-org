function! s:openexternal(uri) abort " {{{1
  if has('win32') || has('win32') || has('wsl')
    let cmd = '!explorer.exe '
  elseif has('mac')
    let cmd = '!open '
  else
    let cmd = '!xdg-open '
  endif
  return cmd . shellescape(a:uri)
endfunction

" echo org#link#follow('[[abc][def]]')
" echo org#link#follow('[[def]]')
" echo org#link#follow('[[def.png]]')
" echo org#link#follow('[[def.png][description!]]')
" echo org#link#follow('[[git@github.com:stephfins/biofilm-lysogeny.git][something]]')
" echo org#link#follow('[[https://www.google.com][something]]')

" links:
" 'http://www.astro.uva.nl/=dominik'         on the web
" 'file:/home/dominik/images/jupiter.jpg'    file, absolute path
" '/home/dominik/images/jupiter.jpg'         same as above
" 'file:papers/last.pdf'                     file, relative path
" './papers/last.pdf'                        same as above
" 'file:projects.org'                        another Org file
" 'id:B7423F4D-2E8A-471B-8810-C40F074717E9'  link to heading by ID
" 'mailto:adent@galaxy.net'                  mail link

" File links can contain additional information to make Emacs jump to a particular location in
" the file when following a link. This can be a line number or a search option after a double
" colon. Here are a few examples,, together with an explanation:
" 'file:~/code/main.c::255'                  Find line 255
" 'file:~/xx.org::My Target'                 Find '<<My Target>>'
" '[[file:~/xx.org::#my-custom-id]]'         Find entry with a custom ID



function! s:weblink(uri) abort " {{{1
  if a:uri =~? '^git@.*\.git$'
    return s:openexternal('https://' . substitute(a:uri[4:-5], ':', '/', ''))
  endif
  return s:openexternal(a:uri)
endfunction

function! s:doilink(uri) abort " {{{1
  return s:openexternal(substitute(a:uri, '^doi:', 'https://doi.org/', ''))
endfunction

function! s:orglink(uri) abort " {{{1
  let [file, type, info] = matchlist(a:uri, '\v^file:(.{-})%(::([#*])?(.*))?$')[1:3]
  if empty(info)             " just file
    return 'edit ' . file
  elseif type == '#'
    return s:idlink('#' . info, file)
  elseif type == '*'
    return printf('edit +/%s %s', '^*.*' . escape(info, '\ '), file)
  elseif info =~ '^\d\+$'    " lnum
    return printf('edit +%d %s', info, file)
  endif                      " text search
  return printf('edit +/%s %s', info, file)
endfunction

function! s:filelink(uri) abort " {{{1
  let [file, info] = matchlist(a:uri, '\v^%(file:)?(.{-})%(::(.*))?$')[1:2]
  if empty(info)             " just file
    return 'edit ' . file
  elseif info =~ '^\d\+$'    " lnum
    return printf('edit +%d %s', info, file)
  endif                      " text search
  return printf('edit +/%s %s', info, file)
endfunction

function! s:idlink(uri, ...) abort " {{{1
  let items = []
  for outline in values(org#outline#multi(exists('a:1') ? a:1 : org#agenda#files()))
    call extend(items, outline.list)
  endfor
  let id = substitute(a:uri, '^#', '', '')
  try
    let item = filter(items, 'get(v:val.properties, "id", "") == id || get(v:val.properties, "CUSTOM_ID", "") == id')
    return printf('edit +%d %s', item[0].lnum, item[0].filename)
  catch
    return printf("echoerr 'Org: no id found: %s'", substitute(a:uri, "'", "''", 'g'))
  endtry
endfunction

function! s:externalmatch(uri) abort " {{{1
  let externals = copy(s:external) + get(g:, 'org#link#external', [])
  return a:uri =~? ('\v^%(file:)?.*%(' . join(externals, '|') . ')$')
endfunction

function! org#link#follow(uri, desc) abort " {{{1
  " Otherwise go through the list of defined link types
  for linktype in filter(s:linktypes + g:org#link#types, 'has_key(v:val, "match")')
    if (type(linktype.match) == v:t_string && a:uri =~? linktype.match)
          \ || (type(linktype.match) == v:t_func && linktype.match(a:uri))
      return linktype.follow(a:uri)
    endif
  endfor

  " Open default if none match
  let default = filter(s:linktypes + g:org#link#types, 'get(v:val, "type", "") == "default"')
  return empty(default) ? s:default(a:uri) : default[0].follow(a:uri)
endfunction
let g:org#regex#link = '\v^\[\[([^][]+)\]%(\[([^][]+)\])?\]$'

function! org#link#atcursor() abort " {{{1
  let text = col('.') == 1 ? '' : split(getline('.')[: col('.') - 2], '\ze[[')[-1]
  let text .= split(getline('.')[col('.') - 1 :], ']]\zs')[0]
  try
    let [uri, desc] = matchlist(text, g:org#regex#link)[1:2]
    return org#link#follow(uri, desc)
  catch /^Vim\%((\a\+)\)\=:E688/
    return printf("echoerr 'Org: unknown link format: %s'", substitute(text, "'", "''", 'g'))
  endtry
endfunction

function! s:default(uri) abort " {{{1
  " 1. Check for targets,
  " 2. check for headlines,
  " 3. check for document titles
  let lnum = search('^\*\+.*' . a:uri, 'nW')
  if lnum
    return lnum
  endif
  for filename in org#agenda#files()
    if get(org#outline#file(filename), 'title', '') ==? a:uri
      return 'edit ' . filename
    endif
  endfor
  return 'echoerr "No way to open ''' . a:uri . '''"'
endfunction

" External & linktypes defaults {{{1
let s:external = ['jpe?g', 'tiff?', 'gif', 'bmp', 'png', 'exif', 'svg', 'pdf', 'e?ps']

let s:linktypes = [
      \ #{type: 'web', match: '\v^%(git\@|https?:)', follow: function('s:weblink')},
      \ #{type: 'org', match: '\v^file:.*\.org%(::.*)?', follow: function('s:orglink')},
      \ #{type: 'doi', match: '\v^doi:10\..+', follow: function('s:doilink')},
      \ #{type: 'file', match: '\v^file:.*\.%(::.*)?', follow: function('s:filelink')},
      \ #{type: 'external', match: function('s:externalmatch'), follow: function('s:filelink')},
      \ ]

