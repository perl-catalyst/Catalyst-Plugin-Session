use strict;
use warnings;

use Test::Needs {
  'Catalyst::Plugin::Session::State::Cookie' => '0.03',
  'Test::WWW::Mechanize::Catalyst' => '0.51',
};

use Test::More;

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";

my $ua = Test::WWW::Mechanize::Catalyst->new( { agent => 'Initial user_agent'} );

my $res;

$res = $ua->get( "http://localhost/user_agent" );
ok +$res->is_success, "get initial user_agent";
like +$res->content, qr{UA=Initial user_agent}, "test initial user_agent";

$res = $ua->get( "http://localhost/page" );
ok +$res->is_success, "initial get main page";
like +$res->content, qr{please login}, "ua not logged in";

$res = $ua->get( "http://localhost/login" );
ok +$res->is_success, "log ua in";
like +$res->content, qr{logged in}, "ua logged in";

$res = $ua->get( "http://localhost/page" );
ok +$res->is_success, "get main page";
like +$res->content, qr{you are logged in}, "ua logged in";

$ua->agent('Changed user_agent');

$res = $ua->get( "http://localhost/user_agent" );
ok +$res->is_success, "get changed user_agent";
like +$res->content, qr{UA=Changed user_agent}, "test changed user_agent";

$res = $ua->get( "http://localhost/page" );
ok +$res->is_success, "test deleted session";
like +$res->content, qr{please login}, "ua not logged in";

done_testing;
