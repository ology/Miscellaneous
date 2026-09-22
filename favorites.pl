#!/usr/bin/env perl

use v5.36;
use Data::Dumper::Compact qw(ddc);
use MetaCPAN::Client ();

my $name = shift || 'GENE';

my $mcpan    = MetaCPAN::Client->new;
my $author   = $mcpan->author($name);
my $releases = $author->releases;

my ($total, $sum) = (0, 0);

while (my $rel = $releases->next) {
    $total++;
    my $fav = $mcpan->favorite({ distribution => $rel->distribution });
    say $rel->distribution, ' (v', $rel->version, ') ', 'Favorites=', $fav->total;
    $sum += $fav->total;
}

say "Total dists: $total, Sum: $sum";