#!/usr/local/bin/perl5 -- # -*- Perl -*-

$VERSION = "2.0beta3";

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

print "DTDStatus version $VERSION\n\n";
print "Loading $xmldtd...";

my $dtd = $parser->parsefile($xmldtd);

print "\n\n";

my $root = $dtd->getDocumentElement();

print "Title          : ", $root->getAttribute('title'), "\n";
print "Version        : ", $root->getAttribute('version'), "\n";
print "Source DTD     : ", $root->getAttribute('source-dtd'), "\n"
    if $root->getAttribute('source-dtd');

print "Case sensitive : ";
if ($root->getAttribute('case-sensitive')) {
    print "yes\n";
} else {
    print "no\n";
}

print "Unexpanded form: ";
if ($root->getAttribute('unexpanded')) {
    print "available\n";
} else {
    print "not available\n";
}

my $elements = $root->getElementsByTagName('element');

print "Elements       : ", $elements->getLength(), "\n";

my $entities = $root->getElementsByTagName('entity');
my %etypes = ();
for (my $count = 0; $count < $entities->getLength(); $count++) {
    my $ent  = $entities->item($count);
    my $type = $ent->getAttribute('type');

    if ($type eq 'param') {
	if ($ent->getAttribute('system') || $ent->getAttribute('public')) {
	    $type = 'paramext';
	}
    }

    $etypes{$type} = 0 if !exists($etypes{$type});
    $etypes{$type}++;
}

print "Entities       : ", $entities->getLength(), "\n";
print "  Parameter    : ", $etypes{'param'}, "\n" if $etypes{'param'};
print "  External     : ", $etypes{'paramext'}, "\n" if $etypes{'paramext'};
print "  SDATA(-ish)  : ", $etypes{'sdata'}, "\n" if $etypes{'sdata'};
print "  General      : ", $etypes{'gen'}, "\n" if $etypes{'gen'};

my $notations = $root->getElementsByTagName('notation');

print "Notations      : ", $notations->getLength(), "\n"
    if $notations->getLength();
