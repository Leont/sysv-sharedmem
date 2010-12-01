#!perl

use strict;
use warnings;

use SysV::SharedMem qw/shared_open shared_remove/;
use Test::More tests => 19;
use Test::Warn;
use Test::Exception;
use Test::NoWarnings;

sub map_named(\$@) {
	my ($ref, $name, $mode, $size) = @_;
	shared_open($$ref, $name, $mode, size => $size);
	shared_remove($$ref);
	return;
}

sub map_anonymous(\$@) {
	my ($ref, $size) = @_;
	shared_open($$ref, undef, '+<', size => $size);
	shared_remove($$ref);
	return;
}

open my $self, '<:raw', $0 or die "Couldn't open self: $!";
my $slurped = do { local $/; <$self> };

my $mmaped;
lives_ok { map_anonymous $mmaped, length $slurped } 'Mapping succeeded';

substr $mmaped, 0, length $mmaped, $slurped;

is $mmaped, $slurped, '$slurped an $mmaped are equal';

warning_like { $mmaped = reverse $mmaped } qr/^Writing directly to shared memory is not recommended at /, 'Reversing should give a warning';

is($mmaped, scalar reverse($slurped), '$mmap is reversed');

{
	no warnings 'substr';
	warning_like { $mmaped = reverse $mmaped } undef, 'Reversing shouldn\'t give a warning when substr warnings are disabled';
}

warning_is { $mmaped = $mmaped } undef, 'No warnings on self-assignment';

throws_ok { map_named my $var, 'some-nonexistant-file', '<', 1024 } qr/Invalid key: No such file or directory at /, 'Can\'t map wth non-existant file as a key';

throws_ok { map_named my $var, $0, '<', 1024 } qr/Can't open shared memory object '[\w\/.-]+': No such file or directory/, 'Can\'t map wth non-existant file as a key';

warnings_like { $mmaped =~ s/(.)/$1$1/ } [ qr/^Writing directly to shared memory is not recommended at /, qr/^Truncating new value to size of the shared memory segment at /], 'Trying to make it longer gives warnings';

warning_is { $slurped =~ tr/r/t/ } undef, 'Translation shouldn\'t cause warnings';

# throws_ok { unmap my $foo } qr/^Could not unmap: this variable is not memory mapped at /, 'Can\'t unmap normal variables';

throws_ok { map_anonymous my $foo, 0 } qr/^Zero length specified for shared memory segment at /, 'Have to provide a length for anonymous maps';

warning_like { $mmaped = "foo" } qr/^Writing directly to shared memory is not recommended at /, 'Trying to make it shorter gives a warning';

is(length $mmaped, length $slurped, '$mmaped and $slurped still have the same length');

warning_like { $mmaped = 1 } qr/^Writing directly to shared memory is not recommended at /, 'Cutting should give a warning for numbers too';

warnings_like { undef $mmaped } [ qr/^Writing directly to shared memory is not recommended at/ ], 'Survives undefing';

SKIP: {
	map_anonymous our $local, 1024;
	skip 'Your perl doesn\'t support hooking localization', 1 if $] < 5.008009;
	throws_ok { local $local } qr/^Can't localize shared memory segment at /, 'Localization throws an exception';
}

my %hash;
lives_ok { map_anonymous $hash{'foo'}, 4096 } 'mapping a hash element shouldn\'t croak';

my $x;
my $y = \$x;

lives_ok { map_anonymous $y, 4096 } 'mapping to a reference shouldn\'t croak';
