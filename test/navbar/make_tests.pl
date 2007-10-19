#!/data/da/Docs/local/perl/bin/perl -w
#
# $Id: make_tests.pl,v 1.4 2004/09/15 18:29:14 dburke Exp dburke $
#
# Usage:
#   make_tests.pl
#
# Aim:
#   Creates files used for the tests of the navbar
#
# Creates:
#   stuff in in/ and out/
#
# Notes:
#   The section code should check the links/news section.
#   I would prefer to amalgamate the stylesheet first (so that
#   the contents of the navbar dictate the contents rather than
#   having so much logic in the stylesheets). This should also
#   make it easier to test.
#
# History:
#   04/09/08 DJB Based on version from ahelp test
#

use strict;

use Cwd;
use IO::File;

use lib "..";
use TESTS;

sub add_test ($$$$);
sub add_test2 ($$$;@);
sub write_script ();

## Code
#
my @name;
my @name2;

my $indir  = "in";
my $outdir = "out";
cleanup_dirs $indir, $outdir;

# test list and li elements in navbar
#
# note: the list does not generate any container (eg ul or ol)
# since it is placed within a dt list
#
# NOTE:
#   I am not sure that the %d in the cxclink is correct?
#
add_test "list-li-navbar",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//list" mode="navbar"/>
</xsl:template>',
'<list>
  <li>a <cxclink href="link.html">link</cxclink></li>
  <li>another <ahelp name="dmextract" tt="1">link</ahelp> and <strong>some text</strong>.</li>
</list>',
'
  <dd>a <a href="%dlink.html">link</a>
</dd>
  <dd>another <tt>' . get_ahelp_link("link") . '</tt> and <strong>some text</strong>.</dd>
';

# test links section
#   this is only for ChaRT/iCXC pages but should be able to test with
#   any site
#
# we test out a list to check it is processed by the "myhtml/helper"
# version rather than the navbar-specific list-handling code
#
add_test "links",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//links" mode="create"/>
</xsl:template>',
'<links>
 <list>
  <li>a <cxclink href="link.html">link</cxclink></li>
  <li>another <ahelp name="dmextract" tt="1">link</ahelp> and <strong>some text</strong>.</li>
 </list>
</links>',
'<hr>
 <ul>
  <li>a <a href="%dlink.html">link</a>
</li>
  <li>another <tt>' . get_ahelp_link("link") . '</tt> and <strong>some text</strong>.</li>
 </ul>
';

# test news and news/item tags
#   this is only for CIAO/Sherpa pages but should be able to test with
#   any site
#
add_test "news-item",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//news" mode="create"/>
</xsl:template>',
'<news>
 <item type="new" day="2" month="September" year="4">
  Some text.
 </item>
 <item type="updated" day="26" month="August" year="2004">
  <p>Some <em>emphasized</em> text in a paragraph.</p>
 </item>
 <item day="20" month="January" year="2002">
  <p>Some <em>emphasized</em> text in a paragraph followed by a list.</p>
  <list type="1">
   <li>a <cxclink href="link.html">link</cxclink></li>
   <li>another <ahelp name="dmextract" tt="1">link</ahelp> and <strong>some text</strong>.</li>
  </list>
 </item>
</news>',
'<hr><div>
<div class="newsbar">
<h2>News</h2>
<a href="/ciao9.9/news.html">Previous Items</a>
</div>
<div>
<p align="left"><strong>2 Sep 2004</strong> <img src="%dimgs/new.gif" alt="[New]"></p>
  Some text.
 <hr width="80%" align="center">
</div>
<div>
<p align="left"><strong>26 Aug 2004</strong> <img src="%dimgs/updated.gif" alt="[Updated]"></p>
  <p>Some <em>emphasized</em> text in a paragraph.</p>
 <hr width="80%" align="center">
</div>
<div>
<p align="left"><strong>20 Jan 2002</strong> </p>
  <p>Some <em>emphasized</em> text in a paragraph followed by a list.</p>
  <ol type="1">
   <li>a <a href="%dlink.html">link</a>
</li>
   <li>another <tt>' . get_ahelp_link("link") . '</tt> and <strong>some text</strong>.</li>
  </ol>
 <hr width="80%" align="center">
</div>
</div>';

# test section
#
my $section_xsl =
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//section" mode="create"/>
</xsl:template>';

