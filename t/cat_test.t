#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# this test was copied from CatalystX::SimpleLogin

BEGIN {
    plan skip_all => "Need Catalyst::Plugin::Session::State::Cookie"
        unless do { local $@; eval { require Catalyst::Plugin::Session::State::Cookie; } };
    plan skip_all => "Need Catalyst::Plugin::Authentication"
        unless do { local $@; eval { require Catalyst::Plugin::Authentication; } };
}

use Catalyst::Test 'SessionTestApp';
my ($res, $c);

($res, $c) = ctx_request(POST 'http://localhost/login', [username => 'bob', password => 's00p3r', remember => 1]);
is($res->code, 200, 'succeeded');
my $cookie = $res->header('Set-Cookie');
ok($cookie, 'Have a cookie');

# check that the cookie has not been reset by the get
($res, $c) = ctx_request(GET 'http://localhost/page', Cookie => $cookie);
like($c->res->body, qr/logged in/, 'Am logged in');
my $new_cookie = $res->header('Set-Cookie');
is( $cookie, $new_cookie, 'cookie is the same' );

# this checks that cookie exists after a logout and redirect
# Catalyst::Plugin::Authentication removes the user session (remove_persisted_user)
($res, $c) = ctx_request(GET 'http://localhost/logout_redirect', Cookie => $cookie);
is($res->code, 302, 'redirected');
is($res->header('Location'), 'http://localhost/from_logout_redirect', 'Redirected after logout_redirect');
ok($res->header('Set-Cookie'), 'Cookie is there after redirect');

done_testing;
