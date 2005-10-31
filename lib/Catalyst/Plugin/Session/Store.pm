#!/usr/bin/perl

package Catalyst::Plugin::Session::Store;

use strict;
use warnings;

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session::Store - Base class for session storage
drivers.

=head1 SYNOPSIS

    package Catalyst::Plugin::Session::Store::MyBackend;
    use base qw/Catalyst::Plugin::Session::Store/;

=head1 DESCRIPTION

This class doesn't actually provide any functionality, but when the
C<Catalyst::Plugin::Session> module sets up it will check to see that
C<< YourApp->isa("Catalyst::Plugin::Session::Store") >>.

When you write a session storage plugin you should subclass this module this
reason only.

=head1 WRITING STORE PLUGINS

All session storage plugins need to adhere to the following interface
specification to work correctly:

=head2 Required Methods

=over 4

=item get_session_data $sid

Retrieve a session from storage, whose ID is the first parameter.

Should return a hash reference.

=item store_session_data $sid, $hashref

Store a session whose ID is the first parameter and data is the second
parameter in storage.

The second parameter is an hash reference, that should normally be serialized
(and later deserialized by C<get_session_data>).

=item delete_session_data $sid

Delete the session whose ID is the first parameter.

=item delete_expired_sessions

This method is not called by any code at present, but may be called in the
future, as part of a catalyst specific maintenance script.

If you are wrapping around a backend which manages it's own auto expiry you can
just give this method an empty body.

=back

=head2 Error handling

All errors should be thrown using L<Catalyst::Exception>. Return values are not
checked at all, and are assumed to be OK.

=head2 Auto-Expirey on the Backend

Storage plugins are encouraged to use C<< $c->config->{session}{expires} >> and
the C<__expires> key in the session data hash reference to auto expire data on
the backend side.

If the backend chooses not to do so, L<Catalyst::Plugin::Session> will detect
expired sessions as they are retrieved and delete them if necessary.

Note that session storages that use this approach may leak disk space, since
nothing will actively delete expired session. The C<delete_expired_sessions>
method is there so that regularly scheduled maintenance scripts can give your
backend the opportunity to clean up.

=cut


