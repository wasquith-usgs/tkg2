package Tkg2::Plot::Plot2D;

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
# $Date: 2004/09/22 15:26:41 $
# $Revision: 1.74 $

use strict;
use vars qw(@ISA);

use Exporter;
use SelfLoader;
use Storable qw(dclone);

use Tkg2::Math::GraphTransform qw(transReal2CanvasGLOBALS setGLOBALS revAxis);
use Tkg2::Draw::DrawMethods;
use Tkg2::Plot::AxisConfiguration qw(routeAutoLimits
                                     autoConfigurePlotLimits
                                     makeAxisSquare);
use Tkg2::Plot::Editors::ContinuousAxisEditor;
use Tkg2::Plot::Editors::DiscreteAxisEditor;
use Tkg2::Plot::Editors::PlotEditor;
use Tkg2::Plot::Editors::ShowHideExplanEntries;
use Tkg2::Anno::QQLine;
use Tkg2::Anno::ReferenceLines;
use Tkg2::DataMethods::DataClass;
use Tkg2::Base qw(Message log10 isNumber Show_Me_Internals pixel_to_inch isInteger);
use Tkg2::Time::TimeMethods;

@ISA = qw(Exporter SelfLoader);

print $::SPLASH "=";

use constant TWO => scalar 2; 
                            
sub new {
   my $pkg = shift;
   my $template = shift;
   my $self = { };
   bless($self, $pkg);
   $self->{-canvwidth}  = shift;
   $self->{-canvheight} = shift;  
   $self->{-scaling} = $template->{-scaling};
   $self->{-skip_axis_config_on_1st_data} = 0; 
   $self->_defaultplot($template);
   $self->convertUnitsToPixels;
   return $self;
}


sub clone { return &dclone(shift()); }

# print statements commented out for release of Tkg2 to the world
# This method is part of my research into the Perl5.8.+ float/integer
# confusion issue.  PERL5.8 CORRECTION
# The calls to this method are left in tact (extremely minor
# increase in processing time)
sub isOffsetInteger { return; # early return for released version of Tkg2.
  my ($plot, $where) = @_;
  if(&isInteger($plot->{-y}->{-logoffset})) {
     print STDERR "BUG: $where -- offset is integer\n";
  }
  else {
     print STDERR "BUG: $where -- offset is not an integer\n";
  }  
}