my $section_in =
'<section id="main" link="index.html">
 <dirs>
  <dir/>
  <dir>foo</dir>
 </dirs>
 <title>A title</title>
 <list>
  <li>a <cxclink href="link.html">link</cxclink></li>
  <li>another <ahelp name="dmextract" tt="1">link</ahelp> and <strong>some text</strong>.</li>
 </list>
</section>';

my $section_out =
'<dt><a class="heading" href="%dindex.html">A title</a></dt>
  <dd>a <a href="%dlink.html">link</a>
</dd>
  <dd>another <tt>' . get_ahelp_link("link") . '</tt> and <strong>some text</strong>.</dd>
 ';

add_test "section-id-locallink", $section_xsl, $section_in, $section_out;

$section_in =~ s/ id="main" / id="foo" /;
$section_out =~ s/ class="heading" / class="selectedheading" /;
add_test "section-id-locallink-matchid", $section_xsl, $section_in, $section_out;

$section_in =~ s/ id="foo" / id="main" /;
$section_out =~ s/ class="selectedheading" / class="heading" /;
$section_in  =~ s{ link="index.html"}{ link="/ciao/index.html"};
$section_out =~ s{ href="%dindex.html"}{ href="/ciao/index.html"};
add_test "section-id-sitelink", $section_xsl, $section_in, $section_out;

$section_in =~ s/ id="main" / id="foo" /;
$section_out =~ s/ class="heading" / class="selectedheading" /;
add_test "section-id-sitelink-matchid", $section_xsl, $section_in, $section_out;

$section_in =~ s/ id="foo" / id="main" /;
$section_in  =~ s{ link="/ciao/index.html"}{};
$section_out =~ s{<a class="selectedheading" href="/ciao/index.html">A title</a>}{<span class="heading">A title</span>};
add_test "section-id-nolink", $section_xsl, $section_in, $section_out;

=begin OLDCODE

this was valid when we had the 'old' navbar code (ie process multiple depths
at one go). We could probably re-write things so that parts of these
tests are retained, but leave for later

# section, mode=process
#   implicitly tests write-navbar
#
# since we are wiring out the navbar for this section
# we have it as the selected heading (no matter what the
# input parameter says)
#
$section_in =
'<section id="main" link="index.html">
 <dirs>
  <dir/>
  <dir>foo</dir>
 </dirs>
 <title>A title</title>
 <list>
  <li>a <cxclink href="link.html">link</cxclink></li>
  <li>another <ahelp name="dmextract" tt="1">link</ahelp> and <strong>some text</strong>.</li>
 </list>
</section>';

$section_out =
'<dl>
<dt><a class="selectedheading" href="%dindex.html">A title</a></dt>
  <dd>a <a href="%dlink.html">link</a>
</dd>
  <dd>another <tt>' . get_ahelp_link("link") . '</tt> and <strong>some text</strong>.</dd>
 </dl>
<br>';

add_test2 "section-process-id-link-logo", $section_in, $section_out,
  logo => "both", mode => "process", out => [ 'out' ];
add_test2 "section-process-id-link-logotxt", $section_in, $section_out,
  logo => "text", mode => "process", out => [ 'out' ];
add_test2 "section-process-id-link-nologo", $section_in, $section_out,
  logo => "none", mode => "process", out => [ 'out' ];

$section_in  =~ s{ link="index.html"}{ link="/ciao/index.html"};
$section_out =~ s{ href="%dindex.html"}{ href="/ciao/index.html"};
add_test2 "section-process-id-sitelink-logo", $section_in, $section_out,
  logo => "both", mode => "process", out => [ 'out' ];
add_test2 "section-process-id-sitelink-logotxt", $section_in, $section_out,
  logo => "text", mode => "process", out => [ 'out' ];
add_test2 "section-process-id-sitelink-nologo", $section_in, $section_out,
  logo => "none", mode => "process", out => [ 'out' ];

$section_in  =~ s{ link="/ciao/index.html"}{};
$section_out =~ s{<a class="selectedheading" href="/ciao/index.html">A title</a>}{<span class="selectedheading">A title</span>};
add_test2 "section-process-id-nolink-logo", $section_in, $section_out,
  logo => "both", mode => "process", out => [ 'out' ];
add_test2 "section-process-id-nolink-logotxt", $section_in, $section_out,
  logo => "text", mode => "process", out => [ 'out' ];
add_test2 "section-process-id-nolink-nologo", $section_in, $section_out,
  logo => "none", mode => "process", out => [ 'out' ];

