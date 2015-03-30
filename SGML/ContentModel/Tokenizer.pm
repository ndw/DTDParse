# -*- Perl -*-

package SGML::ContentModel::Tokenizer;

$CVS = '$Id: Tokenizer.pm,v 1.8 2000/01/03 18:58:03 nwalsh Exp $ ';

use strict;
use Text::DelimMatch;

require 5.000;
require Carp;

{
    package SGML::ContentModel::Tokenizer::Group;

    sub new {
	my($type, $cm) = @_;
	my($class) = ref($type) || $type;
	my($self) = {};

	bless $self, $class;

	die "Bad call to SGML::ContentModel::Tokenizer::Group: $cm\n"
	    if $cm !~ /^\((.*)\)(.?)$/s;

	$self->{'OCCURRENCE'} = $2;
	$self->{'CONTENT_MODEL'} = new SGML::ContentModel::Tokenizer $1, 1;

	return $self;
    }

    sub print {
	my($self, $depth) = @_;

	print "\t" x $depth, "(\n";
	$self->{'CONTENT_MODEL'}->print($depth+1);
	print "\t" x $depth, ")\n";
    }
}

{
    package SGML::ContentModel::Tokenizer::Element;

    sub new {
	my($type, $elem) = @_;
	my($class) = ref($type) || $type;
	my($self) = {};

	bless $self, $class;

	die "Bad call to SGML::ContentModel::Tokenizer::Element: $elem\n"
	    if $elem !~ /^(\S+?)([\*\?\+]?)$/s;

	$self->{'ELEMENT'} = $1;
	$self->{'OCCURRENCE'} = $2;

	return $self;
    }

    sub print {
	my($self, $depth) = @_;

	print "\t" x $depth, $self->{'ELEMENT'}, $self->{'OCCURRENCE'}, "\n";
    }
}

{
    package SGML::ContentModel::Tokenizer::ParameterEntity;

    sub new {
	my($type, $pe) = @_;
	my($class) = ref($type) || $type;
	my($self) = {};

	bless $self, $class;

	die "Bad call to SGML::ContentModel::Tokenizer::ParameterEntity: $pe\n"
	    if $pe !~ /^(\S+)$/s;

	$self->{'PARAMETER_ENTITY'} = $1;

	return $self;
    }

    sub print {
	my($self, $depth) = @_;

	print "\t" x $depth, "%", $self->{'PARAMETER_ENTITY'}, ";\n";
    }
}

{
    package SGML::ContentModel::Tokenizer::Connector;

    sub new {
	my($type, $con) = @_;
	my($class) = ref($type) || $type;
	my($self) = {};

	bless $self, $class;

	die "Bad call to SGML::ContentModel::Tokenizer::Connector: $con\n"
	    if $con !~ /^[\,\|\&]$/s;

	$self->{'CONNECTOR'} = $con;

	return $self;
    }

    sub print {
	my($self, $depth) = @_;

	print "\t" x $depth, $self->{'CONNECTOR'}, "\n";
    }
}

sub new {
    my($type, $cm, $internal) = @_;
    my($class) = ref($type) || $type;
    my($self) = {};
    my(@model) = ();

    bless $self, $class;

    $self->{'CONTENT_MODEL_STRING'} = $cm;

#    print "-->$cm\n";

    if ($cm =~ /(.*?)\s\-(\(.*)$/) {
	my($excl) = $2;
	my($exclcm) = new SGML::ContentModel::Tokenizer $excl;
	$self->{'EXCLUSION'} = $exclcm;
	$cm = $1;
    }

    if ($cm =~ /(.*?)\s\+(\(.*)$/) {
	my($incl) = $2;
	my($inclcm) = new SGML::ContentModel::Tokenizer $incl;
	$self->{'INCLUSION'} = $inclcm;
	$cm = $1;
    }

#    print "==>$cm\n";

    $cm =~ s/^\s+//sg;

    # Simplification: always make the content model a group; unless it's
    # declared content.
    #
    if (!$internal) {
#	print "$cm\n\n";

	my($mc) = new Text::DelimMatch '\(', '\)[\?\+\*]*';
	my($pre, $match, $rest) = $mc->match($cm);

	if ($cm ne 'EMPTY' && $cm ne 'CDATA' && $cm ne 'RCDATA') {
	    if ($cm !~ /^\(/s || ($rest !~ /^\s*$/s)) {
		$cm = "($cm)";
	    }
	}
    }

    while ($cm ne "") {
	if ($cm =~ /^\(/s) {
	    # group;
	    my($mc) = new Text::DelimMatch '\(', '\)[\?\+\*]*';
	    my($pre, $match, $rest) = $mc->match($cm);
	    my($group);

#	    print "\tgroup:\n";
#	    print "\t\tp:$pre\n";
#	    print "\t\tm:$match\n";
#	    print "\t\tr:$rest\n";

	    $group = new SGML::ContentModel::Tokenizer::Group $match;
	    push (@model, $group);

	    $cm = $rest;
	} elsif ($cm =~ /^\%/s) {
	    # parameter entity
	    my($pe);
	    my($pent);
	    if ($cm =~ /%(.*?);?([\|\,\&\s].*)$/s) {
		$pe = $1;
		$cm = $2;
	    } else {
		$pe = $cm;
		$cm = "";
		$pe = $1 if $pe =~ /^\%(.*?);?$/s;
	    }

	    $pent = new SGML::ContentModel::Tokenizer::ParameterEntity $pe;
	    push (@model, $pent);
	} elsif ($cm =~ /^[\,\|\&]/s) {
	    # connector
	    my($con) = new SGML::ContentModel::Tokenizer::Connector $&;
	    $cm = $';

#	    print "\tconnector: $&\n";

	    push (@model, $con);
	} else {
	    # element
	    my($elem);
	    my($element);
	    if ($cm =~ /(.*?)([\|\,\&\s].*)$/s) {
		$elem = $1;
		$cm = $2;
	    } else {
		$elem = $cm;
		$cm = "";
	    }

	    $element = new SGML::ContentModel::Tokenizer::Element $elem;
	    push (@model, $element);
	}

	$cm =~ s/^\s+//sg;
    }

#    print "<==\n";

    @{$self->{'MODEL'}} = @model;

    return $self;
}

sub print {
    my($self) = shift;
    my($depth) = shift || 1;
    my(@model) = @{$self->{'MODEL'}};
    local($_);

    foreach $_ (@model) {
	$_->print($depth);
    }
}

1;
