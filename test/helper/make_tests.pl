#!/data/da/Docs/local/perl/bin/perl -w
#
# Usage:
#   make_tests.pl
#
# Aim:
#   Creates files used for the tests of helper.xsl
#
# Creates:
#   stuff in in/ and out/
#
# Missing tests:
#   add-standard-banner
#   add-hardcopy-banner-top
#   add-hardcopy-banner-bottom
#   dummy ?
#   add-hr-strong
#   add-id-hardcopy
#   add-ssi-include
#   add-start-body-white
#   add-test-banner
#
# History:
#   08/07/30 DJB Based on version from myhtml test
#   04/09/07 DJB Updated for libxml2 v2.6.13/libxslt v1.1.10
#
# TODO: need to include the actual CSS file names
#

use strict;

use IO::File;

use lib "..";
use TESTS;

sub add_test ($$$;$);
sub write_script ();

## Code
#
my %tests;

# note: some of the routines actually hard code $indir/$outdir values
my $indir  = "in";
my $outdir = "out";
cleanup_dirs $indir, $outdir;

my $meta_content =
'<meta http-equiv="Content-Type" content="text/html; charset=us-ascii">';

my $css_content =
'<link rel="stylesheet" title="Default stylesheet for CIAO-related pages" href="">' .
"\n" .
'<link rel="stylesheet" title="Default stylesheet for CIAO-related pages" media="print" href="">';

# we test out some ahelp stuff, so we need an ahelp index file
#
## for ahelp we need to create our own indexfile
#
write_out get_xml_header("ahelpindex") .
'<ahelplist>
<ahelp><key>dmcopy</key><context>tools</context><page>dmcopy</page></ahelp>
</ahelplist>
</ahelpindex>
', "ahelpindexfile.xml";

# the following tests are only to be run with
#   type  = test
#   site  = ciao
#   depth = 1
#

my $tag = "<!--* test a comment *-->";
add_test "comment", $tag, "\n";

$tag = '<foobar goo="ha"><p>XX</p>\nYY</foobar>';
add_test "unknown", $tag, "\n$tag";

add_test "add-disclaimer", "",
"

<!-- THIS FILE IS CREATED AUTOMATICALLY - DO NOT EDIT MANUALLY -->
<!-- SEE: /data/da/Docs/web/devel/test/helper.xml -->

",
  {
   xsl =>
   '<xsl:call-template name="add-disclaimer"><xsl:with-param name="pagename" select="' .
   "''" . # don't know where it's picking pagename up from
   '"/></xsl:call-template>', };

add_test "add-htmlhead", "<info><title><short>a title</short></title></info>",
"<head>
$meta_content
<title>a title</title>
$css_content
</head>",
  { xsl => '<xsl:call-template name="add-htmlhead"><xsl:with-param name="title" select="info/title/short"/></xsl:call-template>' };

my $meta = "<metalist>" .
  '<meta http-equiv="keywords" content="CIAO, x-ray, analysis, reduction, astronomy, astrophysics, chandra, axaf"/>' .
  '<meta http-equiv="description" content="The CIAO software - for analysis of astronomy data"/>' .
  "</metalist>";
add_test "add-htmlhead_meta", "<info><title><short>a title</short></title>$meta</info>",
"<head>
$meta_content
<title>a title</title>
" .
'<meta http-equiv="keywords" content="CIAO, x-ray, analysis, reduction, astronomy, astrophysics, chandra, axaf">
<meta http-equiv="description" content="The CIAO software - for analysis of astronomy data">
' .
$css_content . '
</head>',
  { xsl => '<xsl:call-template name="add-htmlhead"><xsl:with-param name="title" select="info/title/short"/></xsl:call-template>' };

my $css =
"/* a test css rule */
p { color: red }
";
add_test "add-htmlhead_css", "<info><title><short>a title</short></title><css>$css</css></info>",
"<head>
$meta_content
<title>a title</title>
$css_content
<style type=\"text/css\">$css</style>
</head>",
  { xsl =>
    '<xsl:call-template name="add-htmlhead">' .
    '<xsl:with-param name="title" select="info/title/short"/>' .
    '<xsl:with-param name="css" select="info/css"/>' .
    '</xsl:call-template>' };

