#!/usr/bin/perl -w

package FlashTestApp;
use Catalyst qw/Session Session::Store::File Session::State::Cookie/;

use strict;
use warnings;

sub default : Private {
    my ($self, $c) = @_;
    $c->session;
}

    
sub first : Global {
    my ( $self, $c ) = @_;
    if ( ! $c->flash->{is_set}) {
        $c->stash->{message} = "flash is not set";
        $c->stash->{is_set} = 1;
    }
}

sub second : Global {
    my ( $self, $c ) = @_;
    if ($c->flash->{is_set} == 1){
        $c->stash->{message} = "flash set first time";
        $c->flash->{is_set}++;
    }
}

sub third : Global {
    my ( $self, $c ) = @_;
    if ($c->flash->{is_set} == 2) {
        $c->stash->{message} = "flash set second time";
        $c->flash->{is_set} = 2;
    }
}

sub fourth : Global {
    my ( $self, $c ) = @_;
    if ($c->flash->{is_set} == 2) {
        $c->stash->{message} = "flash set 3rd time, same val as prev."
    }
}

sub fifth : Global {
    my ( $self, $c ) = @_;
    $c->forward('/first');
}

sub end : Local {
    my ($self, $c) = @_;
    $c->res->output($c->stash->{message});
}


__PACKAGE__->setup;

__PACKAGE__;

