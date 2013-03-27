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

# most of the config stuff is parsed below, but we need these two here
my $site_config;
( $site, $site_config ) = find_site $config, $dname;
$config = undef; # DBG: just make sure no one is trying to access it
dbg "Site = $site";

check_type_known $site_config, $type;
dbg "Type = $type";

dbg "OS = $ostype";

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
my $favicon     = get_config_type $version_config, "favicon", $type;

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

# google analytics include
#
my $googlessi = "";
$googlessi = get_config_version( $version_config, "googlessi" )
  if check_config_exists( $version_config, "googlessi" );


# storage/published is optional [sort of, depends on the site]
# Moving towards using storageloc but have not completed the move
#
my $published = "";
$published = get_config_type( $version_config, "storage", $type )
  if check_config_exists( $version_config, "storage" );

my $storageloc = "";
$storageloc = get_config_type( $version_config, "storageloc", $type )
  if check_config_exists( $version_config, "storageloc" );

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
dbg "  storageloc=$storageloc";
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

die "Error: unable to find storageloc=$storageloc\n"
  unless $storageloc eq "" or -e $storageloc;

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
# TODO:
#   - remove support for hard-copy files
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
	if (-e $in) {
	    $intime = -M $in;
	} else {
	    # HACK for when the XML is created in-memory
	    # For now we assume that we can skip these pages;
	    # perhaps in this case the intie should have been
	    # sent in instead.
	    #
	    return 0;
	}
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
    foreach my $ext ( qw( log aux dvi eps tex gif gif.0 gif.1 ) ) { myrm $head . ".$ext"; }
    mysetmods $gif;
    print "\nCreated: $gif\n";

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

# Usage:
#   $num = count_slash_in_string $str
#
# returns the number of times that '/' occurs
# in $str
#
sub count_slash_in_string ($) {
  my $str = shift;
  $str =~ s/[^\/]//g;
  return length ($str);
} # count_slash_in_string

# xml2html_navbar - called by xml2html
#
# 02/13/04 - we now pass the site depth into the stylesheet
#  (since the slang directory has its own navbar we can no longer
#   assume that depth=1)
#
sub xml2html_navbar ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $dom    = $$opts{xml_dom};
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
       #depth => $depth,
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
       googlessi => $googlessi,

       storageloc => $$opts{storageloc},
      );

    $params{logoimage} = $logoimage if $logoimage ne "";
    $params{logotext}  = $logotext  if $logotext  ne "";

    # get a list of the pages: we need this so that:
    # - we can create the directory if necessary
    # - we can delete them [if they exist] before the processor runs
    #   (since we write protect them after creation so the processor
    #    can't actually create the new files)
    #
    my @pages;
    my %depths;

    # Process the dirs/dir elements of section elements that contain an id attribute
    # This is a lot simpler than the old XSLT code; it is not clear to me why
    # the old code needed that complexity (ie I think it could have used the
    # logic below). I think it's because I based it on the code used to create
    # the actual navbar's, which needed said logic.
    #
    # Hmm, now I want to calculate the depth values as well I am probably
    # going to re-introduce some of this complexity. However, it is still
    # much simpler.
    #
    my $rnode = $dom->documentElement();
    foreach my $node ($rnode->findnodes('descendant::section[boolean(@id)]')) {

      my $id = $node->findvalue('@id');
      my $tail = "navbar_${id}.incl";

      if ($node->findvalue("count(dirs/dir[.=''])!=0") eq "true") {
	push @pages, "${outdir}$tail";
	$depths{$depth} = [] unless exists $depths{$depth};
	push @{ $depths{$depth} }, $pages[-1];
      }

      foreach my $dnode ($node->findnodes("dirs/dir[.!='']")) {
	my $content = $dnode->textContent;
	$content .= "/" unless $content =~ /\/$/;

	my $ndepth = $depth + count_slash_in_string $content;

	push @pages, "${outdir}${content}$tail";
	$depths{$ndepth} = [] unless exists $depths{$ndepth};
	push @{ $depths{$ndepth} }, $pages[-1];
      }
    }

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

    # process each depth
    #
    foreach my $d (keys %depths) {
      $params{startdepth} = $depth;
      $params{depth} = $d;
      translate_file "$$opts{xslt}navbar.xsl", $dom, \%params;
    }

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
    my $dom    = $$opts{xml_dom};
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

    # how about math pages?
    #
    my @math = find_math_pages $dom;

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
       favicon => $favicon,
       newsfile => $newsfile,
       newsfileurl => $newsfileurl,
       watchouturl => $watchouturl,
       searchssi => $searchssi,
       googlessi => $googlessi,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,

       storageloc => $$opts{storageloc},
      );

    translate_file "$$opts{xslt}page.xsl", $dom, \%params;

    # success or failure?
    check_for_page( @pages );

    # math?
    process_math( $outdir, @math );

    print "\nThe page can be viewed on:\n  ${outurl}$in.html\n\n";

} # sub: xml2html_page


