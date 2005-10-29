use strict;
use Module::Build;

my $build = Module::Build->new(
    create_makefile_pl => 'traditional',
    license            => 'perl',
    module_name        => 'Catalyst::Plugin::Session',
    requires           => {
        'perl'                      => '5.8.1',
        'Catalyst'                  => '5.50',
    },
    create_readme      => 1,
	sign => 1,
);
$build->create_build_script;

