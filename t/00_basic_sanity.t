#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;


my $m; BEGIN { use_ok($m = "Catalyst::Plugin::SessionHP") }

can_ok($m, $_) for qw/session_id session session_delete_reason/;