## now the "final" test which is similar to the behavior of navbar.xsl
#
$section_in =
'<section id="main" link="index.html">
 <dirs>
  <dir/>
  <dir>foo</dir>
 </dirs>
 <title>A title</title>
 <list>
  <li>a <cxclink href="link.html">link</cxclink></li>
  <li>another <ahelp name="dmextract" tt="1">link</ahelp> and <strong>some text</strong>.</li>
 </list>
</section>';

$section_out =
'<dl>
<dt><a class="selectedheading" href="%dindex.html">A title</a></dt>
  <dd>a <a href="%dlink.html">link</a>
</dd>
  <dd>another <tt>' . get_ahelp_link("link") . '</tt> and <strong>some text</strong>.</dd>
 </dl>
<br>';

add_test2 "section-with-id-id-link-logo", $section_in, $section_out,
  logo => "both", mode => "with-id", out => [ 'out', 'out/foo' ];
add_test2 "section-with-id-id-link-logotxt", $section_in, $section_out,
  logo => "text", mode => "with-id", out => [ 'out', 'out/foo' ];
add_test2 "section-with-id-id-link-nologo", $section_in, $section_out,
  logo => "none", mode => "with-id", out => [ 'out', 'out/foo' ];

$section_in  =~ s{ link="index.html"}{ link="/ciao/index.html"};
$section_out =~ s{ href="%dindex.html"}{ href="/ciao/index.html"};
add_test2 "section-with-id-id-sitelink-logo", $section_in, $section_out,
  logo => "both", mode => "with-id", out => [ 'out', 'out/foo' ];
add_test2 "section-with-id-id-sitelink-logotxt", $section_in, $section_out,
  logo => "text", mode => "with-id", out => [ 'out', 'out/foo' ];
add_test2 "section-with-id-id-sitelink-nologo", $section_in, $section_out,
  logo => "none", mode => "with-id", out => [ 'out', 'out/foo' ];

$section_in  =~ s{ link="/ciao/index.html"}{};
$section_out =~ s{<a class="selectedheading" href="/ciao/index.html">A title</a>}{<span class="selectedheading">A title</span>};
add_test2 "section-with-id-id-nolink-logo", $section_in, $section_out,
  logo => "both", mode => "with-id", out => [ 'out', 'out/foo' ];
add_test2 "section-with-id-id-nolink-logotxt", $section_in, $section_out,
  logo => "text", mode => "with-id", out => [ 'out', 'out/foo' ];
add_test2 "section-with-id-id-nolink-nologo", $section_in, $section_out,
  logo => "none", mode => "with-id", out => [ 'out', 'out/foo' ];

=end OLDCODE

=cut

## end of tests

write_script();

## End
#
exit;

## Subroutines

# uses global variable @name
#
sub add_test ($$$$) {
    my $name  = shift;
    my $style = shift;
    my $in    = shift;
    my $out   = shift;

    my $test_string = get_xml_header( "navbar" );
    $test_string .= $in;
    $test_string .= "\n</navbar>\n";
    write_out $test_string, "${indir}/${name}.xml";

    # OUTPUT
    foreach my $type ( qw( live test ) ) {
	foreach my $site ( qw( ciao chart sherpa ) ) {
	    foreach my $depth ( qw( 1 2 ) ) {

		my $out_string = get_html_header();
		$out_string .= convert_depth_site( $out, $depth, $site ) . "\n";
		write_out $out_string, "${outdir}/${name}_${type}_${site}_d${depth}";

	    } # for: $depth
	} # for: $site
    } # for: $type

    # STYLESHEET
    #
    my $out_string = get_xslt_header();
    $out_string .= <<"EOD";
  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
  <xsl:include href="../../../globalparams.xsl"/>
  <xsl:include href="../../../helper.xsl"/>
  <xsl:include href="../../../links.xsl"/>
  <xsl:include href="../../../myhtml.xsl"/>
  <xsl:include href="../../../navbar_main.xsl"/>
EOD

    $out_string .= $style . "\n</xsl:stylesheet>\n";
    write_out $out_string, "${indir}/${name}.xsl";
    print "Created: ${name}.x[sm]l\n";

    push @name, "${name}";

} # sub: add_test()

