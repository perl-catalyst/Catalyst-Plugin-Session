use strict;
use warnings;

use Test::Needs {
  'Catalyst::Plugin::Session::State::Cookie' => '0.03',
  'Test::WWW::Mechanize::Catalyst' => '0.51',
};

use Test::More;

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";

my $ua = Test::WWW::Mechanize::Catalyst->new;

$ua->get_ok("http://localhost/accessor_test", "Set session vars okay");

$ua->content_contains("two: 2", "k/v list setter works okay");

$ua->content_contains("four: 4", "hashref setter works okay");

$ua->content_contains("five: 5", "direct access works okay");

done_testing;
