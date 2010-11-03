#!/data/da/Docs/local/perl/bin/perl -w
#
# Usage:
#   mk_ahelp_setup.pl
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
#   Create the files needed to allow the creation of the ahelp HTML
#   pages.
#
#   It should *only* be run from the CIAO site - ie not the Sherpa
#   or ChIPS sites.
#
# Creates:
#   Files in the storage location given in the config file
#
# Requires:
#
# Author:
#  Doug Burke (dburke@cfa.harvard.edu)
#
# History:
#  02 Oct 03 DJB Re-worked ahelp2html.pl into separate parts
#  12 Oct 07 DJB Removed ldpath var as no longer used
#                and updates to better support CIAO 4 changes
#  15 Oct 07 DJB Executables are now OS specific
#                Indexes now contain site information on each ahelp page.
#                This script should *only* be run from the ciao site
#  16 Oct 07 DJB Removed support for type=dist
#  17 Oct 07 DJB Removed support for xsltproc tool
#  19 Oct 07 DJB Removed use of ahelp_list_info stylesheet
#
# Future?:
#  - include parameter names + synopsis for each ahelp file in the
#    index. This will be used by the web code to add title attribute to
#    ahelp links. Do we not now do this?
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

sub get_ahelp_items ($@);
sub get_ahelp_item_if_exists ($$);
sub set_ahelp_item ($$$);
sub check_multi_key ($\%);
sub expand_seealso ($\%);
sub inspect_xmlfile ($$);

sub protect_xml_chars_for_printf ($);

sub parse_groups ($$$\%);
sub print_seealso_list ($$$$\%);
sub create_index_files ($\%\%\%);
sub create_seealso_files ($\%);

sub check_htmlname ($);

sub print_ahelplist_to_txtindex ($$);
sub print_ahelplist_to_xmlindex ($$);

## set up variables that are also used in CIAODOC
use vars qw( $configfile $verbose $group $site );
$configfile = "$FindBin::Bin/config.dat";
$verbose = 0;
$group = "";
$site = "";

## Variables
#

my $progname = extract_filename $0;
my $usage = <<"EOD";
Usage:
  $progname --config=name --type=test|live|trial --verbose

The default is --type=test, which publishes to the test web site.
The live option publishes to the live (ie cxc.harvard.edu) site.
Don't use the trial option unless you know what it does.

The --config option gives the path to the configuration file; this
defaults to config.dat in the same directory as the script.

The --verbose option is useful for testing/debugging the code.

EOD

## Code
#

# needs CIAO available (for the listseealso call)
#
die "Error: CIAO needs to be started before running $0\n"
  unless defined $ENV{ASCDS_INSTALL};

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
my $listseealso = get_config_main_type( $config, "listseealso", $ostype );

check_executable_runs "list_seealso", $listseealso, "--version";
dbg "Found executable/library paths";

# most of the config stuff is parsed below, but we need these two here
my $site_config;
( $site, $site_config ) = find_site $config, $dname;
$config = undef; # DBG: just make sure no one is trying to access it
dbg "Site = $site";

check_type_known $site_config, $type;
dbg "Type = $type";

dbg "OS = $ostype";

die "ERROR: mk_ahelp_setup.pl should obly be run within site=ciao, not site=$site\n"
  unless $site eq "ciao";

# now we can check the usage
#
die $usage unless $#ARGV == -1;

# Handle the remaining config values
#
# shouldn't have so many global variables...
#
$group = get_group $site_config;
my ( $version, $config_version, $dhead, $depth ) = check_location $site_config, $dname;

my $stylesheets = get_config_type $config_version, "stylesheets", $type;
my $storage     = get_config_type $config_version, "storage", $type;
my $ahelpfiles  = get_config_type $config_version, "ahelpfiles", $type;

# check we can find the needed stylesheets
#
foreach my $name ( qw( ahelp ahelp_index ahelp_common ahelp_main ) ) {
    my $x = "${stylesheets}$name.xsl";
    die "Error: unable to find $x\n"
      unless -e $x;
}