# DrawMe is the main interface to redraw the entire Plot2D object.
# 
sub DrawMe {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($plot, $canv, $template, $increment) = (shift, shift, shift, shift);
   if($increment) {
      &_by_Increment_DrawMe($plot,$canv,$template);
      return;
   }
   # the toggling for plot drawing or not, new for 0.40
   # the exists test is for backwards compatability
   return if(exists $plot->{-doit} and not $plot->{-doit});
  
   $plot->{-doit} = 1; # incase the key wasn't there make it
        # the user still has to perform a save to permanently
        # retain the doit
   
   my $reDRAW = $::TKG2_CONFIG{-REDRAWDATA};
   
   $plot->isOffsetInteger('begin'); # PERL5.8 CORRECTION
   $plot->compute_Coords_for_DiscreteAxis($canv);
   $plot->isOffsetInteger('compute_Coords_for_DiscreteAxis'); # PERL5.8 CORRECTION
   my @fonts_defined = $::MW->fontNames();
   print $::BUG "FONTBUG UPDATECANVAS---PlotDrawBackground(begin): @fonts_defined\n";   
   $plot->drawPlotbackground($canv);
   @fonts_defined = $::MW->fontNames();
   print $::BUG "FONTBUG UPDATECANVAS---PlotDrawBackground(end  ): @fonts_defined\n";   
   $plot->isOffsetInteger('background drawn'); # PERL5.8 CORRECTION
    
   @fonts_defined = $::MW->fontNames();
   print $::BUG "FONTBUG UPDATECANVAS---PlotFinalDraw(begin): @fonts_defined\n"; 
   $plot->drawPlot($canv, $template);
   @fonts_defined = $::MW->fontNames();
   print $::BUG "FONTBUG UPDATECANVAS---PlotFinalDraw(end  ): @fonts_defined\n"; 
   $plot->isOffsetInteger('plot drawn'); # PERL5.8 CORRECTION
   
   if($reDRAW) {
      @fonts_defined = $::MW->fontNames();
      print $::BUG "FONTBUG UPDATECANVAS---PlotDrawBars(begin): @fonts_defined\n"; 
      $plot->drawBars($canv);
      @fonts_defined = $::MW->fontNames();
      print $::BUG "FONTBUG UPDATECANVAS---PlotDrawBars(end  ): @fonts_defined\n"; 

      $plot->isOffsetInteger('bars drawn'); # PERL5.8 CORRECTION
      @fonts_defined = $::MW->fontNames();
      print $::BUG "FONTBUG UPDATECANVAS---PlotDrawLines(begin): @fonts_defined\n";    
      $plot->drawLines($canv);
      @fonts_defined = $::MW->fontNames();
      print $::BUG "FONTBUG UPDATECANVAS---PlotDrawLines(end  ): @fonts_defined\n"; 
      $plot->isOffsetInteger('lines drawn'); # PERL5.8 CORRECTION
   }
   @fonts_defined = $::MW->fontNames();
   print $::BUG "FONTBUG UPDATECANVAS---PlotDrawQQ(begin): @fonts_defined\n"; 
   $plot->{-QQLines}->draw($canv,$plot);  # draw some quantile-quantile lines
   @fonts_defined = $::MW->fontNames();
   print $::BUG "FONTBUG UPDATECANVAS---PlotDrawQQ(end  ): @fonts_defined\n"; 
   $plot->isOffsetInteger('QQlines drawn'); # PERL5.8 CORRECTION
   @fonts_defined = $::MW->fontNames();
   print $::BUG "FONTBUG UPDATECANVAS---PlotDrawReflines(begin): @fonts_defined\n";   
   $plot->{-RefLines}->draw($canv,$plot); # draw some reference lines
   @fonts_defined = $::MW->fontNames();
   print $::BUG "FONTBUG UPDATECANVAS---PlotDrawReflines(end  ): @fonts_defined\n";   
   $plot->isOffsetInteger('ref lines drawn'); # PERL5.8 CORRECTION
   
   
   foreach my $axis  (qw(-x -y -y2)) {
      my $type = $plot->{$axis}->{-type};
      ( $type eq 'time' ) ? $plot->drawTimeAxis($canv,$axis)   :
                            $plot->drawAxisLabels($canv,$axis) ;
      $plot->isOffsetInteger("$axis axis drawn"); # PERL5.8 CORRECTION
   
   }
   $plot->shuffleGrids($canv);
   $canv->update;
   
   if( $reDRAW ) {
     @fonts_defined = $::MW->fontNames();
     print $::BUG "FONTBUG UPDATECANVAS---PlotDrawSpecial(begin): @fonts_defined\n";   
     $plot->drawSpecialPlot($canv);
     @fonts_defined = $::MW->fontNames();
     print $::BUG "FONTBUG UPDATECANVAS---PlotDrawSpecial(end  ): @fonts_defined\n";   
     $plot->isOffsetInteger('special plot drawn'); # PERL5.8 CORRECTION
     @fonts_defined = $::MW->fontNames();
     print $::BUG "FONTBUG UPDATECANVAS---PlotDrawPoints(begin): @fonts_defined\n";
     $plot->drawPoints($canv);
     @fonts_defined = $::MW->fontNames();
     print $::BUG "FONTBUG UPDATECANVAS---PlotDrawPoints(end  ): @fonts_defined\n";
     $plot->isOffsetInteger('points drawn'); # PERL5.8 CORRECTION
     @fonts_defined = $::MW->fontNames();
     print $::BUG "FONTBUG UPDATECANVAS---PlotDrawText(begin): @fonts_defined\n";
     $plot->drawText($canv);
     @fonts_defined = $::MW->fontNames();
     print $::BUG "FONTBUG UPDATECANVAS---PlotDrawText(end  ): @fonts_defined\n";
     $plot->isOffsetInteger('text drawn'); # PERL5.8 CORRECTION   
   }
   @fonts_defined = $::MW->fontNames();
   print $::BUG "FONTBUG UPDATECANVAS---PlotDrawExplanation(begin): @fonts_defined\n";
   $plot->drawExplanation($canv, $template)
      if(not $plot->{-explanation}->{-hide});
   print $::BUG "FONTBUG UPDATECANVAS---PlotDrawExplanation(end): @fonts_defined\n";
   $plot->isOffsetInteger('explanation drawn--plot finished'); # PERL5.8 CORRECTION
}

sub _by_Increment_DrawMe {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($plot, $canv, $template) = (shift, shift, shift);
   
   # the toggling for plot drawing or not, new for 0.40
   # the exists test is for backwards compatability
   return if(exists $plot->{-doit} and not $plot->{-doit});
  
   $plot->{-doit} = 1; # incase the key wasn't there make it
        # the user still has to perform a save to permanently
        # retain the doit
   
   my $reDRAW = $::TKG2_CONFIG{-REDRAWDATA};
   
   $plot->compute_Coords_for_DiscreteAxis($canv);
   
   $plot->drawPlotbackground($canv);
   &_PromptMessage($canv,'Is this plot background correct?'); 
   
   $plot->drawPlot($canv, $template);
   &_PromptMessage($canv,'Is this plot (axis and plot titles) correctly drawn?');

   if($reDRAW) {
      $plot->drawBars($canv);
      &_PromptMessage($canv,'Are data bars correctly drawn?');
      $plot->drawLines($canv);
      &_PromptMessage($canv,'Are data lines correctly drawn?');
   }
      
   $plot->{-QQLines}->draw($canv,$plot);  # draw some quantile-quantile lines
   &_PromptMessage($canv,'Are quantile-quantile lines correctly drawn?');

   $plot->{-RefLines}->draw($canv,$plot); # draw some reference lines
   &_PromptMessage($canv,'Are reference lines correctly drawn?');
   
   foreach my $axis  (qw(-x -y -y2)) {
      my $type = $plot->{$axis}->{-type};
      ( $type eq 'time' ) ? $plot->drawTimeAxis($canv,$axis)   :
                            $plot->drawAxisLabels($canv,$axis) ;
      &_PromptMessage($canv,"Is the $axis axis correctly drawn?");
   }
   $plot->shuffleGrids($canv);
   $canv->update;
   
   if( $reDRAW ) { 
     $plot->drawSpecialPlot($canv);
     &_PromptMessage($canv,'Are boxplots correctly drawn?');

     $plot->drawPoints($canv);
     &_PromptMessage($canv,'Are data points correctly drawn?');

     $plot->drawText($canv);
     &_PromptMessage($canv,'Is data text correctly drawn?');
   }
   
   $plot->drawExplanation($canv, $template)
      if(not $plot->{-explanation}->{-hide});     
   &_PromptMessage($canv,'If the explanation was to be drawn, was it?');
}

