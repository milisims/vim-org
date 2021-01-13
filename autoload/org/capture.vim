" If context exists, it must eval to true to exist. Will not be passed any arguments

" Target must resolve to a string that looks like:
" 'file.org/some/headlines in/this file'
" Or a list
" ['file.org', 'some', 'headlines in', 'this file']
" or a dict: {'file': fname, 'regex': regex matching expression to add}
" or a funcref that results in any of the above.

" valid types:
" entry, item (list), checkitem, plain (plain text)

" TODO
" table-line type
" TODO table-line-pos for options

" https://orgmode.org/manual/Template-elements.html#Template-elements

" Defaults {{{1
" if !exists('g:org#capture#defaults')
let g:org#capture#defaults = {
      \ 'item': '`input("List item> ")`',
      \ 'checkitem': '`input("List item> ")`',
      \ 'plain': '`input("Text> ")`',
      \ 'type': 'entry'
      \ }

let g:org#capture#defaults.entry = [
      \ '* `input("Description> ")`',
      \ ':PROPERTIES:',
      \ ':captured-at: `org#time#dict(''now'').totext()`',
      \ ':captured-in: `fnamemodify(expand("%"), ":p:~")`',
      \ ':END:',
      \ ]
" endif

let s:default_opts = {
      \ 'editcmd': 'split',
      \ 'prepend': 0,
      \ 'format': 1,
      \ 'quit': 0,
      \ 'save': 1,
      \ }

