#!/usr/bin/env perl
use strict;
use warnings;

use DBI;
use Test::mysqld;
use Test::More;
 
my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '', # no TCP socket
#        password => 'abc123',
    },
#    copy_data_from => '/usr/local/var/mysql',
#    base_dir => '/tmp',
) or die $Test::mysqld::errstr;
#warn(__PACKAGE__,' ',__LINE__," MARK: ",$mysqld->base_dir,"\n");

$mysqld->setup;
$mysqld->start;

my $dbh = DBI->connect(
    $mysqld->dsn(),
);

my $sql =<<'SQL';
CREATE TABLE test (
    id INT NOT NULL AUTO_INCREMENT,
    text VARCHAR(255) NOT NULL,
    PRIMARY KEY (id)
)
SQL

my $sth = $dbh->prepare($sql) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;

$sql = "insert into test (text) values ('Yabba dabba doo!')";
$sth = $dbh->prepare($sql) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;

$sql = 'select * from test';
$sth = $dbh->prepare($sql) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;

my $results = $sth->fetchall_arrayref();

$sth->finish;
$dbh->disconnect;

for my $result ( @$results ) {
    is $result->[1], 'Yabba dabba doo!', "test id=$result->[0]";
}

done_testing();
