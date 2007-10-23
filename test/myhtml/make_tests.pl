#!/data/da/Docs/local/perl/bin/perl -w
#
# $Id: make_tests.pl,v 1.13 2005/03/02 23:23:11 dburke Exp $
#
# Usage:
#   make_tests.pl
#
# Aim:
#   Creates files used for the tests of myhtml.xsl
#
# Creates:
#   stuff in in/ and out/
#
# History:
#   02/07/30 DJB Based on version from links test
#   04/05/16 DJB Major updates as have managed to clean up
#                some of the stylesheets for CIAO 3.1
#

use strict;

use IO::File;

use lib "..";
use TESTS;

sub add_test ($$;$);
sub write_script ();

## Code
#
my @name;

# useful combination of text and tags to test
# some of the routines
#
my $contents = "Foo <p>some text</p> baR";

# note: some of the routines actually hard code $indir/$outdir values
my $indir  = "in";
my $outdir = "out";
cleanup_dirs $indir, $outdir;

add_test "start-tag", '<';
add_test "end-tag",   '>';
add_test "add-quote", '"';

# we now use the 'character point' (or whatever it is called)
##add_test "add-nbsp",  '&nbsp;';
add_test "add-nbsp",  '&#160;';

add_test "add-end-body",   '</body>';
add_test "add-start-html", '<html lang="en">';
add_test "add-end-html",   '</html>';

# test the style attributes
# - they rely on the order of processing of the
#   attributes within the stylesheet
#   (which is currently: em tt strong

add_test "add-text-styles", 'foo BaR',
  {
   tag => '',
   param => [ contents => 'foo BaR' ],
  };
add_test "add-text-styles", $contents,
  {
   tag => '', addon => '-tag',
   param => [ contents => $contents ],
  };

foreach my $x ( qw( em strong tt ) ) {
    add_test "add-text-styles", "<$x>foo BaR</$x>",
      {
       tag => '', addon => "-$x", attr => "$x='1'",
       param => [ contents => 'foo BaR' ],
      };
    add_test "add-text-styles", "<$x>${contents}</$x>",
      {
       tag => '', addon => "-${x}-tag", attr => "$x='1'",
       param => [ contents => $contents ],
      };
}

foreach my $x ( qw( strong tt ) ) {
    add_test "add-text-styles", "<em><$x>foo BaR</$x></em>",
      {
       tag => '', addon => "-em-$x", attr => "em='1' $x='1'",
       param => [ contents => 'foo BaR' ],
      };
    add_test "add-text-styles", "<em><$x>${contents}</$x></em>",
      {
       tag => '', addon => "-em-${x}-tag", attr => "em='1' $x='1'",
       param => [ contents => $contents ],
      };
}

add_test "add-text-styles", "<em><tt><strong>foo BaR</strong></tt></em>",
  {
   tag => '', addon => "-em-tt-strong", attr => "em='1' tt='1' strong='1'",
   param => [ contents => 'foo BaR' ],
  };
add_test "add-text-styles", "<em><tt><strong>${contents}</strong></tt></em>",
  {
   tag => '', addon => "-em-tt-strong-tag", attr => "em='1' tt='1' strong='1'",
   param => [ contents => $contents ],
  };


# implicitly tests li as well
add_test "li", '<li>a</li>', { tag => '<li>a</li>' };

add_test "list", '<ul><li>a</li></ul>', { tag => '<list><li>a</li></list>' };
add_test "list", '<ol type="A"><li>a</li></ol>', { addon => '-a', tag => '<list type="A"><li>a</li></list>' };
add_test "list", '<ol type="1"><li>a</li></ol>', { addon => '-1', tag => '<list type="1"><li>a</li></list>' };

# ensure the contents get processed - should include something
# that needs one of my templates to be called as well as
# em - which is just a copy (although still useful to include)
#
add_test "list",
'<ul>
<li>some text</li>
<li>some <em>more</em> text</li>
</ul>',
  { addon => '-more', tag => '<list><li>some text</li><li>some <em>more</em> text</li></list>' };

