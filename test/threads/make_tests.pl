#!/data/da/Docs/local/perl/bin/perl -w
#
# $Id: make_tests.pl,v 1.9 2006/06/07 20:11:48 egalle Exp $
#
# Usage:
#   make_tests.pl
#
# Aim:
#   Creates files used for the tests of the thread conversion
#
# Creates:
#   stuff in in/ and out/
#
# To do:
#   - should we test the 'hardcopy' version?
#     It depends on whether we are getting rid of it quickly or
#     not
#
# Notes:
#   We no try to handle site and depth cases. It makes sense for
#   site, not so much for depth (since threads are meant to be
#   at a "fixed" depth). However, it is probably a good idea to
#   test them as implemented to check things work (particularly
#   because of how the depth value is sent around)
#
# History:
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
my @name_single;
my @name_loop;

my $indir  = "in";
my $outdir = "out";
cleanup_dirs( $indir, $outdir );

## test some links
#
# image links
#  - should test that it fails correctly
#
add_test "imglink1",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//imglink"/>
</xsl:template>',
'<imglink id="bar">image bar bar</imglink>',
'<a name="bar" href="img1.html">image bar bar&#160;<img src="foo.gif" alt="[Link to Image 1: Image 1 title]" height="12" width="10" border="0"></a>';

add_test "imglink3",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//imglink"/>
</xsl:template>',
'<imglink id="before-no-ps">image 3</imglink>',
'<a name="before-no-ps" href="img3.html">image 3&#160;<img src="foo.gif" alt="[Link to Image 3: Image 2 title]" height="12" width="10" border="0"></a>';

add_test "imglink3-in-p",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//p"/>
</xsl:template>',
'<p>A <em>link</em> to <imglink id="before-no-ps">image 3</imglink>.</p>',
'<p>A <em>link</em> to <a name="before-no-ps" href="img3.html">image 3&#160;<img src="foo.gif" alt="[Link to Image 3: Image 2 title]" height="12" width="10" border="0"></a>.</p>';

# this one would be different for the hardcopy version
#
add_test "images-toc",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//thread/images" mode="toc"/>
</xsl:template>',
'<images>
 <image id="foo"><title>Blah Blah</title></image>
 <image id="bar"><title>More stuff</title></image>
</images>',
'<li>
<strong>Images</strong><ul>
<li><a href="img1.html">Blah Blah</a></li>
<li><a href="img2.html">More stuff</a></li>
</ul>
</li>';

my $code = '<images>
 <image id="foo">
  <title>Blah Blah</title>
  <before><p>Some <em>text</em> and a <ahelp name="dmextract" em="1">link</ahelp>.</p></before>
 </image>
 <image id="bar">
  <title>More stuff</title>
  <after><p>Some more <em>text</em> and a <ahelp name="dmextract" tt="1">link</ahelp>.</p></after>
 </image>
</images>';

add_test "before",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//thread/images/image/before">
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:apply-templates>
</xsl:template>',
$code,
'<p>Some <em>text</em> and a <em>' . get_ahelp_link("link") . '</em>.</p>';

add_test "after",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//thread/images/image/after">
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:apply-templates>
</xsl:template>',
$code,
'<p>Some more <em>text</em> and a <tt>' . get_ahelp_link("link") . '</tt>.</p>';

## test the 'calibration files' tags
#

add_test "calupdate",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//calupdate"/>
</xsl:template>',
'<text><overview><synopsis/><why/><when/>
<calinfo><calupdates>
<calupdate version="2.3" day="19" month="March" year="01">
Some text. Really should contain a link.
</calupdate>
</calupdates></calinfo>
</overview></text>',
'<li>
<strong><a href="/caldb/downloads/Release_notes/CALDB_v2.3.txt">CALDB v2.3</a>  <font size="-1">(19 Mar 2001)</font>:</strong>
Some text. Really should contain a link.
</li>';

add_test "calinfo",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//calinfo"/>
</xsl:template>',
'<text><overview><synopsis/><why/><when/>
<calinfo><calupdates>
<calupdate version="2.3" day="19" month="March" year="01">
Some text. Really should contain a link.
</calupdate>
</calupdates></calinfo>
</overview></text>',
'<p><strong><a name="calnotes">Calibration Updates:</a></strong></p><ul><li>
<strong><a href="/caldb/downloads/Release_notes/CALDB_v2.3.txt">CALDB v2.3</a>  <font size="-1">(19 Mar 2001)</font>:</strong>
Some text. Really should contain a link.
</li></ul>';

