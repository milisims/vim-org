" setlocal spell
" setlocal foldmethod=syntax

setlocal indentexpr=GetOrgIndent()
" Default is nolisp nosmartindent autoindent.
setlocal indentkeys=0#,0*,0-,0+,0.,o,O
setlocal foldmethod=indent
setlocal formatoptions=1tronlj
setlocal commentstring='#%s'
setlocal comments=b:+,b:-,fb:*
setlocal formatlistpat=^\\s*\\w\\+[.)]\\s*

" So backspace and <C-t> and <C-d> behave consistently
setlocal softtabstop=0
setlocal shiftwidth=2
setlocal expandtab

" TODO: counts!
" Questionable:
nmap <buffer> cax <Plug>(org-add-or-remove-checkbox)
nmap <buffer> cx <Plug>(org-check-toggle)
nmap <buffer> cd <Plug>(org-todo-cycle)
" nmap <buffer> yu <Plug>(org-headline-above)
nmap <buffer> gO <Plug>(org-headline-open-above)
nmap <buffer> go <Plug>(org-headline-open-below)

vmap <buffer> ah <Plug>(org-section-visual-around)
vmap <buffer> ih <Plug>(org-section-visual-inner)
omap <buffer> ah <Plug>(org-section-operator-around)
omap <buffer> ih <Plug>(org-section-operator-inner)

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
nmap <buffer> ][ <Plug>(org-headline-samelevel-next)
nmap <buffer> [] <Plug>(org-headline-samelevel-prev)