# xml2html_cscdb - called by xml2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
sub xml2html_cscdb ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $dom    = $$opts{xml_dom};
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

    print "Parsing [cscdb]: $in\n";

    # we 'hardcode' the output of the transformation
    my @pages = ( "${outdir}${in}.html", "${outdir}${in}_alpha.html" );

    # how about math pages?
    #
    my @math = find_math_pages $dom;

    # do we need to recreate (include the equations created by any math blocks)
    return if should_we_skip $in, @pages, map( { "${outdir}${_}.gif"; } @math );
    print "\n";

    # remove files [already ensured the dir exists]
    initialise_pages( @pages );
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
       urlhead => $outurl,
       sourcedir => cwd() . "/",
       updateby => $$opts{updateby},
       depth => $depth,
       siteversion => $site_version,
       # ahelpindex added in CIAO 3.0
       ahelpindex => $ahelpindex,
       cssfile => $css,
       cssprintfile => $cssprint,
       favicon => $favicon,
       newsfile => $newsfile,
       newsfileurl => $newsfileurl,
       watchouturl => $watchouturl,
       searchssi => $searchssi,
       googlessi => $googlessi,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,

       storageloc => $$opts{storageloc},
      );

    translate_file "$$opts{xslt}cscdb.xsl", $dom, \%params;

    # success or failure?
    check_for_page( @pages );

    # math?
    process_math( $outdir, @math );

    print "\nThe pages can be viewed at:\n  ${outurl}$in.html\n";
    print "and:\n  ${outurl}$in\_alpha.html\n\n";

} # sub: xml2html_cscdb


# xml2html_bugs - called by xml2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
sub xml2html_bugs ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $dom    = $$opts{xml_dom};
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

    # how about math pages?
    #
    my @math = find_math_pages $dom;

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
       favicon => $favicon,
       newsfile => $newsfile,
       newsfileurl => $newsfileurl,
       watchouturl => $watchouturl,
       searchssi => $searchssi,
       googlessi => $googlessi,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,

       storageloc => $$opts{storageloc},
      );

    translate_file "$$opts{xslt}bugs.xsl", $dom, \%params;

    # success or failure?
    check_for_page( @pages );

    # math?
    process_math( $outdir, @math );

    print "\nThe page can be viewed on:\n  ${outurl}$in.html\n\n";

} # sub: xml2html_bugs


