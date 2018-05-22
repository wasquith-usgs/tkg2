package Tkg2::Draw::DrawPointStuff;

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
# $Date: 2008/01/18 16:05:57 $
# $Revision: 1.62 $

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $SHUFFLE @LINE_CACHE %OVERLAP_CACHE);
use Exporter;
use Tkg2::Math::Geometry qw( line_intersect );
use Tkg2::Math::GraphTransform qw(transReal2CanvasGLOBALS
                                  transReal2CanvasGLOBALS_Xonly
                                  transReal2CanvasGLOBALS_Yonly 
                                  revAxis);
use Tkg2::Base qw(Message
                  isNumber
                  randarray
                  canvas_all_coords
                  commify
                  Show_Me_Internals
                  deleteFontCache);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createOvalMetaPost
                                                createPolygonMetaPost
                                                createLineMetaPost
                                                createAnnoTextMetaPost);

@ISA       = qw(Exporter);
@EXPORT    = qw( drawText drawPoints createSqonSel drawSpecialPlot);
@EXPORT_OK = qw( _reallydrawpoints _drawsometext delOverlapCache);

use constant RADIAN => scalar 3.14159265359 / 180;
use constant TWO    => scalar   2;
use constant S30    => scalar  30;
use constant S45    => scalar  45;
use constant S60    => scalar  60;
use constant S90    => scalar  90;
use constant S135   => scalar 135;
use constant S180   => scalar 180;
use constant S225   => scalar 225;
use constant S270   => scalar 270;
use constant S315   => scalar 315;

print $::SPLASH "=";
@LINE_CACHE = ();  # Cache of coords for 'connectedline' tags
                   # Provides huge speed increase over
                   # repetitive $canv->coords('connectedline') calls
                   
%OVERLAP_CACHE = ();  # Cache of the overlap correction angle
                      # The key is a unique identifier on the leader
                      # line.

sub delOverlapCache {
   %OVERLAP_CACHE = ();
}

sub drawSpecialPlot {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my ($plot, $canv) = @_;
   my $dataclass = $plot->{-dataclass};
   my ($dataset, $data);
   foreach $dataset (@$dataclass) {
      foreach $data ( @{ $dataset->{-DATA} } ) {
         next unless( ref $data->{-attributes}->{-special_plot} );
         &_drawSpecialPlot($plot, $canv, $data);
      }
   }   
}

sub _drawSpecialPlot {
   my ($plot, $canv, $dataset) = @_;
   my $special_plot_style = $dataset->{-attributes}->{-special_plot};
   my $which_y_axis = $dataset->{-attributes}->{-which_y_axis}; # DOUBLE Y
   my $yax = ($which_y_axis == 2) ? '-y2' : '-y'; # DOUBLE Y
   my $tag = "$plot"."$dataset->{-data}"."specialplot";
   
   my $xref      = $plot->{-x};
   my $yref      = $plot->{$yax}; # DOUBLE Y
   my $xtype     = $xref->{-type};
   my $ytype     = $yref->{-type};
   my $revx      = $xref->{-reverse};
   my $revy      = $yref->{-reverse};
   my $xdiscrete = $xref->{-discrete}->{-doit};
   my $ydiscrete = $yref->{-discrete}->{-doit}; 
 
   my $i = 0;
   $plot->setGLOBALS($yax); # DOUBLE Y
   foreach my $pair ( @{ $dataset->{-data} } ) {
      $i++;
      
      my @vals = @{$pair};
      my ($unloadx, $unloady, $extra1) = ($vals[0], $vals[1], $vals[2]);
      my $x = ($xdiscrete and ref $unloadx eq 'ARRAY') ? $unloadx->[0] : $unloadx;
      my $y = ($ydiscrete and ref $unloady eq 'ARRAY') ? $unloady->[0] : $unloady;
      
      next if($x eq 'missingval' or $y eq 'missingval');
 
      $x = &transReal2CanvasGLOBALS_Xonly($plot, $xtype, 1, $x);
      next if(not defined $x);
      $y = &transReal2CanvasGLOBALS_Yonly($plot, $ytype, 1, $y);
      next if(not defined $y );
      $x = &revAxis($plot,'-x',$x) if($revx);
      $y = &revAxis($plot,'-y',$y) if($revy);
      
      $extra1->draw($plot,$canv,$x,$y,$tag,$special_plot_style,$yax);
   }
}


############## BEGINNING OF TEXT DRAWING ALGORITHMS #####################
# drawText
# wrapper for _drawTextorSpecialPlot
# iterates of each data class and each data set within each data class
# and calls _drawText for each data set.
sub drawText {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
      
   my ($plot, $canv) = @_;
   my $dataclass = $plot->{-dataclass};
   my ($dataset, $data);
   foreach $dataset (@$dataclass) {
      foreach $data ( @{ $dataset->{-DATA} } ) {
         next unless( $data->{-attributes}->{-plotstyle} =~ /text/io and
                      $data->{-attributes}->{-text}->{-doit} );
         &_drawText($plot, $canv, $data);
      }
   }   
}

# _drawText
# called by drawText
# parameter set up and loop through each data pair in the data set
# and call the _drawsometext to actually place the text on the canvas
sub _drawText {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   @LINE_CACHE = (); # we are on a new suite of text objects
                     # so the LINE_CACHE needs to be deleted
                     # so that the leader line overlap
                     # subroutine (_do_leader_lines_overlap)
                     # will know that it needs to query the
                     # canvas for the coordinates of 'connectedline'
   
   my ($plot, $canv, $dataset) = @_;
   my $istext = $dataset->{-attributes}->{-plotstyle};
   return unless($istext);   
   my $tag = "$plot"."$dataset->{-data}"."text";
   my $attref = $dataset->{-attributes};
   my $attr   = $attref->{-text};
   my $ftref  = $attr->{-font};
   &deleteFontCache(); # Perl 5.8.3 and Tk 804.027 error trapping
   my $font   = $canv->fontCreate($tag."textfont",
                     -family => $ftref->{-family},
                     -size   => ($ftref->{-size}*
                                 $::TKG2_ENV{-SCALING}*
                                 $::TKG2_CONFIG{-ZOOM}),
                     -weight => $ftref->{-weight},
                     -slant  => $ftref->{-slant} );
   my $xref      = $plot->{-x};
   my $yax = ( $attref->{-which_y_axis} == 2 ) ? '-y2' : '-y';  # DOUBLE Y:
   my $yref      = $plot->{$yax};  # DOUBLE Y:
   my $xtype     = $xref->{-type};
   my $ytype     = $yref->{-type};
   my $revx      = $xref->{-reverse};
   my $revy      = $yref->{-reverse};
   my $xdiscrete = $xref->{-discrete}->{-doit};
   my $ydiscrete = $yref->{-discrete}->{-doit};      
   
   
   $plot->setGLOBALS($yax);
   foreach my $pair ( @{ $dataset->{-data} } ) {
      
      my @vals = @{$pair};
      my ($unloadx, $unloady, $extra1) = ($vals[0], $vals[1], $vals[2]);
      my $x = ($xdiscrete and ref $unloadx eq 'ARRAY') ? $unloadx->[0] : $unloadx;
      my $y = ($ydiscrete and ref $unloady eq 'ARRAY') ? $unloady->[0] : $unloady;
      
      next if($x eq 'missingval' or $y eq 'missingval');
 
      $x = &transReal2CanvasGLOBALS_Xonly($plot, $xtype, 1, $x);
      next if(not defined $x);
      $y = &transReal2CanvasGLOBALS_Yonly($plot, $ytype, 1, $y);
      next if(not defined $y );
      $x = &revAxis($plot,'-x',$x) if($revx);
      $y = &revAxis($plot,'-y',$y) if($revy);

      &_drawsometext($canv,$x,$y,$extra1,$attr,$font,$tag);
   }
   $canv->fontDelete($tag."textfont"); 
   $canv->idletasks unless($::CMDLINEOPTS{'batch'});
}



