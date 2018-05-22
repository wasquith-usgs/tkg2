#!/usr/bin/perl -w

=head1 LICENSE

 This Tkg2 module is authored by the enigmatic William H. Asquith.
     
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
# $Date: 2002/01/06 14:23:10 $
# $Revision: 1.4 $

use strict;

my $infile  = (@ARGV) ? shift(@ARGV) : "/dev/stdin";
my $outfile = (@ARGV) ? shift(@ARGV) : "/dev/stdout";
   $outfile = "$infile.rdb" if($outfile eq "-");
 
open(IN, "<$infile") or
  die "%% $0 died opening '$infile' for reading because $!\n";
open(OUT, ">$outfile") or
  die "%% $0 died opening '$outfile' for writing because $!\n";

print OUT "# GWSI Standard Table format converted to tab delimited\n",
          "# format with converted date field for easier parsing.\n",
          "# Original GWSI table = $infile\n",
          "DATE_TIME\tWATER_LEVEL(FEET)\n",
          "d\tn\n";

while(<IN>) {
   chomp;   # strip the newline to protect against cross-platform issues
   next if /^\s+$/o; # skip lines containing just spaces
   next if / WATER | LEVEL | DATE /ox;
   s/^\s+//o;        # strip leading spaces from the file
   s/\s+$//o;        # strip trailing spaces for safety--not needed?
   s/(\d)-/$1\//go;  # replace - in the date with backslash
                     # the (\d) capture is to prevent negative
                     # water levels from being clobbered.
   s/\s+/\t/go;      # strip all spaces and replace with a tab.
   print OUT "$_\n"; # print the line to the output file handle
}

__DATA__

Here is the gwsi standard table output file format.

1DATE: 08/23/01     PAGE   1 
  
 
   WATER-     WATER
   LEVEL      LEVEL
    DATE      (FEET)
  
 11-15-1946   82.6
 03-11-1947   83.62
 12-15-1947   89.93
 02-05-1948   89.94
 09-21-1948   98.87
  
 12-14-1948   97.76
 02-08-1949   97.16
 06-30-1949   99.11
 09-20-1949  104.50
 12-22-1949  102.51
  
 02-17-1950  102.34
 06-12-1950  103.15
 09-27-1950  108.81
 12-15-1950  109.10
 02-21-1951  108.91
  
 06-13-1951  114.95
 09-18-1951  118.91
 12-13-1951  116.39
 02-05-1952  115.89
 06-17-1952  117.14
  
 09-17-1952  120.02
 12-30-1952  123.51
 02-05-1953  121.07
 09-28-1953  128.99
 12-21-1953  127.38
  
 02-18-1954  127.12
 09-27-1954  135.10
 12-17-1954  134.72
 02-09-1955  132.33
 09-21-1955  137.13
  
 12-09-1955  135.68
 02-16-1956  134.18
 09-14-1956  143.84
 12-12-1956  141.70
 02-20-1957  140.08
  
 09-11-1957  142.86
 12-11-1957  141.58
 02-26-1958  140.11
 09-18-1958  145.71
 12-09-1958  146.13
1DATE: 08/23/01     PAGE   2 
  
 
   WATER-     WATER
   LEVEL      LEVEL
    DATE      (FEET)
  
 02-18-1959  142.55
 09-21-1959  145.14
 12-21-1959  143.52
 02-09-1960  142.11
 12-30-1960  147.16
  
 02-08-1961  145.36
 09-18-1961  150.04
 12-22-1961  148.19
 02-13-1962  147.74
 12-12-1962  154.84
  
 02-21-1963  153.61
 09-25-1963  160.88
 
 
which is converted to this

# gwsi standard table converted to RDB
# original gwsi table = stan.table
DATE_TIME       WATER_LEVEL(FEET)
11/15/1946      82.6
03/11/1947      83.62
12/15/1947      89.93
02/05/1948      89.94
09/21/1948      98.87
12/14/1948      97.76
02/08/1949      97.16
06/30/1949      99.11
09/20/1949      104.50
12/22/1949      102.51

______ BELOW IS OPERATIONAL HEADER FOR A TKG2 TEMPLATE 
#!/usr/bin/perl -w
# --------------------------------------------------------------
# A Tkg2 file -- by the enigmatic William H. Asquith
# --------------------------------------------------------------
#   The following is the standard header written by tkg2
#   during a file save.   Tkg2 requires that the DATA
#   token be present as it uses this as a flag to begin actually
#   reading a file in.  You can edit anything you want
#   above the DATA token or even remove all this entirely.
#   Or you can put any data retrieval scripts above the 'exec'
#   to get the data files in place before tkg2 and this file is
#   actually launched.
use File::Copy;
my $gwsi_file = (@ARGV) ? shift(@ARGV) : undef;
if(defined $gwsi_file and $gwsi_file =~ /help/io) {
   print STDERR
      "%%\n%%            **** The $0 Graphics Package ****\n%%\n",
      "%% You are using the tkg2 implementation of GWSI standard table\n",
      "%% output files for graphical output.\n",
      "%%\n%% A GWSI standard table file name is provided as the first argument\n",
      "%% on the command line.  All other arguments are passed to tkg2.\n",
      "%% This program copies the table to a file called gwsi4tkg2.tmp.\n",
      "%% The gwsi4tkg2.tmp file is then passed through the \n",
      "%% /usr/local/Tkg2/Util/gwsi_std2rdb.pl script via the\n",
      "%% megacommand feature of tkg2.  Please leave a copy of gwsi4tkg2.tmp\n",
      "%% in the current directory as this tkg2 file\n",
      "%%\n%% Usage: $0 gwsi4tkg2.tmp\n%%   Danger--editing the raw tkg2 template\n",
      "%%\n%%      : $0 stan.table\n%%   Usual Mode--To view the graphical output\n",
      "%%                 A TMP_gwsi.tkg2 file is used by tkg2 for safety.\n",
      "%%\n%% by William Asquith <wasquith\@usgs.gov>, August 2001\n";
      exit;
}
die " DIED: Please provide an existing GWSI file name as first argument.\n".
    "         Try '$0 help' for more details\n"
     if(not defined $gwsi_file or not -e $gwsi_file);

# No copying is needed if we just want the temporary file name plotted.
if($gwsi_file ne 'gwsi4tkg2.tmp') {
   copy($gwsi_file,"gwsi4tkg2.tmp");
   $tkg2_template = "TMP_gwsi.tkg2";
   copy($0, $tkg2_template);
   push(@ARGV, "--justdisplayone --nobind");   
}
else {
   $tkg2_template = $0;
}
