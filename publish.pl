#!/data/da/Docs/local/perl/bin/perl -w
#
# Usage:
#   publish.pl --type=test|live|trial <filename(s)>
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
#     Oct 03 DJB Some functionality moved to CIAODOC.pm
#                Removed ahelp page creation (the --ahelp flag)
#  26 Jan 04 DJB Changes to handle the new ahelp generation system
#                [still rough around the edges]
#  13 Feb 04 DJB navbar fixes to allow navbar not in top-level (sent in depth)
#                send in headtitlepostfix for extra text in HTML title attributes
#                send in texttitlepostfix for extra text in headers
#                code cleanup: moved some common code to subroutines including
#                made faq/dictionary handling use the same code
#  19 Apr 04 DJB send in imglinkicon,imglinkiconwidth,imglinkiconheight
#                for image info to use when linking to "images" in threads.
#                Previosly they were hard-coded.
#  11 May 04 DJB we no longer need to create a 'hacked' navbar for download
#                pages
#  14 May 04 DJB separate out production of soft and hard-copy versions of:
#                  page threadindex thread register multiple[faq/dictionary]
#                will be much better once we can drop the 'hardcopy' format
#                entirely
#  24 May 06 ECG added xml2html_bugs section
#  19 Jun 06 ECG math2gif looking for "$head.gif.0", but convert now creates
#                "$head.gif" 
#  1.102 20070911 ecg - don't run "check_config_exists" on "number" for the 
#                 caldb site 
#  12 Oct 07 DJB Removed ldpath/htmllib env vars
#  15 Oct 07 DJB executables are now OS specific
#  17 Oct 07 DJB removed xsltproc global variable as no longer needed
#
 
use strict;
$|++;

use Getopt::Long;
use FindBin;

use Cwd;
use IO::File;
use IO::Pipe;

use lib $FindBin::Bin;
use CIAODOC qw( :util :xslt :cfg );

## Subroutines (see end of file)
#

sub process_xml   ($$);
sub process_files ($$);

## set up variables that are also used in CIAODOC
use vars qw( $configfile $verbose $group $htmldoc $site );
$configfile = "$FindBin::Bin/config.dat";
$verbose = 0;
$group = "";
$htmldoc = "";
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
  $progname --config=name --type=test|live|trial <filename(s)>

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
my $force = 0;
die $usage unless
  GetOptions
  'config=s' => \$configfile,
  'type=s'   => \$type,
  'force!'   => \$force,
  'verbose!' => \$verbose;

# what OS are we running?
#
my $ostype = get_ostype;

# check the options
die "Error: the config option can not be blank\n"
  if $configfile eq "";
my $config = parse_config( $configfile );

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

# check usage
#
die $usage if $#ARGV == -1;

# Handle the remaining config values
#
# shouldn't have so many global variables...
#
$group = get_group $site_config;
my ( $version, $version_config, $dhead, $depth ) = check_location $site_config, $dname;

# used to let a page know it's "name" as it is likely to be specified
# in the navbar (and hence so that it can be highlighted using CSS)
#
# see add-htmlhead in helper.xsl - we don't actually use this at the
# moment since it's not clear how to handle all situations
#
my $navbar_link = '../'x($depth-1) . $dhead;
$navbar_link = "index.html" if $navbar_link eq "";

my $stylesheets = get_config_type $version_config, "stylesheets", $type;
my $outdir      = get_config_type $version_config, "outdir", $type;
my $outurl      = get_config_type $version_config, "outurl", $type;

my $css         = get_config_type $version_config, "css", $type;
my $cssprint    = get_config_type $version_config, "cssprint", $type;

# get the site version
my $site_version = "";

if ( ! ($site =~ /caldb/)) {
    if (check_config_exists( $version_config, "number" )){
	$site_version = get_config_version( $version_config, "number" );
    } else {
	die "Error: version $version in the config file ($configfile) does not contain the number parameter\n";
    }
} 