my $scripts = <<'EOD';
<htmlscripts>
 <htmlscript type="text/javascript" language="Javascript" src="foo.js"/>
 <htmlscript type="text/javascript" language="Javascript">
  <!-- A comment, should include some javascript -->
 </htmlscript>
</htmlscripts>
EOD

add_test "add-htmlhead_scripts", "<info><title><short>a title</short></title>$scripts</info>",
"<head>
$meta_content
<title>a title</title>
" .
'<script language="Javascript" type="text/javascript" src="foo.js"></script><script language="Javascript" type="text/javascript"><!-- A comment, should include some javascript --></script>' .
$css_content . '
</head>',
  { xsl => '<xsl:call-template name="add-htmlhead"><xsl:with-param name="title" select="info/title/short"/></xsl:call-template>' };

# do we still have something like this?
#
##add_test "add-last-modified", "",
##'<hr>
##<p align="right">
##    Last modified:
##    <!--#CONFIG TIMEFMT="%e %B %Y"--><!--#flastmod file="$DOCUMENT_NAME"-->
##</p>',
##  { xsl => '<xsl:call-template name="add-last-modified"/>' };

add_test "add-hr-strong", "",
'<hr size="5" noshade>',
  { xsl => '<xsl:call-template name="add-hr-strong"/>' };

add_test "add-id-hardcopy", "",
'<table border="0" width="100%"><tr>
<td align="left">
          URL: <a href="http://cxc.harvard.edu/ciao/foo/foo.html">http://cxc.harvard.edu/ciao/foo/foo.html</a>
</td>
<td align="right">
          Last modified: 29 Jan 1971</td>
