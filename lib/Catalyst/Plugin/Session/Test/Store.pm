#!/usr/bin/perl

package Catalyst::Plugin::Session::Test::Store;

use strict;
use warnings;

use Test::More tests => 19;
use File::Temp;
use File::Spec;

use Catalyst ();

sub import {
    shift;
    my %args = @_;

    my $backend = $args{backend};
    my $cfg     = $args{config};

    my $p = "Session::Store::$backend";
    use_ok( my $m = "Catalyst::Plugin::$p" );

    isa_ok( bless( {}, $m ), "Catalyst::Plugin::Session::Store" );

    our $restored_session_id;

    {

        package SessionStoreTest;
        use Catalyst qw/Session Session::State/;
        push our (@ISA), $m;

        our $VERSION = "0.01";

        use Test::More;

        sub prepare_cookies {
            my $c = shift;
            $c->sessionid($restored_session_id) if defined $restored_session_id;
            $c->NEXT::prepare_cookies(@_);
        }

        sub create_session : Global {
            my ( $self, $c ) = @_;
            ok( !$c->sessionid, "no session id yet" );
            ok( $c->session,    "session created" );
            ok( $c->sessionid,  "with a session id" );

            $restored_session_id = $c->sessionid;

            $c->session->{magic} = "møøse";
        }

        sub recover_session : Global {
            my ( $self, $c ) = @_;
            ok( $c->sessionid, "session id exists" );
            is( $c->sessionid, $restored_session_id,
                "and is the one we saved in the last action" );
            ok( $c->session, "a session exists" );
            is( $c->session->{magic},
                "møøse",
                "and it contains what we put in on the last attempt" );
            $c->delete_session("user logout");
            $restored_session_id = undef;
        }

        sub after_session : Global {
            my ( $self, $c ) = @_;
            ok( !$c->sessionid,             "no session id" );
            ok( !$c->session->{magic},      "session data not restored" );
            ok( !$c->session_delete_reason, "no reason for deletion" );
        }

        @{ __PACKAGE__->config->{session} }{ keys %$cfg } = values %$cfg;

        __PACKAGE__->setup;
    }

    {

        package SessionStoreTest2;
        use Catalyst qw/Session Session::State/;
        push our (@ISA), $m;

        our $VERSION = "123";

        use Test::More;

        sub prepare_cookies {
            my $c = shift;
            $c->sessionid($restored_session_id) if defined $restored_session_id;
            $c->NEXT::prepare_cookies(@_);
        }

        sub create_session : Global {
            my ( $self, $c ) = @_;

            $c->session->{magic} = "møøse";

            $restored_session_id = $c->sessionid;
        }

        sub recover_session : Global {
            my ( $self, $c ) = @_;

            ok( !$c->sessionid, "no session id" );

            is(
                $c->session_delete_reason,
                "session expired",
                "reason is that the session expired"
            );

            ok( !$c->session->{magic}, "no saved data" );
        }

        __PACKAGE__->config->{session}{expires} = 0;

        @{ __PACKAGE__->config->{session} }{ keys %$cfg } = values %$cfg;

        __PACKAGE__->setup;
    }

    use Test::More;

    can_ok( $m, "get_session_data" );
    can_ok( $m, "store_session_data" );
    can_ok( $m, "delete_session_data" );
    can_ok( $m, "delete_expired_sessions" );

    {

        package t1;
        use Catalyst::Test "SessionStoreTest";

        # idiotic void context warning workaround
        
        my $x = get("/create_session");
        $x = get("/recover_session");
        $x = get("/after_session");
    }

    {

        package t2;
        use Catalyst::Test "SessionStoreTest2";

        my $x = get("/create_session");
        sleep 1;    # let the session expire
        $x = get("/recover_session");
    }
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session::Test::Store - Reusable sanity for session storage
engines.

=head1 SYNOPSIS

    #!/usr/bin/perl

    use Catalyst::Plugin::Session::Test::Store (
        backend => "FastMmap",
        config => {
            storage => "/tmp/foo",
        },
    );

=head1 DESCRIPTION

=cut


