#!/data/da/Docs/local/perl/bin/perl -w
#
# $Id: make_tests.pl,v 1.9 2004/09/15 18:35:09 dburke Exp dburke $
#
# Usage:
#   make_tests.pl
#
# Aim:
#   Creates files used for the tests of the ahelp conversion
#
# Creates:
#   stuff in in/ and out/
#
# History:
#   03/05/02 DJB Based on version from myhtml test
#   10/09/03 DJB Fixing "see also" tests
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
my @name_params;

my $indir  = "in";
my $outdir = "out";
cleanup_dirs $indir, $outdir;

add_test "para-pcdata",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//PARA"/>
</xsl:template>',
'<PARA>A boring paragraph.</PARA>',
'<p>A boring paragraph.</p>';

add_test "para-pcdata-title",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//PARA"/>
</xsl:template>',
'<PARA title="A boring TITLE">A boring paragraph.</PARA>',
'<h3 class="ahelpparatitle"><a name="A_boring_TITLE">A boring TITLE</a></h3><p>A boring paragraph.</p>';

# I'm assuming none of our files have passthru/xmlonly blocks in
# so can't be bothered testing them
add_test "equation-para",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//PARA"/>
</xsl:template>',
'<PARA>A slightly-less boring paragraph.
<EQUATION>
Some stuff
</EQUATION>
</PARA>',
'<p>A slightly-less boring paragraph.
</p><div class="ahelpequation"><pre class="highlight">Some stuff</pre></div><p></p>';

add_test "href-para",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//PARA"/>
</xsl:template>',
'<PARA>A mildly-less boring paragraph.
<HREF link="http://bob/fred">Some stuff</HREF>.
And some more stuff.
</PARA>',
'<p>A mildly-less boring paragraph.
<a href="http://bob/fred">Some stuff</a>.
And some more stuff.
</p>';

add_test "synopsis-entry",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//ENTRY/SYNOPSIS"/>
</xsl:template>',
'<SYNOPSIS>
foo foo mc
foo
  </SYNOPSIS>',
'<div class="ahelpsynopsis">
<h2><a name="synopsis">Synopsis</a></h2>
<p>
foo foo mc
foo
  </p>
</div>';

add_test "synopsis-param",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//PARAM/SYNOPSIS" mode="plist"/>
</xsl:template>',
'<PARAM><SYNOPSIS>
foo foo mc
foo
  </SYNOPSIS></PARAM>',
'<p class="ahelpsynopsis"><em>
foo foo mc
foo
  </em></p>';

# implicitly tests LINE
#
add_test "syntax-entry",
'<xsl:variable name="maxlen" select="10"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//ENTRY/SYNTAX"/>
</xsl:template>',
'<SYNTAX>
<LINE>
</LINE>
<LINE>foo foo mc</LINE>
<LINE>one two three four</LINE>
<LINE>abcdefghijklmnopqr</LINE>
<LINE>
foo
</LINE>
  </SYNTAX>',
'<div class="ahelpsyntax">
<h2><a name="syntax">Syntax</a></h2>
<pre class="highlight">
foo foo mc
one two
three four
abcdefghij
klmnopqr
foo</pre>
</div>';

# implicitly tests LINE
#
add_test "syntax-qexample1",
'<xsl:variable name="maxlen" select="10"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//QEXAMPLE/SYNTAX"/>
</xsl:template>',
'<QEXAMPLE><SYNTAX>
<LINE>
</LINE>
<LINE>foo foo mc</LINE>
<LINE>one two three four</LINE>
<LINE>abcdefghijklmnopqr</LINE>
<LINE>
foo
</LINE>
  </SYNTAX></QEXAMPLE>',
'<div class="ahelpsyntax"><pre class="highlight">
foo foo mc
one two
three four
abcdefghij
klmnopqr
foo</pre></div>';

# ignore "blank" blocks
add_test "syntax-qexample2",
'<xsl:variable name="maxlen" select="10"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//QEXAMPLE/SYNTAX"/>
</xsl:template>',
'<QEXAMPLE><SYNTAX>
<LINE>
</LINE>
  </SYNTAX></QEXAMPLE>',
'';

