
# $Id: CIAODOC.pm,v 1.7 2004/02/13 22:51:29 dburke Exp $
#
# Aim:
#   Useful routines for the CIAO documentation system.
#
# Author:
#  Doug Burke (dburke@cfa.harvard.edu)
#
# History:
#  02 Oct 03 DJB Introduced due to reworking of ahelp2html.pl into
#                multiple scripts & using the config file directly
#  13 Feb 04 DJB removed warning message about protecting params as seems
#                to work
#

#
# Global (ie in package main) variables used by this module
#   $configfile
#   $verbose
#   $group
#   $ldpath
#   $xsltproc
#   $htmllib
#   $htmldoc
#   $site
#

package CIAODOC;

use strict;
$|++;

use Carp;
use Cwd;
use IO::File;

my @funcs_util =
  qw(
     fixme dbg check_dir mymkdir mycp myrm mysetmods
     check_paths check_executables
     extract_filename
    );
my @funcs_xslt = qw( make_params translate_file create_hardcopy );
my @funcs_cfg  =
  qw(
     parse_config find_site get_config_main get_config_site get_config_version
     get_config_type
     check_config_exists check_type_known check_location get_group
    );

use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

@ISA    = qw ( Exporter );
@EXPORT = ();
@EXPORT_OK = ( @funcs_util, @funcs_xslt, @funcs_cfg );
%EXPORT_TAGS =
  (
   util => \@funcs_util, xslt => \@funcs_xslt, cfg => \@funcs_cfg,
  );

## Subroutines (see end of file)
#
sub fixme ($);
sub dbg ($);
sub check_dir ($$);
sub mymkdir   ($);
sub mycp      ($$);
sub myrm      ($);
sub mysetmods ($);

sub check_paths (@);
sub check_executables (@);

sub extract_filename ($);

sub make_params (@);
sub translate_file ($$$);
sub create_hardcopy ($$;$);

sub parse_config ($);
sub find_site ($$);
sub get_config_main ($@);
sub get_config_site ($@);
sub get_config_version ($@);
sub get_config_type ($$$);
sub check_config_exists ($$);
sub check_type_known ($$);

sub check_location ($$);
sub get_group ($);

## Subroutines
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

sub dbg ($) { print ">>DBG: $_[0]\n" if $main::verbose; }

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
	     system "/usr/bin/chgrp $main::group $dhead" and die "Unable to chgrp $main::group $dhead";
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
    system "/usr/bin/chgrp $main::group $name" and die "Unable to chgrp $main::group $name";

} # sub: mysetmods()

# check_paths( $path1, $path2, ... )
#
# checks that the input paths are directories and that they end in a /
# character. dies if they don't.
#
sub check_paths (@) {
    foreach my $path ( @_ ) {
	die "Error: unable to find the directory $path\n"
	  unless -d $path;
	die "Error: path $path does not end in a / character.\n"
	  unless $path =~ /\/$/;
    }
    return;
} # sub: check_paths()

# check_executables( $bin1, $bin2, ... )
#
# checks that the input fiels are executable
# dies if they aren't.
#
sub check_executables (@) {
    foreach my $exe ( @_ ) {
	die "Error: unable to find the executable $exe\n"
	  unless -x $exe;
    }
    return;
} # sub: check_exectuables()

# my $fname = extract_filename( $fullname );
#
# returns everything after the last '/' character
# should really use the filename-parsing routines
#
sub extract_filename ($) { return (split( "/", $_[0] ))[-1]; }

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

		     print STDERR "--- parname $parname has no defined value\n" unless defined $parval;

		     $parval = "''" if !defined($parval) or $parval eq "";
#		     $parval = "''" if $parval eq "";

		     # try and protect spaces in any arguments
		     #
		     if ( $parval =~ / / && $parval !~ /^['"]/ ) {
			 $parval = "'${parval}'";
##			 print STDERR "--- protecting parameter value [$parval]\n";
		     }

		     "--stringparam $parname $parval "
		 } keys %hash );
} # sub: make_params()

# run the processor and return the screen output
#
# uses the global variables $xsltproc and $ldpath
# and we *always* add a --novalid option here
# (since we don't have a proper catalog/location for the DTDs)
#
# I have decided to go back to the "fail on error" condition
# since it's more useful - we'll keep the old code around
# since it may be useful (e.g. for testing)
#

=begin ALLOWERROR

