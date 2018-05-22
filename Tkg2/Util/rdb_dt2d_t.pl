#!/usr/bin/perl
use lib qw(/usr/local); # file prefix to Tkg2 installation

use Tkg2::Util::RDBtools qw(spliceDATE_TIME_inRDB);

use Getopt::Std;  &getopts('h');

if(not $opt_h) {
   &spliceDATE_TIME_inRDB(-input  => shift(@ARGV),
                          -output => shift(@ARGV));
   exit;
}


print <<'HERE';

rdb_dt2d_t.pl -- A date/time splicer for RDB files
  by William H. Asquith
  
rdb_dt2d_t.pl takes an rdb file and if and only if there is a
DATE field and a TIME field these columns are replaced with a
single DATE_TIME field.

Usage:

rdb_dt2d_t.pl original.rdb > my_converted.rdb

cat my.rdb | rdb_dt2d_t.pl > my_converted.rdb

HERE
;
