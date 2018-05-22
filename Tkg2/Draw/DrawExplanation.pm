package Tkg2::Draw::DrawExplanation;

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
# $Date: 2007/09/17 13:16:21 $
# $Revision: 1.30 $

use strict;
use vars qw(@ISA @EXPORT);

use Exporter;

use Tkg2::Plot::Movements::MovingExplanation;
use Tkg2::Draw::DrawPointStuff qw(_reallydrawpoints _drawsometext);

use Tkg2::Base qw(Show_Me_Internals adjustCursorBindings deleteFontCache);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createLineMetaPost
                                                createExplanationTextMetaPost
                                                createRectangleMetaPost
                                                beginExplanationMetaPost
                                                endExplanationMetaPost);


@ISA = qw(Exporter);

@EXPORT = qw(drawExplanation);

print $::SPLASH "=";

use constant ONE   => scalar 1;
use constant TWO   => scalar 2;
use constant THREE => scalar 3;
use constant FOUR  => scalar 4;

sub drawExplanation {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $canv, $template) = @_;
   my $exref = $self->{-explanation};
   return if($self->{-hide});
   
   # BACKWARDS COMPATABILITY FOR 0.39.2
   if( $exref->{-titlexoffset} !~ m/i/io    and
       $exref->{-titlexoffset} !~ m/auto/io and
       $exref->{-titlexoffset} < 0 ) {
       $exref->{-titlexoffset} = 'auto';
       print "Tkg2-Backwards compatability: Please perform a Save on ",
             "this template.  The setting behavior of ",
             "-explanation / -titlexoffset has changed (set to 'auto').\n";
   }
   if( $exref->{-titleyoffset} !~ m/i/io    and
       $exref->{-titleyoffset} !~ m/auto/io and
       $exref->{-titleyoffset} < 0 ) {
       $exref->{-titleyoffset} = 'auto';
       print "Tkg2-Backwards compatability: Please perform a Save on ",
             "this template.  The setting behavior of ",
             "-explanation / -titleyoffset has changed (set to 'auto').\n";
   };
   if( $exref->{-vertspacing}  !~ m/i/io    and
       $exref->{-vertspacing}  !~ m/auto/io and
       $exref->{-vertspacing} < 0 ) {
       $exref->{-vertspacing}  = 'auto';
       print "Tkg2-Backwards compatability: Please perform a Save on ",
             "this template.  The setting behavior of ",
             "-explanation / -vertspacing has changed (set to 'auto').\n";
   }
   # END OF BACKWARDS COMPATABILITY FOR 0.39.2
   

   my $ftref = $exref->{-font};
   
   my $tag = [ "$self", $self."explanation", $self."explantograb" ];
   
   my $dataclass = $self->{-dataclass};
   my $linewidth = $exref->{-linewidth};
   my $gap       = $exref->{-horzgap};
   $gap = $::MW->fpixels($gap) if($gap =~ /i/o);
   
   # BACKWARDS COMPATABILITY FOR 0.39.2
   $exref->{-colspacing} = '0.20i' if( not $exref->{-colspacing} );
   $exref->{-numcol}     = 1       if( not $exref->{-numcol}     );
   # END OF BACKWARDS COMPATABILITY FOR 0.39.2
   
   my $colspc    = $exref->{-colspacing};
   my $xo        = $exref->{-xorigin};
   my $yo        = $exref->{-yorigin};
   my $yoff      = 0;      
   my $title     = $exref->{-title};

   # Insurance that the coordinates of the explanation will be defined
   my ($xmin, $ymin, $xmax, $ymax) = $self->getPlotLimits;
   $xo = $exref->{-xorigin} = $xmax + $self->{-xrmargin}*0.05
        if(not defined $xo );
   $yo = $exref->{-yorigin} = $ymin + $self->{-ypixels}/TWO
        if(not defined $yo );
   # end of origin insurance
   
   my $fontcolor = $ftref->{-color};
   &deleteFontCache(); # Perl 5.8.3 and Tk 804.027 error trapping
   my $font = $canv->fontCreate($self."explanfont",
                      -family =>  $ftref->{-family},
                      -size   => ($ftref->{-size}*
                                  $::TKG2_ENV{-SCALING}*
                                  $::TKG2_CONFIG{-ZOOM}),
                      -weight =>  $ftref->{-weight},
                      -slant  =>  $ftref->{-slant});

   my $scaleupspacing = 1.10;
   my $spacing = ($exref->{-vertspacing} =~ m/auto/io) ?
                 $canv->fpixels($scaleupspacing*
                                 ($ftref->{-size}/72)."i") :
                 $canv->fpixels($exref->{-vertspacing})    ;   


   beginExplanationMetaPost();

   # If there is a title to draw, draw it
   unless($title eq "") {                   
      my $titlexoffset = ($exref->{-titlexoffset} =~ m/auto/io) ?
                          0 : $canv->fpixels($exref->{-titlexoffset});
      my $justify      = $exref->{-titlejustify};
      $canv->createText($xo+$titlexoffset, $yo+$yoff,
                        -text    => $title,
                        -fill    => $fontcolor,
                        -anchor  => 'nw',
                        -justify => $justify, 
                        -font    => $font,
                        -tag     => [ @{$tag}, $self."explantitle"]  );

   # We do not need this createAnnoTextMetaPost following the createText
   # as in just about everywhere else in the tkg2 system because this
   # drawing is for later measurement for the final placement.
      #createAnnoTextMetaPost($xo+$titlexoffset, $yo+$yoff,
      #                       {-text    => "FIRST $title",
      #                        -fill    => $ftref->{-color},
      #                        -anchor  => 'nw',
      #                        -justify => $justify, 
      #                        -family  =>  $ftref->{-family},
      #                        -size    => $ftref->{-size},
      #                        -weight  =>  $ftref->{-weight},
      #                        -slant   =>  $ftref->{-slant}});
      $yoff += ($exref->{-titleyoffset} =~ m/auto/io) ?
               1.5*$spacing                                       :
               $spacing + $canv->fpixels($exref->{-titleyoffset}) ;
   }
   
   # LOOK AHEAD AND DETERMINE THE LAYOUT OF THE COLUMNS AND ENTRIES 
   # determine the number of entries that will actually show up in the
   # explanation
   my $num_entries = 0;
   foreach my $dataset (@$dataclass) {
      next if not $dataset->{-show_in_explanation};
      foreach my $data ( @{$dataset->{-DATA} } ) {
         $num_entries++ if($data->{-show_in_explanation})
      };
   }
   
   
   
   # now check the number of columns against the number of pending
   # entries for consistency
   my $numcol = $exref->{-numcol};
   # if the number of columns > entries then set to one entry per column
   $numcol = $exref->{-numcol} = $num_entries if($numcol > $num_entries);
   # if the number of columns is less than 1 set to one column
   $numcol = $exref->{-numcol} = 1 if($numcol < 1);
   
   # determine number of entries per column
   my $entry_remainder = $num_entries % $numcol;
   my $entries_per_col = ($entry_remainder) ?
                         int($num_entries / $numcol)+ONE :
                             $num_entries / $numcol      ;
   # END OF LAYOUT DETERMINATION
   
   
   # set of two variables for tracking entry insertion
   my $entries_in_col = 0;
   my $on_col_num     = 1;
   # preserve two settings
   my $origyoff       = $yoff; # so each column will start at the proper top
   my $origxo         = $xo;   # so that the title can be properly centered
   
   foreach my $dataset (@$dataclass) {
      next if(not $dataset->{-show_in_explanation});
      my $name = $dataset->{-setname};
      foreach my $data ( @{ $dataset->{-DATA} } ) {
         next if(not $data->{-show_in_explanation});
         
         my $temptag = [ $self."explanation",
                         $self."$data->{-data}",
                         'column'
                       ]; # the column tag is deleted each time
                          # a column is completed
         
         $yoff = &_get_special_offsets($data, $yoff);
         
         &_draw_shade_symbology($canv,$data,$linewidth,
                                $xo,$yo,$yoff,$spacing,$temptag);
                                
         &_draw_bar_symbology($canv,$data,$linewidth,
                              $xo,$yo,$yoff,$spacing,$temptag);

         &_draw_line_symbology($canv,$data,$linewidth,
                               $xo,$yo,$yoff,$spacing,$temptag);
         
         # $ftref passed specifically for MetaPost
         &_draw_special($canv,$data,$self,$linewidth,$gap,   
                        $xo,$yo,$yoff,$spacing,$font,$fontcolor,$temptag,$ftref);                  
         
         &_draw_point_symbology($canv,$data,$linewidth,   
                                $xo,$yo,$yoff,$spacing,$temptag);
           
         &_draw_text_next_to_symbology($canv,$data,$linewidth,
                                       $xo,$yo,$yoff,$temptag);

         $yoff = &_draw_entry($canv, $dataset, $template, $self, $name,
                              $data, $spacing,
                              $linewidth, $gap, $xo, $yo, $yoff,
                              $fontcolor, $font, $tag);
  
         &_bindings_on_data_symbology($template,$self,$canv,$dataset,$data);
         
         $entries_in_col++; # increment the entries in the current column
         
         # the following conditional adjusts of offsets and resets the
         # column counter when the current column is filled up
         if($entries_in_col == $entries_per_col) {
            $entries_in_col = 0;
            $yoff = $origyoff;
            my @coord = $canv->bbox('column');
            # trying to find a event bug with the following                         
            warn "DrawMethods::DrawExplanation on column in",
                 "explanation \@coord @coord\n" unless(@coord == 4);
            my $width = ( $coord[2] - $coord[0] );
            
            $xo += $canv->fpixels($colspc) + $width;
            $canv->dtag('column');
         }      
         
      }  # END OF DATA LOOP
   }  # END OF DATASET LOOP
   
   $canv->dtag('column'); # just a safety measure to always insure
   # that the column tag is removed from the canvas

   my @coord = $canv->bbox("$self"."explanation");
   # trying to find a event bug with the following                         
   if(@coord != 4) {
      # the coordinates can become missing if an explanation
      # has no entries and the title is null.  There might be
      # other situtations such as when explanation is totally
      # outside of the canvas, but that isn't possible by mouse
      # dragging--is it?  2/28/2001
      # the following message is a legacy message that might
      # not be required any more.
      print $::MESSAGE
            "DrawMethods::DrawExplanation for drawing explanation box ",
            "but \@coord is empty\n";
   }
   else {
      $coord[0] -= TWO;  #modify x
      $coord[2] += TWO; 
      $coord[1] -= TWO;  #modify y
      $coord[3] += TWO;  
      # create the bounding box
      my @dash = ();
      push(@dash, (-dash => $exref->{-dashstyle}) )
              if($exref->{-dashstyle} and
                 $exref->{-dashstyle} !~ /Solid/io);
      $canv->createRectangle(@coord, -fill    => $exref->{-fillcolor},
                                     -outline => $exref->{-outlinecolor},
                                     -width   => $exref->{-outlinewidth},
                                     @dash,
                                     -tag     => $self."explanbox" );
      #createRectangleMetaPost(@coord,{ -fill    => $exref->{-fillcolor},
      #                                 -outline => $exref->{-outlinecolor},
      #                                 -width   => $exref->{-outlinewidth},
      #                                 @dash});
      # raise the previously drawn stuff above the box
      $canv->raise($self."explanation",$self."explanbox");
   
   
      # Delete and draw the explanation title again because now entries
      # are in place and the title requires centering ONLY if the
      # user has specified that the x offset of the title is automatic 
      if($exref->{-titlexoffset} =~ m/auto/oi) {
         $canv->delete($self."explantitle"); # $origxo
         $canv->createText(($coord[2]+$coord[0])/TWO, $yo,
                           -text   => $title,
                           -fill   => $fontcolor,
                           -font   => $font,
                           -tag    => [ @{$tag}, "$self"."explantitle"],
                           -anchor => 'n');
         createExplanationTextMetaPost(($coord[2]+$coord[0])/TWO, $yo,
                             {-text    => $title,
                              -fill    => $ftref->{-color},
                              -anchor  => 'n',
                              -family  =>  $ftref->{-family},
                              -size    => $ftref->{-size},
                              -weight  =>  $ftref->{-weight},
                              -slant   =>  $ftref->{-slant}});
      }      
      endExplanationMetaPost({-fill    => $exref->{-fillcolor},
                              -outline => $exref->{-outlinecolor},
                              -width   => $exref->{-outlinewidth},
                              @dash});
   }
   
   $canv->fontDelete($self."explanfont");

   return if($::CMDLINEOPTS{'nobind'});
   $canv->bind($self."explantograb", "<Button-3>",
               sub { &_moveexplan($self, $template, $canv) } );
}



