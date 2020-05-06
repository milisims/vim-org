" Variables {{{1

runtime autoload/org/regex.vim
let g:org#timestamp#scheduled#time = get(g:, 'org#timestamp#scheduled#time', 3)
let g:org#timestamp#deadline#time = get(g:, 'org#timestamp#deadline#time', 3)
let g:org#dir = '~/org'
let g:org#inbox = org#dir . '/inbox.org'
let g:org#format#space_in_empty = get(g:, 'org#format#space_in_empty', 0)

let g:org#regex#settings#todo = '\v^#\+TODO:\s*(.{-})\s*\|\s*(.+)'
let g:org#regex#property = '\v^:([[:alnum:]_-]+)(\+)?:%(\s+|$)(.*)'

" Timestamp {{{2
" formats:
" <YYYY-MM-DD dow [hh:mm[-hh:mm]]>
" <YYYY-MM-DD dow [hh:mm]>--<YYYY-MM-DD dow [hh:mm]>
" <4321-12-01 dow>
" <4321-12-01 dow 12:34>
" <4321-12-01 dow 12:34-13:24>
" <1234-05-21 dow>--<1234-05-22 dow>
" <1234-05-21 dow 12:34>--<1234-05-22 dow 13:34>
" TODO one bigass regex & use submatch and match again to decompose
let g:org#regex#timestamp#date = '\v%((\d{4})-(\d{1,2})-(\d{1,2})(\s+[^]+0-9> -]+)?\s*)'
let g:org#regex#timestamp#date0 = '\v%(\d{4}-\d{1,2}-\d{1,2}%(\s+[^]+0-9> -]+)?\s*)'
let g:org#regex#timestamp#date1 = '\v%((\d{4}-\d{1,2}-\d{1,2}%(\s+[^]+0-9> -]+)?)\s*)'
let g:org#regex#timestamp#time = '\v%((\d{1,2}):(\d{2})\s*)'
let g:org#regex#timestamp#time0 = '\v%(\d{1,2}:\d{2}\s*)'
let g:org#regex#timestamp#time1 = '\v%((\d{1,2}:\d{2})\s*)'
let g:org#regex#timestamp#time2 = '\v%((\d{1,2}):(\d{2})\s*)'
let g:org#regex#timestamp#repeater = '\v%(([.+]?\+)(\d+)(\c[hdwmy])>\s*)'
let g:org#regex#timestamp#repeater0 = '\v%(%([.+]?\+)\d+\c[hdwmy]>\s*)'
let g:org#regex#timestamp#repeater1 = '\v%((%([.+]?\+)\d+\c[hdwmy])>\s*)'
let g:org#regex#timestamp#delay = '\v%((--?)(\d+)(\c[hdwmy])>\s*)'
let g:org#regex#timestamp#delay0 = '\v%(%(--?)\d+\c[hdwmy]>\s*)'
let g:org#regex#timestamp#delay1 = '\v%((%(--?)\d+\c[hdwmy])>\s*)'
let g:org#regex#timestamp#relative = '\v([-+]?[0-9]+)?\s*([hdwmy])>'
let g:org#regex#timestamp#relative0 = '\v%([-+]?[0-9]+)?\s*%([hdwmy])>'
" TODO should we add > to all?

let [o, c] = ['[<[]', '[>\]]']  " open and close for ranges
let g:org#regex#timestamp#repeaterdelay0 = org#regex#timestamp#repeater0 . '?' . org#regex#timestamp#delay0 . '?'
let g:org#regex#timestamp#repeaterdelay2 = org#regex#timestamp#repeater1 . '?' . org#regex#timestamp#delay1 . '?'

let g:org#regex#timestamp#timerange0 = '\v%(' . org#regex#timestamp#time0 . '%(-' . org#regex#timestamp#time0 . ')?)'
let g:org#regex#timestamp#timerange1 = '\v(' . org#regex#timestamp#time0 . '%(-' . org#regex#timestamp#time0 . ')?)'
let g:org#regex#timestamp#timerange2 = '\v%(' . org#regex#timestamp#time1 . '%(-' . org#regex#timestamp#time1 . ')?)'
let g:org#regex#timestamp#timerange4 = '\v%(' . org#regex#timestamp#time2 . '%(-' . org#regex#timestamp#time2 . ')?)'

