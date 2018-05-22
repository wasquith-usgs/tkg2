#!/usr/bin/perl -w
use strict;

# $Author: wasquith $
# $Date: 2009/03/16 17:42:25 $
# $Revision: 1.1 $


use GD::Image;

use Getopt::Long;
my %OPTS    = (); # command line options
my @options = qw(help verbose pxin=i
                 xoff=f yoff=f
                 x1=f   y1=f
                 x2=f   y2=f
                 rot90 rot180 rot270);
              # these are the valid command line options
&GetOptions(\%OPTS, @options); # parse the command line options

&Help(), exit if($OPTS{help}); # do help and exit

my $verbose = ($OPTS{verbose}) ? "/dev/stderr" : "/dev/null";
open(VERBOSE, ">$verbose") or die "DIED: $verbose not opened because $!\n";


my $infile = shift(@ARGV);
die "DIED: Must supply a PNG file as a command line argument\n"
   if(not defined $infile or not -e $infile);


open(PNG,$infile) or die "DIED: $infile not opened because $!\n";
my $image = newFromPng GD::Image(\*PNG) or
            die "DIED: newFromPng not working\n";
close(PNG);
print VERBOSE "STATUS: PNG source file $infile loaded\n";


my $outfile = (@ARGV) ? shift(@ARGV) : $infile;


my ($old_width, $old_height) = ($image->width, $image->height);
print VERBOSE "STATUS: Source PNG width and height: ".
              "{$old_width, $old_height} pixels\n";

my $pxin = ($OPTS{pxin}) ? $OPTS{pxin} : 1;
die "DIED: pxin of $pxin < 1" if($pxin < 1);

my $xoff = ($OPTS{xoff}) ? int($OPTS{xoff} * $pxin) : 0;
my $yoff = ($OPTS{yoff}) ? int($OPTS{yoff} * $pxin) : 0;
my $x1   = ($OPTS{x1}  ) ? int($OPTS{x1}   * $pxin) : 0;
my $y1   = ($OPTS{y1}  ) ? int($OPTS{y1}   * $pxin) : 0;
my $x2   = ($OPTS{x2}  ) ? int($OPTS{x2}   * $pxin) : $old_width;
my $y2   = ($OPTS{y2}  ) ? int($OPTS{y2}   * $pxin) : $old_height;

die "DIED: x1 >= x2" if($x1 >= $x2);
die "DIED: y1 >= y2" if($y1 >= $y2);

my ($new_width, $new_height) = ($x2 - $x1, $y2 - $y1);

die "DIED:  new width >  old width {$new_width  > $old_width}"
                                 if($new_width  > $old_width);
die "DIED: new height > old height {$new_height > $old_height}"
                                 if($new_height > $old_height);


print VERBOSE "STATUS: PNG output width and height: ".
              "{$new_width, $new_height} pixels\n";


my $new_image = new GD::Image($xoff + $new_width, $yoff + $new_height);
print VERBOSE "STATUS: New PNG image variable created\n";
$new_image->copy($image, $xoff, $yoff,
                 $x1,            $y1,
                 $x1+$new_width, $y1+$new_height);
print VERBOSE "STATUS: New PNG image created from special copying from source PNG\n";



$new_image = ($OPTS{rot90})  ? $new_image->copyRotate90()  :
             ($OPTS{rot180}) ? $new_image->copyRotate180() :
             ($OPTS{rot270}) ? $new_image->copyRotate270() : $new_image;
print VERBOSE "STATUS: Rotations made if requested\n";



open(OUTPUT, ">$outfile") or die "DIED: Error opening file $outfile for writing\n";
binmode(OUTPUT);
print OUTPUT $new_image->png(0);
close(OUTPUT) or die "DIED: Error closing file $outfile\n";
print VERBOSE "STATUS: Done\n";


sub Help {
print <<'HERE';

cropPNG.pl -- A PNG cropping utility built.
  by William H. Asquith
  
The script is convenient for cropping PNG files output from Tkg2. Tkg2 considers
a pixels per inch setting when making the conversion from the native postscript
output to the PNG format. Often users know the dimensions in page units (inches)
of the PNG file and not the pixels, which is generally more common. Therefore,
this program can work in inches of the page for cropping as well as pixels. The
input file is clobbered if the outfile is not provided.

   Usage: cropPNG.pl <options> infile.png [outfile.png]

   Options:
       --help       This help;
    
       --pxin=i     An optional integer representing pixels per unit distance
                    of the PNG, which typically would reflect the same setting
                    as used to create the PNG file. This option is needed if the
                    cropping-box settings are provided in units of distances
                    instead of pixels;

       --xoff=f     A potential floating point number of the distance untis or
       --yoff=f     pixels (pixels are cast to an integer) from upper-left corner
                    of the destination PNG in which the contents specified by the
                    [x1, y1, x2, y2] rectangle.  These options are simple 
                    offsets. If the cropping is made "right" these options
                    will likely not be used and default to zero;
       
       --x1=f       A potential floating point number of the distance units or
       --y1=f       pixels (pixels are cast to an integer) from the left (x1) or
                    top (y1) to begin the cropping rectangle. These default to
                    zero if not provided;

       --x2=f       A potential floating point number of the distance units or
       --y2=f       pixels (pixels are cast to an integer) from the left (x2) or
                    top (y2) to end the cropping rectangle. These default to
                    width or height, respectively of the source PNG if these
                    are not provided;

       --rot90      Rotate the new image  90 degrees;
       --rot180     Rotate the new image 180 degrees;
       --rot270     Rotate the new image 270 degrees;

       --verbose    Verbose output along STDERR;

   Example:  We have a PNG file called "exportedFromTkg2.png" rendered at
             90 pixels per inch for a papersize of 8.5 x 11 inches. We want
             to cut out 1.5 inches of the left, 1 inch from right (8.5 - 7.5),
             1 inch from top, and 5 inches from bottom (11 - 6). We also want
             to have the cropped PNG start at 0 from left, but about 0.65 inches
             or 58 pixels (0.65*90 as integer) from the top. We desire inplace
             manipulation of the PNG file so to output file is provided.
 
      cropPNG.pl --xoff=0 --yoff=0.65
                 --x1=1.5 --y1=1
                 --x2=7.5 --y2=6 --pxin=90 exportedFromTkg2.png

HERE
;
}