sub _moveexplan {
   my ($self,$template,$canv) = @_;
   if($::DIALOG{-SELECTEDEXPLANATION}) {
      $canv->delete("rectexplan");
      $::DIALOG{-SELECTEDEXPLANATION} = "";
   }
   else {
      my @coord = $canv->bbox($self."explanation");
      # trying to find a event bug with the following                         
      
      if(@coord != 4) {
         print $::MESSAGE
               "DrawMethods::DrawExplanation moving explanation ",
               "but \@coord is empty--setting to 20, 20, 60, 60.\n";
         @coord = (20, 20, 60, 60); 
      }
      my $width  = $coord[2] - $coord[0];
      my $height = $coord[3] - $coord[1];
      $::DIALOG{-SELECTEDEXPLANATION} =
           $canv->createRectangle(@coord,
                                  -tag     => "rectexplan",
                                  -outline => 'red');
      my $move = Tkg2::Plot::Movements::MovingExplanation->new(
                      $canv, $template, $self, $width, $height);
      $move->bindStart;
   }
};   



sub _draw_shade_symbology {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($canv,$data,$linewidth,$xo,$yo,$yoff,$spacing,$temptag) = @_;
   my $attr = $data->{-attributes}->{-shade};
   return unless($attr->{-doit});
   
   my @ul = ($xo, $yo+$yoff);
   my @lr = ($xo+$linewidth, $yo+$yoff+$spacing/THREE);
   
   $canv->createRectangle(@ul, @lr,
        -fill    => $attr->{-fillcolor},
        -outline => undef,
        -tags    => $temptag);
   createRectangleMetaPost(@ul, @lr, {-fill => $attr->{-fillcolor}})
}


