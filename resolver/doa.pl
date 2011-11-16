#!/usr/bin/perl

use Net::DNS;
use feature "switch";

open(INFILE, "<", "deadhosts.txt") or die("cannot open infile:  $!");

my @ip_array = <INFILE>;

close(INFILE);

open(OUTFILE, ">", "deadhosts.tmp") or die("unable to write output: $!");

chomp(@ip_array);

$p = Net::DNS::Resolver->new;

foreach $s (@ip_array) {
	if($s =~ /^[^!].*$/) {
		$q = $p->query($s);
		if(not $q) {
			print "D $s ", $p->errorstring, "\n";
			given ($p->errorstring) {
				when (/^NOERROR/)  { push(@noerr,$s) }
				when (/^SERVFAIL/) { push(@srvfl,$s) }
				when (/^NXDOMAIN/) { push(@nxdom,$s) }
			}
		} else {
			print "A $s \n";
			foreach my $rr ($q->answer)	{
				next unless $rr->type eq "A";
				print "Address: ", $rr->address, "\n";
			}
		}
	}	
}

print OUTFILE "! NOERROR\n";
foreach(sort @noerr) { print OUTFILE "$_\n" }

print OUTFILE "! SERVFAIL\n";
foreach(sort @srvfl) { print OUTFILE "$_\n" }

print OUTFILE "! NXDOMAIN\n";
foreach(sort @nxdom) { print OUTFILE "$_\n" }

close(OUTFILE);

unlink("deadhosts.txt");
rename("deadhosts.tmp","deadhosts.txt");

print "\n";
print "NOERROR  A NOERROR indicates that the domain does exist", "\n";
print "         according to the root name servers and that the", "\n";
print "         authoritative name servers are answering queries", "\n";
print "         correctly for that domain.", "\n\n";
print "SERVFAIL SERVFAIL means that the domain does exist and the", "\n";
print "         root name servers have information on this domain,", "\n";
print "         but that the authoritative name servers are not", "\n";
print "         answering queries for this domain.", "\n\n";
print "NXDOMAIN NXDOMAIN can means that the root name servers are", "\n";
print "         not providing any authoritative name servers for", "\n";
print "         this domain. This can be because the domain does", "\n";
print "         not exist or that the domain is on-hold.", "\n";
print "\n";

