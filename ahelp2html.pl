#!/data/da/Docs/local/perl/bin/perl -w
#
# $Id: ahelp2html.pl,v 1.37 2004/01/22 23:33:04 dburke Exp $
#
# Usage:
#   ahelp2html.pl
#     --format=web|dist
#       Default is web
#
#     --verbose
#     Turn on screen output that's only useful for testing/debugging
#
#     --version=
#       a string representing the version number of the release.
#       It's used to set the version numnber in the output page
#       since I currently don't trust the VERSION field of the
#       XML files: an example of a valid input is 2.2.1
#
#     --group=
#       Name of unix group to set files to
#       Default is cxcweb_ciao
#
#     --styledir=
#       Full path to the stylesheets directory
#
#     --xsltproc=
#       Full path to xsltproc executable
#
#     --xsltpath=
#       value to set LD_LIBRARY_PATH to when running xsltproc
#
#     --listseealso=
#       Full path to the "list seealso" application that comes
#       with the ahelp2html stuff
#
#     --indir=
#       Name of directory containing the XML and Index files
#
#     --store=
#       Name of directory for storing XML files created
#       (and needed) by the process. These files are NOT deleted
#       on output. Can be the same as indir
#
#     --outdir=
#       Name of directory for the output HTML files
#
#     Only needed if --format=web
#       --type=test|live|trial
#         Default is test
#
#       --htmldoc=
#         Full path to htmldoc executable
#
#       --htmlpath=
#         value to set LD_LIBRARY_PATH to when running htmldoc
#
#       --updateby=
#         Name of person running the update [used in the header
#         for the test pages]. The output of whoami is sufficient.
#
#       --ahelpindexfile=
#         Location of the file containing the text for the
#         contents of http://cxc.harvard.edu/ciao/ahelp/
#
#       --cssfile=
#         URL to use to read in the CSS file for the pages
#
#       --newsfile=
#         full path (not url) to news page used in what's new link
#
#       --newsfileurl=
#         url to news page used in what's new link
#
#       --watchouturl=
#         url to "Watch out" page used in what's new link
#
#       --navbarname=
#         name of navbar to use for the index pages
#         if navabar is called navbar_XXX.incl then set to XXX
#         defaults to ahelp
#
#       --searchssi=
#         url of file to be included to give the search bar
#
#     --force
#        this option is currently ignored: we always recreate
#        the HTML/PDF files for now.
#
# Aim:
#   Convert ahelp XML files into HTML files.
#
#   Two modes:
#     --format=web
#       create pages for the CIAO web site
#
#     --format=dist
#       create pages for the CIAO distribution
#
# Creates:
#   Files in outdir:
#
#     format=web
#       navbar_ahelp_index.incl
#       index.html, index.<a4|letter>.pdf
#       <ahelp>.html, <ahelp>.<a4|letter>.pdf
#         where <ahelp> is the name of the XML file and NOT the
#         value of the key attribute
#
#     format=dist
#       ?
#
# Requires:
#   in styledir
#     ahelp.xsl
#     ahelp_list_info.xsl
#     ahelp_index.xsl
#     ahelp_common.xsl
#     ahelp_main.xsl
#
# Author:
#  Doug Burke (dburke@cfa.harvard.edu)
#
# History:
#  28 Aug 02 DJB Initial version (format=web, viewable HTML only)
#  29 Aug 02 DJB Adding hardcopy support (format=web)
#  17 Sep 02 DJB Added --group option
#  19 Sep 02 DJB Added --version. Made --store mandatory, created XML
#                files are now stored in this directory.
#  01 Nov 02 DJB Added --verbose flag
#  -> Aug 03 DJB Big updates for CIAO 3.0 (added --listseealso config)
#                Reduced the amount of screen output
#                Added --ahelpindexfile option (format=web)
#                Changed navbar_ahelp.incl to navbar_ahelp_index.incl
#                format=web uses CSS (minimally)
#                Added newsfile/url and searchssi parameters
#                Added watchouturl parameter
#                Added navbarname parameter
#     Sep 03 DJB Added the parameter names/synopses to the index file
#                (so that they can be used as tool tips/checked for
#                 validity by the stylesheets).
#

use strict;
$|++;

use Carp;
use Getopt::Long;
use Cwd;
use IO::File;

## Subroutines (see end of file)
#
sub fixme ($);
sub dbg ($);
sub check_dir ($$);
sub mymkdir   ($);
sub mycp      ($$);
sub myrm      ($);
sub mysetmods ($);

sub translate_file ($$$);

sub ahelp2html (@);

## Variables
#

my %_formats = map { ($_,1); } qw( web dist );
my %_types   = map { ($_,1); } qw( test live trial );

my $progname = (split( m{/}, $0 ))[-1];
my $usage = <<"EOD";
Usage: $progname + 'options'

  --format=web|dist
  --version=CIAO version (eg 2.2.1)
  --group=unix group (default is cxcweb_ciao)
  --styledir=full path to the style sheets directory
  --xsltproc=full path to xsltproc executable
  --xsltpath=LD_LIBRARY_PATH value for xsltproc executable
  --listseealso=full path to list_seealso executable

  --indir=input directory containing XML/Index files
  --store=directory to store XML files created in process
          (can equal indir)
  --outdir=out directory for HTML files

  if format=web
    --type=test|live|trial

    --htmldoc=full path of htmldoc executable
    --htmlpath=LD_LIBRARY_PATH value for htmldoc executable

    --updateby=name of person doing the update (`whoami` is sufficient)

    --ahelpindexfile=file containing contents for index.html

    --cssfile=url for CSS file to use

    --newsfile=full path (not url) to "what's new" page on disk
    --newsfileurl=url for "what's new" link

    --watchouturl=url for "watch out" link

    --navbarname=name of navbar to use for index pages
      set to XXX if navbar is called navbar_XXX.incl

    --searchssi=url for SSI file containing the search bar

  --force
    currently a dummy option since it's always "on"

  --verbose
    useful for testing

