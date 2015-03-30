#!/usr/local/bin/perl5 -- # -*- Perl -*-

# NAMECASE YES means NO

$VERSION = "2.0beta3";

($homedir = $0) =~ s/\\/\//g;
$homedir =~ s/^(.*)\/[^\/]+$/$1/;

unshift (@INC, $homedir);

use strict;
use vars qw($VERSION);
use vars qw(@elements %elements %attlists);
use vars qw(@entities %entities @notations %notations);
use vars qw($usage %option %config $fileext $baseid);
use vars qw($xmldtd $basedir $dtd);
use vars qw(%ELEMBASE %ENTBASE %NOTBASE %ROOTS);
use vars qw(%APPEARSIN %EAPPEARSIN %XAPPEARSIN);
use vars qw(%PARENTS %CHILDREN);
use vars qw(%ELEMINCL %ELEMEXCL %POSSINCL %POSSEXCL);
use vars qw($expanded);

use Getopt::Long;
use XML::DOM;

$expanded = 'expanded';

$usage = "$0 version $VERSION\nUsage: $0 [ options ] dtd[.xml]\n";

%option = ('synopsis' => 1,
	   'content-model' => 1,
	   'attributes' => 1,
	   'inclusions' => 1,
	   'exclusions' => 1,
	   'tag-minimization' => 1,
	   'appears-in' => 1,
	   'description' => 1,
	   'attributes' => 1,
	   'parents' => 1,
	   'children' => 1,
	   'examples' => 1,
	   'base-dir' => "",
	   'debug' => 0,
	   'unexpanded' => 1,
	   'verbose' => 1,
	   'include-sdata' => 0,
	   'include-charent' => 0,
	   'include-ms' => 0,
	   'elements' => 1,
	   'entities' => 1,
	   'notations' => 1);

%config = ('expanded-element-dir' => 'elements',
	   'unexpanded-element-dir' => 'dtdelem',
	   'expanded-entity-dir' => 'entities',
	   'unexpanded-entity-dir' => 'dtdent',
	   'notation-dir' => 'notations',
	   'home' => 'index' . $fileext,
	   'expanded-element-index' => "index" . $fileext,
	   'unexpanded-element-index' => "dtdelem" . $fileext,
	   'expanded-entity-index' => "entities" . $fileext,
	   'unexpanded-entity-index' => "dtdent" . $fileext,
	   'notation-index' => 'notations' . $fileext);

my %opt = ();
&GetOptions(\%opt,
	    'html',
	    'refentry|man',
	    'debug+',
	    'verbose+',
	    'synopsis!',
	    'content-model!',
	    'attributes!',
	    'inclusions!',
	    'exclusions!',
	    'tag-minimization!',
	    'include-sdata!',
	    'include-charent!',
	    'include-ms!',
	    'appears-in!',
	    'description!',
	    'attributes!',
	    'parents!',
	    'chilren!',
	    'examples!',
	    'library=s@',
	    'unexpanded!',
	    'base-dir=s',
	    'base-id=s',
	    'elements!',
	    'entities!',
	    'notations!') || die $usage;

if ($opt{'html'} && $opt{'refentry'}) {
    print STDERR $usage;
    die "You can't specify both --html and --refentry.\n";
}

if (!$opt{'html'} && !$opt{'refentry'}) {
    if ($0 =~ /html$/) {
	$opt{'html'} = 1;
    } elsif ($0 =~ /refentry$/ || $0 =~ /man$/) {
	$opt{'refentry'} = 1;
    } else {
	print STDERR $usage;
	die "You must specify either --html or --refentry.\n";
    }
}

if ($opt{'html'}) {
    &status("Formatting HTML.",1);
    require 'dtd2html.pl';
} elsif ($opt{'refentry'}) {
    &status("Formating DocBook RefEntrys.",1);
    require 'dtd2refentry.pl';
}

my @libraries = exists($opt{'library'}) ? @{$opt{'library'}} : ();
if (@libraries) {
    foreach my $userlib (@libraries) {
	require $userlib;
    }
} else {
    my $plain = $0;
    $plain =~ s/\\/\//g;
    if ($plain =~ /\//) {
	$plain =~ s/^(.*)\/[^\/]+$/$1\/plain.pl/;
    } else {
	$plain = "plain.pl";
    }

    &status("Using plain library.",1);
    require $plain;
}