add_test "calinfo-with-text",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//calinfo"/>
</xsl:template>',
'<text><overview><synopsis/><why/><when/>
<calinfo>
<caltext>Here is some text.</caltext>
<calupdates>
<calupdate version="2.3" day="19" month="March" year="01">
Some text. Really should contain a link.
</calupdate>
</calupdates></calinfo>
</overview></text>',
'<p><strong><a name="calnotes">Calibration Updates:</a></strong></p><div>Here is some text.</div><ul><li>
<strong><a href="/caldb/downloads/Release_notes/CALDB_v2.3.txt">CALDB v2.3</a>  <font size="-1">(19 Mar 2001)</font>:</strong>
Some text. Really should contain a link.
</li></ul>';

## some section-handling code
#

# do subsectionlist to check handling of type attribute
# in subsectionlist's
#
# The current design of the stylesheets means we do not have
# to check each attribute against every other attribute
# - ie we can check the type handling and the separator
#   handling separately, which cuts down on testing
#
my $transform =
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//subsectionlist">
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:apply-templates>
</xsl:template>';

my $in =
'<text><subsectionlist>
  <subsection id="foo-bar">
   <title>A title</title>
   <p>A paragraph with a <cxclink href="link.html">link</cxclink>.</p>
  </subsection>
  <subsection id="foo-baz">
   <title>Another title</title>
   <p>A paragraph with a <ahelp name="dmextract" tt="1">link</ahelp>.</p>
  </subsection>
 </subsectionlist></text>';

my $out =
'<div class="subsectionlist">
<div class="subsection">
<h3><a name="foo-bar">A title</a></h3>
   
   <p>A paragraph with a <a href="link.html">link</a>.</p>
  <hr width="80%" align="center">
</div>
<div class="subsection">
<h3><a name="foo-baz">Another title</a></h3>
   
   <p>A paragraph with a <tt>' . get_ahelp_link("link") . '</tt>.</p>
  </div>
</div>';

add_test "subsectionlist-nosep", $transform, $in, $out;

$in =~ s/<text>/<text separator="bar">/;
add_test "subsectionlist-sepbar", $transform, $in, $out;

$in =~ s/<text separator="bar">/<text separator="none">/;
$out =~ s/<hr width="80%" align="center">\s+//;
add_test "subsectionlist-sepnone", $transform, $in, $out;

$in =~ s/<subsectionlist>/<subsectionlist type="1">/;
$out =~ s/A title/1. A title/;
$out =~ s/Another title/2. Another title/;
add_test "subsectionlist-type1", $transform, $in, $out;

$in =~ s/<subsectionlist type="1">/<subsectionlist type="A">/;
$out =~ s/1. A title/A. A title/;
$out =~ s/2. Another title/B. Another title/;
add_test "subsectionlist-typeA", $transform, $in, $out;

## now try sectionlist's
#
$transform =
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//sectionlist">
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:apply-templates>
</xsl:template>';

$in =
'<text><sectionlist><section id="foo"><title>111 is a title</title>
 <p>A paragraph before the sub-sections.</p>
 <subsectionlist>
  <subsection id="foo-bar">
   <title>A title</title>
   <p>A paragraph with a <cxclink href="link.html">link</cxclink>.</p>
  </subsection>
  <subsection id="foo-baz">
   <title>Another title</title>
   <p>A paragraph with a <ahelp name="dmextract" tt="1">link</ahelp>.</p>
  </subsection>
 </subsectionlist></section>
<section id="bar"><title>Boo</title>
<p>Some text with a <dictionary id="bob">dictionary link</dictionary> in it.</p>
</section></sectionlist></text>';

$out =
'<br><div class="sectionlist">
<div class="section">
<h2><a name="foo">111 is a title</a></h2>
 <p>A paragraph before the sub-sections.</p>
 <div class="subsectionlist">
<div class="subsection">
<h3><a name="foo-bar">A title</a></h3>
   
   <p>A paragraph with a <a href="link.html">link</a>.</p>
  <hr width="80%" align="center">
</div>
<div class="subsection">
<h3><a name="foo-baz">Another title</a></h3>
   
   <p>A paragraph with a <tt>' . get_ahelp_link("link") . '</tt>.</p>
  </div>
