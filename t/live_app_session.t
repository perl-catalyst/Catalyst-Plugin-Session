#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;
local $Data::Dumper::Sortkeys = 1;

BEGIN {
    eval {
        require Catalyst::Plugin::Session::State::Cookie;
        Catalyst::Plugin::Session::State::Cookie->VERSION(0.03);
        }
        or plan skip_all =>
        "Catalyst::Plugin::Session::State::Cookie 0.03 or higher is required for this test";

    eval { require Test::WWW::Mechanize::Catalyst }
        or plan skip_all =>
        "Test::WWW::Mechanize::Catalyst is required for this test";

    plan tests => 42;
}

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";

my $ua1 = Test::WWW::Mechanize::Catalyst->new;
my $ua2 = Test::WWW::Mechanize::Catalyst->new;

$_->get_ok( "http://localhost/page", "initial get" ) for $ua1, $ua2;

$ua1->content_contains( "please login", "ua1 not logged in" );
$ua2->content_contains( "please login", "ua2 not logged in" );

$_->get_ok( "http://localhost/inspect_session", "check for value in session" )
    for $ua1, $ua2;

$ua1->content_contains( "value of logged_in is 'undef'",
    "check ua1 'logged_in' val" );
$ua2->content_contains( "value of logged_in is 'undef'",
    "check ua2 'logged_in' val" );

$_->get_ok( "http://localhost/page", "initial get" ) for $ua1, $ua2;

$ua1->content_contains( "please login", "ua1 not logged in" );
$ua2->content_contains( "please login", "ua2 not logged in" );

$ua1->get_ok( "http://localhost/login", "log ua1 in" );
$ua1->content_contains( "logged in", "ua1 logged in" );

$_->get_ok( "http://localhost/page", "get main page" ) for $ua1, $ua2;

$ua1->content_contains( "you are logged in", "ua1 logged in" );
$ua2->content_contains( "please login",      "ua2 not logged in" );

$ua2->get_ok( "http://localhost/login", "get main page" );
$ua2->content_contains( "logged in", "log ua2 in" );

$_->get_ok( "http://localhost/page", "get main page" ) for $ua1, $ua2;

$ua1->content_contains( "you are logged in", "ua1 logged in" );
$ua2->content_contains( "you are logged in", "ua2 logged in" );

$_->get_ok( "http://localhost/page", "get main page" ) for $ua1, $ua2;
$ua1->content_contains( "you are logged in", "ua1 logged in" );
$ua2->content_contains( "you are logged in", "ua2 logged in" );

$ua2->get_ok( "http://localhost/logout", "log ua2 out" );
$ua2->content_like( qr/logged out/, "ua2 logged out" );
$ua2->content_like( qr/after 2 request/,
    "ua2 made 2 requests for page in the session" );

$_->get_ok( "http://localhost/page", "get main page" ) for $ua1, $ua2;

$ua1->content_contains( "you are logged in", "ua1 logged in" );
$ua2->content_contains( "please login",      "ua2 not logged in" );

$ua1->get_ok( "http://localhost/logout", "log ua1 out" );
$ua1->content_like( qr/logged out/, "ua1 logged out" );
$ua1->content_like( qr/after 4 requests/,
    "ua1 made 4 request for page in the session" );

$_->get_ok( "http://localhost/page", "get main page" ) for $ua1, $ua2;

$ua1->content_contains( "please login", "ua1 not logged in" );
$ua2->content_contains( "please login", "ua2 not logged in" );

