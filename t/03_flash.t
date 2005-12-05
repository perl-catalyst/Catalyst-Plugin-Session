#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::MockObject::Extends;
use Test::Exception;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Session" ) }

my $c = Test::MockObject::Extends->new( $m );

$c->set_always( get_session_data => { __expires => time+10000, __updated => time } );
$c->set_always( config => { session => { expires => 1000000 } } );

$c->sessionid("deadbeef");

$c->_load_session;

is_deeply( $c->flash, {}, "nothing in flash");

$c->flash->{foo} = "moose";

$c->finalize;
$c->_load_session;

is_deeply( $c->flash, { foo => "moose" }, "one key in flash" );

$c->flash->{bar} = "gorch";

is_deeply( $c->flash, { foo => "moose", bar => "gorch" }, "two keys in flash");

$c->finalize;
$c->_load_session;

is_deeply( $c->flash, { bar => "gorch" }, "one key in flash" );

$c->finalize;
$c->_load_session;

is_deeply( $c->flash, {}, "nothing in flash");
