#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SysV::SharedMem' ) || print "Bail out!
";
}

diag( "Testing SysV::SharedMem $SysV::SharedMem::VERSION, Perl $], $^X" );
