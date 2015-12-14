#!/usr/bin/env perl -w
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
#     --forceforce
#     Optional.
#
#     --verbose
#     Turn on screen output that's only useful for testing/debugging
#
#     --localxslt
#     Replace the %stylesheets directive in the config file with
#     the location of this script (for testing purposes)
#
#     --ignore-missing
#     Ignore missing links (i.e. let the page publish with a warning
#     rather than error out). The contents of the link may contain
#     place-holder text.
#
#   by default will not create HTML files if they already exist
#   and are newer than the XML file (also checks for other
#   associated files and the created PDF files).
#   Use the --force option to force the creation of the HTML files.
#   [note: the thread index pages are currently ALWAYS created].
#   Use --forceforce to force the copying on non XML files
#   [note: implies --force]
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
# Creates:
#   The location of the output HTML (and possibly PDF) files
#   is defined by the contents of the config file you supply with the
#   --config option
#
# Requires:
#   The location searched for the stylesheets is defined
#   in the config file, as are the actual stylesheets needed,
#   unless the --localxslt flag is used to override this.
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
use CIAODOC qw( :util :xslt :cfg :deps );

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
file). Non XML files are *not* copied when --force is given if
they have not changed.

The --forceforce option is used to also force the copying of
non XML files, even if they have not changed. Setting this also
sets --force.

The --verbose option is useful for testing/debugging the code.

The --localxslt option overides the \%stylesheets directive in the
config file to use the location of $progname instead.

The --ignore-missing option is used to avoid circular dependencies
when publishing pages: i.e. if page a needs info from page b, but
page b needs info from page a. This is experimental and should be
carefully, and rarely, used. One consequence is that the output may
contain place-holder text.

EOD

# this will be mangled later
my $dname = cwd();

# handle options
my $type = "test";
my $force = 0;
my $forceforce = 0;
my $localxslt = 0;
my $ignoremissinglink = 0;
die $usage unless
  GetOptions
  'config=s' => \$configfile,
  'type=s'   => \$type,
  'force!'   => \$force,
  'forceforce!'   => \$forceforce,
  'localxslt!' => \$localxslt,
  'ignore-missing!' => \$ignoremissinglink,
  'verbose!' => \$verbose;

$force = 1 if $forceforce;

$ignoremissinglink = $ignoremissinglink ? "yes" : "no";

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

if ($localxslt) {
    dbg "Overriding stylesheets setting: from $stylesheets to $FindBin::Bin/";
    $stylesheets = "$FindBin::Bin/";
}

if ($ignoremissinglink) {
    dbg "Stylesheets will not error out if missing links/info are found.";
}

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

# MathJax
my $mathjaxpath = "";
$mathjaxpath = get_config_type( $version_config, "mathjaxpath", $type )
  if check_config_exists( $version_config, "mathjaxpath" );

# storage/published is optional [sort of, depends on the site]
#
my $storageloc = "";
$storageloc = get_config_type( $version_config, "storageloc", $type )
  if check_config_exists( $version_config, "storageloc" );

my $published = "";
$published = get_storage_location($storageloc, $site)
  unless $storageloc eq "";

# set up the ahelp index file based on the storeage location
#
my $ahelpindexdir = "";
$ahelpindexdir = get_config_type( $version_config, "ahelpindexdir", $type )
  if check_config_exists( $version_config, "ahelpindexdir" );

# logo image/text/url is also optional
# - only needed for navbar pages
#
my $logoimage = "";
my $logotext = "";
my $logourl = "";
$logoimage = get_config_version( $version_config, "logoimage" )
  if check_config_exists( $version_config, "logoimage" );
$logotext = get_config_version( $version_config, "logotext" )
  if check_config_exists( $version_config, "logotext" );
