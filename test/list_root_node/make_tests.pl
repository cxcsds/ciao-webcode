#!/data/da/Docs/local/perl/bin/perl -w
#
# $Id: make_tests.pl,v 1.2 2004/09/15 21:55:23 dburke Exp $
#
# Usage:
#   make_tests.pl
#
# Aim:
#   Creates files used for the tests of the list_root_node stylesheet
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

sub add_test ($);
sub write_script ();

## Code
#
my @names;

my $indir  = "in";
my $outdir = "out";
cleanup_dirs( $indir, $outdir );

## A few very simple tests
#
add_test "list";
add_test "foo";
add_test "list-foo";

## end of tests

write_script();

## End
#
exit;

## Subroutines

# uses global variable @names
#
sub add_test ($) {
    my $name = shift;

    # INPUT
    #
    write_out
      get_xml_header( $name ) . "</$name>\n",
	"${indir}/${name}.xml";

    # OUTPUT
    #
    write_out "$name\n", "${outdir}/${name}";

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
set xsl = ../../list_root_node.xsl

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
  /usr/bin/env LD_LIBRARY_PATH=$ldpath $xsltproc $xsl in/$id.xml > $out
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

    print $fh get_test_report();
    $fh->close;
    finished_test $ofile;

} # sub: write_script()