# xml2html_news - called by xml2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
sub xml2html_news ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $dom    = $$opts{xml_dom};
    my $depth  = $$opts{depth};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};

    my $lastmod = $$opts{lastmod};

    print "Parsing [news]: $in";

    # we 'hardcode' the output of the transformation
    #my @pages = ( "${outdir}${in}.html" );
    my @pages = ( "${outdir}${in}.html", "${outdir}feed.xml" );

    # how about math pages?
    #
    my @math = find_math_pages $dom;

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
       outurl => $outurl,
       url => "${outurl}${in}.html",
       sourcedir => cwd() . "/",
       updateby => $$opts{updateby},
       depth => $depth,
       siteversion => $site_version,
       # ahelpindex added in CIAO 3.0
       ahelpindex => $ahelpindex,
       cssfile => $css,
       cssprintfile => $cssprint,
       favicon => $favicon,
       newsfile => $newsfile,
       newsfileurl => $newsfileurl,
       watchouturl => $watchouturl,
       searchssi => $searchssi,
       googlessi => $googlessi,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,

       storageloc => $$opts{storageloc},
      );

    translate_file "$$opts{xslt}news.xsl", $dom, \%params;

    # success or failure?
    check_for_page( @pages );

    # math?
    process_math( $outdir, @math );

    print "\nThe page can be viewed on:\n  ${outurl}$in.html\n";
    print "An updated feed was created:\n  ${outurl}feed.xml\n\n";
    
} # sub: xml2html_news


# xml2html_redirect - called by xml2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
sub xml2html_redirect ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $dom    = $$opts{xml_dom};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};

    print "Parsing [redirect]: $in";
    my $out = "${outdir}${in}.html";

    # do we need to recreate
    return if should_we_skip $in, $out;
    print "\n";

    myrm $out;

    translate_file "$$opts{xslt}redirect.xsl", $dom, { filename => $out };

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
    my $dom    = $$opts{xml_dom};
    my $outdir = $$opts{outdir};

    print "Parsing [softlink]: $in\n";

    # What are the link and target files?
    #
    foreach my $name (qw (/softlink/original /softlink/link)) {
      my $nnode = $dom->findvalue ("count($name)");
      die "Error: expected 1 $name node in $in, found $nnode\n"
	unless $nnode == 1;
    }
    my $orig = $dom->findvalue("/softlink/original");
    my $link = $dom->findvalue("/softlink/link");

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

  ## This subroutine was removed in
  ## web4/ciao42 version of publish.pl


# xml2html_relnotes - called by xml2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
sub xml2html_relnotes ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $dom    = $$opts{xml_dom};
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

    print "Parsing [relnotes]: $in";

    # we 'hardcode' the output of the transformation
    my @pages = ( "${outdir}${in}.html" );

    # how about math pages?
    #
    my @math = find_math_pages $dom;

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
       favicon => $favicon,
       newsfile => $newsfile,
       newsfileurl => $newsfileurl,
       watchouturl => $watchouturl,
       searchssi => $searchssi,
       googlessi => $googlessi,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,

       storageloc => $$opts{storageloc},
      );

    translate_file "$$opts{xslt}relnotes.xsl", $dom, \%params;

    # success or failure?
    check_for_page( @pages );

    # math?
    process_math( $outdir, @math );

    print "\nThe page can be viewed on:\n  ${outurl}$in.html\n\n";

} # sub: xml2html_relnotes


