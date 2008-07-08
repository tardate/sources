#!/usr/bin/perl -w

=head1 NAME

oraAlertLog.pl

=head1 SYNOPSIS

Find and tail the Oracle alert log.
See http://tardate.blogspot.com/2007/04/find-and-tail-oracle-alert-log.html for discussion.

$Id: oraAlertLog.pl,v 1.8 2007/04/22 23:27:04 paulg Exp $

=head1 DESCRIPTION

USAGE:
    perl oraAlertLog.pl OPTIONS

OPTIONS:
    [-i] show information about the Oracle environment and log location
    [-f] tail the alert log
    [-h] help

=head1 AUTHOR

Paul Gallagher  gallagher.paul@gmail.com
http://tardate.blogspot.com

=cut

use strict;
use Carp;
use IO::Handle;
use DBI;
use DBD::Oracle qw(:ora_session_modes);
use Env qw(ORACLE_SID ORACLE_HOME);
use Getopt::Std;
use File::Basename;

my $VERSION = 1.0;

my ($scriptBase, $scriptPath, $scriptSuffix) = fileparse($0, qr/\..*/);

my %option = ();
getopts('ifh', \%option);

if ($option{i}) {
	info();
}
elsif ($option{f}) {
	tailLog();
}
else {
	usage();
}

1;


sub usage
{
	my ($msg) = @_;
	if ($msg) {
		print "\nWARNING: $msg\n";
	}
    print <<END_OF_USAGE;

PURPOSE: Find and tail the Oracle alert log.

USAGE:
    perl oraAlertLog.pl OPTIONS

OPTIONS:
    [-i] show information about the Oracle environment and log location
    [-f] tail the alert log
    [-h] help

END_OF_USAGE

	print "Version: $VERSION   ".'Last modified: $Date: 2007/04/22 23:27:04 $'."\n";
    exit;
}


sub getAlertLogName
{
	my $alertlog="";
	use vars qw($cachedalertlog); 
	$cachedalertlog="";

	if (!defined(${ORACLE_SID}) || !(${ORACLE_SID} =~ /\S/) ) {
		print STDERR "ORACLE environment not available.\n\n";
		exit(1);
	}

	my $cacheFile="${scriptPath}${scriptBase}.${ORACLE_SID}.conf";

	my $skipdb=0;
	my $dbh = DBI->connect('dbi:Oracle:', '', '', 
		{ora_session_mode => ORA_SYSDBA , RaiseError => 0, PrintError => 0, AutoCommit => 0}) or 
		$skipdb=1;
	$skipdb or 
		my $sth = $dbh->prepare(q{SELECT value FROM   v$parameter WHERE  name = 'background_dump_dest'}) or
		$skipdb=1;
	if (!$skipdb) {
		$sth->execute;
		my $row = $sth->fetchrow_hashref;
		$sth->finish;
		$alertlog=$row->{VALUE};
		$dbh->disconnect;
	}

	if (  $alertlog =~ /\S/ ) {
		$alertlog .= "/alert_${ORACLE_SID}.log";
	}
	else {
		print "ORACLE not available.Checking for cached settings..\n";
		open( my $fh, "<", $cacheFile) or croak("Problem opening conf file $cacheFile : $!");
		while (<$fh>) {
			chomp;
			if (/^\s*alertlog\s*=/i) {
				s/.*=\s*//; 
				$alertlog= $_;
			}
		}
		close $fh;
	}
	if ( $alertlog !~ /\S/ ) {
		croak( "Could not determine alert log location.");
	}
	else {
		open( my $fh, ">", $cacheFile) or croak("Problem opening cache file $cacheFile : $!");
		print $fh "alertlog=${alertlog}\n";
		close($fh);
	}
	return $alertlog;
}


sub info
{
	my $fn = getAlertLogName();
	print "ORACLE_HOME = " . $ORACLE_HOME . "\n";
	print "ORACLE_SID  = " . $ORACLE_SID . "\n";
	print "ALERT LOG   = " . $fn . "\n";
}


sub tailLog
{
	my $fn = getAlertLogName();
	my $log;
	open (LOGFILE, $fn) or croak("can't open $fn: $!");
	for (;;) {
		while (<LOGFILE>) { print }
		sleep 1;
		LOGFILE->clearerr();
	}
}
