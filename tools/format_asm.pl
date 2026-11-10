#!/usr/bin/env perl

use Modern::Perl;
use File::Copy;
use Getopt::Std;
use Path::Tiny;
use Text::Tabs; $tabstop = 4;

my $KW_L = qr/ \b (?: nz | z | nc | c | po | pe | p | m 
				    | b | c | d | e | h | l | a 
				    | bc | de | hl | af | sp | ix | iy 
				    | i | r 
				    | defb | defw | defc | org 
				    | adc | add | and | bit | call | ccf | cp | cpd | cpdr | cpi | cpir | cpl 
				    | daa | dec | di | djnz | ei | ex | exx | halt | im | in | inc 
				    | ind | indr | ini | inir 
				    | jp | jr | ld | ldd 
				    | lddr | ldi | ldir 
				    | neg | nop | or 
				    | otdr | otir | out | outd | outi 
				    | pop | push | res | ret | reti | retn 
				    | rl | rla | rlc | rlca | rld | rr | rra | rrc | rrca | rrd 
				    | rst | sbc | scf | set | sla | sll | sra | srl | sub | xor
				  ) \b /ix;

my $KW_U = qr/ \b (?: ASMPC
				  ) \b /ix;

our $opt_m; # call make, revert changes if make fails
(getopts("m") &&
 (@ARGV >= 1) &&
 (my $src = shift) &&
 (scalar(@ARGV) % 2 == 0)	# even number of arguments
) or die "Usage: ", path($0)->basename, " [-m] ASM_FILE [str1 replace1 str2 replace2...]\n";

my(%replace) = @ARGV;

$src =~ s/\.\w+$//;

copy($src.".asm", $src.".bak");
open(my $in, "<", $src.".bak") or die;
open(my $out, ">", $src.".new") or die;

my $changes;
while (<$in>) {
	s/\s+$//;

	my $before = $_;
	
	# untabify
	$_ = expand($_);
	
	# leading space
	s/^\s+/ " " x 8 /e;
	
	# space between opcode and operands
	s/^(\s+)(\w+)(\s+)/ sprintf("%-8s%-8s", "", $2) /e;

	my $comment = '';
	my $asm = '';
	while (! / \G \z /gcx) {
		if (/ \G ' .*? ' /gcx) { 
			$asm .= $&; 
		}
		elsif (/ \G " .*? " /gcx) { 
			$asm .= $&; 
		}
		elsif (/ \G $KW_L   /gcx) { 
			$asm .= lc($&); 
		}
		elsif (/ \G $KW_U   /gcx) { 
			$asm .= uc($&); 
		}
		elsif (/ \G (,) \s* /gcx) { 
			$asm .= $1 . ' '; 
		}
		elsif (/ \G \s+     /gcx) { 
			$asm .= $&; 
		}
		elsif (/ \G ; .*    /gcx) { 
			$comment = $&; 
			$asm =~ s/(\S)\s+$/$1/; 
		}
		elsif (/ \G .       /gcx) { 
			$asm .= $&; 
		}
		else { 
			die "cannot parse $_"; 
		}
	}
	
	# replace strings
	while (my($k, $v) = each %replace) {
		my $re = qr/\Q$k\E/;
		if ($k =~ /^\w/) { $re = qr/\b$re/; }
		if ($k =~ /\w$/) { $re = qr/$re\b/; }
		$asm =~ s/$re/$v/g;
	}
	
	# format output
	my $after;
	if (length($asm) > 32) {
		$after = $asm;
		
		if (length($comment) > 0) {
			$after .= "\n" . (" " x 32) . $comment;
		}
	}
	elsif (length($asm) > 0) {
		$after = sprintf("%-32s%s", $asm, $comment);
	}
	else {
		$after = $comment;
	}
	$after =~ s/\s+$//;

	$after = expand($after);		# need to remove tabs for GitHub
	
	if ($before ne $after) {
		$changes++;
		
		if (expand($before) ne expand($after)) {		# only show non-ws changes
			say "line $.:";
			say expand($before);
			say expand($after);
			say "";
		}
	}
	
	say $out $after;
}
close($in);
close($out);

if ($changes) {
	say "Update ".$src.".asm";
	move($src.".new", $src.".asm");

	if ($opt_m && system("make") != 0) {
		say "Error assembling new file, reverting to previous ".$src.".asm";
		move($src.".bak", $src.".asm");
	}
}
else {
	unlink $src.".new";
}
