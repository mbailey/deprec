#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use File::Basename;

# Author: Dean Wilson ; License: GPL
# Project Home: http://www.unixdaemon.net/
# For documentation look at the bottom of this file, or run with '-h'
# Version 0.5 - Tided up arg handling. Added usage

# Changes:
# Usage information corrected, thanks to Bartlomiej Konarski

# nagios requires a 3 for unknown errors.
$SIG{__DIE__} = sub {
  print @_;
  exit 3;
};

my $app = basename($0);

GetOptions(
  "w|warn=s" => \( my $warn_percent = 30 ),
  "c|crit=s" => \( my $crit_percent = 20 ),
  "h|help"   => \&usage,
);

# remove any % passed in
$warn_percent =~ s/%//;
$crit_percent =~ s/%//;

die "Warning value must be larger than critical value\n"
  unless $warn_percent >= $crit_percent;

my $memory_stats_ref = get_mem();
my $percentage_free = get_percentage($memory_stats_ref);

if ($percentage_free <= $crit_percent) {
  print "CRIT: Only $percentage_free% ($memory_stats_ref->{free_cache}M) of memory free!\n";
  exit 2;
} elsif ($percentage_free <= $warn_percent) {
  print "WARN: Only $percentage_free% ($memory_stats_ref->{free_cache}M) of memory free!\n";
  exit 1;
} else {
  print "OK: $percentage_free% ($memory_stats_ref->{free_cache}M) free memory.\n";
  exit 0;
}

#########################################

sub get_mem {
   # get the two values from the free command.
   # return them as a hash ref

   my %memory_stats;

  open(FREEPIPE, "free -m |")
    || die "Failed to open 'free'\n$!\n";

  while(<FREEPIPE>) {
    chomp;
    next unless m!buffers/cache:!;
    m/[^\d]+(\d+)\s+(\d+)$/;
    $memory_stats{'used_cache'} = $1;
    $memory_stats{'free_cache'} = $2;
  }

  close FREEPIPE;

  return \%memory_stats;
}

#------------------------------------------#

sub get_percentage {
  my $mem_stats_ref = shift;
  my $percentage_free;

  my $total = $mem_stats_ref->{'used_cache'} + $mem_stats_ref->{'free_cache'};
  $percentage_free = int (($mem_stats_ref->{'free_cache'} / $total) * 100);

  return $percentage_free;
}

#------------------------------------------#

sub usage {
  print<<EOU;

$app - Copyright (c) 2006 Dean Wilson. Licensed under the GPL

This script reports the percentage of memory that's still free along
with a warning or a critical based upon user defined threshholds.

This script was written to be used in conjunction with Nagios.

Usage Examples:
 $app   -w 20 -c 10
 $app   -warn 30 -crit 15
 $app   -h    # shows this information

Options:
  -w | -warn
    Warn if less than this percentage is free.
  -c | -crit
    Crit if less than this percentage is free.
  -h
    This help and usage information

Notes:
  The output format of "free" (which this script wraps) can change
  between releases. Please double check the outputs before you deploy
  this script.

EOU
  exit 3;
}
