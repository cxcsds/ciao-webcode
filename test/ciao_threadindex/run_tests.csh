#!/bin/csh
#
# Test ciao_threadindex stylesheets
#

# Should check for unknown systems
#
set PLATFORM = `uname`
switch ($PLATFORM)

  case SunOS
    set head     = /data/da/Docs/local
    set xsltproc = "/usr/bin/env LD_LIBRARY_PATH=${head}/lib ${head}/bin/xsltproc"
    unset head
  breaksw

  case Darwin
    set xsltproc = xsltproc
  breaksw

  case Linux
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

## multiple depths
#
set type   = live
set site   = ciao

# note: 
#   copied over one version of the example thread
#
set threaddir = `pwd`/
set params = "--stringparam sourcedir /data/da/Docs/web/devel/test/threads/ --stringparam threadDir $threaddir --stringparam hardcopy 0 --stringparam ahelpindex `pwd`/../links/ahelpindexfile.xml --stringparam type $type --stringparam site $site "

foreach id ( \
 list  sublist  sublist2  title  \
 dataset  package  make-datatable  \
  )

  foreach depth ( 1 2 )
    set h = ${id}_d${depth}
    set out = out/xslt.$h

    if ( -e $out ) rm -f $out
    $xsltproc $params --stringparam depth $depth in/${id}.xsl in/${id}.xml > $out
    set statusa = $status
    set statusb = 1
    if ( $statusa == 0 ) then
      # avoid excess warning messages if we know it has failed
      # for some reason within the stylesheet
      #
      diff out/${h} $out
      set statusb = $status
    endif
    if ( $statusa == 0 && $statusb == 0 ) then
      printf "OK:   %3d  [%s]\n" $ctr $h
      rm -f $out
      @ ok++
    else
      printf "FAIL: %3d  [%s]\n" $ctr $h
      set fail = "$fail $h"
    endif
    @ ctr++
  end # foreach: depth

end
## multiple site/depths
#
set type  = test

set params = "--stringparam sourcedir /data/da/Docs/web/devel/test/threads/ --stringparam hardcopy 0 --stringparam ahelpindex `pwd`/../links/ahelpindexfile.xml --stringparam type $type "

foreach id ( \
 script  \
  )

  foreach site ( ciao sherpa )
    foreach depth ( 1 2 )
      set h = ${id}_${site}_d${depth}
      set out = out/xslt.$h

      if ( -e $out ) rm -f $out
      $xsltproc $params --stringparam depth $depth --stringparam site $site in/${id}.xsl in/${id}.xml > $out
      set statusa = $status
      set statusb = 1
      if ( $statusa == 0 ) then
        # avoid excess warning messages if we know it has failed
        # for some reason within the stylesheet
        #
        diff out/${h} $out
        set statusb = $status
      endif
      if ( $statusa == 0 && $statusb == 0 ) then
        printf "OK:   %3d  [%s]\n" $ctr $h
        rm -f $out
        @ ok++
      else
        printf "FAIL: %3d  [%s]\n" $ctr $h
        set fail = "$fail $h"
      endif
      @ ctr++
    end # foreach: depth
  end # foreach: site

end

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