# _drawsometext
# called by _drawText
# the final code the draw a single text element
# provides a proprocessor to handle number formating and leader lines too
sub _drawsometext {
   my ($canv, $x, $y, $text, $attr, $font, $tag) = @_;
   my $ftref = $attr->{-font};
   
   my $anchor  = $attr->{-anchor};
   my $justify = $attr->{-justify};
   my $numcommify  = $attr->{-numcommify};
   my $numformat   = $attr->{-numformat};
   my $numdecimal  = $attr->{-numdecimal};
   my $leaderline  = $attr->{-leaderline};
   my $format;

   if(defined $text and &isNumber($text)) { # consider formatting only if number
      unless($numformat eq 'free') {
         FORMAT: {
            $format = "%0.$numdecimal"."e", last FORMAT if($numformat eq 'sci');
            $format = "%0.$numdecimal"."f", last FORMAT if($numformat eq 'fixed');
            $format = "%0.$numdecimal"."g", last FORMAT if($numformat eq 'sig');
         }
         $text = sprintf("$format", $text);
      }
      $text = &commify($text) if($numcommify);
   }
   
   $text =~ s/(.)/$1\n/og if($ftref->{-stackit});
   return unless(defined $text);
   
   # great the text can be drawn, but first lets see about drawing
   # a leader line
   if( $leaderline->{-doit} and @{$leaderline->{-lines}} ) {
      ($x, $y) = &_create_leader_lines($canv,$tag,$x,$y,$leaderline,$text);
   }
   else {   
      # no leader line
      $x += $attr->{-xoffset};
      $y -= $attr->{-yoffset};
   }
   
   
   # Finally draw the text, but first we must do some checking on the 
   # tag that was passed into the subroutine.  For the plot rendering
   # tag is a scalar, but during drawing of the explanation tag is
   # necessarily an array reference.  Thus two different methods of
   # getting the 'textplot' tag--which is temporary are needed.
   my $blanking_tag;
   # the incoming tag is ONLY and ARRAY when called from the explanation
   # oriented drawing algorithm, thus we change the tagging to avoid
   # massive blanking of the screen.  The $blanking_tag is a bug fix
   # for 0.53-4+ on January 26, 2000.
   if(ref $tag eq 'ARRAY') {
      $blanking_tag = 'explanation';
      push(@$tag, 'explanation'); 
   }
   else {
      $blanking_tag = 'textplot';
      $tag = [ $tag, 'textplot' ];
   }
   $canv->createText($x,$y, -text    => $text,
                            -font    => $font,
                            -justify => $justify,
                            -anchor  => $anchor,
                            -fill    => $ftref->{-color},
                            -tags => $tag);                  
   createAnnoTextMetaPost($x,$y, {-text    => $text,
                                 -family  => $ftref->{-family},
                                 -size    => $ftref->{-size},
                                 -weight  => $ftref->{-weight},
                                 -slant   => $ftref->{-slant},
                                 -justify => $justify,
                                 -anchor  => $anchor,
                                 -angle   => $ftref->{-rotation},
                                 -fill    => $ftref->{-color},
                                 -blankit => $ftref->{-blankit},
                                 -blankcolor => $ftref->{-blankcolor}});   

   # although the sub _blankit provides for a check whether to blankit or not
   # I choose to test above the sub too to avoid the cost of calling yet
   # another subroutine hundreds of times
   &_blankit($canv, $ftref, $blanking_tag ) if( $ftref->{-blankit} );
   Tk::Canvas::dtag($canv,$blanking_tag);
   # We must delete the blanking tag because it is unneeded and if
   # we have a text plot without blanking that is then followed by another
   # text plot, we will get a huge bounding box on the left over blanking
   # tag from the first text plot.  BUG FIX FOR 0.60-2, 5/24/2001.
}  


