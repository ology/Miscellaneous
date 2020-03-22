#!/usr/bin/env perl
use strict;
use warnings;

use File::Touch;
use File::Which qw(which);
use File::Find::Rule;

sub usage { return "Usage: perl $0 [flavor] [path]\n"; }

my $flavor = shift || '';

my $path = "$ENV{HOME}/sandbox/fish";
die "ERROR: Path does not exist: $path" unless -d $path;

# Unless given a flavor, show the available fish
unless ($flavor) {
    my @fish = File::Find::Rule->file()->name('fish-*.txt')->in($path);
    die usage(), join("\n\t", "Fish in $path:", map { /fish-(.+?)\.txt$/ } sort @fish), "\n";
}

my $fish = "$path/fish-$flavor.txt";

unless (-e $fish) {
    warn "Fish does not exist. Creating $fish";
    touch($fish) || die "Can't touch $fish: $!\n";
}

# Set the editor ... to vim!
my $editor = which('vim');

# Start vim in edit mode at the bottom of the fish file
my @cmd = ($editor, '+', '-c', 'startinsert!', $fish);
#warn "@cmd\n";
system @cmd;
