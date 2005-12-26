use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Catalyst::Plugin::Session',
    requires           => {
        'perl'              => '5.8.1',
        'Catalyst'          => '5.49',
        'Test::MockObject'  => '1.01',
        'Digest'            => 0,
        'Object::Signature' => 0,
        'File::Temp'        => 0,
        'File::Spec'        => 0,
        'Test::Deep'        => 0,
        'Test::More'        => 0,
        'Test::Exception'   => 0,
    },
    reccomends => {

        # for live_app.t
        'Test::WWW::Mechanize::Catalyst'    => 0,
        'Catalyst::Plugin::Session::Cookie' => 0,

    },
    create_readme => 1,
    sign          => 1,
);
$build->create_build_script;