$logourl = get_config_version( $version_config, "logourl" )
  if check_config_exists( $version_config, "logourl" );

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
dbg "  ignoremissinglink=$ignoremissinglink";
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
dbg "  mathjaxpath=$mathjaxpath";
dbg "  logoimage=$logoimage";
dbg "  logotext=$logotext";
dbg "  logourl=$logourl";
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
# - skip directories and any file ending in ",v" or "~"
#
foreach my $in ( map { s/\.xml$//; $_; } @ARGV ) {
    # for some reason I am suddenly seeing empty values of $in, so skip them
    # (rather than work out where they are coming from)
    next unless $in;

    if ( -d $in ) {
	print "skipping directory $in\n";
	next;
    }

    if ( $in =~ /,v$/ ) {
	print "skipping $in as ends in ,v so taken to be RCS file\n";
	next;
    }

    if ( $in =~ /~$/ ) {
	print "skipping $in as ends in ~ so taken to be an emacs backup file\n";
	next;
    }

    if ( -e "${in}.xml" ) { push @xml, $in; }
    elsif ( -e $in )      { push @nonxml, $in; }
    else                  { die "Error: Unable to find in=$in\n"; }

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
	if (-e $in) {
	    $intime = -M $in;
	} else {
	    # HACK for when the XML is created in-memory
	    # For now we assume that we can skip these pages;
	    # perhaps in this case the intime should have been
	    # sent in instead.
	    #
	    return 0;
	}
    }

    foreach my $file ( @files ) {
	return 0
	    unless -e $file and -M $file < $intime;
    } # foreach: @files

    # if got this far the file's for skipping
    print "\tskipping\n";
    return 1;

} # should_we_skip()

# math2image $head, $outfile
#
# convert trhe equation sotred in the file $head.tex
# into an image called $outfile, sets its protections
#
# then delete $tex
#
# NOTE: this is based on text2im v1.5
#
# NOTE: this code is not needed when using MathJax.
#
sub math2image ($$) {
    return if use_mathjax;

    my $head    = shift;
    my $outfile = shift;
    my $tex     = $head . ".tex";

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

    # and now the output file
    system "convert", "+adjoin", "-density", "150x150", "$head.eps", "$head.png"
      and die "Error: unable to convert to PNG\n";

    die "Error: PNG for equation=$head was not created\n"
      unless -e "$head.png";
    system "cp", "$head.png", $outfile;

    # clean up and return
    foreach my $ext ( qw( log aux dvi eps tex png ) ) { myrm $head . ".$ext"; }
    mysetmods $outfile;
    print "\nCreated: $outfile\n";

} # sub: math2image()

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
# NOTE: this code is not needed when using MathJax.
#
sub clean_up_math {
    return if use_mathjax;

    my $outdir = shift;
    foreach my $page ( @_ ) {
	myrm "${page}.tex";
	myrm "${page}.aux";
	myrm "${page}.log";
	myrm "${page}.dvi";
	myrm "${page}.eps";
	myrm "${outdir}${page}.png";
    }
} # clean_up_math()

#
# Usage:
#   process_math( $outdir, $page1, ..., $pageN );
#
# Aim:
#   Creates the PNG images
#
# NOTE: this code is not needed when using MathJax.
#
sub process_math {
    return if use_mathjax;

    my $outdir = shift;
    foreach my $page ( @_ ) { math2image $page, "${outdir}${page}.png"; }
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

# Given an array of file names we expect the stylesheet to produce
# and the string output of the stylesheet, which contains the names
# it did produce, return an array with the merged set of names.
#
# Errors out if any of the expected names are not in the actual names,
# so it isn't really a merge as the expected values should be in the
# return of the stylesheet.
#
# Order is not preserved.
#
# This prototype is obviously not correct, so comment out
#sub merge_filenames (@$) {
sub merge_filenames {
  my @exp = shift;
  my $rval = shift;

  my %created;
  foreach my $line (split /\n/, $rval) {
    $line =~ s/^\s+|\s+$//g;
    next if $line eq "";
    $created{$line} = 1;
  }

  foreach my $efile (@exp) {
    die "ERROR: expected file $efile but not created by stylesheet\n"
      unless exists $created{$efile};
  }

  return keys %created;

} # merge_filenames

# QUESTION:
#
# How best to extend this to support multiple output files?;
#   perhaps have a "primary" output and ancillary ones, which may
#  or may not be HTML.
#
# Probably do not want to set outurl here since used to
# generate the canonical link and header for hardcopy output
#

# Create the basic/default set of options for the stylesheets.
#
# TODO: should url be sent in as an optional/named argument?
sub basic_params ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $outurl = $$opts{outurl};
  
    my $url = "${outurl}${in}.html";

    return {
	    type => $$opts{type},
	    site => $$opts{site},
	    lastmod => $$opts{lastmod},
	    lastmodiso => $$opts{lastmodiso},
	    install => $$opts{outdir},
	    canonicalbase => $outurl,
	    pagename => $in,
	    url => $url,
	    # TODO: should outurl be set ?
	    sourcedir => cwd() . "/",
	    updateby => $$opts{updateby},
	    depth => $$opts{depth},
	    siteversion => $site_version,
	    ahelpindex => $ahelpindex,
	    cssfile => $css,
	    cssprintfile => $cssprint,
	    favicon => $favicon,
	    newsfile => $newsfile,
	    newsfileurl => $newsfileurl,
	    watchouturl => $watchouturl,
	    searchssi => $searchssi,
	    googlessi => $googlessi,
	    mathjaxpath => $mathjaxpath,
	    headtitlepostfix => $headtitlepostfix,
	    texttitlepostfix => $texttitlepostfix,
	    
	    storageloc => $$opts{storageloc},

	    ignoremissinglink => $ignoremissinglink,


	   };

} # basic_params

