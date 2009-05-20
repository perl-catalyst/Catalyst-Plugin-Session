#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::MockObject;
use Test::MockObject::Extends;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::SessionHP::State::Cookie" ) }

my $cookie = Test::MockObject->new;
$cookie->set_always( value => "the session id" );

my $req = Test::MockObject->new;
my %req_cookies;
$req->set_always( cookies => \%req_cookies );

my $res = Test::MockObject->new;
my %res_cookies;
$res->set_always( cookies => \%res_cookies );

my $cxt =
  Test::MockObject::Extends->new("Catalyst::Plugin::SessionHP::State::Cookie");

$cxt->set_always( config   => {} );
$cxt->set_always( request  => $req );
$cxt->set_always( response => $res );
$cxt->set_always( session  => { } );
$cxt->set_always( session_expires => 123 );
$cxt->set_false("debug");
my $session_id;
$cxt->mock( session_id => sub { shift; $session_id = shift if @_; $session_id } );

can_ok( $m, "setup_session" );

$cxt->setup_session;

like( $cxt->config->{session}{cookie_name},
    qr/_session$/, "default cookie name is set" );

$cxt->config->{session}{cookie_name} = "session";

can_ok( $m, "get_sesson_id_from_state" );

ok( !$cxt->get_sesson_id_from_state, "no session id yet");

$cxt->clear;

%req_cookies = ( session => $cookie );

is( $cxt->get_sesson_id_from_state, "the session id", "session ID was restored from cookie" );

$cxt->clear;
$res->clear;


# can_ok( $m, "cookie_is_rejecting" );
# %req_cookies = ( path => '/foo' );
# $req->set_always( path => '' );
# ok( $cxt->cookie_is_rejecting(\%req_cookies), "cookie is rejecting" );
# $req->set_always( path => 'foo/bar' );
# ok( !$cxt->cookie_is_rejecting(\%req_cookies), "cookie is not rejecting" );