# since we no longer die on error it can be easy to miss runs
# that fail. Therefore we keep a counter that is used to determine
# behaviour on exit (ie message to STDERR and exit(1) if there was an
# error)
#
# We return undef on error (I guess this could be a valid return value
# of the transformation, but i doubt it)
#
my $_translate_errors = 0;
END {
    if ( $_translate_errors ) {
	print STDERR "\nERROR: $_translate_errors translations failed!\n";
	exit( 1 );
    }
}

=end ALLOWERROR

=cut

sub translate_file ($$$) {
    my $params     = shift;
    my $stylesheet = shift;
    my $xml_file   = shift; # with/without trailing .xml
    $xml_file .= ".xml" unless $xml_file =~ /\.xml$/;

    dbg "*** XSLT (start) ***";
    dbg "  in=$xml_file";
    dbg "  xslt=$stylesheet";
    dbg "  *** params (start) ***";
    foreach my $p ( split /--/, $params ) {
        next if $p =~ /^\s*$/;
        dbg "    --$p";
    }
    dbg "  *** params (end) ***";

    my $retval = `/usr/bin/env LD_LIBRARY_PATH=$main::ldpath $main::xsltproc --novalid $params $stylesheet $xml_file`;

    die <<"EOE" unless $? == 0;
Error: problems using $stylesheet
       error in XML file ($xml_file)?
       return value was:
$retval

EOE

=begin ALLOWERROR

    unless ( $? == 0 ) {
	$_translate_errors++;
	print <<"EOE";
Error: problems using $stylesheet
       error in XML file ($xml_file)?
       discading return value of "$retval"
EOE
	$retval = undef;
    }

=end

=cut

    dbg "*** XSLT (end) ***";
    return $retval;

} # sub: translate_file()

## create the hardcopy versions of the files
#
# create_hardcopy $dir, $head
# create_hardcopy $dir, $hthml_head, $out_head
#
# creates $dir/$head.[letter|a4].pdf
# and deletes the hardcopy version of the file once it's finished with
#
# uses the global variables $main::htmldoc, $main::htmllib, and $main::verbose
#
# NOTE: there is now almost no screen output unless verbose is set
#
sub create_hardcopy ($$;$) {
    my $indir = shift;
    my $html_head = shift;
    my $out_head  = shift || $html_head;

    my $in = "${indir}${html_head}.hard.html";

    dbg "Creating hardcopy formats:";
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

	    `/usr/bin/env LD_LIBRARY_PATH=$main::htmllib $main::htmldoc --webpage --duplex --size $size -f $out $in 2>&1 >/dev/null`;
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

	    dbg "  created: ${out_head}.${size}.${type}";

	} # foreach: $type
    } # foreach: $size

    # clean up the hardcopy file now we've finished with it
    myrm $in;

    return;

} # sub: create_hardcopy