# Usage:
#   xml2html_multiple $opts, $pagename, \@sitelist;
#
# $pagename is the string used to describe the page (for screen output)
# - e.g. "faq" or "dictionary"
# more importantly, IT also must match the stylesheet name:
#    $pagename.xsl - the main stylesheet
#
# @sitelist is the list of sites that can contain this page
#
# xml2html_multiple - called by xml2html
#
# process pages that can create multiple output pages:
# e.g. faq, dictionary
#
# note: $xslt, $outdir, and $outurl end in a /
#
sub xml2html_multiple ($$$) {
    my $opts     = shift;
    my $pagename = shift;
    my $sitelist = shift;

    my $in     = $$opts{xml};
    my $dom    = $$opts{xml_dom};
    my $depth  = $$opts{depth};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};
    my $site   = $$opts{site};

    my $lastmod = $$opts{lastmod};

    # temporary
    site_check( $site, $pagename, $sitelist );

    print "Parsing [$pagename]: $in";

    my $rnode = $dom->documentElement();

    # get a list of the pages: we need this so that:
    # - we can create the directory if necessary
    # - we can delete them [if they exist] before the processor runs
    #   (since we write protect them after creation so the processor
    #    can't actually create the new files)
    #
    # I want to calculate the list of pages without calling a separate
    # stylesheet. The pages we currently expect to create are:
    #     'index.html'
    #     concat(//<nodename>/@id,'.html')
    # where <nodename> is faqentry for FAQ and entry for dictionaries
    #
    # We special case if for the dictionary_onepage case which creates
    # index.html and entries.html
    #
    my %nodename = ( dictionary => "entry", faq => "faqentry", dictionary_onepage => undef );
    die "\nNeed to update nodename mapping for multiple page style '$pagename' (publish.pl)\n"
      unless exists $nodename{$pagename};
    my @pages = ( "index.html" );

    if (defined $nodename{$pagename}) {
	push @pages, map { $_->textContent . ".html"; } $rnode->findnodes("//" . $nodename{$pagename} . "/\@id");
    } elsif ($pagename eq "dictionary_onepage") {
	push @pages, "entries.html";
    } else {
	die "\nNeed to handle an undef entry for page style '$pagename' in publish.pl\n";
    }

    my @soft = map { "${outdir}$_"; } @pages;

    # how about math pages?
    #
    my @math = find_math_pages $dom;

    # do we need to recreate
    return
      if should_we_skip $in, @soft,
	map( { "${outdir}${_}.gif"; } @math );
    print "\n";

    # create dirs/remove files
    initialise_pages( @soft );
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
       favicon => $favicon,
       newsfile => $newsfile,
       newsfileurl => $newsfileurl,
       watchouturl => $watchouturl,
       searchssi => $searchssi,
       googlessi => $googlessi,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,

       storageloc => $$opts{storageloc},
      );

    translate_file "$$opts{xslt}${pagename}.xsl", $dom, \%params;

    # check the softcopy versions
    check_for_page( @soft );

    # math?
    process_math( $outdir, @math );

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
    my $dom    = $$opts{xml_dom};
    my $depth  = $$opts{depth};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};
    my $site   = $$opts{site};

    my $lastmod = $$opts{lastmod};

    # temporary
    site_check( $site, "threadindex", [ "ciao", "sherpa", "chips", "csc", "iris" ] );

    print "Parsing [threadindex]: $in\n";

    # get a list of the pages: we need this so that:
    # - we can create the directory if necessary
    # - we can delete them [if they exist] before the processor runs
    #   (since we write protect them after creation so the processor
    #    can't actually create the new files)
    #
    my $rnode = $dom->documentElement();
    my @soft = qw ( index.html all.html );
    push @soft, map { $_->textContent . ".html"; } $rnode->findnodes('section/id/name');
    push @soft, "table.html"
      if $rnode->findvalue("boolean(datatable)") eq "true";
    @soft = map { "${outdir}$_"; } @soft;

    # do not allow math in the threadindex (for now)
    #
    my @math = find_math_pages $dom;
    die "Error: found math blocks in $in - not allowed here\n"
      unless $#math == -1;

    # NOTE: we always recreate the threadindex
    # (it just makes things easier, since the thread index pages
    # depend on so many files)
    #
    # create dirs/remove files
    initialise_pages( @soft );

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
       favicon => $favicon,
       newsfile => $newsfile,
       newsfileurl => $newsfileurl,
       watchouturl => $watchouturl,
       url => "${outurl}${in}.html",
       searchssi => $searchssi,
       googlessi => $googlessi,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,

       storageloc => $$opts{storageloc},
      );

    translate_file "$$opts{xslt}threadindex.xsl", $dom, \%params;

    # check the softcopy versions
    check_for_page( @soft );

    print "\nThe thread index pages can be viewed at:\n  $outurl\n\n";

} # sub: xml2html_threadindex