</div>
<br><hr>
</div>
<div class="section">
<h2><a name="bar">Boo</a></h2>
<p>Some text with a ' . get_dictionary_link("bob","dictionary link") . ' in it.</p>
</div>
</div><br>';

add_test "sectionlist-nosep", $transform, $in, $out;

$in =~ s/<text>/<text separator="bar">/;
add_test "sectionlist-sepbar", $transform, $in, $out;

$in =~ s/<text separator="bar">/<text separator="none">/;
$out =~ s/<br><hr>\s+//;
$out =~ s/<hr width="80%" align="center">\s+//;
add_test "sectionlist-sepnone", $transform, $in, $out;

# note quite the same as the sectionlist's
# since only controlled by the number attribute
#
$in =~ s/<text separator="none">/<text separator="none" number="1">/;
$out =~ s/111 is a title/1 - 111 is a title/;
$out =~ s/Boo/2 - Boo/;
add_test "sectionlist-type1", $transform, $in, $out;


## introduction
#
# note: add-introduction expects to be called
#  with /thread as the context node, not /
#
$transform =
'<xsl:template match="/thread">
<xsl:text>
</xsl:text>
  <xsl:call-template name="add-introduction">
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:call-template>
</xsl:template>';

$in = '<text></text>';
$out = '';

add_test "intro-none", $transform, $in, $out;

$in =
'<text><introduction>
<p>Some text</p>
<p>Some <em>more text</em>, with a <cxclink href="bob.html">link</cxclink>
or <ahelp name="dmextract" strong="1">two</ahelp>.</p>
</introduction></text>';

$out =
'<br><h2><a name="introduction">Introduction</a></h2>
<p>Some text</p>
<p>Some <em>more text</em>, with a <a href="bob.html">link</a>
or <strong>' . get_ahelp_link("two") . '</strong>.</p>
<br><hr><br>';

add_test "intro-introduction", $transform, $in, $out;

$in =
'<text><overview>
<synopsis>Some text</synopsis>
</overview></text>';

my $start =
'<br><table width="100%" border="0" bgcolor="#eeeeee"><tr><td>
<h2><a name="overview"><font color="red">Overview</font></a></h2>
<p><strong>Last Update:</strong> 23 Mar 2002 - Test string.</p>
<p><strong>Synopsis:</strong></p>
<div>Some text</div>
';

my $end =
'<div class="noprint"><p><strong>
	  Proceed to the <a href="index.html#start-thread">HTML</a> or
	  hardcopy (PDF:
	  <a title="PDF (A4 format) version of the page" href="test.a4.pdf">A4</a> | <a title="PDF (US Letter format) version of the page" href="test.letter.pdf">letter</a>)
	  version of the thread.
	</strong></p></div>
</td></tr></table><br><hr size="5" noshade><br>';

$out =
$start .
$end;

add_test "intro-overview", $transform, $in, $out;

$in =
'<text><overview>
<synopsis>Some text</synopsis>
<why>
<p>Some <em>more text</em>, with a <cxclink href="bob.html">link</cxclink>
or <ahelp name="dmextract" strong="1">two</ahelp>.</p>
</why>
</overview></text>';

$out =
$start .
'<p><strong>Purpose:</strong></p>
<p>Some <em>more text</em>, with a <a href="bob.html">link</a>
or <strong>' . get_ahelp_link("two") . '</strong>.</p>
' .
$end;

add_test "intro-overview-why", $transform, $in, $out;

$in =
'<text><overview>
<synopsis>Some text</synopsis>
<when>
<p>Some <em>more text</em>, with a <cxclink href="bob.html">link</cxclink>
or <ahelp name="dmextract" strong="1">two</ahelp>.</p>
</when>
</overview></text>';

$out =
$start .
'<p><strong>Read this thread if:</strong></p>
<p>Some <em>more text</em>, with a <a href="bob.html">link</a>
or <strong>' . get_ahelp_link("two") . '</strong>.</p>
' .
$end;

add_test "intro-overview-when", $transform, $in, $out;


$in =
'<text><overview>
<synopsis>Some text</synopsis>
<why>
<p>Some <em>more text</em>, with a <cxclink href="bob.html">link</cxclink>
or <ahelp name="dmextract" strong="1">two</ahelp>.</p>
</why>
<when>
<p>Some <em>more text</em>, with a <cxclink href="bob.html">link</cxclink>
or <ahelp name="dmextract" strong="1">two</ahelp>.</p>
</when>
<calinfo>
<caltext>Here is some text.</caltext>
<calupdates>
<calupdate version="2.3" day="19" month="March" year="01">
Some text. Really should contain a link.
</calupdate>
</calupdates>
</calinfo>
</overview></text>';

