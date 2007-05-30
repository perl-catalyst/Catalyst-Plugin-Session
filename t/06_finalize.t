#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

my $finalized = 0;

{
  package TestPlugin;

  sub finalize_session { $finalized = 1 }

  sub finalize { die "already finalized_session()" if $finalized }

  # Structure inheritance so TestPlugin->finalize() is called *after* 
  # Catalyst::Plugin::Session->finalize()
  package TestApp;

  use Catalyst qw/
    Session Session::Store::Dummy Session::State::Cookie +TestPlugin 
  /;
  __PACKAGE__->setup;
}

BEGIN { use_ok('Catalyst::Plugin::Session') }

my $c = TestApp->new;
eval { $c->finalize };
ok(!$@, "finalize_session() called after all other finalize() methods");
ok($finalized, "finalize_session() called");
