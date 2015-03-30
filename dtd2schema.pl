#!/usr/local/bin/perl5 -- # -*- Perl -*-

$VERSION = "2.0beta1";

use strict;
use vars qw($VERSION);

use XML::DOM;

select(STDOUT); $| = 1;

my $usage  = "$0 dtd.xml\n";
my $xmldtd = shift @ARGV || die $usage;

$xmldtd .= ".xml" if ($xmldtd =~ /\.dtd$/) && -f $xmldtd . ".xml";

if (! -f $xmldtd) {
    $xmldtd .= ".xml" if -f $xmldtd . ".xml";
    die "$0: cannot load $xmldtd\[.xml\].\n" if ! -f $xmldtd;
}

my $parser = new XML::DOM::Parser (NoExpand => 0);

print "DTD2Schema version $VERSION\n\n";
print "Loading $xmldtd...";

my $dtd = $parser->parsefile($xmldtd);

print "\n\n";
print "This code hasn't really been written yet.\n";

