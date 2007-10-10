#!/data/da/Docs/local/perl/bin/perl -w
#
# $Id: make_tests.pl,v 1.3 2006/06/06 19:45:19 dburke Exp $
#
# Usage:
#   make_tests.pl
#
# Aim:
#   Creates files used for the tests of the ciao threadindex
#
# Creates:
#   stuff in in/ and out/
#
# Missing tests:
#
# History:
#
# TODO:
#

use strict;

use IO::File;

use lib "..";
use TESTS;

sub add_test_depth ($$$$);
sub add_test_site_depth ($$$$);
sub write_script ();

## Code
#
my @names_depth;
my @names_site_depth;

# note: some of the routines actually hard code $indir/$outdir values
my $indir  = "in";
my $outdir = "out";
cleanup_dirs $indir, $outdir;

# Tests

# we do not test these with different sites as would need
# to set up some test files for sherpa case
#

# the list/sublist tests also test:
#   title
#   item [except for the 'following a sublist' part
#   text
#   list-thread
#   /thread
#   history mode=date
#   scriptinfo
#   add-thread-pdf-links
#
# Is this still true?
#
my $transform =
'<xsl:template match="/">
 <xsl:apply-templates select="//list" mode="threadindex">
  <xsl:with-param name="depth" select="$depth"/>
 </xsl:apply-templates>
</xsl:template>
<xsl:template name="newline"><xsl:text>
</xsl:text></xsl:template>';

add_test_depth "list", $transform,
'<list>
  <item name="example"/>
  <item>
   <text>
    <p>
     Some <cxclink href="foo.html">test</cxclink> code.
     A <ahelp name="dmextract" tt="1"/> link.
    </p>
   </text>
  </item>
 </list>',
'<div class="threadlist"><ul>
  <li>
<a class="threadlink" href="example/">A rather long title, for the top of the thread</a><br>Uses:
      
    the <tt>script1</tt>
    script; 
    the <tt>script2.sl</tt> S-Lang
    script<br><img src="%dimgs/new.gif" alt="[New]">
    (<strong>29 May 2003</strong>)
  <br><img src="%dimgs/updated.gif" alt="[Updated]">
    (<strong>29 May 2003</strong>)
  </li>
  <li>
    <p>
     Some <a href="foo.html">test</a> code.
     A <tt>' . get_ahelp_link("dmextract") . '</tt> link.
    </p>
   </li>
 </ul></div>
';

add_test_depth "sublist", $transform,
'<list>
  <sublist>
   <title>A sublist</title>
   <item name="example"/>
   <item>
    <text>
     <p>
      Some <cxclink href="foo.html">test</cxclink> code.
      A <ahelp name="dmextract" tt="1"/> link.
     </p>
    </text>
   </item>
  </sublist>
 </list>',
'<div class="threadlist"><ul>
  <li><div class="threadsublist">
<h4>A sublist
</h4>
<ul>
<li>
<a class="threadlink" href="example/">A rather long title, for the top of the thread</a><br>Uses:
      
    the <tt>script1</tt>
    script; 
    the <tt>script2.sl</tt> S-Lang
    script<br><img src="%dimgs/new.gif" alt="[New]">
    (<strong>29 May 2003</strong>)
  <br><img src="%dimgs/updated.gif" alt="[Updated]">
    (<strong>29 May 2003</strong>)
  </li>
<li>
     <p>
      Some <a href="foo.html">test</a> code.
      A <tt>' . get_ahelp_link("dmextract") . '</tt> link.
     </p>
    </li>
</ul>
</div></li>
 </ul></div>
';

add_test_depth "sublist2", $transform,
'<list>
  <sublist>
   <title>A sublist</title>
   <item name="example"/>
   <sublist>
    <title>A nested sublist</title>
    <item>
     <text>
      <p>
       In a nested sublist.
       Some <cxclink href="foo.html">test</cxclink> code.
       A <ahelp name="dmextract" em="1" tt="1"/> link.
      </p>
     </text>
    </item>
    <item name="example"/>
   </sublist>
   <item>
    <text>
     <p>
      Some <cxclink href="foo.html">test</cxclink> code.
      A <ahelp name="dmextract" tt="1"/> link.
     </p>
    </text>
   </item>
  </sublist>
 </list>',
'<div class="threadlist"><ul>
  <li><div class="threadsublist">
<h4>A sublist
</h4>
<ul>
<li>
<a class="threadlink" href="example/">A rather long title, for the top of the thread</a><br>Uses:
      
    the <tt>script1</tt>
    script; 
    the <tt>script2.sl</tt> S-Lang
    script<br><img src="%dimgs/new.gif" alt="[New]">
    (<strong>29 May 2003</strong>)
  <br><img src="%dimgs/updated.gif" alt="[Updated]">
    (<strong>29 May 2003</strong>)
  </li>
