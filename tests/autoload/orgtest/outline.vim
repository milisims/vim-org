function! orgtest#outline#full() abort " {{{1
  " call org#outline#multi(...)
endfunction

function! orgtest#outline#file() abort " {{{1
  call assert_report('Not yet implemented.')
  return
  let fname = tempname()
  execute 'edit' fname
  setfiletype org
  call setline(1, ['#+TODO: A B | D', '* A a /'' b', ':PROPERTIES:', ':p1: 1', ':END:', '** B b', 'SCHEDULED: <2020-01-01>', '*** D c', 'CLOSED: <2015-01-01>', '** c', '* d'])

  let outline = org#outline#file(fname)
  call assert_equal(1, outline.list[0].level)
  call assert_equal('a /'' b', outline.list[0].item)
  call assert_equal('/\V\^* A a \/'' b\$/', outline.list[0].cmd)
  call assert_equal({'p1': '1'}, outline.list[0].properties)

  {'lnum': 6, 'filename': '/tmp/nvim5nDVzb/150', 'properties': {}, 'tags': [], 'priority': '',
  'done': '', 'bufnr': 35, 'level': 2, 'kind': 'h',
  'plan': {'DEADLINE': '', 'CLOSED': '', 'TIMESTAMP': '', 'SCHEDULED': {'active': 1, 'end': 1586926800, 'repeater': {}, 'text': '<2020-04-15 Wed>', 'start': 1586926800, 'delay': {}}}, 'cmd': '/\V\^* A a \/ b\$//\V\^** B b\$/', 'text': '** B b', 'todo': '', 'item': 'b'}
  {'lnum': 8, 'filename': '/tmp/nvim5nDVzb/150', 'properties': {}, 'tags': [], 'priority': '', 'done': 'D', 'bufnr': 35, 'level': 3, 'kind': 'h', 'plan': {'DEADLINE': '', 'CLOSED': {'active': 1, 'end': 1586840400, 'repeater': {}, 'text': '<2020-04-14 Tue>', 'start': 1586840400, 'delay': {}}, 'TIMESTAMP': '', 'SCHEDULED': ''}, 'cmd': '/\V\^* A a \/ b\$//\V\^** B b\$//\V\^*** D c\$/', 'text': '*** D c', 'todo': 'D', 'item': 'c'}
  {'lnum': 8, 'filename': '/tmp/nvim5nDVzb/150', 'properties': {}, 'tags': [], 'priority': '', 'done': 'D', 'bufnr': 35, 'level': 3, 'kind': 'h', 'plan': {'DEADLINE': '', 'CLOSED': {'active': 1, 'end': 1586840400, 'repeater': {}, 'text': '<2020-04-14 Tue>', 'start': 1586840400, 'delay': {}}, 'TIMESTAMP': '', 'SCHEDULED': ''}, 'cmd': '/\V\^* A a \/ b\$//\V\^*** D c\$/', 'text': '*** D c', 'todo': 'D', 'item': 'c'}
  {'lnum': 10, 'filename': '/tmp/nvim5nDVzb/150', 'properties': {}, 'tags': [], 'priority': '', 'done': '', 'bufnr': 35, 'level': 2, 'kind': 'h', 'plan': {'DEADLINE': '', 'CLOSED': '', 'TIMESTAMP': '', 'SCHEDULED': ''}, 'cmd': '/\V\^* A a \/ b\$//\V\^** c\$/', 'text': '** c', 'todo': '', 'item': 'c'}
  {'lnum': 11, 'filename': '/tmp/nvim5nDVzb/150', 'properties': {}, 'tags': [], 'priority': '', 'done': '', 'bufnr': 35, 'level': 1, 'kind': 'h', 'plan': {'DEADLINE': '', 'CLOSED': '', 'TIMESTAMP': '', 'SCHEDULED': ''}, 'cmd': '/\V\^* d\$/', 'text': '* d', 'todo': '', 'item': 'd'}


  " ['list', 'lnums', 'subtrees', 'mtime', 'keywords']

endfunction

function! orgtest#outline#update() abort " {{{1
  " only info from #get. update C
  call s:setup()
  let orig = org#outline#file(g:orgtest#fname)
  call org#headline#update(orig, modified)
endfunction

function! orgtest#outline#keywords() abort " {{{1
  call orgtest#fsetup('keyword', ['#+TODO: A B C | D E'])
  call assert_equal({'todo': ['A', 'B', 'C'], 'done': ['D', 'E'], 'all': ['A', 'B', 'C', 'D', 'E']}, org#outline#keywords())
endfunction
