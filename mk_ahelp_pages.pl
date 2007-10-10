#!/data/da/Docs/local/perl/bin/perl -w
#
# $Id: mk_ahelp_pages.pl,v 1.8 2006/09/06 17:25:11 egalle Exp $
#
# Usage:
#   mk_ahelp_pages.pl [name1 ... namen]
#     --config=name
#     --type=test|live|trial|dist
#     --verbose
#
#   The default is --type=test, which sets up for test web site.
#   The live option sets things up for the live (ie cxc.harvard.edu) site.
#   The type=dist is for people building the HTML pages for the
#   CIAO distribution.
#   Don't use the trial option unless you know what it does.
#
#   The --config option gives the path to the configuration file; this
#   defaults to config.dat in the same directory as the script.
#
#   The --verbose option is useful for testing/debugging the code.
#
# Aim:
#   Convert an ahelp XML file (or more than one) to HTML/PDF format.
#
#   If no files are given then process all *xml files in the doc/xml/ and
#   contrib/doc/xml/ sub-directories of the ahelpfiles directory
#   given in the config file.
#   This *MAY* change.
#
#   Files are only processed if the XML file is newer than the HTML
#   file, or the index file is newer than the HTML file (ie the
#   seealso info may have been updated)
#
# Creates:
#   Files in the storage location given in the config file
#
# Requires:
#   in styledir
#     ahelp.xsl
#     ahelp_common.xsl
#
# Author:
#  Doug Burke (dburke@cfa.harvard.edu)
#
# History:
#  21 Jan 04 DJB Re-worked ahelp2html.pl into separate parts
#  05 May 04 DJB changed so that - if no XML files are given - it uses
#                the contents of the ahelpfiles directory
#  11 May 04 DJB we now create the soft and hardcopy files separately
#                support for media=print css file
#  22 Aug 06 ECG make headtitlepostfix and texttitlepostfix available
#
# To Do:
#  - allow it to work for type=dist (currently it requires the
#    locations of things - such as htmldoc and the searchssi - that
#    are not needed for the distribution).
#
# Future?:
#  -
#

use strict;
$|++;

use Carp;
use Getopt::Long;
use Cwd;
use IO::File;

use FindBin;

use lib $FindBin::Bin;
use CIAODOC qw( :util :xslt :cfg );

## Subroutines (see end of file)
#

sub read_ahelpindex ($);

## set up variables that are also used in CIAODOC
use vars qw( $configfile $verbose $group $ldpath $xsltproc $htmllib $htmldoc $site );
$configfile = "$FindBin::Bin/config.dat";
$verbose = 0;
$group = "";
$ldpath = "";
$xsltproc = "";
$htmllib = "";
$htmldoc = "";
$site = "";

## Variables
#

my $progname = (split( m{/}, $0 ))[-1];
my $usage = <<"EOD";
Usage:
  $progname --config=name --type=test|live|dist|trial --verbose [file(s)]

The default is --type=test, which publishes to the test web site.
The live option publishes to the live (ie cxc.harvard.edu) site.
The dist option is for poeple building the CIAO distribution.
Don't use the trial option unless you know what it does.

The --config option gives the path to the configuration file; this
defaults to config.dat in the same directory as the script.

The --verbose option is useful for testing/debugging the code.

EOD

## Code
#

# this will be mangled later
my $dname = cwd();

# make sure you are in an ahelp directory
my @dirs = split /\//, $dname;
unless ($dirs[-1] =~ "ahelp") {
    die "This script should be run from the 'ahelp' subdirectory\n";
  }


# handle options
my $type = "test";
die $usage unless
  GetOptions
  'config=s' => \$configfile,
  'type=s'   => \$type,
  'verbose!' => \$verbose;

# check the options
my $config = parse_config( $configfile );
dbg "Parsed the config file";

# Get the names of executable/library locations
#
my $listseealso;
( $ldpath, $xsltproc, $listseealso, $htmldoc, $htmllib ) =
  get_config_main( $config, qw( ldpath xsltproc listseealso htmldoc htmllib ) );

check_paths $ldpath, $htmllib;
check_executables $xsltproc, $htmldoc;
dbg "Found executable/library paths";

# most of the config stuff is parsed below, but we need these two here
my $site_config;
( $site, $site_config ) = find_site $config, $dname;
$config = undef; # DBG: just make sure no one is trying to access it
dbg "Site = $site";

check_type_known $site_config, $type;

