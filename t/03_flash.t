#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 12;
use Test::MockObject::Extends;
use Test::Exception;
use Test::Deep;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::SessionHP" ) }

my $c = Test::MockObject::Extends->new($m);

my $flash = {};
$c->mock(
    get_session_data => sub {
        my ( $c, $key ) = @_;
        return $key =~ /expire/ ? time() + 1000 : $flash;
    },
);
$c->mock( "debug"               => sub {0} );
$c->mock( "store_session_data"  => sub { $flash = $_[2] } );
$c->mock( "delete_session_data" => sub { $flash = {} } );
$c->set_always( _session_id => "deadbeef" );
$c->set_always(
    config => { session => { max_lifetime => 1000, min_lifetime => 500 } } );
$c->set_always( stash => {} );

# check that start state is as expected
is_deeply( $c->session, {}, "nothing in session" );
is_deeply( $c->flash,   {}, "nothing in flash" );

# set a value in the flash and check it gets to the flash
pass "--- add one value to the flash ---";
$c->flash->{foo} = "moose";
is_deeply( $c->flash, { foo => "moose" }, "one key in flash" );
$c->finalize_headers;


cmp_deeply(
    $c->session,
    {   __updated => re('^\d+$'),
        __created => re('^\d+$'),
        __flash   => { foo => "moose" },
    },
    "session  has __flash with flash data"
);

pass "--- add second value to flash ---";
$c->flash->{bar} = "gorch";
is_deeply(
    $c->flash,
    { foo => "moose", bar => "gorch" },
    "two keys in flash"
);

$c->finalize_headers;

is_deeply( $c->flash, { bar => "gorch" }, "one key in flash" );

$c->finalize_headers;

$c->flash->{test} = 'clear_flash';

$c->finalize_headers;

$c->clear_flash();

is_deeply( $c->flash, {}, "nothing in flash after clear_flash" );

$c->finalize_headers;

is_deeply( $c->flash, {},
    "nothing in flash after finalize after clear_flash" );

cmp_deeply(
    $c->session,
    { __updated => re('^\d+$'), __created => re('^\d+$'), },
    "session has empty __flash after clear_flash + finalize"
);

$c->flash->{bar} = "gorch";
