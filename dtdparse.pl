#!/usr/local/bin/perl5 -- # -*- Perl -*-

$VERSION = "2.0beta3";

use strict;
use Getopt::Long;

my $homedir = $0;
$homedir =~ s/\\/\//g;
$homedir =~ s/^(.*)\/[^\/]+$/$1/;

unshift (@INC, $homedir);

require 'SGML/DTD.pm';

my $usage = "Usage: $0 <<opts>> dtd\n";

my %option = ('debug' => 0,
	      'verbose' => 1,
	      'title' => '?untitled?',
	      'unexpanded' => 1,
	      'public-id' => '',
	      'system-id' => '',
	      'namecase-general' => 1,
	      'namecase-entity' => 0,
	      'output' => '',
	      'xml' => 0,
	      'declaration' => '');

my %opt = ();
&GetOptions(\%opt,
	    'debug+',
	    'verbose+',
	    'title=s',
	    'unexpanded!',
	    'catalog=s@',
	    'public-id=s',
	    'system-id=s',
	    'output=s',
	    'xml!',
	    'namecase-general!',
	    'namecase-entity!',
	    'declaration=s') || die $usage;

foreach my $key (keys %option) {
    $option{$key} = $opt{$key} if exists($opt{$key});
}

my @catalogs = exists($opt{'catalog'}) ? @{$opt{'catalog'}} : ();

my $file = shift @ARGV;
my $xmlfile = $option{'output'};

if (defined($file) && $xmlfile eq '') {
    $xmlfile = "$file.xml";
}

warn "You didn't specify a title.\n" if !$option{'title'};

print $option{'debug'}, "\n"; exit;

my $dtd = new SGML::DTD ('Verbose' => $option{'verbose'},
			 'Debug' => $option{'debug'},
			 'SgmlCatalogFilesEnv' => $option{'use-sgml-catalog-files'},
			 'Title' => $option{'title'},
			 'UnexpandedContent' => $option{'unexpanded'},
			 'SourceDtd' => $file,
			 'Xml' => $option{'xml'},
			 'NamecaseGeneral' => $option{'namecase-general'},
			 'NamecaseEntity' => $option{'namecase-entity'},
			 'PublicId' => $option{'public-id'},
			 'SystemId' => $option{'system-id'},
			 'Declaration' => $option{'declaration'});

foreach my $catalog (@catalogs) {
    $dtd->parseCatalog($catalog);
}

$dtd->parse($file);

if ($xmlfile eq '' && $dtd->{'SYSTEM_ID'}) {
    $xmlfile = $dtd->{'SYSTEM_ID'} . ".xml";
}

if ($xmlfile eq '') {
    print "The DTD filename is unknown; using \"xmldtd.xml\".\n";
    $xmlfile = "xmldtd.xml";
}

print "Writing $xmlfile...\n";

open (F, ">$xmlfile");
$dtd->xml(*F);
close (F);

print "Done.\n";

__END__

=head1 NAME

dtdparse - Parse a DTD and produce an XML document that represents it

=head1 SYNOPSIS

 dtdparse [options] dtdfile [xmlfile]

=head1 DESCRIPTION

DTDParse is a tool for manipulating XML and SGML Document Type
Definitions (DTDs). DTDParse is designed primarily to aid in the
understanding and documentation of DTDs.

Using DTDParse is a two-step process:

=over 4

=item 1.

Parse the DTD with DTDParse. This produces an XML representation
of the DTD. This representation, described by F<dtdparse.dtd>,
exposes both the logical structure of the DTD (the actual
meta-structure of its grove) and the organizational structure of
the DTD (the declarations and parameter entities that comprise
its textual form.

Version 2.0 of DTDParse improves over the previous version in
two main ways: it has a far more robust algorithm for parsing
the original DTD and it stores the resulting parsed structure as
an XML document.

=item 2.

Manipulate the XML document produced by DTDParse to do whatever
you want. DTDParse is shipped with several programs that demonstrate
various capabilities; the most useful of which is B<dtdformat> which
can produce HTML or DocBook (http://www.oasis-open.org/docbook/)
RefEntry pages for each element and parameter entity in the DTD.

=back

=head2 System Requirements

<para>Running DTDParse requires:</para>
<itemizedlist>
<listitem><para>Perl 5</para></listitem>
<listitem><para>Text::DelimMatch</para></listitem>
<listitem><para>SGML::DTD</para></listitem>
<listitem><para>SGML::ContentModel</para></listitem>
<listitem><para>SGML::ContentModel::Tokenizer</para></listitem>
<listitem><para>SGML::Catalog</para></listitem>
</itemizedlist>

<para>The SGML::* modules are distributed as part of DTDParse and do
not have to be separately installed.</para>

<para>Running B<dtdformat> requires:</para>
<itemizedlist>
<listitem><para>Perl 5</para></listitem>
<listitem><para>Text::DelimMatch</para></listitem>
<listitem><para>XML::DOM</para></listitem>
<listitem><para>XML::Parser</para></listitem>
</itemizedlist>
</section>

<section>Running DTDParse</section>

<funcsynopsis
