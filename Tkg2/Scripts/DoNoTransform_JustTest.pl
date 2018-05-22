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
# $Date: 2002/08/07 18:29:25 $
# $Revision: 1.5 $


# Here is what the external program should look like on its front end and on its back end.
# Make all output along STDERR except for the successful 'External Program OK' on STDOUT.
# Note extreme use of dies.  Only the dumped hash is written back into the $file for thawing
# by the RouteData2Script_Actually_Perform subroutine.

use Data::Dumper;

my ($abscissa, $ordinates, $data) = &FrontEnd();

## GO ON TO PROCESS THE DATA HASH AS NEEDED

&BackEnd($data);




# SUBROUTINES
# FRONT END
sub FrontEnd {
   my $abscissa;
   my @ordinates;

   my $file = "tkg2R2S.tmp";
   open(FH,"<$file") or die "Could not open $file because $!\n";
   while(<FH>) {
     chomp;
     next if(/^#/);
     last if(/Data Dumper Hash/);
     my @line = split(/=/,$_,2);
     if($line[0] =~ /x/i) {
        die "$abscissa defined more than once?\n" if(defined($abscissa));
        $abscissa = $line[1];
     }
     elsif($line[0] =~ /y/i) {
        push(@ordinates, $line[1]);  
     }
     else {
        die "Could not identify @line as either X or Y key for data hash\n";
     } 
   }

   die "Abscissa is not defined\n" if(not defined($abscissa));
   die "No ordinates were defined\n" if(not @ordinates);

   local $/ = undef;
   my $data = <FH>; # slurp in rest of file
   close(FH) or die "Could not close $file because $!\n";
   die "Empty file returned from external program" if(not defined($data));
   eval { eval $data; }; 
   die "The eval did not work because $@\n" if($@);
 
   die "Abscissa $abscissa does not exists in data\n" if(not exists($data->{$abscissa}) );
   foreach my $ord (@ordinates) {
      die "Ordinate $ord does not exists in data\n" if(not exists($data->{$ord}) );
   }
   return ($abscissa, [ @ordinates ], $data); 
}



sub BackEnd {
   my $data = shift;
   my $file = "tkg2R2S.tmp";
   # DUMP THE PROCESSED AND HASH OUT TO $file
   $Data::Dumper::Indent = 1;
   open(FH, ">$file") or die "Could not open $file because $!\n";
   my $stuff = Data::Dumper->Dump([$data], [ qw(data) ]);
   print FH $stuff;
   close(FH) or die "Could not close $file because $!\n";

   print STDOUT "External Program OK";
   exit;
}
