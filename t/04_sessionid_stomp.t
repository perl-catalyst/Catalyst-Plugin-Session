#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Test::MockObject::Extends;
use Test::Exception;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Session" ) }

my $c = Test::MockObject::Extends->new($m);

my $flash = {};
$c->mock(
    get_session_data => sub {
        my ( $c, $key ) = @_;
        return $key =~ /expire/ ? time() + 1000 : $flash;
    }
);
$c->set_true("store_session_data");
#$c->set_always( _sessionid => "deadbeef" );
$c->set_always( config     => { session => { expires => 1000 } } );
$c->set_always( stash      => {} );

$c->sessionid('deadbeef');
is_deeply($c->sessionid(), 'deadbeef', "Session not set properly.");

$c->sessionid('deadbeef2');

is_deeply($c->sessionid(), 'deadbeef', "Session was stomped!.");
