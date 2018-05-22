package Tkg2::Draw::DrawMethods;

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
# $Date: 2007/09/10 02:25:10 $
# $Revision: 1.45 $

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Carp;
use Exporter;


use Tkg2::Math::GraphTransform qw(transReal2CanvasGLOBALS setGLOBALS);
use Tkg2::Plot::Movements::ResizingPlot;
use Tkg2::Plot::Movements::MovingPlot;
use Tkg2::Draw::Labels::DrawLabels qw(drawAxisLabels __blankit);
use Tkg2::Draw::DrawLineStuff;
use Tkg2::Draw::DrawPointStuff;
use Tkg2::Draw::DrawPointStuff qw(_reallydrawpoints _drawsometext);
use Tkg2::Draw::DrawExplanation;
use Tkg2::Base qw(Message isNumber Show_Me_Internals adjustCursorBindings deleteFontCache);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createAxisTitlesMetaPost createPolygonMetaPost);

@ISA = qw(Exporter);

@EXPORT = qw(drawPlotbackground drawPlot   drawLines  drawPoints drawAxisLabels
             drawExplanation    drawOrigin drawBars   drawText
             drawSpecialPlot );          
@EXPORT_OK = qw( _xaxisLabel _yaxisLabel);             

print $::SPLASH "=";
use constant TWO => scalar 2; 
             
sub drawPlotbackground {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $canv) = @_;
   my ($xmin, $ymin, $xmax, $ymax) = $self->getPlotLimits;
   $canv->createPolygon( $xmin, $ymax,        $xmax, $ymax,
                         $xmax, $ymin,        $xmin, $ymin,
                         $xmin, $ymax,
		                   -fill    => $self->{-plotbgcolor},
                         -outline => undef,
                         -tag     => ["$self", $self."background"] );
   createPolygonMetaPost($xmin, $ymax,        $xmax, $ymax,
                         $xmax, $ymin,        $xmin, $ymin,
                         $xmin, $ymax,
                        {-fill    => $self->{-plotbgcolor},
                         -outline => undef});  
   $self->drawOrigin($canv);
} 


