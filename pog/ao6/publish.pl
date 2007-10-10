#!/data/da/Docs/local/perl/bin/perl -w
#
# $Id: publish.pl,v 1.79 2003/09/15 20:04:08 dburke Exp $
#
# Usage:
#   publish.pl --type=test|live|trial <filename(s)>
#     Default for type is test
#
#   publish.pl --ahelp --type=test|live|trial
#     For publishing the ahelp pages ONLY
#     Default for type is test
#
#     --config=config-file
#     The name (including path) of the configuration file.
#     Defaults to <path to this script>/config.dat
#
#     --force
#     Optional.
#
#     --verbose
#     Turn on screen output that's only useful for testing/debugging
#
#   by default will not create HTML files if they already exist
#   and are newer than the XML file (also checks for other
#   associated files and the created PDF files).
#   Use the --force option to force the creation of the HTML files.
#   [note: the thread index pages are currently ALWAYS created].
#
# Aim:
#   Convert the specified files into SSI/web pages.
#   The pages must all reside in the current working directory.
#   The .xml suffix need not be included.
#   If the file does not end in .xml then we assume the file is
#   to be copied over directly and not processed. Used for
#   images/ps files/.. (ie non HTML files).
#
#   The configuration file (probably called config.dat in the
#   "top-level" directory for the particular site) defines a
#   number of important things for the script (eg where to
#   put the HTML files). Actually, to make things easier the
#   config file can contain values for multiple sites
#   (so that the same alias can be used irrespective of site)
#   and the location can be user-defined (by default it is the same
#   as the location of this script, not the site directory as
#   mentioned above - ie this paragraph needs re-writing).
#
#   The location of the output depends on the type option
#   (which defaults to test if not specified). Please don't use
#   the trial type unless you really know what you're doing.
#
# Notes:
#   The ahelp support is essentially orthogonal to everything else
#   here. We actually call a separate script to do the processing
#   [since it also needs to handle creating the CIAO distribution]
#   with this script just being used to call it.
#
#   The support for iCXC pages [ie for our internal pages only] is
#   experimental.
#
# Creates:
#   The location of the output HTML (and possibly PDF) files
#   is defined by the contents of the config file you supply with the
#   --config option
#
# Requires:
#   The location searched for the stylesheets is defined
#   in the config file, as are the actual stylesheets needed.
#
#  xsltproc executable in /data/da/Docs/local/bin
#
# Author:
#  Doug Burke (dburke@cfa.harvard.edu)
#
# History:
#  26 Jul 02 DJB Initial version: amalgamation of all the publish.csh scripts
#                (not complete)
#  30 Jul 02 DJB Removed need to post-process the output of page and navbar documents
#                (required adding list_navbar.xsl)
#                Now uses name of root node (rather than filename) to
#                work out what transforms to apply
#  02 Aug 02 DJB Adding support for threadindex pages (in CIAO only)
#  04 Aug 02 DJB If given a non XML file (well, one not ending in .XML), copy
#                it over to the web site. Added support for redirect pages
#  05 Aug 02 DJB Begin support for threads
#  11 Aug 02 DJB Added support for ChaRT threads. Added hardcopy support for
#                doctype=page. Cleaned up some code.
#  15 Aug 02 DJB temp allow live publishing to the ciao2.3 directory (for testing)
#                Added support for site=pog (messay as a different directory
#                structure and don't want - for now - the "store")
#  20 Aug 02 DJB Added support for faq documents
#  21 Aug 02 DJB Added support for dictionary documents
#                Should amalgamate these as most of the code is the same
#  28 Aug 02 DJB Begin support for ahelp and almost-immediately moved it
#                into a separate script.
#                Post processs the navbar's (using ed) to delete DOCTYPE
#  30 Aug 02 DJB Now processes non-XML files first (may be needed to generate hardcopy)
#  03 Sep 02 DJB Only process if HTML files don't exist/are older than XML file
#                (or use the --force option)
#  04 Sep 02 DJB Adding support for the math tag
#                Explicitly avoid thread=example from the live site
#                create navbar_download_src.incl from navbar_download.incl
#  05 Sep 02 DJB Changing over to use asc-bak rather than icxc as the test site
#                EXCEPT FOR ChaRT pages (since asc-bak is visible to the outside world)
#  17 Sep 02 DJB Added support for publishing the iCXC pages (page & navbar only)
#  18 Sep 02 DJB Added support for /*/info/testonly tag
#                Added support for copying over the contents of /thread/info/files/file
#  20 Sep 02 DJB Moved to using a config file to specify dir locations and the like
#  15 Oct 02 DJB Can now "lock" a release from further changes
#  31 Oct 02 DJB Added --verbose flag
#  28 Mar 03 DJB Moved binary/executable locations to the config file
#                latest htmldoc (1.2.23) now reports when tables exceed page
#                limits, which makes the output noisy. Don't want to remove all
#                messages (ie use -quiet option) and too lazy to parse stderr
#                to remove these warnings.
#  16 Jun 03 DJB Added support for Sherpa thread index page
#  25 Jun 03 DJB Thread index support changed to being pretty-much site agnostic
#  02 Jul 03 DJB Added support for Sherpa FAQ page
#  22 Jul 03 DJB newsfile/newsfileurl params from config
#  01 Aug 03 DJB searchssi params from config
#  08 Aug 03 DJB watchouturl param from config
#                ahelpindexnavbar param from config
#  15 Sep 03 DJB protect XSL parameters with spaces in them
#                Default location for config.dat is now the directory containing
#                this script
#

use strict;
$|++;

use Getopt::Long;
use FindBin;

use Cwd;
use IO::File;
use IO::Pipe;

## Subroutines (see end of file)
#

sub dbg ($);
sub mymkdir   ($);
sub mycp      ($$);
sub myrm      ($);
sub mysetmods ($);

sub process_xml   ($$);
sub process_files ($$);

sub parse_config ($);
sub find_site ($$);

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
  $progname --config=name --type=test|live|trial <filename(s)>
 or
  $progname --config=name --type=test|live|trial --ahelp

The default is --type=test, which publishes to the test web site.
The live option publishes to the live (ie cxc.harvard.edu) site.
Don't use the trial option unless you know what it does.

The --config option gives the path to the configuration file; this
defaults to config.dat in the same directory as the script.

The --force option should be used to force the generation of the
HTML files (by default the program won't publish a file if the HTML,
PDF, and associated files already exist and are newer than the XML
file).

The --verbose option is useful for testing/debugging the code.

EOD

# this will be mangled later
my $dname = cwd();

# handle options
my $type = "test";
my $configfile = "$FindBin::Bin/config.dat";
my $aflag = 0;
my $force = 0;
my $verbose = 0;
die $usage unless
  GetOptions
  'config=s' => \$configfile,
  'type=s'   => \$type,
  'ahelp!'   => \$aflag,
  'force!'   => \$force,
  'verbose!' => \$verbose;

# check the options
die "Error: the config option can not be blank\n"
  if $configfile eq "";
my $config = parse_config( $configfile );

## First check for executable/binary locations
#
my $ldpath   = $$config{ldpath} ||
  die "Error: ldpath location not defined in config file ($configfile)\n";
my $xsltproc = $$config{xsltproc} ||
  die "Error: xsltproc location not defined in config file ($configfile)\n";
my $htmldoc  = $$config{htmldoc} ||
  die "Error: htmldoc location not defined in config file ($configfile)\n";
my $htmllib  = $$config{htmllib} ||
  die "Error: htmllib location not defined in config file ($configfile)\n";

# only bother checking for these if processing ahelp files
my $ahelp2html  = $$config{ahelp2html};
my $listseealso = $$config{listseealso};

# check for paths (just in case)
foreach my $path ( ( $ldpath, $htmllib ) ) {
    die "Error: unable to find the directory $path\n"
      unless -d $path;
}

# check for executables (just in case)
foreach my $exe ( ( $xsltproc, $htmldoc ) ) {
    die "Error: unable to find the executable $exe\n"
      unless -x $exe;
}

