#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

{
  package MyTestPlugin;
  use strict;

  my $finalized = 0;
  sub finalize_session { $finalized = 1 }

  sub finalize { die "already finalized_session()" if $finalized }

  # Structure inheritance so MyTestPlugin->finalize() is called *after* 
  # Catalyst::Plugin::Session->finalize()
  package TestApp;

  use Catalyst qw/ Session Session::Store::Dummy Session::State::Cookie +MyTestPlugin /;
  __PACKAGE__->config(session => { expires => 1000 });
  __PACKAGE__->setup;
}

my $m;
BEGIN { use_ok( $m = "Catalyst::Plugin::Session" ) }

my $c = TestApp->new;
eval { $c->finalize };
ok(!$@, "finalize_session() called after all other finalize() methods");
