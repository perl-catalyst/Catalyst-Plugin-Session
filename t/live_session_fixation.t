#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    eval { require Catalyst::Plugin::Session::State::Cookie; Catalyst::Plugin::Session::State::Cookie->VERSION(0.03) }
      or plan skip_all =>
      "Catalyst::Plugin::Session::State::Cookie 0.03 or higher is required for this test";

    eval { require Test::WWW::Mechanize::Catalyst }
      or plan skip_all =>
      "Test::WWW::Mechanize::Catalyst is required for this test";

    plan tests => 2;
}

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";

my $injected_cookie = "sessiontestapp_session=89c3a019866af6f5a305e10189fbb23df3f4772c";

my $ua1 = Test::WWW::Mechanize::Catalyst->new;
$ua1->add_header('Cookie' => $injected_cookie);

my $res = $ua1->get( "http://localhost/login" );
my $cookie = $res->header('Set-Cookie');

ok $cookie;
isnt $cookie, qr/$injected_cookie/, 'Logging in generates us a new cookie';