sub _PromptMessage {
   my ($canv,$message) = @_;
   $canv->update;
   print "INCREMENTAL CANVAS UPDATE: $message (Y/N) ";
   my $tmp = <STDIN>;
   chomp($tmp);
   $tmp = ($tmp =~ /y/io) ? 'YES' : 'NO';
   print $::MESSAGE "  CANVAS UPDATE: $message   ($tmp)\n";
}


sub shuffleGrids {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($plot, $canv) = @_;
   $canv->lower( "$plot".'background', "$plot"."border" );
   $canv->lower( "$plot".'minorgrid',  "$plot"."border" );
   $canv->lower( "$plot".'majorgrid',  "$plot"."border" );
   $canv->lower( "$plot".'origin',     "$plot"."border" );
}

sub showExplanation {
   my ($plot, $which) = @_;
   $plot->{-explanation}->{-hide} = ($which =~ m/hide/o) ? 1 : 0; 
}

sub toggleAxisConfigurations {
   my ($plot, $on) = @_;
   if($on) {
      $plot->{-x}->{-autominlimit}  =
      $plot->{-x}->{-automaxlimit}  =
      $plot->{-y}->{-autominlimit}  =
      $plot->{-y}->{-automaxlimit}  =
      $plot->{-y2}->{-autominlimit} =
      $plot->{-y2}->{-automaxlimit} = 1;
   }
   else {
      $plot->{-x}->{-autominlimit}  = 
      $plot->{-x}->{-automaxlimit}  = 
      $plot->{-y}->{-autominlimit}  = 
      $plot->{-y}->{-automaxlimit}  = 
      $plot->{-y2}->{-autominlimit} = 
      $plot->{-y2}->{-automaxlimit} = 0;
   }
}

sub compute_Coords_for_DiscreteAxis {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my ($plot, $canv) = (shift, shift);
   &_discrete_coords($plot,$canv,'-x')  if($plot->{-x}->{-discrete}->{-doit});
   &_discrete_coords($plot,$canv,'-y')  if($plot->{-y}->{-discrete}->{-doit});
   &_discrete_coords($plot,$canv,'-y2') if($plot->{-y2}->{-discrete}->{-doit}
                                                          and
                                           $plot->{-y2}->{-turned_on} );  
}

sub _discrete_coords {
   my ($plot, $canv, $axis) = (shift, shift, shift);
   my $xyindex = ($axis eq '-x') ? 0 : 1; # x data in the zero slot, y in 1
   
   my $dataclass      = $plot->{-dataclass};
   my %label_discrete = %{ $plot->{$axis}->{-discrete}->{-labelhash} };
      
   if( $plot->{$axis}->{-discrete}->{-doit} eq 'cluster' ) {
      my $space = $plot->{$axis}->{-discrete}->{-clusterspacing};
         $space = ($space) ? $space : '0i'; # error trap for backwards
                                            # compat for 0.72-3 and earlier
         $space = $canv->fpixels($space);
         $space = $plot->CanvDist2RealDist($axis,$space);
      
      # Need to determine the total bar width
      my $total_bar_width = 0;
      DATACLASSa: foreach my $dataset (@$dataclass) {
         DATASETa: foreach my $data ( @{ $dataset->{-DATA} } ) {
            #EACHPOINTa: foreach my $pair ( @{ $data->{-data} } ) {
               my $bar_width = $data->{-attributes}->{-bars}->{-barwidth};
                  $bar_width = $canv->fpixels($bar_width);
                  $bar_width = $plot->CanvDist2RealDist($axis,$bar_width);
               
               $total_bar_width += $bar_width+$space;
            #   next DATASETa; 
            #}
         }
      }
      my $offset = -($total_bar_width-$space) / TWO;
      
      # Now that the offset is known, determine that actual coordinates
      # of each data within the cluster.
      DATACLASSb: foreach my $dataset (@$dataclass) {
         DATASETb: foreach my $data ( @{ $dataset->{-DATA} } ) {
            
            # Determine bar width
            my $bar_width = $data->{-attributes}->{-bars}->{-barwidth};
               $bar_width = $canv->fpixels($bar_width);
               $bar_width = $plot->CanvDist2RealDist($axis,$bar_width);
            
            EACHPOINTb: foreach my $pair ( @{ $data->{-data} } ) {
               next EACHPOINTb unless(ref($pair->[$xyindex]) eq 'ARRAY');
              
               my $xydata   = $pair->[$xyindex];
               my $label    = $xydata->[1];
               $xydata->[0] = $label_discrete{$label}
                              + $offset
                              + $bar_width / TWO;
           } # END EACHPOINT:
           $offset += $bar_width+$space;
         } # END DATASET:
      }    # END DATACLASS:
   }
   else {  # NOT A CLUSTER PLOT--JUST A STACK PLOT
      DATACLASSc: foreach my $dataset (@$dataclass) {
         DATASETc: foreach my $data (@ { $dataset->{-DATA} } ) {
            EACHPOINTc: foreach my $pair ( @{ $data->{-data} } ) {
               next EACHPOINTc unless(ref($pair->[$xyindex]) eq 'ARRAY');
               my $xydata   = $pair->[$xyindex];
               $xydata->[0] = $label_discrete{$xydata->[1]};
            }
         }
      }
   }
    return 1;
}



