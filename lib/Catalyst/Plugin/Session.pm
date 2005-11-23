#!/usr/bin/perl

package Catalyst::Plugin::Session;
use base qw/Class::Accessor::Fast/;

use strict;
use warnings;

use NEXT;
use Catalyst::Exception ();
use Digest              ();
use overload            ();

our $VERSION = "0.02";

BEGIN {
    __PACKAGE__->mk_accessors(qw/sessionid session_delete_reason/);
}

sub setup {
    my $c = shift;

    $c->NEXT::setup(@_);

    $c->check_session_plugin_requirements;
    $c->setup_session;

    return $c;
}

sub check_session_plugin_requirements {
    my $c = shift;

    unless ( $c->isa("Catalyst::Plugin::Session::State")
        && $c->isa("Catalyst::Plugin::Session::Store") )
    {
        my $err =
          (     "The Session plugin requires both Session::State "
              . "and Session::Store plugins to be used as well." );

        $c->log->fatal($err);
        Catalyst::Exception->throw($err);
    }
}

sub setup_session {
    my $c = shift;

    my $cfg = ( $c->config->{session} ||= {} );

    %$cfg = (
        expires        => 7200,
        verify_address => 1,
        %$cfg,
    );

    $c->NEXT::setup_session();
}

sub finalize {
    my $c = shift;

    if ( $c->{session} ) {

        # all sessions are extended at the end of the request
        my $now = time;
        @{ $c->{session} }{qw/__updated __expires/} =
          ( $now, $c->config->{session}{expires} + $now );
        $c->store_session_data( $c->sessionid, $c->{session} );
    }

    $c->NEXT::finalize(@_);
}

sub prepare_action {
    my $c = shift;

    if ( my $sid = $c->sessionid ) {
        my $s = $c->{session} ||= $c->get_session_data($sid);
        if ( !$s or $s->{__expires} < time ) {

            # session expired
            $c->log->debug("Deleting session $sid (expired)") if $c->debug;
            $c->delete_session("session expired");
        }
        elsif ($c->config->{session}{verify_address}
            && $c->{session}{__address}
            && $c->{session}{__address} ne $c->request->address )
        {
            $c->log->warn(
                    "Deleting session $sid due to address mismatch ("
                  . $c->{session}{__address} . " != "
                  . $c->request->address . ")",
            );
            $c->delete_session("address mismatch");
        }
        else {
            $c->log->debug(qq/Restored session "$sid"/) if $c->debug;
        }
    }

    $c->NEXT::prepare_action(@_);
}

sub delete_session {
    my ( $c, $msg ) = @_;

    # delete the session data
    my $sid = $c->sessionid;
    $c->delete_session_data($sid);

    # reset the values in the context object
    $c->{session} = undef;
    $c->sessionid(undef);
    $c->session_delete_reason($msg);
}

sub session {
    my $c = shift;

    return $c->{session} if $c->{session};

    my $sid = $c->generate_session_id;
    $c->sessionid($sid);

    $c->log->debug(qq/Created session "$sid"/) if $c->debug;

    return $c->initialize_session_data;
}

sub initialize_session_data {
    my $c = shift;

    my $now = time;

    return $c->{session} = {
        __created => $now,
        __updated => $now,
        __expires => $now + $c->config->{session}{expires},

        (
            $c->config->{session}{verify_address}
            ? ( __address => $c->request->address )
            : ()
        ),
    };
}

sub generate_session_id {
    my $c = shift;

    my $digest = $c->_find_digest();
    $digest->add( $c->session_hash_seed() );
    return $digest->hexdigest;
}

my $counter;

sub session_hash_seed {
    my $c = shift;

    return join( "", ++$counter, time, rand, $$, {}, overload::StrVal($c), );
}

my $usable;

sub _find_digest () {
    unless ($usable) {
        foreach my $alg (qw/SHA-1 MD5 SHA-256/) {
            eval {
                my $obj = Digest->new($alg);
                $usable = $alg;
                return $obj;
            };
        }
        $usable
          or Catalyst::Exception->throw(
                "Could not find a suitable Digest module. Please install "
              . "Digest::SHA1, Digest::SHA, or Digest::MD5" );
    }

    return Digest->new($usable);
}