# xml2html_thread - called by xml2html
#
# Notes:
#   use site-specific stylesheets
#   $xslt, $outdir, and $outurl end in a /
#   need to copy over /thread/info/files/file entries
#   updating to support proglang tags in header which
#     indicate creation of index.<lang>.html/index.html files
#
# XXX TODO XXX
# At present we do not have language-specific versions of the
# files we copy or include - e.g. as indicated by the screen tag -
# which could need changing.
#
#
sub xml2html_thread ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $dom    = $$opts{xml_dom};
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

    print "Parsing [thread]: $threadname";

    # Find out information about this conversion
    #
    my $rnode = $dom->documentElement();

    my @html;
    my @lang;
    foreach my $node ($rnode->findnodes('info/proglang')) {
	my $lang = $node->textContent;
	$lang =~ s/^\s*//;
	$lang =~ s/\s*$//;
	$lang = lc $lang;
	die "Error: //thread/info/proglang = '$lang' is unrecognized\n"
	  unless $lang eq "sl" or $lang eq "py";
	push @lang, $lang;
    }

    # We assume that there are either 0, 1, or 2 proglang elements below,
    # and that they are unique.
    #
    die "Unexpected number of //thread/info/proglang elements in $threadname\n"
      if $#lang >= 2;
    die "Repeated //thread/info/proglang elements in $threadname\n"
      if $#lang == 1 and $lang[0] eq $lang[1];

    if ($#lang == -1) {
      push @html, "index.html";
      push @html, map { "img$_.html"; } ( 1 .. $rnode->findnodes('images/image')->size );
    } else {
      foreach my $lang ( @lang ) {
	push @html, "index.${lang}.html";
	push @html, map { "img${_}.${lang}.html"; } ( 1 .. $rnode->findnodes('images/image')->size );
      }
    }

    die "Error: no HTML files to be generated for thread=$threadname!\n"
      if $#html == -1;

    # What files need pre-processing before being included?
    #
    my @screen = map { $_->getAttribute('file'); }
      ($rnode->findnodes('text/descendant::screen[boolean(@file)]'),
       $rnode->findnodes('images/descendant::screen[boolean(@file)]'),
       $rnode->findnodes('parameters/paramfile[boolean(@file)]'));