# implicitly tests add-date as well
my $date = '<font size="-1">(29 Jan 2001)</font>';
add_test "new", '<img src="imgs/new.gif" alt="[New]">', { tag => '<new/>' };
add_test "new", '<img src="imgs/new.gif" alt="[New]"> ' . $date,
  { addon => '-date', tag => '<new day="29" month="Jan" year="1"/>' };
add_test "new", '<img src="imgs/new.gif" alt="[New]"> ' . $date,
  { addon => '-date-2000', tag => '<new day="29" month="Jan" year="2001"/>' };

add_test "updated", '<img src="imgs/updated.gif" alt="[Updated]">', { tag => '<updated/>' };
add_test "updated", '<img src="imgs/updated.gif" alt="[Updated]"> ' . $date,
  { addon => '-date', tag => '<updated day="29" month="Jan" year="1"/>' };
add_test "updated", '<img src="imgs/updated.gif" alt="[Updated]"> ' . $date,
  { addon => '-date-2000', tag => '<updated day="29" month="Jan" year="2001"/>' };

add_test "add-date", " $date", { attr => 'day="29" month="Jan" year="1"' };
add_test "add-date", " $date", { addon => '-2000', attr => 'day="29" month="Jan" year="2001"' };

# test p handling including the extra attributes
#   align
#   text=header/note
#
# - should be done by CSS
#
add_test "p", "<p>some text</p>", { tag => '<p>some text</p>' };
add_test "p", '<p align="center">some text</p>',
  { addon => '-align', tag => '<p align="center">some text</p>' };
add_test "p", '<p><font size="+1">some text</font></p>',
  { addon => '-header', tag => '<p text="header">some text</p>' };
add_test "p", '<p><font size="-1">some text</font></p>',
  { addon => '-note', tag => '<p text="note">some text</p>' };

# and now see if we process the contents properly
# - can not be bothered to fix the "new-line before some </p> tags but not all" issue
# - now we include links.xsl [needed to test the id tag] we can not use
#   a tags in the input XML. We replace them with simple cxclink tags
#   since it is a pain to properly test the links
#
add_test "p",
'<p>some <a href="foo.html">text</a></p>',
  { addon => '-link', tag => '<p>some <cxclink href="foo.html">text</cxclink></p>' };
add_test "p",
'<p align="center">some <a href="foo.html">text</a></p>',
  { addon => '-align-link', tag => '<p align="center">some <cxclink href="foo.html">text</cxclink></p>' };
add_test "p", '<p><font size="+1">some <a href="foo.html">text</a></font></p>',
  { addon => '-header-link', tag => '<p text="header">some <cxclink href="foo.html">text</cxclink></p>' };
add_test "p", '<p><font size="-1">some <a href="foo.html">text</a></font></p>',
  { addon => '-note-link', tag => '<p text="note">some <cxclink href="foo.html">text</cxclink></p>' };

my $attr = 'src="foo.gif" alt="foo foo"';
add_test "img", "<img $attr>", { tag => "<img $attr/>" };
$attr .= ' border="0"';
add_test "img", "<img $attr>", { addon => '-border', tag => "<img $attr/>" };

# implicitly tests:
#
add_test "pre", "<pre>$contents</pre>", { tag => "<pre>$contents</pre>" };
add_test "pre",
  '<pre class="highlight">' . $contents .
  '</pre>',
  { addon => '-highlight', tag => "<pre highlight='1'>$contents</pre>" };

# highlight tests
# (this should have been implicitly tested above?)
#
add_test "add-highlight-pre",
  '<pre class="highlight">FOO BaR</pre>',
  { param => [ contents => 'FOO BaR' ] };

add_test "add-highlight-pre",
  '<pre class="highlight">FOO <flobble>BaR</flobble></pre>',
  { addon => "-tag",
    param => [ contents => 'FOO <flobble>BaR</flobble>' ] };

add_test "add-highlight-block",
  '<div class="highlighttext">FOO BaR</div>',
  { param => [ contents => 'FOO BaR' ] };

add_test "add-highlight-block",
  '<div class="highlighttext">FOO <flobble>BaR</flobble>
</div>',
  { addon => "-tag",
    param => [ contents => 'FOO <flobble>BaR</flobble>' ] };