# highlight-content within a PARA - ie PARA contains a SYNTAX block
add_test "syntax-para",
'<xsl:variable name="maxlen" select="10"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//PARA"/>
</xsl:template>',
'<PARA>
Here is some text before the syntax block
<SYNTAX>
<LINE>
</LINE>
<LINE>foo foo mc</LINE>
<LINE>one two three four</LINE>
<LINE>abcdefghijklmnopqr</LINE>
<LINE>
foo
</LINE>
</SYNTAX>
and some text after it.
</PARA>',
'<p>
Here is some text before the syntax block
</p><div class="ahelpsyntax"><pre class="highlight">
foo foo mc
one two
three four
abcdefghij
klmnopqr
foo</pre></div><p>
and some text after it.
</p>';

# test parts used to generate the SYNTAX block from the PARAMLIST section
add_test "syntax-line-from-paramlist",
'<xsl:template match="/"><xsl:apply-templates select="cxchelptopics/ENTRY" mode="test"/></xsl:template>
<xsl:template match="ENTRY" mode="test">
<xsl:text>
</xsl:text>
  <xsl:call-template name="create-syntax-from-paramlist"/>
  <xsl:text>@@</xsl:text>
</xsl:template>',
'<PARAMLIST>
<PARAM name="foo" reqd="yes"/>
<PARAM name="bar" reqd="no"/>
<PARAM name="baz"/>
</PARAMLIST>',
'foofoo  foo [bar] [baz]@@';

# test parts used to generate the SYNTAX block from the PARAMLIST section
add_test "syntax-block-from-paramlist",
'<xsl:variable name="maxlen" select="10"/>
<xsl:template match="/"><xsl:apply-templates select="cxchelptopics/ENTRY" mode="test"/></xsl:template>
<xsl:template match="ENTRY" mode="test">
<xsl:text>
</xsl:text>
  <xsl:call-template name="create-entry-syntax"/>
</xsl:template>',
'<PARAMLIST>
<PARAM name="foo" reqd="yes"/>
<PARAM name="bar" reqd="no"/>
<PARAM name="baz"/>
</PARAMLIST>',
'<div class="ahelpsyntax">
<h2><a name="syntax">Syntax</a></h2>
<pre class="highlight">
foofoo 
foo [bar]
[baz]</pre>
</div>';

### umm, emacs' indenting seems to go screwy here

# also tests VERBATIM
add_test "bugs1",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//BUGS"/>
</xsl:template>',
'<BUGS>
<PARA>
Wow, a paragraph.
And another line.
</PARA>
 <VERBATIM>
  a a a

b b   b
</VERBATIM>
  </BUGS>',
'<div class="ahelpbugs">
<h2><a name="bugs">Bugs</a></h2>
<p>
Wow, a paragraph.
And another line.
</p>
 <div class="ahelpverbatim"><pre class="highlight">
  a a a

b b   b
</pre></div>
  </div>';

add_test "bugs2",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//BUGS"/>
</xsl:template>',
'<BUGS>
<PARA title="A title">A paragraph.</PARA>
<PARA>
A paragraph with <HREF link="http://www.foo.com/">a link</HREF>.
</PARA>
  </BUGS>',
'<div class="ahelpbugs">
<h2><a name="bugs">Bugs</a></h2>
<h3 class="ahelpparatitle"><a name="A_title">A title</a></h3>
<p>A paragraph.</p>
<p>
A paragraph with <a href="http://www.foo.com/">a link</a>.
</p>
  </div>';

# also tests ITEM
add_test "list",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//LIST"/>
</xsl:template>',
'<LIST><ITEM>foo</ITEM><ITEM>bar</ITEM></LIST>',
'<ul>
<li>foo</li>
<li>bar</li>
</ul><br>';

add_test "list-with-caption",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//LIST"/>
</xsl:template>',
'<LIST>
<CAPTION>
Foo Bar
</CAPTION>
<ITEM>foo</ITEM><ITEM>bar</ITEM>
</LIST>',
'<h4>
Foo Bar
</h4><ul>
<li>foo</li>
<li>bar</li>
</ul><br>';

