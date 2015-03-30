#!/usr/local/bin/perl5 -- # -*- Perl -*-
# Lists the elements that have element or mixed content.

$VERSION = "2.0beta3";

use strict;
use vars qw($VERSION);
use Getopt::Long;
use XML::DOM;

select(STDOUT); $| = 1;

my $usage  = "$0 dtd.xml\n";

my %opt = ();
&GetOptions(\%opt,
	    'mixed') || die $usage;

my $xmldtd = shift @ARGV || die $usage;

$xmldtd .= ".xml" if ($xmldtd =~ /\.dtd$/) && -f $xmldtd . ".xml";

if (! -f $xmldtd) {
    $xmldtd .= ".xml" if -f $xmldtd . ".xml";
    die "$0: cannot load $xmldtd\[.xml\].\n" if ! -f $xmldtd;
}

my $parser = new XML::DOM::Parser (NoExpand => 0);

print STDERR "Contentmdl version $VERSION\n\n";
print STDERR "Loading $xmldtd...";

my $dtd = $parser->parsefile($xmldtd);

print STDERR "\n\n";

my $root = $dtd->getDocumentElement();
my $elements = $root->getElementsByTagName('element');

if ($opt{'mixed'}) {
    print STDERR "The following elements have mixed content models:\n";
} else {
    print STDERR "The following elements have element content models:\n";
}

for (my $count = 0; $count < $elements->getLength(); $count++) {
    my $element = $elements->item($count);
    my $type = $element->getAttribute('content-type');

    print $element->getAttribute('name'), "\n"
	if ($opt{'mixed'} && ($type eq 'mixed'))
	    || (!$opt{'mixed'} && ($type eq 'element'));
}
