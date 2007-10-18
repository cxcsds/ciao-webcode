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
#  12 Oct 07 DJB removed ldpath and htmllib options; we now encode this
#                information in the xsltproc and htmldoc options, which should
#                give the 'correct' way to call the code. It means we lose
#                the ability to check that the executable exists before
#                processing files, but makes it easier to run on multiple
#                OS's
#  15 Oct 07 DJB Initial support for having ahelp pages in multiple sites.
#  17 Oct 07 DJB Changed xslt processing to use XML::LibXSLT rather than xsltproc
#

#
# Global (ie in package main) variables used by this module
#   $configfile
#   $verbose
#   $group
#   $htmldoc
#   $site
#

package CIAODOC;

use strict;
$|++;

use Carp;
use Cwd;
use IO::File;

use XML::LibXML;
use XML::LibXSLT;

# Set up XML/XSLT processors
#
my $parser = XML::LibXML->new()
  or die "Error: Unable to create XML::LibXML parser instance.\n";
$parser->validation(0);

my $xslt = XML::LibXSLT->new()
  or die "Error: Unable to create XML::LibXSLT instance.\n";

# default depth is 250 but this causes problems with some style sheets
# (eg wavdetect, tg_create_mask), so increase randomly until everything
# compiles. Why did we not see this in the xsltproc command-line tool?
#
XML::LibXSLT->max_depth(750);

my @funcs_util =
  qw(
     fixme dbg check_dir mymkdir mycp myrm mysetmods
     check_paths check_executables check_executable_runs
     extract_filename get_ostype
     list_ahelp_sites find_ahelp_site check_ahelp_site_valid
    );
my @funcs_xslt =
  qw(
      translate_file translate_file_hardcopy create_hardcopy
   );
my @funcs_cfg  =
  qw(
     parse_config find_site get_config_main get_config_main_type
     get_config_site get_config_version get_config_type
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
sub check_executable_runs ($$$);

sub extract_filename ($);

sub translate_file ($$;$);
sub translate_file_hardcopy ($$$;$);
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

sub get_ostype ();
sub list_ahelp_sites ();
sub find_ahelp_site ($$);

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

# Hide the OS location of these calls; should use POSIX module instead?
#
sub call_mkdir ($) {
  my $dname = shift;
  system "/bin/mkdir $dname" and die "Unable to mkdir $dname";
}

sub call_chmod ($$) {
  my $opts = shift;
  my $name = shift;
  my $chmod = $^O eq "darwin" ? "/bin/chmod" : "/usr/bin/chmod";
  system "$chmod $opts $name" and die "Unable to chmod $opts $name";
}

sub call_chgrp ($$) {
  my $opts = shift;
  my $name = shift;
  system "/usr/bin/chgrp $opts $name" and die "Unable to chgrp $opts $name";
}

sub call_rm ($) {
  my $name = shift;
  my $rm = $^O eq "darwin" ? "/bin/rm" : "/usr/bin/rm";
  system "$rm -f $name";
  die "Error: been unable to delete $name\n"
    if -e $name;
}

sub call_cp ($$) {
  my $in = shift;
  my $out = shift;
  my $cp = $^O eq "darwin" ? "/bin/cp" : "/usr/bin/cp";
  system "$cp $in $out" and die "Unable to cp $in to $out";
}

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
	     call_mkdir $dhead;
	     call_chmod "ug+w", $dhead;
	     call_chgrp $main::group, $dhead;
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
    call_cp $in, $out;
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
    call_rm $name;

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

    call_chmod "ugo-wx", $name;
    call_chgrp $main::group, $name;

} # sub: mysetmods()

