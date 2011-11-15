#!/usr/bin/perl

#use Net::Ping;
use Net::DNS;

open(INFILE, "<", "checklist.txt") or die("cannot open infile:  $!");

my @ip_array = <INFILE>;

close(INFILE);

open(OUTFILE, ">", "deadhosts.txt") or die("unable to write output: $!");

chomp(@ip_array);

#$p = Net::Ping->new("icmp", 3, 64);
$p = Net::DNS::Resolver->new;

foreach(@ip_array)
  {
   if($_ =~ /^.*$/)
      { 
	if(not $p->query($&))
          {
            print ("D $&\n");
            print OUTFILE ("$&\n");
          }
	else
          {
            print ("A $&\n");
          }
      }	
  } 

close(OUTFILE);