sub drawPlot {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $canv, $template) = @_;
   my ($xmin, $ymin, $xmax, $ymax) = $self->getPlotLimits;

   # we leave the outline undef because other calls draw the
   # actual edges with different tags.  The call is needed here
   # so that we get the $self."border" tag in place
   $canv->createPolygon( $xmin, $ymax,       $xmax, $ymax,
                         $xmax, $ymin,       $xmin, $ymin,
                         $xmin, $ymax,
		                   -width   => $self->{-borderwidth},
                         -fill    => undef,
                         -outline => undef,
                         -tag     => ["$self", $self."background", $self."border"] );
   # because the axes are separately drawn on all four sides, we do not really
   # need the metapost output here.

   # do not form the bindings if started in display only mode                   
   unless($::CMDLINEOPTS{'nobind'}) {
      $canv->bind($self."background", "<Button-1>",
      sub { my @seltags = ( $self."lowerleft",
                            $self."lowerright",
                            $self."upperright",
                            $self."upperleft",
                            $self."middlebottom",
                            $self."middleright",
                            $self."middletop",
                            $self."middleleft");
            if($::DIALOG{-SELECTEDPLOT} eq "") {
               $::DIALOG{-SELECTEDPLOT} = $self;
               my $s = $::MW->fpixels('0.075i');
               my @args = ($self,$canv,$template);
               &createSqonSel(@args,$xmin,$ymax,$s,0,$seltags[0]);
               &createSqonSel(@args,$xmax,$ymax,$s,0,$seltags[1]);
               &createSqonSel(@args,$xmax,$ymin,$s,0,$seltags[2]);
               &createSqonSel(@args,$xmin,$ymin,$s,0,$seltags[3]);
               
               &createSqonSel(@args,(($xmin+$xmax)/TWO),$ymax,$s,0,$seltags[4]);
               &createSqonSel(@args,$xmax,(($ymax+$ymin)/TWO),$s,0,$seltags[5]);
               &createSqonSel(@args,(($xmin+$xmax)/TWO),$ymin,$s,0,$seltags[6]);
               &createSqonSel(@args,$xmin,(($ymax+$ymin)/TWO),$s,0,$seltags[7]);
               
               &{$template->{-markrulerXY}}($canv,$xmin,$ymax, "plotline1",'blue');
               &{$template->{-markrulerXY}}($canv,$xmax,$ymin, "plotline2",'blue');
               &{$template->{-markrulerXY}}($canv,(($xmin+$xmax)/TWO),
                                                ($ymax+$ymin), "plotline3",'blue');
            }
            else { $canv->delete("selectedplot"); $::DIALOG{-SELECTEDPLOT} = "";
                   foreach (@seltags) {
                      $canv->bind($_,"<Button-1>","");
                      $canv->delete($_);
                   }
               &{$template->{-markrulerXY}}($canv,undef,undef, "plotline1",undef);
               &{$template->{-markrulerXY}}($canv,undef,undef, "plotline2",undef);
               &{$template->{-markrulerXY}}($canv,undef,undef, "plotline3",undef);

            } } );
   
      $canv->bind($self."background", "<Double-Button-1>", sub {
                  $self->PlotEditor($canv, $template); return; } );
   }
   
   my @args = ($self, $canv, $template, $xmin, $ymin, $xmax, $ymax);
   &_draw_xaxis(@args);
   &_draw_first_yaxis(@args);
   &_draw_second_yaxis(@args);
   
   &_plotTitle($self, $canv);
   
   &_xaxisLabel($self, $canv)        unless($self->{-x}->{-type}  =~ m/time/o);
   &_yaxisLabel($self, $canv, '-y')  unless($self->{-y}->{-type}  =~ m/time/o);
   &_yaxisLabel($self, $canv, '-y2') unless($self->{-y2}->{-type} =~ m/time/o);
    
    
   my $moveplot = sub { my $canv = shift;
                        # Do not permit the grabbing and movement of a plot
                        # when an explanation is already being moved around
                        # We do not have to worry about annotation at this
                        # time because annotation is moved around with the
                        # left mouse button.
                        return if($::DIALOG{-SELECTEDEXPLANATION});
                        if($::DIALOG{-SELECTEDPLOT}) {
                           $canv->delete("rectplot");
                           $::DIALOG{-SELECTEDPLOT} = "";
                        }
                        else {
                           my @coord = $canv->bbox($self."background");
                           my ($width, $height) = ( $coord[2] - $coord[0], $coord[3] - $coord[1] );
                           $::DIALOG{-SELECTEDPLOT} =
                                     $canv->createRectangle(@coord,
                                                            -tag     => "rectplot",
                                                            -outline => 'red');
                           my @args = ($canv, $template, $self, $width, $height);
                           my $move = Tkg2::Plot::Movements::MovingPlot->new(@args);
                           $move->bindStart;
                        }
                      };                  
                        
   # do not form the bindings if started in display only mode                   
   unless($::CMDLINEOPTS{'nobind'}) {
      $canv->bind($self."background", "<Button-3>", $moveplot );
   }
}


