#!/usr/bin/perl -w
=head1 NAME
  $Id: clob-cdata.pl,v 1.5 2007/02/19 05:41:45 paulg Exp $
=head1 VERSION
  1.0
=head1 DESCRIPTION
  demonstrates generating an XML structure with large [>32k] CLOB elements
  see discussion at http://forums.oracle.com/forums/thread.jspa?threadID=476322

=head1 REQUIRED ARGUMENTS
  parameter 1: database SID
  parameter 2: db username
  parameter 3: db user password

=head1 DEPENDENCIES
  Database user requires "connect,resource,create view" privileges

=head1 AUTHOR
  Paul Gallagher gallagher.paul@gmail.com

=cut

use strict;
use warnings;

use DBI qw(:sql_types);
use XML::Simple ;

my $VERSION = 1.0;

# Set trace level if '-# trace_level' option is given options e.g. ALL, SQL
DBI->trace( shift ) if 1 < @ARGV && $ARGV[0] =~ /^-#/x && shift;

die "syntax: $0 [-# trace] SID user pass" if 3 > @ARGV;
my ( $inst, $user, $pass ) = @ARGV;

# Connect to database. Note we set LongReadLen so can retrieve CLOB intact
my $dbh = DBI->connect( "dbi:Oracle:$inst", $user, $pass,
{ AutoCommit => 1, RaiseError => 0, PrintError => 1, LongReadLen => 5242880 } )
or die $DBI::errstr;


print "--------------------------------------\n";
print "create base table to hold data including CLOB item:\n";
$dbh->do( qq{

CREATE TABLE x1 (item varchar(25) primary key, bigdata clob)

} ) or warn "table creation failure";

print "--------------------------------------\n";
print "create a type to represent data:\n";
$dbh->do( q{

CREATE OR REPLACE TYPE x1_t AS OBJECT 
(Holder varchar(25),BookData CLOB)

} ) or warn "type creation failure";

print "--------------------------------------\n";
print "create xmltype view that includes CLOB elements:\n";
$dbh->do( qq{

CREATE OR REPLACE VIEW vx1 OF XMLTYPE
WITH OBJECT ID (ExtractValue(sys_nc_rowinfo\$, '/ROW/HOLDER')) AS
SELECT sys_XMLGen(x1_t(x.item, x.bigdata)) from x1 x

} ) or warn "view creation failure NB: require create view privilege";

print "--------------------------------------\n";
print "create base record including large CLOB (>32k):\n";
# generate an xml chunk
my @books;
my %dslong;
for (my $i=1; $i<3200; $i++) {
	push(@books, {id => $i, title => [ "the book $i title" ] } );
}
$dslong{"book"} = \@books;
# put some data into it
my $sth = $dbh->prepare( qq{

INSERT INTO x1  (item, bigdata) VALUES (?, ?)

} );
$sth->bind_param(1, "mysample");
$sth->bind_param(2, XMLout( \%dslong , RootName => "books"), { TYPE => SQL_CLOB } );
$sth->execute  or warn "insert creation failure";


print "--------------------------------------\n";
print "vx1 table summary:\n";
list( qq{

SELECT
	extractvalue(x.SYS_NC_ROWINFO\$,'/ROW/HOLDER') as holder
	,'xml_length: ' || dbms_lob.getlength(x.SYS_NC_ROWINFO\$.getclobval()) as xml_length
FROM vx1 x 

} );

print "--------------------------------------\n";
print "vx1 table data:\n";
list( qq{

SELECT
	x.SYS_NC_ROWINFO\$.getclobval()
FROM vx1 x

} );

print "--------------------------------------\n";
print "cleanup:\n";
$dbh->do( 'drop view vx1' ) or warn "drop view vx1 failure";
$dbh->do( 'drop type x1_t' ) or warn "drop view vx1 failure";
$dbh->do( 'drop table x1' ) or warn "drop table x1 failure";

print "--------------------------------------\n";
print "disconnect:\n";
$dbh->disconnect;

1;

# function to list the tables
sub list {
	my ($sql) = @_;
	my $rows = $dbh->selectall_arrayref( $sql );
	foreach my $row (@$rows) {
		print join(", ", map {defined $_ ? $_ : "(null)"} @$row), "\n";
	}
	return;
}

