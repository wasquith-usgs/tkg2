#!/usr/bin/perl -w

=head1 LICENSE

 This program is authored by the enigmatic William H. Asquith.
     
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
# $Date: 2002/03/11 22:42:36 $
# $Revision: 1.8 $

use constant S0     => scalar 0;
use constant S0d015 => scalar 0.015;
use constant S2     => scalar 2; 
use constant S10    => scalar 10;
use constant S1000  => scalar 1000; 
 
my $isFrame = 0;
my $cmnt  = " COMMENTED OUT BY tkmiffix.pl";
my $modf  = " MODIFIED BY tkmiffix.pl";
my $added = " ADDED BY tkmiffix.pl";

die "DIED: tkmiffix.pl: mif file not specified on the command line.\n"
   unless(@ARGV);

# Input file   
my $fili  = shift;
open(IFH, "<$fili") or
     die "DIED: tkmiffix.pl: '$fili' not opened because $!.\n";

# Output file
my $filo  = "$fili"."2";
open(OFH, ">$filo") or
     die "tkmiffix.pl status: '$filo' not opened because $!.\n";

LINE: while(<IFH>) {
   if($. == S2) {
      my $time = localtime;
      print OFH <<HERE;
<Comment   Metafile Title:      "tkg2 | pstoedit | tkmiffix.pl : $time">
<Comment   Metafile Descriptor: "MIF output from TKG2">
<Comment   Picture Title:       "--- FrameMaker ---">
HERE
;
   }
   
   # PAGE OPERATIONS
   # Comment out the portions in the MIF file refering to Page
   # with these removed the graphics are placed into a Frame at the
   # cursor insertion point in the page
   if(m/(^\s*<Page)|(^> # end of Page)/o) {
      chomp;
      print OFH "# $_       # $cmnt\n";
      next LINE; 
   }
   # END OF PAGE OPERATIONS

   # FRAME OPERATIONS
   # Remove the bounding Frame--inconvenient for hand loading and typesetting
   # in Framemaker.  Perhaps the Frame is useful for massive batch processing?
   if(m/^<Frame/o) {
      chomp;
      print OFH "# $_       # $cmnt\n";
    
      foreach my $line (1..6) {
         $_ = <IFH>;
         chomp;
         print OFH "# $_       # $cmnt\n";
      }
      
      next LINE;
   }
   
   if(m/^> # end of Frame/o) {
      chomp;
      print OFH "# $_       # $cmnt\n";
      next LINE; 
   }

   # squeeze the Bounding rectangle of the Frame in by 10 points
   # this makes it easier to select and drag the Frame around on 
   # the page when the page is the exact same size as the MIF file
   #if(($spaces, @pts) = $_ =~ m/(\s*)<BRect(.+)pt(.+)pt(.+)pt(.+)pt/o) {
   #  $pts[0] += S10;
   #  $pts[1] += S10;
   #  $pts[2] -= S10;
   #  $pts[3] -= S10;
   #  foreach my $pt (@pts) {
   #     $pt .= " pt";
   #  }
   #  print "$spaces<BRect @pts> # $modf\n";
   #  next LINE;
   #}

   # Replace the pstoedit request for a NotAnchored Frame to an Inline frame
   # $_ = "$1<FrameType Inline> # $modf\n" if(m/(\s*)<FrameType/o);

   # END OF FRAME OPERATIONS

   # STRING OPERATIONS
   # If we have a String tag in the mif file, potentially
   # replace all '$' not preceded by a '\' to 'e'.  Then 
   # substitude all '\$' pairs with $.  To get a literal
   # '\$' string prepend another '\' (\\$).
   if(($spaces) = $_ =~ m/(\s*)<String/o) {
      # the substitution is repeated twice to catch multiple $$ to ee.
      # I guess that I don't have it figured out as this is not a general
      # solution.
      s% ([^\\])\$ %$1e%xg; # replace non escaped '$' with 'e'
      s% ([^\\])\$ %$1e%xg; # replace non escaped '$' with 'e'
      s% \\\$      %\$%xg;  # replace '\$' with '$'
   
      # If the string has an <Angle \d+> sequence in it, grab the 
      # angle value and strip the sequence and add the
      # <Angle \d+> tag to the mif output
      print OFH "$spaces<Angle $2>      # $added\n"
                       if(s/<[Aa]ng(le)?\s*([-+]?\d+)\s*\\>//o);
   }
   
   # Replace all Font Sizes with a Integer
   if(($spaces, $size) = $_ =~ m/^(\s*)<FSize\s*([\d.]+)\s+pt>/o) {
      $size = int($size);
      $_    = "$spaces<FSize $size pt>   # FORCED INTEGER BY tkmiffix.pl\n";
   } 
   # END STRING OPERTATIONS
   
   
   # PEN WIDTH OPERATIONS
   if(($spaces, $size) = $_ =~ m/^(\s*)<PenWidth\s*([\d.]+)\s+pt>/o) {
      $size   = int(S1000*$size)/S1000;
      $size ||= S0d015; # Frame does not seem to accept 0 pen sizes
                        # when an object is edited once loaded as mif
                        # Frame will request a width between 0.015 and 360 pts
                        # on both Unix and Win32.
      $_ = "$spaces<PenWidth $size pt>   # CLEANED BY tkmiffix.pl\n";
   } 
   # END PEN WIDTH OPERATIONS
   
   # The final print statement to write the lines that
   # were already in the file.
   print OFH;
}
close(IFH);
close(OFH);
rename($filo,$fili);
exit;