<li><div class="threadsublist">
<h4>A nested sublist
</h4>
<ul>
<li>
      <p>
       In a nested sublist.
       Some <a href="foo.html">test</a> code.
       A <em><tt>' . get_ahelp_link("dmextract") . '</tt></em> link.
      </p>
     </li>
<li>
<a class="threadlink" href="example/">A rather long title, for the top of the thread</a><br>Uses:
      
    the <tt>script1</tt>
    script; 
    the <tt>script2.sl</tt> S-Lang
    script<br><img src="%dimgs/new.gif" alt="[New]">
    (<strong>29 May 2003</strong>)
  <br><img src="%dimgs/updated.gif" alt="[Updated]">
    (<strong>29 May 2003</strong>)
  </li>
</ul>
<br>
</div></li>
<li>
     <p>
      Some <a href="foo.html">test</a> code.
      A <tt>' . get_ahelp_link("dmextract") . '</tt> link.
     </p>
    </li>
</ul>
</div></li>
 </ul></div>
';

# here we test that title (no mode) does nothing but title (mode=show) does
#
$transform =
'  <xsl:template match="threadindex">
<xsl:text>
</xsl:text>
    <xsl:apply-templates name="title"/>
<xsl:text>
</xsl:text>
    <xsl:apply-templates name="title" mode="show"/>
  </xsl:template>
  <!--* having fun with newline so write our own here *-->
  <xsl:template name="newline">
<xsl:text>
</xsl:text>
  </xsl:template>';

add_test_depth "title", $transform,
'<title>Some <strong>title</strong> text</title>',
'




Some <strong>title</strong> text


';

# the dataset test also tests:
#   object
#   instrument
#   thread
#
# the package test also tests:
#   text
#
# the make-datatable test also tests:
#   dataset
#   package
#

$transform =
'<xsl:template match="threadindex">
 <xsl:apply-templates>
  <xsl:with-param name="depth" select="$depth"/>
 </xsl:apply-templates>
</xsl:template>';

add_test_depth "dataset", $transform,
'  <dataset obsid="3">
    <object>Foo</object>
    <instrument>FOO</instrument>
    <thread>One</thread>
  </dataset>
  <dataset obsid="3">
    <object>Foo</object>
    <instrument>FOO</instrument>
    <thread>One</thread>
    <thread>Two</thread>
  </dataset>
  <dataset obsid="3" l2="1">
    <object>Foo</object>
    <instrument>FOO</instrument>
    <thread>One</thread>
  </dataset>
  <dataset obsid="3" l1.5="1">
    <object>Foo</object>
    <instrument>FOO</instrument>
    <thread>One</thread>
  </dataset>
  <dataset obsid="3" l1="1">
    <object>Foo</object>
    <instrument>FOO</instrument>
    <thread>One</thread>
  </dataset>
  <dataset obsid="3" aspect="1">
    <object>Foo</object>
    <instrument>FOO</instrument>
    <thread>One</thread>
  </dataset>
  <dataset obsid="3" ephem="1">
    <object>Foo</object>
    <instrument>FOO</instrument>
    <thread>One</thread>
  </dataset>
  <dataset obsid="3" l2="1" l1.5="1" l1="1" aspect="1" ephem="1">
    <object>Foo</object>
    <instrument>FOO</instrument>
    <thread>One</thread>
  </dataset>',
'
  <tr>
<td align="center">3</td>
<td align="center">Foo</td>
<td align="center">FOO</td>
<td align="center">One</td>
</tr><tr><th colspan="4"><hr></th></tr>
  <tr>
<td align="center">3</td>
<td align="center">Foo</td>
<td align="center">FOO</td>
<td align="center">One, Two</td>
</tr><tr><th colspan="4"><hr></th></tr>
  <tr>
<td align="center">3</td>
<td align="center">Foo</td>
<td align="center">FOO</td>
<td align="center">One</td>
</tr><tr><th colspan="4"><hr></th></tr>
  <tr>
<td align="center">3</td>
<td align="center">Foo</td>
<td align="center">FOO</td>
<td align="center">One</td>
</tr><tr><th colspan="4"><hr></th></tr>
  <tr>
<td align="center">3</td>
<td align="center">Foo</td>
<td align="center">FOO</td>
<td align="center">One</td>
</tr><tr><th colspan="4"><hr></th></tr>
  <tr>
<td align="center">3</td>
<td align="center">Foo</td>
<td align="center">FOO</td>
<td align="center">One</td>
</tr><tr><th colspan="4"><hr></th></tr>
  <tr>
<td align="center">3</td>
<td align="center">Foo</td>
<td align="center">FOO</td>
<td align="center">One</td>
</tr><tr><th colspan="4"><hr></th></tr>
  <tr>