sub _draw_bar_symbology {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($canv,$data,$linewidth, $xo,$yo,$yoff,$spacing,$temptag) = @_;
   my $attr = $data->{-attributes}->{-bars};
   return unless($attr->{-doit});
   
   my $dir = $attr->{-direction};
   my $barwidth = $canv->fpixels($attr->{-barwidth});
   my %attr = ( -outlinecolor => $attr->{-outlinecolor},
                -outlinewidth => $attr->{-outlinewidth},
                -fillcolor    => $attr->{-fillcolor} ); 
   
   my @ul = ($xo + $linewidth/TWO - $barwidth, $yo + $yoff - $spacing/FOUR); 
   my @lr = ($xo + $linewidth/TWO + $barwidth, $yo + $yoff + $spacing/FOUR);
   
   $canv->createRectangle(@ul, @lr,
        -fill    => $attr{-fillcolor},
        -outline => $attr{-outlinecolor},
        -width   => $attr{-outlinewidth},
        -tags    => $temptag);
   createRectangleMetaPost(@ul, @lr,{ -fill => $attr{-fillcolor},
                                      -outline => $attr{-outlinecolor},
                                      -width   => $attr{-outlinewidth}});
}


sub _draw_line_symbology {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
      
   my ($canv,$data,$linewidth,$xo,$yo,$yoff,$spacing,$temptag) = @_;
   my $attr = $data->{-attributes}->{-lines};
   return unless($attr->{-doit});
   my $dashstyle = $attr->{-dashstyle};
   my @dash = ();
   push(@dash, (-dash => $dashstyle))
              if($dashstyle and $dashstyle !~ /Solid/io);

   $canv->createLine( $xo, $yo+$yoff, $xo+$linewidth, $yo+$yoff,
        -width => $attr->{-linewidth},
        -fill  => $attr->{-linecolor}, @dash,
        -tag   => $temptag );
   createLineMetaPost($xo, $yo+$yoff, $xo+$linewidth, $yo+$yoff,
                      {-width => $attr->{-linewidth},
                       -fill  => $attr->{-linecolor}, @dash});
}