$out =
$start .
'<p><strong>Purpose:</strong></p>
<p>Some <em>more text</em>, with a <a href="bob.html">link</a>
or <strong>' . get_ahelp_link("two") . '</strong>.</p>
<p><strong>Read this thread if:</strong></p>
<p>Some <em>more text</em>, with a <a href="bob.html">link</a>
or <strong>' . get_ahelp_link("two") . '</strong>.</p>
<p><strong><a name="calnotes">Calibration Updates:</a></strong></p>
<div>Here is some text.</div>
<ul><li>
<strong><a href="/caldb/downloads/Release_notes/CALDB_v2.3.txt">CALDB v2.3</a>  <font size="-1">(19 Mar 2001)</font>:</strong>
Some text. Really should contain a link.
</li></ul>
' .
$end;

add_test "intro-overview-why-when-calinfo", $transform, $in, $out;

$transform =
'<xsl:template match="/thread">
<xsl:text>
</xsl:text>
  <xsl:call-template name="add-summary">
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:call-template>
</xsl:template>';

$in = '<text></text>';
$out = '';

add_test "summary-none", $transform, $in, $out;

$in =
'<text><summary>
<p>Some text</p>
<p>Some <em>more text</em>, with a <cxclink href="bob.html">link</cxclink>
or <ahelp name="dmextract" strong="1">two</ahelp>.</p>
</summary></text>';

$out =
'<hr><br><h2><a name="summary">Summary</a></h2>
<p>Some text</p>
<p>Some <em>more text</em>, with a <a href="bob.html">link</a>
or <strong>' . get_ahelp_link("two") . '</strong>.</p>
<br>';

add_test "summary", $transform, $in, $out;

$transform =
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//history">
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:apply-templates>
</xsl:template>';

$in =
'<text/>';

$out =
'<h2><a name="history">History</a></h2><table class="history">
<tr>
<td class="historydate">02&#160;Jan&#160;2002</td>
<td>A test string with a <tt><strong>' . get_ahelp_link("link") . '</strong></tt>.</td>
</tr>
<tr>
<td class="historydate">23&#160;Mar&#160;2002</td>
<td>Test string.</td>
</tr>
</table>';

add_test "history", $transform, $in, $out;

$transform =
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//screen">
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:apply-templates>
</xsl:template>';

$in =
'<text>
<screen>
 unix&gt; <ahelp name="dmextract"/> foo <strong>bar</strong>
 and some output ...

 more output
</screen>
</text>';

$out =
'<div class="screen"><pre class="highlight">
 unix&gt; ' . get_ahelp_link("dmextract") . ' foo <strong>bar</strong>
 and some output ...

 more output
</pre></div>';

add_test "screen-internal", $transform, $in, $out;

$in =
'<text>
<screen file="screen-external"/>
</text>';

$out =
'<div class="screen"><pre class="highlight">
 unix&gt; ' . get_ahelp_link("dmextract") . ' foo <strong>bar</strong>
 and some output ...

 more output
</pre></div>';

# note:
#   the publishing script converts a .txt file into
#   a XML one. we jut create the XML version directly
#   for this test
#
my $fh = IO::File->new( "> screen-external.xml" )
  or die "Error: unable to create screen-external.xml";
