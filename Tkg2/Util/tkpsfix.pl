#!/usr/bin/perl -w

=head1 LICENSE

 This Tkg2 module is authored by the enigmatic William H. Asquith

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
# $Date: 2002/01/21 13:26:22 $
# $Revision: 1.6 $

use strict;
use File::Spec;
use File::Copy; 

my $home = $ENV{HOME};

my $mess = <<HERE
! Debugging for $0
! To not see this file, delete the .tkg2_tkpsfix_bug file in your
! home or $home directory.
! This file was created by the tkpsfix.pl script during that tkg2
! session in which a postscript rendering of the canvas was created.
! All tkg2 file exporting to other formats involves the creation
! of a postscript file--even if automatically deleted.  This file
! provides a list of a few lines of postscript from the last
! generated file.  The script tkpsfix strips the second translate
! command if the file is rotated.  This fixes almost all postscript
! rendering problems that have been encountered with tk postscript
! rendering, except some issues of portrait files on win32 systems.
! Here are the interesting lines
HERE
;

my $inf   = shift; # the postscript file name
my $outf .= "$inf.2";  # temporary file name for the postscript file

# debugging file
my $bug   = File::Spec->catfile($home,".tkg2_tkpsfix_debug");
   $bug   = (-e $bug) ? $bug : "/dev/null";
   
open(IN,  "<$inf" ) or die "$inf not opened because $!\n";
open(OUT, ">$outf") or die "$outf not opened because $!\n";
open(BUG, ">$bug" ) or die "$bug $!\n";

print BUG "$mess\n";

my ($Rotated, $Page) = ( 0, 0 ); # flags to control behavior
while(<IN>) { # reads each line into $_
   if(not $Page and m/^%%Page: 1 1/o) {
      $Page = 1; # set the flag to true
      print OUT; # print the '%%Page' line
      print BUG;
      $_ = <IN>; print OUT; print BUG; # read/print the 'save' line
      
      $_ = <IN>; print OUT; print BUG; # read/print first 'x y translate'
      
      $_ = <IN>; # read either a 'scale' or 'rotate' line
      if(m/rotate/o) {            # if the last read was a 'rotate'
         $Rotated = 1;            # set the flag to true
         print OUT; print BUG;    # print the 'rotate' line
         $_ = <IN>;               # then read the 'scale' line
      }
      print OUT;    print BUG;    # print the 'scale' line
      
      $_ = <IN>;                  # read second 'x y translate'
      if($Rotated) {  
         print OUT; print BUG; # print if the file was rotated
      }
      else {
        print BUG "# The next line was stripped from the postscript\n";
        print BUG $_; # print what was not rewritten to file'
      }
      next;
   }
   print OUT;
}

print BUG "! End of Interesting Lines\n";
print BUG "INFILE  = $inf\n";
print BUG "OUTFILE = $outf\n";

print BUG "Attempting to File::Copy \&move '$outf' to '$inf'\n";
&move("$outf", "$inf") or
     do { print BUG "\n";
          print BUG "File::Copy \&move of '$outf' to '$inf' failed because $!\n";
          warn "WARNING: $0 '$outf' not copied to '$inf' because $!\n";
          exit;
        };
print BUG "The move appears to have been successful\n";

# The rename function does not work across file systems.
# Although, the in file and out file are (should be) on the
# same system because we are just adding the .2 to the end of
# the name.  An earlier bug on the out file name discovered
# the problem with rename.  The Perl documentation does mention
# no cross file system operations.  It is hoped--but not 100%
# verified that the File::Copy is better behaved.
#print STDERR "$outf not renamed to $inf because $!\n"
#     if(not rename "$outf", "$inf" );

exit;
__END__
The Tk::Canvas postscript call seems to have a bug.  If the following page
settings to the call are made

 -pageanchor => 'nw',    
 -pagex      => 0,
 -pagey      => 0,
Then it is really simple to fix the generated postscript to work for non-letter
sized pages.  I have struggled for nearly a year to get consistent always
working oversized or undersize postscript and hence other graphic formats
working correctly.  Tkpsfix.pl is my best attempt yet.


Here are some details on how the tkpsfix.pl script works.  The following are the
relevant lines from a NON-rotated postscript file generated from the Tk::Canvas
postscript call.  Notice that the second translate seems to be entirely useless
and in fact often translates most if not all of the graphics off of the page
boundaries.  The tkpsfix.pl script strips the second translate command out.  
%%Page: 1 1
save
0.0 0.0 translate
1.506 1.506 scale
0 -405 translate

The following are the relevant lines from a rotated postscript file generated
from the Tk::Canvas postscript call.  In this case, for whatever reason the
second translate is necessary.  The X coordinate remains zero, but the Y
coordinate is negative and approximately equal to 1/2 of the page width.  I
guess that the rotate command rotates the image not about the center of the page,
but about the lower or upper edges.  I do not really know, but this script seems
to fix all postscript problems for all page sizes given the parameters as passed
to the postscript call.
%%Page: 1 1
save
0.0 0.0 translate
90 rotate
1.506 1.506 scale
0 -405 translate