# most of the config stuff is parsed below, but we need these two here
my ( $site, $site_config ) = find_site $config, $dname;
$config = undef; # DBG: just make sure no one is trying to access it
my %_types = map { ($_,1) } @{$$site_config{types}};
die "Error: unknown type ($type)\n"
  unless exists $_types{$type};

die "Error: --ahelp option can only be run within the CIAO tree.\n"
 if $aflag and $site ne "ciao";
die "Error: --ahelp option can only be run within a dir called ahelp/.\n"
 if $aflag and $dname !~ /\/ahelp$/;

# check usage: depends on whether ahelp or general XML files
#
die $usage if
 ( $aflag and $#ARGV != -1 )
 or
 ( !$aflag and $#ARGV == -1 );

# Handle the remaining config values
#
# shouldn't have so many global variables...
#
my $group = $$site_config{group};
my $site_prefix = $$site_config{prefix};
my $lp = length( $site_prefix );

# find out what version we are in
# $dname has previously been set to cwd()
#
die "Error: expected to be running within the $site_prefix directory structure\n"
  unless substr($dname,0,$lp) eq $site_prefix;
die "Error: expected to be running in a sub-directory of $site_prefix\n"
  if $dname eq $site_prefix;

my @dnames = split "/", substr($dname,$lp+1);
my $version = shift @dnames;

my $dhead = join "/", @dnames;
$dhead .= "/" unless $dhead eq "";

# calculate the depth, including any offset from the config file
my $depth = 2 + $#dnames;
if ( exists $$site_config{depth_offset} ) {
    $depth += $$site_config{depth_offset};
}

# used to let a page know it's "name" as it is likely to be specified
# in the navbar (and hence so that it can be highlighted using CSS)
#
# see add-htmlhead in helper.xsl - we don't actually use this at the
# moment since it's not clear how to handle all situations
#
my $navbar_link = '../'x($depth-1) . $dhead;
$navbar_link = "index.html" if $navbar_link eq "";

# do we know this version?
my $vinfo = $$site_config{versions};
die "Error: version $version is not defined in the config file ($configfile)\n"
  unless exists $$vinfo{$version};
$vinfo = $$vinfo{$version};

# are we locked?
die "Error:\n   The pages for version=$version site=$site are locked from further publishing!\n"
  if exists $$vinfo{locked};

# check that the version info contains all the required fields
#
{
    my %required =
      (
       stylesheets => "HASH",
       outdir => "HASH",
       outurl => "HASH",
       ahelpindex => "HASH",
      );
    while ( my ( $key, $kref) = each %required ) {
	die "Error: the config file ($configfile) did not contain a $key element for version $version\n"
	  unless exists $$vinfo{$key};
	my $ref = ref( $$vinfo{$key} ) || "SCALAR";
	die "Error: the config file ($configfile) has $key (version $version) as a $ref when it should be a $kref\n"
	  unless $ref eq $kref;
    }
}

my $stylesheets =
  $$vinfo{stylesheets}{$type} ||
  die "Error: stylesheets option (version $version) does not contain a value for type=$type\n";
my $outdir =
  $$vinfo{outdir}{$type} ||
  die "Error: outdir option (version $version) does not contain a value for type=$type\n";
my $outurl =
  $$vinfo{outurl}{$type} ||
  die "Error: outurl option (version $version) does not contain a value for type=$type\n";
my $ahelpindex =
  $$vinfo{ahelpindex}{$type} ||
  die "Error: ahelpindex option (version $version) does not contain a value for type=$type\n";

my $css = $$vinfo{css}{$type} ||
  die "Error: css option (version $version) does not contain a value for type=$type\n";

# this is optional
my $site_version = $$vinfo{number} || "";
die "Error: version $version in the config file ($configfile) does not contain the number parameter\n"
  if $site eq "ciao" and $site_version eq "";

# as is this
# - since we do send these to the processor then we can not let them
#   default to "" since that will cause problems (it will get lost
#   in the shell expansion and so mess up everything). So we use the
#   string "dummy" which is checked for in the stylesheet
my $newsfile = $$vinfo{newsfile}{$type} || "dummy";
my $newsfileurl = $$vinfo{newsurl}{$type} || "dummy";

# don't bother with the use of dummy here
my $watchouturl = $$vinfo{watchouturl}{$type} || "";

# and this
my $searchssi = $$vinfo{searchssi}{$type} || "/incl/search.html";

# storage/published is optional [sort of, depends on the site]
my $published = "";
if ( exists $$vinfo{storage} ) {
    $published = $$vinfo{storage}{$type}
      if exists $$vinfo{storage}{$type};
}

# logo image/text is also optional
# - only needed for navbar pages
#
my $logoimage = $$vinfo{logoimage} || "";
my $logotext  = $$vinfo{logotext}  || "";

# add on our current working directory
$outdir    .= $dhead;
$outurl    .= $dhead;
$published .= $dhead unless $published eq "";

# check for the stylesheets (just in case)
foreach my $xslt ( @{ $$site_config{stylesheets} } ) {
    my $x = "${xslt}.xsl";
    die "Error: unable to find the stylesheet $x in $stylesheets\n"
      unless -e "$stylesheets$x";
}

# the test pages need to know who you are
#
my $uname = `whoami`;
chomp $uname;

dbg "*** CONFIG DATA ***";
dbg "  uname=$uname";
dbg "  dname=$dname";
dbg "  dhead=$dhead";
dbg "  depth=$depth";
dbg "  outdir=$outdir";
dbg "  outurl=$outurl";
dbg "  published=$published";
dbg "  ahelpindex=$ahelpindex";
dbg "  ahelp files?=$aflag";
dbg "  version=$site_version";
dbg "  css=$css";
dbg "  newsfile=$newsfile";
dbg "  newsfileurl=$newsfileurl";
dbg "  watchouturl=$watchouturl";
dbg "  searchssi=$searchssi";
dbg "  logoimage=$logoimage";
dbg "  logotext=$logotext";
dbg "*** CONFIG DATA ***";

# if we're processing ahelp files then we just call ahelp2html.pl and
# let it handle everything
#
if ( $aflag ) {

    # these are set earlier but not checked for (since only relevant here)
    die "Error: ahelp2html location not defined in config file ($configfile)\n"
      unless defined $ahelp2html;
    die "Error: listseealso location not defined in config file ($configfile)\n"
      unless defined $listseealso;
    foreach my $exe ( ( $ahelp2html, $listseealso ) ) {
	die "Error: unable to find the executable $exe\n"
	  unless -x $exe;
    }

    my $ahelpindexfile = $$vinfo{ahelpindexfile} ||
      die "Error: ahelpindexfile location not on config file.\n";
    die "Error: ahelpindexfile does not exist\n"
      unless -e $ahelpindexfile;

    my $navbar_name = $$vinfo{ahelpindexnavbar} || "";

    # create the output directories if we have to
    mymkdir $outdir;
    mymkdir $published;

    # should we send in ahelpindex location?
    #
    my @extra;
    push @extra, "--navbarname=$navbar_name" unless $navbar_name eq "";

    system( $ahelp2html,
	    "--format=web",
	    "--version=$site_version",
	    "--type=$type",
	    $force ? "--force" : "--noforce",
	    $verbose ? "--verbose" : "--noverbose",
	    "--styledir=$stylesheets",
	    "--xsltproc=$xsltproc",
	    "--xsltpath=$ldpath/",
	    "--listseealso=$listseealso",
	    "--htmldoc=$htmldoc",
	    "--htmlpath=$htmllib/",
	    "--ahelpindexfile=$ahelpindexfile",
	    "--cssfile=$css",
	    "--newsfile=$newsfile",
	    "--newsfileurl=$newsfileurl",
	    "--watchouturl=$watchouturl",
	    "--searchssi=$searchssi",
	    "--indir=$dname/",
	    "--outdir=$outdir",
	    "--updateby=$uname",
	    "--store=$published",
	    @extra
	  )
      and die "Error: unable to convert ahelp files into HTML\n";

    # finished
    print "\nThe ahelp files can be viewed at\n  $outurl\n\n";
    exit 0;
}

# Handle the ahelpindex file:
# - could create a temporary, empty, file if it doesn't exist
#   but let's see how annoying this is
#
die "Error: can not find ahelpindex file - have the ahelp files been published?\n  file=$ahelpindex\n"
  unless -e $ahelpindex;

# otherwise, get the list of files to work on
my @xml;
my @nonxml;

# need filenames: strip off trailing .xml if present
# - split into XML and non XML files
#   we don't do anything clever but just rely on the file name
#
foreach my $in ( map { s/\.xml$//; $_; } @ARGV ) {
    if ( -e "${in}.xml" ) { push @xml, $in; }
    elsif ( -e $in )      { push @nonxml, $in; }
    else                  { die "Error: Unable to find $in\n"; }

    # check that the file is in the current working directory
    # [just makes some things a bit easier later on]
    #
    die "Error: $in must be in the current directory\n"
      if $in =~ /\//;
}

# create the output directories if we have to
mymkdir $outdir;
mymkdir $published unless $published eq "";

# note we process the non-XML files first since they
# may be needed to create the PDF versions of the
# pages (ie images)
#
process_files $type, \@nonxml;
process_xml   $type, \@xml;

# End of script
#
exit;

## Subroutines
#

## helper utilities
#

# dbg $msg
#
# prints the message to STDOUT if $verbose != 0
# (adds a leading >>DBG: and trailing \n)
#
sub dbg ($) { print ">>DBG: $_[0]\n" if $verbose; }

# mymkdir( $dname )
#
# Create the directory $dname, automatically creating any 'intermediate' directories
# as required. It uses /bin/mkdir rather then perl's mkdir() function because I
# can't get the umask value set properly.
#
# for this program we also ensure that each created directory has
#   g+w
#
# For example:
#   mymkdir( "bob/fred/john" ) and only bob/ already exists, creates bob/fred/ then
#   bob/fred/john/.
#

sub mymkdir ($) {
    my $dname = $_[0];

    return if -d $dname;
    die "ERROR: <$dname> is a file.\n" if -e $dname;

    # strip through the parts
    my @dirs = split "/", $dname;
    my $dhead = "";

    foreach my $d ( @dirs ) {
        $dhead .= $d;
	unless ( $dhead eq "" or -d $dhead ) {
	    system "/bin/mkdir $dhead" and die "Unable to mkdir $dhead";
	    system "/usr/bin/chmod ug+w $dhead" and die "Unable to chmod ug+w $dhead";
	    system "/usr/bin/chgrp $group $dhead" and die "Unable to chgrp $group $dhead";
	}
        $dhead .= "/";
    }
} # sub: mymkdir()

# mycp( $in, $out )
#
# Deletes $out (if it exists)
# Copies $in to $out
# Sets the permissions on $out to ugo-wx
#          group       of $out to $group (global parameter)
#
sub mycp ($$) {
    my $in  = shift;
    my $out = shift;
    my $name = $_[0];

    myrm $out;
    system "/usr/bin/cp $in $out" and die "Unable to cp $in to $out";
    mysetmods $out;

} # sub: mycp()

# myrm( $fname )
#
# Deletes the input file ($name) using '-f'.
# It uses /usr/bin/rm rather then perl's unlik() function because I
# couldn't be bothered to work out how to do the equivalent of 'rm -f $foo'
#
# does nothing if $fname doesn't exist or is not a file
# (eg if it's a directory)
#
sub myrm ($) {
    my $name = $_[0];

    return unless -e $name;
    system "/usr/bin/rm -f $name";
    die "Error: been unable to delete $name\n"
      if -e $name;

} # sub: myrm()

# mysetmods( $name )
#
# Sets the permissions of $name to ugo-wx
#          group                   $group (global parameter)
#
# Uses system routines ratehr than perl ones because I couldn't be
# bothered to sort out the octal codes
#
# does nothing if $name doesn't exist or isn't a file (eg a directory)
#
sub mysetmods ($) {
    my $name = $_[0];

    return unless -e $name;

    system "/usr/bin/chmod ugo-wx $name" and die "Unable to chmod ugo-wx $name";
    system "/usr/bin/chgrp $group $name" and die "Unable to chgrp $group $name";

} # sub: mysetmods()

# dup the stdout and set it to /dev/null
#
# return a filehandle for the original STDOUT channel
sub dup_stdout () {
    my $fh = IO::File->new( ">&STDOUT" )
      or die "Unable to dup STDOUT\n";
    open STDOUT, ">/dev/null"
      or die "Unable to set STDOUT to /dev/null\n";
    return $fh;
}

sub undup_stdout ($) {
    my $fh = shift;
    my $fd = $fh->fileno;
    open STDOUT, ">&$fd"
      or die "Unable to restore default STDOUT\n";
}

# dup the stderr and set it to /dev/null
#
# return a filehandle for the original STDERR channel
sub dup_stderr () {
    my $fh = IO::File->new( ">&STDERR" )
      or die "Unable to dup STDERR\n";
    open STDOUT, ">/dev/null"
      or die "Unable to set STDERR to /dev/null\n";
    return $fh;
}

sub undup_stderr ($) {
    my $fh = shift;
    my $fd = $fh->fileno;
    open STDERR, ">&$fd"
      or die "Unable to restore default STDERR\n";
}


# utility routine to convert a hash of key/value pairs into
# a string saying
#  "--stringparam key1 value1 --stringparam key2 value2 ..."
#
sub make_params ($) {
    my $hash = shift;
##    return join( "", map { "--stringparam $_ $$hash{$_} " } keys %$hash );
    return join( "", map
		 {
		     my $parname = $_;
		     my $parval = $$hash{$parname};
#		     $parval = "''" if $parval eq "";

print STDERR "--- parname $parname has no defined value\n" unless defined $parval;
		     $parval = "''" if !defined($parval) or $parval eq "";

		     # try and protect spaces in any arguments
		     #
		     if ( $parval =~ / / && $parval !~ /^['"]/ ) {
			 $parval = "'${parval}'";
print STDERR "--- protecting parameter value [$parval]\n";
		     }

		     "--stringparam $parname $parval "
		 } keys %$hash );

} # sub: make_params()

# run the processor and return the screen output
#
# uses the global variables $xsltproc and $ldpath
#
sub translate_file ($$$) {
    my $params     = shift;
    my $stylesheet = shift;
    my $xml_file   = shift; # with/without trailing .xml
    $xml_file .= ".xml" unless $xml_file =~ /\.xml$/;

    dbg "*** XSLT ***";
    dbg "  in=$xml_file";
    dbg "  xslt=$stylesheet";
    dbg "  *** params ***";
    foreach my $p ( split /--/, $params ) {
	next if $p =~ /^\s*$/;
	dbg "    --$p";
    }
    dbg "  *** params ***";
    ###dbg "  /usr/bin/env LD_LIBRARY_PATH=$ldpath $xsltproc $params $stylesheet $xml_file";

    my $retval = `/usr/bin/env LD_LIBRARY_PATH=$ldpath $xsltproc $params $stylesheet $xml_file`;

    die "\nError: problems using $stylesheet\n       error in XML file ($xml_file)?\n\n"
      unless $? == 0;

    dbg "*** XSLT ***";
    return $retval;

} # sub translate_file()

## create the hardcopy versinos of the files
#
# create_hardcopy $dir, $head
# create_hardcopy $dir, $hthml_head, $out_head
#
# creates $dir/$head.[letter|a4].pdf
# and deletes the hardcopy version of the file once it's finished with
#
# it site=icxc we just delete the hardcopy version
# [should re-write the stylesheets]
#
sub create_hardcopy ($$;$) {
    my $indir = shift;
    my $html_head = shift;
    my $out_head  = shift || $html_head;

    my $in  = "${indir}${html_head}.hard.html";

    return unless -e $in;

    # we shouldn't be here if site=icxc (well, once all pathways have been changed)
    if ( $site eq "icxc" ) {
	print "\nDeleting 'hardcopy' version since site=icxc\n";
	myrm $in;
	return;
    }

    print "\nCreating hardcopy formats:\n";
    foreach my $size ( qw( letter a4 ) ) {
	foreach my $type ( qw( pdf ) ) {

	    my $out = "${indir}${out_head}.${size}.${type}";

	    # check/clean up
	    die "Error: unable to find $in\n"
	      unless -e $in;
	    myrm $out;

	    `/usr/bin/env LD_LIBRARY_PATH=$htmllib $htmldoc --webpage --duplex --size $size -f $out $in`;
	    print "\n" .
                  "WARNING: problems using htmldoc\n" .
                  "         [can ignore if ERR014]\n" .
                  "\n"
	      unless $? == 0;

	    die "Error: $out not created by htmldoc\n"
	      unless -e $out;
	    mysetmods $out;

	    print "  created: ${out_head}.${size}.${type}\n";

	} # foreach: $type
    } # foreach: $size

    # clean up the hardcopy file now we've finished with it
    myrm $in;

} # sub: create_hardcopy

# return if should_we_skip $in, @files
#
# if $in is a scalar, then it is the name of an xml file
# (needn't contain a trailing .xml)
# if it's a reference, then it's a reference to the "age" (-M $foo)
# of the file to check against
#
# returns 1 if we can skip processing this file
# 0 otherwise
#
# uses the global variable $force
#
sub should_we_skip ($@) {
    my $in = shift;
    my @files = @_;

    # don't skip if force is selected
    return 0 if $force;

    # do we need to mess around with things?
    my $intime;
    if ( ref($in) ) {
	$intime = $$in;
    } else {
	$in =~ s/\.xml$//;
	$in .= ".xml";
	$intime = -M $in;
    }

    foreach my $file ( @files ) {
	# is this a 'hard copy' page?
	if ( $file =~ /\.hard\.html$/ ) {
	    $file =~ s/\.hard\.html$//;
	    foreach my $f ( map { "${file}.$_.pdf"; } qw( a4 letter ) ) {
		return 0
		  unless -e $f and -M $f < $intime;
	    }
	} else {
	    return 0
	      unless -e $file and -M $file < $intime;
	}

    } # foreach: @files

    # if got this far the file's for skipping
    print "\tskipping\n";
    return 1;

} # should_we_skip()

# math2gif $head, $gif
#
# convert trhe equation sotred in the file $head.tex
# into a gif called $gif, sets its protections
#
# then delete $tex
#
# NOTE: this is based on text2im v1.5
#
sub math2gif ($$) {
    my $head = shift;
    my $gif  = shift;
    my $tex  = $head . ".tex";

    die "Error: transformation did not create $tex\n"
      unless -e $tex;

    # create the dvi file
    #
    system "latex", "-interaction=batchmode", $tex
      and die "Error: unable to latex $tex\n";

    # and the ps
    my $rflag = system "dvips", "-o", "$head.eps", "-E", "$head.dvi";
    die "Error: unable to run dvips on $head.dvi to create $head.eps\n"
      if $rflag;

    # and now the gif file
    # note - creates 2 versions
    system "convert", "+adjoin", "-density", "150x150", "$head.eps", "$head.gif"
      and die "Error: unable to convert to GIF\n";

    die "Error: $gif was not created\n"
      unless -e "$head.gif.0";
    system "cp", "$head.gif.0", $gif;

    # clean up and return
    foreach my $ext ( qw( log aux dvi eps tex gif.0 gif.1 ) ) { myrm $head . ".$ext"; }
    mysetmods $gif;
    print "Created: $gif\n";

} # sub: math2gif()

# can we publish this page for this site?
#
sub site_check ($$@) {
    my ( $site, $label, @ok ) = @_;
    my %ok = map { ($_,1); } @ok;
    die "Error: currently can only convert $label pages in site=" . join(",",@ok) . "\n"
      unless exists $ok{$site};
} # sub: site_check

# xml2html_navbar - called by xml2html
#
sub xml2html_navbar ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $outdir = $$opts{outdir};

    # convert the input XML file into HTML files
    #
    # output of stylesheet is a list of pages that have been created
    # and the actual pages (created in $outdir).
    # We need to hack the output files to remove unwanted content
    # [managed to remove most of this but the first line contains
    #  '<!DOCTYPE...>' which we don't want]
    #
    # NOTE: $outdir MUST end in a '/' (this is checked for by XSLT stylesheet
    #
    print "Parsing [navbar]: $in"; # don't '\n' until skip check

    my @extra;
    push @extra, ( logoimage => $logoimage )    if $logoimage ne "";
    push @extra, ( logotext  => "'$logotext'" ) if $logotext  ne "";

    my $params = make_params
      {
	  type => $$opts{type},
	  site => $$opts{site},
	  install => $outdir,
	  sourcedir => cwd() . "/",
	  updateby => $$opts{updateby},
	  pagename => $in,
	  # ahelpindex added in CIAO 3.0
	  ahelpindex => $ahelpindex,
	  ## cssfile => $css, # not needed for navbar
	  newsfile => $newsfile,
	  newsfileurl => $newsfileurl,
	  watchouturl => $watchouturl,
	  searchssi => $searchssi,
	  @extra,
      };

    # get a list of the pages: we need this so that:
    # - we can create the directory if necessary
    # - we can delete them [if they exist] before the processor runs
    #   (since we write protect them after creation so the processor
    #    can't actually create the new files)
    #
    my $pages = translate_file $params, "$$opts{xslt}list_navbar.xsl", $in;
    $pages =~ s/\s+/ /g;
    my @pages = split " ", $pages;

    # do we need to recreate
    return if should_we_skip $in, @pages;
    print "\n";

    # create dirs/remove files
    foreach my $page ( @pages ) {
	my $dir = $page;
	$dir =~ s/\/[^\/]+.incl$//;
	mymkdir $dir;
	myrm $page;
    }

    # run the processor - ignore the screen output
    translate_file $params, "$$opts{xslt}navbar.xsl", $in;

    my @download;
    foreach my $page ( @pages ) {
	die "Error: transformation did not create $page\n"
	  unless -e $page;

	# the following is plain ugly
	#
	# hack the page to remove the leading '<!DOCTYPE ...' link
	#
	my $old_stdout = dup_stdout;

	my $pipe = IO::Pipe->new();
	$pipe->writer( "/usr/bin/ed", $page );
	$pipe->print( join( "\n", ( "1,d", "1,d", "w", "q" ) ) . "\n" );
	$pipe->close();

	undup_stdout $old_stdout;

	mysetmods $page;
	print "Created: $page\n";

	push @download, $page if $page =~ /navbar_download.incl$/;
    }

    # do we need to create navbar_download_src.incl?
    #
    # - it's easier to do this here than within a stylesheet
    #
    if ( $#download > -1 ) {
	print "\nWARNING: multiple navbar_download.incl's\n\n"
	  if $#download != 0;

	foreach my $page ( @download ) {
	    my $out = $page;
	    $out =~ s/navbar_download.incl$/navbar_download_src.incl/;
	    myrm $out;

	    my $ifh = IO::File->new( "< $page" )
	      or die "Error: Unable to open $page for reading.\n";
	    my $ofh = IO::File->new( "> $out" )
	      or die "Error: Unable to open $out for reading.\n";
	    while ( <$ifh> ) {
		# rely on a limited choice of src locations for images
		# in the navbar's
		s/ src="imgs\// src="\/ciao\/imgs\//g;
		$ofh->print( $_ );
	    }
	    $ifh->close;
	    $ofh->close;

	    mysetmods $out;
	    print "Created: $out\n";
	}
    }

    print "\nThe navigation pages have been created on:\n  $$opts{outurl}\n\n";

} # sub: xml2html_navbar

# xml2html_page - called by xml2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
sub xml2html_page ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $depth  = $$opts{depth};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};

    my $lastmod = "'$$opts{lastmod}'";

    # the navbarlink is currently not used by the code
    # - see the comments in helper.xsl
    # - note that I do not believe $nlink is set to
    #   a sensible value by the following !!
#    my $nlink = $$opts{navbar_link};
#    $nlink .= "${in}.html" unless $in eq "index";

    print "Parsing [page]: $in";
    my $params = make_params
      {
	  type => $$opts{type},
	  site => $$opts{site},
	  lastmod => $lastmod,
	  install => $outdir,
	  pagename => $in,
#	  navbarlink => $nlink,
	  url => "${outurl}${in}.html",
	  sourcedir => cwd() . "/",
	  updateby => $$opts{updateby},
	  depth => $depth,
	  siteversion => $site_version,
	  # ahelpindex added in CIAO 3.0
	  ahelpindex => $ahelpindex,
	  cssfile => $css,
	  newsfile => $newsfile,
	  newsfileurl => $newsfileurl,
	  watchouturl => $watchouturl,
	  searchssi => $searchssi,
      };

    # we 'hardcode' the output of the transformation
    my @pages = ( "${outdir}${in}.html" );
    push @pages, "${outdir}${in}.hard.html" unless $site eq "icxc";

    # how about math pages?
    #
    my $math = translate_file "", "$$opts{xslt}list_math.xsl", $in;
    my @math = split " ", $math;

    # do we need to recreate (include the equations created by any math blocks)
    return if should_we_skip $in, @pages, map( { "${outdir}${_}.gif"; } @math );
    print "\n";

    # remove files [already ensured the dir exists]
    foreach my $page ( @pages ) { myrm $page; }
    foreach my $page ( @math ) {
	myrm "${page}.tex";
	myrm "${page}.aux";
	myrm "${page}.log";
	myrm "${page}.dvi";
	myrm "${page}.eps";
	myrm "${outdir}${page}.gif";
    }

    # run the processor, pipe the screen output to a file
    translate_file $params, "$$opts{xslt}page.xsl", $in;

    # success or failure?
    foreach my $page ( @pages ) {
	die "Error: transformation did not create $page\n"
	  unless -e $page;
	mysetmods $page;
	print "Created: $page\n";
    }

    # math?
    foreach my $page ( @math ) { math2gif $page, "${outdir}${page}.gif"; }

    # create the hardcopy pages
    create_hardcopy $outdir, $in;

    print "\nThe page can be viewed on:\n  ${outurl}$in.html\n\n";

} # sub: xml2html_page

# xml2html_redirect - called by xml2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
sub xml2html_redirect ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};

    print "Parsing [redirect]: $in";
    my $out = "${outdir}${in}.html";

    # do we need to recreate
    return if should_we_skip $in, $out;
    print "\n";

    myrm $out;

    translate_file "--stringparam filename $out", "$$opts{xslt}redirect.xsl", $in;

    die "Error: unable to create $out\n" unless -e $out;
    mysetmods $out;
    print "Created: $out\n";

    print "\nThe page can be viewed on:\n  ${outurl}$in.html\n\n";

} # sub: xml2html_redirect

