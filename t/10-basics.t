#!perl

use strict;
use warnings;
use SysV::SharedMem qw/shared_open shared_remove/;
use Test::More tests => 4;
use Test::Exception;

my $map;
lives_ok { shared_open $map, $0, '+>', size => 300, id => 2 } "can open file '/name'";

{
	local $SIG{SEGV} = sub { die "Got SEGFAULT\n" };
	lives_ok { substr $map, 100, 6, "foobar" } 'Can write to map';
	ok($map =~ /foobar/, 'Can read written data from map');
}

lives_ok { shared_remove $map } "Can unlink '/name'"