# also tests ROW & DATA
add_test "table",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//TABLE"/>
</xsl:template>',
'<TABLE>
  <ROW><DATA>foo</DATA></ROW>
</TABLE>',
'<table border="1" frame="void"><tr class="headerrow"><th>foo</th></tr></table>';

add_test "table2",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//TABLE"/>
</xsl:template>',
'<TABLE>
  <ROW><DATA>foo</DATA></ROW>
  <ROW><DATA></DATA><DATA>foo</DATA><DATA>baa baa</DATA></ROW>
</TABLE>',
'<table border="1" frame="void">
<tr class="headerrow"><th>foo</th></tr>
<tr>
<td></td>
<td>foo</td>
<td>baa baa</td>
</tr>
</table>';

add_test "table-with-caption",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//TABLE"/>
</xsl:template>',
'<TABLE>
  <CAPTION>A caption.</CAPTION>
  <ROW><DATA>foo</DATA></ROW>
</TABLE>',
'<h4>A caption.</h4><table border="1" frame="void"><tr class="headerrow"><th>foo</th></tr></table>';


add_test "desc-entry",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//ENTRY/DESC"/>
</xsl:template>',
'<DESC>
 <PARA>
foo foo mc
foo
 </PARA>
<VERBATIM>
  aa a
</VERBATIM>
</DESC>',
'<div class="ahelpdesc">
<h2><a name="description">Description</a></h2>
 <p>
foo foo mc
foo
 </p>
<div class="ahelpverbatim"><pre class="highlight">
  aa a
</pre></div>
</div>';

add_test "desc-qexample",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//QEXAMPLE/DESC"/>
</xsl:template>',
'<QEXAMPLELIST><QEXAMPLE><DESC>
 <PARA>
foo foo mc
foo
 </PARA>
<VERBATIM>
  aa a
</VERBATIM>
</DESC></QEXAMPLE></QEXAMPLELIST>',
'<div class="ahelpdesc">
 <p>
foo foo mc
foo
 </p>
<div class="ahelpverbatim"><pre class="highlight">
  aa a
</pre></div>
</div>';

add_test "adesc-entry",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//ENTRY/ADESC"/>
</xsl:template>',
'<ADESC>
 <PARA>
foo foo mc
foo
 </PARA>
<VERBATIM>
  aa a
</VERBATIM>
</ADESC>',
'<div class="ahelpadesc">
 <p>
foo foo mc
foo
 </p>
<div class="ahelpverbatim"><pre class="highlight">
  aa a
</pre></div>
</div>';

add_test "adesc-entry-with-title",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//ENTRY/ADESC"/>
</xsl:template>',
'<ADESC title="Foo Foo_Bar">
 <PARA>
foo foo mc
foo
 </PARA>
<VERBATIM>
  aa a
</VERBATIM>
</ADESC>',
'<div class="ahelpadesc">
<h3 class="ahelpparatitle"><a name="Foo_Foo_Bar">Foo Foo_Bar</a></h3>
 <p>
foo foo mc
foo
 </p>
<div class="ahelpverbatim"><pre class="highlight">
  aa a
</pre></div>
</div>';

add_test "adesc-entry2",
'<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//ENTRY/ADESC"/>
</xsl:template>',
'<ADESC>
 <PARA>
foo foo mc
foo
 </PARA>
<VERBATIM>
  aa a
</VERBATIM>
</ADESC>
<ADESC title="Foo Foo_Bar">
 <PARA>
foo foo mc
foo
 </PARA>
<VERBATIM>
  aa a
</VERBATIM>
</ADESC>',
'<div class="ahelpadesc">
 <p>
foo foo mc
foo
 </p>
<div class="ahelpverbatim"><pre class="highlight">
  aa a
</pre></div>
</div><div class="ahelpadesc">
<h3 class="ahelpparatitle"><a name="Foo_Foo_Bar">Foo Foo_Bar</a></h3>
 <p>
foo foo mc
foo
 </p>
<div class="ahelpverbatim"><pre class="highlight">
  aa a
</pre></div>
</div>';

