#!/usr/bin/perl -w
=head1 NAME

regexplainr.pl - a CGI script to explain regex (using YAPE::Regex::Explain)

=head1 VERSION

$Id: regexplainr.pl,v 1.9 2008/02/24 12:51:10 paulg Exp $

=head1 DESCRIPTION

For more information, see: http://tardate.blogspot.com/2008/02/explaining-regular-expressions.html

=head1 REQUIRES

CGI
YAPE::Regex
YAPE::Regex::Explain

=head1 AUTHOR

gallagher.paul@gmail.com

=cut


use strict;

use CGI qw (:standard escapeHTML escape);
use YAPE::Regex::Explain; 

my $regex = param("regex");

sendRegexPage( $regex );

1;



# send configuration page
sub sendRegexPage {
  my $regex = shift;
  my $webMaster = $ENV{'SERVER_ADMIN'};
  my $style=<<END;
  BODY {
    background-color: white;
    font-size: 10pt;
    font-family: sans-serif;
    color: black;
  }
  h1 {
    font-size: 18pt;
    font-family: sans-serif;
  }
  h2 {
    font-size: 14pt;
    font-family: sans-serif;
  }
  blockquote {
    font-family:courier new;
    font-size:85%;
    background: Gainsboro;
    border: 1px solid LightSlateGray;
    padding: 5px 5px;
    white-space: pre;
  }
END

  print header();
  print start_html(-title=>'RegExplainr',
                            -author=>$webMaster,
                            -style=>$style );

  print h1( 'RegExplainr!' );
  print p( 'Helps to explain Regular Expressions. Discussion of this script is on my ' .
           a({-href=>'http://tardate.blogspot.com/2008/02/explaining-regular-expressions.html'}, 'tardate') . ' blog.' );
  print start_form(-method=>'POST',-action=>url());

  print p( 'Regular Expression: ' . textfield(-name=>'regex', -size=>80) );

  print submit('submit','Explain!');

  print endform();

  if ($regex) {
  	print p( i( a({-href=>url() . '?regex=' . escape($regex) }, 'Permalink to this regexplanation')));
    my $exp = YAPE::Regex::Explain->new($regex)->explain;
    print blockquote( escapeHTML( $exp ) );
  }

  print h2( 'Some Regular Expression Resources..' );

  print ul(
          li([
               a({-href=>'http://en.wikipedia.org/wiki/Regular_expression'}, 'Wikipedia on Regular expressions'),
               a({-href=>'http://www.regular-expressions.info/'}, 'Regular-Expressions.info'),
               a({-href=>'http://del.icio.us/popular/regex'}, 'regex @ del.icio.us'),
               a({-href=>'http://www.amazon.com/gp/product/0596528124?ie=UTF8&tag=itsaprli-20&linkCode=as2&camp=1789&creative=9325&creativeASIN=0596528124'}, 'Mastering Regular Expressions (O\'Reilly)')
             ])
          );

  print end_html();
}
