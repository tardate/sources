#!/usr/bin/perl -w
#
# demonstrates/tests the use of Oracle temporary tables with DBI
# this was prompted by the discussion on perl.dbi.users list concerning
# SQL Server/ODBC temp tables "disappearing" 
# See: http://www.nntp.perl.org/group/perl.dbi.users/2007/05/msg31390.html
#
# bottom line is that temp table behaviour with Oracle seems to work fine
#
# blogged about this at http://tardate.blogspot.com/2007/05/do-oracle-temp-tables-behave-correctly.html
# 
# $Id: testOraTempTables.pl,v 1.3 2007/05/11 14:22:14 paulg Exp $
#

use DBI qw(:sql_types);
use Carp;

use strict;

# Set trace level if '-# trace_level' option is given
DBI->trace( shift ) if 1 < @ARGV && $ARGV[0] =~ /^-#/ && shift;

die "syntax: $0 [-# trace] sid user pass" if 3 > @ARGV;
my ( $sid, $user, $pass ) = @ARGV;

# Connect to database
print "[1st connection] connect to $sid {AutoCommit => 1}:\n";
my $dbh = DBI->connect( "dbi:Oracle:$sid", $user, $pass,
    { AutoCommit => 1, RaiseError => 0, PrintError => 1 } )
    or croak $DBI::errstr;

my $sth;

my $s1 = "create global temporary table t1 (x varchar2(10)) on commit preserve rows";
print "[1st connection] create global temp table: $s1\n";
$sth = $dbh->prepare($s1); 
$sth->execute() or carp "$s1 creation failure\n";


# put some data into it
my $s2 = "insert into t1 values (?)";
print "[1st connection] insert 3 rows of data into it: $s2\n";
$sth = $dbh->prepare( $s2 );
$sth->bind_param(1, "row #1");
$sth->execute() or carp "$s2 failed\n";
$sth->execute() or carp "$s2 failed\n";
$sth->execute() or carp "$s2 failed\n";
$sth->finish;

$s2 = "select count(*) from t1";
print "[1st connection] should be 3 rows because we have \"on commit preserve rows\" set: $s2 = ";
printResults ($dbh, "$s2");

# 2nd Connection to database
print "[2nd connection] connect to $sid:\n";
my $dbh2 = DBI->connect( "dbi:Oracle:$sid", $user, $pass,
    { AutoCommit => 1, RaiseError => 0, PrintError => 1 } )
    or croak $DBI::errstr;
$s2 = "select count(*) from t1";
print "[2nd connection] should be 0 rows because while the table definition is shared, the data is not: $s2 = ";
printResults ($dbh2, "$s2");
print "[2nd connection] disconnect:\n";
$dbh2->disconnect;

print "[1st connection] disconnect:\n";
$dbh->disconnect;

print "[1st connection] reconnect {AutoCommit => 0}:\n";
$dbh = DBI->connect( "dbi:Oracle:$sid", $user, $pass,
    { AutoCommit => 0, RaiseError => 0, PrintError => 1 } )
    or croak $DBI::errstr;

$s2 = "select count(*) from t1";
print "[1st connection] should be 0 rows because this is a new session: $s2 = ";
printResults ($dbh, "$s2");

$s2 = "drop table t1";
print "[1st connection] drop the temp table: $s2\n";
$dbh->do( $s2 ) or carp "drop table failed\n";

# now test with AutoCommit => 0 and on commit delete rows
$s1 = "create global temporary table t1 (x varchar2(10)) on commit delete rows";
print "[1st connection] create global temp table: $s1\n";
$sth = $dbh->prepare($s1); 
$sth->execute() or carp "$s1 creation failure\n";


# put some data into it
$s2 = "insert into t1 values (?)";
print "[1st connection] insert 3 rows of data into it: $s2\n";
$sth = $dbh->prepare( $s2 );
$sth->bind_param(1, "row #1");
$sth->execute() or carp "$s2 failed\n";
$sth->execute() or carp "$s2 failed\n";
$sth->execute() or carp "$s2 failed\n";
$sth->finish;

$s2 = "select count(*) from t1";
print "[1st connection] should be 3 rows because we have autocommit off and not committed yet: $s2 = ";
printResults ($dbh, "$s2");

$dbh->commit();

$s2 = "select count(*) from t1";
print "[1st connection] should be 0 rows because now we have committed: $s2 = ";
printResults ($dbh, "$s2");

print "[1st connection] disconnect:\n";
$dbh->disconnect;

print "[1st connection] reconnect {AutoCommit => 1}:\n";
$dbh = DBI->connect( "dbi:Oracle:$sid", $user, $pass,
    { AutoCommit => 1, RaiseError => 0, PrintError => 1 } )
    or croak $DBI::errstr;

# put some data into it
$s2 = "insert into t1 values (?)";
print "[1st connection] insert 3 rows of data into it: $s2\n";
$sth = $dbh->prepare( $s2 );
$sth->bind_param(1, "row #1");
$sth->execute() or carp "$s2 failed\n";
$sth->execute() or carp "$s2 failed\n";
$sth->execute() or carp "$s2 failed\n";
$sth->finish;

# should be no data because we have autocommit on and "on commit delete rows" defined
$s2 = "select count(*) from t1";
print "[1st connection] should be 0 rows because we have autocommit on and \"on commit delete rows\" defined: $s2 = ";
printResults ($dbh, "$s2");

print "[1st connection] disconnect:\n";
$dbh->disconnect;

print "[1st connection] reconnect {AutoCommit => 0}:\n";
$dbh = DBI->connect( "dbi:Oracle:$sid", $user, $pass,
    { AutoCommit => 0, RaiseError => 0, PrintError => 1 } )
    or croak $DBI::errstr;

$s2 = "drop table t1";
print "[1st connection] drop the temp table: $s2\n";
$dbh->do( $s2 ) or carp "drop table failed\n";

print "[1st connection] disconnect:\n";
$dbh->disconnect;


1;

# function to execute a query and print results
sub printResults {
	my ($dbh, $sql) = @_;
    my $rows = $dbh->selectall_arrayref( $sql ) or carp "$sql failed\n";;
    foreach my $row (@$rows) {
		print join(", ", map {defined $_ ? $_ : "(null)"} @$row), "\n";
    }
}

