#!/usr/bin/perl

package SessionTestApp;
use Catalyst (    #
    'SessionHP',                  #
    'Session::Store::Dummy',    #
    'SessionHP::State::Cookie'
);

use strict;
use warnings;

my $max_lifetime = 6;
my $min_lifetime = 3;

__PACKAGE__->config(
    session => {
        max_lifetime => $max_lifetime,
        min_lifetime => $min_lifetime,
    }
);

sub login : Global {
    my ( $self, $c ) = @_;
    $c->session->{logged_in} = 1;
    $c->res->output("logged in");
}

sub logout : Global {
    my ( $self, $c ) = @_;
    $c->res->output(
        "logged out after " . $c->session->{counter} . " requests" );
    $c->delete_session("logout");
}

sub page : Global {
    my ( $self, $c ) = @_;
    if ( $c->session->{logged_in} ) {
        $c->res->output(
            "you are logged in, session expires at " . $c->session_expires );
        $c->session->{counter}++;
    } else {
        $c->res->output("please login");
    }
}

# This action inspects the session which will cause it to be auto_vivified into
# a hash. However we should not create a session because of this.
sub inspect_session : Global {
    my ( $self, $c ) = @_;

    my $logged_in = $c->session->{logged_in};
    $logged_in = 'undef' if !defined $logged_in;

    $c->res->output("value of logged_in is '$logged_in'");
}

__PACKAGE__->setup;

__PACKAGE__;