# xml2html_softlink - called by xml2html
#
# behavious is somewhat different to other XML
# docs
#
# we always recreate
#
sub xml2html_softlink ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $outdir = $$opts{outdir};

    print "Parsing [softlink]: $in\n";

    # get the in/out list
    my $pages = translate_file "", "$$opts{xslt}list_softlink.xsl", $in;
    $pages =~ s/\s+/ /g;
    my %pages = split " ", $pages;

    die "Error: softlink should have produced keys of original: and link:\n"
      unless exists $pages{"original:"} and exists $pages{"link:"};

    my $orig = $pages{"original:"};
    my $link = $pages{"link:"};

    die "Error: softlink original file ($orig) does not exist\n"
      unless -e "$outdir/$orig";

    # sort out the link
    #
    my $home = cwd();
    chdir $outdir;
    myrm $link;
    symlink $orig, $link or
      die "ERROR: unable to symlink $link to $orig\n";
    chdir $home;

} # sub: xml2html_softlink

# xml2html_register - called by xml2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
sub xml2html_register ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $depth  = $$opts{depth};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};

    my $lastmod = "'$$opts{lastmod}'";

    print "Parsing [register]: $in";
    my $params = make_params
      {
	  type => $$opts{type},
	  site => $$opts{site},
	  lastmod => $lastmod,
	  install => $outdir,
	  pagename => $in,
	  url => "${outurl}${in}.html",
	  sourcedir => cwd() . "/",
	  updateby => $$opts{updateby},
	  depth => $depth,
	  siteversion => $site_version,
	  # ahelpindex added in CIAO 3.0
	  ahelpindex => $ahelpindex,
	  cssfile => $css,
	  newsfile => $newsfile,
	  newsfileurl => $newsfileurl,
	  watchouturl => $watchouturl,
	  searchssi => $searchssi,
      };

    # get a list of the pages: we need this so that:
    # - we can create the directrory if necessary
    # - we can delete them [if they exist] before the processor runs
    #   (since we write protect them after creation so the processor
    #    can't actually create the new files)
    #
    my $pages = translate_file $params, "$$opts{xslt}list_register.xsl", $in;
    $pages =~ s/\s+/ /g;
    my @pages = split " ", $pages;

    # check for math blocks (can't be bothered to handle in register blocks)
    #
    my $math = translate_file "", "$$opts{xslt}list_math.xsl", $in;
    my @math = split " ", $math;
    die "Error: currently math blocks are not allowed in register pages (hassle Doug)\n"
      unless $#math == -1;

    # do we need to recreate
    return if should_we_skip $in, @pages;
    print "\n";

    # create dirs/remove files
    foreach my $page ( @pages ) {
	my $dir = $page;
	$dir =~ s/\/[^\/]+.html$//;
	mymkdir $dir;
	myrm $page;
    }

    # run the processor - create the "register" version of the page
    translate_file $params, "$$opts{xslt}register.xsl", $in;

    # run the processor - create the "live" version of the page
    translate_file $params, "$$opts{xslt}register_live.xsl", $in;

    # success or failure?
    foreach my $page ( @pages ) {
	die "Error: transformation did not create $page\n"
	  unless -e $page;
	mysetmods $page;
	print "Created: $page\n";
    }

    # create the hardcopy pages
    create_hardcopy $outdir, $in;

    print "\nThe pages can be viewed on:\n  ${outurl}${in}_reg.html\n  ${outurl}${in}_src.html\n\n";

} # sub: xml2html_register

