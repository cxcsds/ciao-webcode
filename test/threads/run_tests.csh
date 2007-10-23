#!/bin/csh
#
# Test thread stylesheets
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

set params = "--stringparam sourcedir `pwd`/ --stringparam hardcopy 0 --stringparam depth 1 --stringparam imglinkicon foo.gif --stringparam imglinkiconwidth 10 --stringparam imglinkiconheight 12 --stringparam ahelpindex `pwd`/../links/ahelpindexfile.xml --stringparam site $site"

foreach id ( \
 imglink1  imglink3  imglink3-in-p  images-toc  \
 calupdate  calinfo  calinfo-with-text  intro-none  intro-overview  \
 summary-none  obsidlist1-nodesc  obsidlist1-desc  obsidlist2-nodesc  obsidlist2-desc  \
 filetypelist1  filetypelist2  parameters1-internal  parameters2-internal  parameters1-external  \
 toc  toc-number  toc-number-typeA  \
  )

  set out = out/xslt.$id
  if ( -e $out ) rm -f $out
  $xsltproc $params in/${id}.xsl in/${id}.xml > $out
  set statusa = $status
  set statusb = 1
  if ( $statusa == 0 ) then
    # avoid excess warning messages if we know it has failed
    # for some reason within the stylesheet
    #
    diff out/${id} $out
    set statusb = $status
  endif
  if ( $statusa == 0 && $statusb == 0 ) then
    printf "OK:   %3d  [%s]\n" $ctr $id
    rm -f $out
    @ ok++
  else
    printf "FAIL: %3d  [%s]\n" $ctr $id
    set fail = "$fail $id"
  endif
  @ ctr++
end # foreach: id

## multiple  tests
#
set type  = test

set params = "--stringparam sourcedir `pwd`/ --stringparam hardcopy 0 --stringparam imglinkicon foo.gif --stringparam imglinkiconwidth 10 --stringparam imglinkiconheight 12 --stringparam ahelpindex `pwd`/../links/ahelpindexfile.xml"

foreach id ( \
 before  after  subsectionlist-nosep  subsectionlist-sepbar  \
 subsectionlist-sepnone  subsectionlist-type1  subsectionlist-typeA  sectionlist-nosep  sectionlist-sepbar  \
 sectionlist-sepnone  sectionlist-type1  intro-introduction  intro-overview-why  intro-overview-when  \
 intro-overview-why-when-calinfo  summary  history  screen-internal  screen-external  \
 include  \
  )

  foreach site ( ciao chart sherpa )
    foreach depth ( 1 2 )
      set h = ${id}_${site}_d${depth}
      set out = out/xslt.$h

      if ( -e $out ) rm -f $out
      $xsltproc --stringparam site $site --stringparam depth $depth $params in/${id}.xsl in/${id}.xml > $out
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

