# README for DTDParse version V2.0beta3

N.B. This is a long since moribund project. It exists here mostly
as an historical curiosity.

DTDParse is a tool for processing SGML and XML DTDs. The primary
motivation for writing DTDParse was to provide a framework for
building documentation for DTDs, but other applications are easy
to imagine.

Using DTDParse is a two-step process. First the DTD is parsed
with 'dtdparse.pl'. This produces an XML version of the DTD.
Subsequent processing is performed against this XML version.

## Manifest

* README, this document
* SGML, modules used by DTDParse
* dtd.dtd, the XML DTD for the XML instances procued by dtdparse.pl
* dtd2html.pl, 'dtdformat.pl' library for HTML output
* dtd2refentry.pl, 'dtdformat.pl' library for DocBook RefEntry output
* dtdformat.pl, format a parsed DTD into documentation
* dtdparse.pl, parse an SGML/XML DTD into XML
* dtdstatus.pl, print thes tatus of a parsed DTD
* contentmdl.pl, lists element/mixed content elements for a given DTD
* plain.pl, the default library for 'dtdformat.pl' conversions.
* test, a directory of test DTDs.

## System Requirements

DTDParse version V2.0beta3 requires Perl5 and the `Text::DelimMatch`
module available from CPAN (www.cpan.org).

## Installation

At this point, I haven't arranged a proper Makefile.PL for DTDParse.
Simply unpack the distribution somewhere and run the tools with Perl.
Each of the programs adjusts its @INC path to make sure it can find
the modules it needs.

## Documentation

In the fullness of time [hahaha! —ed], each of the applications will
include appropriate POD documentation. At present, it's pretty sparse.

## Getting Started

Go to the 'test' directory, run

````
perl ../dtdparse.pl --title "Test DTD" --output test.xml test.dtd
````

Peek in test.xml and you'll see the XML version of the DTD. Run

````
perl ../dtdformat.pl --html test.xml
````

Point your favorite web browser at test/index.html and you'll see the
default HTML documentation for the DTD.

Delete the test directory, then run

````
perl ../dtdformat.pl --refentry test.xml
````

Look in `test/*` and you'll find DocBook RefEntry pages of
documentation for the DTD.

You can provide your own library (defining a few perl functions)
to provide additional information for the documentation (such as
reasonable descriptions).

## Examples

The HTML form of the documentation for the
[HTML 4.0 Transitional](https://ndw.github.io/DTDParse/html40/) DTD
is online. The
[XML “database”](https://ndw.github.io/DTDParse/html40.dtd.xml) produced
by `dtdparse` is also online.
