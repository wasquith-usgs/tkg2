#!/usr/bin/perl
use lib qw(/usr/local); # file prefix to Tkg2 installation

use Tkg2::Util::RDBtools qw(spliceYEAR_MONTH_DAY_optionalTIME_inRDB);

use Getopt::Std;  &getopts('h');

if(not $opt_h) {
   &spliceYEAR_MONTH_DAY_optionalTIME_inRDB(-input  => shift(@ARGV),
                                            -output => shift(@ARGV));
   exit;
}


print <<'HERE';

rdb_ymd2d_t.pl -- A year, month, day, and time splicer for RDB files
  by William H. Asquith
  
rdb_ymd2d_t.pl takes an rdb file and if and only if there is are
YEAR, MONTH, DAY fields and an optional TIME field these columns
are replaced with a DATE_TIME field.

Usage:

rdb_ymd2d_t.pl original.rdb > my_converted.rdb

cat my.rdb | rdb_ymd2d_t.pl > my_converted.rdb


HERE
;
