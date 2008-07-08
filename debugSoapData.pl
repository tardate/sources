#!/usr/bin/perl -w
# $Id: debugSoapData.pl,v 1.2 2007/05/19 02:48:51 paulg Exp $
# 
# how to debug SOAP::Lite xml
#
# See  http://www.majordojo.com/archives/cat_soaplite_solutions.html
#

use strict;
use Getopt::Long;
use Data::Dumper; $Data::Dumper::Terse = 1; $Data::Dumper::Indent = 1;

my $opt_name   = "joe blow";
my $opt_city   = "Singapore";
my $opt_zip    = "787082";
my $opt_street = "Yio Chu Kand Rd";
my $opt_state  = "na";
my $opt_debug;
my $opt_help;

GetOptions(
	"name=s" => \$opt_name,
	"city=s" => \$opt_city,
	"street=s" => \$opt_street,
	"state=s" => \$opt_state,
	"zip=s" => \$opt_zip,
	"help" => \$opt_help,
	"debug" => \$opt_debug
);

usage() if $opt_help;

if ($opt_debug) {
    eval "use SOAP::Lite +trace => 'debug';";
} else {
    eval "use SOAP::Lite;";
}


sub usage
{
    print <<END_OF_USAGE;
PURPOSE:
Tests debug for SOAP::Lite
USAGE:
perl debugSoapData.pl -debug

END_OF_USAGE
}


my $serviceUrl = 'http://localhost:8000/axis2/services/AddressBookService';
my $wsdlUrl = 'http://localhost/axis2/services/AddressBookService?wsdl';
my $serviceNs = 'http://service.addressbook.sample/xsd';
my $entryNs = 'http://entry.addressbook.sample/xsd';


my $soap = SOAP::Lite
    -> proxy ( $serviceUrl)
	;

# 
#
sub dumpit {
	my ( $dat ) = @_;
	print Dumper $dat;	

}

# find entry
sub findEntry {
	my ( $soap, $search_name ) = @_;

	my $som = $soap->call(SOAP::Data->name('findEntry')->attr({xmlns => $serviceNs})
	               => ($search_name)
	);

	#my $som = $soap->findEntry($search_name);
	dumpit( $som );
}



# add an entry - works
sub addEntry {

	my ( $soap, $opt_name, $opt_city, $opt_street, $opt_state,$opt_zip ) = @_;

	my $som = $soap->call(
		SOAP::Data->name('addEntry')->attr({xmlns => $serviceNs}) =>
			SOAP::Data->name('param0' =>
				\SOAP::Data->value(
				SOAP::Data->name('city' => $opt_city),
				SOAP::Data->name('name' => $opt_name),
				SOAP::Data->name('postalCode' => $opt_zip),
				SOAP::Data->name('state' => $opt_state),
				SOAP::Data->name('street' => $opt_street)
				)
			)
	);

	# cool. see http://tech.groups.yahoo.com/group/soaplite/message/5946
	print $soap->transport->http_request->content();

	dumpit( $som );

}

addEntry( $soap, $opt_name, $opt_city, $opt_street, $opt_state,$opt_zip );

#findEntry( $soap, $opt_name);
