#!/bin/csh
#
# Test helper stylesheets
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

## single shot tests
#
set type  = test
set site  = ciao
set depth = 1
set srcdir = /data/da/Docs/web/devel/test/helper

foreach id ( \
 add-htmlhead_meta  add-hr-strong  unknown  add-htmlhead_scripts  \
 add-disclaimer  add-htmlhead_css  add-htmlhead  add-id-hardcopy  comment  \
  )

  set h = ${id}_${type}_${site}_d${depth}
  set out = out/xslt.$h
  if ( -e $out ) rm -f $out
  $xsltproc --stringparam type $type --stringparam site $site --stringparam depth $depth --stringparam sourcedir $srcdir --stringparam ahelpindex `pwd`/ahelpindexfile.xml in/${id}.xsl in/${id}.xml > $out
  diff out/${h} $out
  if ( $status == 0 ) then
    printf "OK:   %3d  [%s]\n" $ctr $h
    rm -f $out
    @ ok++
  else
    printf "FAIL: %3d  [%s]\n" $ctr $h
    set fail = "$fail $id"
  endif
  @ ctr++
end # foreach: id

## those tests that loop over depth
#
set type  = test
set site  = ciao

foreach id ( \
 add-image  add-updated-image  add-new-image  dummy  \
 add-path  add-attribute  \
  )

  foreach depth ( 1 2 )

    set h = ${id}_${type}_${site}_d${depth}
    set out = out/xslt.$h
    if ( -e $out ) rm -f $out
    $xsltproc --stringparam type $type --stringparam site $site --stringparam depth $depth --stringparam ahelpindex `pwd`/ahelpindexfile.xml in/${id}.xsl in/${id}.xml > $out
    diff out/$h $out
    if ( $status == 0 ) then
      printf "OK:   %3d  [%s]\n" $ctr $h
      rm -f $out
      @ ok++
    else
      printf "FAIL: %3d  [%s]\n" $ctr $h
      set fail = "$fail $h"
    endif
    @ ctr++
  end # foreach: depth
end # foreach: id

## those tests that loop over type/site/depth
#

foreach id ( \
 add-footer  add-depth  add-navbar  \
  )

  foreach type ( live test )
    foreach site ( ciao chart )
      foreach depth ( 1 2 )
	set h = ${id}_${type}_${site}_d${depth}
	set out = out/xslt.$h
	if ( -e $out ) rm -f $out
	$xsltproc --stringparam type $type --stringparam site $site --stringparam depth $depth --stringparam ahelpindex `pwd`/ahelpindexfile.xml in/${id}.xsl in/${id}.xml > $out
	diff out/${h} $out
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

## those tests that loop over site
#
set type  = test
set depth = 1

foreach id ( \
 is-site-valid  \
  )

  foreach site ( ciao chart unknown )
    set h = ${id}_${type}_${site}_d${depth}
    set out = out/xslt.$h
    if ( -e $out ) rm -f $out
    # NOTE the piping of stderr as well as stdout here
    $xsltproc --stringparam type $type --stringparam site $site --stringparam depth $depth --stringparam ahelpindex `pwd`/ahelpindexfile.xml in/${id}.xsl in/${id}.xml >& $out
    diff out/${h} $out
    if ( $status == 0 ) then
      printf "OK:   %3d  [%s]\n" $ctr $h
      rm -f $out
      @ ok++
    else
      printf "FAIL: %3d  [%s]\n" $ctr $h
      set fail = "$fail $h"
    endif
    @ ctr++
  end #site

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

