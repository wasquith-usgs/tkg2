package Tkg2::Plot::BoxPlot::Draw::DrawData;

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
# $Date: 2002/08/07 18:31:32 $
# $Revision: 1.9 $

use strict;

use Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA       = qw( Exporter );
@EXPORT_OK = qw( _drawData );

use Tkg2::Base qw(Show_Me_Internals);

use Tkg2::Draw::DrawPointStuff qw(_reallydrawpoints);

print $::SPLASH "=";


sub _drawData {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($boxdata, $plot, $canv, $x, $y, $tag, $boxstyle,
       $limits, $real_limits, $plot_order) = @_;

   my %para = %{ $boxstyle->{-show_data} };
   
   return 0 unless(    $para{-doit}
                   and $para{-plot_order} eq $plot_order
                   and defined($x)
                   and defined($y) );

   my $orient = $boxstyle->{-orientation};
   
   # retrieve the vector of data
   my @data = @{$boxdata->{-DATA}};
   my @coords;
   if($orient eq 'vertical') {
      my $yref   = $plot->{-y};
      my $ytype  = $yref->{-type};
      my $revy   = $yref->{-reverse};
      foreach my $y (@data) {
         $y = $plot->transReal2CanvasGLOBALS('Y', $ytype, 1, $y); 
         $y = $plot->revAxis('-y',$y) if($revy);
         next if(not defined $y);
         push(@coords,$y);
      }
   }
   else {
       my $xref   = $plot->{-x};
       my $xtype  = $xref->{-type};
       my $revx   = $xref->{-reverse};
       foreach my $x (@data) {
          $x = $plot->transReal2CanvasGLOBALS('X', $xtype, 1, $x); 
          $x = $plot->revAxis('-x',$x) if($revx);   
          next if(not defined $x);
          push(@coords,$x);
       }
   }
   
   # Wrap the calling of the point drawing method
   # set up parameters for the call on the central point drawing
   # method
   my $attr = { -symbol       => $para{-symbol},
                -size         => $para{-size},
                -angle        => $para{-angle},
                -outlinecolor => $para{-outlinecolor},
                -outlinewidth => $para{-outlinewidth},
                -fillcolor    => $para{-fillcolor} }; 
   if($orient eq 'vertical') {
      foreach my $y (@coords) {
         &_reallydrawpoints($canv,$x,$y,["$plot", $plot."specialplot"], $attr);
      }
   }
   else {
      foreach my $x (@coords) {
         &_reallydrawpoints($canv,$x,$y,["$plot", $plot."specialplot"], $attr);
      }
   }
}

1;