sub _draw_point_symbology {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($canv,$data,$linewidth,$xo,$yo,$yoff,$spacing,$temptag) = @_;
   
   my $attr  = $data->{-attributes};
   my $ptref = $attr->{-points};
   return unless($ptref->{-doit});
   
   my $xlocation = $xo + $linewidth/TWO; # the x location of the symbol
   my $ylocation = $yo + $yoff;          # the y location of the symbol
   
   # Draw the error bar(s) if the plotstyle so indicates
   my $plotstyle = $attr->{-plotstyle};       
   if($plotstyle =~ m/Error/o) {
      my @args = ($canv,$xlocation,$ylocation,$yoff);
      # Always draw the error bar in the Y direction because the
      # plot style is either Y-Error ...  or X-Y Error ...
      &_draw_fake_error(@args, 'Y', $attr->{-yerrorbar}, $temptag);
      &_draw_fake_error(@args, 'X', $attr->{-xerrorbar}, $temptag)
                        if($plotstyle =~ m/X-Y Error/o);
   }
   
   # Now finally draw the symbology on above the error bars (if they exist).
   my %attr = ( -symbol       => $ptref->{-symbol},
                -size         => $ptref->{-size},
                -angle        => $ptref->{-angle},
                -outlinecolor => $ptref->{-outlinecolor},
                -outlinewidth => $ptref->{-outlinewidth},
                -fillcolor    => $ptref->{-fillcolor} ); 
   &_reallydrawpoints($canv,$xlocation,$ylocation,$temptag,\%attr);
   # _reallydrawpoints was imported from the Draw/DrawPointStuff.pm module
} 

