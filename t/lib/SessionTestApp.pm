#!/usr/bin/perl

package SessionTestApp;
use Catalyst qw/Session Session::Store::Dummy Session::State::Cookie/;

use strict;
use warnings;

__PACKAGE__->config->{session} = {
    # needed for live_verify_user_agent.t; should be harmless for other tests 
    verify_user_agent => 1,  
};

sub login : Global {
    my ( $self, $c ) = @_;
    $c->session;
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
    if ( $c->session_is_valid ) {
        $c->res->output("you are logged in, session expires at " . $c->session_expires);
        $c->session->{counter}++;
    }
    else {
        $c->res->output("please login");
    }
}

sub user_agent : Global {
    my ( $self, $c ) = @_;
    $c->res->output('UA=' . $c->req->user_agent);
}

__PACKAGE__->setup;

__PACKAGE__;