# xml2html_basic
#   Process a 'basic' or 'generic' page style
#
# note: $xslt, $outdir, and $outurl end in a /
#
# At present pagelabel and stylesheethead are set to the
# same value, so could amalgamate; leave as is for now
#
sub xml2html_basic ($$$) {
    my $pagelabel = shift; # used to identify the page type to the user
    my $stylesheethead = shift; # name of stylesheet, without path or trailing .xsl
    my $opts = shift;

    my $in     = $$opts{xml};
    my $dom    = $$opts{xml_dom};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};

    print "Parsing [${pagelabel}]: $in";

    # We 'hardcode' the output of the transformation.
    # Note: for 'ancillary' files, such as the slug files created by
    # the bugs and relnotes pages, we rely on calling a perl routine
    # from within the stylesheet to handle the deletion of the pages.
    #
    my @pages = ( "${outdir}${in}.html" );

    # how about math pages?
    #
    my @math = find_math_pages $dom;

    # do we need to recreate (include the equations created by any math blocks)
    return if should_we_skip $in, @pages, map( { "${outdir}${_}.png"; } @math );
    print "\n";

    # remove files [already ensured the dir exists]
    foreach my $page ( @pages ) { myrm $page; }
    clean_up_math( $outdir, @math );

    my $url = "${outurl}${in}.html";
    my $params = basic_params $opts;

    my $retval = translate_file "$$opts{xslt}${stylesheethead}.xsl", $dom, $params;

    my @outfiles = merge_filenames(@pages, $retval);

    # success or failure?
    check_for_page( @outfiles );

    # math?
    process_math( $outdir, @math );

    print "\nThe page can be viewed at:\n  ${url}\n\n";

} # sub: xml2html_basic

# xml2html_navbar - called by xml2html
#
# 02/13/04 - we now pass the site depth into the stylesheet
#  (since the slang directory has its own navbar we can no longer
#   assume that depth=1)
# 05/03/13 - is this still needed (was it added for the proglang
#  code or some other reason)?
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

    my $params = basic_params $opts;
    $$params{logoimage} = $logoimage if $logoimage ne "";
    $$params{logotext}  = $logotext  if $logotext  ne "";
    $$params{logourl}   = $logourl   if $logourl   ne "";

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
      $$params{startdepth} = $depth;
      $$params{depth} = $d;
      translate_file "$$opts{xslt}navbar.xsl", $dom, $params;
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

# xml2html_cscdb - called by xml2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
# TODO: can be processed by _basic if we support multiple values
#       for @pages and displaying at end (also, need to check that
#       setting outurl is not a problem here and what is the urlhead
#       parameter that this routine sets)
#
sub xml2html_cscdb ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $dom    = $$opts{xml_dom};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};

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
    return if should_we_skip $in, @pages, map( { "${outdir}${_}.png"; } @math );
    print "\n";

    # remove files [already ensured the dir exists]
    initialise_pages( @pages );
    clean_up_math( $outdir, @math );

    my $url = "${outurl}${in}.html";

    my $params = basic_params $opts;
    $$params{urlhead} = $outurl; # TODO: this probably does nothing
    delete $$params{url}; # try to stop display of canonical link as have multiple output HTML pages

    translate_file "$$opts{xslt}cscdb.xsl", $dom, $params;

    # success or failure?
    check_for_page( @pages );

    # math?
    process_math( $outdir, @math );

    print "\nThe pages can be viewed at:\n  $url\n";
    print "and:\n  ${outurl}$in\_alpha.html\n\n";

} # sub: xml2html_cscdb

