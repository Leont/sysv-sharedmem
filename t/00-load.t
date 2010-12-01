#!perl -T

use Test::NoWarnings;
use Test::More tests => 2;

BEGIN {
    use_ok( 'SysV::SharedMem' ) || print "Bail out!
";
}

diag( "Testing SysV::SharedMem $SysV::SharedMem::VERSION, Perl $], $^X" );
