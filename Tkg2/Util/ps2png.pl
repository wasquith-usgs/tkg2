#!/usr/bin/perl -w
#
# ps2png.pl [options] file(s)...
#
# Convert a postscript file to PNG. The resolution defaults to 85, which is a
# readable compromise for most screens. The files should be postscript files.
# You can omit a .ps suffix and we'll assume it.
#
# Author: John Chambers <jc@trillian.mit.edu>
# Extensively Modified: William H. Asquith <wasquith@usgs.gov>

# ps2png.pl is a perl wrapper on ghostscript and wpng to convert postscript
# to png files.  This program was borrowed from John Chambers and modified
# extensively by William H. Asquith for his tkg2 2-D Perl/Tk charting program
# Tkg2 does not expect ps2png.pl to reside along PATH, but instead is to
# reside in the Tkg2/Util directory.  This is done so that tkg2 always knows
# where to find this script and furthermore other ps2png convertors might
# lie along PATH.  So they will not be clobbered.  Yes, the .pl extension
# provides some protection, but why not be safe.

# Dependencies:  Ghostscript (version?), and wpng (write png).
#   Each of the dependencies need to lie on the PATH

# $Author: wasquith $
# $Date: 2000/10/11 20:55:11 $
# $Revision: 1.7 $

use strict;
use vars qw(%CMD);
use Getopt::Long;


# John what does this do???
$ENV{LD_LIBRARY_PATH} = '/usr/X11R6/lib/:/usr/eecs/lib:/usr/lib:/usr/lib/aout';
# Would this comment out section be safer
# my $LD_LIBRARY_PATH_old = $ENV{LD_LIBRARY_PATH};
# $ENV{LD_LIBRARY_PATH} = '/usr/X11R6/lib/:/usr/eecs/lib:/usr/lib:/usr/lib/aout';
# .. code runs to exit ..
# $ENV{LD_LIBRARY_PATH} = $LD_LIBRARY_PATH_old;


my @options = qw(
                  help
                  resolution=i
                  papersize=s
                );
&GetOptions(\%CMD, @options);

if($CMD{'help'} or not @ARGV) {
   print STDOUT <<"HERE";

ps2png.pl: A postscript to PNG conversion utility
    
  Usage: % ps2png.pl [options] [files]
  
  Options:
        --help        This help.
        
        --resolution  Output resolution in pixels/inch. The default is 85.
        
        --papersize   The rough papersize of the postscript file. Must be
                      approximately equal to or larger than the file
                      itself.  Too small a pagesize throws exceptions and
                      core dumps(?).  Too large a pagesize consumes CPU
                      during the cropping process.  By cropping, we mean
                      that the null columns and rows are nicely cropped
                      for the final PNG output.  The default papersize is
                      'letter'.  --papersize=a0 (33.0556x46.7778 inches)
                      should cover most situtations reasonable situations
                      as this is the largest(?) papersize directly
                      supported by ghostscript (see man gs).  If the
                      papersize is specified as WWxHH in inches, then the
                      script converts these to pixels by multiplying by
                      the resolution.

  Dependencies:
    Ghostscript
    pnmcrop  (provided by ghostscript?)
    wpng     (provided by PNG, The Definitive Guide, O\'Reilly,
              http://
    
  Authors:
    
    Original--
       John Chambers, <jc\@trillian.mit.edu>
    
    Current Version, used by Tkg2 (Asquith) --
       William H. Asquith <wasquith\@usgs.gov>
    
HERE
;
   exit;
}

my $resolution = ($CMD{'resolution'}) ? int($CMD{'resolution'}) : 85;
my $papersize  = ($CMD{'papersize'} ) ? $CMD{'papersize'}  : 'letter';

print STDERR "\nps2png.pl Status: res=$resolution, papersize=$papersize\n";
print STDERR   "     Input Files: @ARGV\n";
FILE: foreach my $file (@ARGV) {
   print STDERR "ps2png.pl Status: converting $file\n";
   my $fili = "";  # initialize the input
   my $filo = "";  # and output files
   if($file =~ /(.*)\.(\w*ps)$/i) { # if file is *.ps, *.eps or *.?ps
      $fili = $file;    # set the input file to the loop
      $filo = "$1.png"; # cat .png to the end of the file name
   }
   else { # the input file did not have a ps at the end
      # -f tests for a plain file, so if $file.ps then filo is file.png
      $filo = (-f ($fili = "$file.ps" )) ? "$file.png" :
              (-f ($fili = "$file.eps")) ? "$file.png" :
              (-f ($fili = "$file.PS" )) ? "$file.PNG" : "";
      if(not $filo) {
         print STDERR "ps2png.pl Status: Postscript file '$file' not ",
                      "found.  Could not create output file name\n";
         next FILE;
      }
   }
   
   # Trick here is that gs produces ppmraw files which care easily(?)
   # converted to postscript.
   my $command = "gs -q -DNOPAUSE -sDEVICE=ppmraw -r$resolution ";
   if($papersize =~ m/(\d|\.)+x(\d|\.)+/io) {
      my ($width, $height) = split(/x/o, $papersize, 2);
      $width  = "" unless(defined $width);  # set to null to avoid uninit value
      $height = "" unless(defined $height); # warnings as a paranoid precaution
      die "ps2png.pl: bad width='$width'"   if(not $width  or $width  <= 0);
      die "ps2png.pl: bad height='$height'" if(not $height or $height <= 0);
      $width  *= $resolution;
      $height *= $resolution;
      # it seems through testing that ghostscript really prefers to have integer
      # papersize when in pixels  960x700.5 will work, but 960.5x700 will not
      # so wha concludes that ghostscript inconsistently parsed the -g option
      my $gcom = "-g".int($width)."x".int($height);
      system("$command $gcom -sOutputFile='| pnmcrop | wpng >$filo' -- $fili");
   }
   else {
      system($command.
             "-sPAPERSIZE=$papersize ".
             "-sOutputFile='| pnmcrop | wpng >$filo' -- $fili");
   }
   
   if($?) {
      print STDERR "ps2png.pl Status: Conversion of '$fili' ",
                   "failed with exit status $?.\n";
      exit $?;
   }
}

__END__
Other variations on the system calls that need evaluation
-sOutputFile='| pnmcrop | wpng >$filo'
-sOutputFile='| pnmcrop | pnmmargin -white 10 | wpng >$filo'
-sOutputFile='| pnmcrop | pnmmargin -white 10 | pnmtopng >$filo'
