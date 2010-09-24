package SysV::SharedMem;

use 5.008;
use strict;
use warnings FATAL => 'all';

use Carp qw/croak/;
use Const::Fast;
use Fcntl qw/O_RDONLY O_WRONLY O_RDWR O_CREAT/;
use IPC::SysV qw/ftok IPC_STAT IPC_RMID IPC_PRIVATE IPC_CREAT/;
use Sub::Exporter -setup => { exports => [qw/shared_open shared_remove shared_stat shared_chmod/] };

use XSLoader;

our $VERSION = '0.001';
XSLoader::load(__PACKAGE__, $VERSION);

my %flags_for = (
	'<'  => O_RDONLY,
	'+<' => O_RDWR,
	'>'  => O_WRONLY,
	'+>' => O_RDWR | IPC_CREAT,
);

## no critic (RequireArgUnpacking)

sub shared_open {
	my (undef, $name, $mode, %other) = @_;
	my %options = (
		offset => 0,
		id     => 1,
		perms  => oct 700,
		%other,
	);
	$mode = '<' if not defined $mode;
	croak 'No such mode' if not defined $flags_for{$mode};
	my $key = defined $name ? ftok($name, $options{id}) : IPC_PRIVATE;
	my $id = shmget $key, $options{size}, $flags_for{$mode} | $options{perms};
	croak "Can't open shared memory object $name: $!" if not defined $id;

	_shmat($_[0], $id, @options{qw/offset size/}, 0);
	return;
}

sub shared_remove {
	my $id = _get_id($_[0], 'shared_remove');
	shmctl $id, IPC_RMID, 0;
	return;
}

sub shared_stat {
	my $id = _get_id($_[0], 'shared_stat');
	my $data = '';
	shmctl $id, IPC_STAT, $data or croak "Couldn't stat shared memory segment: $!";
	return $data;
}

sub shared_chmod {
	croak 'unimplemented';
}

1;    # End of SysV::SharedMem

__END__

=head1 NAME

SysV::SharedMem - SysV Shared memory made easy

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

 use SysV::SharedMem;

 shared_open my $mem, '/path', '+>', size => 4096;
 vec($mem, 1, 16) = 34567;
 substr $mem, 45, 11, 'Hello World';

This module maps shared memory into a variable that can be read just like any other variable, and it can be written to using standard Perl techniques such as regexps and C<substr>, B<as long as they don't change the length of the variable>.

=head1 METHODS

=head2 shared_open($var, $name, $mode, %options)

Open a shared memory object named C<$name> and attach it to C<$var>. $name must be the path to an existing file or undef, in which case an anonymous object is created. C<$mode> determines the read/write mode. It works the same as in open.

Beyond that it can take a number of optional named arguments:

=over 4

=item * size

This determines the size of the map. Must be set if a new shared memory object is being created.

=item * perms

This determines the permissions with which the file is created (if $mode is '+>'). Default is 0700.

=item * offset

This determines the offset in the file that is mapped. Default is 0.

=item * id

The project id, used to ensure the key generated from the filename is unique. Only the lower 8 bits are significant and may not be zero. Defaults to 1.

=back

=head2 shared_remove($var)

Marks a memory object to be removed. Shared memory has kernel persisence so it has to be explicitly disposed of. One can still use the object after marking it for removal.

=head2 shared_stat($var)

=head2 shared_chmod($var, $modebits)

=head2 shared_chown($var, $uid, $gid = undef)

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sysv-sharedmem at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SysV-SharedMem>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SysV::SharedMem


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SysV-SharedMem>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SysV-SharedMem>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SysV-SharedMem>

=item * Search CPAN

L<http://search.cpan.org/dist/SysV-SharedMem/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Leon Timmermans.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
