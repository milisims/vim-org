" setlocal spell

" inoremap <silent> <Plug>(org-o)   :call org#newline('o')<CR>a
" inoremap <silent> <Plug>(org-O)   :call org#newline('O')<CR>a
" inoremap <silent> <Plug>(org-BS)  <C-r>=org#format("\<BS>")<CR>
" inoremap <silent> <Plug>(org-CR)  <C-r>=org#format("\<CR>")<CR>
" inoremap <silent> <Plug>(org--)   <C-r>=org#format('-')<CR>
" inoremap <silent> <Plug>(org-+)   <C-r>=org#format('+')<CR>
" inoremap <silent> <Plug>(org-*)   <C-r>=org#format('*')<CR>
" inoremap <silent> <Plug>(org-.)   <C-r>=org#format('.')<CR>
" inoremap <silent> <Plug>(org-))   <C-r>=org#format(')')<CR>
" inoremap <silent> <Plug>(org-C-t) <C-r>=org#indent()<CR>
" inoremap <silent> <Plug>(org-C-d) <C-r>=org#dedent()<CR>
" nnoremap <silent> <Plug>(org-<)   :<C-u>set opfunc=org#dedent<CR>g@
" nnoremap <silent> <Plug>(org->)   :<C-u>set opfunc=org#indent<CR>g@

nnoremap <silent> <Plug>(org-toggle-check)           :call org#list#check_toggle()<CR>
nnoremap <silent> <Plug>(org-add-checkbox)           :call org#list#checkbox_add()<CR>
nnoremap <silent> <Plug>(org-remove-checkbox)        :call org#list#checkbox_remove()<CR>
nnoremap <silent> <Plug>(org-add-or-remove-checkbox) :call org#list#checkbox_toggle()<CR>

nnoremap <silent> <Plug>(org-cycle-todo)     :call org#headline#cycle_keyword(1)<CR>
nnoremap <silent> <Plug>(org-backcycle-todo) :call org#headline#cycle_keyword(-1)<CR>

" Motions:
nnoremap <silent> <Plug>(org-next-headline) :<C-u>call org#motion_headline(v:count1, 1, 0)<CR>
nnoremap <silent> <Plug>(org-prev-headline) :<C-u>call org#motion_headline(v:count1, -1, 0)<CR>

" :h :map-<script> :map-<unique>
nnoremap <silent> <Plug>(org-next-headline-same-level) :<C-u>call org#motion_headline(v:count1, 1, 1)<CR>
nnoremap <silent> <Plug>(org-prev-headline-same-level) :<C-u>call org#motion_headline(v:count1, -1, 1)<CR>

vnoremap <silent> <Plug>(org-visual-a-headline)       :<C-u>call org#visual_headline(0)<CR>
vnoremap <silent> <Plug>(org-visual-inner-headline)   :<C-u>call org#visual_headline(1)<CR>
onoremap <silent> <Plug>(org-operator-a-headline)     :<C-u>call org#operator_headline(0)<CR>
onoremap <silent> <Plug>(org-operator-inner-headline) :<C-u>call org#operator_headline(1)<CR>

nnoremap <silent> <Plug>(org-open-headline-above) :call org#headline#open_above()<CR>
nnoremap <silent> <Plug>(org-open-headline-below) :call org#headline#open_below()<CR>

" org-goto is like searching in vim.

" Structure editing
" g[h and g]h are free
" nnoremap <silent> <Plug>(org-insert-heading-above)
" nnoremap <silent> <Plug>(org-insert-heading-below)
" nnoremap <silent> <Plug>(org-insert-heading-at-cursor)(splits-line)
" insert new heading at the end of the subtree
" insert headings with TODO, all drop into insert mode.
" insert item with checkbox in list
" C-t and C-d, operators

" XXX: Operators act on text objects!!!

" nnoremap <silent> <Plug>(org-toggle-heading) turn list or normal line into heading

" <Up><Left><Down><Right> for promotions, S<Right><Left> for whole subtree

" Subtree operators

onoremap <silent> <Plug>(org-a-subtree)     <Nop>
onoremap <silent> <Plug>(org-inner-subtree)         <Nop>
" onoremap <silent> <Plug>(org-a-checkbox)     <Nop>
" onoremap <silent> <Plug>(org-a-checkbox)     <Nop>

" augroup org
"   autocmd!
"   " TODO: just check for cache in function, rather than forcing the autoload to laod
"   autocmd BufRead *.org call org#build_keyword_cache()
" augroup END

"TODO:
" Commands:
" Sort subtree - prompt for alpha/numeric, later other things (see emacs)
" create sparse tree: regexp, todo, todo-kwd (folds/unfolds automatically -- fold expr? manual?)
                " jump to matches for the tree
" Agenda
" Capture (have good binding?)
" List renumber