<td align="center">3</td>
<td align="center">Foo</td>
<td align="center">FOO</td>
<td align="center">One</td>
</tr><tr><th colspan="4"><hr></th></tr>

';

add_test_depth "package", $transform,
'  <package>
    <file>detect.tar.gz</file>
    <text><em>Detect</em> thread</text>
  </package>
  <package>
    <file>user_mms.tar.gz</file>
    <text>
	Some text.
	And a <cxclink href="foo.html">link</cxclink>.
	And <ahelp name="dmextract">another one</ahelp>.
    </text>
  </package>',
'
  <tr>
<td colspan="3" align="center"><tt><a href="data/detect.tar.gz">detect.tar.gz</a></tt></td>
<td align="center"><p><em>Detect</em> thread</p></td>
</tr>
  <tr>
<td colspan="3" align="center"><tt><a href="data/user_mms.tar.gz">user_mms.tar.gz</a></tt></td>
<td align="center"><p>
	Some text.
	And a <a href="foo.html">link</a>.
	And ' . get_ahelp_link("another one") . '.
    </p></td>
</tr>

';

$transform =
'<xsl:template match="threadindex">
 <xsl:call-template name="make-datatable">
  <xsl:with-param name="depth" select="$depth"/>
 </xsl:call-template>
</xsl:template>';

add_test_depth "make-datatable", $transform,
'<datatable>
 <datasets>
  <dataset obsid="3">
   <object>Foo</object>
   <instrument>FOO</instrument>
   <thread>One</thread>
  </dataset>
 </datasets>
 <packages>
  <package>
   <file>user_mms.tar.gz</file>
   <text>
    Some text.
    And a <cxclink href="foo.html">link</cxclink>.
    And <ahelp name="dmextract">another one</ahelp>.
   </text>
  </package>
 </packages>
</datatable>',
'<table id="threaddatatable" align="center" width="90%" bgcolor="#666699" cellspacing="0" cellpadding="2">
<tr><td bgcolor="#666699" align="center"><font size="+1" color="#ffffff"><strong>Data Used in Threads</strong><br><br><a class="tablehead" href="archivedownload/">How to Download Chandra Data from the Archive</a></font></td></tr>
<tr><td><table border="0" bgcolor="#eeeeee" width="100%" cellpadding="6" cellspacing="0">
<tr><th colspan="4" align="center">Sorted by OBSID</th></tr>
<tr>
<th align="center">OBSID</th>
<th align="center">Object</th>
<th align="center">Instrument</th>
<th align="center">Threads</th>
</tr>
<tr>
<td align="center">3</td>
<td align="center">Foo</td>
<td align="center">FOO</td>
<td align="center">One</td>
</tr>
<tr><th colspan="4"><hr></th></tr>
<tr><th colspan="4" align="center">Sorted by Thread</th></tr>
<tr>
<th colspan="3" align="center">File</th>
<th align="center">Thread</th>
</tr>
<tr>
<td colspan="3" align="center"><tt><a href="data/user_mms.tar.gz">user_mms.tar.gz</a></tt></td>
<td align="center"><p>
    Some text.
    And a <a href="foo.html">link</a>.
    And ' . get_ahelp_link("another one") . '.
   </p></td>
</tr>
<tr><td colspan="4" align="center"><br></td></tr>
</table></td></tr>
</table>
';

# as of CIAO 3.1 we no longer allow the package attribute
# in script tags
#
# Umm, this one is a pain to do. We need a thread to test
# against, rather than an index file. Will need to redo
# to use the example thread.
#
$transform =
'<xsl:template match="/">
 <xsl:apply-templates select="threadindex/info/files/script" mode="threadindex">
  <xsl:with-param name="depth" select="$depth"/>
 </xsl:apply-templates>
</xsl:template>';

add_test_site_depth "script", $transform,
'<info><files>
<script>foo</script>
<script slang="1">foo</script>
<script>foo</script>
</files></info>',
'
    the <tt>foo</tt>
    script; 
    the <tt>foo</tt> S-Lang
    script; 
    the <tt>foo</tt>
    script
';


## end of tests

write_script();

## End
#
exit;

## Subroutines

