" {{{ Variables

let org#timestamp#scheduled#time = get(g:, 'org#timestamp#scheduled#time', 3)
let org#timestamp#deadline#time = get(g:, 'org#timestamp#deadline#time', 3)
let org#dir = '~/org'
let org#inbox = org#dir . '/inbox.org'

" }}}

" {{{ Mappings
" NAMING: org-ELEMENT[-MODIFIER][-ACTION][-MODIFIER]
" No action is a selection or motion
" Action can also describe a motion.
" Modifier modifies the object
nnoremap <silent> <Plug>(org-check-toggle)           :call org#list#check_toggle()<CR>
nnoremap <silent> <Plug>(org-checkbox-add)           :call org#list#checkbox_add()<CR>
nnoremap <silent> <Plug>(org-checkbox-remove)        :call org#list#checkbox_remove()<CR>
nnoremap <silent> <Plug>(org-checkbox-toggle)        :call org#list#checkbox_toggle()<CR>

nnoremap <silent> <Plug>(org-todo-cycle)      :call org#keyword#cycle(1)<CR>
nnoremap <silent> <Plug>(org-todo-cycle-back) :call org#keyword#cycle(-1)<CR>

" Editing:
nnoremap <silent> <Plug>(org-shift-right)      :call org#shift(1, 'n')<CR>
nnoremap <silent> <Plug>(org-shift-left)       :call org#shift(-1, 'n')<CR>
xnoremap <silent> <Plug>(org-shift-right)      :call org#shift(1, 'v')<CR>gv
xnoremap <silent> <Plug>(org-shift-left)       :call org#shift(-1, 'v')<CR>gv
inoremap <silent> <Plug>(org-shift-right) <C-o>:call org#shift(1, 'i')<CR>
inoremap <silent> <Plug>(org-shift-left)  <C-o>:call org#shift(-1, 'i')<CR>

" Motions:
nnoremap <silent> <Plug>(org-headline-lower-prev) :<C-u>call org#headline#lower(v:count1, -1, 'n')<CR>
nnoremap <silent> <Plug>(org-headline-lower-next) :<C-u>call org#headline#lower(v:count1,  1, 'n')<CR>
xnoremap <silent> <Plug>(org-headline-lower-prev) :<C-u>call org#headline#lower(v:count1, -1, 'v')<CR>
xnoremap <silent> <Plug>(org-headline-lower-next) :<C-u>call org#headline#lower(v:count1,  1, 'v')<CR>

nnoremap <silent> <Plug>(org-headline-next) :<C-u>call org#headline#jump(v:count1, 1, 0, 'n')<CR>
nnoremap <silent> <Plug>(org-headline-prev) :<C-u>call org#headline#jump(v:count1, -1, 0, 'n')<CR>
nnoremap <silent> <Plug>(org-headline-next-samelevel) :<C-u>call org#headline#jump(v:count1, 1, 1, 'n')<CR>
nnoremap <silent> <Plug>(org-headline-prev-samelevel) :<C-u>call org#headline#jump(v:count1, -1, 1, 'n')<CR>

xnoremap <silent> <Plug>(org-headline-next) :<C-u>call org#headline#jump(v:count1, 1, 0, 'v')<CR>
xnoremap <silent> <Plug>(org-headline-prev) :<C-u>call org#headline#jump(v:count1, -1, 0, 'v')<CR>
xnoremap <silent> <Plug>(org-headline-next-samelevel) :<C-u>call org#headline#jump(v:count1, 1, 1, 'v')<CR>
xnoremap <silent> <Plug>(org-headline-prev-samelevel) :<C-u>call org#headline#jump(v:count1, -1, 1, 'v')<CR>

onoremap <silent> <Plug>(org-headline-next) :<C-u>call org#headline#jump(v:count1, 1, 0, 'o')<CR>
onoremap <silent> <Plug>(org-headline-prev) :<C-u>call org#headline#jump(v:count1, -1, 0, 'o')<CR>
onoremap <silent> <Plug>(org-headline-next-samelevel) :<C-u>call org#headline#jump(v:count1, 1, 1, 'o')<CR>
onoremap <silent> <Plug>(org-headline-prev-samelevel) :<C-u>call org#headline#jump(v:count1, -1, 1, 'o')<CR>

" :h :map-<script> :map-<unique>

vnoremap <silent> <Plug>(org-section-inner)  :<C-u>call org#section#textobject(v:count1, 1, 'v')<CR>
vnoremap <silent> <Plug>(org-section-around) :<C-u>call org#section#textobject(v:count1, 0, 'v')<CR>
onoremap <silent> <Plug>(org-section-inner)  :<C-u>call org#section#textobject(v:count1, 1, 'o')<CR>
onoremap <silent> <Plug>(org-section-around) :<C-u>call org#section#textobject(v:count1, 0, 'o')<CR>

nnoremap <silent> <Plug>(org-headline-open-above) :call org#headline#open(-1)<CR>
nnoremap <silent> <Plug>(org-headline-open-below) :call org#headline#open(1)<CR>

nnoremap <silent> <Plug>(org-capture) :call org#capture()<Cr>
xnoremap <silent> <Plug>(org-capture) :call org#capture()<Cr>

" }}}

" org-goto is like searching in vim.

" Structure editing
" g[h and g]h are free
" nnoremap <silent> <Plug>(org-insert-heading-at-cursor)(splits-line)
" insert new heading at the end of the subtree
" insert headings with TODO, all drop into insert mode.
" insert item with checkbox in list
" C-t and C-d, operators

" <Up><Left><Down><Right> for promotions, S<Right><Left> for whole subtree


augroup org_keywords
  autocmd!
  autocmd BufReadPost,BufWritePost *.org call org#keyword#get()
  autocmd BufEnter,BufWritePost *.org call org#keyword#highlight()
augroup END

augroup org_completion
  autocmd!
  autocmd CmdlineLeave * silent! unlet g:org#agenda#complcache
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
