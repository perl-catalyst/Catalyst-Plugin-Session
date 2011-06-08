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

    plan tests => 12;
}

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";

# Test without delete __address
local $ENV{REMOTE_ADDR} = "192.168.1.1";

my $ua = Test::WWW::Mechanize::Catalyst->new( {} );
$ua->get_ok( "http://localhost/login" );
$ua->content_contains('logged in');

$ua->get_ok( "http://localhost/set_session_variable/logged/in" );
$ua->content_contains('session variable set');


# Change Client 
local $ENV{REMOTE_ADDR} = "192.168.1.2";

$ua->get_ok( "http://localhost/get_session_variable/logged");
$ua->content_contains('VAR_logged=n.a.');

# Inital Client
local $ENV{REMOTE_ADDR} = "192.168.1.1";

$ua->get_ok( "http://localhost/login_without_address" );
$ua->content_contains('logged in (without address)');

$ua->get_ok( "http://localhost/set_session_variable/logged/in" );
$ua->content_contains('session variable set');

# Change Client 
local $ENV{REMOTE_ADDR} = "192.168.1.2";

$ua->get_ok( "http://localhost/get_session_variable/logged" );
$ua->content_contains('VAR_logged=in');