sub _yaxisLabel {
   my ($self, $canv, $yax, $offset) = @_; 
   my ($xmin, $ymin, $xmax, $ymax) = $self->getPlotLimits;  
   my $yref  = $self->{$yax};
   my $double_y = $self->{-y2}->{-turned_on};  # DOUBLE Y, is it turned on
   return if($yax eq '-y2' and not $double_y); # DOUBLE Y
 
   my $ftref = $yref->{-labfont};
   &deleteFontCache(); # Perl 5.8.3 and Tk 804.027 error trapping
   my $ylabfont = $canv->fontCreate($self."ylabfont",
                     -family => $ftref->{-family},
                     -size   => ($ftref->{-size}*
                                 $::TKG2_ENV{-SCALING}*
                                 $::TKG2_CONFIG{-ZOOM}),
                     -weight => $ftref->{-weight},
                     -slant  => $ftref->{-slant});
   
      $offset  =  $yref->{-laboffset} if(not defined $offset);                    
   my $offset2 = ($yref->{-lab2offset}) ? $yref->{-lab2offset} : 0;
   $yref->{-lab2offset} = $offset2; # insure population of the hash
   # for proper backwards compatability and correct operation of --batchsave
   
   my $text = $yref->{-title};
   $text =~ s/(.)/$1\n/g if($ftref->{-stackit});

   my $_leftLabel = sub {
         my $text = shift;
         return if($text eq "");
         my ($x,$y) = (($xmin - $offset),
                       ($self->{-ypixels}/TWO + $ymin - $offset2));
         $canv->createText( $x, $y,
                            -text    => $text,
                            -fill    => $ftref->{-color},
                            -tag     => [ "$self",
                                           $self."label",
                                           $self."ytitle"],
                            -justify => 'center',
                            -anchor  => 'center',
                            -font    => $ylabfont);
         createAxisTitlesMetaPost($x,$y,"nosuffix",
                                       {-offset  => $offset,
                                        -text    => $text,
                                        -angle   => $ftref->{-rotation},
                                        -fill    => $ftref->{-color},
                                        -family  => $ftref->{-family},
                                        -size    => $ftref->{-size},
                                        -weight  => $ftref->{-weight},
                                        -slant   => $ftref->{-slant},
                                        -anchor  => 'center',
                                        -justify => 'center',
                                        -blankit => $yref->{-blankit},
                                        -blankcolor => $yref->{-blankcolor}});

         &__blankit($canv,
                    $yref->{-blankit},
                    $yref->{-blankcolor}, $self."ytitle");
                        };

   my $_rightLabel = sub {      
         my $text = shift;
         return if($text eq "");   
         my ($x,$y) = (($xmax + $offset),
                       ($self->{-ypixels}/TWO + $ymin - $offset2));
         $canv->createText($x,$y,
                            -text    => $text,
                            -fill    => $ftref->{-color},
                            -tag     => [ "$self",
                                           $self."label",
                                           $self."ytitle"],
                            -justify => 'center',
                            -anchor  => 'center',
                            -font    => $ylabfont);
         createAxisTitlesMetaPost($x,$y,"nosuffix",
                                       {-offset  => $offset,
                                        -text    => $text,
                                        -angle   => $ftref->{-rotation},
                                        -fill    => $ftref->{-color},
                                        -family  => $ftref->{-family},
                                        -size    => $ftref->{-size},
                                        -weight  => $ftref->{-weight},
                                        -slant   => $ftref->{-slant},
                                        -anchor  => 'center',
                                        -justify => 'center',
                                        -blankit => $yref->{-blankit},
                                        -blankcolor => $yref->{-blankcolor}});
         &__blankit($canv,
                    $yref->{-blankit},
                    $yref->{-blankcolor}, $self."ytitle");
                        };
   
   
   unless($yref->{-hideit}) {
      my $location = $yref->{-location}; 
      if(not $yref->{-probUSGStype}) {
         if($location eq 'left') {
           &$_leftLabel($text);
           if($yref->{-labelequation} =~ m/;/o) {
              my ($text) = $yref->{-labelequation} =~ m/(.*);/o;
              $text =~ s/\\n/\n/g;
              $text =~ s/(.)/$1\n/g if($ftref->{-stackit});
              &$_rightLabel($text);
           }
         }
         elsif($location eq 'right') {
           &$_rightLabel($text);
         }
      }
      else { # when RI style probabability is turned on then no
             # distinction between labeling by location is made.     
         my $text = 'RECURRENCE INTERVAL, IN YEARS';
         $text =~ s/(.)/$1\n/g;
         my ($x,$y) = (( $xmax + ($yref->{-numoffset}*6) ),
                       ($self->{-ypixels}/TWO + $ymin - $offset2));
         $canv->createText( $x,$y,
                            -text    => $text,
                            -fill    => $ftref->{-color},
                            -tag     => [ "$self", $self."label", $self."ytitle"],
                            -justify => 'center',
                            -font    => $ylabfont); 
         createAxisTitlesMetaPost($x,$y,"nosuffix",
                                       {-offset  => $offset,
                                        -text    => $text,
                                        -angle   => $ftref->{-rotation},
                                        -fill    => $ftref->{-color},
                                        -family  => $ftref->{-family},
                                        -size    => $ftref->{-size},
                                        -weight  => $ftref->{-weight},
                                        -slant   => $ftref->{-slant},
                                        -anchor  => 'center',
                                        -justify => 'center',
                                        -blankit => $yref->{-blankit},
                                        -blankcolor => $yref->{-blankcolor}});
         &__blankit($canv,
                    $yref->{-blankit},
                    $yref->{-blankcolor}, $self."ytitle");                   
         my $exnonex = ($yref->{-invertprob}) ? "EXCEEDANCE" : "NONEXCEEDANCE";
         $text = "ANNUAL\n$exnonex\nPROBABILITY,\nIN PERCENT";

         ($x,$y) = (($xmin - $offset ),
                    ($self->{-ypixels}/TWO + $ymin - $offset2));
         $canv->createText( $x, $y,
                            -text    => $text,
                            -fill    => $ftref->{-color},
                            -tag     => [ "$self", $self."label", $self."ytitle"],
                            -justify => 'center',
                            -font    => $ylabfont);
         createAxisTitlesMetaPost($x,$y,"nosuffix",
                                       {-offset  => $offset,
                                        -text    => $text,
                                        -angle   => $ftref->{-rotation},
                                        -fill    => $ftref->{-color},
                                        -family  => $ftref->{-family},
                                        -size    => $ftref->{-size},
                                        -weight  => $ftref->{-weight},
                                        -slant   => $ftref->{-slant},
                                        -anchor  => 'center',
                                        -justify => 'center',
                                        -blankit => $yref->{-blankit},
                                        -blankcolor => $yref->{-blankcolor}});
         &__blankit($canv,
                    $yref->{-blankit},
                    $yref->{-blankcolor}, $self."ytitle");
      }
   } # END Y LABEL
   $canv->fontDelete($self."ylabfont");
}