# check_paths( $path1, $path2, ... )
#
# checks that the input paths are directories and that they end in a /
# character. dies if they don't.
#
sub check_paths (@) {
    foreach my $path ( @_ ) {
	die "Error: unable to find the directory '$path'\n"
	  unless -d $path;
	die "Error: path '$path' does not end in a / character.\n"
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

# check_executable_runs( $name, $bin, $arg )
#
# checks that you can run the command $bin with the supplied
# argument and you get back status=0. Note that we use the
# "simple" eval method (as a single string) so there are
# security risks here.
#
sub check_executable_runs ($$$) {
  my $name = shift;
  my $exe  = shift;
  my $arg  = shift;

  my $retval = `$exe $arg`;
  die <<"EOE" unless $? == 0;
Error: Executable '$name' failed to run with argument
       '$arg'
       The return value was:
$retval

EOE
  return;
} # sub: check_executable_runs()

# my $fname = extract_filename( $fullname );
#
# returns everything after the last '/' character
# should really use the filename-parsing routines
#
sub extract_filename ($) { return (split( "/", $_[0] ))[-1]; }

# run the processor and return the screen output
#
# We now (as of CIAO 4 beta 3) use XML::LibXSLT to process the file,
# rather than call an external process (xsltproc)
#
{
  # add parsed stylesheets to an internal repository
  # in case they are needed again.
  #
  my %xslt_store;

  # Returns the parsed stylesheet, loading and storing
  # it if it hasn't already been loaded.
  #
  sub _get_stylesheet ($) {
    my $filename = shift;
    return $xslt_store{$filename} if exists $xslt_store{$filename};
    my $style = $xslt->parse_stylesheet_file ($filename) ||
      die "ERROR: unable to parse stylesheet '$filename'\n";
    $xslt_store{$filename} = $style;
    return $xslt_store{$filename};
  }

  # TODO:
  #   allow the return value to be XML and not assume plain text
  #
  # The XML file can be given by name, in which case the suffix
  # ".xml" is added if it doesn't exist, otherwise it can be
  # an XML::LibXML::Document
  #
  sub translate_file ($$;$) {
    my $stylesheet = shift;
    my $xml_arg    = shift;
    my $params     = shift || {};

    dbg "*** XSLT (start) ***";

    # Should do this properly (allow for sub-classes etc) but go
    # for the simple route
    #
    my $xml;
    if (ref $xml_arg eq "") {
      $xml_arg .= ".xml" unless $xml_arg =~ /\.xml$/;
      dbg "  reading XML from $xml_arg";
      $xml = $parser->parse_file ($xml_arg)
	or die "ERROR: unable to parse XML file '$xml_arg'\n";

    } elsif (ref $xml_arg eq "XML::LibXML::Document") {
      dbg "  XML is from a DOM";
      $xml = $xml_arg;

    } else {
      die "Expected xml_file argument to translate_file to be a string or XML::LibXML::Document, found " .
	ref $xml_arg . " instead!\n";
    }

    dbg "  xslt=$stylesheet";
    my $sheet = _get_stylesheet $stylesheet;

    dbg "  *** params (start) ***";
    my %newparams = XML::LibXSLT::xpath_to_string(%$params);
    while (my ($parname, $parval) = each %newparams) {
      dbg "    $parname=$parval";
    }
    dbg "  *** params (end) ***";

    # XXX TODO XXX
    #   trap errors
    my $results = $sheet->transform($xml, %newparams);
    my $retval  = $sheet->output_string($results);

    dbg "*** XSLT (end) ***";
    return $retval;

  } # sub: translate_file()

  # This is a common enough pattern that it is worth abstracting out
  # Note that the params assoc array will be changed by this routine.
  #
  # xml_arg can be a string, in which case it is assumed to be the
  # file name (a trailing ".xml" is added if ncessary) or
  # a XML::LibXML::Document object.
  #
  sub translate_file_hardcopy ($$$;$) {
    my $stylesheet = shift;
    my $xml_arg    = shift;
    my $params     = shift;
    my $hcopy      = shift || [0,1];

    my $hstr = join ",", @$hcopy;
    dbg "*** start XSLT processing (hardcopy=$hstr)";

    # Should do this properly (allow for sub-classes etc) but go
    # for the simple route
    #
    my $xml;
    if (ref $xml_arg eq "") {
      $xml_arg .= ".xml" unless $xml_arg =~ /\.xml$/;
      dbg "  reading XML from $xml_arg";
      $xml = $parser->parse_file ($xml_arg)
	or die "ERROR: unable to parse XML file '$xml_arg'\n";

    } elsif (ref $xml_arg eq "XML::LibXML::Document") {
      dbg "  XML is from a DOM";
      $xml = $xml_arg;

    } else {
      die "Expected xml_file argument to translate_file to be a string or XML::LibXML::Document, found " .
	ref $xml_arg . " instead!\n";
    }

    foreach my $hflag ( @$hcopy ) {
      $$params{hardcopy} = $hflag;
      translate_file $stylesheet, $xml, $params;
    }
    dbg "*** end XSLT processing (hardcopy=$hstr)";

  } # sub: translate_file_hardcopy()

}

## create the hardcopy versions of the files
#
# create_hardcopy $dir, $head
# create_hardcopy $dir, $hthml_head, $out_head
#
# creates $dir/$head.[letter|a4].pdf
# and deletes the hardcopy version of the file once it's finished with
#
# uses the global variables $main::htmldoc and $main::verbose
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

	    dbg "Start htmldoc call";
	    dbg "  $main::htmldoc --webpage --duplex --size $size -f $out $in";
	    `$main::htmldoc --webpage --duplex --size $size -f $out $in 2>&1 >/dev/null`;
	    dbg "End htmldoc call";

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

# $val = get_config_main_type( $config, $name, $type );
# ( $val1, $val2 ) = get_config_main( $config, $name1, $name2, $type );
#
# returns the value of the config variables from the "main" part
# of the config file - ie the part that is not dependent upon the
# site you are in - for the given type. This is for fields like
#    %foo=typea vala
#    %foo=typeb valb
# and get_config_main_type($config, "foo", "typeb") will return
# valb.
#
# Dies with an error if the requested value doesn't exist, or
# isn't an associative array, or the type does not exist.
#
sub get_config_main_type ($@) {
    my $config = shift;
    my $type   = pop;
    my @out;
    foreach my $name ( @_ ) {
	die "Error: $name not defined in config file ($main::configfile).\n"
	  unless exists $$config{$name};
	my $obj = $$config{$name};
	my $ref = ref ($obj) || "SCALAR";
	die "Error: the config file has $name as a $ref when it should be a HASH\n"
	  unless $ref eq "HASH";
	die "Error: $name option does not contain a value for type=$type\n"
	  unless exists $$obj{$type};
	push @out, $$obj{$type};
    }
    return wantarray ? @out : $out[0];

} # sub: get_config_main_type()

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


# $ostype = get_ostype;
#
# returns a string representing the OS that the system
# is running:
#     Return Value    System
#     sun             Solaris
#     lin             Linux
#     osx             OS-X
#
# It does not, at least at present, care about the processor
# type or version of the OS.
#
sub get_ostype () {
  if ($^O eq "darwin")     { return "osx"; }
  elsif ($^O eq "linux")   { return "lin"; }
  elsif ($^O eq "solaris") { return "sun"; }
  else {
    die "Unrecognized OS: $^O\n";
  }
} # sub: get_ostype()

# @sitelist = list_ahelp_sites();
#
# Returns an array reference listing all the sites we know
# about (for the ahelp pages)
#
sub list_ahelp_sites () {
  return qw( ciao chips sherpa );
}

# $site = find_ahelp_site $key, $context;
#
# returns the site in which the ahelp file is published,
# where the ahelp file is referred to by key and context
# values.
#
# The return value is one of
#    ciao
#    chips
#    sherpa
#
sub find_ahelp_site ($$) {
  my $key = shift;
  my $con = shift;
  if ($con =~ /chips$/) {
    return "chips";
  } elsif ($con =~ /sherpa$/) {
    return "sherpa";
  } else {
    return "ciao";
  }
} # sub: find_ahelp_site()

# check_ahelp_site $site;
#
# Dies if $site does not contain any ahelp files.
#
sub check_ahelp_site_valid ($) {
  my $site = shift;
  my %asites = map { ($_,1); } list_ahelp_sites;
  die "ERROR: Unknown site <$site> for ahelp indexes; expected one of:\n\t" .
    join (" ", list_ahelp_sites) . "\n"
      unless exists $asites{$site};
} # sub: check_ahelp_site_valid()

## End
1;
