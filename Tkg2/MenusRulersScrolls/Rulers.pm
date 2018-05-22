package Tkg2::MenusRulersScrolls::Rulers;

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
# $Date: 2004/06/22 16:08:56 $
# $Revision: 1.13 $

use strict;

use Tk;

use Tkg2::Base qw(Show_Me_Internals deleteFontCache);

use Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);

@EXPORT_OK = qw(Rulers);

print $::SPLASH "=";

sub Rulers {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($template, $canv, $hcanv, $vcanv, $hedge, $vedge,
       $no_rulers_option_toggled) = @_;
   
   if($no_rulers_option_toggled) {
      # set empty subroutines for safety
      # draw the rulers to get grid snapping coordinates, but 
      # don't actually draw any rulers on the canvas.
      $template->{-markrulerEv} = sub { return; };
      $template->{-markrulerXY} = sub { return; };
      &_drawRulers($template,$hcanv, $vcanv, 0);   # zero says don't draw
      return;
   }
   
   my $_markrulerEv = sub {
                    my ($canv, $x, $y) = (shift, shift, shift);
                    $x = $canv->canvasx($x);
                    $y = $canv->canvasy($y);
                    ($x, $y) = $template->snap_to_grid($x,$y);
                    $hcanv->delete("rulerline");
                    $hcanv->createLine($x,0,$x,$hedge,
                                       -fill => 'red',
                                       -tag  => 'rulerline');
                    $vcanv->delete("rulerline");
                    $vcanv->createLine(0,$y,$vedge,$y,
                                       -fill => 'red',
                                       -tag => 'rulerline');
                    };
   my $_markrulerXY = sub {
                    my ($canv, $x, $y, $tag, $color) =
                             (shift, shift, shift, shift, shift);
                    $hcanv->delete($tag);
                    $vcanv->delete($tag);
                    $hcanv->createLine($x,0,$x,$hedge,
                                       -fill => $color,
                                       -tag  => $tag) if(defined $x );
                    $vcanv->createLine(0,$y,$vedge,$y,
                                       -fill => $color,
                                       -tag  => $tag) if(defined $y );
                    };
   $template->{-markrulerEv} = $_markrulerEv;
   $template->{-markrulerXY} = $_markrulerXY;
   $canv->Tk::bind("<Motion>", [ $template->{-markrulerEv}, Ev('x'), Ev('y')] );
   &_drawRulers($template,$hcanv, $vcanv, 1);   
}

sub _drawRulers {
   my ($template, $hcanv, $vcanv, $drawem) = @_;
   my $width  = $template->{-width};
   my $height = $template->{-height};
    
   # The first numeric argument is the length between successive
   # ticks on a ruler.  The second numeric argument is the length
   # the tick, and finally, the last argument is a logical that
   # determines whether the tick is to be labeled.
   my @hargs = ( $hcanv, 'x', $width  );
   &_really_drawRuler(@hargs,  1.000, 0.14,  1, $drawem );
   &_really_drawRuler(@hargs,   .500, 0.100, 0, $drawem  );
   &_really_drawRuler(@hargs,   .250, 0.050, 0, $drawem  );
   $template->{-x_grid} =
         &_really_drawRuler(@hargs, .125, 0.025, 0, $drawem  );
   
   my @vargs = ( $vcanv, 'y', $height );
   &_really_drawRuler(@vargs, 1.000, 0.14,  1, $drawem  );
   &_really_drawRuler(@vargs,  .500, 0.100, 0, $drawem  );
   &_really_drawRuler(@vargs,  .250, 0.050, 0, $drawem  );
   $template->{-y_grid} =
         &_really_drawRuler(@vargs, .125, 0.025, 0, $drawem  );     
}




sub _really_drawRuler {
   my ($canv, $which, $length, $step, $tick, $labelit, $drawem) = @_;
   $tick = $::MW->fpixels("$tick"."i");
   &deleteFontCache(); # Perl 5.8.3 and Tk 804.027 error trapping
   my $font = $canv->fontCreate("rulerfont",
                   -family => 'helvetica',
                   -size   => 9,
                   -weight => 'normal',
                   -slant  => 'roman') if($labelit);
                                
   my ($xhoffset, $xvoffset) = (.03,.06);
   $xhoffset = $::MW->fpixels("$xhoffset"."i");
   $xvoffset = $::MW->fpixels("$xvoffset"."i");
   my ($yhoffset, $yvoffset) = (.06,.07);
   $yhoffset = $::MW->fpixels("$yhoffset"."i");
   $yvoffset = $::MW->fpixels("$yvoffset"."i");
          
   my @grid;
   for (my $l=0; $l <= $length; $l += $step) {
      my $fl = $::MW->fpixels("$l"."i");
      push(@grid, $fl);
      next unless( $drawem);
      if($which =~ m/x/oi) {
         $canv->createLine($fl, 0, $fl, $tick);
         $canv->createText($fl+$xhoffset, $tick-$xvoffset,
              -text   => "$l",
              -font   => $font,
              -anchor => 'w') if($labelit and $l != $length);
      }
      else {
         $canv->createLine(0, $fl, $tick, $fl);
         $canv->createText($tick-$yhoffset, $fl+$yvoffset,
              -text   => "$l",
              -font   => $font,
              -anchor => 'w') if($labelit and $l != $length);
      }
   }
   $canv->fontDelete("rulerfont") if($labelit);
   return [ @grid ];
}


1;
