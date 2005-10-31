#!/usr/bin/perl

package Catalyst::Plugin::Session::Store::Dummy;
use base qw/Catalyst::Plugin::Session::Store/;

use strict;
use warnings;

my %store;

sub get_session_data {
    my ( $c, $sid ) = @_;
    $store{$sid};
}

sub store_session_data {
    my ( $c, $sid, $data ) = @_;
    $store{$sid} = $data;
}

sub delete_session_data {
    my ( $c, $sid ) = @_;
    delete $store{$sid};
}

sub delete_expired_sessions { }

__PACKAGE__;

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session::Store::Dummy - 

=head1 SYNOPSIS

    use Catalyst::Plugin::Session::Store::Dummy;

=head1 DESCRIPTION

=cut


