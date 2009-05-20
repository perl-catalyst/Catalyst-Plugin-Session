use strict;
use ExtUtils::MakeMaker;

use strict;
use warnings;

WriteMakefile(
    NAME         => 'Catalyst-Plugin-SessionHP',
    VERSION_FROM => 'lib/Catalyst/Plugin/SessionHP.pm',
    PREREQ_PM    => {

        'Catalyst::Runtime'                => '5.7010',
        'Catalyst::Plugin::Authentication' => '0.10011',

        'Digest::SHA1'      => 0,
        'File::Spec'        => 0,
        'File::Temp'        => 0,
        'Object::Signature' => 0,
        'MRO::Compat'       => 0,
        'Clone'             => 0,
        'Carp'              => 0,

        # an indirect dep. needs a certain version.
        'Tie::RefHash' => '1.34',

        'Test::More'       => 0,
        'Test::Deep'       => 0,
        'Test::Exception'  => 0,
        'Test::MockObject' => '1.01',
    },
);