# as is this
# - since we do send these to the processor then we can not let them
#   default to "" since that will cause problems (it will get lost
#   in the shell expansion and so mess up everything). So we use the
#   string "dummy" which is checked for in the stylesheet
#
# - with the current set of "config" routines this isn't particularly pretty
#
my $newsfile = "dummy";
$newsfile = get_config_type( $version_config, "newsfile", $type )
  if check_config_exists( $version_config, "newsfile" );

my $newsfileurl = "dummy";
$newsfileurl = get_config_type( $version_config, "newsurl", $type )
  if check_config_exists( $version_config, "newsurl" );

# note: no "dummy" here (can't remember if that's important for the stylesheets)
#
my $watchouturl = "";
$watchouturl = get_config_type( $version_config, "watchouturl", $type )
  if check_config_exists( $version_config, "watchouturl" );

my $searchssi = "/incl/search.html";
$searchssi = get_config_type( $version_config, "searchssi", $type )
  if check_config_exists( $version_config, "searchssi" );

# storage/published is optional [sort of, depends on the site]
#
my $published = "";
$published = get_config_type( $version_config, "storage", $type )
  if check_config_exists( $version_config, "storage" );

# set up the ahelp index file based on the storeage location
#
my $ahelpindexdir = "";
$ahelpindexdir = get_config_type( $version_config, "ahelpindexdir", $type )
  if check_config_exists( $version_config, "ahelpindexdir" );

# logo image/text is also optional
# - only needed for navbar pages
#
my $logoimage = "";
my $logotext = "";
$logoimage = get_config_version( $version_config, "logoimage" )
  if check_config_exists( $version_config, "logoimage" );
$logotext = get_config_version( $version_config, "logotext" )
  if check_config_exists( $version_config, "logotext" );

# the following are only useful for threads: they
# define the image to add at the end of links to 'images'
# [which should probably go away]
#
my $imglinkicon       = "imgs/imageicon.gif";
my $imglinkiconwidth  = 30;
my $imglinkiconheight = 30;

$imglinkicon = get_config_version( $version_config, "imglinkicon" )
  if check_config_exists( $version_config, "imglinkicon" );
$imglinkiconwidth = get_config_version( $version_config, "imglinkiconwidth" )
  if check_config_exists( $version_config, "imglinkiconwidth" );
$imglinkiconheight = get_config_version( $version_config, "imglinkiconheight" )
  if check_config_exists( $version_config, "imglinkiconheight" );

# optional
#
my $headtitlepostfix = "";
my $texttitlepostfix = "";
$headtitlepostfix = get_config_version( $version_config, "headtitlepostfix" )
  if check_config_exists( $version_config, "headtitlepostfix" );
$texttitlepostfix = get_config_version( $version_config, "texttitlepostfix" )
  if check_config_exists( $version_config, "texttitlepostfix" );

# add on our current working directory
$outdir    .= $dhead;
$outurl    .= $dhead;
$published .= $dhead unless $published eq "";

# check for the stylesheets (just in case)
foreach my $xslt ( @{ get_config_site( $site_config, "stylesheets" ) } ) {
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
dbg "  ahelpindexdir=$ahelpindexdir";
dbg "  version=$site_version";
dbg "  css=$css";
dbg "  newsfile=$newsfile";
dbg "  newsfileurl=$newsfileurl";
dbg "  watchouturl=$watchouturl";
dbg "  searchssi=$searchssi";
dbg "  logoimage=$logoimage";
dbg "  logotext=$logotext";
dbg "  imglinkicon=$imglinkicon [$imglinkiconwidth x $imglinkiconheight]";
dbg "  headtitlepostfix=$headtitlepostfix";
dbg "  texttitlepostfix=$texttitlepostfix";
dbg "*** CONFIG DATA ***";

# Handle the ahelpindex file
#
my $ahelpindex = "${ahelpindexdir}ahelpindex.xml";
die "Error: can not find ahelpindex file - check config file for\n  ahelpindexdir=$ahelpindexdir\n"
  unless "" eq $ahelpindexdir or -e $ahelpindex;

# Get the list of files to work on
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
      unless -e "$head.gif";
    system "cp", "$head.gif", $gif;

    # clean up and return
    foreach my $ext ( qw( log aux dvi eps tex gif.0 gif.1 ) ) { myrm $head . ".$ext"; }
    mysetmods $gif;
    print "Created: $gif\n";

} # sub: math2gif()

