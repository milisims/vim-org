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

" NAMING: org-ELEMENT[-MODIFIER][-ACTION][-MODIFIER]
" No action is a selection or motion
" Action can also describe a motion.
" Modifier modifies the object
nnoremap <silent> <Plug>(org-check-toggle)           :call org#list#check_toggle()<CR>
nnoremap <silent> <Plug>(org-checkbox-add)           :call org#list#checkbox_add()<CR>
nnoremap <silent> <Plug>(org-checkbox-remove)        :call org#list#checkbox_remove()<CR>
nnoremap <silent> <Plug>(org-checkbox-toggle)        :call org#list#checkbox_toggle()<CR>

nnoremap <silent> <Plug>(org-todo-cycle)      :call org#headline#cycle_keyword(1)<CR>
nnoremap <silent> <Plug>(org-todo-cycle-back) :call org#headline#cycle_keyword(-1)<CR>

" Motions:
nnoremap <silent> <Plug>(org-headline-next) :<C-u>call org#motion_headline(v:count1, 1, 0)<CR>
nnoremap <silent> <Plug>(org-headline-prev) :<C-u>call org#motion_headline(v:count1, -1, 0)<CR>

" :h :map-<script> :map-<unique>
nnoremap <silent> <Plug>(org-headline-next-samelevel) :<C-u>call org#motion_headline(v:count1, 1, 1)<CR>
nnoremap <silent> <Plug>(org-headline-prev-samelevel) :<C-u>call org#motion_headline(v:count1, -1, 1)<CR>

vnoremap <silent> <Plug>(org-section-visual-inner)    :<C-u>call org#visual_headline(1)<CR>
vnoremap <silent> <Plug>(org-section-visual-around)   :<C-u>call org#visual_headline(0)<CR>
onoremap <silent> <Plug>(org-section-operator-inner)  :<C-u>call org#operator_headline(1)<CR>
onoremap <silent> <Plug>(org-section-operator-around) :<C-u>call org#operator_headline(0)<CR>

nnoremap <silent> <Plug>(org-headline-open-above) :call org#headline#open_above()<CR>
nnoremap <silent> <Plug>(org-headline-open-below) :call org#headline#open_below()<CR>

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
" Capture

" TODO:
" Formatting:
"   List renumber
"   Tables
"   Spacing headlines
