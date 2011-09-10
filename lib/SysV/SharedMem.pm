package SysV::SharedMem;

use 5.008;
use strict;
use warnings FATAL => 'all';

use Carp qw/croak/;
use Const::Fast;
use IPC::SysV qw/ftok IPC_PRIVATE IPC_CREAT SHM_RDONLY/;
use Sub::Exporter -setup => { exports => [qw/shared_open shared_remove shared_stat shared_chmod shared_chown/] };

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

const my %flags_for => (
	'<'  => SHM_RDONLY,
	'+<' => 0,
	'>'  => 0 | IPC_CREAT,
	'+>' => 0 | IPC_CREAT,
);

## no critic (RequireArgUnpacking)

sub shared_open {
	my (undef, $filename, $mode, %other) = @_;
	my %options = (
		offset => 0,
		id     => 1,
		perms  => oct 600,
		key    => IPC_PRIVATE,
		size   => 0,
		%other,
	);
	$mode = '<' if not defined $mode;
	croak 'No such mode' if not exists $flags_for{$mode};
	croak 'Zero length specified for shared memory segment' if $options{size} == 0;
	my $key = defined $filename ? ftok($filename, $options{id}) : $options{key};
	croak "Invalid key: $!" if not defined $key;
	my $id = shmget $key, $options{size}, $flags_for{$mode} | $options{perms};
	croak "Can't open shared memory object '$filename': $!" if not defined $id;

	_shmat($_[0], $id, @options{qw/offset size/}, 0);
	return;
}

1;    # End of SysV::SharedMem

__END__

# ABSTRACT: SysV Shared memory made easy

=head1 SYNOPSIS

 use SysV::SharedMem;

 shared_open my $mem, '/path', '+>', size => 4096;
 vec($mem, 1, 16) = 34567;
 substr $mem, 45, 11, 'Hello World';

This module maps shared memory into a variable that can be read just like any other variable, and it can be written to using standard Perl techniques such as regexps and C<substr>, B<as long as they don't change the length of the variable>.

=func shared_open($var, $filename, $mode, %options)

Open a shared memory object named C<$filename> and attach it to C<$var>. $filename must be the path to an existing file or undef, in which case the C<key> option is used. C<$mode> determines the read/write mode. It works the same as in open.

Beyond that it can take a number of optional named arguments:

=over 4

=item * size

This determines the size of the map. Must be set if a new shared memory object is being created.

=item * perms

This determines the permissions with which the segment is created (if $mode is '>' or '+>'). Default is 0600.

=item * offset

This determines the offset in the file that is mapped. Default is 0.

=item * key

If C<$filename> is undefined this parameter is used as the key to lookup the shared memory segment. It defaults to IPC_PRIVATE, which causes a new, anonymous shared memory segment to be created.

=item * id

The project id, used to ensure the key generated from the filename is unique. Only the lower 8 bits are significant and may not be zero. Defaults to 1.

=back

=func shared_remove($var)

Marks a memory object to be removed. Shared memory has kernel persisence so it has to be explicitly disposed of. One can still use the object after marking it for removal.

=func shared_stat($var)

Retrieve the properties of the shared memory object. It returns a hashref with these members:

=over 2

=item * uid

Owner's user ID

=item * gid

Owner's group ID

=item * cuid

Creator's user ID

=item * cgid

Creator's group ID

=item * mode

Read/write permission

=item * segsz

Size of segment in bytes

=item * lpid

Process ID of last shared memory operation

=item * cpid

Process ID of creator

=item * nattch

Number of current attaches

=item * atime

Time of last attachment

=item * dtime

Time of last detachment

=item * ctime

Time of last of control structure

=back

=func shared_chmod($var, $modebits)

Change the (lower 9) modebits of the shared memory object.

=func shared_chown($var, $uid, $gid = undef)

Change the owning uid and optionally gid of the shared memory object.

=cut
