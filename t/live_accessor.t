use strict;
use warnings;

use Test::Needs {
  'Catalyst::Plugin::Session::State::Cookie' => '0.03',
  'Test::WWW::Mechanize::Catalyst' => '0.51',
};

use Test::More;

use lib "t/lib";
use Test::WWW::Mechanize::Catalyst "SessionTestApp";

my $ua = Test::WWW::Mechanize::Catalyst->new;

my $res = $ua->get( '/accessor_test');
ok +$res->is_success, 'Set session vars okay';

like +$res->content, qr{two: 2}, 'k/v list setter works okay';

like +$res->content, qr{four: 4}, 'hashref setter works okay';

like +$res->content, qr{five: 5}, 'direct access works okay';

done_testing;
