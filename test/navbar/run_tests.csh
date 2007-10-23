#!/bin/csh
#
# Test navbar stylesheets
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


set PLATFORM = `uname`
switch ($PLATFORM)

  case SunOS
    set diffprog = /data/dburke2/local32/bin/diff
  breaksw

  case Darwin
    set diffprog = diff
  breaksw

    case Linux
    set diffprog = diff
  breaksw

endsw

## multiple type/site/depth tests
#
foreach id ( \
 list-li-navbar  links  news-item  section-id-locallink  \
 section-id-locallink-matchid  section-id-sitelink  section-id-sitelink-matchid  section-id-nolink  navbar-basedir-nologo  \
 navbar-subdir-nologo  navbar-basedir-logo-image  navbar-subdir-logo-image  navbar-basedir-logo-both  navbar-subdir-logo-both  \
 navbar-basedir-logo-text  navbar-subdir-logo-text  navbar-basedir-sitelink-logo-text  navbar-subdir-sitelink-logo-text  \
  )

  foreach type ( live test )
    foreach site ( ciao chart sherpa )
      foreach depth ( 1 2 )
        set h = ${id}_${type}_${site}_d${depth}
        set out = out/xslt.$h

        if ( -e $out ) rm -f $out
        $xsltproc --stringparam type $type --stringparam site $site --stringparam depth $depth --stringparam ahelpindex `pwd`/../links/ahelpindexfile.xml --stringparam hardcopy 0 --stringparam newsfileurl /ciao9.9/news.html --stringparam pagename foo in/${id}.xsl in/${id}.xml > $out
        $diffprog -u out/${h} $out
        if ( $status == 0 ) then
          printf "OK:   %3d  [%s]\n" $ctr $h
          rm -f $out
          @ ok++
        else
          printf "FAIL: %3d  [%s]\n" $ctr $h
          set fail = "$fail $h"
        endif
        @ ctr++
      end # depth
    end #site
  end # type

end # id


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

