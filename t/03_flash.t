#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::MockObject::Extends;
use Test::Exception;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Session" ) }

my $c = Test::MockObject::Extends->new( $m );

$c->set_always( get_session_data => { } );
$c->set_true( "store_session_data" );
$c->set_always( _sessionid => "deadbeef");
$c->set_always( config => { } );
$c->set_always( stash => { } );

$c->_load_flash;

is_deeply( $c->flash, {}, "nothing in flash");

$c->flash->{foo} = "moose";

$c->finalize;
$c->_load_flash;

is_deeply( $c->flash, { foo => "moose" }, "one key in flash" );

$c->flash->{bar} = "gorch";

is_deeply( $c->flash, { foo => "moose", bar => "gorch" }, "two keys in flash");

$c->finalize;
$c->_load_flash;

is_deeply( $c->flash, { bar => "gorch" }, "one key in flash" );

$c->finalize;
$c->_load_flash;

is_deeply( $c->flash, {}, "nothing in flash");

$c->flash->{bar} = "gorch";

$c->config->{session}{flash_to_stash} = 1;

$c->finalize;
$c->prepare_action;

is_deeply( $c->stash, { bar => "gorch" }, "flash copied to stash" );

