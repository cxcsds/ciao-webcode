#
# Aim:
#   Useful routines for the CIAO documentation system.
#
# Author:
#  Doug Burke (dburke@cfa.harvard.edu)
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
use File::stat;
use File::Basename;
use File::Temp;

use XML::LibXML;
use XML::LibXML::XPathContext;
use XML::LibXSLT;

# Try to support using LaTeX (use_mathjax()=0) or MathJax
# (use_mathjax()=1) for displaying LaTeX equations on the
# web pages.
# For now treat as a hard-coded constant rather than something
# we can change by setting a flag in the publishing script.
#
# This is intended as a temporary measure; once MathJax can
# be installed onto the web site this can be removed, or
# it may become a per-site setting?
sub use_mathjax () { return 1; }

# Set up XML/XSLT processors
# (registration of functions happens later)
#
# NOTE: documentation seems to suggest that expand_entities is set to 1
#       but this no-longer holds, so explicitly set it.
#
my $parser = XML::LibXML->new(expand_entities => 1)
  or die "Error: Unable to create XML::LibXML parser instance.\n";
$parser->validation(0);
$parser->expand_xinclude(1); # NOTE: don't actually use XInclude at the moment

my $xslt = XML::LibXSLT->new()
  or die "Error: Unable to create XML::LibXSLT instance.\n";

# Set up potentially-useful functions. Ideally we would use
# register_element but this is not available using the
# installed version of XML::LibXSLT
#
# TODO: should read-file-if-exists report this information
#       as part of the dependency tracking?
XML::LibXSLT->register_function("http://hea-www.harvard.edu/~dburke/xsl/extfuncs",
				"read-file-if-exists",
  sub {
    my $filename = shift;
    # want to differentiate between 'file does not exist' and
    # 'file is invalid'.
    return XML::LibXML::NodeList->new()
	unless -e $filename;
    my $rval;
    eval { $rval = $parser->parse_file($filename); };
    die "ERROR: problem parsing XML file $filename\n  $@\n"
	if $@;
    return $rval;
  }
);

XML::LibXSLT->register_function("http://hea-www.harvard.edu/~dburke/xsl/extfuncs",
				"delete-file-if-exists",
  sub {
    my $filename = shift;
    eval { CIAODOC::myrm($filename); };
    die "ERROR: unable to delete $filename (requested by stylesheet)\n  $@\n"
	if $@;
    return 1;
  }
);

# default depth is 250 but this causes problems with some style sheets
# (eg wavdetect, tg_create_mask), so increase randomly until everything
# compiles. Why did we not see this in the xsltproc command-line tool?
#
# XML::LibXSLT->max_depth(750);
XML::LibXSLT->max_depth(2000);

my @funcs_util =
  qw(
     fixme dbg check_dir mymkdir mycp myrm mysetmods
     check_paths check_executables check_executable_runs
     extract_filename get_ostype
     list_ahelp_sites find_ahelp_site check_ahelp_site_valid
     get_pygments_styles
    );
my @funcs_xslt =
  qw(
     translate_file
     read_xml_file read_xml_string read_html_string
     find_xinclude_files
     find_math_pages
    );
my @funcs_cfg  =
  qw(
     parse_config find_site get_config_main get_config_main_type
     get_config_site get_config_version get_config_type
     check_config_exists check_type_known check_location get_group
     get_storage_location
    );
my @funcs_deps =
  qw(
     clear_dependencies get_dependencies have_dependencies
     dump_dependencies write_dependencies
     identify_files_to_republish
     use_mathjax
    );

use vars qw( @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS );

@ISA    = qw ( Exporter );
@EXPORT = ();
@EXPORT_OK = ( @funcs_util, @funcs_xslt, @funcs_cfg, @funcs_deps );
%EXPORT_TAGS =
  (
   util => \@funcs_util, xslt => \@funcs_xslt, cfg => \@funcs_cfg,
   deps => \@funcs_deps
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

sub read_xml_file ($);
sub read_xml_string ($);
sub read_html_string ($);
sub translate_file ($$;$);
sub translate_file_lang ($$$;$);

sub parse_config ($);
sub find_site ($$);
sub get_config_main ($@);
sub get_config_site ($@);
sub get_config_version ($@);
sub get_config_type ($$$);
sub check_config_exists ($$);
sub check_type_known ($$);
sub get_storage_location ($$);

sub check_location ($$);
sub get_group ($);

sub get_ostype ();
sub list_ahelp_sites ();
sub find_ahelp_site ($$);

sub clear_dependencies ();
sub get_dependencies ();

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
  my $chmod = $^O eq "solaris" ? "/bin/chmod" : "/bin/chmod";
  system "$chmod $opts $name" and die "Unable to chmod $opts $name";
}

