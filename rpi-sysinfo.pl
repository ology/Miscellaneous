#!/usr/bin/env perl
use strict;
use warnings;

use RPi::SysInfo ();

my $type = shift || die "Usage: perl $0 type\n";
my $first = shift // 0;
my $last = shift // 53;
 
my $sys = RPi::SysInfo->new;

my %dispatch = (
  conf   => sub { $sys->raspi_confi },
  net    => sub { $sys->network_inf },
  fs     => sub { $sys->file_system },
  detail => sub { $sys->pi_details },
  stat   => sub {
    return join(' ', 'CPU:', $sys->cpu_percent, "%\n")
         . join(' ', 'MEM:', $sys->mem_percent, "%\n")
         . join(' ', 'Temp:', $sys->core_temp, "C°\n")
  },
  gpio => sub { $sys->gpio_info([ $first .. $last ]) },
);

print $dispatch{$type}->();
