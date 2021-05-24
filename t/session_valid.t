use strict;
use warnings;

use Test::Needs {
  'Catalyst::Plugin::Session::State::Cookie' => '0.03',
  'Test::WWW::Mechanize::Catalyst' => '0.51',
};

use Test::More;

use lib "t/lib";


use Test::WWW::Mechanize::Catalyst "SessionValid";

my $ua = Test::WWW::Mechanize::Catalyst->new;

$ua->get_ok( "http://localhost/", "initial get" );
$ua->content_contains( "value set", "page contains expected value" );

sleep 2;

$ua->get_ok( "http://localhost/", "grab the page again, after the session has expired" );
$ua->content_contains( "value set", "page contains expected value" );

done_testing;