sub call_chgrp ($$) {
  my $opts = shift;
  my $name = shift;
  my $chgrp = $^O eq "linux" ? "/bin/chgrp" : "/usr/bin/chgrp";
  system "$chgrp $opts $name" and die "Unable to chgrp $opts $name";
}

sub call_rm ($) {
  my $name = shift;
  my $rm = $^O eq "solaris" ? "/usr/bin/rm" : "/bin/rm";
  system "$rm -f $name";
  die "Error: been unable to delete $name\n"
    if -e $name;
}

sub call_cp ($$) {
  my $in = shift;
  my $out = shift;
  my $cp = $^O eq "solaris" ? "/usr/bin/cp" : "/bin/cp";
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

    dbg "Creating directory: $dname";

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
# checks that the input files are executable
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

  # Returns the DOM for the file or dies, although it may be that this
  # method already dies and I need to improve my error handling here.
  #
  # This routine need not be within this closure, but left here for now.
  #
  # We add the .xml suffix if it does not exist.
  #
  sub read_xml_file ($) {
    my $filename = shift;
    $filename .= ".xml" unless $filename =~ /\.xml$/;
    dbg " - about to read XML file '$filename'";
    $parser->parse_file($filename)
      or die "ERROR: unable to parse XML file '$filename'\n";
  }

  # Return the unique xinclude files found in the input XML file.
  # It returns an empty list if there are none.
  sub find_xinclude_files ($) {
    my $filename = shift;
    $filename .= ".xml" unless $filename =~ /\.xml$/;
    dbg " - about to read XML file '$filename' to find XInclude files";
    $parser->expand_xinclude(0);
    my $dom = $parser->parse_file($filename)
      or die "ERROR: unable to parse XML file '$filename'\n";
    $parser->expand_xinclude(1);

    my $context = XML::LibXML::XPathContext->new($dom);
    $context->registerNs("xi", "http://www.w3.org/2001/XInclude");

    my %out = ();
    foreach my $node ( $context->findnodes('//xi:include/@href') ) {
	$out{$node->nodeValue} = ();
    }
    my $nfound = keys %out;
    dbg "   - found $nfound XInclude file(s)";
    return sort keys %out;
  }

  # As read_xml_file but use the input string as the file
  # contents.
  #
  sub read_xml_string ($) {
    my $str = shift;
    my $firstline = (split(/\n/,$str))[0];
    dbg " - about to parse XML chunk, first line='$firstline'";
    $parser->parse_string($str)
      or die "ERROR: unable to parse XML string, start='$firstline'\n";
  }

  sub read_html_string ($) {
    my $str = shift;
    my $firstline = (split(/\n/,$str))[0];
    dbg " - about to parse HTML chunk, first line='$firstline'";
    $parser->parse_html_string($str)
      or die "ERROR: unable to parse HTML string, start='$firstline'\n";
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
      dbg "  reading XML from $xml_arg";
      $xml = read_xml_file $xml_arg;

    } elsif (ref $xml_arg eq "XML::LibXML::Document") {
      dbg "  XML is from a DOM";
      $xml = $xml_arg;

    } else {
      die "Expected xml_file argument to translate_file to be a string or XML::LibXML::Document, found " .
	ref $xml_arg . " instead!\n";
    }

    dbg "  xslt=$stylesheet";
    my $sheet = _get_stylesheet $stylesheet;

    # hard code the MathJax setting
    $$params{'use-mathjax'} = use_mathjax;

    dbg "  *** params (start) ***";
    my %newparams = XML::LibXSLT::xpath_to_string(%$params);
    while (my ($parname, $parval) = each %newparams) {
      dbg "    $parname=$parval";
    }
    dbg "  *** params (end) ***";

    # How do find out if there has been an error in the
    # transformation (e.g. xsl:message with terminate="yes"
    # called)? No error is thrown, so no point in using
    # an eval block (although left in just in case).
    # Is this a module version thing, ie only seen on
    # Sun with old code? Seems to be.
    #
#    my ($results, $retval);
#    eval {
    my $results = $sheet->transform($xml, %newparams);
    my $retval  = $sheet->output_string($results);
#    };
#    die "ERROR from transformation: $@\n" if $@;

    dbg "*** results = [$results]";
    dbg "*** as string =\n$retval";

    dbg "*** XSLT (end) ***";
    return $retval;

  } # sub: translate_file()

}

