#!/usr/bin/env perl
use strict;
use warnings;

use Text::Table::Tiny 0.04 qw/ generate_table /;

my $data = {
    Name   => [qw(Alice Bob Carol)],
    Rank   => [qw(pvt cpl gen)],
    Serial => [qw(123456 98765321 8745)],
};

my @headers = sort keys %$data;

my $rows = [\@headers];

for my $i (0 .. @{ $data->{$headers[0]} } - 1) {
    my @row;
    for my $header (@headers) {
        push @row, $data->{$header}[$i];
    }
    push @$rows, \@row;
}

print generate_table(rows => $rows, header_row => 1);
