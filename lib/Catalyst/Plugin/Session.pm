#!/usr/bin/perl

package Catalyst::Plugin::Session;
use base qw/Class::Accessor::Fast/;

use strict;
use warnings;

use NEXT;
use Catalyst::Exception ();
use Digest ();
use overload ();
use List::Util ();

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

	unless ( $c->isa("Catalyst::Plugin::Session::State") && $c->isa("Catalyst::Plugin::Session::Store") ) {
		my $err = (
			"The Session plugin requires both Session::State " .
			"and Session::Store plugins to be used as well."
		);

		$c->log->fatal($err);
		Catalyst::Exception->throw($err);
	}
}

sub setup_session {
	my $c = shift;

	my $cfg = ($c->config->{session} ||= {});

	%$cfg = (
		expires        => 7200,
		verify_address => 1,
		%$cfg,
	);

	$c->NEXT::setup_session();
}

sub finalize {
	my $c = shift;

	if ($c->{session}) {
		# all sessions are extended at the end of the request
		my $now = time;
		@{ $c->{session} }{qw/__updated __expires/} = ($now, $c->config->{session}{expires} + $now);
		$c->store_session_data( $c->sessionid, $c->{session} );
	}

	$c->NEXT::finalize(@_);
}

sub prepare_action {
    my $c = shift;


	my $ret = $c->NEXT::prepare_action;
    
	my $sid = $c->sessionid || return;

    $c->log->debug(qq/Found session "$sid"/) if $c->debug;

	my $s = $c->{session} ||= $c->get_session_data($sid);
	if ( !$s or $s->{__expires} < time ) {
		# session expired
		$c->log->debug("Deleting session $sid (expired)") if $c->debug;
		$c->delete_session("session expired");
		return $ret;
	}

	if ( $c->config->{session}{verify_address}
	  && $c->{session}{__address}
	  && $c->{session}{__address} ne $c->request->address
	) {
		$c->log->warn(
			"Deleting session $sid due to address mismatch (".
			$c->{session}{__address} . " != " . $c->request->address . ")",
		);
		$c->delete_session("address mismatch");
		return $ret;
	}
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

		($c->config->{session}{verify_address}
			? (__address => $c->request->address)
			: ()
		),
	};
}




# refactor into Catalyst::Plugin::Session::ID::Weak ?

sub generate_session_id {
    my $c = shift;

    my $digest = $c->_find_digest();
    $digest->add( $c->session_hash_seed() );
    return $digest->hexdigest;
}

my $counter;
sub session_hash_seed {
	my $c = shift;

    return join("",
		++$counter,
		time,
        rand,
        $$,
		{},
		overload::StrVal($c),
    );
}

my $usable;
sub _find_digest () {
	unless ($usable) {
		$usable = List::Util::first(sub { eval { Digest->new($_) } }, qw/SHA-1 MD5 SHA-256/)
			or Catalyst::Exception->throw(
				"Could not find a suitable Digest module. Please install " .
				"Digest::SHA1, Digest::SHA, or Digest::MD5"
			);
	}

    return Digest->new($usable);
}


__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session - Generic Session plugin - ties together server side
storage and client side tickets required to maintain session data.

=head1 SYNOPSIS

    use Catalyst qw/Session Session::Store::FastMmap Session::State::Cookie/;

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

=back

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

=cut