# Returns an array of all the name nodes within math tags
# in the file. If there are no math tags then returns an
# empty list.
#
# Should be sent a DOM
#
# NOTE:
#   This routine is not needed for MathJax, so we return
#   an empty list in this case.
#
sub find_math_pages ($) {
    return () if use_mathjax;

  my $dom = shift;

  # Should use a proper OO check here to allow sub-classes to match.
  #
  my $r = ref $dom;
  die "Error: expected a XML::LibXML::Document, but sent " . $r eq "" ? "scalar" : $r . "\n"
    unless $r eq "XML::LibXML::Document";

  my @out;
  foreach my $node ( $dom->findnodes("//math/name") ) {
    push @out, $node->textContent;
  }
  return @out;

} # find_math_pages

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

# Returns the location of the storage area (ie where we store the
# published version of a page + metadata) for a given site.
#
# $storageloc  - location of the storage file
# $site        - site name
#
sub get_storage_location ($$) {
  my $storageloc = shift;
  my $site = shift;

  my $dom = $parser->parse_file($storageloc);
  my $root = $dom->getDocumentElement();
  my $loc = $root->findvalue('/storage/dir[@site="' . $site . '"]');
  die "Unable to find site='$site' in $storageloc\n"
    if $loc eq "";
  return $loc;

} # sub: get_storage_location

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
  elsif ($^O eq "solaris") { die "ERROR: Doug did not expect this to be run on a Solaris box; please contact him\n"; return "sun"; }
  else {
    die "Unrecognized OS: $^O\n";
  }
} # sub: get_ostype()

# $hash = get_filehash $filename;
#
# Returns a hash of the file contents. This is only used for
# identifying when a file has changed. We could cache results,
# which would imply that the file is not expected to change whilst
# the code is running, but this may be problematic if publishing
# many files at once and so some do change! See get_filehash_cache()
# for explicit cacheing.
#
sub get_filehash ($) {
  my $file = shift;
  my $os = get_ostype;
  my $hash;

  # This is a stop gap whilst tracking down why ahelp processing
  # leads to attempts to access a releasenotes-related revdep
  # file (Dec 7 2015), but it may be left in as a general check.
  unless ( -e $file ) {
      print "WARNING: file does not exist - no md5 sum: ${file}\n";
      return undef;
  }

  # do not want to rely on an external module for this
  if ($os eq "osx") {
    $hash = `/sbin/md5 $file`;
    $hash = (split / /, $hash)[-1];
  } elsif ($os eq "lin") {
    $hash = `/usr/bin/md5sum $file`;
    $hash = (split / /, $hash)[0];
  } else {
    die "Internal error: ostype=${os} not handled by get_filehash\n";
  }
  chomp $hash;
  return $hash;

} # sub: get_filehash()

{
  my %filehash_cache = ();

  sub clear_filehash_cache () {
    %filehash_cache = ();
  }

  # get_filehash but caching the results
  # (see clear_filehash_cache)
  sub get_filehash_cache ($) {
    my $file = shift;
    if (exists $filehash_cache{$file}) {
      return $filehash_cache{$file};
    } else {
      my $hash = get_filehash $file;
      $filehash_cache{$file} = $hash;
      return $hash;
    }
  } # sub: get_filehash_cache

}

# @sitelist = list_ahelp_sites();
#
# Returns an array reference listing all the sites we know
# about (for the ahelp pages)
#
sub list_ahelp_sites () {
  return qw( ciao sherpa );
}