Directory names must end in /.

EOD

## Code
#

# needs CIAO available (for the listseealso call)
#
die "Error: CIAO needs to be started before running $0\n"
  unless defined $ENV{ASCDS_INSTALL};

# handle options
my $format = "web";
my $version;
my $group = "cxcweb_ciao";
my $styledir;
my ( $xsltproc, $xsltpath );
my $listseealso;
my $indir;
my $store;
my $outdir;

my $updateby;

# format=web only options
my $type = "test";
my (
    $htmldoc,  $htmlpath, $ahelpindexfile, $cssfile,
    $newsfile, $newsfileurl, $watchouturl, $navbarname,
    $searchssi,
   );

my $force = 0;
my $verbose = 0;

die $usage unless
  GetOptions
  'format=s' => \$format,
  'version=s' => \$version,
  'group=s' => \$group,
  'styledir=s' => \$styledir,
  'xsltproc=s' => \$xsltproc,
  'xsltpath=s' => \$xsltpath,
  'listseealso=s' => \$listseealso,
  'indir=s' => \$indir,
  'store=s' => \$store,
  'outdir=s' => \$outdir,

  'type=s' => \$type,
  'htmldoc=s' => \$htmldoc,
  'htmlpath=s' => \$htmlpath,
  'updateby=s' => \$updateby,
  'ahelpindexfile=s' => \$ahelpindexfile,
  'cssfile=s' => \$cssfile,
  'newsfile=s' => \$newsfile,
  'newsfileurl=s' => \$newsfileurl,
  'watchouturl=s' => \$watchouturl,
  'navbarname=s' => \$navbarname,
  'searchssi=s' => \$searchssi,

  'verbose!' => \$verbose,
  'force!' => \$force;

# for now we set force to 1
# [although it's not actually used below]
#
$force = 1;

# checks
#
die "Error: unknown format ($format)\n"
  unless exists $_formats{$format};

die "Error: CIAO version must be supplied using --version=...\n"
  unless defined $version;

# check the group
my $allowed_groups = `groups`;
chomp $allowed_groups;
my %allowed_groups = map { ($_,1); } split " ", $allowed_groups;
die "Error: group was set to $group but you are only a member of:\n    " .
  join( " ", keys %allowed_groups ) . "\n"
  unless exists $allowed_groups{$group};

die "Error: xsltproc parameter not defined\n"
  unless defined $xsltproc;
die "Error: xsltproc executable ($xsltproc) not found\n"
  unless -x $xsltproc && !-d $xsltproc;

die "Error: listseealso parameter not defined\n"
  unless defined $listseealso;
die "Error: listseealso executable ($listseealso) not found\n"
  unless -x $listseealso && !-d $listseealso;

check_dir "styledir", $styledir;

check_dir "xsltpath", $xsltpath;
check_dir "indir", $indir;
check_dir "store", $store;
check_dir "outdir", $outdir;

if ( $format eq "web" ) {
    die "Error: unknown type ($type)\n"
      unless exists $_types{$type};

    die "Error: htmldoc parameter not defined\n"
      unless defined $htmldoc;
    die "Error: htmldoc executable ($htmldoc) not found\n"
      unless -x $htmldoc && ! -d $htmldoc;

    check_dir "htmlpath", $htmlpath;

    die "Error: updateby parameter not defined\n"
      unless defined $updateby;

    die "Error: ahelpindexfile parameter not defined\n"
      unless defined $ahelpindexfile;
    die "Error: ahelpindexfile not found\n"
      unless -e $ahelpindexfile;

    die "Error: cssfile parameter not defined\n"
      unless defined $cssfile;

    die "Error: newsfile parameter not defined\n"
      unless defined $newsfile;
    die "Error: newsfile parameter not found ($newsfile)\n"
      unless -e $newsfile; # OTT?
    die "Error: newsfileurl parameter not defined\n"
      unless defined $newsfileurl;

    die "Error: searchssi parameter not defined\n"
      unless defined $searchssi;
}

# check we can find the needed stylesheets
#
foreach my $name ( qw( ahelp ahelp_list_info ahelp_index ahelp_common ahelp_main ) ) {
    my $x = "${styledir}$name.xsl";
    die "Error: unable to find $x\n"
      unless -e $x;
}

# check usage
#
die $usage unless $#ARGV == -1;

dbg "*** START CONFIG DATA for $0 ***";
dbg "  format=$format";
dbg "  version=$version";
dbg "  group=$group";
dbg "  styledir=$styledir";
dbg "  xsltproc=$xsltproc";
dbg "  xsltpath=$xsltpath";
dbg "  listseealso=$listseealso";
dbg "  indir=$indir";
dbg "  store=$store";
dbg "  outdir=$outdir";
dbg "  verbose=$verbose";
dbg "  force=$force";
if ( $format eq "web" ) {
    dbg "  type=$type";
    dbg "  htmldoc=$htmldoc";
    dbg "  htmlpath=$htmlpath";
    dbg "  updateby=$updateby";
    dbg "  ahelpindexfile=$ahelpindexfile";
    dbg "  cssfile=$cssfile";
    dbg "  newsfile=$newsfile";
    dbg "  newsfileurl=$newsfileurl";
    dbg "  watchouturl=$watchouturl";
    dbg "  navbarname=$navbarname";
    dbg "  searchssi=$searchssi";
}
dbg "*** END CONFIG DATA for $0 ***";

