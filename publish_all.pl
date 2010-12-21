#!/data/da/Docs/local/perl/bin/perl -w
#
# Usage:
#  publish_all.pl
#     --config=<location of config file>
#     --type=live|test
#     --force
#     --excludedir=<dir1 to ignore>,...,<dirN to ignore> - ie comma-separated list
#     --xmlonly
#     --yes
#
# Aim:
#  This script provides a way to publish all the files in the current
#  directory and in any subdirectories. It essentially just finds all
#  the files and then runs the publish script on it. It finds all the
#  files it thinks are valid - both XML and XML - and then asks you
#  whether it should process them all.
#
# Options:
#    --config - used to find perl executable and passed through to publish.pl
#    --type, and --force are passed through to the publish script
#      but the config variable is also used to get the perl/os value
#    --yes means that the program will not ask you whether to process
#          all the files, it will just go ahead and do it
#          useful for background jobs
#    --xmlonly means that only files matching *xml are published
#    --excludedir is a way of specifying a set of directories that should
#           be excluded from the search
#  
# Notes:
#  - files that are checked out for editing are skipped;
#    not 100% convinced got it right for RCS files
#  - the thread index is published last so that it can pick up all the
#    details of the threads; it probably also needs publishing before
#    the threads too so that the threads can find out what groups
#    they are in
#  - the script currently can not be run in all directories; this
#    restriction should be removed
#  - there's a reasonably complicated set of rules for working out
#    which files are to be skipped - it's a set of heuristic rules
#    (ie we add another case to the list when we find a file to ignore)
#    rather than anything clever.
#
# Changes:
#    2007 Oct 24 DJB
#      Fix up RCS check (only run rlog if the RCS file exists) and calling
#      of the perl executable
#    2007 Oct 22 DJB
#      We now run the publish.pl that is in the same directory as this
#      script, rather than hard code it to /data/da/Docs/web/, and we use
#      CIAODOC/config.dat to get the perl executable name
#      We now exclude RCS/ dirs, as we do SCCS/ dirs.
#

use strict;
$|++;

use Getopt::Long;

use Cwd;
use IO::Pipe;

use FindBin;

use lib $FindBin::Bin;
use CIAODOC qw (:util :cfg);

use vars qw( $configfile );
$configfile = "$FindBin::Bin/config.dat";

# can not end in / because of regexp check below
my @prefixes =
  (
   "/data/da/Docs/cscweb/csc1",
   "/data/da/Docs/caldbweb/caldb4",
   "/data/da/Docs/ciaoweb/ciao43",
   "/data/da/Docs/sherpaweb/ciao43",
   "/data/da/Docs/chipsweb/ciao43",

   "/Users/doug/doc/ahelp/", # Doug's testing
  );

my %_types = map { ($_,1); } qw( test live trial );

my $usage = "Usage: $0 --config=filename --type=live|test --force --xmlonly --excludedir=one,two,.. --yes\n";

## Code
#
my $type = "test";
my $force = 0;
my $xmlonly = 0;
my $excludedirs = "";
my $yes = 0;
die $usage unless
  GetOptions 'config=s' => \$configfile, 'type=s' => \$type, 'force!' => \$force,
  'excludedir=s' => \$excludedirs, 'xmlonly!' => \$xmlonly, 'yes!' => \$yes;

# Get the name of the perl executable
#
my $ostype = get_ostype;
my $config = parse_config( $configfile );
my $perlexe = get_config_main_type ($config, "perl", $ostype);
my @pexe = split / /, $perlexe;

die "Error: unknown type ($type)\n"
  unless exists $_types{$type};

die $usage unless $#ARGV == -1;

# Check we can find the publish.pl script
#
my $script = "$FindBin::Bin/publish.pl";
die "Error: unable to find executable publish.pl - expected it to be at\n\t$script\n"
  unless -e $script;

my $cwd = cwd();

my $prefix;
foreach my $p ( @prefixes ) { $prefix = $p if $cwd =~ /^$p/; }
die "Error: must be run within one of the following dir trees:\n  " .
  join (" ", @prefixes ) . "\n"
  unless defined $prefix;

my $tmp = $cwd;
$tmp =~ s/^$prefix//;

my @dirs;
@dirs = split "/", substr($tmp,1)  # remove the leading /
  if $tmp ne "";

# sort out exclude dirs
#

my %excludedirs;
if ( $excludedirs ne "" ) {

    # need at least one comma for the split
    $excludedirs .= ",null";  
    my %excludedirs = map { ($_,1); } split( /,/, $excludedirs );

}


# find all the files
# - exclude SCCS and RCS directories
#
# from 'man find'
#
#     Recursively print all file names in  the  current  directory
#     and below, but skipping SCCS directories:
#
#     example% find . -name SCCS -prune -o -print
#
#     Example 4: Printing all file names and  the  SCCS  directory
#     name
#
#     Recursively print all file names in  the  current  directory
#     and  below,  skipping  the contents of SCCS directories, but
#     printing out the SCCS directory name:
#
#     example% find . -print -name SCCS -prune
#
# - exclude threads/include/ directory
# - non thread.xml files in the threads/foo/ directories
#
# might be easier to do using perl's find module doohickey
# but let's do this for now (it's ugly but seems to work).
#
my $pipe = IO::Pipe->new();
$pipe->reader( qw( find . \( -name RCS -o -name SCCS \) -prune -o -print ) );