# major testing of QEXAMPLELIST/QEXAMPLE although some
# of the components have already been tested
#
add_test "qexamplelist",
'<xsl:variable name="maxlen" select="10"/>
<xsl:variable name="nexample" select="count(//ENTRY/QEXAMPLELIST/QEXAMPLE)"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//QEXAMPLELIST"/>
</xsl:template>',
'<QEXAMPLELIST>
<QEXAMPLE>
<SYNTAX>
<LINE>
</LINE>
<LINE>foo foo mc</LINE>
<LINE>one two three four</LINE>
<LINE>abcdefghijklmnopqr</LINE>
<LINE>
foo
</LINE>
</SYNTAX>
<DESC>
 <PARA>
foo foo mc
foo
 </PARA>
<VERBATIM>
  aa a
</VERBATIM>
</DESC></QEXAMPLE>
</QEXAMPLELIST>',
'<div class="ahelpexample">
<a name="examples"></a><h2><a name="example1">Example</a></h2>
<div class="ahelpsyntax"><pre class="highlight">
foo foo mc
one two
three four
abcdefghij
klmnopqr
foo</pre></div>
<div class="ahelpdesc">
 <p>
foo foo mc
foo
 </p>
<div class="ahelpverbatim"><pre class="highlight">
  aa a
</pre></div>
</div>
</div>';

add_test "qexamplelist2",
'<xsl:variable name="maxlen" select="10"/>
<xsl:variable name="nexample" select="count(//ENTRY/QEXAMPLELIST/QEXAMPLE)"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//QEXAMPLELIST"/>
</xsl:template>',
'<QEXAMPLELIST>
<QEXAMPLE>
 <SYNTAX><LINE>Foo Foo</LINE></SYNTAX>
 <DESC><PARA>One.</PARA></DESC>
</QEXAMPLE>
<QEXAMPLE>
<SYNTAX>
<LINE>
</LINE>
<LINE>foo foo mc</LINE>
<LINE>one two three four</LINE>
<LINE>abcdefghijklmnopqr</LINE>
<LINE>
foo
</LINE>
</SYNTAX>
<DESC>
 <PARA>
foo foo mc
foo
 </PARA>
<VERBATIM>
  aa a
</VERBATIM>
</DESC></QEXAMPLE>
</QEXAMPLELIST>',
'<div class="ahelpexample">
<a name="examples"></a><h2><a name="example1">Example 1</a></h2>
<div class="ahelpsyntax"><pre class="highlight">
Foo Foo</pre></div>
<div class="ahelpdesc"><p>One.</p></div>
</div><div class="ahelpexample">
<h2><a name="example2">Example 2</a></h2>
<div class="ahelpsyntax"><pre class="highlight">
foo foo mc
one two
three four
abcdefghij
klmnopqr
foo</pre></div>
<div class="ahelpdesc">
 <p>
foo foo mc
foo
 </p>
<div class="ahelpverbatim"><pre class="highlight">
  aa a
</pre></div>
</div>
</div>';

# major testing of PARAMLIST/PARAM although some
# of the components have already been tested
#
# doesn't quite test all combinations (mainly "pathological"
# ones) but is a good start
#
add_test "paramlist",
'<xsl:variable name="nparam"     select="count(//ENTRY/PARAMLIST/PARAM)"/>
<xsl:variable name="have-ftype" select="count(//PARAM[@filetype])!=0"/>
<xsl:variable name="have-def"   select="count(//PARAM[@def])!=0"/>
<xsl:variable name="have-min"   select="count(//PARAM[@min])!=0"/>
<xsl:variable name="have-max"   select="count(//PARAM[@max])!=0"/>
<xsl:variable name="have-units" select="count(//PARAM[@units])!=0"/>
<xsl:variable name="have-reqd"  select="count(//PARAM[@reqd])!=0"/>
<xsl:variable name="have-stcks" select="count(//PARAM[@stacks])!=0"/>
<xsl:variable name="have-aname" select="count(//PARAM[@autoname])!=0"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:apply-templates select="//PARAMLIST"/>
</xsl:template>',
'<PARAMLIST>
<PARAM name="infile" type="file" filetype="input" reqd="yes" stacks="yes">
<SYNOPSIS>
 The input virtual file or stack, e.g. event list, modified
 by a dmextract binning command.
