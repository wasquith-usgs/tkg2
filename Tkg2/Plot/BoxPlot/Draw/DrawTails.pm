package Tkg2::Plot::BoxPlot::Draw::DrawTails;

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
# $Date: 2007/09/14 17:45:29 $
# $Revision: 1.12 $

use strict;

use Exporter;

use vars qw( @ISA @EXPORT_OK );
@ISA       = qw( Exporter );
@EXPORT_OK = qw( _drawTails );

use Tkg2::Base qw(Show_Me_Internals);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createLineMetaPost);

print $::SPLASH "=";

sub _drawTails {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($lt_origin, $ut_origin, $boxdata, $plot, $canv, $x, $y,
       $tag, $boxstyle, $limits, $real_limits) = @_;

   my %para = %{ $boxstyle->{-tail} };

 
   my ($r_xmin, $r_ymin, $r_xmax, $r_ymax) = @$real_limits;
   my ($xmin, $ymin, $xmax, $ymax) = @$limits;
 
   # Can we actually draw any tails, if not return location coordinates to
   # the rest of the drawing
   my $orient = $boxstyle->{-orientation};
   my $lquart = $boxdata->{-lower_quartile};
   my $uquart = $boxdata->{-upper_quartile};
   if( not $para{-doit} ) { 
      return ( 1, $lt_origin, $ut_origin ) ;
   }

   my $type   = $para{-type};
   if( $type ne 'Range'
      and (   not defined $lquart
           or not defined $uquart
          ) ) {
      return ( 1, $lt_origin, $ut_origin );      
   }
      

   my $width  = $para{-width};
   
   my $range  = ($uquart - $lquart) unless($type eq 'Range');
   my ($x1, $y1, $x2, $y2);
   my ($x1tail, $y1tail) = ($lt_origin, $lt_origin);
   my ($x2tail, $y2tail) = ($ut_origin, $ut_origin);
   
   my ($lt_limit, $ut_limit); 
   
   my @coords_line1;
   my @coords_line2;
   
   my $xref   = $plot->{-x};
   my $yref   = $plot->{-y};
   my $xtype  = $xref->{-type};
   my $ytype  = $yref->{-type};
   my $revx   = $xref->{-reverse};
   my $revy   = $yref->{-reverse};
   
   my $min = $boxdata->{-min};
   my $max = $boxdata->{-max};
   if($orient eq 'vertical') {
      if($type eq '3*IQR') {
         $y1 = $lquart - 3*$range;
         $y2 = $uquart + 3*$range;
         # if the 3*IQR extends beyond range of data, reset it to range
         $y1 = $min if($y1 < $min);
         $y2 = $max if($y2 > $max);
      }
      elsif($type eq '1.5*IQR') {
         $y1 = $lquart - 1.5*$range;
         $y2 = $uquart + 1.5*$range;
         # if the 1.5*IQR extends beyond range of data, reset it to range
         $y1 = $min if($y1 < $min);
         $y2 = $max if($y2 > $max);
      }
      else {
         $y1 = $min;
         $y2 = $max;
      }
      $y1 = ( $y1 < $r_ymin ) ? $r_ymin :
            ( $y1 > $r_ymax ) ? $r_ymax : $y1; 
      $lt_limit = $y1;
      $y1 = $plot->transReal2CanvasGLOBALS('Y', $ytype, 1, $y1);     
      $y1 = $plot->revAxis('-y', $y1) if($revy);
      
      $y2 = ( $y2 < $r_ymin ) ? $r_ymin :
            ( $y2 > $r_ymax ) ? $r_ymax : $y2; 
      $ut_limit = $y2;
      $y2 = $plot->transReal2CanvasGLOBALS('Y', $ytype, 1, $y2);
      $y2 = $plot->revAxis('-y', $y2) if($revy);
      
      $y1tail = ( $y1tail < $r_ymin ) ? $r_ymin :
                ( $y1tail > $r_ymax ) ? $r_ymax : $y1tail; 
      $y1tail = $plot->transReal2CanvasGLOBALS('Y', $ytype, 1, $y1tail);     
      $y1tail = $plot->revAxis('-y', $y1tail) if($revy);
      
      $y2tail = ( $y2tail < $r_ymin ) ? $r_ymin :
                ( $y2tail > $r_ymax ) ? $r_ymax : $y2tail; 
      $y2tail = $plot->transReal2CanvasGLOBALS('Y', $ytype, 1, $y2tail);
      $y2tail = $plot->revAxis('-y', $y2tail) if($revy);
      
      @coords_line1 = ($x, $y1, $x, $y1tail);
      @coords_line2 = ($x, $y2, $x, $y2tail);
   }
   else {
      if($type eq '3*quartile') {
         $x1 = $lquart - 3*$range;
         $x2 = $uquart + 3*$range;
         # if the 3*IQR extends beyond range of data, reset it to range
         $x1 = $min if($x1 < $min);
         $x2 = $max if($x2 > $max);
      }
      elsif($type eq '1.5*quartile') {
         $x1 = $lquart - 1.5*$range;
         $x2 = $uquart + 1.5*$range;
         # if the 1.5*IQR extends beyond range of data, reset it to range
         $x1 = $min if($x1 < $min);
         $x2 = $max if($x2 > $max);
      }
      else {
         $x1 = $min;
         $x2 = $max;
      }
      $x1 = ( $x1 < $r_xmin ) ? $r_xmin :
            ( $x1 > $r_xmax ) ? $r_xmax : $x1;
      $lt_limit = $x1;
      $x1 = $plot->transReal2CanvasGLOBALS('X', $xtype, 1, $x1);
      $x1 = $plot->revAxis('-x', $x1) if($revx);
      
      $x2 = ( $x2 < $r_xmin ) ? $r_xmin :
            ( $x2 > $r_xmax ) ? $r_xmax : $x2;
      $ut_limit = $x2;
      $x2 = $plot->transReal2CanvasGLOBALS('X', $xtype, 1, $x2);
      $x2 = $plot->revAxis('-x', $x2) if($revx);
      
      $x1tail = ( $x1tail < $r_xmin ) ? $r_xmin :
                ( $x1tail > $r_xmax ) ? $r_xmax : $x1tail;
      $x1tail = $plot->transReal2CanvasGLOBALS('X', $xtype, 1, $x1tail);
      $x1tail = $plot->revAxis('-x', $x1tail) if($revx);
      
      $x2tail = ( $x2tail < $r_xmin ) ? $r_xmin :
                ( $x2tail > $r_xmax ) ? $r_xmax : $x2tail;
      $x2tail = $plot->transReal2CanvasGLOBALS('X', $xtype, 1, $x2tail);
      $x2tail = $plot->revAxis('-x', $x2tail) if($revx);
         
      @coords_line1 = ($x1, $y, $x1tail, $y);
      @coords_line2 = ($x2, $y, $x2tail, $y);
   }
    
   my $canIdo = 1;
   my @dash = ();
   push(@dash, (-dash => $para{-dashstyle}) )
              if($para{-dashstyle} and
                 $para{-dashstyle} !~ /Solid/io);
   foreach (@coords_line1) { $canIdo = 0 if(not defined $_); }
   
   if($canIdo) {
      $canv->createLine(@coords_line1,
                        -fill  => $para{-linecolor},
                        -width => $para{-linewidth},
                        @dash,
                        -tags  => "$tag");
      createLineMetaPost(@coords_line1,
                         {-fill  => $para{-linecolor},
                          -width => $para{-linewidth},
                          @dash});
   }
   $canIdo = 1;                 
   foreach (@coords_line2) { $canIdo = 0 if(not defined $_); }
   if($canIdo) {
     $canv->createLine(@coords_line2,
                       -fill  => $para{-linecolor},
                       -width => $para{-linewidth},
                       @dash,
                       -tags  => "$tag");
     createLineMetaPost(@coords_line2,
                        {-fill  => $para{-linecolor},
                         -width => $para{-linewidth},
                         @dash});
   }
   ## END DRAWING OF TAILS
   
   
   # Begin drawing of whiskers
   my %whisk = %{$para{-whiskers}};
      $width = $whisk{-width}/2;
   if($whisk{-doit}) {
      my ( @coords1, @coords2 );
      my ($top, $bot);
      @dash = ();
      push(@dash, (-dash => $whisk{-dashstyle}) )
              if($whisk{-dashstyle} and
                 $whisk{-dashstyle} !~ /Solid/io);
   
      if($orient eq 'vertical') {
         ( $top, $bot ) = ( $x-$width, $x+$width );
         @coords1 = ($top, $y1, $bot, $y1);
         @coords2 = ($top, $y2, $bot, $y2);
      }
      else {
         ( $top, $bot ) = ( $y-$width, $y+$width );
         @coords1 = ($x1, $top, $x1, $bot);
         @coords2 = ($x2, $top, $x2, $bot);
      }
      my @args = ( -fill  => $whisk{-linecolor},
                   -width => $whisk{-linewidth},
                   @dash,
                   -tags  => "$tag" );
                   
      $canv->createLine( @coords1, @args );
      createLineMetaPost( @coords1, {@args} );
      $canv->createLine( @coords2, @args );
      createLineMetaPost( @coords2, {@args} );
   }
   # End drawing of whiskers
   
                    
   return (1, $lt_limit, $ut_limit);
}


1;
