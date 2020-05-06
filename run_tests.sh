#!/bin/bash

orgdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tempfile=$(mktemp)
vim --clean +"
set runtimepath+=$orgdir/tests
set runtimepath+=$orgdir
syntax off
runtime! plugin/org*.vim
let g:orgtest#errfile = '$tempfile'
" +"OrgRunTests $@"
rv=$?
cat $tempfile
rm $tempfile
exit $rv