sub configwidth {
   my $self = shift;
   $self->{-xpixels} =
          $self->{-canvwidth}  - $self->{-xlmargin} - $self->{-xrmargin};
   $self->{-ypixels} =
          $self->{-canvheight} - $self->{-yumargin} - $self->{-ylmargin};
   $self->_configlimits;
}  


sub config_xrylmargins_from_xlyumarins {
   my $self = shift;
   $self->{-xrmargin} =
          $self->{-canvwidth} - $self->{-xlmargin} - $self->{-xpixels};
   $self->{-ylmargin} =
          $self->{-canvheight} - $self->{-yumargin} - $self->{-ypixels};
   $self->_configlimits;
}

sub _configlimits {
   my $self = shift;
   
   $self->setGLOBALS('-y'); # there is no need to be concered about -y2
                            # since the canvas coordinates of the y limits
                            # are the same no matter which axis is used in
                            # the calculations.  we only track against -y
                            # so that there is never a chance for later
                            # inconsistencies.
   my $xref  = $self->{-x};
   my $xtype = $xref->{-type};
   my $xmin  = $xref->{-min};
   my $xmax  = $xref->{-max};
   
   # The logoffset MUST be zero for the configuration of the limits
   # and then we will restore the value
   my $oldxlogoffset = $self->{-x}->{-logoffset};
   my $oldylogoffset = $self->{-y}->{-logoffset};
   $self->{-x}->{-logoffset} = 0;
   $self->{-y}->{-logoffset} = 0;
   
   $self->{-xmincanvas} = $self->transReal2CanvasGLOBALS('X',$xtype, 0, $xmin );
   $self->{-xmaxcanvas} = $self->transReal2CanvasGLOBALS('X',$xtype, 0, $xmax );   
   
   my $yref  = $self->{-y};
   my $ytype = $yref->{-type};
   my $ymin  = $yref->{-min};
   my $ymax  = $yref->{-max};  
   # Notice that the ymincanvas and ymaxcanvas are swapped! because canvas
   # counts down from top
   $self->{-ymaxcanvas} = $self->transReal2CanvasGLOBALS('Y',$ytype, 0, $ymin );
   $self->{-ymincanvas} = $self->transReal2CanvasGLOBALS('Y',$ytype, 0, $ymax );
   
   $self->{-x}->{-logoffset} = $oldxlogoffset;
   $self->{-y}->{-logoffset} = $oldylogoffset;
}

sub configplot {
   my $self = shift;
   if( wantarray ) { return %$self };
   if(scalar(@_) == 1) { return $self->{shift()}; }
   if(@_) {
      my %para = @_;
      if( exists($para{-xpixels}) ) {
         warn "Do not try to modify X plot width, use margins and canvas width\n";
         delete $para{-xpixels};
      }
      if( exists($para{-ypixels}) ) {
         warn "Do not try to modify Y plot width, use margins and canvas width\n";
         delete $para{-xpixels};
      }
      @$self{keys %para} = values %para;
      foreach my $yax (qw(-y -y2)) {
         $self->configwidth;  # reset geometry inclase any of 6 values changed
         # IMPORTANT, WILL BREAK IF -xpixels OR -ypixels IS MODIFIED
         $self->_configlimits;   
      }   
      return;
   }
}

sub getPlotWidthandHeight {
   my $self   = shift;
   return ( $self->pixel_to_inch($self->{-xpixels}),
            $self->pixel_to_inch($self->{-ypixels}) );
}

sub getPlotMargins {
   my ($self, $xoy) = (shift, shift);
   $xoy = (not defined $xoy ) ? undef :
          ( $xoy =~ m/x/io  ) ? '-x'  : '-y';
   my @marg = ( $self->{-xlmargin}, $self->{-xrmargin},
                $self->{-yumargin}, $self->{-ylmargin} );
   map { $_ = $self->pixel_to_inch($_) } @marg;
   return @marg;
}

