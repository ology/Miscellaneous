#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename;
use File::Touch;
use File::Which qw(which);

sub usage {
    return "Usage: perl $0 [flavor] [path]\n";
}

my $flavor = shift || '';

my $path = "$ENV{HOME}/sandbox/fish";
die "ERROR: Path does not exist: $path" unless -d $path;

# Unless given a flavor, show the available fish.
unless ($flavor) {
    opendir(my $dir, $path) || die "Can't opendir $path: $!";
    my @fish = grep { /^.*?fish-.+?\.txt$/ } readdir($dir);
    closedir $dir;
    die usage(), join("\n\t", "Fish in $path:", map { /^fish-(.+?)\.txt$/ } sort @fish), "\n";
}

my $fish = "$path/fish-$flavor.txt";

unless (-e $fish) {
    warn "Fish does not exist. Creating $fish";
    touch($fish) || die "Can't touch $fish: $!\n";
}

# Set the editor ... to vim!
my $editor = which('vim');

# Build the command.
my @cmd = ($editor, '+', '-c', 'startinsert!', $fish);
#warn "@cmd\n";
# Execute the command.
system @cmd;