# can we publish this page for this site?
#
sub site_check ($$$) {
    my ( $site, $label, $ok ) = @_;
    my %ok = map { ($_,1); } @{$ok};
    die "Error: currently can only convert $label pages in site=" . join(",",@{$ok}) . "\n"
      unless exists $ok{$site};
} # sub: site_check

# Usage:
#   initialise_pages( $page1, ..., $pageN );
#
# Aim:
#   Ensures the directories exist for these pages
#   and then deletes any current version of the
#   page
#
sub initialise_pages {
    foreach my $page ( @_ ) {
	my $dir = $page;
	$dir =~ s/\/[^\/]+.html$//;
	mymkdir $dir;
	myrm $page;
    }
} # sub: initialise_pages()

# Usage:
#   check_for_page( @soft );
#
# Aim:
#  checks that the transformation created the necessary
#  pages AND sets the correct permission/group
#
sub check_for_page {
    foreach my $page ( @_ ) {
	die "Error: transformation did not create $page\n"
	  unless -e $page;
	mysetmods $page;
	print "Created: $page\n";
    }
} # sub: check_for_page()

#
# Usage:
#   clean_up_math( $outdir, $page1, ..., $pageN );
#
# Aim:
#   ensures none of the files that will be needed to support the math
#   tag are present
#
sub clean_up_math {
    my $outdir = shift;
    foreach my $page ( @_ ) {
	myrm "${page}.tex";
	myrm "${page}.aux";
	myrm "${page}.log";
	myrm "${page}.dvi";
	myrm "${page}.eps";
	myrm "${outdir}${page}.gif";
    }
} # clean_up_math()

#
# Usage:
#   process_math( $outdir, $page1, ..., $pageN );
#
# Aim:
#   Creates the GIF images
#
sub process_math {
    my $outdir = shift;
    foreach my $page ( @_ ) { math2gif $page, "${outdir}${page}.gif"; }
} # process_math()

# xml2html_navbar - called by xml2html
#
# 02/13/04 - we now pass the site depth into the stylesheet
#  (since the slang directory has its own navbar we can no longer
#   assume that depth=1)
#
sub xml2html_navbar ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $depth  = $$opts{depth};
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

    my %params = 
      (
	  type => $$opts{type},
	  site => $$opts{site},
          depth => $depth,
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
      );

    $params{logoimage} = $logoimage if $logoimage ne "";
    $params{logotext}  = $logotext  if $logotext  ne "";

    # get a list of the pages: we need this so that:
    # - we can create the directory if necessary
    # - we can delete them [if they exist] before the processor runs
    #   (since we write protect them after creation so the processor
    #    can't actually create the new files)
    #
    my $pages = translate_file "$$opts{xslt}list_navbar.xsl", $in, \%params;
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
    translate_file "$$opts{xslt}navbar.xsl", $in, \%params;

    foreach my $page ( @pages ) {
	die "Error: transformation did not create $page\n"
	  unless -e $page;

	# hack the page to remove the leading '<!DOCTYPE ...' link
	# (first 2 lines)
	#
	my $ifh = IO::File->new( "< $page" ) or
	  die "ERROR: Unable to read from $page\n";
	my @in = <$ifh>;
	$ifh->close;

	shift @in;
	shift @in;

	my $ofh = IO::File->new( "> $page" ) or
	  die "ERROR: Unable to write to $page\n";
	$ofh->print( $_ ) for @in;
	$ofh->close;

	mysetmods $page;
	print "Created: $page\n";

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

    my $lastmod = $$opts{lastmod};

    # the navbarlink is currently not used by the code
    # - see the comments in helper.xsl
    # - note that I do not believe $nlink is set to
    #   a sensible value by the following !!
#    my $nlink = $$opts{navbar_link};
#    $nlink .= "${in}.html" unless $in eq "index";

    print "Parsing [page]: $in";

    # we 'hardcode' the output of the transformation
    my @pages = ( "${outdir}${in}.html" );
    push @pages, "${outdir}${in}.hard.html" unless $site eq "icxc";

    # how about math pages?
    #
    my $math = translate_file "$$opts{xslt}list_math.xsl", $in;
    my @math = split " ", $math;

    # do we need to recreate (include the equations created by any math blocks)
    return if should_we_skip $in, @pages, map( { "${outdir}${_}.gif"; } @math );
    print "\n";

    # remove files [already ensured the dir exists]
    foreach my $page ( @pages ) { myrm $page; }
    clean_up_math( $outdir, @math );

    # used to set up the list of parameters sent to the
    # stylesheet
    #
    my %params =
      (
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
       cssprintfile => $cssprint,
       newsfile => $newsfile,
       newsfileurl => $newsfileurl,
       watchouturl => $watchouturl,
       searchssi => $searchssi,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,
      );

    # what 'hardcopy' values do we loop through?
    #
    my @hardcopy = ( 0 );
    push @hardcopy, 1 unless $site eq "icxc";

    translate_file_hardcopy "$$opts{xslt}page.xsl", $in, \%params, \@hardcopy;

    # success or failure?
    check_for_page( @pages );

    # math?
    process_math( $outdir, @math );

    # create the hardcopy pages
    #
    create_hardcopy $outdir, $in unless $site eq "icxc";

    print "\nThe page can be viewed on:\n  ${outurl}$in.html\n\n";

} # sub: xml2html_page