</tr></table>',
  { xsl =>
'<xsl:call-template name="add-id-hardcopy">
  <xsl:with-param name="urlfrag" select="\'foo/foo.html\'"/>
  <xsl:with-param name="lastmod" select="\'29 Jan 1971\'"/>
</xsl:call-template>
' };

# the following tests are only to be run with
#   type  = test
#   site  = ciao
#   depth = 1, 2
#

add_test "add-path", "",
"
File = ##foo
File = foo
  ",
  { xsl =>
'File = <xsl:call-template name="add-path">
      <xsl:with-param name="idepth" select="$depth"/>
      </xsl:call-template>foo
File = <xsl:call-template name="add-path"/>foo', type => "depth" };


add_test "add-attribute", "<p>some text with random markup</p>",
'<foo goo="##foobar">
<p>some text with random markup</p></foo>',
  { xsl =>
'<foo>
      <xsl:call-template name="add-attribute">
        <xsl:with-param name="name"  select="\'goo\'"/>
        <xsl:with-param name="value" select="\'foobar\'"/>
      </xsl:call-template>
      <xsl:apply-templates/>
</foo>', type => "depth" };

add_test "add-image", "",
'<img src="##foo.gif" alt="[a foo]">
<img src="##foo.gif" alt="[a foo]" height="10">
<img src="##foo.gif" alt="[a foo]" width="20">
<img src="##foo.gif" alt="[a foo]" border="0">
<img src="##foo.gif" alt="[a foo]" align="right">
<img src="##foo.gif" alt="[a foo]" height="10" width="20" border="0" align="right">',
  { xsl =>
'    <xsl:call-template name="add-image">
      <xsl:with-param name="src"   select="\'foo.gif\'"/>
      <xsl:with-param name="alt"   select="\'a foo\'"/>
    </xsl:call-template>
<xsl:text>
</xsl:text>
    <xsl:call-template name="add-image">
      <xsl:with-param name="src"    select="\'foo.gif\'"/>
      <xsl:with-param name="alt"    select="\'a foo\'"/>
      <xsl:with-param name="height" select="\'10\'"/>
    </xsl:call-template>
<xsl:text>
</xsl:text>
    <xsl:call-template name="add-image">
      <xsl:with-param name="src"    select="\'foo.gif\'"/>
      <xsl:with-param name="alt"    select="\'a foo\'"/>
      <xsl:with-param name="width"  select="\'20\'"/>
    </xsl:call-template>
<xsl:text>
</xsl:text>
    <xsl:call-template name="add-image">
      <xsl:with-param name="src"    select="\'foo.gif\'"/>
      <xsl:with-param name="alt"    select="\'a foo\'"/>
      <xsl:with-param name="border" select="0"/>
    </xsl:call-template>
<xsl:text>
</xsl:text>
    <xsl:call-template name="add-image">
      <xsl:with-param name="src"    select="\'foo.gif\'"/>
      <xsl:with-param name="alt"    select="\'a foo\'"/>
      <xsl:with-param name="align"  select="\'right\'"/>
    </xsl:call-template>
<xsl:text>
</xsl:text>
    <xsl:call-template name="add-image">
      <xsl:with-param name="src"    select="\'foo.gif\'"/>
      <xsl:with-param name="alt"    select="\'a foo\'"/>
      <xsl:with-param name="border" select="0"/>
      <xsl:with-param name="align"  select="\'right\'"/>
      <xsl:with-param name="width"  select="\'20\'"/>
      <xsl:with-param name="height" select="\'10\'"/>
    </xsl:call-template>
', type => "depth" };

add_test "add-new-image", "",
'<img src="##imgs/new.gif" alt="[New]">',
  { xsl =>
'    <xsl:call-template name="add-new-image"/>', type => "depth" };

add_test "add-updated-image", "",
'<img src="##imgs/updated.gif" alt="[Updated]">',
  { xsl =>
'    <xsl:call-template name="add-updated-image"/>', type => "depth" };

# as of CIAO 3.0 we do not use the add-marker template
#

=begin OLDCODE

add_test "add-marker", "some text with <em>random</em> markup",
'<foo><img src="##imgs/drop.gif" alt="[*]" height="15" width="10" border="0" align="left">some text with <em>random</em> markup</foo>
<foo><img src="imgs/drop.gif" alt="[*]" height="15" width="10" border="0" align="left">some text with <em>random</em> markup</foo>',
  { xsl =>
'    <foo>
    <xsl:call-template name="add-marker"/>
    <xsl:apply-templates/>
</foo><xsl:text>
</xsl:text>
<foo>
      <xsl:call-template name="add-marker"/>
      <xsl:apply-templates/>
</foo>', type => "depth" };

=end OLDCODE

=cut

add_test "dummy", '<dummy><ahelp name="dmcopy"/></dummy>',
'
<a class="helplink" href="##ahelp/dmcopy.html">dmcopy</a>',
  { xsl =>
'    <xsl:apply-templates/>', type => "depth" };

# the following tests are only to be run with
#   type  = test
#   site  = ciao, chart, unknown
#   depth = 1
#

# need to trap stderr too
add_test "is-site-valid", "", "^^",
  { trap_stderr => 1,
    xsl =>'<xsl:call-template name="is-site-valid"/>',
    type => "site" };

# the following tests are to be run with
#   type  = test, live
#   site  = ciao, chart
#   depth = 1, 2
#

add_test "add-depth", "",
"
path = ##foo
  ",
  { xsl =>
'path = <xsl:call-template name="add-path"><xsl:with-param name="idepth" select="
$depth"/></xsl:call-template>foo', type => "all" };

add_test "add-footer", "",
'&&',
  {
   xsl_pre =>
'  <xsl:param name="xsl-version" select="\'1.2.3\'"/>
  <xsl:param name="updateby"    select="\'a_tester\'"/>',
   xsl =>
'    <xsl:call-template name="add-footer">
      <xsl:with-param name="type"       select="$type"/>
      <xsl:with-param name="name"       select="' . "'foo'" . '"/>
    </xsl:call-template>', type => "all" };

add_test "add-navbar", "",
'~~',
  {
   xsl_pre =>
'  <xsl:param name="xsl-version" select="\'1.2.3\'"/>
  <xsl:param name="updateby"    select="\'a_tester\'"/>',
   xsl =>
'    <xsl:call-template name="add-navbar">
      <xsl:with-param name="name"       select="\'test\'"/>
      <xsl:with-param name="type"       select="$type"/>
    </xsl:call-template>', type => "all" };

# the following tests are to be run with
#   type  = live  (not test since this uses exslt to get time)
#   site  = ciao, chart
#   depth = 1, 2
#

add_test "add-header", "",
'%%',
  {
   xsl_pre =>
'  <xsl:param name="xsl-version" select="\'1.2.3\'"/>
  <xsl:param name="updateby"    select="\'a_tester\'"/>',
   xsl =>
'    <xsl:call-template name="add-header">
      <xsl:with-param name="type"       select="$type"/>
      <xsl:with-param name="name"       select="' . "'foo'" . '"/>
    </xsl:call-template>', type => "liveonly" };

## end of tests

write_script();

## End
#
exit;

## Subroutines

# uses global variable %tests
#
# add_test $name, $in_xml, $out_text, \%opts
#
# opts values
#   test => simple | 
#
#   xsl  => xsl commands
#    defaults to apply-templates...
#
sub add_test ($$$;$) {
    my $name     = shift;
    my $in_xml   = shift;
    my $out_text = shift;

    # parse the options
    #
    my $opts = shift || {};

    my $root = $$opts{root} || "test";
    my $root_name = "$root";
    if ( defined $$opts{attr} and $$opts{attr} ne "" ) {
	$root_name .= " " . $$opts{attr};
    }

    my $test_type = $$opts{type} || "simple";

    # XML INPUT FILE
    #
    my $test_string = get_xml_header($root) . "$in_xml</$root>\n";
    write_out $test_string, "${indir}/${name}.xml";

    # STYLESHEET
    #
    my $xsl = $$opts{xsl} ||
'    <xsl:apply-templates/>
';

    my $xsl_pre = $$opts{xsl_pre} || "";

    write_out get_xslt_header() .
"  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
  <xsl:include href='../../../globalparams.xsl'/>
  <xsl:include href='../../../helper.xsl'/>
  <xsl:include href='../../../myhtml.xsl'/>
  <xsl:include href='../../../links.xsl'/>
$xsl_pre
<xsl:template match='$root'>
<xsl:text>
</xsl:text>
$xsl
  </xsl:template>
<!--* need to sort out newline template! *-->
<xsl:template name='newline'><xsl:text>
</xsl:text></xsl:template>
</xsl:stylesheet>
", "${indir}/${name}.xsl";

    print "Created: ${name}.x[sm]l\n";

    # OUTPUT
    #
    # what types do we want?
    #
    # [this string below is over-ridden for type=site]
    my $out_string = get_html_header();

    my @tests;

    # the 'default' test
    push @tests, [ "test", "ciao",  1 ];

    # add on any extra
    if ( $test_type eq "simple" ) {
	# none needed
    } elsif ( $test_type eq "depth" ) {
	push @tests, [ "test", "ciao",  2 ];
    } elsif ( $test_type eq "site" ) {
	push @tests, [ "test", "chart", 1 ];
	push @tests, [ "test", "unknown", 1 ]; # ugh: not nice
    } elsif ( $test_type eq "type" ) {
	push @tests, [ "live", "ciao",  1 ];
    } elsif ( $test_type eq "all" ) {
	push @tests, [ "test", "ciao",  2 ];
	push @tests, [ "test", "chart", 1 ];
	push @tests, [ "test", "chart", 2 ];
	push @tests, [ "live", "ciao",  1 ];
	push @tests, [ "live", "ciao",  2 ];
	push @tests, [ "live", "chart", 1 ];
	push @tests, [ "live", "chart", 2 ];
    } elsif ( $test_type eq "liveonly" ) {
	@tests = [ "live", "ciao",  1 ];
	push @tests, [ "live", "ciao", 2 ];
	push @tests, [ "live", "chart", 1 ];
	push @tests, [ "live", "chart", 2 ];
    } else {
	die "test has an unknown type of [$test_type]\n";
    }

    foreach my $aref ( @tests ) {
	my $type  = $$aref[0];
	my $site  = $$aref[1];
	my $depth = $$aref[2];

	# process this for depth/site changes
	# - these changes rely on the input text being simple
	#
	my $tmp = $out_text;

	if ( $test_type eq "depth" or $test_type eq "all" ) {
	    # note: important to substitute even when depth=1
	    #       since want to get rid of ## in this case
	    my $foo = "../" x ($depth-1);
	    $tmp =~ s/##/$foo/g;
	}

	# assume there aren't going to be multiple %%/&& in a string
	if ( ($test_type eq "type" or $test_type eq "all") and $tmp =~ m/%%/ ) {

	    my $orig = $tmp;
	    my $pos = index $orig, "%%";
	    $tmp = substr( $orig, 0, $pos );

	    if ( $type eq "live" ) {
		$tmp .=
"
<!--#include virtual=\"/incl/header.html\"-->
<div class=\"hideme\"><a href=\"#maintext\" accesskey=\"s\" title=\"Skip past the navigation links to the main part of the page\">Skip the navigation links</a></div>
<div class=\"topbar\">
<!--#include virtual=\"/incl/search.html\"-->
</div>
<div class=\"topbar\"><div class=\"lastmodbar\">Last modified: </div></div>";
            } else {

		die "ERROR: I've removed this test from type!=live!!!\n";
		$tmp .=
'<body bgcolor="#FFFFFF"><!-- This header is for pages on the test site only --><table width="100%" border="0"><tr>
<td align="left"><font color="red" size="-1">
' .
# there must be tab characters in the stylesheet!!!
"\t    Last published by: a_tester<br>
\t    at: The day before tomorrow</font></td>"
  . '
</tr></table>
<br clear="all">

<!--#include virtual="/incl/header.html"-->
<div class="hideme"><a href="#maintext" accesskey="s" title="Skip past the navigation links to the main part of the page">Skip the navigation links</a></div>
<div class="topbar">
<!--#include virtual="/incl/search.html"-->
</div>
<div class="topbar"><div class="lastmodbar">Last modified: </div></div>';
	    }
	    $tmp .= substr( $orig, $pos+2 );
        } # %%

	if ( ($test_type eq "type" or $test_type eq "all") and $tmp =~ m/&&/ ) {

	    my $orig = $tmp;
	    my $pos = index $orig, "&&";
	    $tmp = substr( $orig, 0, $pos );

	    $tmp .=
'<div class="bottombar"><div>Last modified: </div></div>
<!--#include virtual="/incl/footer.html"-->
';
##	    if ( $type eq "live" ) {
##            } else {
##		$tmp .=
##'<br>
##<div align="center"><font size="-1"><strong>TEST VERSION</strong></font></div>';
##	    }

	    $tmp .= substr( $orig, $pos+2 );
        } # &&

	if ( ($test_type eq "type" or $test_type eq "all") and $tmp =~ m/~~/ ) {

	    my $orig = $tmp;
	    my $pos = index $orig, "~~";
	    $tmp = substr( $orig, 0, $pos );

	    $tmp .=
'<td class="navbar" valign="top">
<!--#include virtual="navbar_test.incl"-->
</td>
';

	    $tmp .= substr( $orig, $pos+2 );
        } # ~~

	$tmp = $out_string . $tmp . "\n";

	my $ofile = "${outdir}/${name}_${type}_${site}_d${depth}";
	my $fh = IO::File->new( ">$ofile" )
	  or die "Error: unable to open $ofile for writing\n";
	if ( $test_type eq "site" ) {
	    $fh->print(
"
  Error:
    site parameter [unknown] is unknown
    allowed values:  ciao sherpa chips chart caldb pog icxc 
" ) if $site eq "unknown";

	    # note: the space after icxc above is important

	    $fh->print( $out_string . "\n" );

	} else {
	    $fh->print( $tmp );
	}
	$fh->close;

    } # foreach: @tests

    $tests{$name} = $test_type;

} # sub: add_test()

# uses the global variable %tests
#
sub write_script () {
    my $ofile = "run_tests.csh";

    # sort out the test types
    #
    my %lists;
    foreach my $type ( qw( simple all depth site liveonly ) ) {
	$lists{$type} = [];
    }
    foreach my $name ( keys %tests ) {
	my $type = $tests{$name};
	die "Error: unrecognised test type [$type]\n"
	  unless exists $lists{$type};
	push @{$lists{$type}}, $name;
    }

    my $fh = IO::File->new( "> $ofile" )
      or die "Error: unable to open $ofile for writing\n";

    print $fh get_test_setup("helper");
    print $fh <<'EOD';
## single shot tests
#
set type  = test
set site  = ciao
set depth = 1
set srcdir = /data/da/Docs/web/devel/test/helper

foreach id ( \
EOD

    print_id_list( $fh, @{ $lists{simple} } );

    print $fh <<'EOD';
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
EOD

    print_id_list( $fh, @{ $lists{depth} } );

    print $fh <<'EOD';
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
EOD

    print_id_list( $fh, @{ $lists{all} } );

    print $fh <<'EOD';
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
EOD

    print_id_list( $fh, @{ $lists{site} } );

    print $fh <<'EOD';
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

EOD

    print $fh get_test_report();
    $fh->close;
    finished_test $ofile;

} # sub: write_script()