# check there's at least a doc/xml directory in ahelpfiles
die "Error: ahelpfiles directory ($ahelpfiles) does not contain a doc/xml/ sub-directory\n"
  unless -d "$ahelpfiles/doc/xml";

#### note: in ahelp2html used the variable $published here using $storage
$storage .= $dhead;

dbg "*** CONFIG DATA ***";
dbg "  dname=$dname";
dbg "  dhead=$dhead";
dbg "  depth=$depth";
dbg "  storage=$storage";
dbg "  stylesheets=$stylesheets";
dbg "  ahelpfiles=$ahelpfiles";
dbg "  type=$type";
dbg "*** CONFIG DATA ***";

# start work
#
# create the output directory if we have to
mymkdir $storage;

# A)
#
# Find all the XML files we are interested in and get "interesting" info
# about each file
#
# "See Also" handling has got more complicated in CIAO 4 since files can have 
# seealsogroup and displayseealsogroups attributes, where the
# latter means use these values but don't add the cuurent file
# to any of those groups. We have already smooshed the two together, so
# we only have to bother with the seealsogroup list here; let's see how
# that works.
#
# We should probably just create the out DOM here (ie a XML::LibXML::Document
# object) rather than create a number of perl structures which we then later
# have to turn into an XML document, manually.
#
my %out;
my %multi_key;
my %seealso;
my %list_context;
my %list_alphabet;

##my %list_dirs;

# Some, but not all, lists are organized by site
#
foreach my $site ( list_ahelp_sites ) {
  $list_alphabet{$site} = {};
  $list_context{$site} = {};
  ##$list_dirs{$site} = {};
}

foreach my $path ( map { "${ahelpfiles}$_"; } qw( /doc/xml/ /contrib/doc/xml/ ) ) {
     dbg( "parsing xml files in $path for key/context/URL info" );

    foreach my $xmlfile ( glob("${path}*.xml") ) { # $path ends in a /

 	dbg( "+++ Processing file: $xmlfile" );

	my ( $id, $obj ) = inspect_xmlfile( $xmlfile, $stylesheets );
	next unless defined $id;

	my ( $key, $context, $pkg, $groups, $htmlname ) =
	  get_ahelp_items( $obj, "key", "context", "pkg", "seealsogroups", "htmlname" );

	my $site = find_ahelp_site $key, $pkg;

	# NOTE:
	#   rather than die on a multiple, we just ignore the
	#   multiple occurrences. this allows HTML files to be
	#   generated even if something is a bit screwy.
	#
	if ( exists $out{$id} ) {
	    print "WARNING: multiple key=$key context=$context files - ignoring $xmlfile\n";
	    next;
	}

	# store the data
	$out{$id} = $obj;
	check_multi_key( $key, %multi_key );

	# safety check
	check_htmlname( $obj );

	# add to list of "see also" groups (if not known);
	foreach my $grp ( @$groups ) {
	    $seealso{$grp} = {} unless exists $seealso{$grp};
	}

	# update context/alphabetical/directory list
	#
	# we use $id as the key since - at least for the alphabetical list - we
	# may have multiple occurrences of $key but with different contexts
	#
	# we use the same format of all these lists so that we can process
	# them the same way later on
	#
	my $lc = $list_context{$site};
	$$lc{$context} = {} unless exists $$lc{$context};
	${ $$lc{$context} }{$id} = $obj;

	my $fchar = uc(substr($key,0,1));
	my $la = $list_alphabet{$site};
	$$la{$fchar} = {} unless exists $$la{$fchar};
	${ $$la{$fchar} }{$id} = $obj;

	# it's useful to know what directories we are going to be storing the files in
	#
#	my $dname = $htmlname;
#	$dname =~ s{[^/]+$}{};
#	my $ld = $list_dirs{$site};
#	$$ld{$dname} = {} unless exists $$ld{$dname};
#	${ $$ld{$dname} }{$id} = $obj;

    } # foreach: $xmlfile

} # foreach: $path