# _blankit is a little sub that colors in behind a symbol or text object
# drawn on the screen.
sub _blankit {
   my ($canv, $attr, $tag) = @_;
   return unless($attr->{-blankit});
   # the following is color check is just for safety, although at
   # this point paranoid is likely not needed, but o'well.
   $attr->{-blankcolor} = 'white' if( not defined $attr->{-blankcolor} );             
   my @coord = Tk::Canvas::bbox($canv,$tag);
   return unless(@coord == 4); # return quietly for safety for tag problems
   Tk::Canvas::createRectangle($canv, @coord,
                          -outline => $attr->{-blankcolor},
                          -fill    => $attr->{-blankcolor},
                          -tags    => [ $tag."blankit" ]);
   # The newly created Rectangle requires being hidden behind the text                       
   Tk::Canvas::raise($canv, $tag, $tag."blankit");  
   Tk::Canvas::dtag($canv,$tag); # now delete the temporary tag to the canvas does
   # not get progressively filled up with the tag and then pretty soon
   # the entire portions of the canvas are blanked out
}

  
# _create_leader_lines
# called by _drawsometext
# really draws the leader line segment(s) on the canvas
sub _create_leader_lines {
   my ($canv, $tag, $x, $y, $leaderline, $text) = @_; # no shifting for speed
   my $unique_line_tag = "$tag-leaderline:$text";

   # BACKWARDS COMPATABILITY FOR 0.60-2 AND BELOW
   $leaderline->{-flip_lines_with_shuffle} = 1
      unless(exists $leaderline->{-flip_lines_with_shuffle});
   # The original shuffling had reversing.  Users have requested
   # that non reverse be available.  The above invigorates
   # the key if needed and makes true to transparently support
   # old behavior.  WHA 6/4/2001
   $leaderline->{-overlap_correction_doit} = 0
      unless(exists $leaderline->{-overlap_correction_doit});
   # END OF BACKWARDS COMPATABILITY
   
   my %leaderline = %$leaderline;
   
   if($leaderline{-shuffleit}) { 
      $SHUFFLE = 1 if(++$SHUFFLE == 5);
   }
   else {
      $SHUFFLE = 1;
   }
   my ($REVERSE, $JUMP) = ($SHUFFLE == 2) ? (1,0) :
                          ($SHUFFLE == 3) ? (0,1) :
                          ($SHUFFLE == 4) ? (1,1) : (0,0) ;
   
   # Override true reverse unless the flip lines is true
   # we override here because three or more tests on reverse
   # are done in the subroutine and I don't want to test
   # for flipping again and again
   $REVERSE = 0 if(not $leaderline{-flip_lines_with_shuffle});
   
   # Toggle the automatic overlapping leader line correction function
   my $do_overlap_correct = $leaderline{-overlap_correction_doit};
   my $overlap_correction_angle = 0;
   my $overlap_limit            = 4;
   
   my $linewidth = $leaderline{-width}; # the width of the leader line
   my $linecolor = $leaderline{-color}; # the color of the leader line
   
   my ($leadx, $leady, $angle, @lines, $there_was_an_overlap);
   
   if(exists $OVERLAP_CACHE{$unique_line_tag}) {
      $do_overlap_correct = 0; # turn off because we already know the angle
      $overlap_correction_angle = $OVERLAP_CACHE{$unique_line_tag};
      # set the overlap correction angle because we have seen it before
   }
   #print "The overlap correction angle is $overlap_correction_angle\n";
   
   CORR: foreach my $num_overlaps (0..$overlap_limit) {
      my @xy = (); # array of coordinates of the line
      # array of hashes containing the angle and the length of each 
      # leader line segment   
      @lines = @{ $leaderline{-lines} }; 

      # the first coordinates are special 
      $angle  = $lines[0]->{-angle} + $overlap_correction_angle; # first angle
      $angle -= S180 if($REVERSE);
      $angle *= RADIAN;
      # now figure out how far away from the x,y of the data point the
      # leader line should begin
      $leadx = $x + $leaderline{-beginoffset}*cos($angle);
      $leady = $y + $leaderline{-beginoffset}*sin($angle);
      push(@xy, ($leadx, $leady) );
      # push first coordinates onto segment array

      # now loop through the lines
      LINE_PAIR: foreach my $pair (@lines) {
         my %pair   = %$pair; # the hash of angle and length of segment
         my $angle  = $pair{-angle} + $overlap_correction_angle;
         $angle -= S180 if($REVERSE);
         $angle *= RADIAN;
         my $length = $pair{-length};
         $length *= TWO if($JUMP);
         $leadx  += $length*cos($angle);
         $leady  += $length*sin($angle);
         push(@xy, ($leadx, $leady) );
      } 
      
      # Finally, draw the completed leaderline on the canvas and
      # then check for overlapping if desired.
      Tk::Canvas::createLine( $canv, @xy, -width => $linewidth,
                              -fill  => $linecolor,
                              -tags  => [$tag, 'leaderline' ] );
      createLineMetaPost(@xy, {-width => $linewidth, -fill => $linecolor});

      # go ahead and exit the correction block unless overlap      
      # correction is desired
      last CORR if(not $do_overlap_correct);
      
      # test whether the 'leaderline' tagged line(s)--a leader can 
      # have multiple segments--over lap any and all line segments
      # tagged a 'connectedline'.  The line drawing subroutines
      # tag the 'connectedline'.  Both of these tags are temporary
      # and should be deleted after the canvas is updated.
      my $overlap = (&_do_leader_lines_overlap($canv)) ? 1 : 0;
      $there_was_an_overlap = 1 if($overlap);
      
      if($overlap and $num_overlaps < ($overlap_limit-1)) {
         # normally a delete on the leaderline is needed because it
         # overlaps.  However, if we have exhausted the redraw opportunities
         # and still have overlap, then do not execute this code block
         Tk::Canvas::delete($canv,'leaderline');
         if($num_overlaps == 0) {
            # if we have overlap on the original iteration
            # rotate the line 90 degrees clock-wise, otherwise
            # begin the random search
            $overlap_correction_angle = 180;
         }
         else {
            # since, 0 has already been tested and +180 has been
            # too in the potential second loop, these angles are not listed
            # in the array below to randomly select from
            $overlap_correction_angle = &randarray([+90,-90,-270,270]);
         }
      }
      elsif($overlap and $num_overlaps < $overlap_limit) {
         Tk::Canvas::delete($canv,'leaderline');
         $overlap_correction_angle = 0;
      }
   }  # END OF THE CORR LOOP
   
   Tk::Canvas::dtag($canv,'leaderline'); # must have tag removed before next draw

   # the text coordinates needs a little shift
   $angle   = $lines[$#lines]->{-angle} + $overlap_correction_angle;
   $angle  -= S180 if($REVERSE);
   $angle  *= RADIAN;
   my $newx = $leadx + $leaderline{-endoffset}*cos($angle);
   my $newy = $leady + $leaderline{-endoffset}*sin($angle);
   
   # because there is the possibilty that the processing of extensive
   # overlapping leader line is long, let us update the canvas whenever
   # there is an overlap--this allows the user to watch tkg2 working
   # furthermore, this helps the author play with the algorithm
   $canv->update if($there_was_an_overlap);
   
   $OVERLAP_CACHE{$unique_line_tag} = $overlap_correction_angle;
   return ($newx, $newy); # segments of lines, the x and y coords for text
}


sub _do_leader_lines_overlap {
   my ($canv) = @_;
#   &Show_Me_Internals(@_);

   my @line1org = Tk::Canvas::coords($canv,'leaderline');
   return 0 unless(@line1org >= 4);  # must have more than four to work

   # LINE_CACHE is a global array containing array references 
   @LINE_CACHE = &canvas_all_coords($canv,
                                    'connectedline') unless(@LINE_CACHE);
   return 0 unless(@LINE_CACHE);
   

   foreach my $line2 (@LINE_CACHE) {
      my @line1 = @line1org;
      my @line2 = @$line2;
      return 0 unless(@line2 >= 4);  # partial safety check
      
      map {
         my @c1 = splice(@line1,0,2);
         map {
             my @c3 = splice(@line2,0,2);
             return 1 if(&line_intersect(@c1,@line1[(0,1)],
                                         @c3,@line2[(0,1)])
                        );
         } (0..(@line2/4-1));
      } (0..(@line1/4-1)); 
   }
   return 0;
}

############## END OF TEXT DRAWING ALGORITHMS #####################




############## BEGINNING OF POINT DRAWING ALGORITHMS #####################
# drawPoints
# wrapper for _drawPoints
# iterates of each data class and each data set within each data class
# and calls _drawPoints for each data set.
sub drawPoints {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($plot, $canv) = @_;
   my $dataclass = $plot->{-dataclass};
   my ($dataset, $data);
   foreach $dataset (@$dataclass) {
      foreach $data ( @{ $dataset->{-DATA} } ) {
         next unless($data->{-attributes}->{-points}->{-doit});
         &_drawPoints($plot, $canv, $data);
      }
   }
}


# _drawPoints
# called by drawPoints
# parameter set up and loop through each data pair in the data set
# and call the _reallydrawpoints and _drawerrorbar to actually perform the drawing
sub _drawPoints {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($plot, $canv, $dataset) = @_;
   my $tag = "$plot"."$dataset->{-data}"."points";

   my $attref   = $dataset->{-attributes};
   my $pointref = $attref->{-points};
   return 0 unless($pointref->{-doit}); 
   my %attr = ( -symbol       => $pointref->{-symbol},
                -size         => $pointref->{-size},
                -angle        => $pointref->{-angle},
                -outlinecolor => $pointref->{-outlinecolor},
                -outlinewidth => $pointref->{-outlinewidth},
                -fillcolor    => $pointref->{-fillcolor},
                -blankit      => $pointref->{-blankit},
                -blankcolor   => $pointref->{-blankcolor} );
   # The blankits were added for MetaPost, September 2007

   my $original_size = $attr{-size}; # preserve for the potential
                                     # resizing of the symbol from the pscale
                                     # feature
   my $rugx = $pointref->{-rugx};
   my $rugy = $pointref->{-rugy};
   my $rugit = ($rugx->{-doit} or $rugy->{-doit}) ? 1 : 0;
   
   my $num2skip = $pointref->{-num2skip};
   my $skipper  = 0;
   
   my $xref      = $plot->{-x};
   my $yax = ( $attref->{-which_y_axis} == 2 ) ? '-y2' : '-y';  # DOUBLE Y:
   my $yref      = $plot->{$yax};    # DOUBLE Y:
   my $xtype     = $xref->{-type};
   my $ytype     = $yref->{-type};
   my $revx      = $xref->{-reverse};
   my $revy      = $yref->{-reverse};
   my $xdiscrete = $xref->{-discrete}->{-doit};
   my $ydiscrete = $yref->{-discrete}->{-doit};
   
   my $thirdord  = $dataset->{-origthirdord};
   my $plotstyle = $attref->{-plotstyle};
   
   my ($xmin, $ymin, $xmax, $ymax) = $plot->getPlotLimits;
       
   my $i=0;
   $plot->setGLOBALS($yax);   # DOUBLE Y:
   my $yes_draw_point = 1;
   foreach my $pair ( @{ $dataset->{-data} } ) {
      $i++;
      $yes_draw_point = 1;
      my @vals = @{$pair};
      my ($unloadx, $unloady, $extra1, $extra2 ) = ($vals[0], $vals[1], $vals[2], $vals[3]);
      my $x = ($xdiscrete and ref($unloadx) eq 'ARRAY') ? $unloadx->[0] : $unloadx;
      my $y = ($ydiscrete and ref($unloady) eq 'ARRAY') ? $unloady->[0] : $unloady;
      my ($realx, $realy) = ($x, $y);
      # skipping the drawing of points
      if($num2skip) {
         if($skipper == $num2skip) {  # when $skipper equals $num2skip, reset it and DRAW
            $skipper = 0;
         }
         else {  # else increment the skipper and go on to the next point
            $skipper++;
            next;
         }
      }
      if($dataset->{-origthirdord} and $plotstyle =~ /Error/o) { 
         if($plotstyle eq 'Y-Error Bar' or
            $plotstyle eq 'Y-Error Limits') {
            
            next if($x eq 'missingval');
            $x = &transReal2CanvasGLOBALS_Xonly($plot, $xtype, 1, $x);
            next if(not defined $x );
         
            if($y eq 'missingval') {
               if(ref($extra2) eq 'ARRAY' and &isNumber($extra1->[0]) and
                                              &isNumber($extra1->[1])) {
                 $y = $realy = ($extra1->[0]+$extra1->[1])/2;
                 $yes_draw_point = 0; # set to false because y is faked
               }
               else {
                  next;
               }
            }
            $y = &transReal2CanvasGLOBALS_Yonly($plot, $ytype, 1, $y);
            next if(not defined $y );
          
            $x = &revAxis($plot,'-x',$x) if($revx);
            $y = &revAxis($plot,'-y',$y) if($revy);
         
            
            &_drawerrorbar($plot,$canv,$x,$y,$yax,$extra1,
                           'Y',$attref->{-yerrorbar},$tag,
                           $realx,$realy); #DOUBLE Y:
         
         }
         elsif($plotstyle eq 'X-Y Error Bar' or
               $plotstyle eq 'X-Y Error Limits') {
            
            if($x eq 'missingval') {
               if(ref($extra1) eq 'ARRAY' and &isNumber($extra1->[0]) and
                                              &isNumber($extra1->[1])) {
                  $x = $realx = ($extra1->[0]+$extra1->[1])/2;
                  $yes_draw_point = 0; # set to false because x is faked.
               }
               else {
                  next;
               }
            }
            $x = &transReal2CanvasGLOBALS_Xonly($plot, $xtype, 1, $x);
            next if(not defined $x );
         
            if($y eq 'missingval') {
               if(ref($extra2) eq 'ARRAY' and &isNumber($extra2->[0]) and
                                              &isNumber($extra2->[1])) {
                 $y = $realy = ($extra2->[0]+$extra2->[1])/2;
                 $yes_draw_point = 0; # set to false because y is faked
               }
               else {
                  next;
               }
            }
            $y = &transReal2CanvasGLOBALS_Yonly($plot, $ytype, 1, $y);
            next if(not defined $y );
          
            $x = &revAxis($plot,'-x',$x) if($revx);
            $y = &revAxis($plot,'-y',$y) if($revy);
         
            &_drawerrorbar($plot,$canv,$x,$y,$yax,$extra1,
                           'X',$attref->{-xerrorbar},$tag,
                           $realx,$realy); # DOUBLE Y:
            &_drawerrorbar($plot,$canv,$x,$y,$yax,$extra2,
                           'Y',$attref->{-yerrorbar},$tag,
                           $realx,$realy); # DOUBLE Y:
         }
      }
      else {
        next if($x eq 'missingval' or $y eq 'missingval');
        $x = &transReal2CanvasGLOBALS_Xonly($plot, $xtype, 1, $x);
        next if(not defined $x );
        $y = &transReal2CanvasGLOBALS_Yonly($plot, $ytype, 1, $y);
        next if(not defined $y );
        $x = &revAxis($plot,'-x',$x) if($revx);
        $y = &revAxis($plot,'-y',$y) if($revy);
      }
      
      next unless($yes_draw_point);
            
      # If the plotstyle was Text then a third column that isn't for
      # error bars/limits is available. This column could potentially
      # function as means to scale the symbol size up or down through
      # multiplication with the current point size. We test for defineness
      # of the value and then extract its value. The trigger for value
      # extraction is the 'pscale:' string.
      if( $plotstyle eq 'Text' && 
          defined $extra1      &&
                  $extra1 =~ /pscale:(.+)$/) {
	# only modify the point size if extracted and 
	# the extracted value is a number
        $attr{-size} = $original_size*$1 if(defined $1 && isNumber($1));
      }
      &_reallydrawpoints($canv,$x,$y,[$tag, 'pointplot'],\%attr);
      &_blankit($canv, $pointref, 'pointplot') if( $pointref->{-blankit} );
      if($rugit) { # some sort of rug plot is desired
        &_drawRUG($canv,$x,$y,$xmin,$ymin,$xmax,$ymax,[$tag, 'pointplot'], $rugx, $rugy, $yax);
      }	
   }
   $canv->idletasks unless($::CMDLINEOPTS{'batch'});
}    

# _drawRUG
# called by _drawPoints
# draws the rug elements on the axis edges
sub _drawRUG {
   my ($canv, $x, $y, $xmin, $ymin, $xmax, $ymax, $tag, $rugx, $rugy, $yax) = @_;
   my $firstYaxis = ($yax eq '-y') ? 1 : 0;
   if($rugx->{-doit}) { # draw the x-axis rug plot
     my $outc = $rugx->{-linecolor};
     my $outw = $rugx->{-linewidth};
     my $size = $rugx->{-size};
     my $neg  = $rugx->{-negate};
        $size = ($neg) ? -1*$size : $size;
     my @styleFW  = (-fill,$outc, -width,$outw);
     $canv->createLine($x, $ymax, $x, $ymax-$size, @styleFW, -tag => $tag );
     createLineMetaPost($x, $ymax, $x, $ymax-$size, {@styleFW});
     if($rugx->{-both}) {
       $canv->createLine($x, $ymin, $x, $ymin+$size, @styleFW, -tag => $tag );
       createLineMetaPost($x, $ymin, $x, $ymin+$size, {@styleFW})
     }
   }
   if($rugy->{-doit}) { # draw the y-axis rug plot
     my $outc = $rugy->{-linecolor};
     my $outw = $rugy->{-linewidth};
     my $size = $rugy->{-size};
     my $neg  = $rugy->{-negate};
        $size = ($neg) ? -1*$size : $size;
     my @styleFW  = (-fill,$outc, -width,$outw);
     if($firstYaxis) { # need to have slightly different behavior on y axis
       $canv->createLine($xmin, $y, $xmin+$size, $y, @styleFW, -tag => $tag );
       createLineMetaPost($xmin, $y, $xmin+$size, $y, {@styleFW});
       if($rugy->{-both}) {
         $canv->createLine($xmax, $y, $xmax-$size, $y, @styleFW, -tag => $tag );
         createLineMetaPost($xmax, $y, $xmax-$size, $y, {@styleFW});
       }
     }
     else { # one the second y axis so swap the -both conditional
       if($rugy->{-both}) {
         $canv->createLine($xmin, $y, $xmin+$size, $y, @styleFW, -tag => $tag );
         createLineMetaPost($xmin, $y, $xmin+$size, $y, {@styleFW});
       }
       $canv->createLine($xmax, $y, $xmax-$size, $y, @styleFW, -tag => $tag );   
       createLineMetaPost($xmax, $y, $xmax-$size, $y, {@styleFW}); 
     }
   }
}

# _drawerrorbar
# called by _drawPoint
# actually configures and draws the error bars for a given data point on the canvas  
sub _drawerrorbar {
   my ($plot, $canv, $x, $y, $yax, $extra, $which, $attr, $tag,
                           $realx, $realy) = @_; # DOUBLE Y
   my $whisker = $attr->{-whiskerwidth};
      $whisker = $canv->fpixels($whisker);
   my $color = $attr->{-color};
   my $width = $attr->{-width};
   my ($go1, $go2) = (1 , 1);
   my ($whisker1, $whisker2) = ( 1, 1);
   my ($error1, $error2) = ($extra->[0], $extra->[1]);
   
   my @dashstyle = ();
   push(@dashstyle, (-dash => $attr->{-dashstyle}) )
              if($attr->{-dashstyle} and
                 $attr->{-dashstyle} !~ /Solid/io);
     
   my @style = (-fill,$color,-width,$width,@dashstyle,-tags,$tag);
   my ($xmin, $ymin, $xmax, $ymax) = $plot->getPlotLimits;
   $plot->setGLOBALS($yax); # DOUBLE Y: I think that this line can be removed
                            # but it does follow the convention that any su
                            # calling transReal.... also have the setGLOBALS
                            # called.  This is a safety feature.
      # the two errors are either above and below or left and right and still in realworld units
   my ($error1_was_faked, $error2_was_faked) = (0,0);
   if($which =~ /y/oi) {
      if($extra->[0] eq 'missingval') {
         $error1 = $realy;
         $error1_was_faked = 1;
      }
      if($extra->[1] eq 'missingval') {
         $error2 = $realy;
         $error2_was_faked = 1;
      }
      my $type = $plot->{$yax}->{-type}; # DOUBLE Y:
      my $rev  = $plot->{$yax}->{-reverse};
      $error1 = &transReal2CanvasGLOBALS($plot,'Y', $type, 1, $error1);
      $error2 = &transReal2CanvasGLOBALS($plot,'Y', $type, 1, $error2);
      if(not defined $error1) {
         $error1   = ($rev) ? $ymin : $ymax;
         $whisker1 = 0;
      }
      else {
         $error1 = &revAxis($plot, $yax, $error1) if($rev);
      }
      if(not defined $error2) {
         $error2   = ($rev) ? $ymax : $ymin;
         $whisker2 = 0;
      }
      else {
         $error2 = &revAxis($plot, $yax, $error2) if($rev);
      }
      
      # The go's become false if the error will plot at the same location
      # as the Y value.  If so, there is no need to draw the line at all
      # and to not draw the whiskers either.  In pre0.70-1 tkg2, a whisker
      # would be drawn at the same location as the point symbol and would
      # look ugly.
      $go1 = 0 if($error1 == $y and $error1_was_faked);
      $go2 = 0 if($error2 == $y and $error2_was_faked);
      
      if($go1) {
         $canv->createLine($x,$error1,$x,$y,@style);
         createLineMetaPost($x,$error1,$x,$y,{@style});
         
         if($whisker1) {
           $canv->createLine(($x+$whisker),$error1,($x-$whisker),$error1,@style);
           createLineMetaPost(($x+$whisker),$error1,($x-$whisker),$error1,{@style});
         }    
      }
      if($go2) {
         $canv->createLine($x,$error2,$x,$y,@style);
         createLineMetaPost($x,$error2,$x,$y,{@style});
         if($whisker2) {
           $canv->createLine(($x+$whisker),$error2,($x-$whisker),$error2,@style);
           createLineMetaPost(($x+$whisker),$error2,($x-$whisker),$error2,{@style});
         }
      }
      
      return 1;
   }
   
   # Do the error lines on the X axis 
   if($extra->[0] eq 'missingval') {
      $error1 = $realx;
      $error1_was_faked = 1;
   }
   if($extra->[1] eq 'missingval') {
      $error2 = $realx;
      $error2_was_faked = 1;
   }      
   my $type = $plot->{-x}->{-type};
   my $rev  = $plot->{-x}->{-reverse};
   $error1  = &transReal2CanvasGLOBALS($plot,'X', $type, 1, $error1);
   $error2  = &transReal2CanvasGLOBALS($plot,'X', $type, 1, $error2);
   if(not defined $error1) {
      $error1 = ($rev) ? $xmax : $xmin;
      $whisker1 = 0;
   }
   else {
      $error1 = &revAxis($plot, '-x', $error1) if($rev);
   }
   if(not defined $error2) {
      $error2   = ($rev) ? $xmin : $xmax;
      $whisker2 = 0;
   }
   else {
      $error2 = &revAxis($plot, '-x', $error2) if($rev);
   }
   
   $go1 = 0 if($error1 == $x and $error1_was_faked);
   $go2 = 0 if($error2 == $x and $error2_was_faked);

   if($go1) {
      $canv->createLine($error1,$y,$x,$y,@style);
      createLineMetaPost($error1,$y,$x,$y,{@style});
 
      if($whisker1) {
        $canv->createLine($error1,($y-$whisker),$error1,($y+$whisker),@style);
        createLineMetaPost($error1,($y-$whisker),$error1,($y+$whisker),{@style});
      }
   }
   
   if($go2) {
      $canv->createLine($error2,$y,$x,$y,@style);
      createLineMetaPost($error2,$y,$x,$y,{@style});
      
      if($whisker2) {
        $canv->createLine($error2,($y-$whisker),$error2,($y+$whisker),@style);
        createLineMetaPost($error2,($y-$whisker),$error2,($y+$whisker),{@style});
      }
   }
}   


# _reallydrawpoints
# called by _drawPoints
# a router to call the proper symbol subroutine and perform some last second
# parameter configuration.  This has been really worked on for speed yet
# still trying to make a nicely parallel logic structure.
sub _reallydrawpoints {
   my ($canv, $x, $y, $tag, $attr ) = @_;
   my %attr = %$attr;
   
   my $type = $attr{-symbol};
   my $ang  = $attr{-angle};
   my $outc = $attr{-outlinecolor};
   my $outw = $attr{-outlinewidth};

   # These blankits are for MetaPost, nasty design at this point, but
   # I have few other safe options to get the idea of MetaPost blanking
   # to the subordinate MetaPost calls, 09/07/2007
   my $blankit = $attr{-blankit};
      $blankit = 0 if(not defined $blankit);
   my $blankcolor = $attr{-blankcolor};
      $blankcolor = "white" if(not defined $blankcolor);
   my $bref = {-blankit, $blankit, -blankcolor, $blankcolor};
   # No blanking is passed to non-polygon shapes.

   my @args = ( $canv, $x, $y, $attr{-size} );
   
   my @styleOWF = (-outline,$outc,   -width,$outw,  -fill,$attr{-fillcolor}, $bref);
   my @styleFW  = (-fill,$outc,      -width,$outw);
   
   &_createOval(    @args,       $tag, @styleOWF),  return if($type eq 'Circle'  );
   &_createSquare(  @args, $ang, $tag, @styleOWF),  return if($type eq 'Square'  );
   &_createTriangle(@args, $ang, $tag, @styleOWF),  return if($type eq 'Triangle');
   &_createArrow(@args, $ang, $tag, @styleOWF),     return if($type eq 'Arrow');
   &_createPhoenix(@args, $ang, $tag, @styleOWF),   return if($type eq 'Phoenix');
   &_createThinBurst(@args, $ang, $tag, @styleOWF), return if($type eq 'ThinBurst');
   &_createBurst(0.30,@args,$ang, $tag, @styleOWF), return if($type eq 'Burst');
   &_createFatBurst(@args, $ang, $tag, @styleOWF),  return if($type eq 'FatBurst');
   
   &_createCross(   @args, $ang, $tag, @styleFW ),  return if($type eq 'Cross'   );
   &_createStar(    @args, $ang, $tag, @styleFW ),  return if($type eq 'Star'    );
   &_createHorzBar( @args, $ang, $tag, @styleFW ),  return if($type eq 'Horz Bar'); 
   &_createVertBar( @args, $ang, $tag, @styleFW ),  return if($type eq 'Vert Bar');
}

############## END OF POINT DRAWING ALGORITHMS #####################


############## BEGINNING OF SYMBOL DRAWING ALGORITHMS #####################
# the subroutine _reallydrawpoints provides the front end to each of the
# symbol subroutines.
sub _createOval {
   my $bref = pop(@_);
   my ($canv, $x, $y, $s, $tag) = splice(@_,0,5);
   my $s2 = $s/TWO;
   my ($xmin, $ymin) = ($x - $s2, $y - $s2);
   my ($xmax, $ymax) = ($x + $s2, $y + $s2);
   $canv->createOval($xmin, $ymin, $xmax, $ymax, @_, -tag => $tag);
   createOvalMetaPost($x, $y, $xmin, $ymin, $xmax, $ymax,
        {@_, -blankit => $bref->{-blankit}, -blankcolor => $bref->{-blankcolor}});
}



sub _createSquare {
   my $bref = pop(@_);
   my ( $canv,    $x,    $y,    $s,  $ang,  $tag) = splice(@_,0,6);
   my $xoff1 = $s*sin( RADIAN*(S45  + $ang) );
   my $xoff2 = $s*sin( RADIAN*(S135 + $ang) );
   my $xoff3 = $s*sin( RADIAN*(S225 + $ang) );
   my $xoff4 = $s*sin( RADIAN*(S315 + $ang) );
   my $yoff1 = $s*cos( RADIAN*(S45  + $ang) );
   my $yoff2 = $s*cos( RADIAN*(S135 + $ang) );
   my $yoff3 = $s*cos( RADIAN*(S225 + $ang) );
   my $yoff4 = $s*cos( RADIAN*(S315 + $ang) );
   my (@ll, @lr) = ( ($x+$xoff1,$y+$yoff1), ($x+$xoff2,$y+$yoff2) );
   my (@ur, @ul) = ( ($x+$xoff3,$y+$yoff3), ($x+$xoff4,$y+$yoff4) );
   $canv->createPolygon(@ll, @lr, @ur, @ul, @ur, @_, -tag => $tag);   
   createPolygonMetaPost(@ll, @lr, @ur, @ul,
        {@_, -linejoin => "mitered", -angle => 0, -blankit => $bref->{-blankit}, -blankcolor => $bref->{-blankcolor}});
}


sub _createCross {
   my ($canv,    $x,    $y,    $s,  $ang,  $tag) = splice(@_,0,6);
   my $xoff1 = $s*sin( RADIAN*        $ang  );
   my $xoff2 = $s*sin( RADIAN*(S90  + $ang) );
   my $xoff3 = $s*sin( RADIAN*(S180 + $ang) );
   my $xoff4 = $s*sin( RADIAN*(S270 + $ang) );
   my $yoff1 = $s*cos( RADIAN*        $ang  );
   my $yoff2 = $s*cos( RADIAN*(S90  + $ang) );
   my $yoff3 = $s*cos( RADIAN*(S180 + $ang) );
   my $yoff4 = $s*cos( RADIAN*(S270 + $ang) );
   my (@ll, @lr) = ( ($x+$xoff1,$y+$yoff1), ($x+$xoff3,$y+$yoff3) );
   my (@ur, @ul) = ( ($x+$xoff2,$y+$yoff2), ($x+$xoff4,$y+$yoff4) );
   $canv->createLine( @ll, @ul, @_, -tag => $tag );
   $canv->createLine( @ur, @lr, @_, -tag => $tag );
   createLineMetaPost( @ll, @ul, {@_}); # do not pass angle this time
   createLineMetaPost( @ur, @lr, {@_}); # because geometry is already done
}

sub _createStar {
   my ($canv,    $x,    $y,    $s,  $ang,  $tag) = splice(@_,0,6);
   _createCross($canv, $x, $y, $s, $ang, $tag, @_);   
   _createCross($canv, $x, $y, $s, (S45 + $ang), $tag, @_);   
}

sub _createVertBar {
   my ($canv,    $x,    $y,    $s,  $ang,  $tag) = splice(@_,0,6);
   my $yoff = $s/TWO;   
   my @coord = ( ($x,$y+$yoff), ($x,$y-$yoff) );
   $canv->createLine( @coord, @_, -tag => $tag );
   createLineMetaPost(@coord, {@_,-angle => $ang});
}    

sub _createHorzBar {
   my ($canv,    $x,    $y,    $s,  $ang,  $tag) = splice(@_,0,6);
   my $xoff = $s/TWO;   
   my @coord = ( ($x+$xoff,$y), ($x-$xoff,$y) );
   $canv->createLine( @coord, @_, -tag => $tag );
   createLineMetaPost( @coord,{@_, -angle => $ang});
}    

sub _createTriangle {
   my $bref = pop(@_);
   my ($canv,    $x,    $y,    $s,  $ang,  $tag) = splice(@_,0,6);
   my $xoff1 = $s*sin( RADIAN*($ang - S180) );
   my $xoff2 = $s*sin( RADIAN*($ang - S60)  );
   my $xoff3 = $s*sin( RADIAN*($ang + S60)  );
   my $yoff1 = $s*cos( RADIAN*($ang - S180) );
   my $yoff2 = $s*cos( RADIAN*($ang - S60)  );
   my $yoff3 = $s*cos( RADIAN*($ang + S60)  );
   my (@p1) = ($x+$xoff1, $y+$yoff1);
   my (@p2) = ($x+$xoff2, $y+$yoff2);
   my (@p3) = ($x+$xoff3, $y+$yoff3);
   $canv->createPolygon( @p1, @p2, @p3, @_, -tag => $tag );   
   createPolygonMetaPost(@p1, @p2, @p3,
        {@_, -linejoin => "mitered", -angle => 0, -blankit => $bref->{-blankit}, -blankcolor => $bref->{-blankcolor}});
}

sub _createArrow {
   my $bref = pop(@_);
   my ($canv,    $x,    $y,    $s,  $ang,  $tag) = splice(@_,0,6);
   my $xoff1 = $s*sin( RADIAN*($ang - S180) );
   my $xoff2 = $s*sin( RADIAN*($ang - S60)  );
   my $xoff3 = $s*sin( RADIAN*($ang + S60)  );
   my $yoff1 = $s*cos( RADIAN*($ang - S180) );
   my $yoff2 = $s*cos( RADIAN*($ang - S60)  );
   my $yoff3 = $s*cos( RADIAN*($ang + S60)  );
   my (@p1) = ($x+$xoff1, $y+$yoff1);
   my (@p2) = ($x+$xoff2, $y+$yoff2);
   my (@p3) = ($x+$xoff3, $y+$yoff3);
   $canv->createPolygon( @p1, @p2, ($x,$y), @p3, @_, -tag => $tag );   
   createPolygonMetaPost(@p1, @p2, ($x,$y), @p3,
        {@_, -angle => 0, -linejoin => "mitered", -blankit => $bref->{-blankit}, -blankcolor => $bref->{-blankcolor}});
   # we have to pass an angle of zero to the metapost generation of the
   # symbol because the trig transformations are already done.
}

sub _createPhoenix {
   my $bref = pop(@_);
   my ($canv,    $x,    $y,    $s,  $ang,  $tag) = splice(@_,0,6);
   my $scale = 1.80;
   my $xoff1 = $s*sin( RADIAN*($ang - S180) );
   my $xoff2 = $s*sin( RADIAN*($ang - S60)  );
   my $xoff3 = $scale*$s*sin( RADIAN*($ang - S30)  );
   my $xoff4 = $scale*$s*sin( RADIAN*($ang + S30)  );
   my $xoff5 = $s*sin( RADIAN*($ang + S60)  );
   my $yoff1 = $s*cos( RADIAN*($ang - S180) );
   my $yoff2 = $s*cos( RADIAN*($ang - S60)  );
   my $yoff3 = $scale*$s*cos( RADIAN*($ang - S30)  );
   my $yoff4 = $scale*$s*cos( RADIAN*($ang + S30)  );
   my $yoff5 = $s*cos( RADIAN*($ang + S60)  );
   my (@p1) = ($x+$xoff1, $y+$yoff1);
   my (@p2) = ($x+$xoff2, $y+$yoff2);
   my (@p3) = ($x+$xoff3, $y+$yoff3);
   my (@p4) = ($x+$xoff4, $y+$yoff4);
   my (@p5) = ($x+$xoff5, $y+$yoff5);
   $canv->createPolygon( @p1, @p2, @p3, ($x,$y), @p4, @p5, @_, -tag => $tag );   
   createPolygonMetaPost(@p1, @p2, @p3, ($x,$y), @p4, @p5,
        {@_, -angle => 0, -linejoin => "mitered", -blankit => $bref->{-blankit}, -blankcolor => $bref->{-blankcolor}});
   # we have to pass an angle of zero to the metapost generation of the
   # symbol because the trig transformations are already done.
}


sub _createThinBurst {
  &_createBurst(0.15,@_);
}


sub _createFatBurst {
  &_createBurst(0.45,@_);
}


sub _createBurst {
   my $bref = pop(@_);
   my ($scale, $canv,    $x,    $y,    $s,  $ang,  $tag) = splice(@_,0,7);
   my $xoff1 = $s*sin( RADIAN*($ang - S180) );
   my $xoff2 = $scale*$s*sin( RADIAN*($ang - 135)  );
   my $xoff3 = $s*sin( RADIAN*($ang - 90)  );
   my $xoff4 = $scale*$s*sin( RADIAN*($ang - 45)  );
   my $xoff5 = $s*sin( RADIAN*($ang -  0 ) );
   my $xoff6 = $scale*$s*sin( RADIAN*($ang + 45)  );
   my $xoff7 = $s*sin( RADIAN*($ang + 90)  );
   my $xoff8 = $scale*$s*sin( RADIAN*($ang + 135)  );
   
   my $yoff1 = $s*cos( RADIAN*($ang - S180) );
   my $yoff2 = $scale*$s*cos( RADIAN*($ang - 135)  );
   my $yoff3 = $s*cos( RADIAN*($ang - 90)  );
   my $yoff4 = $scale*$s*cos( RADIAN*($ang - 45)  );
   my $yoff5 = $s*cos( RADIAN*($ang -  0 ) );
   my $yoff6 = $scale*$s*cos( RADIAN*($ang + 45)  );
   my $yoff7 = $s*cos( RADIAN*($ang + 90)  );
   my $yoff8 = $scale*$s*cos( RADIAN*($ang + 135)  );

   my (@p1) = ($x+$xoff1, $y+$yoff1);
   my (@p2) = ($x+$xoff2, $y+$yoff2);
   my (@p3) = ($x+$xoff3, $y+$yoff3);
   my (@p4) = ($x+$xoff4, $y+$yoff4);
   my (@p5) = ($x+$xoff5, $y+$yoff5);
   my (@p6) = ($x+$xoff6, $y+$yoff6);
   my (@p7) = ($x+$xoff7, $y+$yoff7);
   my (@p8) = ($x+$xoff8, $y+$yoff8);
   $canv->createPolygon( @p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8, @_, -tag => $tag ); 
   createPolygonMetaPost(@p1, @p2, @p3, @p4, @p5, @p6, @p7, @p8,
        {@_, -angle => 0, -linejoin => "mitered", -blankit => $bref->{-blankit}, -blankcolor => $bref->{-blankcolor}});
   # we have to pass an angle of zero to the metapost generation of the
   # symbol because the trig transformations are already done.
}



# createSqonSel
# this is a highly specialized square drawing subroutine
# this draws the either black squares that are show up when
# a plot is selected or clicked on.  Because this is so close
# to the _createSquare that WHA has placed this subroutine in 
# this package.
sub createSqonSel {
   my ($plot, $canv, $template, $x, $y, $s, $ang, $tag) = @_;
   my $xoff1 = $s*sin( RADIAN*(S45  + $ang) );
   my $xoff2 = $s*sin( RADIAN*(S135 + $ang) );
   my $xoff3 = $s*sin( RADIAN*(S225 + $ang) );
   my $xoff4 = $s*sin( RADIAN*(S315 + $ang) );
   my $yoff1 = $s*cos( RADIAN*(S45  + $ang) );
   my $yoff2 = $s*cos( RADIAN*(S135 + $ang) );
   my $yoff3 = $s*cos( RADIAN*(S225 + $ang) );
   my $yoff4 = $s*cos( RADIAN*(S315 + $ang) );
   my (@ll, @lr) = ( ($x+$xoff1,$y+$yoff1), ($x+$xoff2,$y+$yoff2) );
   my (@ur, @ul) = ( ($x+$xoff3,$y+$yoff3), ($x+$xoff4,$y+$yoff4) );
   $canv->createPolygon( @ll, @lr, @ur, @ul, @ur,
                         -tag => ["selectedplot", $tag] ); 
   $canv->bind($tag, "<Enter>",
          sub { $canv->itemconfigure($tag, -fill => 'grey') } );
   $canv->bind($tag, "<Leave>",
          sub { $canv->itemconfigure($tag, -fill => 'black')  } );
   $canv->bind($tag, "<Button-1>",
          sub { my $resize = Tkg2::Plot::Movements::ResizingPlot->new($canv, $template, $plot, $tag);       
                $resize->bindStart;
          } );    
}

1;
