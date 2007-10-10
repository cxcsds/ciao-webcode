#!/bin/csh -f
#
# Note: we do not re-create the tests (if a ./make_tests.pl
#       exists), just run them
#
foreach x ( */run_tests.csh )
  set dname = $x:h
  cd $dname
  ./run_tests.csh > /dev/null
  if ( $status == 0 ) then
    echo "PASS: $dname"
  else
    echo "FAIL: $dname"
  endif
  cd ..
end

## End of script
