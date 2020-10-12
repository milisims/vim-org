" setlocal spell
setlocal indentexpr=GetOrgIndent()
setlocal indentkeys=0#,0*,0-,0+,0.,o,O,!^F
setlocal foldmethod=expr
setlocal foldexpr=org#fold#expr(v:lnum)
setlocal foldtext=org#fold#text()
setlocal formatoptions=1tronlj
setlocal commentstring=#\ %s
setlocal comments=b:+,b:-,fb:*
setlocal formatlistpat=^\\s*\\w\\+[.)]\\s*\\\|^\\s*\\([-+]\\\|\\s\\@1<=\\*\\)\\s\\+
setlocal formatexpr=org#util#format()

" So backspace and <C-t> and <C-d> behave consistently
setlocal softtabstop=0
setlocal shiftwidth=2
setlocal expandtab

" TODO: counts!
" Questionable:
nmap <buffer> cax <Plug>(org-checkbox-toggle)
nmap <buffer> cx <Plug>(org-check-toggle)
nmap <buffer> cd <Plug>(org-todo-cycle)
" nmap <buffer> yu <Plug>(org-headline-above)
nmap <buffer> gO <Plug>(org-headline-open-above)
nmap <buffer> go <Plug>(org-headline-open-below)

xmap <buffer> ah <Plug>(org-headline-around)
xmap <buffer> ih <Plug>(org-headline-inner)
omap <buffer> ah <Plug>(org-headline-around)
omap <buffer> ih <Plug>(org-headline-inner)

xmap <buffer> ac <Plug>(org-section-around)
xmap <buffer> ic <Plug>(org-section-inner)
omap <buffer> ac <Plug>(org-section-around)
omap <buffer> ic <Plug>(org-section-inner)

omap <buffer> ak <Plug>(org-keyword-up)
omap <buffer> ik <Plug>(org-keyword-current)

xmap <buffer> ak <Plug>(org-keyword-up)
xmap <buffer> ik <Plug>(org-keyword-current)

nmap <buffer> ]k <Plug>(org-todo-cycle)
nmap <buffer> [k <Plug>(org-todo-cycle-back)

" Add property to current headline
nmap <buffer> gap <Plug>(org-property-add)
" Add property to first headline that has properties, or the top level headline
nmap <buffer> gaP <Plug>(org-property-add-top)

nmap <buffer> gas <Plug>(org-headline-schedule)
nmap <buffer> gaS <Plug>(org-headline-schedule-top)

" Keepers: ?
nmap <buffer> ]] <Plug>(org-headline-next)
nmap <buffer> [[ <Plug>(org-headline-prev)
nmap <buffer> ][ <Plug>(org-headline-next-samelevel)
nmap <buffer> [] <Plug>(org-headline-prev-samelevel)

xmap <buffer> ]] <Plug>(org-headline-next)
xmap <buffer> [[ <Plug>(org-headline-prev)
xmap <buffer> ][ <Plug>(org-headline-next-samelevel)
xmap <buffer> [] <Plug>(org-headline-prev-samelevel)

omap <buffer> ]] <Plug>(org-headline-next)
omap <buffer> [[ <Plug>(org-headline-prev)
omap <buffer> ][ <Plug>(org-headline-next-samelevel)
omap <buffer> [] <Plug>(org-headline-prev-samelevel)

nmap <buffer> >>    <Plug>(org-shift-right)
nmap <buffer> <<    <Plug>(org-shift-left)
xmap <buffer> >     <Plug>(org-shift-right)
xmap <buffer> <     <Plug>(org-shift-left)
imap <buffer> <C-t> <Plug>(org-shift-right)
imap <buffer> <C-d> <Plug>(org-shift-left)
nnoremap <buffer> >< >>
nnoremap <buffer> <> <<

nmap <buffer> ]u <Plug>(org-headline-lower-next)
nmap <buffer> [u <Plug>(org-headline-lower-prev)
xmap <buffer> ]u <Plug>(org-headline-lower-next)
xmap <buffer> [u <Plug>(org-headline-lower-prev)

inoremap <buffer> <C-g>t <C-o>diW<C-r>=org#time#dict(@").totext()<Cr>
inoremap <buffer> <C-g><C-t> <C-o>diW<C-r>=org#time#dict(@").totext()<Cr>

" DEV STUFF

command! -nargs=* Plan call org#plan('.')
" command! -nargs=* -complete=customlist,org#time#completion Plan call org#plan('.')
command! -buffer -nargs=* -complete=customlist,org#outline#complete Refile call org#refile(<q-args>)