# $site = find_ahelp_site $key, $pkg;
#
# returns the site in which the ahelp file is published,
# where the ahelp file is referred to by key and context
# values.
#
# The return value is one of
#    ciao
#    sherpa
#
sub find_ahelp_site ($$) {
  my $key = shift;
  my $pkg = shift;

  if ($pkg eq "sherpa") {
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

# Pygments
#
# Use pygments to process the contents with the given language.
# The check for pygmentize should be done only once.
#
# Style sheet can be accessed with
#    pygmentize -f html -S default -a .highlight
#
# Note that to take advantage of the highlighting the code
# needs to either have access to the stylesheet in some
# manner - either included in the file or accessed from an
# external stylesheet.
#
sub get_pygments_styles() {
    my $PROG = "pygmentize";
    my $styles = `$PROG -f html -S default -a .highlight`;
    if ($? ne 0) {
	die 'Error: pygmentize is not available but we have screen[@lang]';
    }
    return $styles;
}

XML::LibXSLT->register_function("http://hea-www.harvard.edu/~dburke/xsl/extfuncs",
				"add-language-styles",
				sub {
				    my $lang = shift;
				    my $cts = shift;

				    if ($lang eq "none") {
					return $cts;
				    }

				    # If we don't have pygmentize just skip
				    # things. This should probably die
				    # instead but leave like this for
				    # testing (and we should have already
				    # checked for pygmnentize anyway).
				    #
				    my $PROG = "pygmentize";
				    `$PROG -V`;
				    if ($? ne 0) {
					dbg "pygmentize is not available - language=$lang";
					return $cts;
				    }

				    my $tfile = File::Temp->new(
					'TEMPLATE' => "pygmXXXXXX",
					'SUFFIX' => ".pyg");
				    $tfile->print($cts);

				    my $filename = $tfile->filename();
				    $tfile->close() and
					my $conv = `$PROG -f html -l $lang -O nowrap=true $filename`;

				    if ($conv eq "") {
					dbg "Unable to $PROG language $lang";
					return $cts;
				    }

				    return $conv;
				});


# Dependency tracking

{
  my %dependencies;

  # Clear the dependency information
  sub clear_dependencies () {
    if (scalar (keys %dependencies) == 0) {
      dbg "Clearing dependencies: already empty";
    } else {
      # Was going to dump the previous values but decided against it.
      dbg "Clearing dependencies:";
    }
    %dependencies = ();
  }

  # Return all the recorded dependencies as a hash reference
  sub get_dependencies () {
    return \%dependencies; # TODO: copy the hash
  }

  # returns 1 if there are any dependencies (ie page has not been skipped)
  # and 0 otherwise.
  sub have_dependencies () {
    return scalar (keys %dependencies) > 0;
  }

  # Display the dependency information via dbg messages
  sub dump_dependencies() {
    dbg "dependencies:";

    #while ( my ($key,$value) = each %dependencies ) {
    #  if (ref($value) eq "ARRAY") {
    #	dbg " key=$key vals=[@$value]";
    #  } elsif (ref($value) eq "HASH") {
    #	my @ans = map { $_ . "=>" . $$value{$_}; } keys(%$value);
    #	dbg " key=$key vals={" . join(" ", @ans) . "}";
    #  } else {
    #	dbg " key=$key vals=$value";
    #  }
    # }

    use Data::Dumper;
    dbg Dumper(\%dependencies);

  }

  # Take the current set of dependencies and
  # add in the hash values of files.
  #
  # Send in
  #   path to the stylesheet directory
  #   path to the parent directory of the output files (not supported)
  sub hash_dependencies($) {
    my $stylesheetdir = shift;
    #my $outdir = shift;
    my %out;

    while (my ($key, $vals) = each %dependencies) {
      if ($key eq "import") {
	# stylesheets used to process the file
	$out{$key} = {};
	foreach my $filename (@$vals) {
	  my $fullpath = $stylesheetdir . $filename;
	  $out{$key}{$filename} =
	    { hash => get_filehash_cache $fullpath,
	      filename => $fullpath };
	}
      } elsif ($key eq "ssi") {
	# For now we do not hash these values (it is
	# more complicated since need to cross sites)
	#
	$out{$key} = $vals;
      } elsif ($key eq "include") {
	# files that are read in and (potentially) used
	# in xpath; we do NOT cache these hash values
	$out{$key} = {};
	while (my ($ilabel, $ifilename) = each %$vals) {
	  $out{$key}{$ilabel} = { hash => get_filehash $ifilename,
				  filename => $ifilename };
	}
      } else {
	$out{$key} = $vals;
      }
    }
    return \%out;
  } # sub: hash_dependencies

  sub add_node ($$$);

  sub add_text_node ($$$) {
    my $parent = shift;
    my $name = shift;
    my $text = shift;
    my $node = XML::LibXML::Element->new($name);
    $node->appendText($text);
    $parent->appendChild($node);
  }

  sub add_array_node ($$) {
    my $parent = shift;
    my $values = shift;

    my $el = XML::LibXML::Element->new("array");
    $parent->appendChild($el);
    foreach my $aval (@$values) {
      add_text_node $el, "item", $aval;
    }
  }

  sub add_hash_node ($$) {
    my $parent = shift;
    my $values = shift;

    my $el = XML::LibXML::Element->new("hash");
    $parent->appendChild($el);
    while (my ($key, $value) = each %$values) {
      my $hel = XML::LibXML::Element->new("hitem");
      add_text_node $hel, "key", $key;
      add_node $hel, "value", $value;
      $el->appendChild($hel);
    }
  }

  sub add_node ($$$) {
    my $parent = shift;
    my $name   = shift;
    my $value  = shift;

    my $el = XML::LibXML::Element->new($name);
    $parent->appendChild($el);
    if (ref($value) eq "ARRAY") {
      add_array_node $el, $value;
    } elsif (ref ($value) eq "HASH") {
      add_hash_node $el, $value;
    } else {
      # assume a text node; guard against an undef (ideally they should
      # be caught before being sent here, but add this in as a check:
      # this was added to catch the ahelp-processing issue, when generating
      # an ahelp page would look for a dependency file in the releasenotes
      # that could be missing; Dec 7 2015. This is therefore a hack and not
      # a proper solution)
      $value = $value || "";
      $el->appendText($value);
    }

  } # sub: add_node

  # Given a file/directory name, return 1 if its group
  # name matches $main::group.
  #
  # It might be nice to use stat(..)->cando
  # but can not guarantee that we have that.
  #
  # This may not be sufficient, but hopefully the
  # publishing code enforces a sensible group value
  # for each file/directory.
  #
  sub grp_matches($) {
    my $name = shift;

    my $stat = stat($name);
    unless (defined $stat) {
	print "Warning: stat of non existant file/directory $name\n";
	return 0;
    }

    my @groupinfo = getgrgid($stat->gid);
    dbg "Checking group for $name = " . $stat->gid . " / ${groupinfo[0]} against $main::group";
    return $groupinfo[0] eq $main::group;

  } # sub: grp_matches

  # Add the dependency information.
  #
  sub add_dep_file ($$$) {
    my $storage = shift;
    my $name = shift;
    my $hdeps = shift;
    my $outfile = "${storage}${name}.dep";

    my $doc = XML::LibXML::Document->new();
    my $root = $doc->createElement("dependencies");
    $doc->setDocumentElement($root);

    add_text_node($root, "base", "${name}.xml");

    while (my ($key,$val) = each %$hdeps) {
      add_node $root, $key, $val;
    }

    myrm $outfile;
    $doc->toFile($outfile, 0); # do not bother with indention
    mysetmods $outfile;
    dbg("Created dependency file: $outfile");

  } # sub: add_dep_file

  # Add the reverse dependency information. We do not
  # look for "deletions" here (since would need to process
  # all the revdep files), instead these get cleaned up
  # when actually checking the dependency information.
  #
  # $revdepfile is the file on which the current page
  # $name.xml stored in $storage and user-editable found in
  # $userdir
  # ($revdepfile should end in xml and be a full path).
  #
  # We only do this IF the $main::group variable matches
  # the group of the file/directory. This is to avoid
  # permission problems such as CDO proposals which link
  # to ahelp files. This does lose a lot of functionality
  # but worry about that at a later date.
  #
  # ahelp files do not fit in nicely since we dont store the
  # ahelp XML file in the storage location, which means the
  # checks below fail (in particular the first sfile check).
  # Instead, we would want to check ahelpindex.xml, but we
  # do not want to then link the reverse dependency of
  # $revdepfile (e.g. a releasenotes file) to ahelpindex,
  # but rather we want to mention the ahelp file.
  #
  # A very simple locking scheme is used: RCS. I tried a
  # separate lock file, but it didn't work out well, so I have
  # decided to use RCS as this is designed to support this
  # workflow. The cost is un-needed history revisions for the
  # revdep files, but it should not be excessive.
  #

=pod HELP

TODO: review this

Argh: ahelp reverse dependencies are generally complicated because
(for example, processing dmextract)

 a) we don't store a version the ahelp XML file in the normal
    location -> we *could* change this

 b) ahelp links use ahelpindex.xml rather than the stored ahelp
    file -> the processing code could avoid using the ahelpindex
    route OR we cheat and use the ahelpindex file but then
    store the xpath/value from the actual ahelp file *which seems
    pointless, unless there's a big gain in using ahelpindex [which
    we could access via perl if necessary]

  NOTE: would need some sort of index to go from key/key+context
  to file name.

 c) each page includes bugs/release notes, and these are generated
    from a single page, but at this point we have the individual
    file names (i.e. *.slug.xml), but these don't exist as a user-visible
    entity.

    Perhaps want to deal with include vs extract via xpath as
    different?

