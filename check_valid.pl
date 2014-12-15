#!/usr/bin/env perl -w
#
# Usage:
#   ./check_valid.pl <site>
#
# Aim:
#   checks the validity of all HTML pages for the given site
#   (ie everything below it) by calling the W3C's validator
#
#   site must be one of
#      ciao
#      sherpa
#      chart
#      caldb
#      atomdb
#
#   The output is to the screen and lists each "interesting"
#   page - i.e. something that ends in .html and does not
#   live in a SCCS dir - along with the status of the
#   validation (ok or fail + errors or an 'external' error
#   due to the validator/parsing code)
#

use strict;
$|++;

use File::Find;

# taken from ~/local/perl5/DSS.pm
#
use HTTP::Request::Common qw( POST );
use LWP::UserAgent;
use IO::File;

use XML::LibXML;

## Code
#
my %sites = map { ($_,1); } qw( ciao sherpa chart caldb atomdb );
my $sitelist = join( "  ", sort keys %sites );

my $progname = (split( m{/}, $0 ))[-1];
my $usage = <<"EOD";
Usage:
  $progname <site>

where site is one of:
   $sitelist

EOD

die $usage unless $#ARGV == 0;
my $site = shift;
die $usage unless exists $sites{$site};

# where are we to look?
#
my $url = "http://cxc.harvard.edu/${site}/";
my $dir = "/proj/web-cxc/htdocs/${site}/";

my %pages;

my $ua = LWP::UserAgent->new();

$ua->agent( "check_valid/1.0 " . $ua->agent );

my $parser = XML::LibXML->new()
  or die "Unable to create XML parser\n";

# find out what the validator says about the pages
# relies on version 0.9 of the XML DTD from the validator
#
sub parse_response ($$) {
    my $resp = shift;
    my $page = shift;

    my $dom = $parser->parse_string( $resp );
    unless ( $dom ) {
	print "INTERNAL_FAILURE - unable to parse response for $page\n";
	return;
    }

    my @msgs = $dom->getElementsByTagName( "msg" );
    if ( $#msgs == -1 ) {
	print "OK   - $page\n";
	return;
    }

    # loop through the messages and extract the content
    #
    printf "FAIL - %3d - %s\n", 1+$#msgs, $page;
    my $i = 1;
    foreach my $msg ( @msgs ) {
	my $line = $msg->getAttribute( "line" );
	my $text = $msg->textContent;
	printf "  #%3d: line=%4d  %s\n", $i, $line, $text;
	$i++;
    }

} # sub: parse_response

# only process files that end in .html
#
sub wanted {
    return unless /\.html$/;

    my $path = substr $File::Find::name, length($dir);

    # see what the validator says about the page
    #
    my $response = $ua->get( "http://validator.w3.org/check?uri=" . $url . $path . ";output=xml" );
    if ( $response->is_success ) {
	parse_response $response->content, $path;
    } else {
	print "+++REQUEST FAILED on $path - " . $response->status_line . "\n";
    }
}

# we assume we do not have to filter out SCCS files
# here (ie the contents of SCCS dirs), since we
# weill not be called starting in such a dir
#
sub remove_sccs {
    my @in = @_;
    my @out = grep { !/SCCS/ } @in;
    return @out;
}

find { wanted => \&wanted, preprocess => \&remove_sccs },
  $dir;

## End
#
exit;