# xml2html_bugs - called by xml2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
sub xml2html_bugs ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $depth  = $$opts{depth};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};

    my $lastmod = $$opts{lastmod};

    # the navbarlink is currently not used by the code
    # - see the comments in helper.xsl
    # - note that I do not believe $nlink is set to
    #   a sensible value by the following !!
#    my $nlink = $$opts{navbar_link};
#    $nlink .= "${in}.html" unless $in eq "index";

    print "Parsing [bugs]: $in";

    # we 'hardcode' the output of the transformation
    my @pages = ( "${outdir}${in}.html" );
    push @pages, "${outdir}${in}.hard.html" unless $site eq "icxc";

    # how about math pages?
    #
    my $math = translate_file "$$opts{xslt}list_math.xsl", $in;
    my @math = split " ", $math;

    # do we need to recreate (include the equations created by any math blocks)
    return if should_we_skip $in, @pages, map( { "${outdir}${_}.gif"; } @math );
    print "\n";

    # remove files [already ensured the dir exists]
    foreach my $page ( @pages ) { myrm $page; }
    clean_up_math( $outdir, @math );

    # used to set up the list of parameters sent to the
    # stylesheet
    #
    my %params =
      (
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
       cssprintfile => $cssprint,
       newsfile => $newsfile,
       newsfileurl => $newsfileurl,
       watchouturl => $watchouturl,
       searchssi => $searchssi,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,
      );

    # what 'hardcopy' values do we loop through?
    #
    my @hardcopy = ( 0 );
    push @hardcopy, 1 unless $site eq "icxc";

    translate_file_hardcopy "$$opts{xslt}bugs.xsl", $in, \%params, \@hardcopy;

    # success or failure?
    check_for_page( @pages );

    # math?
    process_math( $outdir, @math );

    # create the hardcopy pages
    #
    create_hardcopy $outdir, $in unless $site eq "icxc";

    print "\nThe page can be viewed on:\n  ${outurl}$in.html\n\n";

} # sub: xml2html_bugs

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

    translate_file "$$opts{xslt}redirect.xsl", $in, { filename => $out };

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
    my $pages = translate_file "$$opts{xslt}list_softlink.xsl", $in;
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

    my $lastmod = $$opts{lastmod};

    print "Parsing [register]: $in";

    # we 'hardcode' the output of the transformation
    # (as of CIAO 3.1 it is rather simple)
    #
    my @pages = map { "${outdir}${in}$_"; } qw( _src.html .hard.html );

    # check for math blocks (can't be bothered to handle in register blocks)
    #
    my $math = translate_file "$$opts{xslt}list_math.xsl", $in;
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

    my %params =
      (
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
       cssprintfile => $cssprint,
       newsfile => $newsfile,
       newsfileurl => $newsfileurl,
       watchouturl => $watchouturl,
       searchssi => $searchssi,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,
      );

    # we used to have register.xsl and register_live.xsl but
    # we no longer need to create so-many different versions
    # as of CIAO 3.1
    #
    translate_file_hardcopy "$$opts{xslt}register_live.xsl", $in, \%params;

    # success or failure?
    check_for_page( @pages );

    # create the hardcopy pages
    create_hardcopy $outdir, $in;

    print "\nThe pages can be viewed on:\n  ${outurl}${in}_src.html\n\n";

} # sub: xml2html_register