sub getPlotMargins_inPixels {
   my $self = shift;  
   return ( $self->{-xlmargin}, $self->{-xrmargin},
            $self->{-yumargin}, $self->{-ylmargin} );
}

sub getPlotLimits {
   my $self = shift;
   return ( $self->{-xmincanvas}, $self->{-ymincanvas},
            $self->{-xmaxcanvas}, $self->{-ymaxcanvas} );
}

sub getRealPlotLimits {
   my ($self, $yax) = @_;
   my $xref = $self->{-x};
   my $yref = $self->{$yax};
   return ( $xref->{-min}, $yref->{-min},
            $xref->{-max}, $yref->{-max} );
}   

sub highlightPlot {
   my ($plot, $canv) = (shift, shift);
   my @coords = $canv->bbox("$plot");
   $canv->delete('selectedplot');
   return unless(@coords == 4);
   $canv->createRectangle(@coords, -outline => 'red', -tag => 'selectedplot');   
}


sub convertUnitsToPixels {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my $self  = shift;
   # we test for isNumber on the values, because fpixels will only work
   # on numbers ending in pt, i, or m. etc.  If the value is already 
   # a number, we will assume that the number is already converted
   # to pixels and all is ok
   foreach my $key (qw(-plottitlexoffset -plottitleyoffset
                       -canvwidth -canvheight
                       -yumargin  -xrmargin
                       -xlmargin  -ylmargin)) {
      my $val = $self->{$key};
      next if(not defined $val); # needed because the -*margin are
                                 # undefined when plot object is first created
      $self->{$key} = $::MW->fpixels($val) unless( &isNumber($val) );
   }

   my $exref = $self->{-explanation};
   foreach my $key (qw(-horzgap -linewidth -xorigin -yorigin)) {
      my $val = $exref->{$key};
      next if(not defined $val); # needed because -xorigin and -yorigin 
                                 # are undefined when plot object is created
      $exref->{$key} = $::MW->fpixels($val) unless( &isNumber($val) );
   }

   my $xref   = $self->{-x};
   my $yref   = $self->{-y};
   my $y2ref  = $self->{-y2};
   foreach my $key (qw(-laboffset -lab2offset
                       -numoffset -num2offset -ticklength)) {
      
      # conditional for backwards compatability for 0.52 and on
      if($key eq '-lab2offset') {
          $xref->{$key} = "0i" unless( $xref->{$key});
          $yref->{$key} = "0i" unless( $yref->{$key});
         $y2ref->{$key} = "0i" unless($y2ref->{$key});
      } # end of conditional for backwards compatability
      
      my $val = $xref->{$key};
      $xref->{$key}  = $::MW->fpixels($val) unless( &isNumber($val) );   
      
      $val = $yref->{$key};
      $yref->{$key}  = $::MW->fpixels($val) unless( &isNumber($val) );
      
      $val = $y2ref->{$key};
      $y2ref->{$key} = $::MW->fpixels($val) unless( &isNumber($val) );
   }
}


sub convertAxisMinMaxtoIntegerifTime {
   my $self   = shift;
   my $xref   = $self->{-x};
   my $yref   = $self->{-y};
   my $y2ref  = $self->{-y2};
   my $xmin   = \$xref->{-min};
   my $xmax   = \$xref->{-max};
   my $ymin   = \$yref->{-min};
   my $ymax   = \$yref->{-max};
   my $y2min  = \$y2ref->{-min};
   my $y2max  = \$y2ref->{-max}; 
     
   my @vals = ( $xmin, $xmax, $ymin, $ymax, $y2min, $y2max);
   #map { print "convertAxisMinMaxifTimetoInteger $$_\n"; } @vals;
   foreach (@vals) {
       next if(&isNumber($$_));
       my $decode = &DecodeTkg2DateandTime($$_);
       $$_ = $decode if( defined $decode );
   }
   #map { print "convertAxisMinMaxifTimetoInteger $$_\n"; } @vals;
}


sub CanvHeightWidth_have_changed {
   my ($plot, $oldcanvwidth, $oldcanvheight) = @_;
   # the plot parameters have already been changed
   my $newcanvwidth  = $plot->{-canvwidth};
   my $newcanvheight = $plot->{-canvheight};
   
   my ($oldxlmargin, $oldxrmargin,
       $oldyumargin, $oldylmargin ) = $plot->getPlotMargins_inPixels;
         
   my ($percentage, $newval, $origin);
   if($::CMDLINEOPTS{'width'} and $newcanvwidth != $oldcanvwidth) {
      # work on the left edge
      $percentage = $oldxlmargin / $oldcanvwidth;
      $newval = $percentage*$newcanvwidth;
      $plot->{-xlmargin} = $newval;
      
      # work on the right edge
      $percentage = ($oldcanvwidth - $oldxrmargin) / $oldcanvwidth;
      $newval = $newcanvwidth - $percentage*$newcanvwidth;
      $plot->{-xrmargin} = $newval;
      
      # work on the x origin of the explanation
      $origin = $plot->{-explanation}->{-xorigin};
      $percentage = $origin / $oldcanvwidth;
      $newval = $percentage*$newcanvwidth;
      $plot->{-explanation}->{-xorigin} = $newval;
   }
   
   if($::CMDLINEOPTS{'height'} and $newcanvheight != $oldcanvheight) {
      # work on the upper edge
      $percentage = $oldyumargin / $oldcanvheight;
      $newval = $percentage*$newcanvheight;
      $plot->{-yumargin} = $newval;
      
      # work on the lower edge
      $percentage = ($oldcanvheight - $oldylmargin) / $oldcanvheight;
      $newval = $newcanvheight - $percentage*$newcanvheight;
      $plot->{-ylmargin} = $newval;

      # work on the y origin of the explanation
      $origin = $plot->{-explanation}->{-yorigin};
      $percentage = $origin / $oldcanvheight;
      $newval = $percentage*$newcanvheight;
      $plot->{-explanation}->{-yorigin} = $newval;
   }
}


