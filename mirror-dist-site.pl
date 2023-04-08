#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long qw(GetOptions);
use File::Basename qw(basename dirname);
use File::Copy::Recursive qw(fcopy);
use File::Path qw(make_path);
use File::Slurper qw(read_text write_text);

my %replacement = (
    REPLACE_ME => 'Abc123',
);

my %opt = (
    source => '.',
    dest   => '.',
);
GetOptions(\%opt,
    'source=s',
    'dest=s',
) or die 'Error parsing command options';

die "Source directory not given.\n" unless $opt{source};

$opt{source} =~ s/\/$//;
$opt{dest} =~ s/\/$//;

while (my $line = readline(DATA)) {
    chomp $line;

    my ($file, $to) = split /\s+/, $line;

    my $name = basename($file);

    my $source = "$opt{source}/$file";

    unless (-e $source) {
        warn "WARNING: $source does not exist: $!\n";
        next;
    }

    my $content = '';

    if (-f $source) {
        $content = read_text($source);
        for my $replace (keys %replacement) {
            if ($content =~ /<%\s*$replace\s*%>/) {
                $content =~ s/<%\s*$replace\s*%>/$replacement{$replace}/g;
                print "Replaced $replace in $source\n";
            }
        }
    }

    $to ||= '';
    $to =~ s/\/$//;

    $to = "$to/$name" if -d $source;

    my $path = $opt{dest};
    $path .= "/$to" if $to;

    unless (-e $path) {
        make_path($path);
        print "Wrote $path\n";
    }

    if (-f $source) {
        my $dest = "$path/$name";
        write_text($dest, $content);
        print "Wrote $source to $dest\n";
    }
}

__END__
images docs
config.yaml docs
custom.scss docs
Makefile docs
menu.yaml docs
package.json docs
README.md docs
_pages/index.md docs
_pages/installation.md docs