#    my @image =
#      (
#       map { $_->getAttribute('src'); } 
#       ($rnode->findnodes('images/image'), $rnode->findnodes('text/descendant::img')),
#       map { $_->getAttribute('ps'); } $rnode->findnodes('images/image[boolean(@ps)]')
#      );
    my @image =
      map { $_->getAttribute('src'); }
	($rnode->findnodes('images/image'), $rnode->findnodes('text/descendant::img'));
    push @image,
      map { $_->getAttribute('ps'); } $rnode->findnodes('images/image[boolean(@ps)]');

    # support the new "figure" environment
    push @image,
      map { $_->textContent }
      ($rnode->findnodes('//figure/bitmap'), $rnode->findnodes('//figure/vector'));

    my @file = map { $_->textContent; } $rnode->findnodes('info/files/file');

    # Check the files exist and find which of these is the "youngest" file,
    # for use in the 'skip' check below.
    #
    my $time = -M "$in.xml";
    foreach my $name (@image, @file) {
	die "Error: thread needs file $name which does not exist\n"
	  unless -e $name;

	my $t = -M $name;
	$time = $t if $t < $time;
    }
    foreach my $head (@screen) {
	my $name = "${head}.txt";
	die "Error: thread needs file $name which does not exist\n"
	  unless -e $name;

	my $t = -M $name;
	$time = $t if $t < $time;
    }

    # how about math pages?
    #
    my @math = find_math_pages $dom;

    # do we need to recreate
    # (need to send in a reference since it's the age of
    #  the file, rather than the file itself)
    #
    # + need to add installation dir onto output file names
    #   and hack the .hard. version so that we look for the
    #   correct pdf file names (not index.[a4|letter].pdf)
    #
    # XXX TODO XXX
    #   update this to handle proglang!='', if necessary
    #
    return if should_we_skip \$time,
      map { my $a = $_; $a =~ s/index\.hard\.html$/$threadname.hard.html/; "${outdir}$a"; } @html,
	map( { "${outdir}${_}.gif"; } @math );
    print "\n";

    print "  install to: $outdir\n";

    # convert the text file into XML format
    # (it will be included by the main transformation)
    #
    # For now we assume we do not need language-specific versions,
    # but this could change.
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

    # Note that threads contain their own history block, and we use that
    # to create the last modified date, rather than send one in.
    #
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
       favicon => $favicon,
       newsfile => $newsfile,
       newsfileurl => $newsfileurl,
       watchouturl => $watchouturl,
       url => "${outurl}${in}.html",
       searchssi => $searchssi,
       googlessi => $googlessi,
       headtitlepostfix => $headtitlepostfix,
       texttitlepostfix => $texttitlepostfix,
       # currently imglinkicon/... are always set [since we define
       # a default value above if they are not specified]. This may
       # change ?
       imglinkicon => $imglinkicon,
       imglinkiconwidth => $imglinkiconwidth,
       imglinkiconheight => $imglinkiconheight,

       storageloc => $$opts{storageloc},
      );

    # Safety check: ensure all restrict attributes are set to sl or py
    #
    my @fails = $rnode->findnodes('//@restrict[. != "sl" and . != "py"]');
    die "ERROR: thread=$threadname restrict attribute can only be 'sl' or 'py', not:\n\t" .
      join (" ", map { $_->textContent; } @fails ) . "\n"
	unless $#fails == -1;

    # Hack to avoid translate_file_langs having to know the xslt path
    # (not a very good idea)
    #
    preload_stylesheet "$$opts{xslt}strip_proglang.xsl", "strip_proglang.xsl";
    translate_file "$$opts{xslt}${site}_thread.xsl", $dom, \%params;

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

    # delete the converted screen files
    #
    foreach my $page ( @screen ) { myrm "$page.xml"; }

    # No langauge support? We can leave now.
    #
    if ($#lang == -1) {
      print "\nThe thread can be viewed at:\n  $outurl\n\n";
      return;
    }

    # If proglang != '' then we need an index.html file. Its contents
    # depend on whether there are one or two languages to be created.
    # We create either a redirect or page DOM and then treat it as
    # a separate document. We could create it manually via DOM
    # manipulation but it's easier to create it as a string.
    #
    # Copy over the options we were sent in. We explicitly override
    # some of these values below. Hopefully the presence of the rest
    # will not be a problem.
    #
    my %nopts;
    while ( my ($key, $value) = each %$opts ) {
      $nopts{$key} = $value;
    }

    my $xml_text = <<'EOX';
<?xml version="1.0" encoding="utf-8"?>
EOX

    my $process;
    my $infostr;
    if ( $#lang == 0 ) {
      # simple redirect
      #
      $infostr = "redirect";
      $process = \&xml2html_redirect;
      my $lang = $lang[0];
      $xml_text .= <<"EOX";
<!DOCTYPE redirect>
<redirect><to>index.$lang.html</to></redirect>
EOX
    } else {
      # a page offering a choice
      #
      $infostr = "page";
      $process = \&xml2html_page;

      # Ugly, as not clear what rules the threads use.
      #
      my $has_title_long  = $rnode->findvalue('boolean(info/title/long)') eq "true";
      my $has_title_short = $rnode->findvalue('boolean(info/title/short)') eq "true";

      die "ERROR: thread '$in' is missing both /thread/info/title/long and /thread/info/title/short\n"
	if $has_title_long == 0 and $has_title_short == 0;

      my $thread_title_long  = $has_title_long ? $rnode->findvalue('info/title/long') : "";
      my $thread_title_short = $has_title_short ? $rnode->findvalue('info/title/short') : "";

      $thread_title_long  = $thread_title_short if $thread_title_long eq "";
      $thread_title_short = $thread_title_long  if $thread_title_short eq "";

      my $thread_page_string;
      if ($site eq "pog" or $site eq "chart") {
        $thread_page_string = "or return to <cxclink href=\"../\">the Threads Page<\/cxclink>";
      } else {
	$thread_page_string = "or return to the Threads Page: <cxclink href=\"../\">Top<\/cxclink> | <cxclink href=\"../all.html\">All<\/cxclink>";
      }       

      # For now no navbar or meta information
      #
      $xml_text .= <<"EOX";
<!DOCTYPE page>
<page>
<info>
 <title><short>${thread_title_short}: S-Lang or Python?</short></title>
</info>
<text>
<p>Please choose the S-Lang or Python version of the thread
"${thread_title_long}":</p>
<list>
 <li><cxclink href="index.sl.html">S-Lang</cxclink></li>
 <li><cxclink href="index.py.html">Python</cxclink></li>
</list>

<p>${thread_page_string}</p>

</text>
</page>
EOX
    }
    $nopts{xml} = "index";
    $nopts{xml_dom} = read_xml_string $xml_text;
    dbg "-- about to create index page for multi-language thread with root=$infostr";

