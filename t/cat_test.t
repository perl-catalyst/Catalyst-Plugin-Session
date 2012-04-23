#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

use Catalyst::Test 'SessionTestApp';
my ($res, $c);

($res, $c) = ctx_request(POST 'http://localhost/login', [username => 'bob', password => 's00p3r', remember => 1]);
is($res->code, 200, 'succeeded');
my $cookie = $res->header('Set-Cookie');
ok($cookie, 'Have a cookie');

# this checks that cookie persists across a redirect
($res, $c) = ctx_request(GET 'http://localhost/logout_persist', Cookie => $cookie);
is($res->code, 302, '/logout with cookie redirects');
is($res->header('Location'), 'http://localhost/', 'Redirect to / after logout');
ok($res->header('Set-Cookie'), 'Cookie is reset by /logout');

done_testing;
