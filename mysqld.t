#!/usr/bin/env perl
use strict;
use warnings;

use DBI;
use Test::mysqld;
use Test::More;
 
my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '', # no TCP socket
    },
    copy_data_from => '/usr/local/var/mysql',
) or die $Test::mysqld::errstr;

$mysqld->setup;
$mysqld->start;

my $dbh = DBI->connect(
    $mysqld->dsn(dbname => 'stuff'), 'root', 'abc123'
) or die $DBI::errstr;

my $sql = 'select * from junk';
my $sth = $dbh->prepare($sql) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;

my $results = $sth->fetchall_arrayref();
#use Data::Dumper;warn(__PACKAGE__,' ',__LINE__," MARK: ",Dumper$results);

$sth->finish;
$dbh->disconnect;

$mysqld->stop;

is_deeply $results->[0], [qw/foo 42 3/], 'results';
is_deeply $results->[1], [qw/bar 1 1000/], 'results';

done_testing();