function! org#capture#do(capture) abort " {{{1
  let capture = copy(a:capture)
  let capture.opts = extend(copy(get(capture, 'opts', {})), g:org#capture#opts, 'keep')
  let capture.opts = extend(capture.opts, s:default_opts, 'keep')
  let g:org#currentcapture = capture
  silent doautocmd User OrgCapturePre
  let target = org#capture#get_target(capture)

  let ctype = get(capture, 'type', g:org#capture#defaults.type)
  let template = get(capture, 'template', g:org#capture#defaults[ctype])
  let text = org#capture#template2text(template)

  let layout = winlayout()
  " Check if it's open already?
  execute capture.opts.editcmd target.filename

  if ctype == 'entry'
    let range = s:add_entry(target, text, capture.opts.prepend)
  elseif ctype == 'item'
    let range = s:add_item(target, text, capture.opts.prepend, 0)
  elseif ctype == 'checkitem'
    let range = s:add_item(target, text, capture.opts.prepend, 1)
  elseif ctype == 'plain'
    let range = s:add_plaintext(target, text, capture.opts.prepend)
  else
    throw "Org: Only capture types in [entry, item, checkitem, plain] are supported."
  endif

  call cursor(range[0], 1)
  normal! m[
  call cursor(range[1], col([range[1], '$']))
  normal! m]

  if capture.opts.save | update | endif
  if capture.opts.quit
    if layout == winlayout() | buffer # | else | quit | endif
  endif

  silent doautocmd User OrgCapturePost
  unlet g:org#currentcapture

endfunction

function! org#capture#get_target(template) abort " {{{1
  " target can be:

  " string processing
  " file
  " full target string
  " file + unique headline
  " file + regex

  " funcref returning headline object

  " dict containing ???????

  " returns: string or dict. String if just a filename, dict of org#headline#get if specified.
  if !has_key(a:template, 'target')
    return org#headline#fromtarget(g:org#inbox)
  elseif type(a:template.target) == v:t_string
    return org#headline#fromtarget(a:template.target, 1)
  elseif type(a:template.target) == v:t_func
    let target = a:template.target()
    return type(target) == v:t_string ? org#headline#fromtarget(target, 1) : target
  elseif type(a:template.target) == v:t_list
    return a:template.target
  elseif type(a:template.target) == v:t_dict
    let bufn = fnamemodify(a:template.target.filename, ':p')
    if has_key(a:template.target, 'regex')
    elseif has_key(a:template.target, 'target')
    endif
    return 1
  endif
  throw 'Org: Cannot find target from template provided'
endfunction


function! org#capture#template2text(template) abort " {{{1
  " TODO add dictionary template possible for 'entry' type
  let template = type(a:template) == v:t_list ? join(a:template, "\n") : a:template
  let parts = split(template, '`', 1)
  if len(parts) == 1
    return template
  elseif len(parts) % 2 == 0
    throw 'Org: capture template may have unmatched backticks. Check formatting.'
  endif
  for ix in range(1, len(parts) - 1, 2)
    let parts[ix] = eval(parts[ix])
  endfor
  return split(join(parts, ''), "\n")
endfunction

function! org#capture#window(templates) abort " {{{1
  let templates = map(copy(a:templates), {_, t -> [t.key, t.description]})
  " let templates = map(templates, {_, t -> [t[0], type(t[1]) == v:t_func ? t[1]() : t[1]]})
  let fulltext = s:capture_text(templates)
  let winid = has('nvim') ? s:nvimwin(fulltext) : s:vimwin(fulltext)
  let selection = ''
  messages clear

  while 1
    redraw
    try
      let capture = getchar()
    catch /^Vim:Interrupt$/  " for <C-c>
      call s:closewin(winid) | return {}
    endtry
    if capture == char2nr("\<Esc>")
      call s:closewin(winid) | return {}
    elseif capture == char2nr("\<Cr>") && !empty(selection)
      break
    endif
    let selection = selection . nr2char(capture)
    let reduced = filter(copy(templates), {_, t -> t[0][: len(selection) - 1] == selection})
    if len(reduced) == 1
      break
    elseif len(reduced) == 0
      call s:set_text(winid, fulltext)
      let selection = ''
    elseif len(reduced) > 1
      call s:set_text(winid, s:capture_text(reduced, fulltext))
    endif
  endwhile

  call s:closewin(winid)
  return filter(copy(a:templates), 'v:val.key == selection')[0]
endfunction

function! s:add_entry(target, text, prepend) abort " {{{1
  let lnum = org#section#range(a:target.lnum)[1]
  let lnum = prevnonblank(lnum)  " TODO + 1, check for edge
  let text = type(a:text) == v:t_string ? [a:text] : a:text
  call append(lnum, text)
  if has_key(a:target, 'level')
    let range = (lnum + 1 + empty(getline(lnum))). ',' . (lnum + len(text))
    " FIXME org#shift should work on this.
    let cursor = getcurpos()[1:]
    call cursor(lnum + 1, 1)
    call org#headline#promote(a:target.level)
    call cursor(cursor)
  endif
  return [lnum + 1, lnum + len(text)]
endfunction

function! s:add_item(target, text, prepend, ...) abort " {{{1
  let checkbox = get(a:, 1, 0)
  let range = org#section#range(a:target.lnum)
  let lnum = org#list#find(range[1], 'bW')
  let lnum = lnum < range[0] ? range[1] : lnum
  call org#listitem#append(lnum, a:text, checkbox)
  return org#listitem#range(org#listitem#range(lnum)[1] + 1)
endfunction

function! s:add_plaintext(target, text, prepend, ...) abort " {{{1
  let lnum = org#section#range(a:target.lnum)[1]
  let lnum = prevnonblank(lnum) + 1
  call append(lnum, a:text)
  return [lnum, lnum + len(a:text) - 1]
endfunction

function! s:capture_text(options, ...) abort " {{{1
  let full = get(a:, 1, a:options)
  let text = map(copy(a:options), {_, t -> '  ' . t[0] . repeat(' ', 5 - len(t[0])) . t[1]})
  return text + map(range(len(full) - len(text)), '""')
endfunction

function! s:closewin(winid) abort " {{{1
  if has('nvim')
    quit
  else
    call popup_close(a:winid)
  endif
endfunction

function! s:getlines() abort " {{{1
  " Get 'absolute' line number. Seems easier than traversing winlayout()
  let [start, lines] = [winnr(), winline() + 1]
  noautocmd wincmd k
  while winnr() != winnr('k')
    let lines += winheight(winnr()) + 1
    noautocmd wincmd k
  endwhile
  return lines
endfunction

function! s:nvimwin(text) abort " {{{1
  let buf = nvim_create_buf(v:false, v:true)
  let s:buf = buf
  let above = (s:getlines() + len(a:text) + 3 > &lines)
  let opts = {
        \ 'relative': 'cursor',
        \ 'row': !above,
        \ 'col': -1,
        \ 'width': 3 + max(map(copy(a:text), 'len(v:val)')),
        \ 'height': len(a:text) + 1,
        \ 'anchor': above ? "SW" : "NW",
        \ }

  let winid = nvim_open_win(buf, v:true, opts)
  setfiletype org-capture
  call setline(1, ' Capture:')
  call append('$', a:text)
  return winid
endfunction

function! s:set_text(winid, text) abort " {{{1
  if has('nvim')
    call setline(1, ' Capture:')
    call setline(2, a:text)
  else
    call win_execute(a:winid, 'call setline(1, " Capture:")')
    call win_execute(a:winid, 'call setline(2, a:text)')
  endif
endfunction

function! s:vimwin(text) abort " {{{1
  let text = [' Capture:'] + a:text
  let above = (s:getlines() + len(a:text) + 1 > &lines)
  let winid = popup_atcursor(text, {
        \ 'pos': above ? 'botleft' : 'topleft',
        \ 'col': above ? 'cursor' : 'cursor-1',
        \ 'minwidth': 3 + max(map(copy(a:text), 'len(v:val)')),
        \ })
  call win_execute(winid, 'setfiletype org-capture')
  return winid
endfunction