foreach my $key (keys %option) {
    $option{$key} = $opt{$key} if exists $opt{$key};
}

if (!defined($option{'base-id'})) {
    $baseid = "dtdparse";
    if ($opt{'refentry'}) {
	&status("No base-id specified, \"$baseid\" will be used.",1);
    }
} else {
    $baseid = $option{'base-id'};
}

select(STDOUT); $| = 1;

$xmldtd = shift @ARGV || die $usage;

$xmldtd .= ".xml" if ($xmldtd =~ /\.dtd$/) && -f $xmldtd . ".xml";

if (! -f $xmldtd) {
    $xmldtd .= ".xml" if -f $xmldtd . ".xml";
    die "$0: cannot load $xmldtd\[.xml\].\n" if ! -f $xmldtd;
}

if ($option{'base-dir'} ne "") {
    $basedir = $option{'base-dir'};
} else {
    $basedir = $xmldtd;
    $basedir =~ s/\\/\//g;             # foo\bar.dtd.xml => foo/bar.dtd.xml
    $basedir =~ s/^.*\/([^\/]+)$/$1/;  # foo/bar.dtd.xml => bar.dtd.xml
    $basedir =~ s/^([^\.]+).*$/$1/;    # bar.dtd.xml => bar
    $option{'base-dir'} = $basedir;
}

my $parser = new XML::DOM::Parser (NoExpand => 0);

&status("Loading $xmldtd...");
$dtd = $parser->parsefile($xmldtd);

foreach my $opt ('namecase-general', 'namecase-entity', 
		 'unexpanded', 'xml') {
    $option{$opt} = $dtd->getDocumentElement()->getAttribute($opt);
}

&createDir ($basedir, 0755) if ! -d $basedir;
&checkDir ($basedir);
foreach my $key ('expanded-element-dir', 'expanded-entity-dir', 
		 'notation-dir') {
    my $dir = $basedir . "/" . $config{$key};
    &createDir ($dir, 0755) if ! -d $dir;
    &checkDir ($dir);
}

if ($option{'unexpanded'}) {
    foreach my $key ('unexpanded-element-dir', 'unexpanded-entity-dir') {
	my $dir = $basedir . "/" . $config{$key};
	&createDir ($dir, 0755) if ! -d $dir;
	&checkDir ($dir);
    }
}

my $elemnodelist = $dtd->getElementsByTagName("element");

# Build a hash of element nodes, then a sorted list
%elements = ();
for (my $count = 0; $count < $elemnodelist->getLength(); $count++) {
    my $element = $elemnodelist->item($count);
    my $name = $element->getAttribute('name');

    $name = lc($name) if $option{'namecase-general'};

    $elements{$name} = $element;
}

@elements = sort { uc($a) cmp uc($b) } keys %elements;

%ELEMBASE = &basenames(@elements);

# Build a hash of entity nodes, then a sorted list
my $entnodelist = $dtd->getElementsByTagName("entity");

%entities = ();
for (my $count = 0; $count < $entnodelist->getLength(); $count++) {
    my $entity = $entnodelist->item($count);
    my $name = $entity->getAttribute('name');

    $name = lc($name) if $option{'namecase-entity'};

    $entities{$name} = $entity;
}

@entities = sort { uc($a) cmp uc($b) } keys %entities;

%ENTBASE = &basenames(@entities);

# Build a hash of notation nodes, then a sorted list
my $notnodelist = $dtd->getElementsByTagName("notation");

%notations = ();
for (my $count = 0; $count < $notnodelist->getLength(); $count++) {
    my $notation = $notnodelist->item($count);
    my $name = $notation->getAttribute('name');
    $notations{$name} = $notation;
}

@notations = sort { uc($a) cmp uc($b) } keys %notations;

%NOTBASE = &basenames(@notations);

&status("Calculating parents and children...");

%PARENTS = ();
%CHILDREN = ();
%ELEMINCL = ();
%ELEMEXCL = ();
%POSSINCL = ();
%POSSEXCL = ();

