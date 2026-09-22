#!/usr/bin/env perl

use v5.36;
use Data::Dumper::Compact qw(ddc);
use MetaCPAN::Client ();

my $name = shift || 'GENE';

my $mcpan    = MetaCPAN::Client->new;
my $author   = $mcpan->author($name);
my $releases = $author->releases;

my ($i, $total, $sum) = (0, 0, 0);

while (my $rel = $releases->next) {
    $i++;
    $total++;
    my $fav = $mcpan->favorite({ distribution => $rel->distribution });
    say $i, '. ', $rel->distribution, ' (v', $rel->version, ') ', 'Favorites=', $fav->total;
    $sum += $fav->total;
}

say "\nTotal dists: $total, Favs: $sum";