#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Data::Dumper;
local $Data::Dumper::Sortkeys = 1;
use Clone;

BEGIN {

    eval { require Test::WWW::Mechanize::Catalyst }
        or plan skip_all =>
        "Test::WWW::Mechanize::Catalyst is required for this test";

    plan tests => 36;
}

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";

my $ua = Test::WWW::Mechanize::Catalyst->new;

# initial request - should not set cookie
$ua->get_ok( "http://localhost/page", "initial get" );
$ua->content_contains( "please login", "ua not logged in" );
is_deeply get_cookie(), undef, "no cookies yet";

# request that checks the session - should not set cookie
$ua->get_ok( "http://localhost/inspect_session",
    "check for value in session" );
$ua->content_contains( "value of logged_in is 'undef'",
    "check ua 'logged_in' val" );
is_deeply get_cookie(), undef, "no cookies yet";

# Login - should create a session
$ua->get_ok( "http://localhost/login", "log ua in" );
$ua->content_contains( "logged in", "ua logged in" );

# check that the session cookie created
my $session_id = get_cookie()->{val};
ok $session_id, "found a session cookie ($session_id)";

# check session loaded from store
$ua->get_ok( "http://localhost/page", "get main page" );
$ua->content_contains( "you are logged in", "ua logged in" );
is get_cookie()->{val}, $session_id, "session id has not changed";

# check that the expires time is updated
{
    my $min_lifetime
        = SessionTestApp->config->{session}{min_lifetime};
    my $max_lifetime
        = SessionTestApp->config->{session}{max_lifetime};

    # do some requests until the expires changes
    my $original_expiry = get_cookie()->{expires};

    for ( 1 .. 10 ) {
        sleep 1;
        $ua->get("http://localhost/inspect_session");
        my $new_expiry = get_cookie()->{expires};
        next if $new_expiry == $original_expiry;
        $original_expiry = $new_expiry;
        last;
    }

    # expiry just updated - check it stays the same
    $ua->get_ok(
        "http://localhost/inspect_session",
        "get page to see expiry not changed"
    );
    is get_cookie()->{expires}, $original_expiry,
        "expiry is still '$original_expiry'";
    is get_cookie()->{val}, $session_id, "session id has not changed";

    # sleep so that we go past the min lifetime
    ok sleep $_, "sleep $_ so expires get extended"
        for $max_lifetime - $min_lifetime + 1;

    # expiry just updated - check it stays the same
    $ua->get_ok(
        "http://localhost/inspect_session",
        "get page to see expiry has changed"
    );
    my $new_expiry = get_cookie()->{expires};
    cmp_ok $new_expiry, '>', $original_expiry,
        "expiry updated to '$new_expiry'";
    is get_cookie()->{val}, $session_id, "session id has not changed";

    # sleep beyond the lifetime and see that the session gets expired
    ok sleep $_, "sleep $_ so session is too old" for $max_lifetime + 2;
    $ua->get_ok(
        "http://localhost/inspect_session",
        "get page to see session expired"
    );
    is get_cookie(), undef, "Cookie has been reset";

}

# check that a session that is not in the db is deleted

my @session_ids_to_test = (
    'a' x 40,                      # valid session id
    'This is not valid @#$%^&',    # bad value
);

foreach my $new_session_id (@session_ids_to_test) {

    pass "--- Testing session_id '$new_session_id' ---";

    $ua->get_ok( "http://localhost/login", "log ua in" );
    $ua->content_contains( "logged in", "ua logged in" );

    my $session_id = get_cookie()->{val};
    ok $session_id, "have session_id '$session_id'";

    # change the value in the cookie to a valid value
    ok set_cookie_val($new_session_id),
        "change cookie value to '$new_session_id'";

    # check that the cookie gets deleted
    $ua->get_ok(
        "http://localhost/inspect_session",
        "get page to see if session is deleted"
    );
    is get_cookie(), undef, "Cookie has been reset";

}

#############################################################################

sub get_cookie {
    my $cookie_jar = $ua->cookie_jar;

    my $cookie_data = undef;

    $cookie_jar->scan(
        sub {
            my ($version, $key,     $val,       $path,
                $domain,  $port,    $path_spec, $secure,
                $expires, $discard, $hash
            ) = @_;

            # warn "cookie key: $key";

            if ( $key eq 'sessiontestapp_session' ) {
                $cookie_data = {
                    val     => $val,
                    expires => $expires,
                };
            }
        }
    );

    return $cookie_data;
}

sub set_cookie_val {
    my $new_val    = shift;
    my $cookie_jar = $ua->cookie_jar;

    $cookie_jar->scan(
        sub {
            my ( $version, $key, $val, $path, $domain ) = @_;

            # warn "cookie key: $key";

            if ( $key eq 'sessiontestapp_session' ) {

                $cookie_jar->set_cookie( $version, $key, $new_val, $path,
                    $domain );

            }
        }
    );

    return 1;
}