sub dump_these {
    my $c = shift;

    (
        $c->NEXT::dump_these(),

        $c->sessionid
        ? ( [ "Session ID" => $c->sessionid ], [ Session => $c->session ], )
        : ()
    );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session - Generic Session plugin - ties together server side
storage and client side state required to maintain session data.

=head1 SYNOPSIS

    # To get sessions to "just work", all you need to do is use these plugins:

    use Catalyst qw/
      Session
      Session::Store::FastMmap
      Session::State::Cookie
      /;

	# you can replace Store::FastMmap with Store::File - both have sensible
	# default configurations (see their docs for details)

	# more complicated backends are available for other scenarios (DBI storage,
	# etc)


    # after you've loaded the plugins you can save session data
    # For example, if you are writing a shopping cart, it could be implemented
    # like this:

    sub add_item : Local {
        my ( $self, $c ) = @_;

        my $item_id = $c->req->param("item");

        # $c->session is a hash ref, a bit like $c->stash
        # the difference is that it' preserved across requests

        push @{ $c->session->{items} }, $item_id;

        $c->forward("MyView");
    }

    sub display_items : Local {
        my ( $self, $c ) = @_;

        # values in $c->session are restored
        $c->stash->{items_to_display} =
          [ map { MyModel->retrieve($_) } @{ $c->session->{items} } ];

        $c->forward("MyView");
    }

=head1 DESCRIPTION

The Session plugin is the base of two related parts of functionality required
for session management in web applications.

The first part, the State, is getting the browser to repeat back a session key,
so that the web application can identify the client and logically string
several requests together into a session.

The second part, the Store, deals with the actual storage of information about
the client. This data is stored so that the it may be revived for every request
made by the same client.

This plugin links the two pieces together.

=head1 RECCOMENDED BACKENDS

=over 4

=item Session::State::Cookie

The only really sane way to do state is using cookies.

=item Session::Store::File

A portable backend, based on Cache::File.

=item Session::Store::FastMmap

A fast and flexible backend, based on Cache::FastMmap.

=back

=head1 METHODS

=over 4

=item sessionid

An accessor for the session ID value.

=item session

Returns a hash reference that might contain unserialized values from previous
requests in the same session, and whose modified value will be saved for future
requests.

This method will automatically create a new session and session ID if none
exists.

=item session_delete_reason

This accessor contains a string with the reason a session was deleted. Possible
values include:

=over 4

=item *

C<address mismatch>

=item *

C<session expired>

=back

=back

=item INTERNAL METHODS

=over 4

=item setup

This method is extended to also make calls to
C<check_session_plugin_requirements> and C<setup_session>.

=item check_session_plugin_requirements

This method ensures that a State and a Store plugin are also in use by the
application.

=item setup_session

This method populates C<< $c->config->{session} >> with the default values
listed in L</CONFIGURATION>.

=item prepare_action

This methoid is extended, and will restore session data and check it for
validity if a session id is defined. It assumes that the State plugin will
populate the C<sessionid> key beforehand.

=item finalize

This method is extended and will extend the expiry time, as well as persist the
session data if a session exists.

=item delete_session REASON

This method is used to invalidate a session. It takes an optional parameter
which will be saved in C<session_delete_reason> if provided.

=item initialize_session_data

This method will initialize the internal structure of the session, and is
called by the C<session> method if appropriate.

=item generate_session_id

This method will return a string that can be used as a session ID. It is
supposed to be a reasonably random string with enough bits to prevent
collision. It basically takes C<session_hash_seed> and hashes it using SHA-1,
MD5 or SHA-256, depending on the availibility of these modules.

=item session_hash_seed

This method is actually rather internal to generate_session_id, but should be
overridable in case you want to provide more random data.

Currently it returns a concatenated string which contains:

=over 4

=item *

A counter

=item *

The current time

=item *

One value from C<rand>.

=item *

The stringified value of a newly allocated hash reference

=item *

The stringified value of the Catalyst context object

=back

In the hopes that those combined values are entropic enough for most uses. If
this is not the case you can replace C<session_hash_seed> with e.g.

    sub session_hash_seed {
        open my $fh, "<", "/dev/random";
        read $fh, my $bytes, 20;
        close $fh;
        return $bytes;
    }

Or even more directly, replace C<generate_session_id>:

    sub generate_session_id {
        open my $fh, "<", "/dev/random";
        read $fh, my $bytes, 20;
        close $fh;
        return unpack("H*", $bytes);
    }

Also have a look at L<Crypt::Random> and the various openssl bindings - these
modules provide APIs for cryptographically secure random data.

=item dump_these

See L<Catalyst/dump_these> - ammends the session data structure to the list of
dumped objects if session ID is defined.

=back

=head1 USING SESSIONS DURING PREPARE

The earliest point in time at which you may use the session data is after
L<Catalyst::Plugin::Session>'s C<prepare_action> has finished.

State plugins must set $c->session ID before C<prepare_action>, and during
C<prepare_action> L<Catalyst::Plugin::Session> will actually load the data from
the store.

	sub prepare_action {
		my $c = shift;

		# don't touch $c->session yet!

		$c->NEXT::prepare_action( @_ );

		$c->session;  # this is OK
		$c->sessionid; # this is also OK
	}

=head1 CONFIGURATION

    $c->config->{session} = {
        expires => 1234,
    };

All configuation parameters are provided in a hash reference under the
C<session> key in the configuration hash.

=over 4

=item expires

The time-to-live of each session, expressed in seconds. Defaults to 7200 (two
hours).

=item verify_address

When false, C<< $c->request->address >> will be checked at prepare time. If it
is not the same as the address that initiated the session, the session is
deleted.

=back

=head1 SPECIAL KEYS

The hash reference returned by C<< $c->session >> contains several keys which
are automatically set:

=over 4

=item __expires

A timestamp whose value is the last second when the session is still valid. If
a session is restored, and __expires is less than the current time, the session
is deleted.

=item __updated

The last time a session was saved. This is the value of
C<< $c->{session}{__expires} - $c->config->{session}{expires} >>.

=item __created

The time when the session was first created.

=item __address

The value of C<< $c->request->address >> at the time the session was created.
This value is only populated of C<verify_address> is true in the configuration.

=back

=head1 CAVEATS

C<verify_address> could make your site inaccessible to users who are behind
load balanced proxies. Some ISPs may give a different IP to each request by the
same client due to this type of proxying. If addresses are verified these
users' sessions cannot persist.

To let these users access your site you can either disable address verification
as a whole, or provide a checkbox in the login dialog that tells the server
that it's OK for the address of the client to change. When the server sees that
this box is checked it should delete the C<__address> sepcial key from the
session hash when the hash is first created.

=head1 AUTHORS

Andy Grundman
Christian Hansen
Yuval Kogman, C<nothingmuch@woobling.org>
Sebastian Riedel

=head1 COPYRIGHT & LICNESE

	Copyright (c) 2005 the aforementioned authors. All rights
	reserved. This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut


