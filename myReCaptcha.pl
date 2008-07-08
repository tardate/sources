#!/usr/bin/perl 

=head1 NAME

myReCaptcha.pl - a simple CGI script to test the reCAPTCHA service http://recaptcha.net

=head1 VERSION

$Id: myReCaptcha.pl,v 1.2 2007/07/28 14:30:48 oracle Exp $

=head1 DESCRIPTION

For more information, see: http://tardate.blogspot.com/2007/07/playing-with-captchas.html

=head1 REQUIRES

CGI
Captcha::reCAPTCHA

=head1 AUTHOR

gallagher.paul@gmail.com

=cut


use strict;

use CGI qw (:standard escapeHTML);
use Captcha::reCAPTCHA;

# the following defines your personal reCAPTCHA public/private keys
#   $main::recaptcha_private and
#   $main::recaptcha_public
require '/home/mywww/cgi-bin/myCaptchaKeys.conf';

my $c = Captcha::reCAPTCHA->new;

my $title = 'reCAPTCHA Test Page';
my $webMaster = $ENV{'SERVER_ADMIN'};

my $challenge = param('recaptcha_challenge_field');
my $response = param('recaptcha_response_field');

sendCaptchaPage();

1;


# send reCaptcha page
sub sendCaptchaPage {
  my $style=<<END;
  BODY {
    background-color: #FFF0BD;
  }
  P {
    font-size: 10pt;
    font-family: sans-serif;
    color: black;
  }
END

  print header();
  print start_html( -title=>$title,
                    -author=>$webMaster,
                    -style=>$style );

  print p( 'This is a sample script using the ' .
           a({-href=>'http://recaptcha.net/'}, 'reCAPTCHA') . 
           ' service to tell if you are a human or not.' .
           ' The neat thing is that each time you use it, you are also helping to digitize public domain archives!' );
  print p( 'See ' .
           a({-href=>'http://tardate.blogspot.com/2007/07/playing-with-captchas.html'}, 'here') .
           ' for more information about this sample.' );



  if ($challenge) {
    my $result = $c->check_answer(
        $main::recaptcha_private, $ENV{'REMOTE_ADDR'},
        $challenge, $response
    );

    if ( $result->{is_valid} ) {
        print p( 'That\'s correct. Try another?' );
    }
    else {
        # Error
        print p( 'Hmm .. are you human? [' . $result->{error} . ']' );
    }
  }


  print start_form(-method=>'POST',-action=>'');

  print $c->get_html( $main::recaptcha_public );

  print submit('Submit','submit');

  print endform();

  print end_html();
}



