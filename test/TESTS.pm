#
# $Id: TESTS.pm,v 1.4 2004/12/03 17:51:40 dburke Exp $
#
# Aim:
#  useful routines for the test code
#
# Notes:
#  perhaps a less-generic name would be useful
#

package TESTS;
use Exporter;

@ISA    = qw( Exporter );
@EXPORT = qw(
	     cleanup_dirs
	     get_html_header get_xml_header get_xslt_header
	     get_test_setup get_test_report finished_test
	     write_out
	     get_ahelp_link get_dictionary_link
	     convert_depth_site
	     print_id_list
	    );

use strict;

use IO::File;

sub call_touch ($) {
  my $arg = shift;
  my $t = $^O eq "darwin" ? "/usr/bin/touch" : "/usr/ucb/touch";
  `$t $arg`;
}

sub call_rm ($) {
  my $arg = shift;
  my $rm = $^O eq "darwin" ? "/bin/rm" : "/usr/bin/rm";
  `$rm $arg`;
}

sub cleanup_dirs (@) {
    foreach my $dir ( @_ ) {
	die "Error: unable to find $dir\n" unless -d $dir;
	# just to stop warning messages if the dir is empty
	call_touch "$dir/delme.now";
	# clear out
	call_rm "$dir/*";
    }
}

# valid for libxmlv2.6
#
sub get_html_header() {
    return <<'EOD';
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">

EOD
}

sub get_xml_header($;@) {
    my $name = shift;
    my $opts = { attribute => "", @_ };

    my $extra = $$opts{attribute} eq "" ? "" : " " . $$opts{attribute};

    return <<"EOD";
<?xml version='1.0' encoding='us-ascii' ?>
<!DOCTYPE ${name}>
<${name}${extra}>
EOD
}

sub get_xslt_header() {
    return <<"EOD";
<?xml version='1.0' encoding='us-ascii' ?>
<!DOCTYPE xsl:stylesheet>
<xsl:stylesheet version='1.0' xmlns:xsl='http://www.w3.org/1999/XSL/Transform'>
EOD
}

sub get_test_setup($) {
    my $name = shift;

    return <<"EOD";
#!/bin/csh
#
# Test $name stylesheets
#

# Should check for unknown systems
#
set PLATFORM = `uname`
switch (\$PLATFORM)

  case SunOS
    set head     = /data/da/Docs/local
    set xsltproc = /usr/bin/env LD_LIBRARY_PATH=\${head}/lib \${head}/bin/xsltproc
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
set fail = \"\"

EOD
}

sub get_test_report() {
    return <<'EOD';

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

EOD
}

sub finished_test($) {
    my $name = shift;
    print "\nCreated: $name\n\n";
    `chmod ug+x $name`;
}

sub write_out($$) {
    my $content = shift;
    my $file    = shift;
    my $fh = IO::File->new( "> $file" )
      or die "Error: unable to open $file for writing\n";
    $fh->print( $content );
    $fh->close;
}

# NOTE:
#  this does not include the tt/em/strong attributes
#  ie you need to add these yourself
#
sub get_ahelp_link($) {
    my $contents = shift;
    return '<a class="helplink" title="Ahelp (tools): This is a summary!" href="%sahelp/dmextract.html">' . $contents . "</a>";
}

# note:
#  could use faq tag but that's a pain since it has
#  somewhat non-standard handling of sites (as it links
#  to either the ciao or sherpa faq OR uses the site tag)
#
sub get_dictionary_link($$) {
    my $name     = shift;
    my $contents = shift;
    return '<a class="helplink" title="CIAO Dictionary" href="%sdictionary/' . $name . '.html">' . $contents . "</a>";
}

# for the moment we assume that
# the base "site" for site tags is ciao
# this should probably be relaxed (so we can
# test handling of certain tags)
#
sub convert_depth_site ($$$) {
    my $text  = shift;
    my $depth = shift;
    my $site  = shift;

    my $dir = '../' x ($depth-1);
    my $out = $text;
    $out =~ s/%d/$dir/g;

    if ( $site eq "ciao" ) {
	$out =~ s/%s/$dir/g;
    } else {
	$out =~ s/%s/\/ciao\//g;
    }

    return $out;
}

sub print_id_list ($@) {
    my $fh    = shift;
    my @names = @_;
    my $ctr = 1;
    foreach my $name ( @names ) {
        $fh->print( " $name " );
        $ctr = ($ctr+1) % 5;
        $fh->print(" \\\n") unless $ctr;
    }
    $fh->print(" \\\n") if $ctr;
}

# end
1;