# this is not-really much different than the above tests
#
add_test "highlight",
  '<div class="highlighttext">' . $contents .
  '</div>',
  { tag => "<highlight>$contents</highlight>" };

add_test "center", '<div align="center">' . $contents . '</div>', { tag => "<center>$contents</center>" };

# how to test the math code?

add_test "flastmod",
  '<!--#flastmod file="foofoo.html"-->',
  { tag => "<flastmod>foofoo.html</flastmod>" };

add_test "bugnum",
  '',
  { tag => "<bugnum>6123</bugnum>" };

# this is actually a tag from links.xsl but it is easier
# to test here than there because of the way the test infrastructure
# has grown up for the 2 modules
#
add_test "id",
  '<a name="example">Some Text</a>',
  { tag => '<id name="example">Some Text</id>' };
add_test "id",
  '<a name="example">Some <p>Text</p></a>',
  { addon => '-process-p', tag => '<id name="example">Some <p>Text</p></id>' };
add_test "p",
  '<p>Some <a name="example">Text</a>.</p>',
  { addon => '-id', tag => '<p>Some <id name="example">Text</id>.</p>' };
foreach ( 1, 2, 3, 4, 5 ) {
    my $h = "h$_";
    add_test $h,
      "<${h}><a name=\"example\">Some Text</a></${h}>",
	{ addon => '-id', tag => "<${h}><id name=\"example\">Some Text</id></${h}>" };
}

# want to test the scriptlist/catagory/script handling
# given the way the code is written it looks like we have
# to do pretty-much it all in one test
#
add_test "scriptlist",
'<h2><a name="scripts">Scripts included in the Package (by category)</a></h2><ul>
<li><a href="#Foo">Foo</a></li>
<li><a href="#BARBAR">BAR BAR</a></li>
</ul><table border="0" cellpadding="5" width="100%">
<tr><th align="left" colspan="5"><a name="Foo">Foo</a></th></tr>
<tr>
<td>Script</td>
<td>Associated thread(s)</td>
<td>Language</td>
<td>Version</td>
<td>Last update</td>
</tr>
<tr bgcolor="#cccccc">
<td align="center" rowspan="2"><strong>foo</strong></td>
<td>
    Should test links, but <a href="/foo/bar.html">hard to do</a>.
   </td>
<td align="center"></td>
<td align="center"></td>
<td align="center">29-Jan-1971</td>
</tr>
<tr bgcolor="#cccccc"><td align="left" colspan="4">A description</td></tr>
<tr><td colspan="5"></td></tr>
<tr bgcolor="#cccccc">
<td align="center" rowspan="2"><strong>bar</strong></td>
<td>
    Should test links, but <a href="/foo/bar.html">hard to do</a>.
   </td>
<td align="center">S-Lang</td>
<td align="center"></td>
<td align="center">29-Jan-1971<br><img src="imgs/updated.gif" alt="[Updated]">
</td>
</tr>
<tr bgcolor="#cccccc"><td align="left" colspan="4">More description</td></tr>
<tr><td colspan="5"></td></tr>
<tr><th align="left" colspan="5"><a name="BARBAR">BAR BAR</a></th></tr>
<tr>
<td>Script</td>
<td>Associated thread(s)</td>
<td>Language</td>
<td>Version</td>
<td>Last update</td>
</tr>
<tr bgcolor="#cccccc">
<td align="center" rowspan="2"><strong>ihavenowool</strong></td>
<td>
    Should test links, but <a href="/foo/bar.html">hard to do</a>.
   </td>
