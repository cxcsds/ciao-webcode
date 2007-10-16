#!/data/da/Docs/local/perl/bin/perl -w
#
# Usage:
#   mk_ahelp_indexes.pl
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
#   Create the alphabetical and contextual list of ahelp files
#   as index pages.
#
# Creates:
#   Files in the storage location given in the config file
#
# Requires:
#   in styledir
#     ahelp_index.xsl
#     ahelp_common.xsl
#
# Author:
#  Doug Burke (dburke@cfa.harvard.edu)
#
# History:
#  03 Oct 03 DJB Re-worked ahelp2html.pl into separate parts
#  14 May 04 DJB we now create the soft and hardcopy files separately
#                support for media=print css file
#  22 Aug 06 ECG make headtitlepostfix and texttitlepostfix available
#  12 Oct 07 DJB Removed ldpath and htmllib vars as no longer used
#                and updates to better support CIAO 4 changes
#  15 Oct 07 DJB Executables are now OS specific
#                Handle site-specific index files
#
# To Do:
#  - allow it to work for type=dist (currently it requires the
#    locations of things - such as htmldoc and the searchssi - that
#    are not needed for the distribution).
#    Hmmm, as we no longer need type=dist this comment is not as
#    useful, although it may be useful to run on htmldoc-less
#    systems for testing/development purposes.
#
# Future?:
#  -
#

#XXX update to be site specific XXX

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

## set up variables that are also used in CIAODOC
use vars qw( $configfile $verbose $group $xsltproc $htmldoc $site );
$configfile = "$FindBin::Bin/config.dat";
$verbose = 0;
$group = "";
$xsltproc = "";
$htmldoc = "";
$site = "";

## Variables
#

my $progname = (split( m{/}, $0 ))[-1];
my $usage = <<"EOD";
Usage:
  $progname --config=name --type=test|live|dist|trial --verbose

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

# what OS are we running?
#
my $ostype = get_ostype;

# check the options
my $config = parse_config( $configfile );
dbg "Parsed the config file";

# Get the names of executable/library locations
#
( $xsltproc, $htmldoc ) = 
  get_config_main_type( $config, qw( xsltproc htmldoc ), $ostype );

check_executable_runs "xsltproc", $xsltproc, "--version";
check_executable_runs "htmldoc", $htmldoc, "--version";
dbg "Found executable/library paths";

# most of the config stuff is parsed below, but we need these two here
my $site_config;
( $site, $site_config ) = find_site $config, $dname;
$config = undef; # DBG: just make sure no one is trying to access it
dbg "Site = $site";

check_type_known $site_config, $type;
check_ahelp_site_valid $site;

# now we can check the usage
#
die $usage unless $#ARGV == -1;

# Handle the remaining config values
#
# shouldn't have so many global variables...
#
$group = get_group $site_config;
my ( $version, $version_config, $dhead, $depth ) = check_location $site_config, $dname;

# we actually want the CIAO version number (e.g. "3.0.2" rather than
# the version id used in the config file - ie "ciao3"), so we 'override'
# the $version variable
#
$version = get_config_version $version_config, "version_string";

#my $storage     = get_config_type $version_config, "storage", $type;

my $outdir      = get_config_type $version_config, "outdir", $type;
my $outurl      = get_config_type $version_config, "outurl", $type;
my $stylesheets = get_config_type $version_config, "stylesheets", $type;

# We did have the following, but that did not work, and I do not understand
# why I did not bother with the get_config_type call anyway...
#
# my $ahelpindex  = "${storage}ahelp/ahelpindex.xml";
my $ahelpindex  = get_config_type $version_config, "ahelpindexdir", $type;
$ahelpindex .= "ahelpindex.xml";

die "ERROR: Unable to find ahelp index - has mk_ahelp_setup.pl been run?\n\n  ahelpindexdir=$ahelpindex\n"
  unless -e $ahelpindex;

# check we can find the needed stylesheets
#
foreach my $name ( qw( ahelp_index ahelp_common ) ) {
    my $x = "${stylesheets}$name.xsl";
    die "Error: unable to find $x\n"
      unless -e $x;
}

my $uname = `whoami`;
chomp $uname;

