#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require Catalyst::Plugin::Session::State::Cookie; Catalyst::Plugin::Session::State::Cookie->VERSION(0.03) }
      or plan skip_all =>
      "Catalyst::Plugin::Session::State::Cookie 0.03 or higher is required for this test";

    eval {
        require Test::WWW::Mechanize::Catalyst;
        Test::WWW::Mechanize::Catalyst->VERSION(0.51);
    }
    or plan skip_all =>
        'Test::WWW::Mechanize::Catalyst >= 0.51 is required for this test';
}

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";

my $ua = Test::WWW::Mechanize::Catalyst->new;

my $res = $ua->get( "http://localhost/get_expires" );
ok($res->is_success, "get expires");

my $expiry = $res->decoded_content;

sleep(1);

$res = $ua->get( "http://localhost/get_expires" );
ok($res->is_success, "get expires");

is($res->decoded_content, $expiry, "expiration not updated");

sleep(10);

$res = $ua->get( "http://localhost/get_expires" );
ok($res->is_success, "get expires");

isnt($res->decoded_content, $expiry, "expiration updated");

done_testing;
