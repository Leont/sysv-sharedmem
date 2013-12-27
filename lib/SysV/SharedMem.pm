package SysV::SharedMem;

use 5.008;
use strict;
use warnings FATAL => 'all';

use Carp qw/croak/;
use IPC::SysV qw/ftok IPC_PRIVATE IPC_CREAT SHM_RDONLY/;
use Sub::Exporter::Progressive -setup => { exports => [qw/shared_open shared_remove shared_stat shared_chmod shared_chown/] };

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

my %get_flags_for = (
	'<'  => 0,
	'+<' => 0,
	'>'  => 0 | IPC_CREAT,
	'+>' => 0 | IPC_CREAT,
);

my %at_flags_for = (
	'<'  => SHM_RDONLY,
	'+<' => 0,
	'>'  => 0,
	'+>' => 0,
);

## no critic (RequireArgUnpacking)

sub _get_key {
	my ($filename, $mode, %options) = @_;
	return $options{key} if defined $options{key};
	return ftok($filename, $options{proj_id}) || croak "Invalid filename for shared memory segment: $!" if defined $filename;
	return IPC_PRIVATE;
}

sub shared_open {
	my (undef, $filename, $mode, %other) = @_;
	my %options = (
		offset  => 0,
		proj_id => 1,
		perms   => oct 600,
		size    => 0,
		%other,
	);
	$mode = '<' if not defined $mode;
	croak 'No such mode' if not exists $at_flags_for{$mode};
	my $id = $options{id} || do {
		my $key = _get_key($filename, $mode, %options);
		croak 'Zero length specified for shared memory segment' if $options{size} == 0 && ($get_flags_for{$mode} & IPC_CREAT || $key == IPC_PRIVATE);
		shmget $key, $options{size}, $get_flags_for{$mode} | $options{perms} or croak "Can't open shared memory object: $!";
	};

	_shmat($_[0], $id, @options{qw/offset size/}, $at_flags_for{$mode});
	return;
}

1;    # End of SysV::SharedMem

# ABSTRACT: SysV Shared memory made easy

=head1 SYNOPSIS

 use SysV::SharedMem;

 shared_open my $mem, '/path', '+>', size => 4096;
 vec($mem, 1, 16) = 34567;
 substr $mem, 45, 11, 'Hello World';

=head1 DESCRIPTION

This module maps SysV shared memory into a variable that can be read just like any other variable, and it can be written to using standard Perl techniques such as regexps and C<substr>, B<as long as they don't change the length of the variable>.

=func shared_open($var, $filename, $mode, %options)

Open a shared memory object named C<$filename> and attach it to C<$var>. The segment that will be opened is determined with this order of precedence: C<$options{id}>, C<$options{key}>, C<$filename>, C<IPC_PRIVATE> (create a new anonymous segment).

$filename must be the path to an existing file if defined. C<$mode> determines the read/write mode; it works the same as in open.

Beyond that it can take a number of optional named arguments:

=over 4

=item * id

The option is defined is specifies the shared memory identifier that will be opened. It overrides both C<$options{key}> and C<$filename>.

=item * key

If C<$options{id}> is undefined this parameter is used as the key to lookup the shared memory segment.

=item * size

This determines the size of the map. Must be set if a new shared memory object is being created.

=item * perms

This determines the permissions with which the segment is created (if C<$mode> is '>' or '+>'). Default is 0600.

=item * offset

This determines the offset in the file that is mapped. Default is 0.

=item * proj_id

The project id, used to ensure the key generated from C<$filename> is unique. Only the lower 8 bits are significant and may not be zero. Defaults to 1.

=back

=func shared_remove($var)

Marks a memory object to be removed. Shared memory has kernel persistence so it has to be explicitly disposed of. One can still use the object after marking it for removal.

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
