#!/usr/bin/env perl
use strict;
use warnings;

use File::Find::Rule ();
use File::Remove qw(remove);

my $path = "$ENV{HOME}/tmp/pi";
my $dest = '.';
my $img_glob = 'image*.jpg';
my $animation = 'animated-*.gif';
my $animation_re = 'animated-(\d+).gif';

chdir $path or die "Can't chdir $path: $!";

my $where = "pi:Pictures/$img_glob";
my @cmd = ('scp', $where, $dest);
system(@cmd) == 0 or die "system(@cmd) failed: $?";

my @files = reverse sort File::Find::Rule->file()
    ->name($animation)->in($dest);
my $last = $files[0];
(my $number = $last) =~ s/^$animation_re$/$1/;
$number++;
(my $fresh_animation = $last) =~ s/\d+/$number/;

@cmd = (qw(convert -delay 70), $img_glob, $fresh_animation);
system(@cmd) == 0 or die "system @cmd failed: $?";

remove(\1, $img_glob);
