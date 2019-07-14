#!/usr/bin/env perl
use strict;
use warnings;

use File::Basename;
use File::Touch;
use File::Which qw(which);

sub usage {
    return "Usage: perl $0 [flavor] [path] | path/to.txt\n";
}

# What flavor do we want?
my $flavor = shift || '';

# Where is our fish?
my $path = shift;
$path ||= "$ENV{HOME}/sandbox/fish";
# Bail out if the path does not exist.
die "ERROR: Path does not exist: $path" unless -d $path;

# Unless given a flavor, show the available fish.
unless ($flavor) {
    opendir(my $dir, $path) || die "Can't opendir $path: $!";
    my @fish = grep { /^.*?fish-\w+\.txt$/ } readdir($dir);
    closedir $dir;
    die usage(), join("\n\t", "Fish in $path:", map { /^fish-(\w+)\.txt$/ } sort @fish), "\n";
}

# If we are given a file with a suffix: that is the fish to use.
my($name, undef, $suffix) = fileparse($flavor);
my $fish = $suffix ? $name : "$path/fish-$name.txt";
# Create it if the fish file does not exist.
unless (-e $fish) {
    warn "WARNING: Fish does not exist. Creating $fish";
    touch($fish) || die "Can't touch $fish: $!\n";
}

# Set the editor ... to vim!
my $editor = which('vim');

# Build the command.
my @cmd = ($editor, '+', '-c', 'startinsert!', $fish);
#warn "@cmd\n";
# Execute the command.
system @cmd;