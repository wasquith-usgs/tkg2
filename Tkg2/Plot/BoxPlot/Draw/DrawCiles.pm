package Tkg2::Plot::BoxPlot::Draw::DrawCiles;

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
# $Date: 2007/09/14 17:45:28 $
# $Revision: 1.11 $

use strict;

use Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT_OK = qw(_drawCiles);

use Tkg2::Base qw(Show_Me_Internals);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createRectangleMetaPost);

print $::SPLASH "=";

sub _drawCiles {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($cile, $boxdata, $plot, $canv, $x, $y, $tag, $boxstyle,
       $limits, $real_limits) = @_;

   my %para    = %{ $boxstyle->{"-"."$cile"} };

   return (0,undef,undef) unless($para{-doit});
 
   my ( $r_xmin, $r_ymin, $r_xmax, $r_ymax ) = @$real_limits;
   my ( $xmin, $ymin, $xmax, $ymax )         = @$limits;
 
   my $orient = $boxstyle->{-orientation};
   my $type   = $para{-showtype};
   my $width  = $para{-width}/2;
   
   my ($x1, $y1, $x2, $y2);
   
   my $xref   = $plot->{-x};
   my $yref   = $plot->{-y};
   my $xtype  = $xref->{-type};
   my $ytype  = $yref->{-type};
   my $revx   = $xref->{-reverse};
   my $revy   = $yref->{-reverse};
   
   my ($lt_origin, $ut_origin);
   
   if($orient eq 'vertical') {
      $y1 = $boxdata->{"-lower_"."$cile"};
      return (0, undef, undef) unless(defined $y1);
      
      $y1 = ( $y1 < $r_ymin ) ? $r_ymin :
            ( $y1 > $r_ymax ) ? $r_ymax : $y1; 
      $lt_origin = $y1;
      $y1 = $plot->transReal2CanvasGLOBALS('Y', $ytype, 1, $y1);     
      $y1 = $plot->revAxis('-y',$y1) if($revy);
      
      $y2 = $boxdata->{"-upper_"."$cile"};
      return (0, undef, undef) unless(defined $y2);
      
      $y2 = ( $y2 < $r_ymin ) ? $r_ymin :
            ( $y2 > $r_ymax ) ? $r_ymax : $y2;
      $ut_origin = $y2; 
      $y2 = $plot->transReal2CanvasGLOBALS('Y', $ytype, 1, $y2);
      $y2 = $plot->revAxis('-y',$y2) if($revy);
      
      ($x1, $x2) = ($x-$width, $x+$width);
      $x1 = ( $x1 < $xmin ) ? $xmin :
            ( $x1 > $xmax ) ? $xmax : $x1;
      $x2 = ( $x2 < $xmin ) ? $xmin :
            ( $x2 > $xmax ) ? $xmax : $x2;
   }
   else {
      $x1 = $boxdata->{"-lower_"."$cile"};
      return (0, undef, undef) unless(defined $x1);
      
      $x1 = ( $x1 < $r_xmin ) ? $r_xmin :
            ( $x1 > $r_xmax ) ? $r_xmax : $x1;
      $lt_origin = $x1;
      $x1 = $plot->transReal2CanvasGLOBALS('X', $xtype, 1, $x1);
      $x1 = $plot->revAxis('-x',$x1) if($revx);
      
      $x2 = $boxdata->{"-upper_"."$cile"};
      return (0, undef, undef) unless(defined $x2);
      
      $x2 = ( $x2 < $r_xmin ) ? $r_xmin :
            ( $x2 > $r_xmax ) ? $r_xmax : $x2;
      $ut_origin = $x2;
      $x2 = $plot->transReal2CanvasGLOBALS('X', $xtype, 1, $x2);
      $x2 = $plot->revAxis('-x',$x2) if($revx);
         
      ($y1, $y2) = ($y-$width, $y+$width);
      $y1 = ( $y1 < $ymin ) ? $ymin :
            ( $y1 > $ymax ) ? $ymax : $y1; 
      $y2 = ( $y2 < $ymin ) ? $ymin :
            ( $y2 > $ymax ) ? $ymax : $y2; 
   }
      
   my @coords = ($x1, $y1, $x2, $y2 );   
   foreach (@coords) { return (0,undef,undef) if(not defined $_); }
   my @dash = ();
   push(@dash, (-dash => $para{-dashstyle}) )
              if($para{-dashstyle} and
                 $para{-dashstyle} !~ /Solid/io);   
   $canv->createRectangle(@coords,
                          -fill    => $para{-fillcolor},
                          -outline => $para{-linecolor},
                          -width   => $para{-linewidth}, @dash,
                          -tags    => $tag);
   createRectangleMetaPost(@coords,
                          {-fill    => $para{-fillcolor},
                           -outline => $para{-linecolor},
                           -width   => $para{-linewidth}, @dash});
   
   return (1, $lt_origin, $ut_origin);
}

1;
