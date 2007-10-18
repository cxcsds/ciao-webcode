#!/data/da/Docs/local/perl/bin/perl -w
#
# Usage:
#   mk_ahelp_pages.pl [name1 ... namen]
#     --config=name
#     --type=test|live|trial
#     --verbose
#
#   The default is --type=test, which sets up for test web site.
#   The live option sets things up for the live (ie cxc.harvard.edu) site.
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
#  12 Oct 07 DJB Removed ldpath and htmllib vars as no longer used
#                and updates to better support CIAO 4 changes
#  15 Oct 07 DJB Executables are now OS specific
#  16 Oct 07 DJB Handle site-specific pages
#                Removed support for type=dist
#  17 Oct 07 DJB Removed support for xsltproc tool
#
# To Do:
#  - 
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
sub find_ahelpfiles ($$);

## set up variables that are also used in CIAODOC
use vars qw( $configfile $verbose $group $htmldoc $site );
$configfile = "$FindBin::Bin/config.dat";
$verbose = 0;
$group = "";
$htmldoc = "";
$site = "";

## Variables
#

my $progname = (split( m{/}, $0 ))[-1];
my $usage = <<"EOD";
Usage:
  $progname --config=name --type=test|live|trial --verbose [file(s)]

The default is --type=test, which publishes to the test web site.
The live option publishes to the live (ie cxc.harvard.edu) site.
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

# what OS are we running?
#
my $ostype = get_ostype;

# check the options
my $config = parse_config( $configfile );
dbg "Parsed the config file";

# Get the names of executable/library locations
#
$htmldoc = get_config_main_type( $config, "htmldoc", $ostype );

check_executable_runs "htmldoc", $htmldoc, "--version";
dbg "Found executable/library paths";

# most of the config stuff is parsed below, but we need these two here
my $site_config;
( $site, $site_config ) = find_site $config, $dname;
$config = undef; # DBG: just make sure no one is trying to access it
dbg "Site = $site";

check_type_known $site_config, $type;
check_ahelp_site_valid $site;

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

my $ahelpfiles  = get_config_type $version_config, "ahelpfiles", $type;

my $outdir      = get_config_type $version_config, "outdir", $type;
my $outurl      = get_config_type $version_config, "outurl", $type;
my $stylesheets = get_config_type $version_config, "stylesheets", $type;

#$storage .= "ahelp/";
#my $ahelpindex_xml  = "${storage}ahelpindex.xml";
#my $ahelpindex_dat  = "${storage}ahelpindex.dat";
my $ahelpstore     = get_config_type $version_config, "ahelpindexdir", $type;
my $ahelpindex_xml = "${ahelpstore}ahelpindex.xml";
my $ahelpindex_dat = "${ahelpstore}ahelpindex.dat";

foreach my $f ( $ahelpindex_xml, $ahelpindex_dat ) {
  die "ERROR: Unable to find ahelp index - has mk_ahelp_setup.pl been run?\n\n  missing=$f\n"
    unless -e $f;
}

# check we can find the needed stylesheets
#
foreach my $name ( qw( ahelp ahelp_common ) ) {
    my $x = "${stylesheets}$name.xsl";
    die "Error: unable to find $x\n"
      unless -e $x;
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
# As of CIAO 4 this has got more complicated since we
# store all the XML files within one directory but we publish
# to separate sites. So we need to:
#   user gives files to process => check files belong to this site
#   no files given              => select the correct files
#
my @allowed_names = find_ahelpfiles $site, $ahelpindex_xml;
my @names;
if ( $#ARGV == -1 ) {

  # Use the database to select the files to process
  #
  @names = @allowed_names;

} else {
  @names = @ARGV;

  # We only check on the file name, not the path, for these files.
  # This could lead to problems but let's not bother with that for
  # now.
  #
  my %check_names = map { my $f = (split "/",$_)[-1]; ($f,1); } @allowed_names;
  foreach my $name (@names) {
    my $t = (split "/", $name)[-1];
    die "Error: file not known for site=$site: $t\n"
      unless exists $check_names{$t};
  }
}
@names = map { s/\.xml$//; $_; }
  grep { !/onapplication/ } @names;
die "Error: no ahelp files have been specified or found in the directory\n"
  if $#names == -1;
dbg "Found " . (1+$#names) . " ahelp files";

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
dbg "  htmldoc=$htmldoc";

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

dbg "  uname=$uname";
dbg "  urlbase=$urlbase";
dbg "  searchssi=$searchssi";
dbg "  cssfile=$cssfile";
dbg "  cssprintfile=$cssprintfile";
dbg "  searchssi=$searchssi";
dbg "  headtitlepostfix=$headtitlepostfix";
dbg "  texttitlepostfix=$texttitlepostfix";
dbg "*** CONFIG DATA (end) ***";

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

my %paramlist = @extra;

# what 'hardcopy' values do we loop through?
#
my @hardcopy = ( 0, 1 );

# Loop through each file
#
foreach my $in ( @names ) {

    dbg "Processing: $in";
    my $name = (split("/",$in))[-1];

    # We need to convert depth from a number to a string
    # - e.g. from 2 to '../' - here
    #
    my ( $depth, $outname, $seealso_name ) = @{ $$html_mapping{$name} };

    # we 'hardcode' the output of the transformation
    # and ensure that any old files have been deleted
    #
    my @names = ( $outname, "${outname}.hard" );

    my @pages = map { "${outdir}${_}.html"; } @names;
    foreach my $page ( @pages ) {
	dbg " ---> deleting (if it exists) $page";
	myrm( $page );
    }

    $paramlist{outname} = $outname;
    $paramlist{seealsofile} = "${ahelpstore}$seealso_name";
    $paramlist{depth} = '../' x ($depth-1);

    # loop through the hardcopy flags
    #
    foreach my $hflag ( @hardcopy ) {

      $paramlist{hardcopy} = $hflag;
      my $flag = translate_file "${stylesheets}ahelp.xsl",
	"${in}.xml", \%paramlist;

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

    # create the hardcopy pages
    create_hardcopy( $outdir, $outname );

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
# Note:
#   Now that we process the XML index proper, is this file still
#   useful?
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

# Usage:
#   @filelist = find_ahelpfiles $site, $ahelpindex_xml;
#
# Returns a reference to a list of all the ahelp files to process
# for the given site.
#
sub find_ahelpfiles ($$) {
  my $site    = shift;
  my $xmlfile = shift;

  my $dom = read_xml_file $xmlfile;
  my $root = $dom->documentElement();
  my @out;
  dbg "Processing ahelp index to find pages in site=$site";
  foreach my $node ($root->findnodes("/ahelpindex/ahelplist/ahelp[site='$site']")) {
    push @out, $node->findvalue("xmlname");
  }
  return @out;
} # sub: find_ahelpfiles