# xml2html_faq - called by xml2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
sub xml2html_faq ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $depth  = $$opts{depth};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};
    my $site   = $$opts{site};

    my $lastmod = "'$$opts{lastmod}'";

    # temporary
    site_check( $site, "faq", "ciao", "sherpa" );

    print "Parsing [faq]: $in";
    my $params = make_params
      {
	  type => $$opts{type},
	  site => $site,
	  lastmod => $lastmod,
	  install => $outdir,
	  sourcedir => cwd() . "/",
	  urlhead => $outurl,
	  depth => $depth,
	  updateby => $$opts{updateby},
	  pagename => $in,
	  siteversion => $site_version,
	  # ahelpindex added in CIAO 3.0
	  ahelpindex => $ahelpindex,
	  cssfile => $css,
	  newsfile => $newsfile,
	  newsfileurl => $newsfileurl,
	  watchouturl => $watchouturl,
	  searchssi => $searchssi,
      };

    # get a list of the pages: we need this so that:
    # - we can create the directrory if necessary
    # - we can delete them [if they exist] before the processor runs
    #   (since we write protect them after creation so the processor
    #    can't actually create the new files)
    #
    my $pages = translate_file $params, "$$opts{xslt}list_faq.xsl", $in;
    $pages =~ s/\s+/ /g;
    my @soft = split " ", $pages;
    my @hard = map { my $a = $_; $a =~ s/\.html$/.hard.html/; $a; } @soft;

    # how about math pages?
    #
    my $math = translate_file "", "$$opts{xslt}list_math.xsl", $in;
    my @math = split " ", $math;

    # do we need to recreate
    return if should_we_skip $in, @soft, @hard, map( { "${outdir}${_}.gif"; } @math );
    print "\n";

    # create dirs/remove files
    foreach my $page ( @soft, @hard ) {
	my $dir = $page;
	$dir =~ s/\/[^\/]+.html$//;
	mymkdir $dir;
	myrm $page;
    }
    foreach my $page ( @math ) {
	myrm "${page}.tex";
	myrm "${page}.aux";
	myrm "${page}.log";
	myrm "${page}.dvi";
	myrm "${page}.eps";
	myrm "${outdir}${page}.gif";
    }

    # run the processor [ignore the screen output here]
    translate_file $params, "$$opts{xslt}faq.xsl", $in;

    # check the softcopy versions
    foreach my $page ( @soft ) {
	die "Error: transformation did not create $page\n"
	  unless -e $page;
	mysetmods $page;
	print "Created: $page\n";
    }

    # math?
    foreach my $page ( @math ) { math2gif $page, "${outdir}${page}.gif"; }

    # create the hardcopy pages
    foreach my $page ( @hard ) {
	die "Error: transformation did not create $page\n"
	  unless -e $page;
	mysetmods $page;
	$page =~ s/^.+\/([^\/]+).hard.html$/$1/;
	create_hardcopy $outdir, $page;
    }

    print "\nThe FAQ index page can be viewed at:\n  $outurl\n\n";

} # sub: xml2html_faq

