package SessionTestApp::Controller::Root;
use strict;
use warnings;
use Data::Dumper;

use base qw/Catalyst::Controller/;

__PACKAGE__->config( namespace => '' );

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

sub set_session_variable : Global {
    my ( $self, $c, $var, $val ) = @_;
    $c->session->{$var} = $val;
    $c->res->output("session variable set");
}

sub get_session_variable : Global {
    my ( $self, $c, $var ) = @_;
    my $val = $c->session->{$var} || 'n.a.';
    $c->res->output("VAR_$var=$val");
}

sub get_sessid : Global {
    my ( $self, $c ) = @_;
    my $sid = $c->sessionid || 'n.a.';
    $c->res->output("SID=$sid");
}

sub dump_session : Global {
    my ( $self, $c ) = @_;
    my $sid = $c->sessionid || 'n.a.';
    my $dump = Dumper($c->session || 'n.a.');
    $c->res->output("[SID=$sid]\n$dump");
}

sub change_sessid : Global {
    my ( $self, $c ) = @_;
    $c->change_session_id;
    $c->res->output("session id changed");
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

1;