# uses global variable @names_depth
#
sub add_test_depth ($$$$) {
    my $name  = shift;
    my $style = shift;
    my $in    = shift;
    my $out   = shift;

    # INPUT
    #
    my $test_string = get_xml_header( "threadindex" );
    $test_string .= $in;
    $test_string .= "\n</threadindex>\n";
    write_out $test_string, "${indir}/${name}.xml";

    # OUTPUT
    #
    my $ofile = "${outdir}/${name}";
    my $site = "ciao";
    foreach my $depth ( qw( 1 2 ) ) {
	my $out_string = get_html_header();
	$out_string =~ s/\n\n/\n/;
	$out_string .=  convert_depth_site( $out, $depth, $site );
	write_out $out_string, "${ofile}_d${depth}";
    } # for: $depth

    # STYLESHEET
    #
    my $out_string = get_xslt_header();
    $out_string .= <<"EOD";
  <xsl:include href="../../../globalparams_thread.xsl"/>
  <xsl:include href="../../../helper.xsl"/>
  <xsl:include href="../../../links.xsl"/>
  <xsl:include href="../../../myhtml.xsl"/>
  <xsl:include href="../../../threadindex_common.xsl"/>
  <xsl:output method="html" media-type="text/html" version="4.0" encoding="us-ascii"/>
EOD

    $out_string .= $style . "\n</xsl:stylesheet>\n";
    write_out $out_string, "${indir}/${name}.xsl";
    print "Created: ${name}.x[sm]l\n";

    push @names_depth, $name;

} # sub: add_test_depth()

# uses global variable @names_site_depth
#
sub add_test_site_depth ($$$$) {
    my $name  = shift;
    my $style = shift;
    my $in    = shift;
    my $out   = shift;

    # INPUT
    #
    my $test_string = get_xml_header( "threadindex" );
    $test_string .= $in;
    $test_string .= "\n</threadindex>\n";
    write_out $test_string, "${indir}/${name}.xml";

    # OUTPUT
    #
    my $ofile = "${outdir}/${name}";
    foreach my $site ( qw( ciao sherpa ) ) {
	foreach my $depth ( qw( 1 2 ) ) {
	    my $out_string = get_html_header();
	    $out_string =~ s/\n\n/\n/;
	    $out_string .=  convert_depth_site( $out, $depth, $site );
	    write_out $out_string, "${ofile}_${site}_d${depth}";
	} # for: $depth
    } # for: $site

    # STYLESHEET
    #
    my $out_string = get_xslt_header();
    $out_string .= <<"EOD";
  <xsl:include href="../../../globalparams_thread.xsl"/>
  <xsl:include href="../../../helper.xsl"/>
  <xsl:include href="../../../links.xsl"/>
  <xsl:include href="../../../myhtml.xsl"/>
  <xsl:include href="../../../threadindex_common.xsl"/>
  <xsl:output method="html" media-type="text/html" version="4.0" encoding="us-ascii"/>
EOD

    $out_string .= $style . "\n</xsl:stylesheet>\n";
    write_out $out_string, "${indir}/${name}.xsl";
    print "Created: ${name}.x[sm]l\n";

    push @names_site_depth, $name;

} # sub: add_test_site_depth()

# uses the global variables @names_depth, @names_site_depth
#
sub write_script () {
    my $ofile = "run_tests.csh";

    my $fh = IO::File->new( "> $ofile" )
      or die "Error: unable to open $ofile for writing\n";

    print $fh get_test_setup("ciao_threadindex");

    print $fh <<'EOD';
## multiple depths
#
set type   = live
set site   = ciao
set srcdir = /data/da/Docs/web/devel/test/threads/

# note: set threadDir to test site even though testing live code since
# want to use the example thread and that is only published to the test site
#
set params = "--stringparam sourcedir /data/da/Docs/web/devel/test/threads/ --stringparam threadDir /data/da/Docs/ciaoweb/published/test/threads/ --stringparam hardcopy 0 --stringparam ahelpindex `pwd`/../links/ahelpindexfile.xml --stringparam type $type --stringparam site $site "

foreach id ( \
EOD

    print_id_list $fh, @names_depth;

    print $fh <<'EOD';
  )

  foreach depth ( 1 2 )
    set h = ${id}_d${depth}
    set out = out/xslt.$h

    if ( -e $out ) rm -f $out
    /usr/bin/env LD_LIBRARY_PATH=$ldpath $xsltproc $params --stringparam depth $depth in/${id}.xsl in/${id}.xml > $out
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
EOD

    print $fh <<'EOD';
## multiple site/depths
#
set type  = test
set srcdir = /data/da/Docs/web/devel/test/threads/

set params = "--stringparam sourcedir /data/da/Docs/web/devel/test/threads/ --stringparam hardcopy 0 --stringparam ahelpindex `pwd`/../links/ahelpindexfile.xml --stringparam type $type "

foreach id ( \
EOD

    print_id_list $fh, @names_site_depth;

    print $fh <<'EOD';
  )

  foreach site ( ciao sherpa )
    foreach depth ( 1 2 )
      set h = ${id}_${site}_d${depth}
      set out = out/xslt.$h

      if ( -e $out ) rm -f $out
      /usr/bin/env LD_LIBRARY_PATH=$ldpath $xsltproc $params --stringparam depth $depth --stringparam site $site in/${id}.xsl in/${id}.xml > $out
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
EOD

    print $fh get_test_report();
    $fh->close;
    finished_test $ofile;

} # sub: write_script()