=cut

  sub add_revdep_file ($$$$) {
    my $revdepfile = shift;
    my $name = shift;
    my $storage = shift;
    my $userdir = shift;

    die "Expected revdepfile=$revdepfile to end in .xml\n"
      unless $revdepfile =~ /\.xml$/;

    # print "HACK: add_revdep_file\n  revdepfile=$revdepfile\n  name=$name  storage=$storage  userdir=$userdir\n"; # TODO checking processing ahelp files

    my $sfile = "${storage}${name}.xml";
    my $ufile = "${userdir}${name}.xml";

    # For now skip checks if processing an ahelp file
    if ($name ne "index" and $userdir =~ /\/ahelp\/$/) {
      dbg "Skipping check for storage/user-editable version as ahelp page: $name";
    } else {
      die "Unable to find storage version: $sfile\n"
        unless -e $sfile;
      die "Unable to find original/user-editable version: $ufile\n"
        unless -e $ufile;
    }

    # It's important not to refer to yourself in the revdep
    # file, as don't want infinite loops and am too lazy to
    # set up a proper graph system to process the data.
    #
    return if $revdepfile eq $sfile;

    # Above we needed to check the .xml for the storage version of
    # the file, but we actually want to store the '.dep' version of
    # the file, so
    #
    $sfile = "${storage}${name}.dep";
    die "Unable to find dependency file $sfile\n"
      unless -e $sfile;

    my $fname = substr($revdepfile, 0, length($revdepfile)-4) . ".revdep";

    my $rcsdir = dirname($fname) . "/RCS";
    dbg "REVDEP file=$fname  RCS=$rcsdir";

    # Do we need to create the RCS directory?
    mymkdir $rcsdir unless -d $rcsdir;

    # If the revdep file doesn't exist, create an empty one and add it to RCS
    #
    my $dom;
    my $root;
    unless ( -e $fname ) {
	dbg "Creating RCS file for $fname";
	system "rcs -i -L -t-lockfile -q $fname"
	    and die "Unable to create RCS file for $fname";
	# system "touch $fname"
	#     and die "Unable to create empty file $fname";
	# mysetmods $fname;

	dbg "Creating new revdep file: $fname";
	$dom = XML::LibXML::Document->new();
	$root = $dom->createElement("reversedependencies");
	$dom->setDocumentElement($root);
	$dom->toFile($fname, 0);
	mysetmods $fname;

	system "ci -u -q $fname"
	    and die "Unable to run 'ci -u $fname'";

	$root = undef;
	$dom = undef;
    }

    if (not grp_matches $fname) {
	dbg "NOTE: unable to write to dependency file $fname as group differs";
	return;
    }

    # There is a possibility that there is a .revdep file but no version in
    # RCS (due to changes in development), which means that a hack is needed.
    #
    my $tempname = $rcsdir . "/" . basename($fname) . ",v";
    if ( ! -e $tempname ) {
	system "rcs -i -L -t-lockfile -q $fname"
	    and die "Unable to create RCS file for $fname";
	system "ci -u -q $fname"
	    and die "Unable to run 'ci -u -q $fname'";

    }

    dbg "Reading in revdep file: $fname";
    system "co -l -q $fname"
	and die "Unable to 'co -l -q $fname'";
    $dom = $parser->parse_file($fname);
    $root = $dom->documentElement();

    my $count = $dom->find("count(//revdep/store[normalize-space(.)='" . $sfile . "'])");
    if ($count == 0) {
      dbg "Adding revdep $sfile";
      my $revdep = XML::LibXML::Element->new("revdep");
      $root->appendChild($revdep);

      add_text_node $revdep, "store", $sfile;
      add_text_node $revdep, "user", $ufile;

      myrm $fname;
      $dom->toFile($fname, 0);
      mysetmods $fname;

    } elsif ($count > 1) {
	# do not bother with -q here as about to die anyway
	system "ci -u -mupdate $fname"
	    and die "Unable to check in the revdep file $fname";
	die "Internal error: multiple ($count) revdep store=$sfile in $fname\n";
    }

    system "ci -u -q -mupdate $fname"
	and die "Unable to 'ci -u -q -mupdate $fname'";

  } # sub: add_revdep_file

  # Write out the dependency information
  #
  # Doesn't need to be XML, but don't want to
  # either write my own format or require another
  # perl package be installed.
  #
  sub write_dependencies ($$$$) {
    my $name = shift;
    my $storage = shift;
    my $userdir = shift;
    my $stylesheetdir = shift;

    my $hdeps = hash_dependencies $stylesheetdir;

    add_dep_file $storage, $name, $hdeps;

    # Now for the reverse dependencies:
    #
    # At present, hdeps contains
    #    include
    #    ssi
    #    import
    #    xpath
    #
    # As xpath does not contiain file names (it uses include
    # to identify that), we are not interested in this here.
    #
    # Both ssi and import could be tracked - but for now
    # not tracking this, so just interested in the include
    # section.
    #
    dbg "Now creating reverse dependencies";
    while ( my ($label, $vals) = each %{$$hdeps{include}}) {
      dbg "Rev dep for label=$label";
      add_revdep_file $$vals{filename}, $name, $storage, $userdir;
    }

  } # sub: write_dependencies

  # TODO: probably going to need to change how things are stored
  # TODO: do we need to store the site along with things like
  #       faq/dictionary (for reverse dependency tracking?)
  #
  # add_dependency is for arrays/sets (ie we only add the value
  # if it isn't already included).
  #
  # Theproblem of multiple entries comes about when handling
  # stylesheets that produce multiple pages.
  #
  sub add_dependency ($$) {
    my $label = shift;
    my $value = shift;
    dbg "add_dependency: label=$label value=$value";
    $dependencies{$label} = []
      unless exists $dependencies{$label};

    return if grep /^$value$/, @{$dependencies{$label}};
    push @{$dependencies{$label}}, $value;
  }

  # add as a key/value pair
  sub add_dependency_key ($$$) {
    my $label = shift;
    my $key = shift;
    my $value = shift;
    $dependencies{$label} = {}
      unless exists $dependencies{$label};
    if (exists $dependencies{$label}{$key}) {
      my $cval = $dependencies{$label}{$key};
      die "Error: add_dependency_key label=$label key=$key sent both $cval and $value\n"
	if $cval ne $value;
    } else {
      dbg "add_dependency_key: label=$label key=$key value=$value";
      $dependencies{$label}{$key} = $value;
    }
  }

  # add as a key/key/value setup
  sub add_dependency_key2 ($$$$) {
    my $label = shift;
    my $key1 = shift;
    my $key = shift;
    my $value = shift;
    $dependencies{$label} = {}
      unless exists $dependencies{$label};
    $dependencies{$label}{$key1} = {}
      unless exists $dependencies{$label}{$key1};
    my $href = $dependencies{$label}{$key1};

    if (exists $$href{$key}) {
      my $cval = $$href{$key};
      die "Error: add_dependency_key2 label=$label key1=$key key=$key sent both $cval and $value\n"
	if $cval ne $value;
    } else {
      dbg "add_dependency_key2: label=$label key1=$key1 key=$key value=$value";
      $$href{$key} = $value;
    }
  }

  sub add_import_dependency ($) {
    my $name = shift;
    add_dependency "import", $name;
  }

  sub add_included_file_dependency ($$) {
    my $label = shift;
    my $filename = shift;
    add_dependency_key "include", $label, $filename;
  }

  # only allow this if $label has been recorded via
  # add_included_file_dependency
  #
  sub add_xpath_dependency ($$$) {
    my $label = shift;
    my $xpath = shift;
    my $value = shift;
    die "ERROR: $label has not been included via register-included-file\n"
      unless exists $dependencies{"include"}{$label};
    add_dependency_key2 "xpath", $label, $xpath, $value;
  }

  # Ideally would not be a function but not convinced that the
  # libXSLT version is modern enough to have register_element.
  #
  # The assumption is that this is processed for a single file,
  # and we know what that is, so we can identify these dependencies
  # with the file.
  #
  # The functions all return "", a dummy value.
  XML::LibXSLT->register_function("http://hea-www.harvard.edu/~dburke/xsl/extfuncs",
				  "register-import-dependency",
				  sub {
				    my $filename = shift;
				    add_import_dependency $filename;
				    return "";
				  }
				 );

  XML::LibXSLT->register_function("http://hea-www.harvard.edu/~dburke/xsl/extfuncs",
				  "register-xpath",
				  sub {
				    my $label = shift;
				    my $xpath = shift;
				    my $value = shift;
				    add_xpath_dependency $label, $xpath, $value;
				    return "";
				  }
				 );

  # The contents of this file are incorporated into the document
  # The file may not exists.
  XML::LibXSLT->register_function("http://hea-www.harvard.edu/~dburke/xsl/extfuncs",
				  "register-included-file",
				  sub {
				    my $label = shift;
				    my $filename = shift;
				    add_included_file_dependency $label, $filename;
				    return "";
				  }
				 );

  # The contents of this file are incorporated into the document
  # via SSI.
  XML::LibXSLT->register_function("http://hea-www.harvard.edu/~dburke/xsl/extfuncs",
				  "register-ssi-file",
				  sub {
				    my $filename = shift;
				    add_dependency "ssi", $filename;
				    return "";
				  }
				 );

  # Given the url and depth, return the breadcrumb terms
  #
  # I return the actual HTML as it was easier than dealing with
  # node sets. I've also forgotten all my Perl ...
  #
  # We remove ' index.html' as it doesn't really add anything,
  # but maybe in this case we don't make the last dir a link?
  #
  XML::LibXSLT->register_function("http://hea-www.harvard.edu/~dburke/xsl/extfuncs",
				  "get-breadcrumbs",
				  sub {
				    my $url = shift;
                                    my $depth = int(shift) + 1;
				    my @toks = split(/\//, $url);

				    # remove leading terms
				    splice(@toks, 0, -$depth);

				    my @counts = reverse (0 .. $#toks);

				    my $out = "";
				    foreach my $i ( 0 .. $#toks ) {
					my $count = $counts[$i];
					my $tok = $toks[$i];
					if ($out ne "") { $out .= " "; }
					if ($count == 0) {
					    $out .= "/";
					    $out .= " $tok" if $tok ne "index.html";
					} else {
					    my $href;
					    if ($count == 1) { $href = '.'; }
					    else { $href = '../' x ($count - 1); }
					    $out .= "/ <a href='${href}'>$tok</a>";
					}
				    }

				    return $out;
				  }
				 );

}


# Read in the dependencies from the input file
# and see if any of them have changed.
#
# The return value is 0 (unchanged/no need to re-publish)
# or 1 (need to re-publish)
#
# TODO: how to deal with include files that do not have
# xpath matches, since they are straight-forward includes.
# ie relnotes and bugs in ahelp .dep files?
#
sub process_dep_file ($) {
  my $depfile = shift;
  dbg "Processing dependency file: $depfile";

  my $dom = $parser->parse_file($depfile);
  my $root = $dom->documentElement();

  # First identify all the files that we need to check
  # and see if any of them have changed.
  #
  my %changed;
  foreach my $node ( $root->findnodes('//include/hash/hitem') ) {
    my $label = $node->findvalue('key');
    my $fname = $node->findvalue('value/hash/hitem[key="filename"]/value');
    my $ohash = $node->findvalue('value/hash/hitem[key="hash"]/value');

    # As outside the publishing loop here we can, and should, cache the
    # hash calculation.
    #
    my $nhash = get_filehash_cache $fname || "";
    dbg "Note: label=$label not found (hash is empty)" if $nhash eq "";
    dbg "Has label=$label changed hash (" . ($ohash ne $nhash) . ")";
    $changed{$label} = $fname unless $ohash eq $nhash;

  }

  # Now loop through all the xpath elements for those labels that
  # have changed.
  #
  while ( my ($label, $filename) = each %changed ) {
    dbg "Reading in from $filename";

    my $xdom = $parser->parse_file($filename);
    my $xroot = $xdom->documentElement();

    foreach my $node ( $root->findnodes('//xpath/hash/hitem[key="' . $label . '"]/value/hash/hitem') ) {
      my $xpath = $node->findvalue('key');
      my $ovalue = $node->findvalue('value');

      # query filename using xpath and compare to value
      my $nvalue = $xroot->findvalue("normalize-space(${xpath})");
      if ($ovalue ne $nvalue) {
	  dbg "**DIFF** '$xpath' '$ovalue' '$nvalue'";
      }
      ###dbg "Comparing $ovalue to $nvalue";
      return 1 if $ovalue ne $nvalue;
    }
  }

  # if got to here then there's been no change
  return 0;

} # sub: process_dep_file

# Identify the files that need to be re-processed because a
# file has changed.
#
# If there's no revdep file, then nothing.
# If there is, then need to do something....
#
sub identify_files_to_republish ($) {
  my $fname = shift;
  dbg "Looking for reverse dependencies in $fname";

  return unless -e $fname;

  my $dom = $parser->parse_file($fname);
  my $root = $dom->documentElement();
  my @out;
  clear_filehash_cache;
  foreach my $node ( $root->findnodes("//revdep") ) {
    my $store = $node->findvalue('store');
    my $user = $node->findvalue('user');

    push @out, $user if process_dep_file $store;
  }

  dbg " .. found " . (1 + $#out) . " files to republish";
  return \@out;

} # identify_files_to_republish

## End
1;
