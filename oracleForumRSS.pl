#!/usr/bin/perl 

=head1 NAME

oracleForumRSS.pl - a CGI script to generate RSS feed of recent posts by a
specified author to the Oracle forums at http://forums.oracle.com

=head1 VERSION

$Id: oracleForumRSS.pl,v 1.6 2007/05/13 17:16:56 oracle Exp $

=head1 DESCRIPTION

For more information, see: http://tardate.blogspot.com/2007/05/getting-your-oracle-forum-posts-as-rss.html

=head1 REQUIRES

CGI
XML::RSS::SimpleGen

=head1 AUTHOR

gallagher.paul@gmail.com

=cut


use strict;

use CGI qw (:standard escapeHTML);
use XML::RSS::SimpleGen;

my $userID = param("userID");
my $userName = param("userName");
my $webMaster = $ENV{'SERVER_ADMIN'};

if ($userID) {
  sendAuthorRss( $userID, $userName );
} else {
  sendConfigPage();
}

1;


# send configuration page
sub sendConfigPage {
  my $style=<<END;
  BODY {
    background-color: cyan;
  }
  P {
    font-size: 10pt;
    font-family: sans-serif;
    color: black;
  }
END

  print header();
  print start_html(-title=>'Oracle Forum - Author RSS Feed',
                            -author=>$webMaster,
                            -style=>$style );

  print p( 'This script will generate an RSS feed of all recent posts to the ' .
           a({-href=>'http://forums.oracle.com'}, 'Oracle Forums') . ' by the user you specify here.' );
  print start_form(-method=>'GET',-action=>'');

  print p( 'Forum User ID: ' . textfield(-name=>'userID') . ' (you will need to look this up. It is the numeric userID value)' );

  print p( 'Display name: ' .  textfield(-name=>'userName') . ' (make up a screen name for the user)' );

  print submit('Submit','submit');

  print endform();

  print end_html();
}


# generate the RSS feed for given author 
sub sendAuthorRss {
  my $userID = shift;
  my $userName = shift;

  my $urlRel = 'http://forums.oracle.com/forums/';
  my $url = $urlRel . 'profile.jspa?userID=' . $userID . '&start=0';


  rss_new( $url, "My Activity in the Oracle Forums", "Recent Posts By " . $userName );
  rss_language( 'en' );
  rss_webmaster( $webMaster );
  rss_updatePeriod('daily');

  get_url( $url );

  while(
	m{jive-thread-name.*?<a href="(.*?)"\s*>(.*?)</a>.*?<nobr>.*?<nobr>.*?<nobr>.*?<nobr>.*?<nobr>(.*?)</nobr>.*?<div class="preview">(.*?)</}sg
  ) {
	#print "url:$1, title:$2, date:$3, desc:$4\n";
	rss_item("$urlRel$1", $2, $4);
  }

  print "Content-type: text/xml\n\n";
  print rss_as_string(); 

}

