package Tkg2::DeskTop::Rendering::RenderPDF;

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
# $Date: 2016/02/29 17:13:56 $
# $Revision: 1.13 $

use strict;

use File::Basename;
use Cwd;
use Tkg2::Base qw(Show_Me_Internals);
use Tkg2::DeskTop::Rendering::RenderPS;
use Exporter;
use SelfLoader;

use vars     qw( @ISA @EXPORT $LASTSAVEDIR );
@ISA    = qw( Exporter SelfLoader );
@EXPORT = qw( RenderPDF);

print $::SPLASH "=";


1;
__DATA__


# Render Adobe Portable Document Format export file.
#   subroutine called from Tkg2Export (this module) or from 
#   batch in Batch.pm.
#  Requires that ghostscript or ps2pdf is available.
#  Suggested addition by Bruce Moring and Lynne Fahlquist, Austin, Texas
sub RenderPDF {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   # do not remove  shifts
   my ($template, $canv, $options ) = (shift, shift, shift);
   
   my $zoom   = $options->{-zoom};
      $zoom ||= 1;
   
   my $tmpps = "xxxxxxxtkg2tmpps";  # temporary postscript file name
   my $filetypes = [ [ 'PDF',        [ '.pdf'  ] ],
                     [ 'Tkg2 Files', [ '.tkg2' ] ],
                     [ 'All Files',  [ '*'     ] ]
                   ];
   my $file;
   my $tw = $canv->parent;
   
   my $dir2save = ($LASTSAVEDIR) ? $LASTSAVEDIR : $::TKG2_ENV{-USERHOME};
   my $nextarg = shift; # see if the export file name is provided
   if($nextarg and $nextarg ne "") {
      $file = $nextarg;
   }
   elsif($template->{-tkg2filename}) {
      my $canvasname = $template->{-tkg2filename};
      $file = $tw->getSaveFile(-title      => "Save $canvasname as PDF",
                               -initialdir => $dir2save,
                               -filetypes  => $filetypes );
   }
   else {
      $file = $tw->getSaveFile(-title      => "Save Canvas as PDF",
                               -initialdir => $dir2save,
                               -filetypes  => $filetypes );
   }
   $LASTSAVEDIR = "", return if(not defined $file or $file eq ""); 
   
   # logic to work out whether we should remember the directory
   my $dirname = &dirname($file);
   my $cwd     = &cwd;  # gives use a full path name without the '.'
   $LASTSAVEDIR = ($dirname eq '.') ? $cwd : $dirname;
   # Check to make sure that the directory does exist before we
   # allow the directory to be remembered
   $LASTSAVEDIR = "" unless(-d $LASTSAVEDIR);
   
   # make sure that a .pdf extension is tagged on
   $file .= ".pdf" if($file !~ m/.+\.pdf$/o);
   
   &RenderPostscript($template, $canv, $tmpps);
   
   my $width      = $template->{-width};
   my $height     = $template->{-height};
   
   my $pxlwidth   = $::MW->pixels($width."i");
   my $pxlheight  = $::MW->pixels($height."i");
   my $scaling    = $::MW->scaling;
   my $pxlperinch = int($scaling*1000*72*$zoom)/1000;
   
   &correctTkPostscript($tmpps);
   my $command;
   if($::TKG2_ENV{-OSNAME} eq 'darwin') {
     $command = "/usr/local/bin/ps2pdf $tmpps $file";
   }
   else {
     ($pxlwidth, $pxlheight) =
     ($pxlheight, $pxlwidth) if($template->{-postscript}->{-rotate});
   
     my $gcom     = "-g".$pxlwidth."x".$pxlheight;
     $command  = "gs -q -DNOPAUSE -sDEVICE=pdfwrite ".
                 "$gcom -r$pxlperinch ".
                 "-sOutputFile=$file -- $tmpps";
   }
   print $::VERBOSE " EXTERNAL_COMMAND: $command\n";
   system("$command");
          
   unlink($tmpps);
   if(not -e $file) {
      print STDERR "WARNING: Tkg2 could not build a pdf file, check that ",
                   "ghostscript is available for unix systems or ",
		   "that ps2pdf is available for MacOSX(darwin) ",
		   "systems.\n";
      return 0;
   }
   return $file;
}

1;