# start work
#
# create the output directories if we have to
mymkdir $outdir;
mymkdir $store;

# and how about the Index files
# - this actually does a lot
#
print "Parsing the See Also sections:\n";
my $seealso = SeeAlso->new( $indir, $store, $format );

# create the index pages
#
my @extra;
push @extra, ( navbarname => $navbarname ) if defined $navbarname;
$seealso->create_ahelp_index(
  $outdir, type => $type, version => $version,
  updateby => $updateby, ahelpindexfile => $ahelpindexfile,
  cssfile => $cssfile,
  newsfile => $newsfile, newsfileurl => $newsfileurl,
  watchouturl => $watchouturl,
  searchssi => $searchssi,
  @extra
);

# perform the XML conversions
#
# - should have a proper iterator..
#
print "Parsing ahelp files:\n";
foreach my $ahelp ( $seealso->list_ahelp_files() ) {

    my ( $key, $context, $seealsofile, $htmlname, $depth, $xmlname ) =
      $ahelp->get( 'key', 'context', 'seealsofile', 'htmlname', 'depth', 'xmlname' );

    ahelp2html(
	       format => $format,
	       xml => $xmlname,
	       xslt => $styledir,
	       type => $type,
	       outdir => $outdir,
	       outname => $htmlname,
	       version => $version,
	       seealsofile => $seealsofile,
	       # _web options below
	       outurl => "http://cxc.harvard.edu/ciao/ahelp/", # umm
	       site => "ciao",
	       updateby => $updateby,
	       depth => $depth,
	       cssfile => $cssfile,
	       searchssi => $searchssi,
	      );

} # foreach: my $in

# End of script
#
exit;

## Subroutines
#

## helper utilities
#

# fixme $msg
#
# can print out the message to screen if we want to
# - but mainly useful as a way of marking a problem area
#
##sub fixme ($) {}
sub fixme ($) { print STDERR "$_[0]\n"; }

# dbg $msg
#
# prints the message to STDOUT if $verbose != 0
# (adds a leading >>DBG: and trailing \n)
#
sub dbg ($) { print ">>DBG: $_[0]\n" if $verbose; }

# used to check input params
#
# note:
#   we do not check for the existence of the directory
#   just that the input string matches certain requirements
#
sub check_dir ($$) {
    my $name  = shift;
    my $value = shift;

    die "Error: $name not defined\n"
      unless defined $value;
    die "Error: $name ($value) not found\n"
      unless -d $value;
    die "Error: $name ($value) does not end in '/'\n"
      unless $value =~ /\/$/;

} # sub: check_dir()

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
# It uses /usr/bin/rm rather then perl's unlink() function because I
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

# utility routine to convert a hash of key/value pairs into
# a string saying
#  "--stringparam key1 value1 --stringparam key2 value2 ..."
#
sub make_params (@) {
    my %hash = @_;
    return join( "", map
		 {
		     my $parname = $_;
		     my $parval  = $hash{$parname};
print "--- parname $parname has no defined value\n" unless defined $parval;
		     $parval = "''" if !defined($parval) or $parval eq "";
#		     $parval = "''" if $parval eq "";

		     # try and protect spaces in any arguments
		     #
		     if ( $parval =~ / / && $parval !~ /^['"]/ ) {
			 $parval = "'${parval}'";
			 print STDERR "--- protecting parameter value [$parval]\n";
		     }

		     "--stringparam $parname $parval "
		 } keys %hash );
} # sub: make_params()

# run the processor and return the screen output
#
# uses the global variables $xsltproc and $xsltpath
# and we *always* add a --novalid option here
# (since we don't have a proper catalog/location for the DTDs)
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

    my $retval = `/usr/bin/env LD_LIBRARY_PATH=$xsltpath $xsltproc --novalid $params $stylesheet $xml_file`;

    # just a warning, do not die any more
    ##die "\nError: problems using $stylesheet\n       error in XML file ($xml_file)?\n\n"
    ##  unless $? == 0;
    print "\nError: problems using $stylesheet\n       error in XML file ($xml_file)?\n"
      unless $? == 0;

    dbg "*** XSLT ***";
    return $retval;

} # sub translate_file()