##use Data::Dumper; print Dumper \%nopts; die;

    &$process (\%nopts);

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
	   xml => $in,
	   depth => $depth,
	   dirname => $thisdir,
	   navbar_link => $navbar_link,
	   site => $site, type => $type, xslt => $stylesheets,
	   outdir => $outdir, outurl => $outurl,
	   store => $published,
	   storageloc => $storageloc,
	   updateby => $uname,
	   version => $version,
	   headtitlepostfix => $headtitlepostfix,
	   texttitlepostfix => $texttitlepostfix,
	  };

	# what is the name of the root node and is this
	# file not intended only type=live?
	#
	my $dom      = read_xml_file $in;
	my $droot    = $dom->documentElement();
	my $root     = $droot->nodeName;
	my $testonly = $droot->findvalue("count(info/testonly) != 0");

	# skip if we're live publishing
	if ( $type eq "live" and $testonly eq "true" ) {
	    print "The page $in [type $root] has been marked as for the test site only\n\n";
	    next;
	}

	$$opts{xml_dom} = $dom;

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
	} elsif ( $root eq "news" ) {
	    xml2html_news $opts;
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
	    die "Sorry, cannot process 'register' pages with this version of publish.pl.\nUse /data/da/Docs/web4/ciao4/publish.pl\n"
	} elsif ( $root eq "faq" ) {
	    die_if_icxc $root;
	    xml2html_multiple $opts, "faq", [ "ciao", "sherpa", "chips", "csc", "iris" ];
	} elsif ( $root eq "dictionary" ) {
	    die_if_icxc $root;
	    xml2html_multiple $opts, "dictionary", [ "ciao" ];
	} elsif ( $root eq "dictionary_onepage" ) {
	    die_if_icxc $root;
	    xml2html_multiple $opts, "dictionary_onepage", [ "csc" ];
	} elsif ( $root eq "cxchelptopics" ) {
	    die_if_icxc $root;
	    die "Error: ahelp files should be processed using the --ahelp option\n";
	} elsif ( $root eq "cscdb" ) {
	    die_if_icxc $root;
	    xml2html_cscdb $opts;
	} elsif ( $root eq "relnotes" ) {
	    die_if_icxc $root;
	    xml2html_relnotes $opts;
	} else {
	  # We have some "non-publishing" XML files on iCXC (they are used
	  # to create other XML files that can be published), so skip them
	  #.
	  if ($site eq "icxc") {
	    print "Skipping $in.xml has it has an unknown root node [$root]\n";
	  } else {
	    die "Error: $in.xml has an unknown root node [$root]\n";
	  }
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
# NOTE: we no longer copy the files over to the storage site
# to save space
#
sub process_files ($$) {
    my $type = shift;
    my $aref = shift;
    dbg "processing " . (1+$#$aref). " files";

    # nothing to do?
    return if $#$aref == -1;

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


