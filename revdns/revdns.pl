#!/usr/bin/perl

use Net::DNS;
use feature "switch";

$infile = "hosts.txt";

foreach my $arg (@ARGV) {
	given ($arg) {
		when (/^-t/) { $testloop = 1; }
		default      { $infile = $arg; }
	}
}

open(INFILE, "<", $infile) or die("Can't open file:  $!");

my @ip_array = <INFILE>;

close(INFILE);

chomp(@ip_array);

$p = Net::DNS::Resolver->new;

sub formatip {
	@octets = split(/\./, @_[0]);
	foreach $o (@octets) { while (length($o) < 3) { $o = '0' . $o; } }
	return join('.',@octets);
}

$| = 1;
foreach $s (@ip_array) {
	if($s =~ /^[^!].*$/) {
		print "\rDomain: $s";
		for($i = 80-8-length($s);$i>0;$i--) {print " ";} 
		$q = $p->query($s);
		if($q) {
			foreach my $rr ($q->answer) {
				next unless $rr->type eq "A";
				push(@lst, {ad => $s, ip => formatip($rr->address)});
			}
		}
	}	
}
print "\n";

open(OUTFILE, ">", "hosts.lst") or die("Unable to write output: $!");
$prev = ''; $rpt = 0;
foreach(sort {$a->{ip} cmp $b->{ip}} @lst) {
	$now = $_->{ip};
	if ($now eq $prev) { $rpt++; }
	if ((not $now eq $prev) and ($rpt > 0)) { $rpt = 0; print OUTFILE "# ^\n"; }
	print OUTFILE $_->{ip}." ".$_->{ad}."\n";
	$prev = $now;
}
close(OUTFILE);

