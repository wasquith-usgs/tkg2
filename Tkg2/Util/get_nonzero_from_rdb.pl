#!/usr/bin/perl -w

=head1 LICENSE

 This Tkg2 utility program is authored by the enigmatic William H. Asquith
     
 This program is absolutely free software; 

Author of this software makes no claim whatsoever about suitability,
reliability, editability or usability of this product. If you can use it,
you are in luck, if not, I should not be and can not be held responsible.
Furthermore, portions of this software (tkg2 and related modules) were
developed by the Author as an employee of the U.S. Geological Survey
Water-Resources Division, neither the USGS, the Department of the
Interior, or other entities of the Federal Government make any claim
whatsoever about suitability, reliability, editability or usability
of this product.

=cut

# $Author: wasquith $
# $Date: 2006/09/01 13:06:49 $
# $Revision: 1.2 $

use strict;
my (@labels, %values);
our ($opt_h);
use Getopt::Std;
&getopts('h');

if($opt_h) {
print <<'HERE';

get_nonzero_from_rdb.pl -- Get non-zero VALUEs from RDB files
  by William H. Asquith
  
Occasionally, one encounters very large RDB files with many zero values.
It can be desirable to remove the zero values before plotting or
otherwise processing the data.  This program reads a RDB file or
reads standard input and prints to standard output only the records
with a non-zero value in the VALUE field.  The field identifier VALUE
is hard wired and can only be changed by modifying the program itself.
Further details on the file format are shown after the __END__ token
in the program.

Usage:

get_nonzero_from_rdb.pl original.rdb > my_converted.rdb

cat my.rdb | get_nonzero_from_rdb.pl > my_converted.rdb

HERE
;
   exit;
}

while(<>) {
   if(/^#/) { print; next}
   print;
   chomp;
   @labels = split(/\t/,$_);
   $_ = <>;
   print;
   last;
}

while(<>) {
   if(/^#/) { print; next}
   chomp;
   @values{@labels} = split(/\t/,$_);
   next if($values{VALUE} == 0);
   print join("\t",@values{@labels}),"\n";
}

__END__
# //FILE TYPE="NWIS-I UNIT-VALUES" EDITABLE=NO
# //DATABASE NUMBER=1 DESCRIPTION="Texas District"
# //STATION AGENCY="USGS " NUMBER="08167353       " TIME_ZONE="CST" DST_FLAG=Y
# //STATION NAME="Unm Trib Honey Ck Site 2T nr Spring Branch, TX"
# //DD DDID="   3" RNDARY="0223455552" DVABORT=120
# //DD LABEL="PRECIPITATION FROM DCP, IN INCHES"
# //PARAMETER CODE="00045" SNAME="PRECIPITATION"
# //PARAMETER LNAME="PRECIPITATION, TOTAL, INCHES"
# //TYPE CODE=C NAME=COMPUTED
# //RANGE START="20011001000000" END="20020930240000"
DATETIME	VALUE	PRECISION	REMARK	FLAGS	QA
14D	16N	1S	1S	32S	1S
20011001000500	.00	1	 		P
20011001001000	.00	1	 		P
20011001001500	.00	1	 		P