## Now find out the "See Also" information
#
# - match up files with the see also groups
expand_seealso $listseealso, %seealso;

# - create the "See Also" XML files used by the ahelp pages
# - also update the matchkeys flag in the object
#   (done here since we're looping through the XML files again and
#    %multi_key should be up-to-date now)
#
create_seealso_files $storage, %out;

# write out the files which list all the ahelp files
# and useful information about them (summary, parameter lists, ...)
#
create_index_files $storage, %out, %list_alphabet, %list_context;

# End of script
#
exit;

## Subroutines
#

# internal routine used by get_ahelp_items()/set_ahelp_item()
# - faking an object
sub _check_object ($@) {
    my $obj = shift;

    my @c = caller(1);

    die "Usage error: $c[3] not called with correct object (file=$c[1] line=$c[2])\n"
      unless defined($obj) && ref($obj) eq "HASH";

    foreach my $key ( @_ ) {
	die "object missing field $key for $c[3] (file=$c[1] line=$c[2])\n"
	  unless exists $$obj{$key};
    }

} # sub: _check_object;

# $val = get_ahelp_items( $obj, $name );
# ( $val1, $val2 ) = get_ahelp_items( $obj, $val1, $val2 );
#
# returns the items listed in the object
# (semi OO practices going on here)
#
sub get_ahelp_items ($@) {
    my $obj = shift;
    _check_object( $obj, @_ );
    my @out;
    foreach my $val ( @_ ) { push @out, $$obj{$val}; }
    return wantarray ? @out : $out[0];

} # sub: get_ahelp_items

# $val = get_ahelp_item_if_exists( $obj, $name );
#
# returns the item listed in the object, if it exists,
# otherwise returns undef.
#
sub get_ahelp_item_if_exists ($$) {
    my $obj = shift;
    my $key = shift;

    return exists $$obj{$key} ? $$obj{$key} : undef;
} # sub: get_ahelp_item_if_exists

