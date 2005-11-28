#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 25;
use Test::MockObject;
use Test::Deep;
use Test::Exception;

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Session" ) }

my %config;
my $log      = Test::MockObject->new;
my $req      = Test::MockObject->new;
my @mock_isa = ();
my %session;

$log->set_true(qw/fatal warn error/);

$req->set_always( address => "127.0.0.1" );

{

    package MockCxt;
    use base $m;
    sub new { bless {}, $_[0] }
    sub config  { \%config }
    sub log     { $log }
    sub request { $req }
    sub debug   { 0 }
    sub isa     { 1 }          # subvert the plugin tests, we're faking them
    sub get_session_data    { \%session }
    sub store_session_data  { }
    sub delete_session_data { }
}

{
    my $c = MockCxt->new;
    $c->setup;

    $c->prepare_action;
    ok( !$c->_session, "without a session ID prepare doesn't load a session" );
}

{
    %config = ( session => { expires => 100 } );

    %session = (
        __expires => time() + 1000,
        __created => time(),
        __updated => time(),
        __address => "127.0.0.1",
    );

    my $c = MockCxt->new;
    $c->setup;

    $c->sessionid("decafbad");
    $c->prepare_action;

    ok( $c->_session, 'session "restored" with session id' );
}

{
    %session = (
        __expires => time() - 100,    # a while ago
        __created => time() - 1000,
        __udpated => time() - 1000,
        __address => "127.0.0.1",
    );

    my $c = MockCxt->new;
    $c->setup;

    $c->sessionid("decafbad");
    $c->prepare_action;

    ok( !$c->_session, "expired sessions are deleted" );
    like( $c->session_delete_reason, qr/expire/i, "with appropriate reason" );
    ok( !$c->sessionid, "sessionid is also cleared" );
}

{
    %session = (
        __expires => time() + 1000,
        __created => time(),
        __updated => time(),
        __address => "unlocalhost",
    );

    my $c = MockCxt->new;
    $c->setup;

    $c->sessionid("decafbad");
    $c->prepare_action;

    ok( !$c->_session, "hijacked sessions are deleted" );
    like( $c->session_delete_reason, qr/mismatch/, "with appropriate reason" );
    ok( !$c->sessionid, "sessionid is also cleared" );
}

{
    %session = (
        __expires => time() + 1000,
        __created => time(),
        __updated => time(),
        __address => "unlocalhost",
    );

    $config{session}{verify_address} = 0;

    my $c = MockCxt->new;
    $c->setup;

    $c->sessionid("decafbad");
    $c->prepare_action;

    ok( $c->_session, "address mismatch is OK if verify_address is disabled" );
}

{
    %session = ();
    %config  = ();

    my $now = time;

    my $c = MockCxt->new;
    $c->setup;
    $c->prepare_action;

    ok( $c->session,   "creating a session works" );
    ok( $c->sessionid, "session id generated" );

    cmp_ok( $c->session->{__created}, ">=", $now, "__created time is logical" );
    cmp_ok( $c->session->{__updated}, ">=", $now, "__updated time is logical" );
    cmp_ok(
        $c->session->{__expires},
        ">=",
        ( $now + $config{session}{expires} ),
        "__expires time is logical"
    );
    is( $c->session->{__address},
        $c->request->address, "address is also correct" );

    cmp_deeply(
        [ keys %{ $c->_session } ],
        bag(qw/__expires __created __updated __address/),
        "initial keys in session are all there",
    );
}

{
    %session = (
        __expires => time() + 1000,
        __created => time(),
        __updated => time(),
        __address => "127.0.0.1",
    );

    $config{session}{expires} = 2000;

    my $c = MockCxt->new;
    $c->setup;

    my $now = time();

    $c->sessionid("decafbad");
    $c->prepare_action;
    $c->finalize;

    ok( $c->_session,
        "session is still alive after 1/2 expired and finalized" );

    cmp_ok(
        $c->session->{__expires},
        ">=",
        $now + 2000,
        "session expires time extended"
    );
}

{
    my $c = MockCxt->new;
    $c->setup;

	dies_ok {
		$c->sessionid("user:foo");
	} "can't set invalid sessionid string";
}

{
    %session = (
        %session,
        __expire_keys => {
            foo => time - 1000,
            bar => time + 1000,
        },
        foo => 1,
        bar => 2,
        gorch => 3,
    );

    my $c = MockCxt->new;
    $c->setup;

    $c->sessionid("decafbad");
    $c->prepare_action;
    $c->finalize;

    ok( !$c->session->{foo}, "foo was deleted, expired");
    ok( $c->session->{bar}, "bar not deleted - still valid");
    ok( $c->session->{gorch}, "gorch not deleted - no expiry");

    is_deeply( [ sort keys %{ $c->session->{__expire_keys} } ], [qw/bar/], "expiry entry only for bar");

    $c->session_expire_key( gorch => 10 );

    is_deeply( [ sort keys %{ $c->session->{__expire_keys} } ], [qw/bar gorch/], "expiry entries for bar and gorch");
}
