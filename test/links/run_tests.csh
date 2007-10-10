#!/bin/csh
#
# Test links stylesheets
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


foreach id ( \
 ahelp_home  ahelp_name  ahelp_name_id  ahelp_param  \
 faq_home  faq_id  faq_site_sherpa  faq_site_sherpa_id  faq_site_ciao  \
 faq_site_ciao_id  dictionary_home  dictionary_id  pog_home  pog_id  \
 pog_name  pog_name_id  manualpage  manual_name  manual_name_id  \
 manual_name_page  manual_name_page_id  dpguide  dpguide_id  dpguide_page  \
 dpguide_page_id  caveat  caveat_id  caveat_page  caveat_page_id  \
 aguide  aguide_id  aguide_page  aguide_page_id  why  \
 why_id  why_page  why_page_id  download  download_id  \
 download_type  script_name  scriptpage  extlink  extlink_id  \
 cxclink_href  cxclink_href_id  cxclink_id  cxclink_extlink  helpdesk  \
 threadpage  threadpage_id  threadpage_name  threadpage_name_id  threadlink_name  \
 threadlink_name_id  threadlink_thread  threadlink_thread_id  threadlink_thread_name  threadlink_thread_name_id  \
  )

  foreach type ( live test )
    foreach site ( ciao chart sherpa )
      foreach depth ( 1 2 )
        set h = ${id}_${type}_${site}_d${depth}
        set out = out/xslt.$h

        if ( -e $out ) rm -f $out
        $xsltproc --stringparam type $type --stringparam site $site --stringparam depth $depth --stringparam ahelpindex `pwd`/ahelpindexfile.xml test.xsl in/${id}.xml > $out
        diff out/${h} $out
        if ( $status == 0 ) then
          printf "OK:   %3d  [%s]\n" $ctr $h
          @ ok++
          rm -f $out
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