foreach my $element (values %elements) {
    my $cm     = $element->getElementsByTagName('content-model-expanded');
    my $incl   = $element->getElementsByTagName('inclusions');
    my $excl   = $element->getElementsByTagName('exclusions');
    my $chlist = $cm->item(0)->getElementsByTagName('element-name');
    my $pname  = $element->getAttribute('name');

    $pname = lc($pname) if $option{'namecase-general'};

    for (my $chcount = 0; $chcount < $chlist->getLength(); $chcount++) {
	my $child = $chlist->item($chcount);
	my $cname = $child->getAttribute('name');

	$cname = lc($cname) if $option{'namecase-general'};

	$PARENTS{$cname} = {} if !exists($PARENTS{$cname});
	$PARENTS{$cname}->{$pname} = 0 if !exists($PARENTS{$cname}->{$pname});
	$PARENTS{$cname}->{$pname}++;

	$CHILDREN{$pname} = {} if !exists($CHILDREN{$pname});
	$CHILDREN{$pname}->{$cname} = 0
	    if !exists($CHILDREN{$pname}->{$cname});
	$CHILDREN{$pname}->{$cname}++;
    }

    if ($incl && $incl->getLength() > 0) {
	$chlist = $incl->item(0)->getElementsByTagName('element-name');

	for (my $chcount = 0; $chcount < $chlist->getLength(); $chcount++) {
	    my $child = $chlist->item($chcount);
	    my $cname = $child->getAttribute('name');

	    $cname = lc($cname) if $option{'namecase-general'};

	    $ELEMINCL{$pname} = {} if !exists($ELEMINCL{$pname});
	    $ELEMINCL{$pname}->{$cname} = 1;
	}
    }

    if ($excl && $excl->getLength() > 0) {
	$chlist = $excl->item(0)->getElementsByTagName('element-name');

	for (my $chcount = 0; $chcount < $chlist->getLength(); $chcount++) {
	    my $child = $chlist->item($chcount);
	    my $cname = $child->getAttribute('name');

	    $cname = lc($cname) if $option{'namecase-general'};

	    $ELEMEXCL{$pname} = {} if !exists($ELEMEXCL{$pname});
	    $ELEMEXCL{$pname}->{$cname} = 1;
	}
    }
}

# Now the fun part, recurse over all elements and propagate inclusions
# and exclusions...

&status("Propagating inclusions and exclusions...");
&propagateInclExcl();

# Calculate the root elements.
%ROOTS = ();
foreach my $element (values %elements) {
    my $pname  = $element->getAttribute('name');
    $pname = lc($pname) if $option{'namecase-general'};
    $ROOTS{$pname} = $element if !exists($PARENTS{$pname});
}

# Elements that are inclusions aren't roots
my %allincl = ();
foreach my $element (keys %POSSINCL) {
    my %incl = %{$POSSINCL{$element}};
    foreach my $key (keys %incl) {
	$allincl{$key} = 1;
    }
}
foreach my $element (keys %allincl) {
    delete $ROOTS{$element} if exists $ROOTS{$element};
}

&status("Finding Attribute Lists...");

%attlists = ();
my $attlistnodelist = $dtd->getElementsByTagName("attlist");

for (my $count = 0; $count < $attlistnodelist->getLength(); $count++) {
    my $node = $attlistnodelist->item($count);
    my $name = $node->getAttribute('name');
    $name = lc($name) if $option{'namecase-general'};
    $attlists{$name} = $node;
}

#open (DEBUGFILE, ">dtdformat.debug");

%APPEARSIN = ();
%EAPPEARSIN = ();
%XAPPEARSIN = ();
if ($option{'appears-in'}) {
    &status("Calculating appears-in...");
    &calculateAppearsIn();
    &calculateEntityAppearsIn();
}

#print DEBUGFILE "APPEARSIN:\n";
#foreach my $key (keys %APPEARSIN) {
#    print DEBUGFILE "  $key (APPEARSIN)\n";
#    my %x = %{$APPEARSIN{$key}};
#    foreach my $key2 (keys %x) {
#	print DEBUGFILE "\t$key2\n";
#    }
#}
#print "\n";
#
#print DEBUGFILE "EAPPEARSIN:\n";
#foreach my $key (keys %EAPPEARSIN) {
#    print DEBUGFILE "  $key (EAPPEARSIN)\n";
#    my %x = %{$EAPPEARSIN{$key}};
#    foreach my $key2 (keys %x) {
#	print DEBUGFILE "\t$key2\n";
#    }
#}
#print "\n";
#
#print DEBUGFILE "XAPPEARSIN:\n";
#foreach my $key (keys %XAPPEARSIN) {
#    print DEBUGFILE "  $key (XAPPEARSIN)\n";
#    my %x = %{$XAPPEARSIN{$key}};
#    foreach my $key2 (keys %x) {
#	print DEBUGFILE "\t$key2\n";
#    }
#}
#print "\n";
#
#close (DEBUGFILE);