let g:org#regex#timestamp#datetime0 = org#regex#timestamp#date0 . org#regex#timestamp#timerange0 . '?'
let g:org#regex#timestamp#datetime2 = org#regex#timestamp#date1 . org#regex#timestamp#timerange1 . '?'
let g:org#regex#timestamp#full0 = org#regex#timestamp#datetime0 . org#regex#timestamp#repeaterdelay0
let g:org#regex#timestamp#full4 = org#regex#timestamp#datetime2 . org#regex#timestamp#repeaterdelay2
let g:org#regex#timestamp#daterange0 = '\v'.o. org#regex#timestamp#full0 .c. '--' .o. org#regex#timestamp#full0 .c
let g:org#regex#timestamp#daterange2 = '\v'.o. '(' . org#regex#timestamp#full0 . ')' .c. '--' .o. '(' . org#regex#timestamp#full0 . ')' .c

unlet o c

" List {{{2
let g:org#regex#list#bullet#ordered   = '(\d+[.)]|\a[.)])'
let g:org#regex#list#bullet#unordered = '([-+]|\s@1<=\*)'
let g:org#regex#list#bullet           = '([-+]|\s@1<=\*|\d+[.)]|\a[.)])'
let g:org#regex#list#counter_start    = '%(\[\@%(:start:)?(\d+|\a)\])'
let g:org#regex#list#checkbox         = '(\[[ Xx-]\])'
let g:org#regex#list#checkedbox       = '(\[[Xx]\])'
let g:org#regex#list#uncheckedbox     = '(\[ \])'
let g:org#regex#list#tag              = '(%(.*)\s+::)'
let g:org#regex#list#end              = '^\s*\n\s*$'

" whitespace, bullet, counter-set, checkbox, tagtext, itemtext
let g:org#regex#listitem = '\v^(\s*)' . g:org#regex#list#bullet . '\s*' . join([g:org#regex#list#counter_start, g:org#regex#list#checkbox, g:org#regex#list#tag, '(.*)'], '?\s*')

" Maps {{{1
" NAMING: org-ELEMENT[-MODIFIER][-ACTION][-MODIFIER]
" No action is a selection or motion
" Action can also describe a motion.
" Modifier modifies the object
nnoremap <silent> <Plug>(org-check-toggle)           :call org#listitem#check_toggle()<CR>
nnoremap <silent> <Plug>(org-checkbox-add)           :call org#listitem#checkbox_add()<CR>
nnoremap <silent> <Plug>(org-checkbox-remove)        :call org#listitem#checkbox_remove()<CR>
nnoremap <silent> <Plug>(org-checkbox-toggle)        :call org#listitem#checkbox_toggle()<CR>

nnoremap <silent> <Plug>(org-todo-cycle)      :call org#keyword#cycle(1)<CR>
nnoremap <silent> <Plug>(org-todo-cycle-back) :call org#keyword#cycle(-1)<CR>

" Editing:
nnoremap <silent> <Plug>(org-shift-right)      :call org#shift(1, 'n')<CR>
nnoremap <silent> <Plug>(org-shift-left)       :call org#shift(-1, 'n')<CR>
xnoremap <silent> <Plug>(org-shift-right)      :call org#shift(1, 'v')<CR>gv
xnoremap <silent> <Plug>(org-shift-left)       :call org#shift(-1, 'v')<CR>gv
inoremap <silent> <Plug>(org-shift-right) <C-o>:call org#shift(1, 'i')<CR>
inoremap <silent> <Plug>(org-shift-left)  <C-o>:call org#shift(-1, 'i')<CR>

inoremap <silent> <Plug>(org-parse-date)  <C-r>=org#parsedate()<Cr>

onoremap <silent> <Plug>(org-keyword-up)      :<C-u>call org#op#keyword(1)<CR>
onoremap <silent> <Plug>(org-keyword-current) :<C-u>call org#op#keyword(0)<CR>

