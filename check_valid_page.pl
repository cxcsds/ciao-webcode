#!/usr/bin/env perl -w
#
# Usage:
#   ./check_valid_page.pl <URL>
#            --doctype=default, h401t, h32, h20
#
#    default means it uses the document-supplied doctype
#    h401s means HTML 4.01 Strict
#    h401t means HTML 4.01 Transitional
#    h401f means HTML 4.01 Frameset
#    h32   means HTML 3.2
#    h20   means HTML 2.0
#
# Aim:
#   checks the validity of the given HTML page using the
#   W3C's validator
#
#   The output is to the screen and lists the status of the
#   validation (ok or fail + errors or an 'external' error
#   due to the validator/parsing code)
#

use strict;
$|++;

# taken from ~/local/perl5/DSS.pm
#
use HTTP::Request::Common qw( POST );
use LWP::UserAgent;
use URI;
use IO::File;

use XML::LibXML;

use Getopt::Long;

## Subroutines
#

# find out what the validator says about the page
# relies on version 0.9 of the XML DTD from the validator
#
sub parse_response ($$$) {
    my $parser = shift;
    my $resp   = shift;
    my $url    = shift;

    my $dom = $parser->parse_string( $resp );
    unless ( $dom ) {
	print "INTERNAL_FAILURE - unable to parse response for $url\n";
	return;
    }

    my @msgs = $dom->getElementsByTagName( "msg" );
    if ( $#msgs == -1 ) {
	print "OK   - $url\n";
	return;
    }

    # loop through the messages and extract the content
    #
    printf "FAIL - %3d - %s\n", 1+$#msgs, $url;
    my $i = 1;
    foreach my $msg ( @msgs ) {
	my $line = $msg->getAttribute( "line" );
	my $text = $msg->textContent;
	printf "  #%3d: line=%4d  %s\n", $i, $line, $text;
	$i++;
    }

} # sub: parse_response


## Code
#
my $progname = (split( m{/}, $0 ))[-1];

my %doctypes = (
    default => "",
    h401s => "HTML+4.01+Strict",
    h401t => "HTML+4.01+Transitional",
    h401f => "HTML+4.01+Frameset",
    h32 => "HTML+3.2",
    h20 => "HTML+2.0",
);

my $doctype_list = join (", ", sort keys %doctypes);

my $usage = <<"EOD";
Usage:
  $progname <URL>

Options:
  --doctype=$doctype_list

EOD

# process options
#
my $doctype = "default";
die $usage unless
    GetOptions 'doctype:s' => \$doctype;
die $usage unless exists $doctypes{$doctype};

die $usage unless $#ARGV == 0;
my $url = shift;

# is this OTT?
my $u = URI->new( $url );
die "Error: argument '$url' does not appear to be a HTTP: URI.\n"
    unless $u->scheme eq "http";

# Create the user agent
my $ua = LWP::UserAgent->new();
$ua->agent( "check_valid/1.0 " . $ua->agent );

my $parser = XML::LibXML->new()
  or die "Unable to create XML parser\n";

# see what the validator says about the page
#
my $query = "http://validator.w3.org/check?uri=" . $url . ";output=xml";

unless ( $doctypes{$doctype} eq "" ) {
    $query .= ";doctype=" . $doctypes{$doctype};
}

my $response = $ua->get( $query );
if ( $response->is_success ) {
    parse_response $parser, $response->content, $url;
} else {
    print "+++REQUEST FAILED for $url - " . $response->status_line . "\n";
}

## End
#
exit;