## AXIS BINDING SUBROUTINES -- Real drawing in the Labeling routines
sub _draw_xaxis {
   my ($plot, $canv, $template, $xmin, $ymin, $xmax, $ymax) = @_;
   my $discrete = $plot->{-x}->{-discrete}->{-doit};
   
   # don't fill the line, leave it empty because really drawn in
   # by axis labeling routines, things don't look right when multiple
   # dashed lines are plotted on top of each other
   my @args = (-width => $plot->{-borderwidth},
               -fill  => undef,
               -tag   => [ "$plot", $plot."bounds", $plot."xaxis" ] );

   # do not form the bindings if started in display only mode
   return if($::CMDLINEOPTS{'nobind'});                
   &adjustCursorBindings($canv,$plot."xaxis");
   $canv->bind($plot."xaxis", "<Double-Button-1>",
         sub { if($discrete) {
                 $plot->DiscreteAxisEditor($canv, $template,'X');
               }
               else {
                 $plot->ContinuousAxisEditor($canv, $template,'X');
               }
             } );                                                          
}

sub _draw_first_yaxis { 
   my ($plot, $canv, $template, $xmin, $ymin, $xmax, $ymax) = @_; 
   my $discrete = $plot->{-y}->{-discrete}->{-doit};
   
   # don't fill the line, leave it empty because really drawn in
   # by axis labeling routines, things don't look right when multiple
   # dashed lines are plotted on top of each other
   my @args = ( -width => $plot->{-borderwidth},
                -fill  => undef,
                -tag   => [ "$plot", $plot."bounds", $plot."yaxis1" ] );

   # do not form the bindings if started in display only mode                   
   return if($::CMDLINEOPTS{'nobind'});
   &adjustCursorBindings($canv,$plot."yaxis1");
   $canv->bind($plot."yaxis1", "<Double-Button-1>",
         sub { if($discrete) {
                 $plot->DiscreteAxisEditor($canv, $template,'-y');
               }
               else {
                 $plot->ContinuousAxisEditor($canv, $template,'-y');
               }
             } );
}   

sub _draw_second_yaxis {
   my ($plot, $canv, $template, $xmin, $ymin, $xmax, $ymax) = @_;
   my $discrete1 = $plot->{-y}->{-discrete}->{-doit};
   my $discrete2 = $plot->{-y2}->{-discrete}->{-doit};
   
   # don't fill the line, leave it empty because really drawn in
   # by axis labeling routines, things don't look right when multiple
   # dashed lines are plotted on top of each other
   my @args = ( -width => $plot->{-borderwidth},
                -fill  => undef ); # We tag the second axis later
   
   return if($::CMDLINEOPTS{'nobind'} or not $plot->{-y2}->{-turned_on});
  
   &adjustCursorBindings($canv,$plot."yaxis2");                                
   $canv->bind($plot."yaxis2", "<Double-Button-1>",
         sub { if($discrete2) {
                 $plot->DiscreteAxisEditor($canv, $template,'-y2');
               }
               else {
                 $plot->ContinuousAxisEditor($canv, $template,'-y2');
               }
             } );
} 
## END OF AXIS DRAWING AND BINDING


