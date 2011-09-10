#!perl

use strict;
use warnings;
use SysV::SharedMem qw/shared_open shared_remove shared_stat shared_chmod/;
use Test::More tests => 10;
use Test::Exception;
use Test::NoWarnings;

my $map;
lives_ok { shared_open $map, $0, '+>', size => 300, id => 2 } "can open file '/name'";

{
	local $SIG{SEGV} = sub { die "Got SEGFAULT\n" };
	lives_ok { substr $map, 100, 6, "foobar" } 'Can write to map';
	ok($map =~ /foobar/, 'Can read written data from map');
}

my $stat;
lives_ok { $stat = shared_stat($map) } 'Can stat shared memory';

is $stat->{uid}, $>, 'uid matches process\' uid';

is $stat->{mode} & 0777, 0600, 'Owner can read and write';

lives_ok { shared_chmod $map, 0600 } 'Can chmod shared memory';

is shared_stat($map)->{mode} & 0777, 0600;

lives_ok { shared_remove $map } "Can unlink '/name'"