</SYNOPSIS>
<DESC>
 <PARA>
  Any table or stack of tables is valid input, with the
  <EQUATION>table[bin scalar_col=min:max:step]</EQUATION>
  blah.
 </PARA>
</DESC>
</PARAM>
<PARAM name="bob" type="integer" min="-1" max="10" def="2">
<SYNOPSIS>Foo</SYNOPSIS>
</PARAM>
<PARAM name="fred" type="notype" units="km/s foo">
<SYNOPSIS>Bar</SYNOPSIS>
<DESC>
 <LIST>
  <ITEM>One</ITEM>
 </LIST>
</DESC>
</PARAM>
<PARAM name="george" autoname="yes" type="string">
<SYNOPSIS>111 222</SYNOPSIS>
</PARAM>
</PARAMLIST>',
'<div class="ahelpparameters">
<h2><a name="ptable">Parameters</a></h2>
<table class="ahelpparamlist" border="1" cellspacing="1" cellpadding="2">
<tr class="headerrow">
<th>name</th>
<th>type</th>
<th>ftype</th>
<th>def</th>
<th>min</th>
<th>max</th>
<th>units</th>
<th>reqd</th>
<th>stacks</th>
<th>autoname</th>
</tr>
<tr class="oddrow">
<td><a title="Jump to parameter description" href="#plist.infile">infile</a></td>
<td>file</td>
<td>input</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>yes</td>
<td>yes</td>
<td>&nbsp;</td>
</tr>
<tr class="evenrow">
<td><a title="Jump to parameter description" href="#plist.bob">bob</a></td>
<td>integer</td>
<td>&nbsp;</td>
<td>2</td>
<td>-1</td>
<td>10</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
</tr>
<tr class="oddrow">
<td><a title="Jump to parameter description" href="#plist.fred">fred</a></td>
<td>notype</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>km/s foo</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
</tr>
<tr class="evenrow">
<td><a title="Jump to parameter description" href="#plist.george">george</a></td>
<td>string</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>&nbsp;</td>
<td>yes</td>
</tr>
</table>
<br><h2><a name="plist">Detailed Parameter Descriptions</a></h2>
<div class="ahelpparam">
<h4>
<a name="plist.infile">Parameter=infile</a><tt> (file required filetype=input stacks=yes)</tt>
</h4>
<p class="ahelpsynopsis"><em>
 The input virtual file or stack, e.g. event list, modified
 by a dmextract binning command.
</em></p>
<div class="ahelpdesc">
 <p>
  Any table or stack of tables is valid input, with the
  </p><div class="ahelpequation"><pre class="highlight">table[bin scalar_col=min:max:step]</pre></div><p>
  blah.
 </p>
</div>
</div>
<div class="ahelpparam">
<h4>
<a name="plist.bob">Parameter=bob</a><tt> (integer default=2 min=-1 max=10)</tt>
</h4>
<p class="ahelpsynopsis"><em>Foo</em></p>
</div>
<div class="ahelpparam">
<h4>
<a name="plist.fred">Parameter=fred</a><tt> (notype units=km/s foo)</tt>
</h4>
<p class="ahelpsynopsis"><em>Bar</em></p>
<div class="ahelpdesc">
 <ul><li>One</li></ul>
<br>
</div>
</div>
<div class="ahelpparam">
<h4>
<a name="plist.george">Parameter=george</a><tt> (string autoname=yes)</tt>
</h4>
<p class="ahelpsynopsis"><em>111 222</em></p>
</div>
</div>';

# tests for which we need to change/add parameters
#
write_out
'<?xml version="1.0" encoding="us-ascii" ?>
<!DOCTYPE seealso>
<seealso/>
', "in/seealso.empty.xml";

add_test "no-seealso",
'<xsl:param name="seealso" select="document($seealsofile)/seealso"/>
<xsl:param name="have-seealso"  select="$seealso != \'\'"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:call-template name="add-seealso"/>
</xsl:template>',
'', '',
params => { seealsofile => getcwd() . "/in/seealso.empty.xml" };

