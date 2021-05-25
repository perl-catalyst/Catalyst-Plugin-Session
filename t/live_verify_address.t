use strict;
use warnings;

use Test::Needs {
  'Catalyst::Plugin::Session::State::Cookie' => '0.03',
  'Catalyst::Plugin::Authentication' => 0,
  'Test::WWW::Mechanize::Catalyst' => '0.51',
};

use Test::More;

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";

my $ua = Test::WWW::Mechanize::Catalyst->new;

# Test without delete __address
local $ENV{REMOTE_ADDR} = "192.168.1.1";

my $res;

$res = $ua->get( "http://localhost/login" );
ok +$res->is_success;
like +$res->content, qr{logged in};

$res = $ua->get( "http://localhost/set_session_variable/logged/in" );
ok +$res->is_success;
like +$res->content, qr{session variable set};


# Change Client
my $ua2 = Test::WWW::Mechanize::Catalyst->new;
$res = $ua2->get( "http://localhost/get_session_variable/logged" );
ok +$res->is_success;
like +$res->content, qr{VAR_logged=n\.a\.};

# Inital Client
local $ENV{REMOTE_ADDR} = "192.168.1.1";

$res = $ua->get( "http://localhost/login_without_address" );
ok +$res->is_success;
like +$res->content, qr{logged in \(without address\)};

$res = $ua->get( "http://localhost/set_session_variable/logged/in" );
ok +$res->is_success;
like +$res->content, qr{session variable set};

# Change Client
local $ENV{REMOTE_ADDR} = "192.168.1.2";

$res = $ua->get( "http://localhost/get_session_variable/logged" );
ok +$res->is_success;
like +$res->content, qr{VAR_logged=in};

done_testing;
