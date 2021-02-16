function! s:markdone() abort
  " Meant to be called in an autocmd orgkeyworddone
  let plan = org#plan#get('.')
  if empty(plan)
    return
  endif
  let repeat = empty(filter(values(plan), 'empty(v:val.repeater)'))
  for [kind, time] in items(plan)
    if repeat
      let plan[kind] = org#time#repeat(time)
    else
      let plan[kind].active = 0
    endif
  endfor
  call setline(org#headline#at('.') + 1, org#plan#totext(plan))
  if repeat
    call org#keyword#set(g:org#keyword#old)
  endif
endfunction

function! s:marktodo() abort
  let plan = org#plan#get('.')
  if empty(plan)  " Otherwise, will set line
    return
  endif
  for kind in keys(plan)
    if kind != 'CLOSED'
      let plan[kind].active = 1
    endif
  endfor
  call setline(org#headline#at('.') + 1, org#plan#totext(plan))
endfunction

augroup org_keywords
  autocmd!
  autocmd User OrgKeywordDone call s:markdone()
  autocmd User OrgKeywordToDo call s:marktodo()
  autocmd BufEnter,BufWritePost *.org call org#outline#keywords()
augroup END

augroup org_completion
  " setup for agenda#completion
  autocmd!
augroup END

augroup org_agenda
  autocmd!
augroup END

command! -nargs=? Capture call org#capture('c')
command! -nargs=+ View call org#agenda#view(<q-args>)

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