my $seealso_text =
'<dl>
<dt><em>chips:</em></dt>
<dd><a href="foo.html">foo</a></dd>
<dt><em>bob:</em></dt>
<dd>
<a href="foo.html">foo</a>, <a href="bar.html">bar</a>
</dd>
</dl>';

write_out
  get_xml_header("seealso") . $seealso_text . "\n</seealso>\n",
  "in/seealso.full.xml";

add_test "seealso",
'<xsl:param name="seealso" select="document($seealsofile)/seealso"/>
<xsl:param name="have-seealso"  select="$seealso != \'\'"/>
<xsl:template match="/">
<xsl:text>
</xsl:text>
  <xsl:call-template name="add-seealso"/>
</xsl:template>',
'',
"<div class=\"ahelpseealso\">
<h2><a name=\"seealso\">See Also</a></h2>
$seealso_text
</div>",
params => { seealsofile => getcwd() . "/in/seealso.full.xml" };

## lots more tests
#
# not tested all DESC stuff
#

## end of tests

write_script();

## End
#
exit;

## Subroutines

# uses global variables @name, @name_params
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

    # for now hard-code key/context/etc - may want to allow this to be changeable
    #
    my $test_string = get_xml_header("cxchelptopics") . <<"EOD";
<ENTRY key="foofoo" context="baabaa" refkeywords="foo bar mary poppins"
seealsogroups="foogroup">
EOD

    $test_string .= $in;
    $test_string .= "\n</ENTRY></cxchelptopics>\n";
    write_out $test_string, "${indir}/${name}.xml";

    # OUTPUT
    write_out get_html_header() . "$out\n", "${outdir}/${name}";

    # STYLESHEET
    #
    my $out_string = get_xslt_header();
    $out_string .= <<'EOD';
  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
  <xsl:include href="../../../ahelp_main.xsl"/>
  <xsl:strip-space elements="SYNTAX PARA"/> <!--* addded for CIAO 3.1 *-->
EOD

    write_out $out_string . $style . "\n</xsl:stylesheet>\n", "${indir}/${name}.xsl";

    print "Created: ${name}.x[sm]l\n";

    if ( exists $opts{params} ) {
      push @name_params, [ $name, $opts{params} ];
    } else {
      push @name, "${name}";
    }

} # sub: add_test()

# uses the global variables @name and @name_params
#
sub write_script () {
    my $ofile = "run_tests.csh";

    my $fh = IO::File->new( "> $ofile" )
      or die "Error: unable to open $ofile for writing\n";

    print $fh get_test_setup("ahelp");
    print $fh <<'EOD';
## single shot tests
#
set type  = test
set site  = ciao
set depth = 1
set srcdir = /data/da/Docs/web/devel/test/ahelp

foreach id ( \
EOD

    print_id_list( $fh, @name );

    print $fh <<'EOD';
  )

  set out = out/xslt.$id
  if ( -e $out ) rm -f $out
  /usr/bin/env LD_LIBRARY_PATH=$ldpath $xsltproc --stringparam hardcopy 0 --stringparam bocolor foo --stringparam bgcolor bar in/${id}.xsl in/${id}.xml > $out
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

## 'parameter' tests
#
# do these individually
#
EOD

    foreach my $aref ( @name_params ) {
      my $name   = $$aref[0];
      my $params = join( ' ',
                   map { "--stringparam $_ " . ${ $$aref[1] }{$_}; }
                     keys %{ $$aref[1] }
                   );
      my $out = "out/xslt.$name";
      print $fh <<"EOD";

  if ( -e $out ) rm -f $out
  /usr/bin/env LD_LIBRARY_PATH=\$ldpath \$xsltproc --stringparam hardcopy 0 --stringparam bocolor foo --stringparam bgcolor bar $params \\
    in/${name}.xsl in/${name}.xml > $out
  diff out/${name} $out
  if ( \$status == 0 ) then
    printf "OK:   %3d  [%s]\\n" \$ctr $name
    rm -f $out
    @ ok++
  else
    printf "FAIL: %3d  [%s]\\n" \$ctr $name
    set fail = "\$fail $name"
  endif
  @ ctr++

EOD

  } # foreach: $aref

    print $fh get_test_report();
    $fh->close;
    finished_test $ofile;

} # sub: write_script()