sub _get_special_offsets {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my ($data, $yoff) = @_;
   my $attr     = $data->{-attributes};   
   my $specplot = $attr->{-special_plot};
   return $yoff unless($specplot);
   
   my $explansets = $specplot->{-explanation_settings};
   my $top  = (defined $explansets->{-spacing_top}) ?
                       $explansets->{-spacing_top}  : '.65i';
   $specplot->{-explanation_settings}->{-spacing_top}    = $top; # insure backwards compatability
   $top = $::MW->fpixels($top);
   return $yoff + $top;
}

sub _draw_special {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($canv, $data, $plot,
       $linewidth,
       $gap, $xo, $yo, $yoff, $spacing,
       $font, $fontcolor, $temptag, $ftref) = @_;
   my $attr     = $data->{-attributes};   
   my $specplot = $attr->{-special_plot};  
   return 0 unless($specplot);
   
   my $points_doit  = $attr->{-points}->{-doit};
   my $which_y_axis = $attr->{-which_y_axis};
   my $orientation  = $specplot->{-orientation};
   my $axis         = ($orientation eq 'vertical') ? "-y" : "-x";
   $axis = $axis."2" if($axis eq '-y' and $which_y_axis == 2);
   my $is_reversed  = $plot->{$axis}->{-reverse};
   
   $specplot->Explanation($canv,
                          $is_reversed,
                          $points_doit,
                          $linewidth,
                          $gap,
                          $xo, $yo,
                          $yoff,
                          $spacing,
                          $font,
                          $fontcolor,
                          $temptag,
                          $ftref);
   return 1; 
}


