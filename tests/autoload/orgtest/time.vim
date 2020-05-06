
function! orgtest#time#dict() abort " {{{1
  " Basic functionality
  let tz = strftime('%z', 0)
  let td = org#time#dict(0)
  call assert_equal('<' . strftime('%Y-%m-%d %a %R', 0) . '>', td.totext('t'))
  unlet td.totext
  call assert_equal({'active': 1, 'end': 0, 'repeater': {}, 'start': 0, 'delay': {}}, td)
  call assert_true(org#time#dict('now').active)
  call assert_false(org#time#dict('[now]').active)
  call assert_true(org#time#dict('<now>').active)
  call assert_equal({'val': 86400, 'type': '+', 'text': '+1d'}, org#time#dict('now +1d').repeater)
  call assert_equal({'val': 86400, 'type': '+', 'text': '+1d'}, org#time#dict('now +1d -1d').repeater)
  call assert_equal({'val': 604800, 'type': '.+', 'text': '.+1w'}, org#time#dict('now .+1w').repeater)
  call assert_equal({'val': 604800, 'type': '++', 'text': '++1w'}, org#time#dict('now ++1w').repeater)
  call assert_equal({'val': 86400, 'type': '--', 'text': '--1w'}, org#time#dict('now --1d +1d').delay)
  call assert_equal({'val': 86400, 'type': '--', 'text': '--1w'}, org#time#dict('now +1d --1d').delay)

  " Test number
  let td = org#time#dict(0)
  call assert_equal('<' . strftime('%Y-%m-%d %a %R', 0) . '>', org#time#dict(0).totext('t'))
  call assert_equal('<' . strftime('%Y-%m-%d %a %R', 1000000) . '>', org#time#dict(1000000).totext('t'))

  " Special strings
  " These two tests fail at midnight:
  call assert_equal('<' . strftime('%Y-%m-%d %a %R') . '>', org#time#dict('now').totext())
  call assert_true(org#time#dict('today').totext() < org#time#dict('now').totext())

  call assert_equal('<' . strftime('%Y-%m-%d %a') . '>', org#time#dict('today').totext())
  call assert_equal(strftime(''), strftime(org#time#dict('tomorrow').start))

  " relative times
  let lt = localtime()
  let td = org#time#dict('now', lt)
  unlet td.totext
  call assert_equal({'active': 1, 'end': lt, 'start': lt, 'repeater': {}, 'delay': {}}, td)
  call assert_true(abs(localtime() - org#time#dict('now')) <= 1)

  " Relative day of weeks

  " Dates

endfunction


function! orgtest#time#tdiff() abort " {{{1
  call assert_report("No test for org#time#diff(t1, t2)")
  " call assert_equal(, org#time#diff(t1, t2))
endfunction
