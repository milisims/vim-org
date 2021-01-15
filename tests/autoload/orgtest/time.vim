
function! orgtest#time#dict() abort " {{{1
  " Seconds per hour, day, week, month (approximately)
  let sp = {'h': 3600, 'd': 86400, 'w': 604800, 'm': 2678400}
  let now = localtime()
  let tomorrow = localtime() + sp.d
  let yesterday = localtime() - sp.d
  let nextweek = localtime() + sp.w
  let nextmonth = localtime() + sp.m

  let today     = strftime('%u')
  " If today is monday, %u -> 1, 1 week later.
  let monday    = (8 - today)  % 7 * sp.d + now
  let tuesday   = (9 - today)  % 7 * sp.d + now
  let wednesday = (10 - today) % 7 * sp.d + now
  let thursday  = (11 - today) % 7 * sp.d + now
  let friday    = (12 - today) % 7 * sp.d + now
  let saturday  = (13 - today) % 7 * sp.d + now
  let sunday    = (14 - today) % 7 * sp.d + now
  let twosday   = tuesday + sp.w
  let lasttues  = tuesday - sp.w

  " number to tdict
  let td = org#time#dict(0)
  call assert_equal('<' . strftime('%Y-%m-%d %a %R', 0) . '>', td.totext('t'))
  unlet td.totext
  call assert_equal({'active': 1, 'end': 0, 'repeater': {}, 'start': 0, 'delay': {}}, td)
  call assert_false(org#time#dict('[1]').active)
  call assert_true(org#time#dict('<0>').active)

  " Timestamps
  call assert_equal('<1998-06-21 Sun 11:14>', org#time#dict('<1998-06-21 Sun 11:14>').totext())
  " call assert_equal('<1998-06-21 Sun 11:14>', org#time#dict('<1998-06-21 Sun 11:14>').totext())

  " Test keywords
  call assert_equal(strftime('%Y-%m-%d', now), org#time#dict('today', now).totext('TBD'))
  call assert_equal(strftime('%Y-%m-%d', tomorrow), org#time#dict('tomorrow', now).totext('TBD'))
  call assert_equal(strftime('%Y-%m-%d', yesterday), org#time#dict('yesterday', now).totext('TBD'))

  " Relative day of weeks
  call assert_equal(strftime('%Y-%m-%d', monday)   , org#time#dict('monday'  , now).totext('TBD'))
  call assert_equal(strftime('%Y-%m-%d', tuesday)  , org#time#dict('tue'     , now).totext('TBD'))
  call assert_equal(strftime('%Y-%m-%d', wednesday), org#time#dict('wednesda', now).totext('TBD'))
  call assert_equal(strftime('%Y-%m-%d', thursday) , org#time#dict('thur'    , now).totext('TBD'))
  call assert_equal(strftime('%Y-%m-%d', friday)   , org#time#dict('+friday' , now).totext('TBD'))
  call assert_equal(strftime('%Y-%m-%d', saturday) , org#time#dict('saturday', now).totext('TBD'))
  call assert_equal(strftime('%Y-%m-%d', sunday)   , org#time#dict('sunday'  , now).totext('TBD'))
  call assert_equal(strftime('%Y-%m-%d', twosday)  , org#time#dict('+2tues'  , now).totext('TBD'))
  call assert_equal(strftime('%Y-%m-%d', lasttues) , org#time#dict('-tues'   , now).totext('TBD'))

  " Relative modifiers[hdwmy]
  call assert_equal(strftime('%Y-%m-%d', nextweek), org#time#dict('+1w', now).totext('TBD'))

  " Bugs
  call assert_equal('<2020-10-26 Mon>', org#time#dict('mon', 1603570918).totext())

endfunction


function! orgtest#time#tdiff() abort " {{{1
  call assert_report("No test for org#time#diff(t1, t2)")
  " call assert_equal(, org#time#diff(t1, t2))
endfunction