sub _plotTitle {
   my ($self, $canv) = @_;
   
   my $ftref = $self->{-plottitlefont};
   &deleteFontCache(); # Perl 5.8.3 and Tk 804.027 error trapping
   my $plottitlefont = $canv->fontCreate($self."plottitlefont",
                     -family => $ftref->{-family},
                     -size   => ($ftref->{-size}*
                                 $::TKG2_ENV{-SCALING}*
                                 $::TKG2_CONFIG{-ZOOM}),
                     -weight => $ftref->{-weight},
                     -slant  => $ftref->{-slant});
   my $text = $self->{-plottitle};
   $text =~ s/(.)/$1\n/g if($ftref->{-stackit});                  
   my ($x,$y) = (($self->{-xlmargin} + $self->{-xpixels}/TWO +
                                       $self->{-plottitlexoffset}),
                 ($self->{-yumargin}-$self->{-plottitleyoffset}));
   $canv->createText( $x, $y,
                      -text    => $text,
                      -fill    => $ftref->{-color},
                      -tag     => [ "$self", $self."label", $self."title"],
                      -justify => $self->{-plottitlejustify},
                      -anchor  => 'n',
                      -font    => $plottitlefont);
   createAxisTitlesMetaPost($x,$y,"nosuffix",
                                 {-offset  => 0,
                                  -text    => $text,
                                  -angle   => $ftref->{-rotation},
                                  -fill    => $ftref->{-color},
                                  -family  => $ftref->{-family},
                                  -size    => $ftref->{-size},
                                  -weight  => $ftref->{-weight},
                                  -slant   => $ftref->{-slant},
                                  -anchor  => 'center',
                                  -justify => 'center'});
   $canv->fontDelete($self."plottitlefont");
}

