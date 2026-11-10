#!/usr/bin/env perl

use Modern::Perl;

@ARGV > 2 or die "Usage: $0 make target rom...\n";
my($make, $target, @roms) = @ARGV;

for my $rom (@roms) {
	my $cmd = "$make --no-print-directory PROJ=$rom $target";
	say $cmd;
	system($cmd) == 0 or die "command failed\n";
}