$fh->print( '<dummy>
 unix&gt; <ahelp name="dmextract"/> foo <strong>bar</strong>
 and some output ...

 more output
</dummy>' );
$fh->close;

add_test "screen-external", $transform, $in, $out;

$transform =
'<xsl:param name="includeDir" select="$sourcedir"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//include">
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:apply-templates>
</xsl:template>';

$in =
'<text>
<include>screen-external</include>
</text>';

$out =
'
 unix&gt; ' . get_ahelp_link("dmextract") . ' foo <strong>bar</strong>
 and some output ...

 more output
';

add_test "include", $transform, $in, $out;

# obsidlist and filetypelist should be in the metadata for the thread
#
$transform =
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//obsidlist">
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:apply-templates>
</xsl:template>';

add_test "obsidlist1-nodesc", $transform,
'<text>
<sectionlist>
 <section id="bob">
  <title>A title</title>
  <obsidlist>
   <obsid>432</obsid>
  </obsidlist>
 </section>
</sectionlist>
</text>',
'<p><strong>Sample ObsID used:</strong> 432</p>';

add_test "obsidlist1-desc", $transform,
'<text>
<sectionlist>
 <section id="bob">
  <title>A title</title>
  <obsidlist>
   <obsid desc="foo bat">432</obsid>
  </obsidlist>
 </section>
</sectionlist>
</text>',
'<p><strong>Sample ObsID used:</strong> 432 (foo bat)</p>';

add_test "obsidlist2-nodesc", $transform,
'<text>
<sectionlist>
 <section id="bob">
  <title>A title</title>
  <obsidlist>
   <obsid>432</obsid>
   <obsid>987</obsid>
  </obsidlist>
 </section>
</sectionlist>
</text>',
'<p><strong>Sample ObsIDs used:</strong> 432; 987</p>';

add_test "obsidlist2-desc", $transform,
'<text>
<sectionlist>
 <section id="bob">
  <title>A title</title>
  <obsidlist>
   <obsid desc="foo bat">432</obsid>
   <obsid>987</obsid>
  </obsidlist>
 </section>
</sectionlist>
</text>',
'<p><strong>Sample ObsIDs used:</strong> 432 (foo bat); 987</p>';

$transform =
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//filetypelist">
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:apply-templates>
</xsl:template>';

add_test "filetypelist1", $transform,
'<text>
<sectionlist>
 <section id="bob">
  <title>A title</title>
  <filetypelist>
   <filetype>evt1</filetype>
  </filetypelist>
 </section>
</sectionlist>
</text>',
'<p><a href="../intro_data/"><strong>File types needed:</strong> </a>evt1</p>';

add_test "filetypelist2", $transform,
'<text>
<sectionlist>
 <section id="bob">
  <title>A title</title>
  <filetypelist>
   <filetype>evt1</filetype>
   <filetype>asol1</filetype>
  </filetypelist>
 </section>
</sectionlist>
</text>',
'<p><a href="../intro_data/"><strong>File types needed:</strong> </a>evt1; asol1</p>';

## now try parameters
#
# not the table-of-contents versions (leave them for elsewhere)
#
$transform =
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//parameters">
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:apply-templates>
</xsl:template>';

$in =
'<text><parameters>
<paramfile name="bob">
  infile = evt2.fits  Some sort of comment
    (bob = no)
</paramfile>
</parameters></text>';

$out =
'<hr size="5" noshade>
<a name="bob.par"> </a><table border="0" width="100%"><tr><td><pre class="paramlist">

Parameters for /home/username/cxcds_param/bob.par


  infile = evt2.fits  Some sort of comment
    (bob = no)
</pre></td></tr></table><hr size="5" noshade>
';

add_test "parameters1-internal", $transform, $in, $out;

$in =
'<text><parameters>
<paramfile name="bob">
  infile = evt2.fits  Some sort of comment
    (bob = no)
</paramfile>
<paramfile name="bob" id="fred">
  infile = evt2.fits  Some sort of comment
    (bob = yes)
</paramfile>
</parameters></text>';

$out =
'<hr size="5" noshade>
<a name="bob.par"> </a><table border="0" width="100%"><tr><td><pre class="paramlist">

Parameters for /home/username/cxcds_param/bob.par


  infile = evt2.fits  Some sort of comment
    (bob = no)
</pre></td></tr></table><hr size="5" noshade>
<a name="bob.par_fred"> </a><table border="0" width="100%"><tr><td><pre class="paramlist">

Parameters for /home/username/cxcds_param/bob.par


  infile = evt2.fits  Some sort of comment
    (bob = yes)
</pre></td></tr></table><hr size="5" noshade>
';

add_test "parameters2-internal", $transform, $in, $out;

$in =
'<text><parameters>
<paramfile name="bob" file="param-external"/>
</parameters></text>';

# the br in the output is un-needed and should be removed
$out =
'<hr size="5" noshade>
<a name="bob.par"> </a><table border="0" width="100%"><tr><td><pre class="paramlist">

Parameters for /home/username/cxcds_param/bob.par


  infile = evt2.fits  Some sort of comment
    (bob = no)
<br></pre></td></tr></table><hr size="5" noshade>
';

$fh = IO::File->new( "> param-external.xml" )
  or die "Error: unable to create screen-external.xml";
$fh->print( '<dummy>
  infile = evt2.fits  Some sort of comment
    (bob = no)
</dummy>' );
$fh->close;

add_test "parameters1-external", $transform, $in, $out;

## now try the table of contents
#
# try and stuff as much in as possible
# although should test the output when various parts
# are/are not included
#
# note: there is some testing of the number/type attributes
#
$transform =
'<xsl:template match="/thread">
<xsl:text>
</xsl:text>
  <xsl:call-template name="add-toc">
    <xsl:with-param name="depth" select="$depth"/>
  </xsl:call-template>
</xsl:template>';

$in =
'<text>
<overview>
<synopsis>Some text</synopsis>
<why>
<p>Some <em>more text</em>, with a <cxclink href="bob.html">link</cxclink>
or <ahelp name="dmextract" strong="1">two</ahelp>.</p>
</why>
<when>
<p>Some <em>more text</em>, with a <cxclink href="bob.html">link</cxclink>
or <ahelp name="dmextract" strong="1">two</ahelp>.</p>
</when>
<calinfo>
<caltext>Here is some text.</caltext>
<calupdates>
<calupdate version="2.3" day="19" month="March" year="01">
Some text. Really should contain a link.
</calupdate>
</calupdates>
</calinfo>
</overview>
<sectionlist>
 <section id="foo">
  <title>111 is a title</title>
  <p>A paragraph before the sub-sections.</p>
  <subsectionlist>
   <subsection id="foo-bar">
    <title>A title</title>
    <p>A paragraph with a <cxclink href="link.html">link</cxclink>.</p>
   </subsection>
   <subsection id="foo-baz">
    <title>Another title</title>
    <p>A paragraph with a <ahelp name="dmextract" tt="1">link</ahelp>.</p>
   </subsection>
  </subsectionlist>
 </section>
 <section id="bar">
  <title>Boo</title>
   <p>Some text with a <dictionary id="bob">dictionary link</dictionary> in it.</p>
 </section>
</sectionlist>
<summary>
<p>Some text</p>
<p>Some <em>more text</em>, with a <cxclink href="bob.html">link</cxclink>
or <ahelp name="dmextract" strong="1">two</ahelp>.</p>
</summary>
</text>
<parameters>
<paramfile name="bob">
  infile = evt2.fits  Some sort of comment
    (bob = no)
</paramfile>
<paramfile name="bob" id="fred">
  infile = evt2.fits  Some sort of comment
    (bob = yes)
</paramfile>
</parameters>
<images>
 <image id="foo"><title>Blah Blah</title></image>
 <image id="bar"><title>More stuff</title></image>
</images>';

$out =
'<h2><a name="toc">Contents</a></h2><ul>
<li>
<strong><a href="index.html#foo">111 is a title</a></strong><ul>
<li><a href="index.html#foo-bar">A title</a></li>
<li><a href="index.html#foo-baz">Another title</a></li>
</ul>
</li>
<li><strong><a href="index.html#bar">Boo</a></strong></li>
<li><a href="index.html#summary"><strong>Summary</strong></a></li>
<li>
<strong>Parameter files:</strong><ul>
<li><a href="index.html#bob.par">bob</a></li>
<li><a href="index.html#bob.par_fred">bob</a></li>
</ul>
</li>
<li><strong><a href="index.html#history">History</a></strong></li>
<li>
<strong>Images</strong><ul>
<li><a href="img1.html">Blah Blah</a></li>
<li><a href="img2.html">More stuff</a></li>
</ul>
</li>
</ul><hr>';

add_test "toc", $transform, $in, $out;

$in =~ s/<text>/<text number="1">/;

$out =~ s/111 is a title/1 - 111 is a title/;
$out =~ s/Boo/2 - Boo/;

add_test "toc-number", $transform, $in, $out;

$in =~ s/<subsectionlist>/<subsectionlist type="A">/;

$out =~ s{111 is a title</a></strong><ul>}{111 is a title</a></strong><ol type="A">};
$out =~ s{Another title</a></li>\n</ul>}{Another title</a></li>\n</ol>};

add_test "toc-number-typeA", $transform, $in, $out;

## end of tests

write_script();

## End
#
exit;

## Subroutines

# uses global variables @name_single and @name_loop
#
sub add_test ($$$$;@) {
    my $name  = shift;
    my $style = shift;
    my $in    = shift;
    my $out   = shift;
    my %opts  =
      (
       type => "web",
       @_
       );

    my $type = $opts{type};

    # we default to site=ciao depth=1 unless
    # the output string (here $out) contains
    # either %d or %s (NOTE: for now this can NOT be
    # over-ridden, eg by protecting the % character)
    # If either of these are found then we loop through
    # site=ciao,sherpa,chart and depth=1,2
    #
    my $loop = $out =~ m/%d/ || $out =~ m/%s/ ? "multiple" : "single";

    # for now hard-code the meta information
    #
    my $test_string = get_xml_header( "thread" );
    $test_string .= <<"EOD";
<info><name>test</name><version>3.0</version>
<title><long>Long Title</long><short>short</short></title>
<history>
<entry day="2" month="January" year="2002" who="bob">A test string with a <ahelp name="dmextract" tt="1" strong="1">link</ahelp>.</entry>
<entry day="23" month="March" year="2" who="tester">Test string.</entry>
</history>
</info>
EOD

    $test_string .= $in;
    $test_string .= "\n</thread>\n";
    write_out $test_string, "${indir}/${name}.xml";

    # OUTPUT
    #
    # this depends on whether we have to worry about
    # single or multiple site/depths
    #
    my $ofile = "${outdir}/${name}";
    my $out_string;
    if ( $loop eq "single" ) {
	$out_string = get_html_header();
	$out_string .=  "$out\n";
	write_out $out_string, $ofile;

	push @name_single, "${name}";
    } else {
	foreach my $site ( qw( ciao sherpa chart ) ) {
	    foreach my $depth ( qw( 1 2 ) ) {
		$out_string = get_html_header();
		$out_string .=  convert_depth_site( $out, $depth, $site ) . "\n";
		write_out $out_string, "${ofile}_${site}_d${depth}";
	    } # for: $depth
	} # for: $site

	push @name_loop, "${name}";
    }

    # STYLESHEET
    #
    $out_string = get_xslt_header();
    $out_string .= <<"EOD";
  <xsl:include href="../../../globalparams.xsl"/>
  <xsl:include href="../../../thread_common.xsl"/>
  <xsl:include href="../../../helper.xsl"/>
  <xsl:include href="../../../links.xsl"/>
  <xsl:include href="../../../myhtml.xsl"/>
  <!--* has to be after thread_commmon since that sets output to text *-->
  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
EOD

    $out_string .= $style . "\n</xsl:stylesheet>\n";
    write_out $out_string, "${indir}/${name}.xsl";
    print "Created: ${name}.x[sm]l\n";

} # sub: add_test()

# uses the global variables @name_loop and @name_single
#
sub write_script () {
    my $ofile = "run_tests.csh";

    my $fh = IO::File->new( "> $ofile" )
      or die "Error: unable to open $ofile for writing\n";

    print $fh get_test_setup("thread");

    print $fh <<'EOD';
## single shot tests
#
set type  = test
set site  = ciao
set depth = 1

set params = "--stringparam sourcedir `pwd`/ --stringparam hardcopy 0 --stringparam depth 1 --stringparam imglinkicon foo.gif --stringparam imglinkiconwidth 10 --stringparam imglinkiconheight 12 --stringparam ahelpindex `pwd`/../links/ahelpindexfile.xml --stringparam site $site"

foreach id ( \
EOD

    my $ctr = 1;
    foreach my $name ( @name_single ) {
        $fh->print( " $name " );
        $ctr = ($ctr+1) % 5;
        $fh->print(" \\\n") unless $ctr;
    }
    $fh->print(" \\\n") if $ctr;

    print $fh <<'EOD';
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

EOD

    print $fh <<'EOD';
## multiple  tests
#
set type  = test

set params = "--stringparam sourcedir `pwd`/ --stringparam hardcopy 0 --stringparam imglinkicon foo.gif --stringparam imglinkiconwidth 10 --stringparam imglinkiconheight 12 --stringparam ahelpindex `pwd`/../links/ahelpindexfile.xml"

foreach id ( \
EOD

    $ctr = 1;
    foreach my $name ( @name_loop ) {
        $fh->print( " $name " );
        $ctr = ($ctr+1) % 5;
        $fh->print(" \\\n") unless $ctr;
    }
    $fh->print(" \\\n") if $ctr;

    print $fh <<'EOD';
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

EOD

    print $fh get_test_report();
    $fh->close;
    finished_test $ofile;

} # sub: write_script()

