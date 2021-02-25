nnoremap <silent> <Plug>(org-check-toggle)           :call org#listitem#check_toggle()<CR>
nnoremap <silent> <Plug>(org-checkbox-add)           :call org#listitem#checkbox_add()<CR>
nnoremap <silent> <Plug>(org-checkbox-remove)        :call org#listitem#checkbox_remove()<CR>
nnoremap <silent> <Plug>(org-checkbox-toggle)        :call org#listitem#checkbox_toggle()<CR>

nnoremap <silent> <Plug>(org-todo-cycle)      :<C-u>call org#keyword#cycle(v:count1)<CR>
nnoremap <silent> <Plug>(org-todo-cycle-back) :<C-u>call org#keyword#cycle(-v:count1)<CR>

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

nnoremap <silent> <Plug>(org-headline-next)           :<C-u>call org#op#nexthl(v:count1, 1, 0, 'n')<CR>
nnoremap <silent> <Plug>(org-headline-prev)           :<C-u>call org#op#nexthl(v:count1, -1, 0, 'n')<CR>
nnoremap <silent> <Plug>(org-headline-next-samelevel) :<C-u>call org#op#nexthl(v:count1, 1, 1, 'n')<CR>
nnoremap <silent> <Plug>(org-headline-prev-samelevel) :<C-u>call org#op#nexthl(v:count1, -1, 1, 'n')<CR>

xnoremap <silent> <Plug>(org-headline-next)           :<C-u>call org#op#nexthl(v:count1, 1, 0, 'v')<CR>
xnoremap <silent> <Plug>(org-headline-prev)           :<C-u>call org#op#nexthl(v:count1, -1, 0, 'v')<CR>
xnoremap <silent> <Plug>(org-headline-next-samelevel) :<C-u>call org#op#nexthl(v:count1, 1, 1, 'v')<CR>
xnoremap <silent> <Plug>(org-headline-prev-samelevel) :<C-u>call org#op#nexthl(v:count1, -1, 1, 'v')<CR>

onoremap <silent> <Plug>(org-headline-next)           :<C-u>call org#op#nexthl(v:count1, 1, 0, 'o')<CR>
onoremap <silent> <Plug>(org-headline-prev)           :<C-u>call org#op#nexthl(v:count1, -1, 0, 'o')<CR>
onoremap <silent> <Plug>(org-headline-next-samelevel) :<C-u>call org#op#nexthl(v:count1, 1, 1, 'o')<CR>
onoremap <silent> <Plug>(org-headline-prev-samelevel) :<C-u>call org#op#nexthl(v:count1, -1, 1, 'o')<CR>

vnoremap <silent> <Plug>(org-section-inner)  :<C-u>call org#section#textobject(v:count1, 1, 'v')<CR>
vnoremap <silent> <Plug>(org-section-around) :<C-u>call org#section#textobject(v:count1, 0, 'v')<CR>
onoremap <silent> <Plug>(org-section-inner)  :<C-u>call org#section#textobject(v:count1, 1, 'o')<CR>
onoremap <silent> <Plug>(org-section-around) :<C-u>call org#section#textobject(v:count1, 0, 'o')<CR>

nnoremap <silent> <Plug>(org-headline-open-above) :call org#edit#openhl(-1)<CR>
nnoremap <silent> <Plug>(org-headline-open-below) :call org#edit#openhl(1)<CR>

nnoremap <silent> <Plug>(org-capture) :call org#capture()<Cr>
xnoremap <silent> <Plug>(org-capture) :call org#capture()<Cr>

nnoremap <silent> <Plug>(org-follow-link) :execute org#link#atcursor()<Cr>
