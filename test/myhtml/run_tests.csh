#!/bin/csh
#
# Test myhtml stylesheets
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

## single shot tests
#
set type  = test
set site  = ciao
set depth = 1
set srcdir = /data/da/Docs/web/devel/test/helper

foreach id ( \
 start-tag  end-tag  add-quote  add-nbsp  \
 add-end-body  add-start-html  add-end-html  add-text-styles  add-text-styles-tag  \
 add-text-styles-em  add-text-styles-em-tag  add-text-styles-strong  add-text-styles-strong-tag  add-text-styles-tt  \
 add-text-styles-tt-tag  add-text-styles-em-strong  add-text-styles-em-strong-tag  add-text-styles-em-tt  add-text-styles-em-tt-tag  \
 add-text-styles-em-tt-strong  add-text-styles-em-tt-strong-tag  li  list  list-a  \
 list-1  list-more  new  new-date  new-date-2000  \
 updated  updated-date  updated-date-2000  add-date  add-date-2000  \
 p  p-align  p-header  p-note  p-link  \
 p-align-link  p-header-link  p-note-link  img  img-border  \
 pre  pre-highlight  add-highlight-pre  add-highlight-pre-tag  add-highlight-block  \
 add-highlight-block-tag  highlight  center  flastmod  bugnum  \
 id  id-process-p  p-id  h1-id  h2-id  \
 h3-id  h4-id  h5-id  scriptlist  \
  )

  set out = out/xslt.$id
  if ( -e $out ) rm -f $out
  /usr/bin/env LD_LIBRARY_PATH=$ldpath $xsltproc --stringparam type $type --stringparam site $site --stringparam depth $depth --stringparam sourcedir $srcdir --stringparam hardcopy 0 in/${id}.xsl in/${id}.xml > $out
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