sub RealDist2CanvDist {
   my ($self, $axis, $realdist) = @_;
   $axis = ($axis =~ m/x/io) ? '-x'  :
           ($axis =~ m/2/io) ? '-y2' : '-y';
   
   # subtle point here is than we use -y for the argument for the
   # getRealPlotLimits when the axis of interest is
   # the -x one.  Note that in the ratio calculation that the calculations
   # are only pertinent to the $axis, but the getRealPlotLimits methods require that
   # a request for -y or -y2 be made.
   my $yax = ($axis eq '-x') ? '-y' : $axis;
   if($self->{$axis}->{-type} ne 'linear') {
      warn "Tkg2 Warning: Bad call into RealDist2CanvDist, axis must be linear\n".
           "              Called with $self->{$axis}->{-type} instead\n";
      return undef;
   }
   
   my ($xmincanv, $ymincanv, $xmaxcanv, $ymaxcanv) = $self->getPlotLimits;
   my ($xminreal, $yminreal, $xmaxreal, $ymaxreal) = $self->getRealPlotLimits($yax);
 
   my $ratio =  ($axis eq '-x') ?    ($xmaxcanv - $xmincanv) /
                                  abs($xmaxreal - $xminreal)
                                :
                                     ($ymaxcanv - $ymincanv) /
                                  abs($ymaxreal - $yminreal);
   return $ratio*$realdist;
}


sub CanvDist2RealDist {
   my ($self, $axis, $canvdist) = @_;
   $axis = ($axis =~ m/x/io) ? '-x'  :
           ($axis =~ m/2/io) ? '-y2' : '-y';
   
   # subtle point here is than we use -y for the argument for the
   # getRealPlotLimits when the axis of interest is
   # the -x one.  Note that in the ratio calculation that the calculations
   # are only pertinent to the $axis, but the getRealPlotLimits methods require that
   # a request for -y or -y2 be made.
   my $yax = ($axis eq '-x') ? '-y' : $axis;
       
   if($self->{$axis}->{-type} ne 'linear') {
      warn "Tkg2 Warning: Bad call into CanvDist2RealDist, axis must be linear\n".
           "              Called with $self->{$axis}->{-type} instead\n";
      return undef;
   }
   
   my ($xmincanv, $ymincanv, $xmaxcanv, $ymaxcanv) = $self->getPlotLimits;
   my ($xminreal, $yminreal, $xmaxreal, $ymaxreal) = $self->getRealPlotLimits($yax);
 
   # the calculation is the same for either -y or -y2 axis
   my $ratio =  ($axis eq '-x') ?  abs($xmaxreal - $xminreal) /
                                      ($xmaxcanv - $xmincanv)
                                :
                                   abs($ymaxreal - $yminreal) /
                                      ($ymaxcanv - $ymincanv);
   return $ratio*$canvdist;
}

1;

__DATA__

sub configureAxisToPercentBase {
  my ($self, $axis, $frac_or_not) = @_;
  $axis = ($axis =~ m/x/io) ? '-x'  :
          ($axis =~ m/2/io) ? '-y2' : '-y';
  my $aref = $self->{$axis};
  if($frac_or_not) {
    $aref->{-min}       = 0;
    $aref->{-max}       = 1;
    $aref->{-numminor}  = 4;
    $aref->{-majorstep} = .1;
    $aref->{-type}      = 'linear';
  }
  else { # assume true percentages
    $aref->{-min}       = 0;
    $aref->{-max}       = 100;
    $aref->{-numminor}  = 4;
    $aref->{-majorstep} = 10;
    $aref->{-type}      = 'linear';
  }
}

sub _defaultexplanation  {
   my $self = { -hide         => 0,
                -numcol       => 1,
                -colspacing   => '0.10i',
                -xorigin      => undef,
                -yorigin      => undef,
                -vertspacing  => 'auto',
                -horzgap      => '0.056i',
                -linewidth    => '0.333i',
                -titlexoffset => 'auto',
                -titleyoffset => 'auto',
                -fillcolor    => 'white',
                -dashstyle    => undef,
                -fillstyle    => undef,
                -outlinewidth => '0.01i', 
                -outlinecolor => 'white',
                -title => 'EXPLANATION',
                -titlejustify => 'center',
                -area_line_point_order => 0,
                -font => { -family  => "Times",    -size  => 8,
                           -weight  => 'normal',   -slant => 'roman',
                           -color   => 'black', -rotation => 0,
                           -stackit => 0,       -custom1  => undef,
                           -custom2 => undef  }
              };
   return $self;
}