#---------------------------------------------------------------------
#
# Configuration:
#
# my $config = parse_config $filename
#
# parse the config file
# returns a reference to an associative array
#
sub parse_config ($) {
    my $infile = shift;

    # check the options
    die "Error: the config option can not be blank\n"
      unless defined $infile and $infile ne "";

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

# $val = get_config_main( $config, $name );
# ( $val1, $val2 ) = get_config_main( $config, $name1, $name2 );
#
# returns the value of the config variables from the "main" part
# of the config file - ie the part that is not dependent upon the
# site you are in
#
# Dies with an error if the requested value doesn't exist
#
sub get_config_main ($@) {
    my $config = shift;
    my @out;
    foreach my $name ( @_ ) {
	die "Error: $name not defined in config file ($main::configfile).\n"
	  unless exists $$config{$name};
	push @out, $$config{$name};
    }
    return wantarray ? @out : $out[0];

} # sub: get_config_main()

# $val = get_config_site( $site_config, $name );
# ( $val1, $val2 ) = get_config_site( $site_config, $name1, $name2 );
#
# returns the value of the config variables from the "site" part
# of the config file - ie the value returned by get_config_site
#
# Dies with an error if the requested value doesn't exist
#
sub get_config_site ($@) {
    my $config = shift;
    my @out;
    foreach my $name ( @_ ) {
	die "Error: $name not defined in site part of config file (site=$main::site, file=$main::configfile).\n"
	  unless exists $$config{$name};
	push @out, $$config{$name};
    }
    return wantarray ? @out : $out[0];

} # sub: get_config_site()

# $val = get_config_version( $version_config, $name );
# ( $val1, $val2 ) = get_config_version( $version_config, $name1, $name2 );
#
# returns the value of the config variables from the "version" part
# of the config file.
#
# Dies with an error if the requested value doesn't exist
#
sub get_config_version ($@) {
    my $config = shift;
    my @out;
    foreach my $name ( @_ ) {
	die "Error: $name not defined in version part of config file ($main::configfile).\n"
	  unless exists $$config{$name};
	push @out, $$config{$name};
    }
    return wantarray ? @out : $out[0];

} # sub: get_config_version()

# $val = get_config_type $config, $name, $type;
#
# gets the value for the given variable ($name) with the
# publishing type ($type)
# dies if $name doesnt' exist, isn't a hash reference, or
# if the type isn't defined for this variable
#
sub get_config_type ($$$) {
    my $config = shift;
    my $name   = shift;
    my $type   = shift;

    die "Error: the config file did not contain a $name element\n"
      unless exists $$config{$name};
    my $obj = $$config{$name};
    my $ref = ref( $obj ) || "SCALAR";
    die "Error: the config file has $name as a $ref when it should be a HASH\n"
      unless $ref eq "HASH";
    die "Error: $name option does not contain a value for type=$type\n"
      unless exists $$obj{$type};
    return $$obj{$type};

} # sub: get_config_type

# $boolean = check_config_exists( $config, $name );
#
# returns 1 if $name exists in the config variable, 0 otherwise.
#
# Note: got tired of having different methods in case things changes so using one for
#   the moment
#
sub check_config_exists ($$) {
    my $config = shift;
    my $name   = shift;
    return exists $$config{$name};

} # sub: check_config_exists()

# check_type_known $site_config, $type
#
# dies unless the supplied type is allowed for this site
#
sub check_type_known ($$) {
    my $site_config = shift;
    my $type        = shift;

    my %_types = map { ($_,1) } @{ get_config_site( $site_config, "types" ) };
    die "Error: unknown type ($type) for this site ($main::site)\n"
      unless exists $_types{$type};
    return;
} # sub: check_type_known()

# ( $version, $config_version, $dhead, $depth ) = check_location $site_config, $dname;
#
# checks we're in the right place and sets up some necessary variables
#
sub check_location ($$) {
    my $site_config = shift;
    my $dname       = shift;

    my ( $site_prefix, $depth_offset, $vinfo ) = get_config_site $site_config, "prefix", "depth_offset", "versions";
    my $lp = length( $site_prefix );

    # find out what version we are in
    # $dname has previously been set to cwd()
    #
    # FIXME: this probably won't work well for type=dist?
    #
    die "Error: expected to be running within the $site_prefix directory structure\n"
      unless substr($dname,0,$lp) eq $site_prefix;
    die "Error: expected to be running in a sub-directory of $site_prefix\n"
      if $dname eq $site_prefix;

    my @dnames = split "/", substr($dname,$lp+1);
    my $version = shift @dnames;

    # do we know this version?
    # - note: we are cheating since, at this point, $vinfo isn't technically
    #   the version config variable. However, since we are just dealing with
    #   hash references we can use the same bit of code.
    #   which isn't exactly brilliant.
    #
    $vinfo = get_config_version $vinfo, $version;

    # are we locked?
    die "Error:\n   The pages for version=$version are locked from further publishing!\n"
      if check_config_exists $vinfo, "locked";

    my $dhead = join "/", @dnames;
    $dhead .= "/" unless $dhead eq "";

    # calculate the depth, including any offset from the config file
    my $depth = 2 + $#dnames + $depth_offset;

    return ( $version, $vinfo, $dhead, $depth );

} # sub: check_location

# $group = get_group $site_config;
#
# returns the group to use for the created pages (and
# checks that the user is a member of the group).
# dies on failuire
#
sub get_group ($) {
    my $site_config = shift;

    my $group = get_config_site $site_config, "group";

    # check the group
    my $allowed_groups = `groups`;
    chomp $allowed_groups;
    my %allowed_groups = map { ($_,1); } split " ", $allowed_groups;
    die "Error: group was set to $group but you are only a member of:\n    " .
      join( " ", keys %allowed_groups ) . "\n"
	unless exists $allowed_groups{$group};

    return $group;

} # sub: get_group()



## End
1;