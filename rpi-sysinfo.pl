#!/usr/bin/env perl
use strict;
use warnings;

use RPi::SysInfo ();

my $type  = shift || die "Usage: perl $0 [conf|net|fs|pi|pins|stat|gpiov|gpiora]\n";
my $first = shift // 0;
my $last  = shift // 53;
 
my $sys = RPi::SysInfo->new;

my %dispatch = (
  conf => sub { $sys->raspi_config },
  net  => sub { $sys->network_info },
  fs   => sub { $sys->file_system },
  pi   => sub { $sys->pi_details },
  pins => sub { $sys->gpio_info([ $first .. $last ]) },
  stat => sub {
    return join(' ', 'CPU:', $sys->cpu_percent, "%\n")
         . join(' ', 'MEM:', $sys->mem_percent, "%\n")
         . join(' ', 'Temp:', $sys->core_temp, "C°\n")
  },
  gpiov  => sub { qx{ gpio -v } },
  gpiora => sub { qx{ gpio readall } },
);

print $dispatch{$type}->();