sub _defaultplot {
   my $self     = shift;
   my $template = shift;
   $self->{-RefLines}  = Tkg2::Anno::ReferenceLines->new;   # NEW FOR VERSION 0.11
   $self->{-QQLines}   = Tkg2::Anno::QQLine->new;           # NEW FOR VERSION 0.11
   $self->{-dataclass} = Tkg2::DataMethods::DataClass->new; 
   $self->{-username}  = "",
   $self->{-doit} = 1;  # new for 0.40
   $self->{-explanation}  = &_defaultexplanation();
   $self->{-xlmargin} = undef;              
   $self->{-xrmargin} = undef;
   $self->{-yumargin} = undef;             
   $self->{-ylmargin} = undef;
  
   $self->{-x}  = &_build_X_axis();
   $self->{-y}  = &_build_Y_axis();   
   
   $self->{-y2} = &_build_Y_axis();       # DOUBLE Y:
   $self->{-y2}->{-location}  = 'right';  # DOUBLE Y: 
   
   
   $self->{-borderwidth}     = '0.01i';
   $self->{-borderdashstyle} = undef;
   $self->{-bordercolor}     = 'black';   
   $self->{-plotbgcolor}     = 'white'; 
   $self->{-plotbgfillstyle} = undef;                       
   $self->{-plottitle}       = "";
   $self->{-plottitlefont} = { -family  => "Helvetica", -size => 10,
                               -weight  =>  'bold',    -slant => 'roman',
                               -color   => 'black', -rotation => 0,
                               -stackit => 0,       -custom1  => undef,
                               -custom2 => undef};
   $self->{-plottitleyoffset} = '0.24i';
   $self->{-plottitlexoffset} = '0.06i';
   $self->{-plottitlejustify} = 'center';
}




sub _build_X_axis {
   my %h = ( -type        => 'linear',
             -location    => 'bottom',
             -doublelabel => 0,
             -labelmin    => 1,
             -labelmax    => 1,
             -discrete => { -doit      => 0,
                            -labelhash => { },
                            -bracketgroup => 1,
                            -clusterspacing => '0i' },
             -hideit       => 0,
             -blankit      => 0,
             -blankcolor   => 'white',
             -autominlimit => 1,
             -automaxlimit => 1,
             -min   =>  -10,
             -max   =>   10,
             -min_to_begin_labeling => "",
             -max_to_end_labeling   => "",
             -tick_to_actual_min_and_max => 0,
             -datamin => { -whenlinear => undef,
                           -whenlog    => undef,
                           -whenprob   => undef },
             -datamax => { -whenlinear => undef,
                           -whenlog    => undef,
                           -whenprob   => undef },
             -labelequation   =>   0,
             -laboffset       => '0.2i',
             -lab2offset      => '0i',
             -numoffset       => '0.05i',
             -num2offset      => '0.05i',
             -ticklength      => '0.089i',
             -tickratio       => 0.6,
             -spectickratio   => 0.8,
             -tickwidth  => '0.01i',
             -labskip    => 0,
             -numminor   => 1,
             -majorstep  => 2,
             -usesimplelog => 0,
             -basemajor        => [ ],
             -basemajortolabel => [ ],
             -baseminor        => [ ],
             -logoffset        => 0,
             -probUSGStype => 0,
             -invertprob   => 0,
             -title => 'X-DATA',          
             -major => [],     
             -minor => [],     
             -reverse    => 0,               
             -numcommify => 0,           
             -numformat  => 'free',           
             -numdecimal => 0,
             -labfont    => { -family  => "Helvetica", -size => 10,
                              -weight  =>  'normal', -slant  => 'roman',
                              -color   => 'black', -rotation => 0,
                              -stackit => 0,       -custom1  => undef,
                              -custom2 => undef },
             -numfont    => { -family  => "Helvetica", -size => 9,
                              -weight  => 'normal',  -slant  => 'roman',
                              -color   => 'black', -rotation => 0,
                              -stackit => 0,       -custom1  => undef,
                              -custom2 => undef },
             -gridmajor => { -linewidth   => '0.01i',
                             -linecolor   => 'grey75',
                             -dashstyle   => undef,
                             -doit        => 0 },
             -gridminor => { -linewidth   => '0.005i',
                             -linecolor   => 'grey75',
                             -dashstyle   => undef,
                             -doit        => 0 },                                   
             -originwidth      => '0.01i',
             -origincolor      => 'grey85',
             -origindashstyle  => undef,
             -origindoit       => 0,
             -time => { -tickratio   =>   .7,
                        
                        -showyear    =>  1,
                                 
                        -yeardoit    =>  1,
                        -monthdoit   =>  1,
                        -daydoit     =>  1,
                        -hourdoit    =>  1,
                        -minutedoit  =>  1,
                        -seconddoit  =>  1,
                                  
                        -yeartickevery    =>  'auto',
                        -monthtickevery   =>  'auto',
                        -daytickevery     =>  'auto',
                        -hourtickevery    =>  'auto',
                        -minutetickevery  =>  'auto',
                        -secondtickevery  =>  'auto',
                        
                        -compact_months_in_publication_style => 0,           
                        -show_day_as_additional_string => 0,
                        -show_day_of_year_instead => 0,
                       
                        -labeldensity => 1,
                        -labeldepth   => 1,
                        -labellevel1  => 1,
                        
                        -min => "",
                        -max => "",
                        -basedate => [ ],                       
                      } );
   return { %h };
}

