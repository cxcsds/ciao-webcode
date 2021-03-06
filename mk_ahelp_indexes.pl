#!/usr/bin/env perl -w
#
# Usage:
#   mk_ahelp_indexes.pl
#     --config=name
#     --type=test|live|trial
#     --localxslt
#     --verbose
#
#   The default is --type=test, which sets up for test web site.
#   The live option sets things up for the live (ie cxc.harvard.edu) site.
#   Don't use the trial option unless you know what it does.
#
#   The --config option gives the path to the configuration file; this
#   defaults to config.dat in the same directory as the script.
#
#   The --localxslt option is used for testing; it overrides the
#   %stylesheets setting in the config file, using the location
#   of this script instead.
#
#   The --verbose option is useful for testing/debugging the code.
#
# Aim:
#   Create the alphabetical and contextual list of ahelp files
#   as index pages.
#
# Creates:
#   Files in the storage location given in the config file
#   (Actually, we don't at present).
#
# Requires:
#   in styledir
#     ahelp_index.xsl
#     ahelp_common.xsl
#
# Author:
#  Doug Burke (dburke@cfa.harvard.edu)
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
use CIAODOC qw( :util :xslt :cfg :deps );

## Subroutines (see end of file)
#

## set up variables that are also used in CIAODOC
use vars qw( $configfile $verbose $group $site );
$configfile = "$FindBin::Bin/config.dat";
$verbose = 0;
$group = "";
$site = "";

## Variables
#

my $progname = (split( m{/}, $0 ))[-1];
my $usage = <<"EOD";
Usage:
  $progname --config=name --type=test|live|trial --localxslt --verbose

The default is --type=test, which publishes to the test web site.
The live option publishes to the live (ie cxc.harvard.edu) site.
Do not use the trial option unless you know what it does.

The --config option gives the path to the configuration file; this
defaults to config.dat in the same directory as the script.

The --localxslt option is used for testing; it overrides the
\%stylesheets setting in the config file, using the location
of this script instead.

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
my $localxslt = 0;
die $usage unless
  GetOptions
  'config=s'   => \$configfile,
  'type=s'     => \$type,
  'localxslt!' => \$localxslt,
  'verbose!'   => \$verbose;

# what OS are we running?
#
my $ostype = get_ostype;

# check the options
my $config = parse_config( $configfile );
dbg "Parsed the config file";

# most of the config stuff is parsed below, but we need these two here
my $site_config;
( $site, $site_config ) = find_site $config, $dname;
$config = undef; # DBG: just make sure no one is trying to access it
dbg "Site = $site";

check_type_known $site_config, $type;
dbg "Type = $type";

dbg "OS = $ostype";

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

my $outdir      = get_config_type $version_config, "outdir", $type;
my $outurl      = get_config_type $version_config, "outurl", $type;
my $stylesheets = get_config_type $version_config, "stylesheets", $type;

if ($localxslt) {
    dbg "Overriding stylesheets setting: from $stylesheets to $FindBin::Bin/";
    $stylesheets = "$FindBin::Bin/";
}

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

# start work
#
# create the output directories if we have to
$outdir .= $dhead;
mymkdir $outdir;

# create the index pages
#

my @extra;

my $navbar       = get_config_version $version_config, "ahelpindexnavbar";

my $cssfile      = get_config_type $version_config, "css", $type;
my $cssprintfile = get_config_type $version_config, "cssprint", $type;
my $favicon      = get_config_type $version_config, "favicon", $type;
my $searchssi    = get_config_type $version_config, "searchssi", $type;
my $googlessi    = get_config_version( $version_config, "googlessi" );
my $urlbase      = get_config_type $version_config, "outurl", $type;

# site banner is optional
my $sitebanner = "";
$sitebanner = get_config_type( $version_config, "sitebanner", $type )
  if check_config_exists( $version_config, "sitebanner" );

# logo image/text/url is also optional
my $logoimage = "";
$logoimage = get_config_version( $version_config, "logoimage" )
  if check_config_exists( $version_config, "logoimage" );
my $logotext = "";
$logotext = get_config_version( $version_config, "logotext" )
  if check_config_exists( $version_config, "logotext" );
my $logourl = "";
$logourl = get_config_version( $version_config, "logourl" )
  if check_config_exists( $version_config, "logourl" );

# optional "postfix" text for page headers
my $headtitlepostfix = "";
my $texttitlepostfix = "";
$headtitlepostfix = get_config_version( $version_config, "headtitlepostfix" )
  if check_config_exists( $version_config, "headtitlepostfix" );
$texttitlepostfix = get_config_version( $version_config, "texttitlepostfix" )
  if check_config_exists( $version_config, "texttitlepostfix" );

# only needed for a warning in the output HTML file (to point to
# the work directory).
#
my $sourcedir = cwd() . "/";

dbg "  uname=$uname";
dbg "  urlbase=$urlbase";
dbg "  searchssi=$searchssi";
dbg "  sitebanner=$sitebanner";
dbg "  cssfile=$cssfile";
dbg "  cssprintfile=$cssprintfile";
dbg "  favicon=$favicon";
dbg "  googlessi=$googlessi";
dbg "  navbarname=$navbar";
dbg "  logoimage=$logoimage";
dbg "  logotext=$logotext";
dbg "  logourl=$logourl";
dbg "  headtitlepostfix=$headtitlepostfix";
dbg "  texttitlepostfix=$texttitlepostfix";
dbg "  sourcedir=$sourcedir";
dbg "*** CONFIG DATA (end) ***";

@extra =
  (
   urlbase      => $urlbase,
   updateby     => $uname,
   cssfile      => $cssfile,
   cssprintfile => $cssprintfile,
   favicon      => $favicon,
   searchssi    => $searchssi,
   sitebanner   => $sitebanner,
   googlessi    => $googlessi,
   navbarname   => $navbar,
   headtitlepostfix => $headtitlepostfix,
   texttitlepostfix => $texttitlepostfix,
   sourcedir => $sourcedir,
  );

# note: tweek logoimage location by depth
# (difference to how the main navbars are created)
#
push @extra, ( logoimage => '../' x ($depth-1) . $logoimage )
  if $logoimage ne "";
push @extra, ( logotext  => $logotext )
  if $logotext ne "";
push @extra, ( logourl   => $logourl )
  if $logourl ne "";

# we 'hardcode' the output of the transformation
# and ensure that any old files have been deleted
#

# TODO: take out @h version

my @s;
my @h;

@s = qw( navbar_ahelp_index.incl index_alphabet.html index_context.html );
@h = qw( index_alphabet index_context );


my @soft = map { "${outdir}${_}"; } @s;

foreach my $page ( @soft ) {
    dbg " ---> deleting (if it exists) $page";
    myrm( $page );
}

my %paramlist = (
		 type     => $type eq "trial" ? "test" : $type,
		 outdir   => $outdir,
		 site     => $site,
		 version  => $version,
		 @extra
		);

clear_dependencies;

translate_file "${stylesheets}ahelp_index.xsl", $ahelpindex, \%paramlist;

dump_dependencies;

# success or failure?
foreach my $page ( @soft ) {
    #die "Error: transformation did not create $page\n"
    #  unless -e $page;
    unless ( -e $page ) {
	print "Error: transformation did not create $page\n";
	next;
    }
    mysetmods( $page );
    dbg("Created: $page");
}

print "Try page(s) at: ${outurl}$dhead\n";

# End of script
#
exit;

## Subroutines
#