# uses the global variable @name2
#
# this is for tests that create their own output file
# rather than printing to STDOUT
#
sub add_test2 ($$$;@) {
    my $name  = shift;
    my $in    = shift;
    my $out   = shift;
    my %opts  =
      (
       @_
       );

    my $mode = $opts{mode} || die "Error: add_test2 needs a mode option\n";
    my $outref = $opts{out} || die "Error: add_test2 needs an out option\n";

    my $test_string = get_xml_header( "navbar" );
    $test_string .= $in;
    $test_string .= "\n</navbar>\n";
    write_out $test_string, "${indir}/${name}.xml";

    # OUTPUT
    my $out_string = <<'EOD';


<!-- THIS FILE IS CREATED AUTOMATICALLY - DO NOT EDIT MANUALLY -->
<!-- SEE: foo.xml -->

<!--htdig_noindex-->
<div>
EOD

    my $logoimage = "";
    my $logotext  = "";
    if ( $opts{logo} eq "both" ) {
	$logoimage = "logo.gif";
	$logotext  = "LOGO TEXT";
	$out_string .= <<'EOD';
<p align="center"><img src="%dlogo.gif" alt="[LOGO TEXT]"></p>
EOD
    } elsif ( $opts{logo} eq "text" ) {
	$logotext = "LOGO TEXT";
	$out_string .= <<'EOD';
<p align="center">LOGO TEXT</p>
EOD
    }

    $out_string .= "$out\n";

    $out_string .= <<'EOD';
</div><!--/htdig_noindex-->

EOD

    foreach my $odir ( @$outref ) {
	foreach my $type ( qw( live test ) ) {
	    foreach my $site ( qw( ciao chart sherpa ) ) {
		foreach my $depth ( qw( 1 2 ) ) {

		    # can not have the split within the scalar() call apparently
		    # (well, not without warnings)
		    #
		    my @dirs = split( /\//, $odir );
		    write_out convert_depth_site( $out_string, $depth+$#dirs, $site ),
		      "${outdir}/${name}_${type}_${site}_d${depth}_" . join("_",@dirs);

		} # for: $depth
	    } # for: $site
	} # for: $type
    } # for: $odir

    # STYLESHEET
    #
    # we hack in the logoimage/text here if necessary
    # (rather than sending them in as parameters to the
    #  tool). This is possible since they are defined in
    # navbar.xml which we do not include here.
    #
    $out_string = get_xslt_header();
    $out_string .= <<"EOD";
  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
  <xsl:param name="logoimage" select='"$logoimage"'/>
  <xsl:param name="logotext"  select='"$logotext"'/>
  <xsl:param name="sourcedir"  select='"foo"'/>
  <xsl:include href="../../../globalparams.xsl"/>
  <xsl:include href="../../../helper.xsl"/>
  <xsl:include href="../../../links.xsl"/>
  <xsl:include href="../../../myhtml.xsl"/>
  <xsl:include href="../../../navbar_main.xsl"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//section" mode="$mode"/>
</xsl:template>
</xsl:stylesheet>
EOD

    write_out $out_string, "${indir}/${name}.xsl";
    print "Created: ${name}.x[sm]l\n";

    push @name2, [ $name, $outref ];

} # sub: add_test2()

# uses the global variables @name and @name2
#
sub write_script () {
    my $ofile = "run_tests.csh";

    my $fh = IO::File->new( "> $ofile" )
      or die "Error: unable to open $ofile for writing\n";

    print $fh get_test_setup("navbar");
    print $fh <<'EOD';

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
EOD

    print_id_list $fh, @name;

    print $fh <<'EOD';
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

EOD

    # now the "section" tests in @name2
    #
    print $fh <<'EOD';

## transform creates the output file rather than written to STDOUT
#
# first those with only 1 output file
#
foreach id ( \
EOD

    my @names;
    foreach my $aref ( @name2 ) {
	my $name = $$aref[0];
	my $oref = $$aref[1];
	push @names, $name if $#$oref == 0;
    }
    print_id_list $fh, @names;

    print $fh <<'EOD';
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

EOD

    print $fh <<'EOD';
#
# and now those with 2 output files
# [we cheat and assume the two files are always
#  written to out/ and out/foo/]
#
foreach id ( \
EOD

    @names = ();
    foreach my $aref ( @name2 ) {
	my $name = $$aref[0];
	my $oref = $$aref[1];
	push @names, $name if $#$oref == 1;
    }
    print_id_list $fh, @names;

    print $fh <<'EOD';
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

EOD

    print $fh get_test_report();
    $fh->close;
    finished_test $ofile;

} # sub: write_script()

