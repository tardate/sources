#!/usr/bin/perl -w
# see DATA section below for info
# $Id: xmltypeinsert-testcase.pl,v 1.3 2007/04/22 02:48:37 paulg Exp $
#

use strict;
use warnings;

use DBI qw(:sql_types);
use XML::Simple;

die "syntax: $0 sid user pass xml-elements" if 4 > @ARGV;
my ( $inst, $user, $pass, $xmlElements ) = @ARGV;

# define how much xml data to insert
print "create a long xml structure or $xmlElements elements (3000 or more should cause ORA fault on insert)\n";

# generate an xml chunk
my @books;
my %dslong;
for (my $i=1; $i<$xmlElements; $i++) {
	push(@books, {id => $i, title => [ "the book $i title" ] } );
}
$dslong{"book"} = \@books;

# Connect to database
my $dbh = DBI->connect( "dbi:Oracle:$inst", $user, $pass,
    { AutoCommit => 1, RaiseError => 0, PrintError => 1 } )
    or die $DBI::errstr;

print "create the database table:\n";
$dbh->do( qq{
CREATE TABLE xmlinserttest
 ( fname VARCHAR(25)
 ,file_header XMLTYPE
)
} ) or warn "table creation failure";


print "insert:\n";
my $sth = $dbh->prepare(qq{
   INSERT INTO xmlinserttest
     (fname
     ,file_header
     )
   VALUES
     (:fname
     ,SYS.XMLType.CreateXML(:file_header)
     )
 }) || die $DBI::errstr;

$sth->bind_param(":fname", "INSERTXMLTYPE");
$sth->bind_param(":file_header", XMLout( \%dslong , RootName => "books") );
$sth->execute  or warn "INSERTXMLTYPE creation failure";

print "list table contents:\n";
list( qq{
SELECT fname,dbms_lob.getlength(xmltype.getclobval(file_header)) FROM xmlinserttest
});

print "drop the database table:\n";
$dbh->do( qq{
drop table xmlinserttest
} ) or warn "table drop failure";

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

__END__


=head1 NAME

DBD::Oracle - Oracle database driver for the DBI module

=head1 SYNOPSIS

perl xmltypeinsert-testcase.pl {SID} {user} {password} {xml-elements}

e.g.

perl xmltypeinsert-testcase.pl ORCL scott tiger 10

.. will test using scott/tiger@ORCL with an XML record of 10 elements


=head1 TEST RESULTS

-----------------------------------------------------------
-- Paul Gallagher gallagher.paul@gmail.com 17-Feb-2007 ----

Environment:
	1.  ActiveState Perl 5.8.8 on Windows XP
	2.  DBI 1.52-r1
	3.  DBD::Oracle v1.17
	4.  Database: Oracle v10.2.0.2 on RHEL3

Results:

	if xmlElements>63, insert fails with:
	DBD::Oracle::st execute failed: ORA-01461: can bind a LONG value only for insert into a LONG column
	
	explicit typing the xml as CLOB will fail with ORA-00942: table or view does not exist. 
	e.g. bind like this:
	$sth->bind_param(":file_header", XMLout( \%dslong , RootName => "books"), { TYPE => SQL_CLOB } );

------------------------------------------------------------
-- Garrett, Philip Philip.Garrett@manheim.com 18-Feb-2007 --

Environment:
	1.  DBD::Oracle v1.19

Results:
	Philip confirmed on dbi-users that limit still remains with 1.19

------------------------------------------------------------

=cut