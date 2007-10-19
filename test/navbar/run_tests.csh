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


set PLATFORM = `uname`
switch ($PLATFORM)

  case SunOS
    set diffprog = /data/dburke2/local32/bin/diff
  breaksw

  case Darwin
    set diffprog = diff
  breaksw

endsw

## multiple type/site/depth tests
#
foreach id ( \
 list-li-navbar  links  news-item  section-id-locallink  \
 section-id-locallink-matchid  section-id-sitelink  section-id-sitelink-matchid  section-id-nolink  \
  )

  foreach type ( live test )
    foreach site ( ciao chart sherpa )
      foreach depth ( 1 2 )
        set h = ${id}_${type}_${site}_d${depth}
        set out = out/xslt.$h

        if ( -e $out ) rm -f $out
        $xsltproc --stringparam matchid foo --stringparam type $type --stringparam site $site --stringparam depth $depth --stringparam ahelpindex `pwd`/../links/ahelpindexfile.xml --stringparam hardcopy 0 --stringparam newsfileurl /ciao9.9/news.html in/${id}.xsl in/${id}.xml > $out
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


## transform creates the output file rather than written to STDOUT
#
# first those with only 1 output file
#
foreach id ( \
 \
  )

  foreach type ( live test )
    foreach site ( ciao chart sherpa )
      foreach depth ( 1 2 )
        set h = ${id}_${type}_${site}_d${depth}_out
        set out = out/navbar_main.incl

        if ( -e $out ) rm -f $out
        $xsltproc --stringparam install out/ --stringparam matchid foo --stringparam type $type --stringparam site $site --stringparam depth $depth --stringparam ahelpindex `pwd`/../links/ahelpindexfile.xml --stringparam hardcopy 0 --stringparam newsfileurl /ciao9.9/news.html in/${id}.xsl in/${id}.xml > /dev/null
        if ( ! -e $out ) then
          # fake a file so that code below works
          touch $out
        endif
        $diffprog -u out/${h} $out
        if ( $status == 0 ) then
          printf "OK:   %3d  [%s]\n" $ctr $h
          rm -f $out
          @ ok++
        else
          printf "FAIL: %3d  [%s]\n" $ctr $h
          set fail = "$fail $h"
          mv $out out/xslt.$h
        endif
        @ ctr++
      end # depth
    end #site
  end # type

end # id

#
# and now those with 2 output files
# [we cheat and assume the two files are always
#  written to out/ and out/foo/]
#
foreach id ( \
 \
  )

  foreach type ( live test )
    foreach site ( ciao chart sherpa )
      foreach depth ( 1 2 )
        set h = ${id}_${type}_${site}_d${depth}
        set out1 = out/navbar_main.incl
        set out2 = out/foo/navbar_main.incl

        if ( -e $out1 ) rm -f $out1
        if ( -e $out2 ) rm -f $out2
        $xsltproc --stringparam install out/ --stringparam matchid foo --stringparam type $type --stringparam site $site --stringparam depth $depth --stringparam ahelpindex `pwd`/../links/ahelpindexfile.xml --stringparam hardcopy 0 --stringparam newsfileurl /ciao9.9/news.html in/${id}.xsl in/${id}.xml > /dev/null
        if ( ! -e $out1 ) then
          # fake a file so that code below works
          touch $out1
        endif
        $diffprog -u out/${h}_out $out1
        if ( $status == 0 ) then
          printf "OK:   %3d  [%s] [out]\n" $ctr $h
          rm -f $out1
          @ ok++
        else
          printf "FAIL: %3d  [%s] [out]\n" $ctr $h
          set fail = "$fail $h"
          mv $out1 out/xslt.${h}_out
        endif
        @ ctr++

        if ( ! -e $out2 ) then
          # fake a file so that code below works
          touch $out2
        endif
        $diffprog -u out/${h}_out_foo $out2
        if ( $status == 0 ) then
          printf "OK:   %3d  [%s] [out/foo]\n" $ctr $h
          rm -f $out2
          @ ok++
        else
          printf "FAIL: %3d  [%s] [out/foo]\n" $ctr $h
          set fail = "$fail $h"
          mv $out2 out/xslt.${h}_out_foo
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