# set_ahelp_item( $obj, $name, $newval );
#
# sets the item $name in the object to $newval
# (can only change existing items)
# (semi OO practices going on here)
#
sub set_ahelp_item ($$$) {
    my $obj = shift;
    my $name = shift;
    my $nval = shift;
    _check_object( $obj, $name );
    $$obj{$name} = $nval;

    # calculate derived properties
    # - this assumes that htmlname is only ever set via the
    #   set_ahelp_item() call
    #
    if ( $name eq "htmlname" ) {
	my @split = split( /\//, $nval );
	$$obj{depth} = 1 + $#split;
    }

} # sub: set_ahelp_item

# check_multi_key( $key, \%mkey );
#
# sets the necessary field in %mkey if $key is already known about
#
sub check_multi_key ($\%) {
    my $key = shift;
    my $obj = shift;

    # do we have multiple matches for a given key?
    $$obj{$key} = 0 unless exists $$obj{$key};
    $$obj{$key}++;
    return;
} # sub: check_multi_key

# check_htmlname( $obj );
#
# We check that the htmlname is "sensible". It is not
# clear how useful/needed this is now we no longer need
# to support type=dist (>=CIAO 4).
#
# If we find a 'problem' we print a message to STDERR
# but continue processing.
#
sub check_htmlname ($) {
    my $obj = shift;
    _check_object( $obj, "htmlname", "filehead" );

    my $h = $$obj{htmlname};
    my $f = $$obj{filehead};
    print STDERR "WARNING: html mismatch for $f.html\n"
      unless $h eq $f;

#    if ( $htmlname ne "${filehead}.html" ) {
#      push @temp_address_fixes, $filehead;
#      $htmlname = $filehead;
#  }

    return;

} # sub: check_htmlname()

# expand_seealso $listseealso, \%seealso;
#
# Takes the list of seealso groups (keys of %seealso)
# and finds - via the $listseealso program - all the key/context
# pairs of files that are in this group
#
sub expand_seealso ($\%) {
    my $listseealso = shift;
    my $href        = shift;

    #
    # - now, we are guaranteed that the output is in the seealso order
    #   but it's not worth using this knowledge in the algorithm below
    #
    # $listseealso is a small C++ program that queries the ahelp DB
    # for the seealso groups for a given keyword (global variable)
    #
    my $keys = join( " ", keys %{ $href } );
     dbg( "parsing ahelp DB file to find seealsogroup members:" );
     dbg( "  $keys\n" );
    my $fh = IO::File->new( "$listseealso $keys |" )
      or die "Error: Unable to run $listseealso\n";
    while ( <$fh> ) {
	chomp;
	my ( $grpname, $context, $key ) = split;
	my $aref = $$href{$grpname};
	$$aref{$context} = [] unless exists $$aref{$context};
	push @{ $$aref{$context} }, $key;
    }
    $fh->close;
    return;

} # sub: expand_seealso()

# ( $id, $obj ) = inspect_xmlfile( $filename, $styledir )
#
# parses the XML file $filename (includes full path to the file).
# We return ( undef, undef ) if it is not a file we want to include
# $styledir gives the location of the stylesheets
#
# $id is the 'mangled' key/concept values for this file
# and $obj is a hash reference describing the file (although the user
# should just treat it as an opague thingy).
#
# what to do about isis - ie url => http:// -- I think we should just replace
# it -- since otherwise we need to adapt all the link codes to handle the
# case that a link could be an external one rather than internal. I guess
# we could set the depth to -1 and trap that but it is an effort for
# only one file (at the moment).
#
# Obviously not an ideal solution - we need to come up with guidelines for
# the ASSRESS/URL tags
#
# CIAO 4 introduced displayseealsogroups which are similar to the seealsogroups
# values but do not add the current file to the group list. I do not think
# we need to bother about this distinction, so I combine the two here
# -- ie get_ahelp-item($obj,"seealsogroups") will return the contents
# of both the seealsogroups and displayseealsogroups attributes
#
# NOTE: as no longer need the type=dist output this would be much
# better/easier/cleaner/understandable if I used XML::LibXML to extract
# the data directly from the XML file rather than have to bother with
# parsing the output of stylesheets
#
sub inspect_xmlfile ($$) {

  my $xmlfile  = shift;
  my $styledir = shift;

  my $dom = read_xml_file( $xmlfile );
  my $droot = $dom->documentElement();
  my $entry = $droot->find('ENTRY');

  # I don't understand why a NodeList can be returned here,
  # so just hack around it
  #
  $entry = $entry->get_node(1)
    if ref $entry eq "XML::LibXML::NodeList";

  # Extract information from the XML file, as long as it is
  # not an ENTRY[@key='onapplication'] file
  #
  return (undef,undef) if $entry->findvalue('@key="onapplication"') eq "true";

  # just used for the temporary ADDRESS/URL hack
  my $filehead = extract_filename $xmlfile;
  $filehead =~ s/\.xml$//;

  my $key     = $entry->findvalue('normalize-space(@key)');
  my $context = lc $entry->findvalue('normalize-space(@context)');

  # set a default value for pkg
  my $pkg = "ciao";
  my $pkgtemp     = lc $entry->findvalue('normalize-space(@pkg)');
  if (defined $pkgtemp) {
      $pkg = $pkgtemp;
  }

  # create single id
  my $id = mangle( $key, $context );

  my $htmlname = $filehead;

  # bring back the hack in which we convert http URL's to the
  # file name, since it makes our lives easier elsewhere in the
  # XSL transformations.
  #
  if ( $htmlname =~ /^http/ ) {
      print "NOTE: URL $htmlname -> $filehead\n";
      $htmlname = $filehead;
  }

  # Grab the seealsogroups and displayseealsogroups values. We grab the
  # strings (with excess spaces removed from its ends), split on white space,
  # and convert to lower case. We convert to a hash and then back again to
  # remove duplicated values, as a defensive measure.
  #
  my @dummy = 
    map { ($_, 1); }
      split( " ",
	     lc $entry->findvalue('concat(normalize-space(@seealsogroups)," ",normalize-space(@displayseealsogroups))')
	   );
  my %dummy = @dummy;
  my @seealsogroups = keys %dummy;

  # Provide visual feedback to say that a file that need a summary added
  #
  my $summary = $entry->findvalue('normalize-space(SYNOPSIS)');
  print STDERR "WARNING: key=$key context=$context has NO summary block\n"
    if $summary eq "";

  # safety check
  die "Error: HTML output name for key=$key context=$context is $htmlname which clashes with the index pages\n"
    if $htmlname =~ /^index(_alphabet|_context)$/;

  # do we need to worry about parameters?
  # - the following relies on the ahelp file being valid
  #
  my $paramlist = [];
  foreach my $param ( $dom->getElementsByTagName( "PARAM" ) ) {
    my $name = $param->getAttribute( "name" );
    my $synopsis = protect_xml_chars_for_printf $param->findvalue( "SYNOPSIS" );

    # remove excess whitespace/newlines
    $synopsis =~ s/^\s+//;
    $synopsis =~ s/\s+$//;
    $synopsis =~ s/\n/ /g;
    $synopsis =~ s/\s+/ /g;
    push @$paramlist, [ $name, $synopsis ];
  }

  # we need to define all the valid keys here, even if we do not set them
  # to a valid value
  #
  # we set the htmlname individually so that the depth field gets updated correctly
  my $out =
    {
     key => $key, context => $context, pkg => $pkg, id => $id,
     filename => $xmlfile, filehead => $filehead, htmlname => undef,
     seealsogroups => \@seealsogroups,
     summary => $summary,
     matchkey => undef, depth => undef, seealsofile => undef,
     paramlist => $paramlist,
    };
  set_ahelp_item( $out, htmlname => $htmlname );
  return ( $id, $out );

} # sub: inspect_xmlfile()

# ( $listref, $flag ) = parse_groups $key, $context, $grouplist, \%seealso;
#
# return a hash reference (keys = context) to the
# ahelp files in the "See Also" groups listed in
# $grouplist (an array reference).
#
# We EXCLUDE the file itself from the list
#
# $flag is set to 1 if there is at least one match
# (otherwise it is 0).
#
# The value of each $listref key is itself a hash reference,
# with keys being the key value for the ahelp file.
#
sub parse_groups ($$$\%) {
    my $key     = shift;
    my $context = shift;
    my $grplist = shift;
    my $seealso = shift;

    my %list;
    my $flag = 0;

    foreach my $grp ( @$grplist ) {
	 dbg( "  -- group = $grp" );
	while ( my ( $ctxt, $aref ) = each %{ $$seealso{$grp} } ) {

	    # remove the current file from the seealso list
	    #
	    my @keylist = grep { $ctxt ne $context or $_ ne $key } @{$aref};
	    next if $#keylist == -1;

	    # $ctxt is the context and $aref a list of keys
	    #
	    # a little bit of perl trickery to add key=>1 sets
	    # to the hash array (so that we can do an alphabetical
	    # sort later). Since we don't mind overwriting
	    # the contents we just treat the hash array as a normal
	    # array and add on a load of key=>1 pairs
	    #
	    $list{$ctxt} = {} unless exists $list{$ctxt};
	    $list{$ctxt} = { %{ $list{$ctxt} }, map { ($_,1); } @keylist };
	    $flag = 1;

	} # while: $ctxt,$aref
    } #foreach: $grp

    return ( \%list, $flag );

} # sub: parse_groups()

# $out = protect_xml_chars_for_printf $in;
#
# converts $in (a string) into $out (also a string)
# where XML characters have been converted into entities
# (", <, and >)
# Also converts ' % ' to ' %% ' since the output string
# is going to be used by printf (or its variants )
#
sub protect_xml_chars_for_printf ($) {
    my $in = shift;
    my $out = $in;

    # handle XML characters
    #
    $out =~ s{"}{&quot;}g;
    $out =~ s{<}{&lt;}g;
    $out =~ s{>}{&gt;}g;
    $out =~ s{&}{&amp;}g;

    # since being used as part of a printf statement, protect % characters
    # - this is not guaranteed to be a sufficient check but should hopefully
    #   work for the cases we have
    $out =~ s{ % }{ %% }g;

    return $out;

} # sub: protect_xml_chars_for_printf()

# print_seealso_list $fh, $obj, $pkg, $listref, \%out
#
# We have the case that the see also list could contain files
# for which we are not creating an HTML version - mainly because
# the ADDRESS/URL value is 'wrong' but possibly some other reason.
# We keep these files in the "See Also" list but do not create a
# link for them.
#
# Unlike earlier versions of this code we have already removed the
# page itself from the list so we don't need to worry about that
# one.
#
# both these choices mean that we no longer need to worry about
# 'empty' context groups: every context included in $listref
# will have a non-empty see also lising.
#

sub print_seealso_list ($$$$\%) {
    my $fh      = shift;
    my $obj     = shift;
    my $pkg     = shift;
    my $listref = shift;
    my $objlist = shift;

    $fh->print( "<seealso>\n<dl>\n" );

    # output is in context order, alphabeticised
    # - we need to add on the depth of the ahelp file itself to the
    #   links in the seealso section, not the depth of the actual seealso file
    #
    my $depth = '../' x (get_ahelp_items($obj,'depth')-1);
    
    foreach my $scontext ( sort keys %$listref ) {

	$fh->print( "<dt><em>$scontext</em></dt>\n<dd>\n" );

	# we need to decide whether each entry should have a link or not
	# (ie if there is an object corresponding to the file in the
	#  object list).
	# We print each entry on its own line to avoid really-long lines
	# (which seemed to cause problems somewhere)
	# and we also have to worry about quoting characters
	#
	$fh->printf(
		    join(
			 # the \n is to avoid really-long lines
			 ",\n",
			 map
			 {
			     my $skey = $_;
			     
			     # are we creating a HTML file for this object?
			     #
			     if ( exists $$objlist{ mangle($skey,$scontext) } ) {

				 my $sout = $$objlist{ mangle($skey,$scontext) }; 
				 my ( $summary, $filename ) = get_ahelp_items( $sout, 'summary', 'htmlname' );

				 my $ahelp_site = find_ahelp_site $skey, $pkg;

				 $summary = protect_xml_chars_for_printf $summary;
				 
				 # ecg: I don't know if this will break should depth actually be defined
				 #      Have never run into a non-empty depth variable [13 July 2010]

				 "<a href='/" . $ahelp_site . "/ahelp/" . $depth . $filename . ".html' title=\"Ahelp: " .
				   $summary . '">' . $skey . "</a>";

			     } else {
				 $skey;
			     }

			 } sort keys %{ $$listref{$scontext} }
			)
		   );

	$fh->print( "\n</dd>\n" );

    } # foreach my $scontext

    $fh->print( "</dl>\n</seealso>\n" );

    return;

} # sub: print_seealso_list()

# this sorts a list so that those words beginning with _ are moved
# to the end of the list. Very simple.
#
sub my_alphabetical_sort { my $x=$a;my $y=$b; $x=~ s/_/zzz/g;$y=~ s/_/zzz/g; $x cmp $y; }

sub print_site_list_to_index ($$$$) {
    my $fh   = shift;
    my $name = shift;
    my $site = shift;
    my $list = shift;

    $fh->print( "<${name} site='$site'>\n" );

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

    return;

} # sub: print_site_list_to_index

# We only print out the list for a given site if it is not
# empty.
#
sub print_list_to_index ($$$) {
    my $fh   = shift;
    my $name = shift;
    my $list = shift;

    foreach my $site ( keys %$list ) {
      print_site_list_to_index $fh, $name, $site, $$list{$site}
	if scalar keys %{$$list{$site}};
    }

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
} # mangle

# create_seealso_files $storage, \%out;
#
# creates
#    $storage/seealso.<context>.<key>.xml
#
# Global variables:
#    %multi_key
#    %seealso
#
sub create_seealso_files ($\%) {
  my $storage = shift;
  my $objlist = shift;

  foreach my $obj ( values %$objlist ) {
    my ( $key, $context, $pkg, $grplist ) = get_ahelp_items( $obj, "key", "context", "pkg", "seealsogroups" );
    dbg( "Creating seealso info for $key/$context" );

    # record how many matches this key has
    set_ahelp_item( $obj, "matchkey", $multi_key{$key} );
    
    # get the key/context values of all the files in the See Also
    # section (excluding this file)
    #


    my ( $listref, $flag ) = parse_groups $key, $context, $grplist, %seealso;


    my $seealso_head = "seealso.$context.$key.xml";
    my $ofile = "${storage}$seealso_head";
     dbg( " -- about to create $ofile" );
    myrm( $ofile );
    my $fh = IO::File->new( "> $ofile" )
      or die "Error: Unable to create $ofile\n";
    
    $fh->print( '<?xml version="1.0" encoding="us-ascii" ?>' . "\n" .
		"<!DOCTYPE seealso>\n" );
    
    if ( $flag ) { print_seealso_list $fh, $obj, $pkg, $listref, %$objlist; }
    else         { $fh->print( "<seealso/>\n" ); }
    
    $fh->close();
    mysetmods( $ofile );
    
    # store the name of the seealso file in the 'object'
    #
    set_ahelp_item( $obj, seealsofile => $ofile );
    
  } # foreach: $obj
} # sub: create_seealso_files


# create_index_files $dirname, \%out, \%list_alphabet, \%list_context;
#
# creates
#    $dirname/ahelpindex.xml
#    $dirname/ahelpindex.dat
#
# which lists all the info we need - in XML and text format - about the
# XML files.
#
# We also add in information about all the parameters that
# each XML file contains (so that ahelp tags can have this
# as their title attribute rather than the summary of the
# ahelp file itself).
#
# ahelpindex.dat is created to make mk_ahelp_pages.pl easier to
# code - it just lists the mapping between XML file name and the
# file name used for the HTML file. This way we can avoid
# excessive processig (such as processing the ahelp file to get the
# names of the files it will create, only to then re-process the
# file to actually do the conversion). As of CIAO 4 we probably
# do not need this since we could just always use the XML ahelp
# index file.
#
# Format of ahelpindex.dat
#    <xml name>  <depth>  <head of html name>  <seealso filename (without path)>
# (I do not believe that we need to encode site information in this file)
#
# NOTE:
#   how do we handle the difference between contrib and main?
#   - at the moment assume all the HTML files live in the same directory
#
#   It is okay if the depth attribute is '' for the ahelpindex/ahelplist/ahelp/page
#   attribute, since here depth is the actual path fragment to use (eg
#   '../') and not a numeric value. This is just a reminder to self.
#
sub create_index_files ($\%\%\%) {
    my $dirname = shift;
    my $objlist = shift;
    my $list_a  = shift;
    my $list_c  = shift;

    my $xmlfile = "${dirname}/ahelpindex.xml";
    my $datfile = "${dirname}/ahelpindex.dat";

    # create the index files
    dbg( "Creating the index files in: $dirname\n" );

    # First handle the text version
    #
    print_ahelplist_to_txtindex $datfile, $objlist;

    # Now the XML version
    #
    myrm( $xmlfile );
    my $xmlfh = IO::File->new( "> $xmlfile" )
      or die "Error: unable to open $xmlfile for writing\n";

    $xmlfh->print( '<?xml version="1.0" encoding="us-ascii" ?>' . "\n" .
		   "<!DOCTYPE ahelpindex>\n" .
		   "<ahelpindex>\n"
		 );

    # Print out the list of ahelp files.
    #
    print_ahelplist_to_xmlindex $xmlfh, $objlist;

    # print out the alphabetical and contextual lists to the index file
    #
    print_list_to_index $xmlfh, "alphabet",   $list_a;
    print_list_to_index $xmlfh, "context",    $list_c;
    ##print_list_to_index $xmlfh, "directory", $list_d;

    $xmlfh->print( "</ahelpindex>\n" );
    $xmlfh->close();

    mysetmods( $xmlfile );

} # sub: create_index_files()

# print_ahelplist_to_txtindex $filename, $objlist;
#
# prints the list of ahelp files to the text file.
# We do not have to bother about the site of the
# ahelp file, at least for now.
#
# This has been separated out from the XML file index
# file, to allow for future changes, although at
# present it would be more efficient to process both
# in the same loop.
#
sub print_ahelplist_to_txtindex ($$) {
  my $datfile = shift;
  my $objlist = shift;

  myrm( $datfile );
  my $datfh = IO::File->new( "> $datfile" )
    or die "Error: unable to open $datfile for writing\n";
  foreach my $out ( values %$objlist ) {

    my ( $key, $context, $pkg, $id, $h, $d, $xmlname, $seealso ) =
      get_ahelp_items( $out,
		       "key", "context", "pkg", "id", "htmlname",
		       "depth",
		       "filename", "seealsofile"
		     );
      
    # now print the data to the 'dat' file
    # - note we do not want the full path of $xmlname or the seealso file
    #
    if ( $h =~ /^http/ ) {
      $h = extract_filename($xmlname);
      $d = 1;
    }
    $datfh->printf( "%s %d %s %s\n",
		    extract_filename $xmlname,
		    $d, $h,
		    extract_filename $seealso );
  }
  $datfh->close();
  mysetmods( $datfile );
} # print_ahelplist_to_txtindex

# print_ahelplist_to_xmlindex $xmlfh, $objlist;
#
# prints the list of ahelp files to the XML file
# (order does not matter, although I guess it could
# do when searching).
#
# As of CIAO 4 we have to worry about the site for the page.
#
sub print_ahelplist_to_xmlindex ($$) {
  my $xmlfh   = shift;
  my $objlist = shift;

  $xmlfh->print( "<ahelplist>\n" );
  foreach my $out ( values %$objlist ) {

    my ( $key, $context, $pkg, $id, $h, $d, $summary, $mkey, $paramlist, $fname ) =
      get_ahelp_items( $out,
		       "key", "context", "pkg", "id", "htmlname",
		       "depth", "summary", "matchkey",
		       "paramlist", "filename"
		     );

    # what site are we: ciao, chips, or sherpa
    #
    my $ahelp_site = find_ahelp_site $key, $pkg;

    # normalise the space in the summary - including within the string (not really necessary)
    $summary =~ s/\s+/ /g;

    # NOTE:
    #   key, context, and page are okay to print as is,
    #   but we need to protect < and & in the summary
    #   - there should be no reason why we can't change them
    #     (although need care for & so &amp; isn't converted)
    #
    $summary =~ s/</&lt;/g;
    $summary =~ s/&\s/&amp; /g;
    $summary =~ s/&$/&amp;/;

    $xmlfh->printf( "<ahelp id='%s' samekey='%d'><key>%s</key><context>%s</context><site>%s</site><page depth='%s'>%s</page>\n",
		    $id, $mkey, $key, $context, $ahelp_site, '../' x ($d-1), $h );
    $xmlfh->printf( "<xmlname>%s</xmlname>\n", $fname );
    $xmlfh->printf( "<summary>%s</summary>\n", $summary );

    # list the name and synopsis for each parameter
    #
    if ( $#$paramlist != -1 ) {
      $xmlfh->printf( "<parameters>\n" );
      my $ctr = 1;
      foreach my $param ( @$paramlist ) {
	$xmlfh->printf( "<parameter pos='$ctr'><name>$$param[0]</name><synopsis>$$param[1]</synopsis></parameter>\n" );
	$ctr++;
      }
      $xmlfh->printf( "</parameters>\n" );
    } # if: $#$paramlist

    $xmlfh->printf( "</ahelp>\n" );

  }
  $xmlfh->print( "</ahelplist>\n" );

} # print_ahelplist_to_xmlindex
