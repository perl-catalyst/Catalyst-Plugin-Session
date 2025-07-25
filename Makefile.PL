use strict;
use warnings;
use 5.008;

my %META = (
  name => 'Catalyst-Plugin-Session',
  license => 'perl_5',
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker' => 0,
    } },
    test => {
      requires => {
        'Plack::Test' => 0,
        'Test::Deep' => 0,
        'Test::Needs' => 0,
      },
    },
    runtime => {
      requires => {
        'Catalyst::Runtime' => '5.71001',
        'namespace::clean' => '0.10',
        'Crypt::SysRandom' => '0.007',
        'File::Spec' => 0,
        'File::Temp' => 0,
        'List::Util' => 0,
        'Object::Signature' => 0,
        'MRO::Compat' => 0,
        'MooseX::Emulate::Class::Accessor::Fast' => '0.00801',
        'Moose' => '0.76',
        'HTML::Entities' => 0,
        'Test::More' => '0.88',
        'perl' => '5.008',
      },
      recommends => {
        'Crypt::SysRandom::XS' => '0.009',
      },
    },
    develop => {
      requires => {
        'Test::Pod' => 0,
        'Test::Pod::Coverage' => 0,
      },
    },
  },
  x_breaks => {
    'Catalyst::Plugin::Session::State::Cookie' => '< 0.03',
    'Catalyst::Plugin::Session::State::URI' => '< 0.02',
  },
  resources => {
    repository => {
      url => 'https://github.com/perl-catalyst/Catalyst-Plugin-Session.git',
      web => 'https://github.com/perl-catalyst/Catalyst-Plugin-Session',
      type => 'git',
    },
    bugtracker => {
      web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Catalyst-Plugin-Session',
      mailto => 'bug-Catalyst-Plugin-Session@rt.cpan.org',
    },
    license => [ 'http://dev.perl.org/licenses/' ],
  },
  no_index => {
    directory => [ 't', 'xt' ]
  },
);

my %MM_ARGS = ();

for my $breaks (sort keys %{ $META{x_breaks} }) {
  my $version = $META{x_breaks}{$breaks};
  $version =~ s{\A<\s+([0-9.]+)\z}{$1} or die "can't handle $version";
  if (eval "require $breaks") {
    if (!eval { $breaks->VERSION($version) }) {
      warn <<WARN;
********** NOTE **********

$breaks must also be updated!

The currently installed version is *not* compatible with this version of
Catalyst::Plugin::Session!

The updated versions have been added to the prerequisites.

**************************
WARN
    }
  }
}

## BOILERPLATE ###############################################################
require ExtUtils::MakeMaker;
(do './maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
my $mymeta        = $eumm_version >= 6.57_02;
my $mymeta_broken = $mymeta && $eumm_version < 6.57_07;

($MM_ARGS{NAME} = $META{name}) =~ s/-/::/g;
($MM_ARGS{VERSION_FROM} = "lib/$MM_ARGS{NAME}.pm") =~ s{::}{/}g;
$META{license} = [ $META{license} ]
  if $META{license} && !ref $META{license};
$MM_ARGS{LICENSE} = $META{license}[0]
  if $META{license} && $eumm_version >= 6.30;
$MM_ARGS{NO_MYMETA} = 1
  if $mymeta_broken;
$MM_ARGS{META_ADD} = { 'meta-spec' => { version => 2 }, %META }
  unless -f 'META.yml';
$MM_ARGS{PL_FILES} ||= {};
$MM_ARGS{NORECURS} = 1
  if not exists $MM_ARGS{NORECURS};

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  my $r = $MM_ARGS{$key} = {
    %{$META{prereqs}{$_}{requires} || {}},
    %{delete $MM_ARGS{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

$MM_ARGS{MIN_PERL_VERSION} = delete $MM_ARGS{PREREQ_PM}{perl} || 0;

delete $MM_ARGS{MIN_PERL_VERSION}
  if $eumm_version < 6.47_01;
$MM_ARGS{BUILD_REQUIRES} = {%{$MM_ARGS{BUILD_REQUIRES}}, %{delete $MM_ARGS{TEST_REQUIRES}}}
  if $eumm_version < 6.63_03;
$MM_ARGS{PREREQ_PM} = {%{$MM_ARGS{PREREQ_PM}}, %{delete $MM_ARGS{BUILD_REQUIRES}}}
  if $eumm_version < 6.55_01;
delete $MM_ARGS{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

ExtUtils::MakeMaker::WriteMakefile(%MM_ARGS);
## END BOILERPLATE ###########################################################
