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

    plan tests => 9;
}
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Test::WWW::Mechanize::Catalyst "SessionValid";

my $ua = Test::WWW::Mechanize::Catalyst->new;

my $res = $ua->get( "http://localhost/" );
ok $res->is_success, "get with no session id";
my $old_session_cookie = $res->header('Set-Cookie');
ok $old_session_cookie, "has session id";

#inject some HTML into our session id like a hacker would try
my $invalid_sessionid = '<h1>sdasdasdsddfger5343232321sad';
$ua->cookie_jar->set_cookie( 0, 'sessionvalid_session', $invalid_sessionid, '/', 'localhost.local', undef, 1, undef, undef, 1, { HttpOnly => undef } );

$res = $ua->get( "http://localhost/" );
ok $res->is_success, "get with invalid session id";
my $new_session_cookie = $res->header('Set-Cookie');
ok $new_session_cookie, "has session id";
isnt $new_session_cookie, $old_session_cookie, "got new session id";
unlike $new_session_cookie, qr/sessionvalid_session=$invalid_sessionid/, "new sessionid is valid";

$res = $ua->get( "http://localhost/" );
ok $res->is_success, "get with same cookies as last response";
my $newer_session_cookie = $res->header('Set-Cookie');
ok $newer_session_cookie, "has session id";
is $newer_session_cookie, $new_session_cookie, "same session id used";