# Fake error bars are drawn, because it is impossible to handle real errors
# from the actual data when drawing the explanation.  We choose that the
# error bars shown will be one half of the vertical spacing of the explanation
# and will be symetrical although the actual plot could be either a symetrical
# or asymetrical error plot.
sub _draw_fake_error {
   my ($canv, $x, $y, $error, $which, $attr, $tag) = @_;
   $error /= TWO; # The error was equal to the y spacing offset of the 
   # explanation, by dividing by two, things will look a little better
   my $whisker = $canv->fpixels($attr->{-whiskerwidth});
   my $color = $attr->{-color};
   my $width = $attr->{-width};

   my @style = (-fill, $color, -width, $width, -tags, $tag );
   
   my $dashstyle = $attr->{-dashstyle};
   push(@style, (-dash => $dashstyle))
               if($dashstyle and $dashstyle !~ /Solid/io);

   # If the direction is in y, that is vertical, then draw a fake
   # vertical error bar and then draw the symbology
   if($which =~ /y/oi) {
      my $yp  = $y + $error;
      my $ym  = $y - $error;
      my $xpw = $x + $whisker;
      my $xmw = $x - $whisker;
      $canv->createLine($x,$ym,$x,$yp,@style);
      $canv->createLine($xpw,$ym,$xmw,$ym,@style);
      $canv->createLine($xpw,$yp,$xmw,$yp,@style);
      createLineMetaPost($x,$ym,$x,$yp,{@style});
      createLineMetaPost($xpw,$ym,$xmw,$ym,{@style});
      createLineMetaPost($xpw,$yp,$xmw,$yp,{@style});
}
   else { # draw the error in the horizontal direction instead
      my $xp  = $x + $error;
      my $xm  = $x - $error;
      my $ypw = $y + $whisker;
      my $ymw = $y - $whisker;
      $canv->createLine($xm,$y,$xp,$y,@style);                   
      $canv->createLine($xm,$ymw,$xm,$ypw,@style);
      $canv->createLine($xp,$ymw,$xp,$ypw,@style);
      createLineMetaPost($xm,$y,$xp,$y,{@style});
      createLineMetaPost($xm,$ymw,$xm,$ypw,{@style});
      createLineMetaPost($xp,$ymw,$xp,$ypw,{@style});
   }
}



sub _draw_entry {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($canv, $dataset, $template, $plot, $name, $data, $spacing,
       $linewidth, $gap, $xo, $yo, $yoff,
       $fontcolor, $font, $tag) = @_;
   
   # This is for specific accomodation for MetaPost 
   my $ftref = $plot->{-explanation}->{-font};

    # setting the text up
   my $temptext = $data->{-showordinate};  # make copy
      $temptext =~ s/(.+\n)\s*/$1    /g;   # add four spaces infront of
                                           #  each line below the first
   my (@text) = $temptext =~ m/(.+)\n/og;   # grab each line to \n
   push(@text,  $temptext =~ m/(.+)$/og);   # grab the last line
           
   foreach my $text (@text) {
       my ($x,$y) = (($xo + $linewidth + $gap), ($yo + $yoff));
       $canv->createText($x, $y,
                         -text    => $text,
                         -fill    => $fontcolor,
                         -font    => $font,
                         -justify => 'left',
                         -anchor  => 'w',
                         -tag     => [ @$tag, 'column',
                                       "$dataset",
                                     ]);
       $yoff += $spacing; 
       createExplanationTextMetaPost($x,$y,
                             {-text    => $text,
                              -fill    => $ftref->{-color},
                              -anchor  => 'w',
                              -angle   => $ftref->{-rotation},
                              -family  =>  $ftref->{-family},
                              -size    =>  $ftref->{-size},
                              -weight  =>  $ftref->{-weight},
                              -slant   =>  $ftref->{-slant}});
   } 
   unless($::CMDLINEOPTS{'nobind'}) {
      &adjustCursorBindings($canv,"$dataset");
      $canv->bind("$dataset", "<Double-Button-1>",
                  sub { my @args = ($canv, $plot, $template, $name);
                        $dataset->DataSetEditor(@args) } );
   }
   my $scaleupspacing = 1.3;
   return ($yoff-$spacing)+($scaleupspacing*$spacing);
}


