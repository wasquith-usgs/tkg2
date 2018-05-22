package Tkg2::DeskTop::Rendering::RenderPNG;

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
# $Date: 2005/02/23 17:57:47 $
# $Revision: 1.14 $

use strict;
use File::Basename;
use Cwd;
use Tkg2::Base qw(Show_Me_Internals);
use Tkg2::DeskTop::Rendering::RenderPS;
use Exporter;
use SelfLoader;

use vars     qw( @ISA @EXPORT $LASTSAVEDIR );
@ISA    = qw( Exporter SelfLoader );
@EXPORT = qw( RenderPNG );

print $::SPLASH "=";


1;
__DATA__

sub RenderPNG {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   # do not remove shifts
   my ($template, $canv, $options) = (shift, shift, shift);

   my $res = $options->{-resolution};
      $res ||= 100;
   
   my $tmpps = "xxxxxxxtkg2tmp";  # temporary postscript file name
   my $filetypes = [ [ 'PNG',        [ '.png'  ] ],
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
      $file = $tw->getSaveFile(-title      => "Save $canvasname as PNG",
                               -initialdir => $dir2save,
                               -filetypes  => $filetypes );
   }
   else {
      $file = $tw->getSaveFile(-title      => "Save Canvas as PNG",
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
   
   $file .= ".png" if($file !~ m/.+\.png$/o);

   &RenderPostscript($template, $canv, "$tmpps");
   
   my $width      = $template->{-width};
   my $height     = $template->{-height};

   my $papersize = ($template->{-postscript}->{-rotate}) ? 
                    $height."x".$width : $width."x".$height;

   &correctTkPostscript($tmpps);

   # Run the postscript to PNG conversion
   my $command;
   if($::TKG2_ENV{-OSNAME} ne 'MSWin32') {
     $command = "gs -dNOPAUSE -sDEVICE=png256 -r$res -sOutputFile=$file -q -dBATCH $tmpps";
     print $::VERBOSE " EXTERNAL_COMMAND: $command\n";
     system($command);
   }
   unlink($tmpps); # remove the temporary postscript
   if(not -e $file) {
      print STDERR "Tkg2-warning: Could not build a png file from postscript.\n",
                   "  This feature is not implemented on MSWin32 machines.\n";
      return 0;
   }
   return $file;
}

1;
