package Tkg2::Plot::BoxPlot::BoxPlotDraw;

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
# $Date: 2002/08/07 18:32:21 $
# $Revision: 1.14 $

use strict;

use Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT_OK = qw(draw);

use Tkg2::Base qw(Show_Me_Internals);

use Tkg2::Plot::BoxPlot::Draw::DrawData  qw( _drawData  );
use Tkg2::Plot::BoxPlot::Draw::DrawCiles qw( _drawCiles );
use Tkg2::Plot::BoxPlot::Draw::DrawTails qw( _drawTails );
use Tkg2::Plot::BoxPlot::Draw::DrawText  qw( _drawText  );
use Tkg2::Plot::BoxPlot::Draw::DrawLocation_Outliers qw( _drawLocation
                                                         _drawOutliers );                                                        

print $::SPLASH "=";


sub draw {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($boxdata, $plot, $canv, $x, $y, $tag, $boxstyle, $yax) = @_;
 
   # All the methods will use essentially the same arguments
   my @bulkargs = ($boxdata, $plot, $canv, $x, $y, $tag, $boxstyle);
   
   # retrieve the canvas limits of the plot
   my ($xmin, $ymin, $xmax, $ymax) = $plot->getPlotLimits;
   push( @bulkargs, [$xmin, $ymin, $xmax, $ymax] );
   
   # retrieve the real-world plot limits
   my ($r_xmin, $r_ymin, $r_xmax, $r_ymax) = $plot->getRealPlotLimits($yax);
   push( @bulkargs, [$r_xmin, $r_ymin, $r_xmax, $r_ymax] );
   
   
   &_drawData(@bulkargs,'first');
   
   # As we cycle through the methods to draw the box, we need to
   # keep track of proper offset to draw the sample size
   # and the tails.  For example, if quartiles and deciles are
   # to be plotted then the tails start further away from the
   # location
   my $done;
   
   # what is the origin point for this boxplot
   my $start = &_start($plot, $boxstyle, $boxdata);                            
   my $lt_origin  = $start;
   my $ut_origin  = $start;
   
   foreach my $cile ( qw(decile pentacile quartile tercile) ) {
      my ($new_lt, $new_ut);
      ($done, $new_lt, $new_ut) = &_drawCiles($cile, @bulkargs);
      $lt_origin = (defined($new_lt) and $new_lt < $lt_origin) ?
                            $new_lt   :            $lt_origin  ;
      $ut_origin = (defined($new_ut) and $new_ut > $ut_origin) ?
                            $new_ut   :            $ut_origin  ;
   }
   
   $done = &_drawLocation(@bulkargs);
   
   my ( $low_limit, $up_limit );
   ( $done, $low_limit, $up_limit ) = &_drawTails($lt_origin, $ut_origin, @bulkargs);
     
   my ( $new_low, $new_up );
   ( $done, $new_low, $new_up ) = &_drawOutliers(-type1_outliers, @bulkargs);
   ( $low_limit, $up_limit    ) = &_outer_limits($new_low, $new_up, $low_limit, $up_limit);
   
   ( $done, $new_low, $new_up ) = &_drawOutliers(-type2_outliers, @bulkargs);
   ( $low_limit, $up_limit    ) = &_outer_limits($new_low, $new_up, $low_limit, $up_limit);
   
   # ($done, $new_low, $new_up) = &_drawDetectionLimits( @bulkargs );
   
   $done = &_drawText($low_limit,$up_limit,@bulkargs);
   # print "BOX: END OF A SINGLE BOX DRAWING\n";
   
   &_drawData(@bulkargs,'last');
   
   $canv->idletasks;
}   


sub _outer_limits {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($new_low, $new_up, $low_limit, $up_limit) = @_;
   $low_limit = (defined($new_low) and $new_low < $low_limit) ?
                         $new_low   :  $low_limit;
   $up_limit  = (defined($new_up ) and $new_up  > $up_limit ) ?
                         $new_up    :  $up_limit;
   return ($low_limit, $up_limit);
}



sub _start {
   my ($plot, $boxstyle, $boxdata) = @_;
   my $locref = $boxstyle->{-location};
   my $start  = ($locref->{-showtype} eq 'mean') ? $boxdata->{-mean  } :
                                                   $boxdata->{-median} ;
   my $orient = $boxstyle->{-orientation};
#   if($orient eq 'vertical') {
#      my $yref  = $plot->{-y};
#      my $ytype = $yref->{-type};
#      my $revy  = $yref->{-reverse};    
#      $start = $plot->transReal2CanvasGLOBALS('Y', $ytype, 1, $start);     
#      if($revy) { $start = $plot->revAxis('-y',$start) }
#   }
#   else {
#      my $xref  = $plot->{-x};
#      my $xtype = $xref->{-type};  
#      my $revx  = $xref->{-reverse};
#      $start = $plot->transReal2CanvasGLOBALS('X', $xtype, 1, $start);
#      if($revx) { $start = $plot->revAxis('-x',$start) }   
#   }   
   return $start;
}

1;