# xml2html_news - called by xml2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
# TODO: can be processed by _basic if we support multiple values
#       for @pages and displaying at end (also, need to check that
#       setting outurl is not a problem here)
#
sub xml2html_news ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $dom    = $$opts{xml_dom};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};

    print "Parsing [news]: $in";

    # we 'hardcode' the output of the transformation
    #my @pages = ( "${outdir}${in}.html" );
    my @pages = ( "${outdir}${in}.html", "${outdir}feed.xml" );

    # how about math pages?
    #
    my @math = find_math_pages $dom;

    # do we need to recreate (include the equations created by any math blocks)
    return if should_we_skip $in, @pages, map( { "${outdir}${_}.png"; } @math );
    print "\n";

    # remove files [already ensured the dir exists]
    foreach my $page ( @pages ) { myrm $page; }
    clean_up_math( $outdir, @math );

    my $url = "${outurl}${in}.html";

    my $params = basic_params $opts;
    $$params{outurl} = $outurl;

    translate_file "$$opts{xslt}news.xsl", $dom, $params;

    # success or failure?
    check_for_page( @pages );

    # math?
    process_math( $outdir, @math );

    print "\nThe page can be viewed on:\n  $url\n";
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
# behaviour is somewhat different to other XML
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
# TODO: this could be a wrapper around a _basic-like routine;
#   need to set up @pages and what to print at the end.
#
sub xml2html_multiple ($$$) {
    my $opts     = shift;
    my $pagename = shift;
    my $sitelist = shift;

    my $in     = $$opts{xml};
    my $dom    = $$opts{xml_dom};
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};
    my $site   = $$opts{site};

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
	map( { "${outdir}${_}.png"; } @math );
    print "\n";

    # create dirs/remove files
    initialise_pages( @soft );
    clean_up_math( $outdir, @math );

    my $params = basic_params $opts;
    delete $$params{url}; # try to stop display of canonical link as have multiple output HTML pages

    translate_file "$$opts{xslt}${pagename}.xsl", $dom, $params;

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
    my $outdir = $$opts{outdir};
    my $outurl = $$opts{outurl};
    my $site   = $$opts{site};

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

    # do not allow math in the threadindex (when using images, since too
    # lazy to handle them); not a problem for MathJax since no external
    # files needed.
    my @math = find_math_pages $dom;
    die "Error: found math blocks in $in - not allowed here\n"
      unless $#math == -1 or use_mathjax == 1;

    # NOTE: we always recreate the threadindex
    # (it just makes things easier, since the thread index pages
    # depend on so many files)
    #
    # create dirs/remove files
    initialise_pages( @soft );

    my $params = basic_params $opts;
    $$params{threadDir} = $$opts{store};
    $$params{urlhead} = $outurl; # TODO: does this actually do anything?
    delete $$params{url}; # try to stop display of canonical link as have multiple output HTML pages

    translate_file "$$opts{xslt}threadindex.xsl", $dom, $params;

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
#
sub xml2html_thread ($) {
    my $opts = shift;

    my $in     = $$opts{xml};
    my $dom    = $$opts{xml_dom};
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

    # TODO: the proglang support (for both Python and S-Lang)
    #       has been removed, so refuse to publish any threads
    #       containing this element.
    #
    my @lang;
    foreach my $node ($rnode->findnodes('info/proglang')) {
	my $lang = $node->textContent;
	push @lang, $lang;
    }
    die "There are info/proglang elements in $threadname - please remove (values=@lang)\n"
      unless $#lang == -1;

    my @fails = $rnode->findnodes('//@restrict');
    die "ERROR: thread=$threadname contains element(s) with a restrict attribute.\n\tPlease fix and re-publish (see Doug for help)\n"
      unless $#fails == -1;

    @fails = $rnode->findnodes('images');
    die "ERROR: thread=$threadname contains an images block. This should be converted to inline figure blocks. See Doug for help.\n"
      unless $#fails == -1; 

    my @html = ("index.html");

    # What files need pre-processing before being included?
    #
    my @screen = map { $_->getAttribute('file'); }
      ($rnode->findnodes('text/descendant::screen[boolean(@file)]'),
       $rnode->findnodes('images/descendant::screen[boolean(@file)]'),
       $rnode->findnodes('parameters/paramfile[boolean(@file)]'));

    my @image =
      map { $_->getAttribute('src'); } $rnode->findnodes('text/descendant::img');
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
    #
    return if should_we_skip \$time,
      map { my $a = $_; "${outdir}$a"; } @html,
	map( { "${outdir}${_}.png"; } @math );
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

    my $params = basic_params $opts;
    delete $$params{lastmod};
    #delete $$params{lastmodiso}; # we still need to send this value in for the header
    $$params{threadDir} = $threadDir;
    $$params{url} = $outurl; # drop the index.html part

    $$params{imglinkicon} = $imglinkicon;
    $$params{imglinkiconwidth} = $imglinkiconwidth;
    $$params{imglinkiconheight} = $imglinkiconheight;

    translate_file "$$opts{xslt}thread.xsl", $dom, $params;

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

# Given the files that have been changed, work out
# if any other files need to be re-published.
#
sub process_changed ($$$) {
  my $type = shift;
  my $storage = shift;
  my $changed = shift;

  return if $#$changed < 0;
  dbg "Do we need to republish anything?";
  
  my @todo = ();
  foreach my $in ( @$changed ) {
    my $c = identify_files_to_republish "${storage}${in}.revdep";
    for my $fname ( @$c ) {
      push @todo, $fname;
    }
  }

  if ($#todo == -1) {
    dbg "No files need to be republished";
    return;
  }

  print "The following files need re-publishing:\n";
  foreach my $fname ( @todo ) {
    print "   $fname\n";
  }

} # sub: process_changed

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
    my @changed = ();
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
	    $$opts{lastmodiso} = sprintf "%4d-%02d-%02d",
	      1900 + $tm[5], $tm[4] + 1, $tm[3];
	}

	clear_dependencies;

	# what transformation do we apply?
	#
	if ( $root eq "xinclude" ) {
	    # NOTE: use a root of xinclude since the threads support an include
	    # tag so wanted to differentiate between them (include could be
	    # retired and XInclude processing used instead in threads).
	    print "Skipping xinclude file: $in\n";
	    next;
	} elsif ( $root eq "navbar" ) {
	    xml2html_navbar $opts;
	} elsif ( $root eq "page" ) {
	    xml2html_basic 'page', 'page', $opts;
	} elsif ( $root eq "bugs" ) {
	    xml2html_basic 'bugs', 'bugs', $opts;
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
	    # TODO: relnotes creates multiple files, so 
	    #   a) need to know about them to clean up beforehand
	    #   b) remove the <?xml... line from the 'slugs'/included files
	    xml2html_basic 'relnotes', 'relnotes', $opts;
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

	# Can we handle dependencies globally (ie not within xml2html_xxx)?
	# I would think so, but may not be possible.
	# Since we track the stylesheets then deps will only be empty
	# if the file was skipped.
	#
	if ($published ne "" and have_dependencies) {
	  push @changed, $in;

	  # copy file over to storage space and sort out protection/group
	  # - we need to be more clever than this because some files will need multiple
	  #   files copied over [eg the threads have images, screen, and include files]
 	  #
	  # TODO: Is there ever a case when we have no dependencies but want to publish?
	  #       Should *not* be
	  mycp "${in}.xml", "${published}/${in}.xml";

	  # Write the dependencies out after copying the file to the storage directory
	  # since we check on the published copy existing when writing out the reverse
	  # dependencies.
	  dump_dependencies;
	  write_dependencies $in, $published, cwd() . "/", $stylesheets;

	}

    } # foreach: my $in

    # TODO: send in more information
    process_changed $type, $published, \@changed;

} # sub: process_xml()

# handle non-XML files
#
# uses lots of global variables...
#
# NOTE: we no longer copy the files over to the storage site
# to save space
#
# To force a copy of a non XML file even if it has not changed
# requires the $forceforce global variable to be set.
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
	    if ( $forceforce or ! -e $out or -M "$in" < -M "$out" ) {
		mycp $in, $out;
		print "Created: $out\n" if $odir ne $published;
	    } else {
		print "skipped $in\n" if $odir ne $published;
	    }

	} # foreach: @dirs

    } # foreach @$aref

} # sub: process_files