# Handle the remaining config values
#
# shouldn't have so many global variables...
# - the depth returned by check_location is
#   a dummy variable which we manipulate (so
#   perl doesn't complain) and then don't do anything with
#   [depth information is stored in the 'database' files]
#
$group = get_group $site_config;
my ( $version, $version_config, $dhead, $_depth ) = check_location $site_config, $dname;
$_depth = undef;

# we actually want the CIAO version number (e.g. "3.0.2" rather than
# the version id used in the config file - ie "ciao3"), so we 'override'
# the $version variable
#
$version = get_config_version $version_config, "version_string";

my $storage     = get_config_type $version_config, "storage", $type;
my $ahelpfiles  = get_config_type $version_config, "ahelpfiles", $type;

my $outdir      = get_config_type $version_config, "outdir", $type;
my $outurl      = get_config_type $version_config, "outurl", $type;
my $stylesheets = get_config_type $version_config, "stylesheets", $type;

$storage .= "ahelp/";
my $ahelpindex_xml  = "${storage}ahelpindex.xml";
my $ahelpindex_dat  = "${storage}ahelpindex.dat";

# check we can find the needed stylesheets
#
foreach my $name ( qw( ahelp ahelp_common ) ) {
    my $x = "${stylesheets}$name.xsl";
    die "Error: unable to find $x\n"
      unless -e $x;
}

foreach my $name ( $ahelpindex_xml, $ahelpindex_dat ) {
    die "Error: unable to find $name\n"
      unless -e $name;
}

# now we can check on which files to process
# - not 100% sure on what 'no arguments' means
#   For now go with it implying the contents of
#     doc/xml/ and contrib/doc/xml/ of the
#   ahelpfiles directory (from the config file).
#   [this way it matches mk_ahelp_setup.sl]
#
# We want the names without the .xml suffix
# AND we exclude any names inclding 'onapplication' - even if
# the user specified them
#
my @names;
if ( $#ARGV == -1 ) {

    # check there's at least a doc/xml directory in ahelpfiles
    die "Error: ahelpfiles directory ($ahelpfiles) does not contain a doc/xml/ sub-directory\n"
      unless -d "$ahelpfiles/doc/xml";

    @names = ();
    foreach my $path ( map { "${ahelpfiles}$_"; } qw( doc/xml/ contrib/doc/xml/ ) ) {
	dbg( "Searching for XML files in $path" );
	@names = ( @names, glob("${path}*.xml") ); # $path ends in a /
    }

} else {
    @names = @ARGV;
}
die "Error: no ahelp files have been specified or found in the directory\n"
  if $#names == -1;