my %files;
my %images;
my $threadindex;
my $nrej = 0;
my $nuserrej = 0;
my $ndir = 0;
my $nfil = 0;
while ( <$pipe> ) {

    # helps checks below if we include the full path
    # (eg so that can find out if in the threads directory
    #  if run in it/sub-dir of it)
    #
    my $name = $cwd . substr($_,1);
    chomp $name;

    # is it a directory? (can't find do this)
    $ndir++, next if -d $name;

    # do we reject?
    #
    my @dirs = split "/", $name;
    my $fname = pop @dirs;
    my $dname = $dirs[-1];
    my $path  = join "/", @dirs;

    # user reject
    $nuserrej++, next if exists $excludedirs{$dname};

    # reject "backup" files
    $nrej++, next if $fname =~ /^#/ or $fname =~ /^$/ or $fname =~ /~$/;

    # reject "._" files created by mac osx
    $nrej++, next if $fname =~ /^\._/;     

    # check in the threads dir
    if ( $name =~ m{/threads/} ) {
	$nrej++, next if $dname eq "example" or $dname eq "include";

	# want to keep all the .gz contents of the data directory
	# (exclude everything else)
	# and want the index page
	$nrej++, next unless
	  ($fname eq "index.xml" and $dname eq "threads")
	    or
	  ($dname eq "data" and $fname =~ /\.gz$/)
            or
	  $fname eq "thread.xml"

	    # need to publish redirect files during s-lang removal
            or	    
	  $fname eq "index.sl.xml"
            or
	  $fname eq "index.py.xml";
    }

    # for the moment we reject the README in the workshop talk dirs
    #
    $nrej++, next if $fname eq "README" and $dname eq "talks" and $dirs[-3] eq "workshop";

    # we reject a set of files from xxx_html_manual/ directories
    #
    # TMP dirs are empty so we don't really need to worry about them but we do
    $nrej++, next if $dname eq "TMP" and $dirs[-2] =~ /_html_manual$/;

    # presumably these are tmp files created during the conversion
    $nrej++, next if $dname =~ /^l2h\d+$/ and $dirs[-2] =~ /_html_manual$/;

    if ( $dname =~ /_html_manual$/ ) {
	$nrej++, next if $fname =~ /^IMG_PARAMS\./;
	$nrej++, next if $fname =~ /^(images|internals|labels)\.pl$/;
	$nrej++, next if $fname =~ /^images\.(aux|log|tex)$/;
    }

    # we reject the download/doc/dmodel directory/contents
    $nrej++, next if $path =~ /download\/doc\/dmodel($|\/)/;

    # last check - is it checked out for editing?
    # Not 100% convinced about the RCS check
    #
    if ( -e "$path/SCCS/p.$fname" ) {
	print "skipping $dname/$fname as checked out [SCCS]\n";
	$nrej++;
	next;
    }
    if ( -e "$path/RCS/$fname,v" ) {
	my $dummy = `rlog -L -R -l $path/RCS/$fname,v`;
	die "Error: problem running 'rlog -L -R -l $path/RCS/$fname,v'\n"
	  unless $? == 0;
	if ( $dummy ne "" ) {
	    print "skipping $dname/$fname as checked out [RCS]\n";
	    $nrej++;
	    next;
	}
    }

    # skip if not an XML file?
    $nrej++, next if $xmlonly && $fname !~ /\.xml$/;

    # hey, we must want this
    # - add to the files in this directory
    # - note CIAO thread index is a special case since
    #   we want to process that AFTER all the threads
    #   have been updated, so we just do it last
    #
    if ( $dname eq "imgs" ) {
	$images{$path} = [] unless exists $images{$path};
	push @{ $images{$path} }, $fname;
    } elsif ( $fname eq "index.xml" and $dname eq "threads" ) {
	die "error: multiple index.xml files in dir called threads/ - what's going on\n"
	  if defined $threadindex;
	$threadindex = $path;
    } else {
	$files{$path} = [] unless exists $files{$path};
	push @{ $files{$path} }, $fname;
    }
    $nfil++;
}
$pipe->close;

#use Data::Dumper;
#print Dumper(\%images), "\n";
#print Dumper(\%files), "\n";

print "Num of files            = $nfil\n";
print "Num of dirs             = $ndir\n";
print "Num of rej. files       = $nrej\n";
print "Num of user rej. files = $nuserrej\n";

# now loop through everything and publish it
#
unless ( $yes ) {
    print "\nAre you sure you want to begin this?\n";
    print "Answer \"y\" for the affirmative.\n";
    print "[THIS IS TO THE " . uc($type) . " SITE]\n";
    my $answer = <STDIN>;
    die unless $answer eq "y\n";
}

# first we publish all the "img" directories
# (since they may be useful for creating PDF files)
#
my $cfg_opt = "--config=$configfile";
my $type_opt = "--type=$type";
my $force_opt = $force ? "--force" : "--noforce";

foreach my $href ( \%images, \%files ) {
    foreach my $dir ( keys %{$href} ) {
	my @files = @{ $$href{$dir} };
	print "Publishing " . (1+$#files) . " files in $dir\n";
	chdir $dir;

	# and do the actual publishing
	system @pexe, $script,
	  $cfg_opt, $type_opt, $force_opt,
	  @files
	    and die "\nerror in\n dir=$dir\n with files=" . join(" ",@files) . "\n\n";
    }
}

# we can now publish the thread index page
#
if ( defined $threadindex ) {
    my @files = qw( index.xml );
    my $dir = $threadindex;

    print "Publishing " . (1+$#files) . " files in $dir\n";
    chdir $dir;

    # and do the actual publishing
    system @pexe, $script,
      "--type=$type", $force ? "--force" : "--noforce",
      @files
	and die "\nerror in\n dir=$dir\n with files=" . join(" ",@files) . "\n\n";
}

chdir $cwd;

## End
#
exit;