# xml2html_dictionary - called by xml2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
sub xml2html_dictionary ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $depth  = $$opts{depth};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};
    my $site   = $$opts{site};

    my $lastmod = "'$$opts{lastmod}'";

    # temporary
    site_check( $site, "dictionary", "ciao" );

    print "Parsing [dictionary]: $in";
    my $params = make_params
      {
	  type => $$opts{type},
	  site => $site,
	  lastmod => $lastmod,
	  install => $outdir,
	  sourcedir => cwd() . "/",
	  urlhead => $outurl,
	  depth => $depth,
	  updateby => $$opts{updateby},
	  pagename => $in,
	  siteversion => $site_version,
	  # ahelpindex added in CIAO 3.0
	  ahelpindex => $ahelpindex,
	  cssfile => $css,
	  newsfile => $newsfile,
	  newsfileurl => $newsfileurl,
	  watchouturl => $watchouturl,
	  searchssi => $searchssi,
      };

    # get a list of the pages: we need this so that:
    # - we can create the directrory if necessary
    # - we can delete them [if they exist] before the processor runs
    #   (since we write protect them after creation so the processor
    #    can't actually create the new files)
    #
    my $pages = translate_file $params, "$$opts{xslt}list_dictionary.xsl", $in;
    $pages =~ s/\s+/ /g;
    my @soft = split " ", $pages;
    my @hard = map { my $a = $_; $a =~ s/\.html$/.hard.html/; $a; } @soft;

    # how about math pages?
    #
    my $math = translate_file "", "$$opts{xslt}list_math.xsl", $in;
    my @math = split " ", $math;

    # do we need to recreate
    return if should_we_skip $in, @soft, @hard, map( { "${outdir}${_}.gif"; } @math );
    print "\n";

    # create dirs/remove files
    foreach my $page ( @soft, @hard ) {
	my $dir = $page;
	$dir =~ s/\/[^\/]+.html$//;
	mymkdir $dir;
	myrm $page;
    }
    foreach my $page ( @math ) {
	myrm "${page}.tex";
	myrm "${page}.aux";
	myrm "${page}.log";
	myrm "${page}.dvi";
	myrm "${page}.eps";
	myrm "${outdir}${page}.gif";
    }

    # run the processor [ignore the screen output here]
    translate_file $params, "$$opts{xslt}dictionary.xsl", $in;

    # check the softcopy versions
    foreach my $page ( @soft ) {
	die "Error: transformation did not create $page\n"
	  unless -e $page;
	mysetmods $page;
	print "Created: $page\n";
    }

    # math?
    foreach my $page ( @math ) { math2gif $page, "${outdir}${page}.gif"; }

    # create the hardcopy pages
    foreach my $page ( @hard ) {
	die "Error: transformation did not create $page\n"
	  unless -e $page;
	mysetmods $page;
	$page =~ s/^.+\/([^\/]+).hard.html$/$1/;
	create_hardcopy $outdir, $page;
    }

    print "\nThe dictionary index page can be viewed at:\n  $outurl\n\n";

} # sub: xml2html_dictionary

