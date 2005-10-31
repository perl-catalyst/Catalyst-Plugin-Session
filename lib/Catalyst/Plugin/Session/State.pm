#!/usr/bin/perl

package Catalyst::Plugin::Session::State;

use strict;
use warnings;

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session::State - Base class for session state
preservation plugins.

=head1 SYNOPSIS

	package Catalyst::Plugin::Session::State::MyBackend;
	use base qw/Catalyst::Plugin::Session::State/;

=head1 DESCRIPTION

This class doesn't actually provide any functionality, but when the
C<Catalyst::Plugin::Session> module sets up it will check to see that
C<< YourApp->isa("Catalyst::Plugin::Session::State") >>.

When you write a session state plugin you should subclass this module this
reason only.

=head1 WRITING STATE PLUGINS

To write a session state plugin you usually need to extend C<finalize> and
C<prepare> (or e.g. C<prepare_action>) to do two things:

=over 4

=item *

Set C<sessionid> (accessor) at B<prepare> time using data in the request

=item *

Modify the response at B<finalize> to include the session ID if C<sessionid> is
defined.

=back

=cut





