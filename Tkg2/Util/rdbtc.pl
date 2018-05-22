#!/usr/bin/perl
use lib qw(/usr/local); # file prefix to Tkg2 installation

use Tkg2::Util::RDBtools qw(optime_fixformRDB);

use Getopt::Std;  &getopts('h');

if(not $opt_h) {
   &optime_fixformRDB(-input  => 'stdin',
                      -output => 'stdout',
                      -format => shift());
   exit;
}


print <<'HERE';

RDBTC.PL -- A date/time preprocessor for RDB files
  by William H. Asquith
  
rdbtc.pl takes an rdb file and converts any and all date columns
(designated by a 'd' or 'D' in the format line) to the tkg2 internal
date/time representation, which is fractional days since 19000101.

Usage:

cat my.rdb | rdbtc.pl > my_converted.rdb
# The expected data format is 'YYYYMMDD' by default

cat my.rdb | rdbtc.pl 'MM/DD/YYYY@HH:MM:SS' > my_converted.rdb

See the &optime_fixformRDB subroutine in Tkg2/Util/RDBtools.pm for
further details about the supported date/time formats and how to use
&opttime_fixformRDB on files instead of standard input and standard
output.  You are welcome to modify the subroutine to support your
particular date/time formats--please forward the format to
wasquith@usgs.gov so that the support can be built into the package.

HERE
;