sub _draw_text_next_to_symbology {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($canv,$data,$linewidth,$xo,$yo,$yoff,$temptag) = @_;            
   my $dataattr = $data->{-attributes};
   my $attr     = $dataattr->{-text};
   
   return unless($dataattr->{-plotstyle} =~ /text/io and $attr->{-doit} );
                 
   my $ftref = $attr->{-font};
   &deleteFontCache(["textfont"],'FULL CACHE DELETION NOT DESIRED'); # Perl 5.8.3 and Tk 804.027 error trapping
   my $font = $canv->fontCreate("textfont",
                   -family =>  $ftref->{-family},
                   -size   => ($ftref->{-size}*
                               $::TKG2_ENV{-SCALING}*
                               $::TKG2_CONFIG{-ZOOM}),
                   -weight =>  $ftref->{-weight},
                   -slant  =>  $ftref->{-slant} );

   # We are going to use the font size to determine nice looking
   # offsets for the explanation to keep the explanation from getting
   # too confusing or large.
   my $fontsize = $canv->fpixels($ftref->{-size}*$::TKG2_ENV{-SCALING});                  
   my $origxoffset = $attr->{-xoffset};
   my $origyoffset = $attr->{-yoffset};
   $attr->{-xoffset} = -$fontsize/2;
   $attr->{-yoffset} = $fontsize/1.5;
   
   
   my $text; # the text element that will be shown in explanation
   foreach my $pair ( @{ $data->{-data} } ) {
      $text = $$pair[2];
      next if( not defined $text      or
               $text eq ""            or
               $text =~ m/^0+$/o      or
               $text =~ m/^0+\.0+/o   or
               $text =~ m/^\.0+/o 
             );
      last; # hey we have a valid text string moving on
   }
   $text = "" if(not defined $text); # protection
               
   # Willard requested that even if the text is stacked on the
   # plot that we do not stackit in the explanation because
   # it will seriously overwrite other explanation entries. Also
   # very long strings need east anchoring because the explanations
   # are almost all left justified.  However, the appearance is
   # still dependent on the xoffset and yoffset settings that the
   # user provides
   my $anchor  = $attr->{-anchor};
   $attr->{-anchor} = 'e';
               
   my $stackit = $attr->{-font}->{-stackit};
     
   # turn stacking off
   $attr->{-font}->{-stackit} = 0 if($stackit);
   
   my $leaderdoit = $attr->{-leaderline}->{-doit};
   $attr->{-leaderline}->{-doit} = 0;
      
   # We do not know what state SHUFFLE was left in so
   # it is necessary to reset the SHUFFLE counter so that the
   # leader line in the explanation looks exactly like the 
   # leader line settings without SHUFFLE are.
   $::Tkg2::Draw::DrawPointStuff::SHUFFLE = 0;
   &_drawsometext($canv, ($xo + $linewidth/TWO), ($yo + $yoff),
                  $text, $attr, $font, $temptag);
     
   # turn the stacking back on
   $attr->{-font}->{-stackit} = 1 if($stackit);
    
   # now restore the user's anchor choice
   $attr->{-anchor} = $anchor;
   
   # now restore the user's leader line choice
   $attr->{-leaderline}->{-doit} = $leaderdoit;
   
   # now restore the user's original offset choices
   $attr->{-xoffset} = $origxoffset;
   $attr->{-yoffset} = $origyoffset;
   
   $canv->fontDelete("textfont");  
}

# The symbology bindings allow the mouse to double-click on the symbology
# of the explanation entry and launch the DrawDataEditor
sub _bindings_on_data_symbology {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
      
   my ($template,$self,$canv,$dataset,$data) = @_;
 
   # do not form the bindings if started in display only mode
   return if($::CMDLINEOPTS{'nobind'});
   my $tag = "$self"."$data->{-data}";
   &adjustCursorBindings($canv,$tag);
   $canv->bind($tag,
               "<Double-Button-1>",
               sub { $dataset->DrawDataEditor($data, $canv, 
                                              $template, $self);
                   } );
}

1;
