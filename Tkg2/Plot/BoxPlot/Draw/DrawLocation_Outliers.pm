package Tkg2::Plot::BoxPlot::Draw::DrawLocation_Outliers;

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
# $Revision: 1.11 $

use strict;
use Exporter;

use vars qw(@ISA @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT_OK = qw(_drawLocation _drawOutliers);

use Tkg2::Base qw(Show_Me_Internals);
use Tkg2::Draw::DrawPointStuff qw(_reallydrawpoints);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createLineMetaPost);

print $::SPLASH "=";

sub _drawLocation {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($boxdata, $plot, $canv, $x, $y, $tag, $boxstyle,
       $limits, $real_limits) = @_;
   my %para = %{ $boxstyle->{-location} };
   return 0 unless($para{-doit} and defined($x) and defined($y));
   
   my $orient   = $boxstyle->{-orientation};
   my $type     = $para{-showtype};
   
   my $width    = $para{-width}/2;
   
   my ($x1, $y1, $x2, $y2);
   
   my $xref      = $plot->{-x};
   my $yref      = $plot->{-y};
   my $xtype     = $xref->{-type};
   my $ytype     = $yref->{-type};
   my $revx      = $xref->{-reverse};
   my $revy      = $yref->{-reverse};
   
   if($type eq 'mean') {
      if($orient eq 'vertical') {  
         ($x1, $x2) = ($x-$width,$x+$width);
         $y1 = $y2  = $y;
      }
      else {
         $x1 = $x2  = $x;
         ($y1, $y2) = ($y-$width,$y+$width);
      }
   }
   else {
      my $location = $boxdata->{-median};
      if($orient eq 'vertical') {
         my $newy = $plot->transReal2CanvasGLOBALS('Y', $ytype, 1, $location);
         return 0 unless(defined $newy);
         $newy = $plot->revAxis('-y',$newy) if($revy);
         $y1 = $y2 = $newy;
         ($x1, $x2) = ($x-$width,$x+$width);
      }
      else {
         my $newx = $plot->transReal2CanvasGLOBALS('X', $xtype, 1, $location);
         return 0 unless(defined $newx);
         $newx = $plot->revAxis('-x',$newx) if($revx);
         $x1 = $x2  = $newx;
         ($y1, $y2) = ($y-$width,$y+$width);
      }
   }
      
   $canv->createLine($x1, $y1, $x2, $y2,
                     -fill  => $para{-linecolor},
                     -width => $para{-linewidth},
                     -tags  => "$tag");
   createLineMetaPost($x1, $y1, $x2, $y2,
                      {-fill  => $para{-linecolor},
                       -width => $para{-linewidth}});


   # Now optionally draw the symbol on the location line
   %para = %{ $para{-symbology} };
   return 0 unless($para{-doit} and defined($x) and defined($y));     
   
   my $attr = { -symbol       => $para{-symbol},
                -size         => $para{-size},
                -angle        => $para{-angle},
                -outlinecolor => $para{-outlinecolor},
                -outlinewidth => $para{-outlinewidth},
                -fillcolor    => $para{-fillcolor} }; 
   
   if($orient eq 'vertical') {
      # y1 = y2
      &_really_draw_points_on_box($plot,$canv,($x1+$width),$y1,$attr,'Y',0);
   }
   else {
      # x1n = x2
      &_really_draw_points_on_box($plot,$canv,$x1,($y1+$width),$attr,'X',0);
   }


   return 1;
}


sub _drawOutliers {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($outliertype, $boxdata, $plot, $canv, $x, $y,
       $tag, $boxstyle, $limits, $real_limits) = @_;

   my %para    = %{ $boxstyle->{$outliertype} };
    
   return (0,undef,undef) unless($para{-doit});
   
   my ($r_xmin, $r_ymin, $r_xmax, $r_ymax) = @$real_limits;
   
   my $orient = $boxstyle->{-orientation};
   
   my $attr = { -symbol       => $para{-symbol},
                -size         => $para{-size},
                -angle        => $para{-angle},
                -outlinecolor => $para{-outlinecolor},
                -outlinewidth => $para{-outlinewidth},
                -fillcolor    => $para{-fillcolor} }; 
   
   my $outliers = $boxdata->{$outliertype};
   my @outliers = @$outliers;
   
   foreach my $val (@outliers) {
      if($orient eq 'vertical') {
         my $newy = $val;
         &_really_draw_points_on_box($plot,$canv,$x,$newy,$attr,'Y',1);
         
      }
      else {
         my $newx = $val;
         &_really_draw_points_on_box($plot,$canv,$newx,$y,$attr,'X',1);
      }
   }
   
   my ($low, $up) = ($outliers[0], $outliers[$#outliers]);
   if($orient eq 'vertical') {
      if(defined $low) {
         $low = ($low < $r_ymin ) ? $r_ymin : ($low > $r_ymax) ? $r_ymax : $low; 
      }
      if(defined $up) {
         $up  = ($up  < $r_ymin ) ? $r_ymin : ($up  > $r_ymax) ? $r_ymax : $up ; 
      }
   }
   else {
      if(defined $low) {
         $low = ($low < $r_xmin ) ? $r_xmin : ($low > $r_xmax) ? $r_xmax : $low;
      }
      if(defined $up) {
         $up  = ($up  < $r_xmin ) ? $r_xmin : ($up  > $r_xmax) ? $r_xmax : $up ;
      }
   }
   # the returned low and up are the limits of the outliers seen on the 
   # plot in REAL WORLD units
   return (1,$low,$up);
}


sub _really_draw_points_on_box {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($plot,$canv, $x, $y, $para, $which, $trans_toggle) = @_;
   if($trans_toggle) {
      if($which =~ /y/io) {
         my $yref   = $plot->{-y};
         my $ytype  = $yref->{-type};
         my $revy   = $yref->{-reverse};
         $y  = $plot->transReal2CanvasGLOBALS('Y', $ytype, 1, $y); 
         $y = $plot->revAxis('-y',$y) if($revy);
         return 0 if(not defined $y);
      }
      else {
         my $xref   = $plot->{-x};
         my $xtype  = $xref->{-type};
         my $revx   = $xref->{-reverse};
         $x = $plot->transReal2CanvasGLOBALS('X', $xtype, 1, $x); 
         $x = $plot->revAxis('-x',$x) if($revx);   
         return 0 if(not defined $x);
      }
   }
   &_reallydrawpoints($canv, $x, $y, ["$plot", $plot."specialplot"], $para);  
}

1;
