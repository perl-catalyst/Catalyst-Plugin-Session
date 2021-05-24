use strict;
use warnings;

use Test::Needs {
  'Catalyst::Plugin::Session::State::Cookie' => '0.03',
  'Catalyst::Plugin::Authentication' => 0,
  'Test::WWW::Mechanize::PSGI' => 0,
};

use Test::More;

use lib "t/lib";
use Test::WWW::Mechanize::PSGI;
use SessionTestApp;
my $ua = Test::WWW::Mechanize::PSGI->new(
  app => SessionTestApp->psgi_app(@_),
  cookie_jar => {}
);

# Test without delete __address
local $ENV{REMOTE_ADDR} = "192.168.1.1";

$ua->get_ok( "http://localhost/login" );
$ua->content_contains('logged in');

$ua->get_ok( "http://localhost/set_session_variable/logged/in" );
$ua->content_contains('session variable set');


# Change Client
use Plack::Builder;
my $app = SessionTestApp->psgi_app(@_);
my $ua2 = Test::WWW::Mechanize::PSGI->new(
    app => $app,
    cookie_jar => {}
);
$ua2->get_ok( "http://localhost/get_session_variable/logged");
$ua2->content_contains('VAR_logged=n.a.');

# Inital Client
local $ENV{REMOTE_ADDR} = "192.168.1.1";

$ua->get_ok( "http://localhost/login_without_address" );
$ua->content_contains('logged in (without address)');

$ua->get_ok( "http://localhost/set_session_variable/logged/in" );
$ua->content_contains('session variable set');

# Change Client
local $ENV{REMOTE_ADDR} = "192.168.1.2";

$ua->get_ok( "http://localhost/get_session_variable/logged" );
$ua->content_contains('VAR_logged=in');

done_testing;