## create the hardcopy versions of the files
#
# create_hardcopy $dir, $head
# create_hardcopy $dir, $hthml_head, $out_head
#
# creates $dir/$head.[letter|a4].pdf
# and deletes the hardcopy version of the file once it's finished with
#
# uses the global variables $htmldoc and $htmlpath
#
# NOTE: there is now almost no screen output unless verbose is set
#
sub create_hardcopy ($$;$) {
    my $indir = shift;
    my $html_head = shift;
    my $out_head  = shift || $html_head;

    my $in  = "${indir}${html_head}.hard.html";

    dbg "Creating hardcopy formats:\n";
    foreach my $size ( qw( letter a4 ) ) {
	foreach my $type ( qw( pdf ) ) {

	    my $out = "${indir}${out_head}.${size}.${type}";

	    # check/clean up
	    # - note: consider file not existing an error but do not die
	    #die "Error: unable to find $in\n"
	    #  unless -e $in;
	    unless ( -e $in ) {
		print "Error: trying to create hardcopy of $in [$type,$size] but it doesn't exist.\n";
		next;
	    }
	    myrm $out;

	    `/usr/bin/env LD_LIBRARY_PATH=$htmlpath $htmldoc --webpage --duplex --size $size -f $out $in 2>&1 >/dev/null`;
	    # now get errors if text is too wide for page (which we have plenty
	    # of), so don't bother checking -- other than whether the output was created
	    #print "\nWARNING: problems using htmldoc\n\n" unless $? == 0;

	    #die "Error: $out not created by htmldoc\n"
	    #  unless -e $out;
	    unless ( -e $out ) {
		print "Error: unable to create hardcopy of $in [$type,$size]\n";
		next;
	    }
	    mysetmods $out;

	    dbg "  created: ${out_head}.${size}.${type}\n";

	} # foreach: $type
    } # foreach: $size

    # clean up the hardcopy file now we've finished with it
    myrm $in;

} # sub: create_hardcopy

# ahelp2html
#
# note: $xslt, $outdir, and $outurl end in a /
#
# note: screen output only if $verbose is set
#
sub ahelp2html (@) {
    my %opts = @_;

    my $in      = $opts{xml};
    my $format  = $opts{format};
    my $outdir  = $opts{outdir};
    my $outname = $opts{outname};
    my $outurl  = $opts{outurl};
    my $type    = $opts{type};
    my $version = $opts{version};
    my $depth   = $opts{depth};

    # handle values only required for format=web
    my @extra;
    if ( $format eq "web" ) {
	@extra =
	  (
	   # below are the "format=web" only options
	   updateby => $opts{updateby},
	   type     => $type eq "trial" ? "test" : $type, # this is important!!!
	   url      => "${outurl}${outname}.html",
	   site     => "ciao",
	   cssfile  => $opts{cssfile},
	   searchssi  => $opts{searchssi},
	  );
    }

    my $params =
      make_params(
		  format      => $format,
		  outdir      => $outdir,
		  outname     => $outname,
		  version     => $version,
		  seealsofile => $opts{seealsofile},
		  depth    => "" . '../' x ($opts{depth}-1),
		  @extra
		 );

    # we 'hardcode' the output of the transformation
    # and ensure that any old files have been deleted
    #
    my @names = $format eq "dist" ? ( $outname ) : ( $outname, "${outname}.hard" );
    my @pages = map { "${outdir}${_}.html"; } @names;
    foreach my $page ( @pages ) { myrm $page; }

    # run the processor, pipe the screen output to a file
    #
    translate_file $params, $opts{xslt} . "ahelp.xsl", $in;

    # success or failure?
    foreach my $page ( @pages ) {
	#die "Error: transformation did not create $page\n"
	#  unless -e $page;
	unless ( -e $page ) {
	    print "Error: transformation did not create $page\n";
	    next;
	}
	mysetmods $page;
	dbg "Created: $page\n";
    }

    # create the hardcopy pages
    create_hardcopy $outdir, $outname if $format eq "web";

} # sub: ahelp2html

#-----------------------------------------------------------------------------------

## Set up the AhelpObj object
#
# $ahelpobj = AhelpObj->new( $key, $context, opt1 => $val1, .. );
#
# NOTE:
#   we do not really need an object here. All I am using the
#   object for is a convenient way to store and access data;
#   there's no fancy polymorphism or inheritance or multi-method
#   dispatch or ... going on
#

package AhelpObj;

use strict;

### Constructor

#
# $obj = AhelpObj->new( $key, $context, $opt1 => $val1, ... )
#
# - a new addition is to parse the XML file for
#   parameter names + synopsis values
# - which means we really should redo the system so that we can get
#   this info more "sensibly" (ie without accessing the XML files
#   multiple times which is what happens now)
#
sub new {
    my $this  = shift;
    my $class = ref($this) || $this;

    my $key     = shift;
    my $context = shift;

    my %opts =
      (
       key => $key, context => $context,
       xmlname => undef,
       seealsogroups => undef, seealsofile => undef,
       summary => undef, htmlname => undef, depth => undef,
       matchkey => undef,
       @_
      );

    my $self = bless \%opts, $class;
    $self->_update();
    return $self;

} # sub: new