<td align="center"></td>
<td align="center">1.2</td>
<td align="center">29-Jan-1971<br><img src="imgs/new.gif" alt="[New]">
</td>
</tr>
<tr bgcolor="#cccccc"><td align="left" colspan="4">A description</td></tr>
<tr><td colspan="5"></td></tr>
</table>',
  {
   tag => <<EOD,
<scriptlist>
 <category name="Foo">
  <script name="foo" day="29" month="1" year="1971">
   <desc>A description</desc>
   <thread>
    Should test links, but <cxclink href="/foo/bar.html">hard to do</cxclink>.
   </thread>
  </script>
  <script name="bar" lang="S-Lang" updated="yes" day="29" month="1" year="1971">
   <desc>More description</desc>
   <thread>
    Should test links, but <cxclink href="/foo/bar.html">hard to do</cxclink>.
   </thread>
  </script>
 </category>
 <category name="BAR BAR">
  <script name="ihavenowool" new="yes" day="29" month="1" year="1971" ver="1.2">
   <desc>A description</desc>
   <thread>
    Should test links, but <cxclink href="/foo/bar.html">hard to do</cxclink>.
   </thread>
  </script>
 </category>
</scriptlist>
EOD
  };


## end of tests

write_script();

## End
#
exit;

## Subroutines

# add_test $name, $out, [ $opts=hash reference ]
#
# uses global variable @name
#
sub add_test ($$;$) {
    my $name = shift;
    my $out  = shift;
    my $opts = shift || {};

    # get the root node
    my $root = "test";

    my $attr = $$opts{attr} || "";
    my $tag  = $$opts{tag}  || "";
    my $call_flag = $tag eq "";  # I am not sure this is valid logic

    my $addon = $$opts{addon} || "";

    my $head = "${name}${addon}";

    # do we add a parameter to the template call?
    my $param = $$opts{param} || "";

    # INPUT
    #
    write_out get_xml_header($root, attribute => $attr ) . "\n$tag\n</$root>\n",
      "${indir}/${head}.xml";

    # OUTPUT
    #
    write_out get_html_header() . "$out\n", "${outdir}/${head}";

    # STYLESHEET
    #
    my $ofile = "${indir}/${head}.xsl";
    my $fh = IO::File->new( ">$ofile" )
      or die "Error: unable to open $ofile for writing\n";

    print $fh get_xslt_header() .
"  <xsl:output method='html' media-type='text/html' version='4.0' encoding='us-ascii'/>
  <xsl:include href='../../../helper.xsl'/>
  <xsl:include href='../../../myhtml.xsl'/>
  <xsl:include href='../../../links.xsl'/>
  <xsl:template match='$root'>
<xsl:text>
</xsl:text>
";

    if ( $call_flag ) {
	if ( ref($param) ) {
	    $fh->printf(
			"<xsl:call-template name='%s'>\n" .
			"  <xsl:with-param name='%s'>%s</xsl:with-param>\n" .
			"</xsl:call-template>\n",
			$name, $$param[0], $$param[1] );
 	} else {
	    $fh->print( "<xsl:call-template name=\"$name\"/>\n" );
	}
    } else {
	if ( ref($param) ) {
	    $fh->printf(
			"<xsl:apply-templates select='%s'>\n" .
			"  <xsl:with-param name='%s'>%s</xsl:with-param>\n" .
			"</xsl:apply-templates>\n",
			$name, $$param[0], $$param[1] );
 	} else {
	    $fh->print( "<xsl:apply-templates select=\"$name\"/>\n" );
	}
    }
print $fh <<"EOD";
  </xsl:template>
</xsl:stylesheet>
EOD

    $fh->close;

    print "Created: ${name}${addon}.x[sm]l\n";

    push @name, "${name}${addon}";

} # sub: add_test()

# uses the global variable @name
#
sub write_script () {
    my $ofile = "run_tests.csh";

    my $fh = IO::File->new( "> $ofile" )
      or die "Error: unable to open $ofile for writing\n";

    print $fh get_test_setup("myhtml");
    print $fh <<'EOD';
## single shot tests
#
set type  = test
set site  = ciao
set depth = 1
set srcdir = /data/da/Docs/web/devel/test/helper

foreach id ( \
EOD

    print_id_list( $fh, @name );

    print $fh <<'EOD';
  )

  set out = out/xslt.$id
  if ( -e $out ) rm -f $out
  $xsltproc --stringparam type $type --stringparam site $site --stringparam depth $depth --stringparam sourcedir $srcdir --stringparam hardcopy 0 in/${id}.xsl in/${id}.xml > $out
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

EOD

    print $fh get_test_report();
    $fh->close;
    finished_test $ofile;

} # sub: write_script()