# xml2html_threadindex - called by xml2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
# note: always publish as too lazy to check against
#   all the threads
#
sub xml2html_threadindex ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $depth  = $$opts{depth};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};
    my $site   = $$opts{site};

    my $lastmod = "'$$opts{lastmod}'";

    # temporary
    site_check( $site, "threadindex", "ciao", "sherpa" );

    print "Parsing [threadindex]: $in\n";
    my $params = make_params
      {
	  type => $$opts{type},
	  site => $site,
	  lastmod => $lastmod,
	  install => $outdir,
	  sourcedir => cwd() . "/",
	  urlhead => $outurl,
	  depth => $depth,
	  updateby => $$opts{updateby},
          pagename => $in,
	  # where the published threads are stored
	  threadDir => $$opts{store},
	  siteversion => $site_version,
	  # ahelpindex added in CIAO 3.0
	  ahelpindex => $ahelpindex,
	  cssfile => $css,
	  newsfile => $newsfile,
	  newsfileurl => $newsfileurl,
	  watchouturl => $watchouturl,
	  searchssi => $searchssi,
      };

    # get a list of the pages: we need this so that:
    # - we can create the directrory if necessary
    # - we can delete them [if they exist] before the processor runs
    #   (since we write protect them after creation so the processor
    #    can't actually create the new files)
    # - note I'm too lazy to add the hardcopy versions to list_threadindex.xsl
    #
    my $pages = translate_file $params, "$$opts{xslt}list_threadindex.xsl", $in;
    $pages =~ s/\s+/ /g;
    my @soft = split " ", $pages;
    my @hard = map { my $a = $_; $a =~ s/\.html$/.hard.html/; $a; } @soft;

    # do not allow math in the threadindex (for now)
    #
    my $math = translate_file "", "$$opts{xslt}list_math.xsl", $in;
    my @math = split " ", $math;
    die "Error: found math blocks in $in - not allowed here\n"
      unless $#math == -1;

    # NOTE: we always recreate the threadindex
    # (it just makes things easier, since the thread index pages
    # depend on so many files)
    #

    # create dirs/remove files
    foreach my $page ( @soft, @hard ) {
	my $dir = $page;
	$dir =~ s/\/[^\/]+.html$//;
	mymkdir $dir;
	myrm $page;
    }

    # run the processor [ignore the screen output here]
    translate_file $params, "$$opts{xslt}threadindex.xsl", $in;

    # check the softcopy versions
    foreach my $page ( @soft ) {
	die "Error: transformation did not create $page\n"
	  unless -e $page;
	mysetmods $page;
	print "Created: $page\n";
    }

    # create the hardcopy pages
    foreach my $page ( @hard ) {
	die "Error: transformation did not create $page\n"
	  unless -e $page;
	mysetmods $page;
	$page =~ s/^.+\/([^\/]+).hard.html$/$1/;
	create_hardcopy $outdir, $page;
    }

    print "\nThe thread index pages can be viewed at:\n  $outurl\n\n";

} # sub: xml2html_threadindex

# xml2html_thread - called by xml2html
#
# note: use site-specific stylesheets
#
# note: $xslt, $outdir, and $outurl end in a /
#
# note: need to copy over /thread/info/files/file entries
#
sub xml2html_thread ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $depth  = $$opts{depth};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};
    my $threadname = $$opts{dirname};
    my $site   = $$opts{site};

    # $store only relevant for non POG sites
    # - well, I'd like that to be the case but for now (AO5 release, Dec 2002)
    #   I am going to re-introduce the storage directory for the pog
    #   just to get things working (otherwise we'd need to check what
    #   stylesheets want threadDir
    #
    my $store = "";
    my $threadDir = "";