dbg "*** CONFIG DATA (start) ***";
dbg "  type=$type";
dbg "  site=$site";
dbg "  dname=$dname";
dbg "  dhead=$dhead";
dbg "  depth=$depth";
dbg "  outdir=$outdir";
dbg "  stylesheets=$stylesheets";
dbg "  ahelpindex=$ahelpindex";
dbg " ---";
dbg "  xsltproc=$xsltproc";
dbg "  htmldoc=$htmldoc";
dbg "*** CONFIG DATA (end) ***";

# start work
#
# create the output directories if we have to
$outdir .= $dhead;
mymkdir $outdir;

# create the index pages
#

# handle values only required for type != dist
my @extra;
if ( $type ne "dist" ) {

    my $navbar       = get_config_version $version_config, "ahelpindexnavbar";

    my $cssfile      = get_config_type $version_config, "css", $type;
    my $cssprintfile = get_config_type $version_config, "cssprint", $type;
    my $searchssi    = get_config_type $version_config, "searchssi", $type;
    my $urlbase      = get_config_type $version_config, "outurl", $type;
    my $newsfile     = get_config_type $version_config, "newsfile", $type;
    my $newsfileurl  = get_config_type $version_config, "newsurl", $type;
    my $watchouturl  = get_config_type $version_config, "watchouturl", $type;

    # logo image/text is also optional
    my $logoimage = "";
    $logoimage = get_config_version( $version_config, "logoimage" )
      if check_config_exists( $version_config, "logoimage" );
    my $logotext = "";
    $logotext = get_config_version( $version_config, "logotext" )
      if check_config_exists( $version_config, "logotext" );

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
    dbg "  navbarname=$navbar";
    dbg "  newsfile=$newsfile";
    dbg "  newsfileurl=$newsfileurl";
    dbg "  watchouturl=$watchouturl";
    dbg "  logoimage=$logoimage";
    dbg "  logotext=$logotext";
    dbg "  headtitlepostfix=$headtitlepostfix";
    dbg "  texttitlepostfix=$texttitlepostfix";
    dbg "*** END ***";

    @extra =
      (
       urlbase      => $urlbase,
       updateby     => $uname,
       cssfile      => $cssfile,
       cssprintfile => $cssprintfile,
       newsfile     => $newsfile,
       newsfileurl  => $newsfileurl,
       watchouturl  => $watchouturl,
       searchssi    => $searchssi,
       navbarname   => $navbar,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,
      );

    # note: tweek logoimage location by depth
    # (difference to how the main navbars are created)
    #
    push @extra, ( logoimage => '../' x ($depth-1) . $logoimage )
      if $logoimage ne "";
    push @extra, ( logotext  => $logotext )
      if $logotext ne "";

}

# what 'hardcopy' values do we loop through?
#
my @hardcopy = ( 0 );
push @hardcopy, 1 unless $type eq "dist";

# we 'hardcode' the output of the transformation
# and ensure that any old files have been deleted
#
my @soft;
my @hard;
if ( $type eq "dist" ) {
    @soft = map { "${outdir}${_}.html"; } qw( index_alphabet index_context );

} else {
    my @s = qw( navbar_ahelp_index.incl index_alphabet.html index_context.html );
    my @h = qw( index_alphabet index_context );

    @soft = map { "${outdir}${_}"; } @s;
    @hard = map { "${outdir}${_}.hard.html"; } @h;

}
foreach my $page ( @soft, @hard ) {
    dbg " ---> deleting (if it exists) $page";
    myrm( $page );
}

foreach my $hflag ( @hardcopy ) {
    my $params =
      make_params(
		  type     => $type eq "trial" ? "test" : $type,
		  outdir   => $outdir,
		  site     => $site,
		  version  => $version,
		  hardcopy => $hflag,
		  @extra
		 );

    # run the processor, pipe the screen output to a file
    translate_file( $params, "${stylesheets}ahelp_index.xsl", $ahelpindex );
}

# success or failure?
foreach my $page ( @soft, @hard ) {
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
foreach my $page ( @hard ) {
    $page =~ s/^.*\/([^\/].+)\.hard\.html$/$1/;
    create_hardcopy( $outdir, $page );
}

print "Try page(s) at: ${outurl}$dhead\n";

# End of script
#
exit;

## Subroutines
#
