use strict;
use warnings;

use Test::Needs {
  'Catalyst::Plugin::Session::State::Cookie' => '0.03',
  'Test::WWW::Mechanize::Catalyst' => '0.51',
};

use Test::More;

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";

my $ua = Test::WWW::Mechanize::Catalyst->new( { agent => 'Initial user_agent'} );
$ua->get_ok( "http://localhost/user_agent", "get initial user_agent" );
$ua->content_contains( "UA=Initial user_agent", "test initial user_agent" );

$ua->get_ok( "http://localhost/page", "initial get main page" );
$ua->content_contains( "please login", "ua not logged in" );

$ua->get_ok( "http://localhost/login", "log ua in" );
$ua->content_contains( "logged in", "ua logged in" );

$ua->get_ok( "http://localhost/page", "get main page" );
$ua->content_contains( "you are logged in", "ua logged in" );

$ua->agent('Changed user_agent');
$ua->get_ok( "http://localhost/user_agent", "get changed user_agent" );
$ua->content_contains( "UA=Changed user_agent", "test changed user_agent" );

$ua->get_ok( "http://localhost/page", "test deleted session" );
$ua->content_contains( "please login", "ua not logged in" );

done_testing;
