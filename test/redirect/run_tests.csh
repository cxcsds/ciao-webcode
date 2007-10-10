#!/bin/csh
#
# Test redirect stylesheets
#

set head     = /data/da/Docs/local
set xsltproc = ${head}/bin/xsltproc
set ldpath   = ${head}/lib

## clean up xslt files
#
# [touch one just so that we don't get a 'no file' warning]
touch out/xslt.this-is-a-dummy
rm out/xslt.*

@ ctr = 1
@ ok  = 0
set fail = ""

# unlike most tests we can use the actual stylesheet
#
set xsl = ../../redirect.xsl

foreach id ( \
 list  foo  ahelp-index  \
  )

  set out = out/xslt.$id
  if ( -e $out ) rm -f $out
  set outname = `/usr/bin/env LD_LIBRARY_PATH=$ldpath $xsltproc --stringparam filename $out $xsl in/$id.xml`
  set statusa = $status
  set statusb = 1
  if ( $statusa == 0 ) then
    # avoid excess warning messages if we know it has failed
    # for some reason within the stylesheet
    #
    diff out/${id} $out
    set statusb = $status
  endif
  if ( $statusa == 0 && $statusb == 0 && $outname == $out ) then
    printf "OK:   %3d  [%s]\n" $ctr $id
    rm -f $out
    @ ok++
  else
    printf "FAIL: %3d  [%s]\n" $ctr $id
    set fail = "$fail $id"
  endif
  @ ctr++
end # foreach: id


## Report

@ ctr--
if ( $ctr == $ok ) then
  echo " "
  echo "Success: all tests passed"
  echo " "
else
  @ num = $ctr - $ok
  echo " "
  echo "Error: the following $num tests failed"
  echo "$fail"
  echo " "
  echo "See the out/xslt.<> files for info on the failures"
  echo " "
  exit 1
endif

## end
exit

