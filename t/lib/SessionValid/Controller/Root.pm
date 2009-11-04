package SessionValid::Controller::Root;
use strict;
use warnings;
use Data::Dumper;

use base qw/Catalyst::Controller/;

__PACKAGE__->config( namespace => '' );

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    $c->session->{'value'} = 'value set';
    $c->session_is_valid;
    $c->res->output($c->session->{'value'});
}

1;
