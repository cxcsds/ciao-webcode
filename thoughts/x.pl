use strict;

my $infile = shift;

my @lines = `cat $infile`;
my $oneline = join( '', @lines );

if ( $oneline =~ m/<\/EQUATION>\s*<EQUATION>/ ) {
  print "--- $infile\n";
}
