#!/bin/csh
#
# Test ahelp stylesheets
#

# Should check for unknown systems
#
set PLATFORM = `uname`
switch ($PLATFORM)

  case SunOS
    set head     = /data/da/Docs/local
    set xsltproc = /usr/bin/env LD_LIBRARY_PATH=${head}/lib ${head}/bin/xsltproc
    unset head
  breaksw

  case Darwin
    set xsltproc = xsltproc
  breaksw

endsw

## clean up xslt files
#
# [touch one just so that we don't get a 'no file' warning]
touch out/xslt.this-is-a-dummy
rm out/xslt.*

@ ctr = 1
@ ok  = 0
set fail = ""

## single shot tests
#
set type  = test
set site  = ciao
set depth = 1

foreach id ( \
 para-pcdata  para-pcdata-title  equation-para  href-para  \
 synopsis-entry  synopsis-param  syntax-entry  syntax-qexample1  syntax-qexample2  \
 syntax-para  syntax-line-from-paramlist  syntax-block-from-paramlist  bugs1  bugs2  \
 list  list-with-caption  table  table2  table-with-caption  \
 desc-entry  desc-qexample  adesc-entry  adesc-entry-with-title  adesc-entry2  \
 qexamplelist  qexamplelist2  paramlist  \
  )

  set out = out/xslt.$id
  if ( -e $out ) rm -f $out
  $xsltproc --stringparam hardcopy 0 --stringparam bocolor foo --stringparam bgcolor bar in/${id}.xsl in/${id}.xml > $out
  diff out/${id} $out
  if ( $status == 0 ) then
    printf "OK:   %3d  [%s]\n" $ctr $id
    rm -f $out
    @ ok++
  else
    printf "FAIL: %3d  [%s]\n" $ctr $id
    set fail = "$fail $id"
  endif
  @ ctr++
end # foreach: id

## 'parameter' tests
#
# do these individually
#

set srcdir = `pwd`/in

  if ( -e out/xslt.no-seealso ) rm -f out/xslt.no-seealso
  $xsltproc --stringparam hardcopy 0 --stringparam bocolor foo --stringparam bgcolor bar --stringparam seealsofile $srcdir/seealso.empty.xml \
    in/no-seealso.xsl in/no-seealso.xml > out/xslt.no-seealso
  diff out/no-seealso out/xslt.no-seealso
  if ( $status == 0 ) then
    printf "OK:   %3d  [%s]\n" $ctr no-seealso
    rm -f out/xslt.no-seealso
    @ ok++
  else
    printf "FAIL: %3d  [%s]\n" $ctr no-seealso
    set fail = "$fail no-seealso"
  endif
  @ ctr++


  if ( -e out/xslt.seealso ) rm -f out/xslt.seealso
  $xsltproc --stringparam hardcopy 0 --stringparam bocolor foo --stringparam bgcolor bar --stringparam seealsofile $srcdir/seealso.full.xml \
    in/seealso.xsl in/seealso.xml > out/xslt.seealso
  diff out/seealso out/xslt.seealso
  if ( $status == 0 ) then
    printf "OK:   %3d  [%s]\n" $ctr seealso
    rm -f out/xslt.seealso
    @ ok++
  else
    printf "FAIL: %3d  [%s]\n" $ctr seealso
    set fail = "$fail seealso"
  endif
  @ ctr++


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

