#!/usr/bin/env perl
use strict;
use warnings;

use File::Find::Rule ();
use File::Remove qw(remove);

my $path = "$ENV{HOME}/tmp/pi";
my $dest = '.';
my $img_glob = 'image*.jpg';
my $anim_glob = 'animated-*.gif';
my $anim_re = 'animated-(\d+).gif';

# go to the image capture directory
chdir $path or die "Can't chdir $path: $!";

# capture the images
my $where = "pi:Pictures/$img_glob";
my @cmd = ('scp', $where, $dest);
system(@cmd) == 0 or die "system(@cmd) failed: $?";

# remove night-time images
my @files = File::Find::Rule->file()
    ->name($img_glob)->size('<80K')->in($dest);
remove(@files);

# increment the animation filename
@files = reverse sort File::Find::Rule->file()
    ->name($anim_glob)->in($dest);
my $last = $files[0];
(my $number = $last) =~ s/^$anim_re$/$1/;
$number++;
(my $fresh_anim = $last) =~ s/\d+/$number/;

# create a fresh animation
@cmd = (qw(convert -delay 70), $img_glob, $fresh_anim);
system(@cmd) == 0 or die "system @cmd failed: $?";

# remove the image files
remove(\1, $img_glob);
