#!/data/da/Docs/local/perl/bin/perl -w
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

sub add_test ($$$$;@);
sub write_script ();

## Code
#
my @name;

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
'
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
'<div>
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
  <xsl:apply-templates select="//section" mode="create">
    <xsl:with-param name="matchid" select="\'foo\'"/>
  </xsl:apply-templates>
</xsl:template>';

my $section_in_orig =
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

my $section_out_orig =
'<dt><a class="heading" href="%dindex.html">A title</a></dt>
  <dd>a <a href="%dlink.html">link</a>
</dd>
  <dd>another <tt>' . get_ahelp_link("link") . '</tt> and <strong>some text</strong>.</dd>
 ';

my $section_in  = $section_in_orig;
my $section_out = $section_out_orig;
add_test "section-id-locallink", $section_xsl, $section_in, $section_out;

$section_in =~ s/ id="main" / id="foo" /;
$section_out =~ s/ class="heading" / class="selectedheading" /;
add_test "section-id-locallink-matchid", $section_xsl, $section_in, $section_out;

$section_in  = $section_in_orig;
$section_in  =~ s{ link="index.html"}{ link="/ciao/index.html"};
$section_out = $section_out_orig;
$section_out =~ s{ href="%dindex.html"}{ href="/ciao/index.html"};
add_test "section-id-sitelink", $section_xsl, $section_in, $section_out;

$section_in =~ s/ id="main" / id="foo" /;
$section_out =~ s/ class="heading" / class="selectedheading" /;
add_test "section-id-sitelink-matchid", $section_xsl, $section_in, $section_out;

$section_in  = $section_in_orig;
$section_in  =~ s{ link="/ciao/index.html"}{};
$section_out = $section_out_orig;
$section_out =~ s{<a class="heading" href="/ciao/index.html">A title</a>}{<span class="heading">A title</span>};
add_test "section-id-nolink", $section_xsl, $section_in, $section_out;

# test the navbar creation code; it is not quite the same code as in
# navbar.xsl/navbar_main.xsl. It is based on the old section/mode=process
# tests.
#
# I think that the basedir/subdir tests could be rolled into one
# here, as they do not actually test anythign different, since the only
# think that happens differently in the actual stylesheet are:
#   - change in output file name
#   - change in depth
# and neither of these are tested here (the first point is handled
# by write-navbar which we do not test and the second one isn't because
# we do not include a startdepth parameter (or something equivalent) in the
# tests.
#
# XXX TODO XXX
# I am not 100% convinced about the class="selectedheading" test (ie
# that the actual code being tested is behaving sensibly here, and that
# I am not sure how to test it. Needs thought.
#
my $navbar_basedir_xsl =
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:for-each select="descendant::section[boolean(@id)]/dirs/dir[.=\'\']">
    <xsl:call-template name="navbar-contents"/>
  </xsl:for-each>
</xsl:template>';

my $navbar_subdir_xsl =
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:for-each select="descendant::section[boolean(@id)]/dirs/dir[.!=\'\']">
    <xsl:call-template name="navbar-contents"/>
  </xsl:for-each>
</xsl:template>';

my $navbar_in =
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

my $navbar_base_out =
'

<!-- THIS FILE IS CREATED AUTOMATICALLY - DO NOT EDIT MANUALLY -->
<!-- SEE: foo.xml -->

<!--htdig_noindex-->
<div>
LOGO-HERE
<dl>
<dt><a class="selectedheading" href="%dindex.html">A title</a></dt>
  <dd>a <a href="%dlink.html">link</a>
</dd>
  <dd>another <tt>' . get_ahelp_link("link") . '</tt> and <strong>some text</strong>.</dd>
 </dl>DELME
</div>
<!--/htdig_noindex-->
';

# For some reason the spacing of the div/dl elements depends
# on what is going on
#
my $navbar_out = $navbar_base_out;
$navbar_out =~ s{\nLOGO-HERE\n}{};
$navbar_out =~ s{DELME\n}{};

add_test "navbar-basedir-nologo", $navbar_basedir_xsl, $navbar_in, $navbar_out,
  logoimage => "", logotext => "";
add_test "navbar-subdir-nologo", $navbar_subdir_xsl, $navbar_in, $navbar_out,
  logoimage => "", logotext => "";

add_test "navbar-basedir-logo-image", $navbar_basedir_xsl, $navbar_in, $navbar_out,
  logoimage => "logo.gif", logotext => "";
add_test "navbar-subdir-logo-image", $navbar_subdir_xsl, $navbar_in, $navbar_out,
  logoimage => "logo.gif", logotext => "";

$navbar_out = $navbar_base_out;
$navbar_out =~ s{LOGO-HERE}{<p align="center"><img src="%dlogo.gif" alt="[Logo Text]"></p>};
$navbar_out =~ s{DELME}{};
add_test "navbar-basedir-logo-both", $navbar_basedir_xsl, $navbar_in, $navbar_out,
  logoimage => "logo.gif", logotext => "Logo Text";
add_test "navbar-subdir-logo-both", $navbar_subdir_xsl, $navbar_in, $navbar_out,
  logoimage => "logo.gif", logotext => "Logo Text";

$navbar_out = $navbar_base_out;
$navbar_out =~ s{LOGO-HERE}{<p align="center">Logo Text</p>};
$navbar_out =~ s{DELME}{};
add_test "navbar-basedir-logo-text", $navbar_basedir_xsl, $navbar_in, $navbar_out,
  logoimage => "", logotext => "Logo Text";
add_test "navbar-subdir-logo-text", $navbar_subdir_xsl, $navbar_in, $navbar_out,
  logoimage => "", logotext => "Logo Text";

# I could test the logo handling for all these cases, but I can
# not be bothered at the moment.
#
$navbar_in =~ s{ link="index.html"}{ link="/ciao/index.html"};
$navbar_out =~ s{ href="%dindex.html"}{ href="/ciao/index.html"};
add_test "navbar-basedir-sitelink-logo-text", $navbar_basedir_xsl, $navbar_in, $navbar_out,
  logoimage => "", logotext => "Logo Text";
add_test "navbar-subdir-sitelink-logo-text", $navbar_subdir_xsl, $navbar_in, $navbar_out,
  logoimage => "", logotext => "Logo Text";

## end of tests

write_script();

## End
#
exit;

## Subroutines

# uses global variable @name
#
sub add_test ($$$$;@) {
    my $name  = shift;
    my $style = shift;
    my $in    = shift;
    my $out   = shift;
    my %params = ( @_ );

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

    while ( my ($pname, $pval) = each %params ) {
      $out_string .= sprintf '<xsl:param name="%s" select=\'"%s"\'/>', $pname, $pval;
      $out_string .= "\n";
    }

    $out_string .= $style . "\n</xsl:stylesheet>\n";
    write_out $out_string, "${indir}/${name}.xsl";
    print "Created: ${name}.x[sm]l\n";

    push @name, "${name}";

} # sub: add_test()

# uses the global variables @name
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

    case Linux
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

EOD

    print $fh get_test_report();
    $fh->close;
    finished_test $ofile;

} # sub: write_script()

