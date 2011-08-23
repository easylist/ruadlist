#!/usr/bin/perl

#############################################################################
# This is a reference script to add checksums to downloadable               #
# subscriptions. The checksum will be validated by Adblock Plus on download #
# and checksum mismatches (broken downloads) will be rejected.              #
#                                                                           #
# To add a checksum to a subscription file, run the script like this:       #
#                                                                           #
#   perl addChecksum.pl subscription.txt                                    #
#                                                                           #
# Note: your subscription file should be saved in UTF-8 encoding, otherwise #
# the generated checksum might be incorrect.                                #
#                                                                           #
#############################################################################

use strict;
use warnings;
use Digest::MD5 qw(md5_base64);

die "Usage: $^X $0 subscription.txt\n" unless @ARGV;

my $file = $ARGV[0];
my $data = readFile($file);

# Remove already existing checksum
$data =~ s/^.*!\s*checksum[\s\-:]+([\w\+\/=]+).*\n//gmi;
my $oldsum = $1;

# Calculate new checksum
my $checksum = getChecksum($data);

if ($checksum ne $oldsum) {
  # Get current date and time (GMT)
  my ($sec,$min,$hour,$day,$month,$yr19,@rest) = gmtime(time);
  my $datetimevar = ($yr19+1900).".".sprintf("%02d",$month).".".sprintf("%02d",$day)." ".sprintf("%02d",$hour).":".sprintf("%02d",$min);

  # Remove already existing date-time
  $data =~ s/^.*!\s*last update \(gmt\)[\s\-:]+(\d{4}([\s.:]\d\d?)*).*\n//gmi;

  # Insert date-time into the file
  $data =~ s/(\r?\n)/$1! Last update (GMT): $datetimevar$1/;
}

# Calculate new checksum
$checksum = getChecksum($data);

# Insert checksum into the file
$data =~ s/(\r?\n)/$1! Checksum: $checksum$1/;

writeFile($file, $data);

sub getChecksum
{
  # Calculate new checksum: remove all CR symbols and empty
  # lines and get an MD5 checksum of the result (base64-encoded,
  # without the trailing = characters).
  my $checksumData = shift;
  $checksumData =~ s/\xEF\xBB\xBF//g;
  $checksumData =~ s/\r//g;
  $checksumData =~ s/\n+/\n/g;

  # Calculate new checksum
  return md5_base64($checksumData);
}

sub readFile
{
  my $file = shift;

  open(local *FILE, "<", $file) || die "Could not read file '$file'";
  binmode(FILE);
  local $/;
  my $result = <FILE>;
  close(FILE);

  return $result;
}

sub writeFile
{
  my ($file, $contents) = @_;

  open(local *FILE, ">", $file) || die "Could not write file '$file'";
  binmode(FILE);
  print FILE $contents;
  close(FILE);
}
