package Tkg2::DeskTop::Rendering::RenderPS;

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
# $Revision: 1.15 $

use strict;

use Tkg2::Base qw(Show_Me_Internals);

use Exporter;
use SelfLoader;

use vars     qw( @ISA @EXPORT
                 $TKPSFIXPLX );
@ISA    = qw( Exporter SelfLoader );
@EXPORT = qw( correctTkPostscript
              RenderPostscript
            );


$TKPSFIXPLX = $::TKG2_ENV{-UTILITIES}->{-TKPSFIX_EXEC};

print $::SPLASH "=";

1;

__DATA__

# Main frontend to the Tk 'postscript' call.  This subroutine provides
# some setup to the postscript call and builds an postscript output file
# RenderPostscript is called by the other Render* subroutines since
# postscript is the only exporting format that Tk natively supports.
sub RenderPostscript {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($template, $canv, $file) = ( shift, shift, shift );

   # setting the page sizes
   my $width     = $template->{-width};
   my $height    = $template->{-height};
   # The addition of two more pixels on the height and width seems to
   # make the rendering to other formats work better
   my $pxlwidth  = int($::MW->fpixels($width."i" )+2);
   my $pxlheight = int($::MW->fpixels($height."i")+2);  
   my $scaling   = $::MW->scaling();
   
   # delete any of the selection rectangles that might be left on
   # the canvas after a mouse event
   $canv->delete('selectedplot','selectedanno','rectexplan');
   $::DIALOG{-SELECTEDPLOT} = "";  # since selectedplot delete, must reset
   
   if(not defined $file ) {
      print STDERR "Tkg2-Warning: A file to dump postscript to is undefined or null.\n",
                   "      Returning from RenderPostscript.\n";
      return;
   }
   else {
      unlink("$file") if(-e "$file");  # delete the forthcoming postscript file
   }
   
   # First remove the current background, draw again, and then lower it
   # I do not remember exactly why this was necessary, but not a big deal
   my $bgcolor = $template->{-color};
   $canv->delete("background");
   $canv->createRectangle(0,0,$pxlwidth,$pxlheight,
                          -fill    => $bgcolor,
                          -outline => $bgcolor,
                          -tags    => "background");
   $canv->lower("background");
   
   my $postref   = $template->{-postscript};
   my $rotate    = $postref->{-rotate};   
   my $colormode = $postref->{-colormode};
   
   print $::VERBOSE " Tkg2-RenderPostscript: $width x $height, $file, $colormode\n";
  
   # -pageheight => size
   # Specifies that the Postscript should be scaled in both x and y so
   # that the printed area is size high on the Postscript page. Size
   # consists of a floating-point number followed by c for centimeters,
   # i for inches, m for millimeters, or p or nothing for printer's
   # points (1/72 inch). Defaults to the height of the printed area on
   # the screen. If both -pageheight and -pagewidth are specified then
   # the scale factor from -pagewidth is used (non-uniform scaling is
   # not implemented).

   # -pagewidth => size
   # Specifies that the Postscript should be scaled in both x and y so
   # that the printed area is size wide on the Postscript page. Size has
   # the same form as for -pageheight. Defaults to the width of the
   # printed area on the screen. If both -pageheight and -pagewidth are
   # specified then the scale factor from -pagewidth  is used
   # (non-uniform scaling is not implemented).

   # -colormode => mode
   # Specifies how to output color information.  Mode must be either
   # color (for full color output), gray (convert all colors to their
   # gray-scale equivalents) or mono (convert all colors to black or white).

   my %pscom = ( -file       => $file,
                 -rotate     => $rotate,
                 -pageheight => $height."i",
                 -pagewidth  => $width."i",
                 -colormode  => $colormode );
                 
   # -height => size
   # Specifies the height of the area of the canvas to print. Defaults
   # to the height of the canvas window.
   $pscom{-height} = $pxlheight;
   
   # -width => size
   # Specifies the width of the area of the canvas to print. Defaults
   # to the width of the canvas window.
   $pscom{-width}  = $pxlwidth;
   
   # -x => position
   # Specifies the x-coordinate of the left edge of the area of the
   # canvas that is to be printed, in canvas coordinates, not window
   # coordinates. Defaults to the coordinate of the left edge of the window.
   $pscom{-x} = 0;

   # -y => position
   # Specifies the y-coordinate of the top edge of the area of the
   # canvas that is to be printed, in canvas coordinates, not window
   # coordinates. Defaults to the coordinate of the top edge of the window.
   $pscom{-y} = 0;
   
   
   # -pageanchor => anchor
   # Specifies which point of the printed area of the canvas should
   # appear over the positioning point on the page (which is given by
   # the -pagex and -pagey options). For example, -pageanchor=>n means
   # that the top center of the area of the canvas being printed (as it
   # appears in the canvas window) should be over the positioning point.
   # Defaults to center.
   $pscom{-pageanchor} = 'nw';    
   
   # -pagex => position
   # Position gives the x-coordinate of the positioning point on
   # the Postscript page, using any of the forms allowed for -pageheight.
   # Used in conjunction with the -pagey and -pageanchor options to
   # determine where the printed area appears on the Postscript page.
   # Defaults to the center of the page.
   $pscom{-pagex} = 0;

   # -pagey => position
   # Position gives the y-coordinate of the positioning point on
   # the Postscript page, using any of the forms allowed for -pageheight.
   # Used in conjunction with the -pagex and -pageanchor options to
   # determine where the printed area appears on the Postscript page.
   # Defaults to the center of the page.
   $pscom{-pagey} = 0;
                  
   #map { print $::BUG "$_ => $pscom{$_}\n" } sort keys %pscom
   #            if($::TKG2_CONFIG{-DEBUG});
   
   $canv->postscript(%pscom);
   if(not -e $file) {
      print $::VERBOSE " Tkg2-RenderPostscript: PS file '$file' not created.\n";
      return 0;
   }
   else {
      return 1;
   }
}


sub correctTkPostscript {
  &Show_Me_Internals(@_) if($::CMDLINEOPTS{'showme'});
  
  my $psfile = shift;

  print $::VERBOSE " Tkg2-correctTkPostscript for psfile = $psfile\n";
  
  if(not defined $psfile or $psfile eq "") {
     print STDERR "Tkg2-Warning: file for correctTkPostscript is undefined.\n";
     return;
  }
  elsif(not -e $psfile) {
     print STDERR "Tkg2-Warning: file for correctTkPostscript does not exist.\n";
     return;
  }
  
  if( $::TKG2_ENV{-UTILITIES}->{-BYPASS_PSFIX} ) {
     print STDERR "%% Tkg2 has bypassed the tkpsfix.pl script\n",
                  "%% The postscript is raw from the Tk toolkit.\n";
  }
  else {
     system("$TKPSFIXPLX $psfile");
  }

}

1;
