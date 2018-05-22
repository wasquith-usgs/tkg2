#!/usr/bin/perl -w

=head1 LICENSE

 This program is authored by the enigmatic William H. Asquith
     
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
# $Date: 2002/08/07 18:26:57 $
# $Revision: 1.4 $

use strict;
$| = 1; # turn autoflush on

my $leader = " OUTWAT=>RDB: ";
print STDERR " $leader $0 is working.\n";

&handleCommandLine_and_IO();
print STDERR " $leader Input and Output has been routed.\n";

my @labels = &process_and_write_header();
print STDERR " $leader Header has been processed and written.\n";

&write_label_and_format_lines(@labels);
print STDERR " $leader Label and format lines have been processed.\n";

&process_and_write_data();
print STDERR " $leader $0 has successfully executed.\n";

exit;



#####################################################
#
#      SUBROUTINES
#
#####################################################
sub handleCommandLine_and_IO {
   my $infile = shift @ARGV;
   
   # no input file specified on command line
   &help_and_exit if not $infile or not -e $infile;
   
   # Where is input coming from?
   open(INFH, "<$infile") or
      die "$0: Died--could not open $infile because $!\n";

   # Where is the output going?
   my $otfile = (@ARGV) ? shift(@ARGV) : "/dev/stdout";
   open(OUTFH, ">$otfile") or
      die "$0: Died--could not open $otfile because $!\n";
}


sub write_label_and_format_lines {
   my @labels = @_;
   
   # write the label and format lines
   print OUTFH join("\t",qw(NAME DATE),@labels),"\n";
   print OUTFH join("\t",qw(s d));
   foreach (0..$#labels-1) {
      print OUTFH "\tn";
   }
   print OUTFH "\tn\n";
}


sub process_and_write_header {
   my @header;
   # Read in the header
   while(<INFH>) {
      chomp;
      push(@header, $_);
      last if m/^-+$/;
   }

   pop(@header);  # remove the ------------------- line
   my @labels = split(/\s+/o, pop(@header)); # grab labels, but we don't use

   # dump the original header with prepended # signs
   foreach (@header) {
      print OUTFH "# $_\n";
   }
   splice(@labels,0,5);
   return @labels;
}


sub process_and_write_data {
   while(<INFH>) {
     chomp;
     next if(/^\s*$/o);
     my ($name, $y, $m, $d, $minutes, @line) = split(/\s+/o,$_);
     my $hhmmss = &minutes2hhmmss($minutes);
     $m = &show2digits($m);
     $d = &show2digits($d);
     print OUTFH "$name\t$m/$d/$y $hhmmss\t",join("\t",@line),"\n";   
   }
}


sub minutes2hhmmss {
   my $min = $_[0];  # incoming minutes into day
   $min /= 60; # convert to hours and fractional hours
   my ($hh, $frh) = split(/\./o,$min,2);
   $hh = &show2digits($hh);
   return "$hh:00:00" unless($frh);
   
   $frh = ".$frh";
   $frh *=60;  # convert to minutes and fractional minutes
   my ($mm, $frm) = split(/\./o,$frh,2);
   $mm = &show2digits($mm);
   return "$hh:$mm:00" unless($frm);
   
   $frm  = ".$frm";
   $frm *= 60; # convert to seconds and fractional seconds
   my ($ss, $frs) = split(/\./o,$frm,2);
   $ss = &show2digits($ss);
   return "$hh:$mm:$ss";
   
   # follow is not run as we are fully tested on fractional seconds
   #return "$hh:$mm:$ss" unless($frs);
   
   #$frs = ".$frs";
   #$ss += $frs;
   #return "$hh:$mm:$ss";
}


sub show2digits { return sprintf("%2.2d",$_[0]) }


sub help_and_exit {
   print STDERR <<HERE;

 outwat2rdb.pl: Convert OUTWAT file to a pseudo RDB file
                for Tkg2 and other applications using
                simple single label and format lined tab
                delimited files.
                    
 USAGE
   
   % outwat2rdb.pl outwat.in
      The outwat.in file is read in, unmodified, and RDB output
      is passed along standard output.  You can capture this
      out put by adding "> rdb.out" to the command line in the
      usual Unix fashion.
   
   % outwat2rdb.pl outwat.in rdb.out
      See previous, only an rdb.out output file is create.  If 
      this file exists it will be overwritten without confirmation.
      
   % outwat2rdb.pl
      This man page.   

 INPUT FILE FORMAT
   The following six lines provide the input format for processing.
   The ': ' string indicates lines in the input file.
   The file is delimited by one or more spaces.  The "---..." line is 
   not echoed on the output and the column label line is modified.
   The YEAR, MONTH, DAY, and MINUTE columns are combined into a
   much more Tkg2 suitable DATE string.  One or more VALUE columns are
   retained as one would expect.
   
  : TIME SERIES RECORD
  :
  : NAME              YEAR     MONTH      DAY        MINUTE      VALUE
  : ---------------------------------------------------------------------
  : precip_intensity   1999       1       23         1234.7      0
  : precip_intensity   1999       1       23         1234.85     4.00

 OUTPUT FILE FORMAT
   The following six lines are matching output for the above example.
   The ': ' string indicates lines in the input file.
   
  : # TIME SERIES RECORD
  : #
  : NAME    DATE    VALUE
  : s       d       n
  : precip_intensity        01/23/1999 20:34:41     0
  : precip_intensity        01/23/1999 20:34:50     4.00
  
 AUTHOR                    William H. Asquith <wasquith\@usgs.gov>
                           Hydrologist
                           USGS, Austin, Texas
   
 DATE                      September 17, 2001
 
HERE
;
  exit;
}


1;
