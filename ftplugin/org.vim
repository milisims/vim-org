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
nmap <buffer> cx <Plug>(org-toggle-check)
nmap <buffer> cd <Plug>(org-cycle-todo)
nmap <buffer> yu <Plug>(org-up-heading)
nmap <buffer> gO <Plug>(org-open-headline-above)
nmap <buffer> go <Plug>(org-open-headline-below)

vmap <buffer> ah <Plug>(org-visual-a-headline)
vmap <buffer> ih <Plug>(org-visual-inner-headline)
omap <buffer> ah <Plug>(org-operator-a-headline)
omap <buffer> ih <Plug>(org-operator-inner-headline)

nmap <buffer> ]h <Plug>(org-cycle-todo)
nmap <buffer> [h <Plug>(org-backcycle-todo)

" Keepers: ?
nmap <buffer> ]] <Plug>(org-next-headline)
nmap <buffer> [[ <Plug>(org-prev-headline)
nmap <buffer> ][ <Plug>(org-next-headline-same-level)
nmap <buffer> [] <Plug>(org-prev-headline-same-level)