#    if ( $site ne "pog" ) {
#	$store = $$opts{store};
#	$store .= "/" unless $store =~ /\/$/; # make sure we have a trailing '/'
#
#	# do we really need both $store and $threadDir?
#	$threadDir = $store;
#	$threadDir =~ s/\/[^\/]+\/$/\//;
#    }

    $store = $$opts{store};
    $store .= "/" unless $store =~ /\/$/; # make sure we have a trailing '/'

    # do we really need both $store and $threadDir?
    $threadDir = $store;
    $threadDir =~ s/\/[^\/]+\/$/\//;

    print "Parsing [thread]: $in";
    my $params = make_params
      {
	  type => $$opts{type},
	  site => $site,
	  install => $outdir,
	  sourcedir => cwd() . "/",
	  depth => $depth,
	  updateby => $$opts{updateby},
	  pagename => $in,
	  # where the published threads are stored [if they are]
	  threadDir => $threadDir,
	  siteversion => $site_version,
	  # ahelpindex added in CIAO 3.0
	  ahelpindex => $ahelpindex,
	  cssfile => $css,
	  newsfile => $newsfile,
	  newsfileurl => $newsfileurl,
	  watchouturl => $watchouturl,
	  searchssi => $searchssi,
      };

    # find out information about this conversion
    #
    my $list_files = translate_file "", "$$opts{xslt}list_thread.xsl", $in;

    # split the list up into sections: html, image, screen, and file
    #
    # we also want to find out which of these is the "youngest" file
    # for use in the 'skip' check below
    #
    my $time     = -M "$in.xml";

    my ( @html, @image, @screen, @file );
    foreach my $page_info ( split "\n", $list_files ) {
	my ( $type, $name ) = split " ", $page_info;

	# note: only want to carry on processing within this loop if an input file
	if    ( $type eq "html:" )      { push @html, $name; next; }
	elsif ( $type eq "image:" )     { push @image, $name; }
	elsif ( $type eq "screen:" )    { push @screen, $name; $name .= ".txt"; }
	elsif ( $type eq "file:" )      { push @file, $name; }
	else {
	    die "Error: list_thread.xsl returned unknown type [$type]\n";
	}

	# check if file is knowm
	die "Error: thread needs file $name which does not exist\n"
	  unless -e $name;

	# check if it's younger than the previous files
	my $t = -M $name;
	$time = $t if $t < $time;

    } # foreach: $page_info

    # how about math pages?
    #
    my $math = translate_file "", "$$opts{xslt}list_math.xsl", $in;
    my @math = split " ", $math;

    # do we need to recreate
    # (need to send in a reference since it's the age of
    #  the file, rather than the file itself)
    #
    # + need to add installation dir onto output file names
    #   and hack the .hard. version so that we look for the
    #   correct pdf file names (not index.[a4|letter].pdf)
    #
    return if should_we_skip \$time,
      map { my $a = $_; $a =~ s/index\.hard\.html$/$threadname.hard.html/; "${outdir}$a"; } @html,
	map( { "${outdir}${_}.gif"; } @math );
    print "\n";

    print "  install to: $outdir\n";

    # convert the text file into XML format
    # (it will be included by the main transformation)
    #
    foreach my $page ( @screen ) {
	my $in  = "$page.txt";
	my $out = "$page.xml";

	die "Error: unable to find $in\n" unless -e $in;

	my $ifh = IO::File->new( "< $in" )
	  or die "Error: unable to open $in for reading\n";
	my $ofh = IO::File->new( "> $out" )
	  or die "Error: unable to open $out for writing\n";
	$ofh->print( "<dummy>\n" );
	while ( <$ifh> ) {
	    # protect the ahelp tags
	    s/<ahelp/{ahelp/g;
	    s/<\/ahelp/{\/ahelp/g;
            s/&/&amp;/g;
            s/</\&lt;/g;
            s/{\/ahelp/<\/ahelp/g;
            s/{ahelp/<ahelp/g;
	    $ofh->print( $_ );
	}
	$ofh->print( "</dummy>\n" );
	$ofh->close;
	print "  processing: $in\n";

    } # foreach: $file

    # copy across each file (image and file) to the output directory
    # (and set the correct ownership/permissions)
    #
    # note: already checked for existence of each file earlier
    #
    foreach my $in ( @image, @file ) {
	my $out = "${outdir}$in";

	# copy, set up permissions and owner
	mycp $in, $out;
	print "  copied    : $in\n";

    } # foreach: $page

    # what HTML files are created (so we can delete them before the processor
    # tries to create them and barfs because they are write protected)
    #
    foreach my $page ( @html ) { myrm "${outdir}$page"; }
    foreach my $page ( @math ) {
	myrm "${page}.tex";
	myrm "${page}.aux";
	myrm "${page}.log";
	myrm "${page}.dvi";
	myrm "${page}.eps";
	myrm "${outdir}${page}.gif";
    }

    # run the processor [ignore the screen output here]
    translate_file $params, "$$opts{xslt}${site}_thread.xsl", $in;

    # create the "hardcopy" version
    translate_file $params, "$$opts{xslt}${site}_thread_hard.xsl", $in;

    # set the correct owner/permissions for the HTML files
    #
    foreach my $page ( @html ) {
	my $out = "${outdir}$page";
	die "Error: transformation did not create $out\n"
	  unless -e $out;
	mysetmods $out;
	print "Created: $page\n";
    }

    # math?
    foreach my $page ( @math ) { math2gif $page, "${outdir}${page}.gif"; }

    # create the hardcopy files
    # [perhaps should return an array of files that are processed by xml2html?]
    #
    create_hardcopy $outdir, "index", $threadname;

    # delete the converted screen files
    # these SHOULD BE copied over to the storage space first
    #
    foreach my $page ( @screen ) { myrm "$page.xml"; }

    print "\nThe thread can be viewed at:\n  $outurl\n\n";

} # sub: xml2html_thread

# die_if_icxc $root
#
# dies if the site (flobal variable $site) is equal
# to icxc
#
sub die_if_icxc ($) {
    my $root;
    die "Error: can not publish $root type documents on the iCXC site\n"
      if $site eq "icxc";

} # sub: die_if_icxc()

# handle non-ahelp XML files
#
# uses lots of global variables...
#
sub process_xml ($$) {
    my $type = shift;
    my $aref = shift;
    dbg "processing " . (1+$#$aref). " XML files";

    # perform the XML conversions
    # - this routine just decides which particular conversion
    #   system to use, and then farms it off. It does this on the
    #   basis of the name of the root node of the document
    #
    foreach my $in ( @$aref ) {

	die "Error: unable to find the output directory '$outdir'\n"
	  unless -d $outdir;

	# perhaps should include siteversion?
	my $opts =
	  {
	   xml => $in, depth => $depth,
	   dirname => $dnames[-1],
	   navbar_link => $navbar_link,
	   site => $site, type => $type, xslt => $stylesheets,
	   outdir => $outdir, outurl => $outurl,
	   store => $published,
	   updateby => $uname,
	   version => $version,
	  };

	# what is the name of the root node?
	# (plus we also check for the presence of the /*/info/testonly tag here)
	my $roots = translate_file "", "${stylesheets}list_root_node.xsl", $in;
	chomp $roots;
	my ( $root, $testonly ) = split " ", $roots;
	$testonly ||= "";

	# skip if we're live publishing
	if ( $type eq "live" and $testonly eq "TESTONLY" ) {
	    print "The page $in [type $root] has been marked as for the test site only\n\n";
	    next;
	}

	# when was the file last modified?
	# convert the date into "Day_number Month_string Year_number"
	{
	    my @month = qw( January February March April May June July August
			    September October November December );
	    my @tm = localtime( (stat("$in.xml"))[9] );
	    $$opts{lastmod} = sprintf "%d %s %d",
	      $tm[3], $month[$tm[4]], 1900+$tm[5];
	}

	# what transformation do we apply?
	#
	if ( $root eq "navbar" ) {
	    xml2html_navbar $opts;
	} elsif ( $root eq "page" ) {
	    xml2html_page $opts;
	} elsif ( $root eq "redirect" ) {
	    die_if_icxc $root;
	    xml2html_redirect $opts;
	} elsif ( $root eq "softlink" ) {
	    die_if_icxc $root;
	    xml2html_softlink $opts;
	} elsif ( $root eq "threadindex" ) {
	    die_if_icxc $root;
	    xml2html_threadindex $opts;
	} elsif ( $root eq "thread" ) {
	    die_if_icxc $root;
	    xml2html_thread $opts;
	} elsif ( $root eq "register" ) {
	    die_if_icxc $root;
	    xml2html_register $opts;
	} elsif ( $root eq "faq" ) {
	    die_if_icxc $root;
	    xml2html_faq $opts;
	} elsif ( $root eq "dictionary" ) {
	    die_if_icxc $root;
	    xml2html_dictionary $opts;
	} elsif ( $root eq "cxchelptopics" ) {
	    die_if_icxc $root;
	    die "Error: ahelp files should be processed using the --ahelp option\n";
	} else {
	    die "Error: $in.xml has an unknown root node [$root]\n";
	}

	# copy file over to storage space and sort out protection/group
	# - we need to be more clever than this because some files will need multiple
	#   files copied over [eg the threads have images, screen, and include files]
	#
	mycp "${in}.xml", "${published}/${in}.xml" if $published ne "";

    } # foreach: my $in

} # sub: process_xml()

# handle non-XML files
#
# uses lots of global variables...
#
# We do nothing if site=icxc (since we're within the
# live site anyway)
#
# NOTE: we no longer copy the files over to the storage site
# to save space
#
sub process_files ($$) {
    my $type = shift;
    my $aref = shift;
    dbg "processing " . (1+$#$aref). " files";

    # nothing to do?
    return if $#$aref == -1;

    # wrong site?
    if ( $site eq "icxc" ) {
	print "NOTE: you do NOT publish non XML files in the iCXC site\n";
	return;
    }

    # process the files
    foreach my $in ( @$aref ) {

	# where do we want the file copied to?
	my @dirs = ( $outdir );
##	push @dirs, $published if $published ne "";

	# copy over to the necessary directories
	# (checking for dates)
	#
	# we only print messages if not the published directory
	foreach my $odir ( @dirs ) {
	    my $out = "${odir}$in";
	    if ( $force or ! -e $out or -M "$in" < -M "$out" ) {
		mycp $in, $out;
		print "Created: $out\n" if $odir ne $published;
	    } else {
		print "skipped $in\n" if $odir ne $published;
	    }

	} # foreach: @dirs

    } # foreach @$aref

} # sub: process_files

# my $config = parse_config $filename
#
# parse the config file
# returns a reference to an associative array
#
sub parse_config ($) {
    my $infile = shift;

    dbg "Parsing config file: $infile";
    my $fh = IO::File->new( "< $infile" )
      or die "Error: unable to open the config file ($infile) for reading.\n";

    my %config = ( sites => {} );
    my $site;
    my $version;

    # the array we're currently adding to
    # can be the top level, site, or one of the version sections
    my $array = \%config;

    while ( <$fh> ) {
	# assume a simple format
	# - # or blank lines are ignored
	# - no continuation lines (ie everything on one line)
	#
	next if /^#/ or /^\s*$/;
	chomp;

	# are we exiting a site block?
	if ( /^-site/ ) {
	    die "Exiting a site block when not in one.\n"
	      unless defined $site;
	    die "Exiting a site block ($site) when version block ($version) is still open.\n"
	      if defined $version;
	    $site = undef;
	    $array = \%config;

	    next;
	}

	# are we exiting a version block?
	if ( /^-version/ ) {
	    die "Exiting a version block when not in one.\n"
	      unless defined $version;
	    $version = undef;
	    $array = $config{sites}{$site}; # drop back to the site

	    next;
	}

	# are we entering a site block?
	if ( /^\+site/ ) {
	    die "Entering a site block ('$_') when already in one for $site\n"
	      if defined $site;

	    my @words = split;
	    die "Error: expected '+site name', found '$_'\n"
	      unless $#words == 1;

	    $site = $words[1];
	    die "Error: site $site is already defined\n"
	      if exists $$array{sites}{$site};
	    $$array{sites}{$site} = { versions => {} };
	    $array = $$array{sites}{$site};

	    next;
	}

	# are we entering a version block?
	if ( /^\+version/ ) {
	    die "Entering a version block ('$_') when not in a site\n"
	      unless defined $site;
	    die "Entering a version block ('$_') when already in one for $version\n"
	      if defined $version;

	    my @words = split;
	    die "Error: expected '+version name', found '$_'\n"
	      unless $#words == 1;

	    $version = $words[1];
	    die "Error: version $version (site $site) is already defined\n"
	      if exists $$array{versions}{$version};
	    $$array{versions}{$version} = {};
	    $array = $$array{versions}{$version};

	    next;
	}

	# safety checks
	die "Error: valid line must be of the form '[\@\%]name=data' not '$_'\n"
	  unless /=/;
	die "Error: version ('$_') is not an allowed parameter\n"
	  if /^version=/;

	# now parse the input line
	#  scalar, array, hash array
	#
	my ( $key, $data ) = split "=", $_, 2;

	# array
	if ( substr($key,0,1) eq "@" ) {
	    $key = substr($key,1);

	    # check for overlap: unlike perl we don't allow scalar/array/hash
	    # values to have the same name, everything must be distinct
	    if ( exists $$array{$key} ) {
		my $ref = ref( $$array{$key} ) || "SCALAR";
		die "Error: defining an array element for $key, but it's previously\n" .
		  "been defined as a $ref\n"
		    unless $ref eq "ARRAY";
	    } else {
		$$array{$key} = [];
	    }

	    push @{ $$array{$key} }, $data;
	    next;
	}

	# associative array
	if ( substr($key,0,1) eq "%" ) {
	    $key = substr($key,1);

	    # check for overlap: unlike perl we don't allow scalar/array/hash
	    # values to have the same name, everything must be distinct
	    if ( exists $$array{$key} ) {
		my $ref = ref( $$array{$key} ) || "SCALAR";
		die "Error: defining an associative array element for $key, but it's previously\n" .
		  "been defined as a $ref\n"
		    unless $ref eq "HASH";
	    } else {
		$$array{$key} = {};
	    }

	    my ( $left, $right ) = split " ", $data, 2;
	    $$array{$key}{$left} = $right;
	    next;
	}

	# must be a scalar
	# check for overlap
	die "Error: multiple definitions for $key\n"
	  if exists $$array{$key};
	$$array{$key} = $data;

    }

    $fh->close;

    # check that that the required fields exist
    # note we do not check anything to do with the version info
    #
    my %required =
      (
       group => "SCALAR", prefix => "SCALAR",
       types => "ARRAY", stylesheets => "ARRAY",
      );
    foreach my $site ( keys %{ $config{sites} } ) {
	my $s = $config{sites}{$site};
	while ( my ( $key, $kref ) = each %required ) {
	    die "Error: the config file ($infile) did not contain a $key element for site $site\n"
	      unless exists $$s{$key};
	    my $ref = ref( $$s{$key} ) || "SCALAR";
	    die "Error: the config file ($infile) has $key as a $ref when it should be a $kref\n"
	      unless $ref eq $kref;
	}
    }

    return \%config;

} # sub: parse_config

# ( $site, $site_config ) = find_site $config, $dname;
#
# given the config 'object' and a directory name, find the
# corresponding site and its config options
#
sub find_site ($$) {
    my $config = shift;
    my $dname  = shift;

    dbg "Finding site for directory $dname";

    my @matches;
    while ( my ( $site, $href ) = each %{ $$config{sites} } ) {
	my $prefix = $$href{prefix};
	push @matches, $site
	  if substr($dname,0,length($prefix)) eq $prefix;
    }

    die "Error: unable to find a site matching the directory $dname\n"
      if $#matches == -1;
    die "Error: found multiple sites [" . join(",",@matches) . "] matching the directory $dname\n"
      if $#matches == -1;

    return ( $matches[0], $$config{sites}{$matches[0]} );

} # sub: find_site

