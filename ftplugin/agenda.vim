setlocal buftype=nofile
setlocal nobuflisted
setlocal nowrap
setlocal nospell
setlocal nomodifiable
setlocal bufhidden=delete
" TODO check if map exists
nmap <buffer> <Cr> <Plug>(org-agenda-goto-headline)

command! -buffer -nargs=+ Filter call org#agenda#filterview(<q-args>)
command! -buffer -nargs=+ Sort call org#agenda#sortview(<q-args>)
