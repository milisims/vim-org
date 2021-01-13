#!/usr/bin/env bash

orgdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $orgdir
thistest=$(mktemp)
testlist=$(mktemp)

opts="set runtimepath+=$orgdir/tests
set runtimepath+=$orgdir
let g:orgtest#stdout = 1
syntax off
runtime! plugin/org*.vim"

grep -rohP '(?#function! )orgtest#\w*#[^()]*' tests/autoload > $testlist
if [ $# -gt 0 ]; then
  grep "$1" $testlist > $testlist.copy
  mv $testlist.copy $testlist
fi

for testname in $(cat $testlist); do
  vim  --clean -e +"$opts" +"TestOrg! $testname" - > $thistest
  if [ "$(cat $thistest | wc -l)" -gt 0 ]; then
    head -n-1 $thistest  # the last line just confirms the test executed
  else
    echo $(grep -ronH $testname tests/autoload | sed 's/:/::/g')"::E::Test failed to complete"
    # filename::module::lnum::E::message
  fi
done
