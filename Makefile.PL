use ExtUtils::MakeMaker;

my %state = (
    Cookie => 0.03,
    URI    => 0.02,
);

my @extra;

foreach my $module (keys %state) {
    if ( eval "require Catalyst::Plugin::Session::State::$module" and
    not eval { "Catalyst::Plugin::Session::State::$module"->VERSION($state{$module}) } ) {
        warn <<WARN;

********** NOTE **********
**************************

Catalyst::Plugin::Session::State::$module must also be updated!

The currently installed version is *not* compatible with this version of
Catalyst::Plugin::Session!

The updated versions have been added to the prerequisites.

**************************
**************************
WARN

        push @extra, "Catalyst::Plugin::Session::State::$module" => $state{$module};
    }
}

WriteMakefile
(
          'NAME' => 'Catalyst::Plugin::Session',
          'VERSION_FROM' => 'lib/Catalyst/Plugin/Session.pm',
          'PREREQ_PM' => {
                           'Catalyst' => '5.49',
                           'Digest' => '0',
                           'File::Spec' => '0',
                           'File::Temp' => '0',
                           'Object::Signature' => '0',
                           'Test::Deep' => '0',
                           'Test::Exception' => '0',
                           'Test::MockObject' => '1.01',
                           'Test::More' => '0',
                           'Tie::RefHash' => '1.34',
                           @extra,
                         },
          'INSTALLDIRS' => 'site',
          'EXE_FILES' => [],
          'SIGN'      => 1,
          'PL_FILES'  => {}
        )
;