" Motions:
nnoremap <silent> <Plug>(org-headline-lower-prev) :<C-u>call org#op#lowerlevelhl(v:count1, -1, 'n')<CR>
nnoremap <silent> <Plug>(org-headline-lower-next) :<C-u>call org#op#lowerlevelhl(v:count1,  1, 'n')<CR>
xnoremap <silent> <Plug>(org-headline-lower-prev) :<C-u>call org#op#lowerlevelhl(v:count1, -1, 'v')<CR>
xnoremap <silent> <Plug>(org-headline-lower-next) :<C-u>call org#op#lowerlevelhl(v:count1,  1, 'v')<CR>

nnoremap <silent> <Plug>(org-headline-next) :<C-u>call org#op#nexthl(v:count1, 1, 0, 'n')<CR>
nnoremap <silent> <Plug>(org-headline-prev) :<C-u>call org#op#nexthl(v:count1, -1, 0, 'n')<CR>
nnoremap <silent> <Plug>(org-headline-next-samelevel) :<C-u>call org#op#nexthl(v:count1, 1, 1, 'n')<CR>
nnoremap <silent> <Plug>(org-headline-prev-samelevel) :<C-u>call org#op#nexthl(v:count1, -1, 1, 'n')<CR>

xnoremap <silent> <Plug>(org-headline-next) :<C-u>call org#op#nexthl(v:count1, 1, 0, 'v')<CR>
xnoremap <silent> <Plug>(org-headline-prev) :<C-u>call org#op#nexthl(v:count1, -1, 0, 'v')<CR>
xnoremap <silent> <Plug>(org-headline-next-samelevel) :<C-u>call org#op#nexthl(v:count1, 1, 1, 'v')<CR>
xnoremap <silent> <Plug>(org-headline-prev-samelevel) :<C-u>call org#op#nexthl(v:count1, -1, 1, 'v')<CR>

onoremap <silent> <Plug>(org-headline-next) :<C-u>call org#op#nexthl(v:count1, 1, 0, 'o')<CR>
onoremap <silent> <Plug>(org-headline-prev) :<C-u>call org#op#nexthl(v:count1, -1, 0, 'o')<CR>
onoremap <silent> <Plug>(org-headline-next-samelevel) :<C-u>call org#op#nexthl(v:count1, 1, 1, 'o')<CR>
onoremap <silent> <Plug>(org-headline-prev-samelevel) :<C-u>call org#op#nexthl(v:count1, -1, 1, 'o')<CR>

" :h :map-<script> :map-<unique>

vnoremap <silent> <Plug>(org-section-inner)  :<C-u>call org#section#textobject(v:count1, 1, 'v')<CR>
vnoremap <silent> <Plug>(org-section-around) :<C-u>call org#section#textobject(v:count1, 0, 'v')<CR>
onoremap <silent> <Plug>(org-section-inner)  :<C-u>call org#section#textobject(v:count1, 1, 'o')<CR>
onoremap <silent> <Plug>(org-section-around) :<C-u>call org#section#textobject(v:count1, 0, 'o')<CR>

nnoremap <silent> <Plug>(org-headline-open-above) :call org#edit#openhl(-1)<CR>
nnoremap <silent> <Plug>(org-headline-open-below) :call org#edit#openhl(1)<CR>

nnoremap <silent> <Plug>(org-capture) :call org#capture()<Cr>
xnoremap <silent> <Plug>(org-capture) :call org#capture()<Cr>

" org-goto is like searching in vim.

" Structure editing
" nnoremap <silent> <Plug>(org-insert-heading-at-cursor)(splits-line)
" insert new heading at the end of the subtree
" insert headings with TODO, all drop into insert mode.
" insert item with checkbox in list
" C-t and C-d, operators

" <Up><Left><Down><Right> for promotions, S<Right><Left> for whole subtree

" Autocmds & Cmds {{{1

augroup org_keywords
  autocmd!
  autocmd BufReadPost,BufWritePost *.org call org#outline#keywords()
augroup END

augroup org_completion
  " setup for agenda#completion
  autocmd!
augroup END

command! -nargs=? Capture call org#capture('c')

" TODO:
"  Commands:
"  Agenda
"  Refile
"  Plan
"  Capture

" TODO:
" Formatting:
"   List renumber
"   Tables
"   Spacing headlines