# Usage:
#   xml2html_multiple $opts, $pagename, \@sitelist;
#
# $pagename is the string used to describe the page (for screen output)
# - e.g. "faq" or "dictionary"
# more importantly, IT also must match the stylesheet names:
#    $pagename.xsl - the main stylesheet
#    list_$pagename.xsl - prints out the pages that are created
#
# @sitelist is the list of sites that can contain this page
#
# xml2html_multiple - called by xml2html
#
# process pages thaty create multiple output pages:
# e.g. faq, dictionary
#
# note: $xslt, $outdir, and $outurl end in a /
#
sub xml2html_multiple ($$$) {
    my $opts     = shift;
    my $pagename = shift;
    my $sitelist = shift;

    my $in     = $$opts{xml};
    my $depth  = $$opts{depth};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};
    my $site   = $$opts{site};

    my $lastmod = $$opts{lastmod};

    # temporary
    site_check( $site, $pagename, $sitelist );

    print "Parsing [$pagename]: $in";

    # get a list of the pages: we need this so that:
    # - we can create the directory if necessary
    # - we can delete them [if they exist] before the processor runs
    #   (since we write protect them after creation so the processor
    #    can't actually create the new files)
    #
    my $pages = translate_file "$$opts{xslt}list_${pagename}.xsl", $in;
    $pages =~ s/\s+/ /g;
    my @soft = map { "${outdir}$_"; }split " ", $pages;
    my @hard = map { my $a = $_; $a =~ s/\.html$/.hard.html/; $a; } @soft;

    # how about math pages?
    #
    my $math = translate_file "$$opts{xslt}list_math.xsl", $in;
    my @math = split " ", $math;

    # do we need to recreate
    return
      if should_we_skip $in, @soft, @hard,
	map( { "${outdir}${_}.gif"; } @math );
    print "\n";

    # create dirs/remove files
    initialise_pages( @soft, @hard );
    clean_up_math( $outdir, @math );

    my %params =
      (
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
       cssprintfile => $cssprint,
       newsfile => $newsfile,
       newsfileurl => $newsfileurl,
       watchouturl => $watchouturl,
       searchssi => $searchssi,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,
      );

    translate_file_hardcopy "$$opts{xslt}${pagename}.xsl", $in, \%params;

    # check the softcopy versions
    check_for_page( @soft );

    # math?
    process_math( $outdir, @math );

    # create the hardcopy pages
    foreach my $page ( @hard ) {
	die "Error: transformation did not create $page\n"
	  unless -e $page;
	mysetmods $page;
	$page =~ s/^.+\/([^\/]+).hard.html$/$1/;
	create_hardcopy $outdir, $page;
    }

    print "\nThe $pagename page can be viewed at:\n  $outurl\n\n";

} # sub: xml2html_multiple

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

    my $lastmod = $$opts{lastmod};

    # temporary
    site_check( $site, "threadindex", [ "ciao", "sherpa", "chips" ] );

    print "Parsing [threadindex]: $in\n";

    # get a list of the pages: we need this so that:
    # - we can create the directory if necessary
    # - we can delete them [if they exist] before the processor runs
    #   (since we write protect them after creation so the processor
    #    can't actually create the new files)
    # - note: I'm too lazy to add the hardcopy versions to list_threadindex.xsl
    # - note: the list of names returned by this stylesheet does not
    #         include the installation directory
    #
    my $pages = translate_file "$$opts{xslt}list_threadindex.xsl", $in;
    $pages =~ s/\s+/ /g;
    my @soft = map { "${outdir}$_"; } split " ", $pages;
    my @hard = map { my $a = $_; $a =~ s/\.html$/.hard.html/; $a; } @soft;

    # do not allow math in the threadindex (for now)
    #
    my $math = translate_file "$$opts{xslt}list_math.xsl", $in;
    my @math = split " ", $math;
    die "Error: found math blocks in $in - not allowed here\n"
      unless $#math == -1;

    # NOTE: we always recreate the threadindex
    # (it just makes things easier, since the thread index pages
    # depend on so many files)
    #
    # create dirs/remove files
    initialise_pages( @soft, @hard );

    my %params =
      (
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
       cssprintfile => $cssprint,
       newsfile => $newsfile,
       newsfileurl => $newsfileurl,
       watchouturl => $watchouturl,
       searchssi => $searchssi,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,
      );

    translate_file_hardcopy "$$opts{xslt}threadindex.xsl", $in, \%params;

    # check the softcopy versions
    check_for_page( @soft );

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

    # find out information about this conversion
    #
    my $list_files = translate_file "$$opts{xslt}list_thread.xsl", $in;

    # split the list up into sections: html, image, screen, and file
    #
    # we also want to find out which of these is the "youngest" file
    # for use in the 'skip' check below
    #
    my $time = -M "$in.xml";

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
    my $math = translate_file "$$opts{xslt}list_math.xsl", $in;
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
    clean_up_math( $outdir, @math );

    my %params =
      (
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
       cssprintfile => $cssprint,
       newsfile => $newsfile,
       newsfileurl => $newsfileurl,
       watchouturl => $watchouturl,
       searchssi => $searchssi,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,
       # currently imglinkicon/... are always set [since we define
       # a default value above if they are not specified]. This may
       # change ?
       imglinkicon => $imglinkicon,
       imglinkiconwidth => $imglinkiconwidth,
       imglinkiconheight => $imglinkiconheight,
      );

    translate_file_hardcopy "$$opts{xslt}${site}_thread.xsl", $in, \%params;

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
    process_math( $outdir, @math );

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
# dies if the site (global variable $site) is equal
# to icxc
#
sub die_if_icxc ($) {
    my $root = shift;
    die "Error: can not publish '$root' type documents on the iCXC site\n"
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

    # what directory are we in?
    # - some conversions (probably only for threads) need to know this
    #
    my $thisdir = ( split( "/", getcwd() ) ) [-1];

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
	   dirname => $thisdir,
	   navbar_link => $navbar_link,
	   site => $site, type => $type, xslt => $stylesheets,
	   outdir => $outdir, outurl => $outurl,
	   store => $published,
	   updateby => $uname,
	   version => $version,
	   headtitlepostfix => $headtitlepostfix,
	   texttitlepostfix => $texttitlepostfix,
	  };

	# what is the name of the root node?
	# (plus we also check for the presence of the /*/info/testonly tag here)
	#
	# This would be better done using XML::LibXML, but if so can we
	# then pass the dom around instead of the filename?
	#
	my $roots = translate_file "${stylesheets}list_root_node.xsl", $in;
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
	} elsif ( $root eq "bugs" ) {
	    xml2html_bugs $opts;
	} elsif ( $root eq "redirect" ) {
	    ##die_if_icxc $root;
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
	    xml2html_multiple $opts, "faq", [ "ciao", "sherpa", "chips" ];
	} elsif ( $root eq "dictionary" ) {
	    die_if_icxc $root;
	    xml2html_multiple $opts, "dictionary", [ "ciao" ];
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


