#!/usr/bin/env perl -w
#
# Usage:
#   check_status.pl --type=test|live|trial
#     Default for type is test
#
#     --config=config-file
#     The name (including path) of the configuration file.
#     Defaults to <path to this script>/config.dat
#
#     --verbose
#     Turn on screen output that's only useful for testing/debugging
#
# Aim:
#   Report those files that need to be re-published because of
#   changes in their dependencies.
#
#   Looks for all files in the current site (does not restrict
#   to the current directory, but may be changed to do so).
#
# Creates:
#   A list of file names, to the screen.
#
# Requires:
#
# Author:
#  Doug Burke (dburke@cfa.harvard.edu)
#
use strict;
$|++;

use Getopt::Long;
use FindBin;

use Cwd;
use File::Find;

use lib $FindBin::Bin;
use CIAODOC qw( :util :cfg :deps );

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

# We need a default prefix in order to find the default
# config file, even if we want to be able to over-ride
# everything from the command-line
#
my $prefix   = "/data/da/Docs"; # should NOT end in a /

## Code
#
my $progname = (split( m{/}, $0 ))[-1];
my $usage = <<"EOD";
Usage:
  $progname --config=name --type=test|live|trial

The default is --type=test.

The --config option gives the path to the configuration file; this
defaults to config.dat in the same directory as the script.

The --verbose option is useful for testing/debugging the code.

EOD

# this will be mangled later
my $dname = cwd();

# handle options
my $type = "test";
die $usage unless
  GetOptions
  'config=s' => \$configfile,
  'type=s'   => \$type,
  'verbose!' => \$verbose;

# check the options
die "Error: the config option can not be blank\n"
  if $configfile eq "";
my $config = parse_config( $configfile );

# most of the config stuff is parsed below, but we need these two here
my $site_config;
( $site, $site_config ) = find_site $config, $dname;
$config = undef; # DBG: just make sure no one is trying to access it
dbg "Site = $site";

check_type_known $site_config, $type;
dbg "Type = $type";

# check usage
#
die $usage unless $#ARGV == -1;

# Handle the remaining config values
#
# shouldn't have so many global variables...
#
$group = get_group $site_config;
my ( $version, $version_config, $dhead, $depth ) = check_location $site_config, $dname;

# get the site version
my $site_version = "";

if ( ! ($site =~ /caldb/)) {
    if (check_config_exists( $version_config, "number" )){
	$site_version = get_config_version( $version_config, "number" );
    } else {
	die "Error: version $version in the config file ($configfile) does not contain the number parameter\n";
    }
} 

my $storageloc = "";
$storageloc = get_config_type( $version_config, "storageloc", $type )
  if check_config_exists( $version_config, "storageloc" );

die "Error: no dependency information possible for site=$site/type=$type as storageloc is empty!\n"
  if $storageloc eq "";

dbg "Using storage area: $storageloc";

die "Error: unable to find storageloc=$storageloc\n"
  unless -e $storageloc;

my $storagedir = get_storage_location $storageloc, $site;

# Get the list of revdep files to query
my @revdeps;

sub wanted {
  push @revdeps, $File::Find::name
    if /\.revdep$/ && -e $_;
}

File::Find::find(\&wanted, $storagedir);
dbg "Found " . (1 + $#revdeps) . " matching files";

my %seen = ();

foreach my $revdep (@revdeps) {
  dbg "Processing: $revdep";
  my $files = identify_files_to_republish $revdep;
  dbg " -> " . (1 + $#$files) . " matches";
  foreach my $file (@$files) {
    # TODO: convert file into a relative path
    print "$file\n"
      unless exists $seen{$file};
    $seen{$file} = 1;
  }
}

# end
