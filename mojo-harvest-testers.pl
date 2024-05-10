#!/usr/bin/env perl
use strict;
use warnings;

use Mojo::UserAgent;
use Mojo::DOM;

my $author = shift || 'GENE';
my $site = 'https://metacpan.org';
my $url = "$site/author/$author";

my $ua = Mojo::UserAgent->new;
my $tx = $ua->get($url);

my $content = $tx->res->body;
my $dom = Mojo::DOM->new($content);

my $links = $dom->find('a.release-name');

for my $link (@$links) {
    $url = $site . $link->attr('href');
    $tx = $ua->get($url);
    $content = $tx->res->body;
    $dom = Mojo::DOM->new($content);
    my $testers = $dom->at('li a[title=Matrix]')->parent;
    (my $text = $testers->all_text) =~ s/\n//g;
    $text =~ s/\s+/ /g;
    print $link->all_text, ' :', $text, "\n";
    sleep 1;
}
