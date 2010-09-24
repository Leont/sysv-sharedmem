use 5.008;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'SysV::SharedMem',
	license             => 'perl',
	dist_author         => q{Leon Timmermans <leont@cpan.org>},
	dist_version_from   => 'lib/SysV/SharedMem.pm',
	configure_requires  => {
		'Module::Build' => 0.28,
	},
	build_requires => {
		'ExtUtils::CBuilder' => 0,
		'Module::Build' => 0.28,
		'Test::More'    => 0,
	},
	requires            => {
		perl            => 5.008,
		'Const::Fast'   => 0,
		'Sub::Exporter' => 0,
	},
	add_to_cleanup      => [ 'SysV-SharedMem-*' ],
	create_makefile_pl  => 'small',
	sign                => 1,
);

$builder->create_build_script();