@names = map { s/\.xml$//; $_; }
  grep { !/onapplication/ } @names;

#########################

my $uname = `whoami`;
chomp $uname;

dbg "*** CONFIG DATA (start) ***";
dbg "  type=$type";
dbg "  dname=$dname";
dbg "  dhead=$dhead";
##dbg "  depth=$depth";
dbg "  outdir=$outdir";
dbg "  stylesheets=$stylesheets";
dbg "  ahelpindex_xml=$ahelpindex_xml";
dbg "  ahelpindex_dat=$ahelpindex_dat";
dbg "  version=$version";
dbg " ---";
dbg "  xsltproc=$xsltproc";
dbg "  ldpath=$ldpath";
dbg "  htmldoc=$htmldoc";
dbg "  htmllib=$htmllib";
dbg "*** CONFIG DATA (end) ***";

# start work
#

# parse the ahelp index file (dat) to get the mapping from xml file name
# to HTML head and then check we have a mapping for all the files
#
# not 100% convinced about the directory munging (necessary since v1.3
# when we changed to picking up files from the ahelpfiles directory
# rather than the local directory)
#
my $html_mapping = read_ahelpindex $ahelpindex_dat;
foreach my $fullname ( @names ) {
    my $name = (split("/",$fullname))[-1];
    die <<"EOE" unless exists $$html_mapping{$name};
Error: $fullname.xml is not found in the ahelp index
       you will probably need to re-run
         mk_ahelp_setup.pl
         mk_ahelp_indexes.pl

EOE
}

# create the output directories if we have to
$outdir .= $dhead;
mymkdir $outdir;

my @extra = (
	  type     => $type eq "trial" ? "test" : $type,
	  outdir   => $outdir,
	  site     => $site,
	  version  => $version,
);

# handle values only required for type != dist
#
if ( $type ne "dist" ) {

    my $cssfile      = get_config_type $version_config, "css", $type;
    my $cssprintfile = get_config_type $version_config, "cssprint", $type;
    my $searchssi    = get_config_type $version_config, "searchssi", $type;
    my $urlbase      = get_config_type $version_config, "outurl", $type;

    # optional "postfix" text for page headers
    my $headtitlepostfix = "";
    my $texttitlepostfix = "";
    $headtitlepostfix = get_config_version( $version_config, "headtitlepostfix" )
	if check_config_exists( $version_config, "headtitlepostfix" );
    $texttitlepostfix = get_config_version( $version_config, "texttitlepostfix" )
	if check_config_exists( $version_config, "texttitlepostfix" );

    dbg "*** CONFIG (type != dist) ***";
    dbg "  uname=$uname";
    dbg "  urlbase=$urlbase";
    dbg "  searchssi=$searchssi";
    dbg "  cssfile=$cssfile";
    dbg "  cssprintfile=$cssprintfile";
    dbg "  searchssi=$searchssi";
    dbg "  headtitlepostfix=$headtitlepostfix";
    dbg "  texttitlepostfix=$texttitlepostfix";
    dbg "*** END CONFIG ***";

    @extra =
      (
       @extra,
       updateby     => $uname,
       cssfile      => $cssfile,
       cssprintfile => $cssprintfile,
       searchssi    => $searchssi,
       urlbase      => $urlbase,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,
      );
}

# what 'hardcopy' values do we loop through?
#
my @hardcopy = ( 0 );
push @hardcopy, 1 unless $type eq "dist";

# Loop through each file
#
foreach my $in ( @names ) {

    dbg "Processing: $in";
    my $name = (split("/",$in))[-1];

    # To avoid forcing the use of XML::LibXML for type=dist, we
    # have a simple ascii file that maps between XML and HTML names.
    # We have already used it to check that all the files are
    # known about.
    #
    # we need to convert depth from a number to a string
    # - e.g. from 2 to '../' - here
    #
    my ( $depth, $outname, $seealso_name ) = @{ $$html_mapping{$name} };

    # we 'hardcode' the output of the transformation
    # and ensure that any old files have been deleted
    #
    my @names = $type eq "dist" ?
      ( $outname ) : ( $outname, "${outname}.hard" );

    my @pages = map { "${outdir}${_}.html"; } @names;
    foreach my $page ( @pages ) {
	dbg " ---> deleting (if it exists) $page";
	myrm( $page );
    }

    # loop through the hardcopy flags
    #
    foreach my $hflag ( @hardcopy ) {

	# set up the parameters for this file
	#
	my $params = make_params(
				 outname     => $outname,
				 seealsofile => "${storage}$seealso_name",
				 depth       => '../' x ($depth-1),
				 hardcopy    => $hflag,
				 @extra
				);

	# run the processor
	#
	my $flag = translate_file( $params,
				"${stylesheets}ahelp.xsl",
				"${in}.xml" );

	# we skip further processing on error
	# - we might want to skip this file completely (ie if fail on hardcopy=0
        #   then do not bother with hardcopy=1). This is more complicated to code
        #   and I think we can live with repeated failures as they should not
        #   happen in production use
        #
	unless ( defined $flag ) {
	    print "-> problem generating HTML for $in with hardcopy=$hflag\n";
	    next;
	}

    } # foreach: @hardcopy

    # success or failure?
    foreach my $page ( @pages ) {
	#die "Error: transformation did not create $page\n"
	#  unless -e $page;
	unless ( -e $page ) {
	    print "Error: transformation did not create $page\n";
	    next;
	}
	mysetmods( $page );
	dbg("Created: $page");
    }

    # create the hardcopy pages [if required]
    create_hardcopy( $outdir, $outname ) if $type ne "dist";

} # foreach: $in

print "\nTry page(s) at: ${outurl}$dhead\n";

# End of script
#
exit;

## Subroutines
#

# Usage:
#   my $map = read_ahelpindex $ahelpindex_dat;
#
# Aim:
#   given the name of the file containing the mapping
#   between XML file name and the HTML name for the output.
#
#   The return value is a hash reference:
#     keys   = xml file name (with no .xml suffix)
#     values = [
#                 depth value,
#                 head (ie no .html suffix) of HTML file name,
#                 seealso file name (with .xml but without path)
#              ]
#
sub read_ahelpindex ($) {
    my $infile = shift;
    my $fh = IO::File->new( "< $infile" )
      or die "ERROR: unable to open $infile for reading\n";

    my %map;
    while ( <$fh> ) {
	next if /^(#|\s*$)/;
	chomp;
	my ( $xml, $depth, $html, $seealso ) = split;
	$xml =~ s/\.xml$//;
	die "Error: multiple occurrnces of $xml found in $infile\n"
	  if exists $map{$xml};
	$map{$xml} = [ $depth, $html, $seealso ];
    }

    $fh->close;
    return \%map;

} # sub: read_ahelpindex