&status("Writing Index Pages...");

&writeElementIndexes($basedir);
&writeEntityIndexes($basedir);
&writeNotationIndexes($basedir);
&writeIndex($basedir);

if ($option{'unexpanded'}) {
    $expanded = 'unexpanded';
    &writeElementIndexes($basedir);
    &writeEntityIndexes($basedir);
    $expanded = 'expanded';
}

&status("Writing Elements...",1);

for (my $count = 0; $option{'elements'} && ($count <= $#elements); $count++) {
    my $name = $elements[$count];
    my $element = $elements{$name};
    my $path = $basedir . "/" . $config{'expanded-element-dir'};
    my $basename = $ELEMBASE{$name};
    my $html = "";

    &status($element->getAttribute('name'));

    $expanded = 'expanded';
    $html = &formatElement($count);
    &writeElement($count, $path, $basename, $fileext, $html);

    if ($option{'unexpanded'}) {
	$expanded = 'unexpanded';
	$path = $basedir . "/" . $config{'unexpanded-element-dir'};
	$html = &formatElement($count);
	&writeElement($count, $path, $basename, $fileext, $html);
    }
}

&status("Writing Entities...",1);

for (my $count = 0; $option{'entities'} && ($count <= $#entities); $count++) {
    my $name = $entities[$count];
    my $entity = $entities{$name};
    my $etype = &entityType($entity);
    my $path = $basedir . "/" . $config{'expanded-entity-dir'};
    my $basename = $ENTBASE{$name};
    my $html = "";

    &status($entity->getAttribute('name'));

    $expanded = 'expanded';

    $html = "";

    if ($etype eq 'sdata') {
	$html = &formatEntity($count) if $option{'include-sdata'};
    } elsif ($etype eq 'msparam') {
	$html = &formatEntity($count) if $option{'include-ms'};
    } elsif ($etype eq 'charent') {
	$html = &formatEntity($count) if $option{'include-charent'};
    } else {
	$html = &formatEntity($count);
    }

    &writeEntity($count, $path, $basename, $fileext, $html);

    if ($option{'unexpanded'}) {
	$expanded = 'unexpanded';
	$path = $basedir . "/" . $config{'unexpanded-entity-dir'};

	$html = "";

	if ($etype eq 'sdata') {
	    $html = &formatEntity($count) if $option{'include-sdata'};
	} elsif ($etype eq 'msparam') {
	    $html = &formatEntity($count) if $option{'include-ms'};
	} else {
	    $html = &formatEntity($count);
	}

	&writeEntity($count, $path, $basename, $fileext, $html);
    }
}

&status("Writing Notations...",1);

$expanded = 'expanded';
for (my $count = 0; $option{'notations'} && ($count <= $#notations); $count++) {
    my $name = $notations[$count];
    my $notation = $notations{$name};
    my $path = $basedir . "/" . $config{'notation-dir'};
    my $basename = $NOTBASE{$name};
    my $html = "";

    &status($notation->getAttribute('name'));

    $html = &formatNotation($count);

    &writeNotation($count, $path, $basename, $fileext, $html);
}

&status("Done.",1);

exit;

# ======================================================================

sub createDir {
    my $dir = shift;
    my $mode = shift;
    mkdir($dir,$mode);
}

sub checkDir {
    my $dir = shift;
    die "$0: Failed to create $dir.\n" if ! -d $dir;
}

sub writeElement {
    my $count = shift;
    my $path = shift;
    my $basename = shift;
    my $fileext = shift;
    my $html = shift;

    open (F, ">$path/" . $basename . $fileext);
    print F $html;
    close (F);
}

sub writeEntity {
    my $count = shift;
    my $path = shift;
    my $basename = shift;
    my $fileext = shift;
    my $html = shift;

    open (F, ">$path/" . $basename . $fileext);
    print F $html;
    close (F);
}


sub writeNotation {
    my $count = shift;
    my $path = shift;
    my $basename = shift;
    my $fileext = shift;
    my $html = shift;

    open (F, ">$path/" . $basename . $fileext);
    print F $html;
    close (F);
}

sub basenames {
    my @names = @_;
    my %basename = ();
    my %usedname = ();

    foreach my $name (@names) {
	my $count = 2;
	my $bname = lc($name);

	if ($usedname{$bname}) {
	    $bname = lc($name) . $count;
	    while ($usedname{$bname}) {
		$bname++;
	    }
	}

	$basename{$name} = $bname;
	$usedname{$name} = 1;
    }

    return %basename;
}

sub entityType {
    my $ent    = shift;
    my $textnl = $ent->getElementsByTagName("text");
    my $text   = $textnl->item(0);
    my $type   = $ent->getAttribute('type');

    if ($type eq 'param') {
	if ($ent->getAttribute('system') || $ent->getAttribute('public')) {
	    $type = 'paramext';
	} elsif ($text && $text->getFirstChild()) {
	    my $data = $text->getFirstChild()->getData();
	    if ($data eq 'INCLUDE' || $data eq 'IGNORE') {
		$type = 'msparam';
	    }
	}
    } elsif (($type eq 'gen') || ($type eq 'cdata')) {
	if ($text && $text->getFirstChild()) {
	    my $data = $text->getFirstChild()->getData();
	    if ($data =~ /^\&\#[xX][0-9A-F]+\;/i
		|| $data =~ /^\&\#[0-9]+\;/i) {
		$type = 'charent';
	    }
	}
    }

    return $type;
}

# ======================================================================

sub propagateInclExcl {
    # For each element, look for inclusions on all its parents
    my $totelem = $#elements+1;
    my $count = 0;

    foreach my $name (@elements) {
	my %children = ();
	my %checked = ();
	my @tocheck = ();
	my %excl = ();
	my %incl = ();

	%children = %{$CHILDREN{$name}} if exists $CHILDREN{$name};

	&status(sprintf("Propagating inclusions and exclusions: %5.1f%%", 
			$count / $totelem * 100.0));
	$count++;

	@tocheck = keys %{$PARENTS{$name}} if exists $PARENTS{$name};
	while (@tocheck) {
	    my $parent = shift @tocheck;

	    if (exists $ELEMINCL{$parent}) {
		foreach my $element (keys %{$ELEMINCL{$parent}}) {
		    $incl{$element} = 1;
		}
	    }
	    if (exists $ELEMEXCL{$parent}) {
		foreach my $element (keys %{$ELEMEXCL{$parent}}) {
		    $excl{$element} = 1;
		}
	    }
	    if (exists $PARENTS{$parent}) {
		foreach my $element (keys %{$PARENTS{$parent}}) {
		    push (@tocheck, $element) unless $checked{$element};
		    $checked{$element} = 1;
		}
	    }
	}

	# Exclusions are only interesting if they're allowed as children.
	foreach my $element (keys %excl) {
	    delete $excl{$element} if !exists $children{$element};
	}

	if (%excl) {
	    $POSSEXCL{$name} = {};
	    %{$POSSEXCL{$name}} = %excl;
	}

	# Inclusions are only interesting if they're not also excluded
	if (exists $ELEMEXCL{$name}) {
	    foreach my $element (keys %incl) {
		delete $incl{$element} if exists $ELEMEXCL{$name}->{$element};
	    }
	}

	if (%incl) {
	    $POSSINCL{$name} = {};
	    %{$POSSINCL{$name}} = %incl;
	}
    }

#    foreach my $name (@elements) {
#	my %incl = ();
#	my %iincl = ();
#	my %excl = ();
#	my %iexcl = ();
#
#	%incl = %{$ELEMINCL{$name}} if exists $ELEMINCL{$name};
#	%iincl = %{$POSSINCL{$name}} if exists $POSSINCL{$name};
#	%excl = %{$ELEMEXCL{$name}} if exists $ELEMEXCL{$name};
#	%iexcl = %{$POSSEXCL{$name}} if exists $POSSEXCL{$name};
#
#	print "\n$name:\n";
#	print "\t I:", join(",", keys %incl), "\n";
#	print "\tiI:", join(",", keys %iincl), "\n";
#	print "\t E:", join(",", keys %excl), "\n";
#	print "\tiE:", join(",", keys %iexcl), "\n";
#    }
}

sub calculateAppearsIn {
    # Calculates where elements and parameter entities appear in
    # other parameter entities

    my $totent = $#entities + 1;
    my $count = 0;

    foreach my $entname (@entities) {
	my $entity = $entities{$entname};
	my $expnl  = $entity->getElementsByTagName("text-expanded");
	my $uexpnl = $entity->getElementsByTagName("text");
	my $node = undef;
	my $cnode = undef;
	my $text = undef;

	&status(sprintf("Calculating appears-in: %5.1f%%", 
			$count / $totent * 100.0));
	$count++;

	$node = $expnl->item(0) if $expnl;
	$cnode = $node->getFirstChild() if $node;
	$text = $cnode->getData() if $cnode;

	if (&cmFragment($text)) {
	    while ($text =~ /[-a-z0-9.:_]+/is) {
		my $pre = $`;
		my $match = $&;
		$text = $';

		my $name = $match;
		$name = lc($name) if $option{'namecase-general'};

		$APPEARSIN{$name} = {} if !exists $APPEARSIN{$name};
		$APPEARSIN{$name}->{$entname} = 1;

#		print DEBUGFILE "A: $name appears in $entname\n";
	    }
	}

	$text = undef;
	$node = $uexpnl->item(0) if $uexpnl;
	$cnode = $node->getFirstChild() if $node;
	$text = $cnode->getData() if $cnode;

	while ($text =~ /\%([^\s;]+);?/is) {
	    my $pre = $`;
	    my $match = $1;
	    $text = $';

	    my $name = "%$match";

	    $APPEARSIN{$name} = {} if !exists $APPEARSIN{$name};
	    $APPEARSIN{$name}->{$entname} = 1;

#	    print DEBUGFILE "A: $name appears in $entname\n";
	}
    }
}

sub calculateEntityAppearsIn {
    # Calculates where parameter entities appear in element declarations
    # Note: for any given PE 'x', this function calculates the
    # elements that contain %x; directly (%EAPPEARSIN) and the elements
    # that contain %x; indirectly (%XAPPEARSIN).

    my $totelem = $#elements + 1;
    my $count = 0;

    foreach my $elemname (@elements) {
	my $element = $elements{$elemname};
	my $cmlist  = $element->getElementsByTagName('content-model');

	&status(sprintf("Calculating entity appears-in: %5.1f%%", 
			$count / $totelem * 100.0));
	$count++;

	if ($cmlist->getLength() > 0) {
	    my $cm      = $cmlist->item(0);
	    my $pelist  = $cm->getElementsByTagName('parament-name');

	    for (my $count = 0; $count < $pelist->getLength(); $count++) {
		my $pename = $pelist->item($count);
		my $name = $pename->getAttribute('name');

		if (!exists($EAPPEARSIN{"%$name"})) {
		    $EAPPEARSIN{"%$name"} = {};
		}

		$EAPPEARSIN{"%$name"}->{$elemname} = 1;

#		print DEBUGFILE "E: %$name appears in $elemname\n";
	    }
	}

	# Ok, if a PE appears in the ATTLIST decl we say it appears in
	# the element. This may not really work, but it seems so unlikely
	# that the same pe would be used in both, that I don't see the
	# harm.

	my $attlist = $attlists{$elemname};
	if (defined($attlist)) {
	    my $adlist  = $attlist->getElementsByTagName('attdecl');
	    if ($adlist->getLength() > 0) {
		my $attdecl = $adlist->item(0);
		my $cnode   = $attdecl->getFirstChild(); # will be only one!
		my $text    = $cnode->getData() if $cnode;

		while ($text =~ /%([^\s;]+);?/is) {
		    my $pe = $1;
		    $text = $';

		    $EAPPEARSIN{"%$pe"} = {} if !exists($EAPPEARSIN{"%$pe"});
		    $EAPPEARSIN{"%$pe"}->{$elemname} = 1;
#		    print DEBUGFILE "EA: %$pe appears in $elemname\n";
		}
	    }
	}
    }

    # Ok, now $APPEARSIN{'%x'} tells us what PEs %x appears in and
    # $EAPPEARSIN{'%x'} tells us what elements %x appears in.
    # Next we've got to calculate the complete set of all elements
    # that are influenced by %x. This is the elements that contain
    # PEs that contain %x or PEs that contain PEs that contain %x, etc.

    my $totent = $#entities + 1;
    my $count = 0;

    foreach my $name (@entities) {
	&status(sprintf("Calculating extended entity appears-in: %5.1f%%", 
			$count / $totent * 100.0));
	$count++;

	# Any element that contains %x is influenced by %x
	foreach my $elemname (keys %{$EAPPEARSIN{"%$name"}}) {
	    $XAPPEARSIN{"%$name"} = {} if !exists $XAPPEARSIN{"%$name"};
	    $XAPPEARSIN{"%$name"}->{$elemname} = 1;
#	    print DEBUGFILE "X': %$name appears in $elemname\n";
	}

	next if !$APPEARSIN{"%$name"};

#	print DEBUGFILE "?: %$name appears in: ";

	my %toinspect = %{$APPEARSIN{"%$name"}};

#	print DEBUGFILE join(", ", keys %toinspect), "\n";

	my %inspected = ();
	while (%toinspect) {
	    my $pe = (keys %toinspect)[0];

	    $inspected{$pe} = 1;
	    delete($toinspect{$pe});

	    if (exists($EAPPEARSIN{"%$pe"})) {
		foreach my $elemname (keys %{$EAPPEARSIN{"%$pe"}}) {
#
# nwalsh: 11/04/1999 Why was this here? It short-circuits the whole process.
#                    What was I trying to accomplish?
#
#		    my %eapp = %{$EAPPEARSIN{"%$pe"}};
#		    next if exists $eapp{$elemname};
		    $XAPPEARSIN{"%$name"} = {}
		        if !exists $XAPPEARSIN{"%$name"};
		    $XAPPEARSIN{"%$name"}->{$elemname} = 1;

#		    print DEBUGFILE "X: %$name appears in $elemname\n";
		}
	    }

	    if ($APPEARSIN{"%$pe"}) {
		foreach my $entname (keys %{$APPEARSIN{"%$pe"}}) {
		    $toinspect{$entname} = 1 if !$inspected{$entname};
		}
	    }
	}
    }
}

# ======================================================================

sub cmFragment {
    my $text = shift;
    my $cmfragment = 1;

    # if it contains a keyword, it's not a content model fragment.
    $cmfragment = 0 if $text =~ /\#implied|\#required|\#fixed/is;

    # if it contains characters that can't appear in a content
    # model fragment, then it isn't one.

    # The string #PCDATA is allowed, but would confuse us...
    $text =~ s/\#pcdata//isg;
    $cmfragment = 0 if $text =~ /[^\sa-z0-9_\|\,\&\(\)\*\?\+\-]/is;

    return $cmfragment;
}

# ======================================================================

my $lastmsglen = 0;
my $persist = 0;

sub status {
    my $msg = shift;
    my $shouldpersist = shift || $opt{'debug'};

    return if !$option{'verbose'};

    if ($persist) {
	print "\n";
	$persist = 0;
    } else {
	print "\r";
	print " " x $lastmsglen;
	print "\r";
    }
	
    print $msg;

    $lastmsglen = length($msg);
    $persist = 1 if $shouldpersist || (length($msg) > 78); 
}

# ======================================================================

__END__

=head1 NAME

dtdformat - Read a DTDParse XML file and produce formatted documentation

=head1 SYNOPSIS

 dtdformat [options] xmlfile

=head1 DESCRIPTION

DTDParse is a tool for manipulating XML and SGML Document Type
Definitions (DTDs). DTDParse is designed primarily to aid in the
understanding and documentation of DTDs.

=head2 Options

=over 4

=item html
=item refentry or man
=item debug
=item verbose
=item synopsis
=item content-model
=item attributes
=item inclusions
=item exclusions
=item tag-minimization
=item appears-in
=item description
=item parents
=item chilren
=item examples
=item library
=item unexpanded
=item base-dir

=back

=head2 System Requirements

Running B<dtdformat> requires:

=over 4
=item * Perl 5
=item * Text::DelimMatch
=item * XML::DOM
=item * XML::Parser
=back

=cut
