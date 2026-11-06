#!/usr/bin/env perl

use Modern::Perl;

for my $file (@ARGV) {
	my $cmd = "perl format_asm.pl $file";
	say $cmd;
	system($cmd) == 0 or die "command failed\n";
}