sub _xaxisLabel {
   my ($self, $canv, $offset) = @_;
   my ($xmin, $ymin, $xmax, $ymax) = $self->getPlotLimits;
   my $xref = $self->{-x};
   
   # LABELING ON THE X-AXIS
   # STARTS HERE
   my $ftref = $xref->{-labfont};
   &deleteFontCache(); # Perl 5.8.3 and Tk 804.027 error trapping
   my $xlabfont = $canv->fontCreate($self."xlabfont",
                     -family => $ftref->{-family},
                     -size   => ($ftref->{-size}*
                                 $::TKG2_ENV{-SCALING}*
                                 $::TKG2_CONFIG{-ZOOM}),
                     -weight => $ftref->{-weight},
                     -slant  => $ftref->{-slant});
   
      $offset  =  $xref->{-laboffset} if(not defined $offset);
   my $offset2 = ($xref->{-lab2offset}) ? $xref->{-lab2offset} : 0;
   $xref->{-lab2offset} = $offset2; # insure population of the hash
   # for proper backwards compatability and correct operation of --batchsave
   
   my $text = $xref->{-title};
   $text =~ s/(.)/$1\n/g if($ftref->{-stackit});

   my $_bottomLabel = sub {
         my $text = shift;
         return if($text eq "");
         my ($x,$y) = (($xmin + ( $self->{-xpixels} / 2 ) + $offset2),
                       ($ymax + $offset));
         $canv->createText( $x,$y,
                            -text    => $text,
                            -fill    => $ftref->{-color},
                            -tag     => [ "$self", $self."label", $self."xtitle"],
                            -justify => 'center',
                            -anchor  => 'n',
                            -font    => $xlabfont);
         createAxisTitlesMetaPost($x,$y,"nosuffix",
                                        {-offset  => $offset,
                                         -text    => $text,
                                         -angle   => $ftref->{-rotation},
                                         -fill    => $ftref->{-color},
                                         -family  => $ftref->{-family},
                                         -size    => $ftref->{-size},
                                         -weight  => $ftref->{-weight},
                                         -slant   => $ftref->{-slant},
                                         -anchor  => 'center',
                                         -justify => 'center',
                                         -blankit => $xref->{-blankit},
                                         -blankcolor => $xref->{-blankcolor}});
          &__blankit($canv,
                     $xref->{-blankit},
                     $xref->{-blankcolor}, $self."xtitle");
                          };
                          
   my $_topLabel = sub {
         my $text = shift;
         return if($text eq "");
         my ($x,$y) = (($xmin + ( $self->{-xpixels} / 2 ) + $offset2 ),
                       ($ymin - $offset));
         $canv->createText( $x,$y,
                            -text    => $text,
                            -fill    => $ftref->{-color},
                            -tag     => [ "$self", $self."label", $self."xtitle"],
                            -justify => 'center',
                            -anchor  => 's',
                            -font    => $xlabfont);
         createAxisTitlesMetaPost($x,$y,"nosuffix",
                                        {-offset  => $offset,
                                         -text    => $text,
                                         -angle   => $ftref->{-rotation},
                                         -fill    => $ftref->{-color},
                                         -family  => $ftref->{-family},
                                         -size    => $ftref->{-size},
                                         -weight  => $ftref->{-weight},
                                         -slant   => $ftref->{-slant},
                                         -anchor  => 'center',
                                         -justify => 'center',
                                         -blankit => $xref->{-blankit},
                                         -blankcolor => $xref->{-blankcolor}});
         &__blankit($canv,
                    $xref->{-blankit},
                    $xref->{-blankcolor}, $self."xtitle");
                       };                      


   unless($xref->{-hideit}) {
      if(not $xref->{-probUSGStype}) {
         if($xref->{-location} eq 'bottom') {
           &$_bottomLabel($text);
           if($xref->{-labelequation} =~ m/;/o) {
              my ($text) = $xref->{-labelequation} =~ m/(.*);/o;
              $text =~ s/\\n/\n/g;
              $text =~ s/(.)/$1\n/g if($ftref->{-stackit});
              &$_topLabel($text);
           }
         }
         else {
           &$_topLabel($text);
         }
      }
      else { # when RI style probabability is turned on then no
             # distinction between labeling by location is made.              
         my $text = 'RECURRENCE INTERVAL, IN YEARS';
         $canv->createText( ($xmin + ( $self->{-xpixels} / 2 ) + $offset2 ),
                            ($ymin - $offset),
                         -text    => $text,
                         -fill    => $ftref->{-color},
                         -tag     => [ "$self", $self."label", $self."xtitle"],
                         -justify => 'center',
                         -anchor  => 's',
                         -font    => $xlabfont); 

         &__blankit($canv,
                    $xref->{-blankit},
                    $xref->{-blankcolor}, $self."xtitle");


         my $exnonex = ($xref->{-invertprob}) ? "EXCEEDANCE" : "NONEXCEEDANCE";
         $text = "ANNUAL $exnonex PROBABILITY, IN PERCENT";
         my ($x,$y) = (($xmin + ( $self->{-xpixels} / 2 ) + $offset2 ),
                       ($ymax + $offset));
         $canv->createText($x,$y,
                         -text    => $text,
                         -fill    => $ftref->{-color},
                         -tag     => [ "$self", $self."label", $self."xtitle"],
                         -justify => 'center',
                         -anchor  => 'n',
                         -font    => $xlabfont);
         createAxisTitlesMetaPost($x,$y,"nosuffix",
                                        {-offset  => $offset,
                                         -text    => $text,
                                         -angle   => $ftref->{-rotation},
                                         -fill    => $ftref->{-color},
                                         -family  => $ftref->{-family},
                                         -size    => $ftref->{-size},
                                         -weight  => $ftref->{-weight},
                                         -slant   => $ftref->{-slant},
                                         -anchor  => 'center',
                                         -justify => 'center',
                                         -blankit => $xref->{-blankit},
                                         -blankcolor => $xref->{-blankcolor}});

         &__blankit($canv,
                    $xref->{-blankit},
                    $xref->{-blankcolor}, $self."xtitle");
      }
   } # END X LABEL
   $canv->fontDelete($self."xlabfont");
}

1;
