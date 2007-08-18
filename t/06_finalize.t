#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    if ( eval { require Catalyst::Plugin::Session::State::Cookie } ) {
        plan tests => 3;
    } else {
        plan skip_all => "Catalyst::Plugin::Session::State::Cookie required";
    }
}

my $finalized = 0;

{
  package TestPlugin;
  BEGIN { $INC{"TestPlugin.pm"} = 1 } # nasty hack for 5.8.6

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