sub _build_Y_axis {
   my %h = ( -type         => 'linear',
             -turned_on    => 0,
             -make_axis_square => 0,
             -location     => 'left',
             -doublelabel  => 0,
             -labelmin     => 1,
             -labelmax     => 1,
             -discrete     => { -doit      => 0,
                                -labelhash => { },
                                -bracketgroup => 1,
                                -clusterspacing => '0i' },
             -hideit       => 0,
             -blankit      => 0,
             -blankcolor   => 'white',
             -autominlimit => 1,
             -automaxlimit => 1,
             -min     =>  -10,          
             -max     =>   10,
             -min_to_begin_labeling => "",
             -max_to_end_labeling   => "",
             -tick_to_actual_min_and_max => 0,
             -datamin => { -whenlinear => undef,
                           -whenlog    => undef,
                           -whenprob   => undef },
             -datamax => { -whenlinear => undef,
                           -whenlog    => undef,
                           -whenprob   => undef },
             -labelequation   =>   0,
             -laboffset       => '0.7i',
             -lab2offset      => '0i',
             -numoffset       => '0.045i',
             -num2offset      => '0.045i',
             -ticklength      => '0.089i',
             -tickratio       => 0.6,
             -spectickratio   => 0.8,
             -tickwidth  => '0.01i',
             -labskip    => 0,
             -numminor   => 1,
             -majorstep  => 2,
             -usesimplelog => 0,
             -basemajor        => [ ],
             -basemajortolabel => [ ],
             -baseminor        => [ ],
             -logoffset        => 0,
             -probUSGStype => 0,
             -invertprob   => 0,
             -title => 'Y-DATA',          
             -major => [],     
             -minor => [],     
             -reverse    => 0,               
             -numcommify => 0,           
             -numformat  => 'free',           
             -numdecimal => 0,
             -labfont    => { -family  => "Helvetica", -size => 10,
                              -weight  =>  'normal', -slant  => 'roman',
                              -color   => 'black', -rotation => 0,
                              -stackit => 0,       -custom1  => undef,
                              -custom2 => undef },
             -numfont    => { -family  => "Helvetica", -size => 9,
                              -weight  => 'normal',  -slant  => 'roman',
                              -color   => 'black', -rotation => 0,
                              -stackit => 0,       -custom1  => undef,
                              -custom2 => undef },
             -gridmajor => { -linewidth   => '0.01i',
                             -linecolor   => 'grey75',
                             -dashstyle   => undef,
                             -doit        => 0 },
             -gridminor => { -linewidth   => '0.005i',
                             -linecolor   => 'grey75',
                             -dashstyle   => undef,
                             -doit        => 0 },      
             -originwidth     => '0.01i',
             -origincolor     => 'grey85',
             -origindashstyle => undef,
             -origindoit      => 0,
             -time => { -tickratio   =>   .7,
                        -showyear    =>  1,
                        
                        -yeardoit    =>  1,
                        -monthdoit   =>  1,
                        -daydoit     =>  1,
                        -hourdoit    =>  1,
                        -minutedoit  =>  1,
                        -seconddoit  =>  1,
                                 
                        -yeartickevery    =>  'auto',
                        -monthtickevery   =>  'auto',
                        -daytickevery     =>  'auto',
                        -hourtickevery    =>  'auto',
                        -minutetickevery  =>  'auto',
                        -secondtickevery  =>  'auto',
                        
                        -compact_months_in_publication_style => 0,
                        -show_day_as_additional_string => 0,
                        -show_day_of_year_instead => 0,
                        
                        -labeldensity => 1,
                        -labeldepth   => 1,
                        -labellevel1  => 1,
                        
                        -min => "",
                        -max => "",
                        -basedate => [ ],
                      } ); # year, month, day 
   return { %h };
}



sub switchAxis {
   my $plot = shift;
   return $plot;  # feature is not yet turned on
   return $plot if($plot->{-y2}->{-turned_on});
   my $xold = $plot->{-x};
   my $yold = $plot->{-y};
   $plot->{-x} = $yold;
   $plot->{-y} = $xold;
   $plot->{-x}->{-location} = 'bottom';
   $plot->{-y}->{-location} = 'left';
   # need to switch the data to
   return $plot;
   #$self->{-xmincanvas}, $self->{-ymincanvas},
   #         $self->{-xmaxcanvas}, $self->{-ymaxcanvas}
}
   


1;

__END__
