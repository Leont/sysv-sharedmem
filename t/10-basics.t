#!perl

use strict;
use warnings;
use SysV::SharedMem qw/shared_open shared_remove shared_stat/;
use Test::More tests => 6;
use Test::Exception;

my $map;
lives_ok { shared_open $map, $0, '+>', size => 300, id => 2 } "can open file '/name'";

{
	local $SIG{SEGV} = sub { die "Got SEGFAULT\n" };
	lives_ok { substr $map, 100, 6, "foobar" } 'Can write to map';
	ok($map =~ /foobar/, 'Can read written data from map');
}

my $stat;
lives_ok { $stat = shared_stat($map) } 'Can stat shared memory';

is $stat->{uid}, $<, 'uid matches process\' uid';

lives_ok { shared_remove $map } "Can unlink '/name'"