sub _update {
    my $self = shift;

    # calculate derived properties
    if ( defined $$self{htmlname} ) {
	my @split = split( /\//, $$self{htmlname} );
	$$self{depth} = 1 + $#split;
    }
}

sub set {
    my $self = shift;
    my %add = @_;
    while ( my ( $key, $value ) = each %add ) {
	die "Error: unable to add $key to the " . ref($self) . " object\n"
	  unless exists $$self{$key};
	$$self{$key} = $value;
    }
    $self->_update();
} # sub: set

sub get {
    my $self = shift;
    my @out;
    foreach my $key ( @_ ) {
	die "Error: unable to get $key from the " . ref($self) . " object\n"
	  unless exists $$self{$key};
	push @out, $$self{$key};
    }
    return wantarray ? @out : $out[0];
} # sub: get

#-----------------------------------------------------------------------------------

## Set up the SeeAlso object
#
# $seealsoobj = SeeAlso->new( $indir, $storedir );
#
# $seealsoobj->create_ahelp_index( $dir, opt1 => $val1, ... );
#
# @obj = $seealsoobj->list_ahelp_files()
#

package SeeAlso;

use strict;

### Helper functions

sub my_alphabetical_sort { my $x=$a;my $y=$b; $x=~ s/_/zzz/g;$y=~ s/_/zzz/g; $x cmp $y }

sub print_list_to_index ($$$) {
    my $fh   = shift;
    my $name = shift;
    my $list = shift;

    $fh->print( "<${name}>\n" );

    # we want '_' to come at the end, hence the 'amusing' sort function
    # - and we do this for both the 'containers' and the 'contents'
    #   ( eg for context list, sort both the contexts and the
    #     contents of each context )
    #
    my @words = sort my_alphabetical_sort keys %$list;
    foreach my $word ( @words ) {
	my $href = $$list{$word};
	$fh->printf( "<term><name>%s</name><itemlist>\n", $word );
	# since id has context in it we just use the default sort for now
        my $ctr = 1;
	my @ids = sort my_alphabetical_sort keys %$href;
	foreach my $id ( @ids ) {
	    # just print the id value (used to index into the main list)
	    print $fh "<item number='$ctr' id='$id'/>\n";
	    $ctr++;
    }
	$fh->print( "</itemlist></term>\n" );
    }
    $fh->print( "</${name}>\n" );

} # sub: print_list_to_index

# $id = mangle( $key, $context )
#
# since we need to be able to reference a help file via
# key AND context (ie print/slang and print/chips)
# we need to mangle the key & context to provide a
# unique identifier.
# Both the key and the context are converted to lower-case
# since the database does this and we can get the context
# from the database (parsing the 'See Also' information).
#
# note:
#  now we have an object to hide things in we could be more
#  clever, but I don't have the time
#
sub mangle ($$) {
    my ( $key, $context ) = @_;

    # key/context are case insensitive (stored in AHELP db as lower case I believe)
    $key     = lc $key;
    $context = lc $context;

    # assume that || is unique [ie does not appear in key or context]
    # - actually, I'm not sure it's important any more whether || is in the key or context
    #   since we no longer have an unmangle method, ie we no longer need to convert
    #   back from a mangled key/context pair to the separate values
    #
    return "${key}||${context}";
}

### Constructor

#
# $seealso = SeeAlso->new( $dirname, $storedir, $format )
#
# returns the seealso information (+ other juicy info) for
# all the XML files in dirname whose root node is
# cxchelptopics, and whose cxchelptioics/ENTRY/@key != 'onapplication'
#
# It also *creates* the XML index/seealso files needed for the
# HTML creation (maybe this should be factored out into a separate
# method since it's currently a pretty hunky constructor)
#
# The return value is an object. Methods are:
#    ...
#
# we die - at the moment - if key = index index_alphabet or index_context
# fortunately this isn't true at the moment, but once it is we may have to go
# to either listing pages within context directories [and could have a index
# for each directory] or have them as key.context.html
#
# This routine has changed from CIAO 2.3: we used to parse the database files
# (CXCHelp*) to find a lot of the information. Now we directly search the XML
# files for some of the information and (not yet implemented) use the
# Ahelp API to access the see also information. So, we should be insulated from
# changes to the DB format. Preferably we would like to use the Ahelp API
# to get all this informaiton but that's not possible (the Ahelp API isn't
# really designed for the queries we're doing here)
#
sub new {
    my $this  = shift;
    my $class = ref($this) || $this;

    my $path   = shift;
    my $store  = shift;
    my $format = shift;

    # store values
    #   each key of %out is the mangled key/context value
    #   the value is a AhelpObj object
    #
    #   the lists have the same format:
    #     each key is the item the list is split into and its
    #     key is a hash reference, where the hash contains
    #       ( $id, $out{$id} )
    #     pairs
    #
    #   each key of %seealso is the name of a seealso group
    #   each value is a hash reference with key/value pairs
    #   that are context/list of key values for that seealso group
    #
    #   each key of %multi_key is a given key, the value is the
    #   number of xml files with that key
    #
    my %out;
    my %list_context;
    my %list_alphabet;
    my %list_dirs;
    my %seealso;
    my %multi_key;

    # first, let's parse the XML files to get a list of
    #   key context URL1 URL2 [ seealsogroup1 ... seealsogroupN ] summary-text
    #
    # URL1 and 2 can equal the string NULL
    # (if there isn't a corresponding entry in the XML file)
    #
    # since there may be a large number of files that match $path/*xml we do
    # them individually -- which is slower since we need to load/parse the
    # stylesheet for each file. It does, however, give us the advantage of
    # matching the xml file name with the parsed info.
    #
    main::dbg( "parsing xml files in $path for key/context/URL info" );
    my @temp_address_fixes;
    foreach my $xmlfile ( glob("${path}*.xml") ) { # $path ends in a /
	# should only be one line
	my $res = main::translate_file( "", "${styledir}ahelp_list_info.xsl", $xmlfile );
	next if $res =~ /^\s*$/;
	chomp $res;

	# just used for the temporary ADDRESS/URL hack
	my $filehead = (split("/",$xmlfile))[-1];
	$filehead =~ s/\.xml$//;

	my ( $key, $context, $url1, $url2, $rest ) = split " ", $res, 5;
	$context = lc $context; # since this is how ahelp sees it

	# create single id
	my $id = mangle( $key, $context );

	# NOTE:
	#   rather than die on a multiple, we just ignore the
	#   multiple occurrences. this allows HTML files to be
	#   generated even if something is a bit screwy.
	#
	if ( exists $out{$id} ) {
	    print "WARNING: multiple key=$key context=$context files - ignoring $filehead.xml\n";
	    next;
	}

	# do we have multiple matches for a given key?
	$multi_key{$key} = 0 unless exists $multi_key{$key};
	$multi_key{$key}++;

	# what is remote and local output location?
	# (strip off "http://..." where necessary)
	# Actually, only bother with the one that is related to the
	# site (aka global variable $format)
	#
	# note:
	#   we want to ignore this file if we cannot find the
	#   address block - [$url1/2 == NULL] - ie don't die
	#
	my $htmlname;
	if ( $format eq "web" ) {
	    # want http://...
	    if    ( $url1 =~ /^http/ ) { $htmlname = $url1; }
	    elsif ( $url2 =~ /^http/ ) { $htmlname = $url2; }
	    else {
		print "WARNING: unable to find a 'http:...' ADDRESS/URL field for key=$key context=$context - ignoring file\n";
		next;
	    }
	    # strip off the leading part
	    # - NEED TO THINK HOW RELATIVE PATHS ARE GOING TO WORK
	    ##$htmlname =~ s{^http://[^/]+}{}; # just strips off machine name
	    $htmlname =~ s{^http://[^/]+/ciao/ahelp/}{};

	} else {
	    # want local - don't need to strip off anything
	    #
	    if    ( $url1 ne "NULL" and $url1 !~ /^http/ ) { $htmlname = $url1; }
	    elsif ( $url2 ne "NULL" and $url2 !~ /^http/ ) { $htmlname = $url2; }
	    else {
		print "WARNING: unable to find a 'local' ADDRESS/URL field for key=$key context=$context - ignoring file\n";
		next;
	    }
	}

	# In CIAO 3.0 we should have all the ADDRESS/URL tags be sensible.
	# Unfortunately this is not yet true. So what we do is change
	# them here (so that the 'see also' links work) but ahelp -i/w
	# won't [until the updated files make there way through to the
	# distribution].
	#
	if ( $htmlname ne "${filehead}.html" ) {
	    push @temp_address_fixes, $filehead;
	    $htmlname = $filehead;
	}
	$htmlname =~ s/\.html$//;

	# we are not guaranteed to have any seealso groups
	# or a summary block...
	##$rest =~ m/^\s*\[([^\]]+)\] (.+)$/
	##  or die "Error: expected line to look like '[...] ...' but found\n$rest\n";
	#
	$rest =~ m/^\s*\[([^\]]*)\] (.*)$/
	  or die "Error: expected line to look like '[...] ...' but found\n$rest\n";

	# convert the seealsogrooup list to lowercase since that seems to
	# be how the database works. Plus creates a key matching the group name
	# in %seealso (trying to write posy Perl code rather than understandable stuff)
	#
	my @seealsogroups =
	  map
	    { my $grp = lc $_; $seealso{$grp} = {} unless exists $seealso{$grp}; $grp; }
	      split( " ", $1 );

	my $summary = $2;
	# just to indicate those files that need a summary added to them
	print "WARNING: key=$key context=$context has NO summary block\n"
	  if $summary eq "";

	# safety check
	die "Error: HTML output name for key=$key context=$context is $htmlname which clashes with the index pages\n"
	  if $htmlname =~ /^index(_alphabet|_context)$/;

	# note that the stylesheet cuts out 'onapplication' help files

	# create the object
	#
	$out{$id} = AhelpObj->new( $key, $context,
				   xmlname => $xmlfile,
				   seealsogroups => \@seealsogroups,
				   summary => $summary,
				   htmlname => $htmlname,
				 );

	# update context/alphabetical/directory list
	#
	# we use $id as the key since - at least for the alphabetical list - we
	# may have multiple occurrences of $key but with different contexts
	#
	# we use the same format of all these lists so that we can process
	# them the same way later on
	#
	$list_context{$context} = {} unless exists $list_context{$context};
	die "Errrr: have multiple matches for id=$id in context list $context\n"
	  if exists ${ $list_context{$context} }{$id}; # this should be impossible
	${ $list_context{$context} }{$id} = $out{$id};

	my $fchar = uc(substr($key,0,1));
	$list_alphabet{$fchar} = {} unless exists $list_alphabet{$fchar};
	die "Errrr: have multiple matches for id=$id in alphabetical list $fchar\n"
	  if exists ${ $list_alphabet{$fchar} }{$id}; # this should be impossible
	${ $list_alphabet{$fchar} }{$id} = $out{$id};

	# it's useful to know what directories we are going to be storing the files in
	#
	my $dname = $htmlname;
	$dname =~ s{[^/]+$}{};
	$list_dirs{$dname} = {} unless exists $list_dirs{$dname};
	${ $list_dirs{$dname} }{$id} = $out{$id};

    } # foreach: $xmlfile

    # report on ADDRESS/URL hacks
    my $nfixes = 1 + $#temp_address_fixes;
    if ( $nfixes > 0 ) {
	print "WARNING: the following $nfixes files had issues with ADDRESS/URL blocks\n";
	foreach my $tmp ( @temp_address_fixes ) {
	    print "  $tmp\n";
	}
    }

    # now find all the seealso info
    #
    # - now, we are guaranteed that the output is in the seealso order
    #   but it's not worth using this knowledge in the algorithm below
    #
    # $listseealso is a small C++ program that queries the ahelp DB
    # for the seealso groups for a given keyword (global variable)
    #
    main::dbg( "parsing ahelp DB file to find seealsogroup members:" );
    main::dbg( "  " . join( " ", keys %seealso ) . "\n" );
    my $fh = IO::File->new( "$listseealso " . join( " ", keys %seealso ). " |" )
      or die "Error: Unable to run $listseealso\n";
    while ( <$fh> ) {
	chomp;
	my ( $grpname, $context, $key ) = split;
	my $aref = $seealso{$grpname};
	$$aref{$context} = [] unless exists $$aref{$context};
	push @{ $$aref{$context} }, $key;
    }
    $fh->close;

    # loop through each key/context item and calculate the seealso info
    # - and update the matchkeys flag in the object
    #
    foreach my $ahelp ( values %out ) {
	my ( $key, $context, $grplist ) = $ahelp->get( "key", "context", "seealsogroups" );
	main::dbg( "Creating seealso info for $key/$context" );

	$ahelp->set( matchkey => $multi_key{$key} );

	my %list;
	my $flag = 0;
	foreach my $grp ( @$grplist ) {
	    main::dbg( "  -- group = $grp" );
	    while ( my ( $ctxt, $aref ) = each %{ $seealso{$grp} } ) {

		# $ctxt is the context and $aref a list of keys
		#
		$list{$ctxt} = {} unless exists $list{$ctxt};

		# a little bit of perl trickery to add key=>1 sets
		# to the hash array (so that we can do an alphabetical
		# sort later). Since we don't mind overwriting
		# the contents we just treat the hash array as a normal
		# array and add on a load of key=>1 pairs
		#
		$list{$ctxt} =
		  {
		   %{ $list{$ctxt} },
		   map { ($_,1); } @{$aref}
		  };
		$flag = 1;
	    } # while: $ctxt,$aref
	} #foreach: $grp

	my $ofile = "${store}seealso.$context.$key.xml";
	main::dbg( " -- about to create $ofile" );
	main::myrm( $ofile );
	$fh = IO::File->new( "> $ofile" )
	  or die "Error: Unable to create $ofile\n";

	$fh->print( '<?xml version="1.0" encoding="us-ascii" ?>' . "\n" .
		    "<!DOCTYPE seealso>\n" );

	if ( $flag ) {
	    $fh->print( "<seealso>\n<dl>\n" );

	    # output is in context order, alphabeticised
	    # - we need to add on the depth of the ahelp file itself to the
	    #   links in the seealso section, not the depth of the actual seealso file
	    my $depth = '../' x ($ahelp->get('depth')-1);

	    foreach my $scontext ( sort keys %list ) {
		# at the least we have to filter out the entry for the actual tool
		# - we also ignore those items for which we don't have a ahelp file
		#   [either some config error or because we're ignoring them because they
		#    don't contain ADDRESS blocks]
		# - which is really messy since it can mean that we shouldn't print
		#   an entire section
		#
		# I use a grep statement to work out whether each item in $list{$scontext}
		# should be included or not. The subset of entries that are to be included
		# then get sent to a map statement which creates the link.
		# We then output the section if there's actually anything to print out.
		#
		my $outtext =
		  join(
		       # the \n is to avoid really-long lines
		       ",\n",
		       map
		       {
			   my $skey = $_;
			   my $sout = $out{ mangle($skey,$scontext) };
			   # do I need to worry about any double quotes in the summary? -- yes
			   # - and other non XML characters...
			   my $summary = $sout->get('summary');
			   $summary =~ s{"}{&quot;}g;
			   $summary =~ s{<}{&lt;}g;
			   $summary =~ s{>}{&gt;}g;
###print STDERR "+++ summary='$summary'\n" if $summary =~ m/&/;
			   sprintf( "<a href='%s.html' title=\"Ahelp: %s\">%s</a>",
				    $depth . $sout->get('htmlname'),
				    $summary,
				    $skey );
		       }
		       grep
		       {
			   # this does the filtering
			   my $skey = $_;
			   if ( $skey eq $key && $scontext eq $context ) {
			       # we're looking at ourselves, so skip it
			       0;
			   } else {
			       if ( defined $out{ mangle($skey,$scontext) } ) {
				   1;
			       } else {
				   print "WARNING: no ahelp file found for context= $scontext key= $skey\n";
				   0;
			       }
			   }
		       }
		       sort keys %{ $list{$scontext} }
		      );
		if ( $outtext ne "" ) {
		    $fh->print( "<dt><em>$scontext</em></dt>\n<dd>\n" );
		    $fh->print( $outtext );
		    $fh->print( "\n</dd>\n" );
		}
	    }
	    $fh->print( "</dl>\n</seealso>\n" );
	} else {
	    $fh->print( "<seealso/>\n" );
	} # if: $flag

	$fh->close();
	main::mysetmods( $ofile );
	$ahelp->set( seealsofile => $ofile );

    } # foreach: $href

    # create the index XML file
    my $indexfile = "${store}seealso-index.xml";
    main::dbg( "Creating the index file: $indexfile\n" );
    main::myrm( $indexfile );
    $fh = IO::File->new( "> $indexfile" )
      or die "Error: unable to open $indexfile for writing\n";
    $fh->print( '<?xml version="1.0" encoding="us-ascii" ?>' . "\n" .
		 "<!DOCTYPE ahelpindex>\n" .
		 "<ahelpindex>\n"
	       );

    # print out the list of ahelp files (order does not matter
    # although I guess it could do when searching)
    #
    $fh->print( "<ahelplist>\n" );
    foreach my $out ( values %out ) {
	my ( $k, $c, $h, $d, $s ) = $out->get( "key", "context", "htmlname", "depth", "summary" );
	my $mkey = $out->get( "matchkey" );
	my $id = mangle($k,$c);
	# normalise the space in the summary - including within the string (not really necessary)
	$s =~ s/\s+/ /g;
	# NOTE:
	#   key, context, and page are okay to print as is,
	#   but we need to protect < and & in the summary
	#   - there should be no reason why we can't change them
	#     (although need care for & so &amp; isn't converted)
	#
	$s =~ s/</&lt;/g;
	$s =~ s/&\s/&amp; /g;
	$s =~ s/&$/&amp;/;

	$fh->printf( "<ahelp id='%s' samekey='%d'><key>%s</key><context>%s</context><page depth='%s'>%s</page>\n" .
                     "<summary>%s</summary></ahelp>\n",
		     $id, $mkey, $k, $c, '../' x ($d-1), $h, $s );
    }
    $fh->print( "</ahelplist>\n" );

    # print out the alphabetical and contextual lists to the index file
    #
    print_list_to_index $fh, "alphabet",   \%list_alphabet;
    print_list_to_index $fh, "context",    \%list_context;
    ##print_list_to_index $fh, "directory",  \%list_dirs;

    $fh->print( "</ahelpindex>\n" );
    $fh->close();
    main::mysetmods( $indexfile );

    # create the object
    my $obj =
      {
       all       => \%out,           # all the xml files indexed by mangled keyword/context
       context   => \%list_context,  # 'all' in a list of contexts
       alphabet  => \%list_alphabet, # 'all' arranged in an alphabetical list
       dirs      => \%list_dirs,     # do we need this?
       indexfile => $indexfile,      # xml file containing info needed to create the index files
       path      => $path,
       format    => $format,         # may as well carry this around too
      };

    return bless $obj, $class;

} # sub: new

# $seealso->create_ahelp_index( $outdir, $opt1 => $val1, $opt2 => $val2, ... );
#
# Creates the ahelp index files in $outdir
# [we know the format to use]
#
# Valid options:
#   type
#   indir
#   version
#   updateby
#   ahelpindexfile (format=web only at the moment)
#   site      => ciao
#   urlbase   => http://cxc.harvard.edu/ciao/ahelp/
#   searchssi (format=web)
#

sub create_ahelp_index {
    my $self   = shift;
    my $outdir = shift;
    my %opts   = @_;

    my $xmlfile = $$self{indexfile};
    my $indir   = $$self{path};
    my $format  = $$self{format};

    # set some defaults
    #
    $opts{site}      ||= "ciao";
    $opts{urlbase}   ||= "http://cxc.harvard.edu/ciao/ahelp/";

    # handle values only required for format=web
    my @extra;
    if ( $format eq "web" ) {
	@extra =
	  (
	   type     => $opts{type} eq "trial" ? "test" : $opts{type}, # this is important!!!
	   urlbase  => $opts{urlbase},
	   updateby => $opts{updateby},
	   ahelpindexfile => $opts{ahelpindexfile},
	   cssfile  => $opts{cssfile},
	   newsfile  => $opts{newsfile},
	   newsfileurl  => $opts{newsfileurl},
	   watchouturl  => $opts{watchouturl},
	   searchssi  => $opts{searchssi},
	  );
	push @extra, ( navbarname => $opts{navbarname} )
	  if exists $opts{navbarname};
    }

    print "Parsing [ahelpindex]: $xmlfile\n";
    my $params =
      main::make_params(
		  format   => $format,
		  outdir   => $outdir,
		  indir    => $indir,          # do we really need this?
		  site     => $opts{site},
		  version  => $opts{version},
		  @extra
		 );

    # we 'hardcode' the output of the transformation
    # and ensure that any old files have been deleted
    #
    my @soft;
    my @hard;
    if ( $format eq "web" ) {
	my @s = qw( navbar_ahelp_index.incl index.html index_alphabet.html index_context.html );
	my @h = qw( index index_alphabet index_context );

	@soft = map { "${outdir}${_}"; } @s;
	@hard = map { "${outdir}${_}.hard.html"; } @h;

    } elsif ( $format eq "dist" ) {
	@soft = map { "${outdir}${_}.html"; } qw( index index_alphabet index_context );
    } else {
	die "Error: how did you get this far with an unknown format of $format?\n";
    }
    foreach my $page ( @soft, @hard ) { main::myrm( $page ); }

    # run the processor, pipe the screen output to a file
    main::translate_file( $params, "${styledir}ahelp_index.xsl", $xmlfile );

    # success or failure?
    foreach my $page ( @soft, @hard ) {
	#die "Error: transformation did not create $page\n"
	#  unless -e $page;
	unless ( -e $page ) {
	    print "Error: transformation did not create $page\n";
	    next;
	}
	main::mysetmods( $page );
	main::dbg("Created: $page\n");
    }

    # create the hardcopy pages [if required]
    foreach my $page ( @hard ) {
	$page =~ s/^.*\/([^\/].+)\.hard\.html$/$1/;
	main::create_hardcopy( $outdir, $page );
    }

} # sub: create_ahelp_index

# @files = $seealso->list_ahelp_files();
#
# returns an array of AhelpObj objects that represent all
# the XML files processed
#

sub list_ahelp_files {
    my $self = shift;
    return values %{ $$self{all} };
}

1;
