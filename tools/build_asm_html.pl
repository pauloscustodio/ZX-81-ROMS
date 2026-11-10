#!/usr/bin/env perl

use Modern::Perl;
use File::Copy;
use Path::Tiny;
use Text::Tabs; $tabstop = 4;
use HTML::Entities;

@ARGV==1 or die;

my $src = shift;
(my $dest = $src) =~ s/\.asm$/.html/ or die;
copy($dest, $dest.".bak") if -f $dest;

(my $map = $src) =~ s/\.asm$/.map/ or die;

# read whole map file, define as comment
my @map_syms = map {s/\s*;.*//; s/^/; /; $_} grep {!/^__/} path($map)->lines;

# read whole asm file
my @lines = (
	path($src)->lines,
	"\n",
	"\n",
	"; *****************\n",
	"; Map file by value\n",
	"; *****************\n",
	"\n",
	@map_syms,
	"\n",
	"; ****************\n",
	"; Map file by name\n",
	"; ****************\n",
	"\n",
	(sort @map_syms),
);

# collect all labels from asm, create anchors at each
my %labels;
my $first = 1;
for (@lines) {
	$_ = expand($_);
	$_ = encode_entities($_);
	if (/^\s*(\w+):/ || /^\s*\.(\w+)/ || /^\s*DEFC\s+(\w+)/i) {
		my $label = $1;
		die "label $label redefined" if $labels{$label}++;
		$_ = '<a name="'.$label.'"></a>'.$_;
	}
	$_ = '<br>'.$_ unless $first;
	$first = 0;
}

# create links
for (@lines) {
	my $out = '';
	while (!/\G\z/gc) {
		if (/\G<.*?>/gc) { $out .= $&; }
		elsif (/\G&.*?;/gc) { $out .= $&; }
		elsif (/\G\$[0-9A-F]+/gci) { $out .= '<b>'.$&.'</b>'; }
		elsif (/\G[-=*]{4,}/gc) { $out .= '<b>'.$&.'</b>'; }
		elsif (/\G\w+/gc) {
			my $name = $&;
			if ($labels{$name}) {
				$out .= '<a href="#'.$name.'">'.$name.'</a>';
			}
			else {
				$out .= $name;
			}
		}
		elsif (/\G /gc) { $out .= '&nbsp;'; }
		elsif (/\G./gcs) { $out .= $&; }		# s: . matches newline
		else { die; }
	}
	$_ = $out;
}

# add header and footer
unshift(@lines, <<END);
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<title>$src</title>
<style>
*{
	font-family: Courier New;
	font-size: small;
}
</style>
</head>
<body bgcolor="#FFFFFF">
END

push (@lines, <<END);
</body>
</html>
END

# write htm file
path($dest)->spew(@lines);
