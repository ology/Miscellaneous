#!/usr/bin/env perl

use v5.36;
use Data::Dumper::Compact qw(ddc);
use MetaCPAN::Client ();

my $mcpan    = MetaCPAN::Client->new;
my $author   = $mcpan->author('GENE');
my $releases = $author->releases;

my $sum = 0;

while (my $rel = $releases->next) {
    my $fav = $mcpan->favorite({ distribution => $rel->distribution });
    say $rel->distribution, ' (v', $rel->version, ') ', 'Favorites=', $fav->total;
    $sum += $fav->total;
}

say "Sum: $sum";