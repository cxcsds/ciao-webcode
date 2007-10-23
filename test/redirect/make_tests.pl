#!/data/da/Docs/local/perl/bin/perl -w
#
# $Id: make_tests.pl,v 1.3 2005/03/02 23:21:13 dburke Exp $
#
# Usage:
#   make_tests.pl
#
# Aim:
#   Creates files used for the tests of the redirect stylesheet
#
# Creates:
#   stuff in in/ and out/
#
# To do:
#
# Notes:
#
# History:
#

use strict;

use Cwd;
use IO::File;

use lib "..";
use TESTS;

sub add_test ($$);
sub write_script ();

## Code
#
my @names;

my $indir  = "in";
my $outdir = "out";
cleanup_dirs( $indir, $outdir );

## A few very simple tests
#
add_test "list", "list.html";
add_test "foo", "../foo/";
add_test "ahelp-index", "ahelp/index.html";

## end of tests

write_script();

## End
#
exit;

## Subroutines

# uses global variables @names
#
sub add_test ($$) {
    my $name  = shift;
    my $url   = shift;

    # for now hard-code the meta information
    #
    write_out
      get_xml_header( "redirect" ) . "<to>$url</to>\n</redirect>\n",
	"${indir}/${name}.xml";

    # OUTPUT
    #
    my $out_string = get_html_header();
    $out_string =~ s/\n\n/\n/;
    $out_string .=
'<html lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=us-ascii">
<title>The page you are looking for has moved</title>
<meta http-equiv="Refresh" content="0; URL=">
</head>
<body></body>
</html>
';
    $out_string =~ s/URL=/URL=$url/;
    write_out $out_string, "${outdir}/${name}";

    push @names, $name;
    print "Created: ${name}.x[sm]l\n";

} # sub: add_test()

# uses the global variable @names
#
sub write_script () {
    my $ofile = "run_tests.csh";

    my $fh = IO::File->new( "> $ofile" )
      or die "Error: unable to open $ofile for writing\n";

    print $fh get_test_setup("redirect");

    print $fh <<'EOD';
# unlike most tests we can use the actual stylesheet
#
set xsl = ../../redirect.xsl

foreach id ( \
EOD

    my $ctr = 1;
    foreach my $name ( @names ) {
        $fh->print( " $name " );
        $ctr = ($ctr+1) % 5;
        $fh->print(" \\\n") unless $ctr;
    }
    $fh->print(" \\\n") if $ctr;

    print $fh <<'EOD';
  )

  set out = out/xslt.$id
  if ( -e $out ) rm -f $out
  set outname = `$xsltproc --stringparam filename $out $xsl in/$id.xml`
  set statusa = $status
  set statusb = 1
  if ( $statusa == 0 ) then
    # avoid excess warning messages if we know it has failed
    # for some reason within the stylesheet
    #
    diff out/${id} $out
    set statusb = $status
  endif
  if ( $statusa == 0 && $statusb == 0 && $outname == $out ) then
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

