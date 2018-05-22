package Tkg2::Plot::BoxPlot::BoxPlotStyle;

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
# $Date: 2007/09/18 20:44:42 $
# $Revision: 1.24 $

use Tkg2::Plot::BoxPlot::Editor::BoxPlotEditor qw(SpecialPlotEditor
                                                  checkConfiguration);
use Tkg2::Base qw(Show_Me_Internals isNumber commify deleteFontCache);
use Tkg2::Draw::DrawPointStuff qw(_reallydrawpoints);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createRectangleMetaPost
                                                createLineMetaPost
                                                createAnnoTextMetaPost);

use strict;

use constant TWO => scalar 2;

print $::SPLASH "=";


# OBJECT CONSTRUCTORS
sub new {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   # do not remove shifts
   my ($pkg, $orientation, $bygroup) = (shift, shift, shift);
   my $box  = {  };
   bless($box, $pkg);
   $box->{-orientation}   = $orientation;       # vertical or horizonal
   $box->{-data_by_group} = ($bygroup) ? 1 : 0; # by grouping or not--see LoadData.pm
   $box->{-explanation_settings} = { -spacing_top    => '.65i',
                                     -size           => '1.25i',
                                     -use_percent_sign => 0 };
   $box->{-special_instructions} = shift;
   $box->_setdefaults();
   return $box;
}


sub _setdefaults {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my $box = shift;
    
   $box->{-split} = 0;
   # Other possible values of split are 'leftorabove', 'rightorbelow'   
      
   $box->{-tercile}   = &_box_defaults(0,'0.13i');   # 1 to turn on
   $box->{-quartile}  = &_box_defaults(1,'0.11i');   # 0 to turn off
   $box->{-pentacile} = &_box_defaults(0,'0.09i');
   $box->{-decile}    = &_box_defaults(0,'0.07i');
   $box->{-centacile} = &_box_defaults(0,'0.05i');

   # What is the location measure? -- showtype = 'median' or 'mean'
   # Remember that the x,y location or origin of the box in general
   # is going to be at x,mean or mean,y.  -showtype just controls
   # where the horizontal or vertical bar is draw across the box.
   my $symbology = &_symbol_defaults('Circle','black');
   $box->{-location} = { 
                         -doit      => 1,
                         -showtype  => 'median',
                         -width     => $::MW->fpixels('0.11i'),
                         -linewidth => '0.015i',
                         -linecolor => 'black',
                         -dashstyle => undef,
                         -symbology => $symbology
                       };
   $box->{-location}->{-symbology}->{-doit} = 0;
                
   # Control whether the user wants all the data values that were used
   # to generate a particular box plot plotted too.
   my @symbology = &_symbol_defaults('Circle','black');             
   $box->{-show_data} = { -doit => 0,
                          @symbology,
                          -plot_order => 'first',
                        };             
                      
   # Control whether or not the sample size is going to be displayed
   # along with the box and how the sample size is going to be formatted 
   $box->{-sample} = { 
                       -doit     => 1,
                       -offset   => $::MW->fpixels('0.09i'),
                       -font     => { -family   => "Helvetica",
                                      -size     => 9,
                                      -weight   => 'normal',
                                      -slant    => 'roman',
                                      -color    => 'black',
                                      -rotation => 0,
                                      -stackit  => 0,
                                      -custom1  => undef,
                                      -custom2  => undef,
                                      -parenthesis => 1
                                    },
                       -location => 'Above/Left',
                       -commify  => 0,
                       -decimal  => 0,
                       -format   => 'free' 
                     };
   $box->{-show_stats} = { -doit => 0 };
                     
   $box->{-tail} = &_tail_defaults();
                    
   $box->{-detection_limits} = {
                                 -lower => &_detection_limit_defaults(),
                                 -upper => &_detection_limit_defaults()
                               };
                                          
   $box->{-type1_outliers} = {
                               -doit  => 1, 
                               -description =>
               '1.5 to 3 times interquartile range',
                               &_outlier_defaults('Circle'),
                              };
                             
   $box->{-type2_outliers} = {
                               -doit  => 1,
                               -description =>
               '3 times interquartile range',
                               &_outlier_defaults('Star'),
                             };
}

sub _tail_defaults {
   my $tref = {
                -doit      => 1        ,
                -linewidth => '0.01i' ,
                -dashstyle => undef    ,
                -linecolor => 'black'  ,
                -whiskers  => { -doit      => 0        ,
                                -width     => $::MW->fpixels('0.1i'),
                                -linewidth => '0.01i' ,
                                -linecolor => 'black'  ,
                                -dashstyle => undef    ,
                              },
                -type => '1.5*IQR',
              };
   return $tref;
}


sub _outlier_defaults {
   my $symbol = shift;
   my $fill = (@_) ? shift() : 'white';
   my @para = (
                -symbol       => $symbol  ,
                -size         => $::MW->fpixels('0.056i'),
                -angle        => 0        ,
                -outlinewidth => '0.01i' ,
                -fillcolor    => 'white'  ,
                -fillstyle    => undef    ,
                -dashstyle    => undef    ,
                -outlinecolor => 'black'  ,
             );
   return @para;
}                                                     


sub _symbol_defaults {
   my $symbol = shift;
   my $fill = (@_) ? shift() : 'white';
   my $href = {
                -symbol       => $symbol  ,
                -size         => $::MW->fpixels('0.056i'),
                -angle        => 0        ,
                -outlinewidth => '0.01i' ,
                -fillcolor    => 'white'  ,
                -fillstyle    => undef    ,
                -dashstyle    => undef    ,
                -outlinecolor => 'black'  ,
             };
   return (wantarray) ? %$href : $href;
}           

sub _detection_limit_defaults {
   my $tref = { 
                -doit      => 0        ,
                -width     => '0.1i'   ,
                -linewidth => '0.01i' ,
                -linecolor => 'black'  ,
                -dashstyle => undef    , 
              };
    return $tref;
}


sub _box_defaults {
   my $doit  = (@_) ? shift() : 0;
   my $width = (@_) ? shift() : '0.1i'; 
   return { -doit      => $doit    ,
            -width     => $::MW->fpixels($width)   ,
            -linewidth => '0.01i' ,
            -dashstyle => 'solid'  ,
            -fillcolor => 'white'  ,
            -linecolor => 'black'  ,
          };
}

sub Explanation {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $canv,
       $is_reversed, $points_doit,
       $basewidth, $gap,
       $xo, $yo,
       $baseyoff, $spacing,
       $font, $fontcolor, $tag, $ftref) = @_;
   
   my $explansets = $self->{-explanation_settings};
   my $top  = (defined $explansets->{-spacing_top}) ?
                       $explansets->{-spacing_top}  : '1i';
   my $size = (defined $explansets->{-size}) ?
                       $explansets->{-size}  : '1i';
   $self->{-explanation_settings}->{-spacing_top}    = $top; # insure backwards compatability
   $self->{-explanation_settings}->{-size}           = $size;
      
   foreach ($top,$size) { $_ = $::MW->fpixels($_); }
   
   # indicate mean if the regular points are being shown
   if($points_doit) {
     $canv->createText(($xo - $gap), $yo + $baseyoff,
                         -text    => "Mean",
                         -fill    => $fontcolor,
                         -font    => $font,
                         -justify => 'right',
                         -anchor  => 'e',
                         -tag     => $tag);   
     createAnnoTextMetaPost(($xo - $gap), $yo + $baseyoff,
                         {-text    => "Mean",
                          -fill    => $fontcolor,
                          -family  => $ftref->{-family},
                          -size    => $ftref->{-size},
                          -weight  => $ftref->{-weight},
                          -slant   => $ftref->{-slant},
                          -angle   => $ftref->{-rotation},
                          -justify => 'right',
                          -anchor  => 'e'});
   }
   
   # draw ciles
   my $cilenum = 5;
   my $first_height;
   my $final_height;
   my $percent = ($explansets->{-use_percent_sign}) ? " \%" : " percentile";
   foreach my $cile (qw(centacile decile pentacile quartile tercile)) {
      my %para    = %{ $self->{"-"."$cile"} };
      my $width  = $para{-width} / TWO;
      my $height = $size * $cilenum**.8 / 5;
      my @coords = ($xo + $basewidth/TWO - $width,
                    $yo + $baseyoff  + $height,
                    $xo + $basewidth/TWO + $width,
                    $yo + $baseyoff - $height,
                    );

      my @dash = ();
      push(@dash, (-dash => $para{-dashstyle}) )
                  if($para{-dashstyle} and
                     $para{-dashstyle} !~ /Solid/io);


      #moved these assignments in September 2007 to avoid a cascade of
      #undef warnings if NO 'ciles were to be "done". Unfortunately, the
      #tails in will not connect because they are drawn by two separate
      #lines after the ciles are draw---that is the key.
      $first_height = $height if not defined $first_height;
      $final_height = $height;
      next unless($para{-doit});

      $canv->createRectangle(@coords,
                       -fill    => $para{-fillcolor},
                       -outline => $para{-linecolor},
                       -width   => $para{-linewidth}, @dash,
                       -tags    => $tag);
      createRectangleMetaPost(@coords,
                       {-fill    => $para{-fillcolor},
                        -outline => $para{-linecolor},
                        -width   => $para{-linewidth}, @dash});
      my ($x,$y1,$y2) = ($coords[0], $coords[3], $coords[1]);
      my ($text1, $text2) = ($cile eq 'centacile') ?
                                  ("99th$percent", " 1st$percent") :
                            ($cile eq 'decile')    ?
                                  ("90th$percent", "10th$percent") :
                            ($cile eq 'pentacile')    ?
                                  ("80th$percent", "20th$percent") :
                            ($cile eq 'quartile')    ?
                                  ("75th$percent", "25th$percent") :
                                  ("67th$percent", "33rd$percent") ;
                                  
      ($y1, $y2) = ($y2, $y1) if($is_reversed);
      $canv->createText(($xo - $gap), $y1,
                         -text    => $text1,
                         -fill    => $fontcolor,
                         -font    => $font,
                         -justify => 'right',
                         -anchor  => 'e',
                         -tag     => $tag);
      createAnnoTextMetaPost(($xo - $gap), $y1,
                             {-text    => $text1,
                              -fill    => $fontcolor,
                              -family  => $ftref->{-family},
                              -size    => $ftref->{-size},
                              -weight  => $ftref->{-weight},
                              -slant   => $ftref->{-slant},
                              -angle   => $ftref->{-rotation},
                              -justify => 'right',
                              -anchor  => 'e'});
      $canv->createText(($xo - $gap), $y2,
                         -text    => $text2,
                         -fill    => $fontcolor,
                         -font    => $font,
                         -justify => 'right',
                         -anchor  => 'e',
                         -tag     => $tag);
      createAnnoTextMetaPost(($xo - $gap), $y2,
                             {-text    => $text1,
                              -fill    => $fontcolor,
                              -family  => $ftref->{-family},
                              -size    => $ftref->{-size},
                              -weight  => $ftref->{-weight},
                              -slant   => $ftref->{-slant},
                              -angle   => $ftref->{-rotation},
                              -justify => 'right',
                              -anchor  => 'e'});
      $cilenum--;
   }
   
   # handle the location 
   my $locref = $self->{-location}; 
   if($locref->{-doit}) {
      if($locref->{-showtype} eq 'mean') {
            my $width = $locref->{-width};
            my @coords = ($xo + $basewidth/TWO - $width/TWO,
                          $yo + $baseyoff,
                          $xo + $basewidth/TWO + $width/TWO,
                          $yo + $baseyoff);
            $canv->createLine(@coords,
                              -fill  => $locref->{-linecolor},
                              -width => $locref->{-linewidth},
                              -tags  => $tag);
            createLineMetaPost(@coords,
                               {-fill  => $locref->{-linecolor},
                                -width => $locref->{-linewidth}});
            unless($points_doit) {
               $canv->createText(($xo - $gap), $yo + $baseyoff,
                         -text    => "Mean",
                         -fill    => $fontcolor,
                         -font    => $font,
                         -justify => 'right',
                         -anchor  => 'e',
                         -tag     => $tag);
               createAnnoTextMetaPost(($xo - $gap), $yo + $baseyoff,
                         {-text    => "Mean",
                          -fill    => $fontcolor,
                          -family  => $ftref->{-family},
                          -size    => $ftref->{-size},
                          -weight  => $ftref->{-weight},
                          -slant   => $ftref->{-slant},
                          -angle   => $ftref->{-rotation},
                          -justify => 'right',
                          -anchor  => 'e'});
            }
            &_draw_symbology($canv,$locref,
                             ($xo+$basewidth/TWO),
                             ($yo + $baseyoff),
                             $tag);
      }
      if($locref->{-showtype} eq 'median') {
            my $width = $locref->{-width};
            my @coords = ($xo + $basewidth/TWO - $width/TWO,
                          $yo + $baseyoff + $final_height/TWO,
                          $xo + $basewidth/TWO + $width/TWO,
                          $yo + $baseyoff + $final_height/TWO);
            $canv->createLine(@coords,
                              -fill  => $locref->{-linecolor},
                              -width => $locref->{-linewidth},
                              -tags  => $tag);
            createLineMetaPost(@coords,
                               {-fill  => $locref->{-linecolor},
                                -width => $locref->{-linewidth}});
            $canv->createText(($xo - $gap), $yo + $baseyoff + $final_height/TWO,
                         -text    => "Median (50th$percent)",
                         -fill    => $fontcolor,
                         -font    => $font,
                         -justify => 'right',
                         -anchor  => 'e',
                         -tag     => $tag);
            createAnnoTextMetaPost(($xo - $gap), $yo + $baseyoff + $final_height/TWO,
                         {-text    => "Median (50th$percent)",
                          -fill    => $fontcolor,
                          -family  => $ftref->{-family},
                          -size    => $ftref->{-size},
                          -weight  => $ftref->{-weight},
                          -slant   => $ftref->{-slant},
                          -angle   => $ftref->{-rotation},
                          -justify => 'right',
                          -anchor  => 'e'});
            &_draw_symbology($canv,$locref,
                             ($xo+$basewidth/TWO),
                             ($yo + $baseyoff + $final_height/TWO),
                             $tag);
      }
   }
  
   $first_height = &_draw_tails($canv,$self,$is_reversed,
                $xo,$yo,
                $basewidth,$gap,$baseyoff,$first_height,$final_height,
                $font,$fontcolor,$tag,$ftref);
   &_draw_sample_size($canv, $self, $is_reversed, 
                      $xo,$yo,$basewidth,$gap, $baseyoff, $first_height,
                      $font, $fontcolor, $tag, $ftref);
   return 1;
}

sub _draw_tails {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($canv,$boxstyle,$is_reversed,
       $xo,$yo,
       $basewidth,$gap,$baseyoff,$first_height,$final_height,
       $font,$fontcolor,$tag,$ftref) = @_;
   
   my %para = %{ $boxstyle->{-tail} };
   return $first_height unless($para{-doit});
   
   my $type     = $para{-type};
   my $lgest    = "or largest value";
   my $smest    = "or smallest value";
   my $iqr1d5_1 = "1.5*IQR $lgest";
   my $iqr1d5_2 = "-".$iqr1d5_1;
   my $iqr3_1   = "3*IQR $lgest";
   my $iqr3_2   = "-".$iqr3_1;
   my ($text1, $text2) =
             ($type eq 'Range')   ? ('Largest value','Smallest value') :
             ($type eq '1.5*IQR') ? ($iqr1d5_1, $iqr1d5_2)             :
                                    ($iqr3_1,     $iqr3_2);
   
   my $yo_plus_baseyoff = $yo + $baseyoff;
   my $y1_1 = ($yo_plus_baseyoff - $first_height);
   my $y2_1 = ($yo_plus_baseyoff + $first_height);
   my $y1_2 = ($y1_1 - $final_height);
   my $y2_2 = ($y2_1 + $final_height);
   
   ($y1_1, $y2_1, $y1_2, $y2_2) =
   ($y2_1, $y1_1, $y2_2, $y1_2) if($is_reversed);
   my $xo_minus_gap = $xo - $gap;
   $canv->createText($xo_minus_gap, $y1_2,
                     -text    => "$text1",
                     -font    => $font,
                     -anchor  => "e",
                     -justify => 'right', 
                     -fill    => $fontcolor,
                     -tags    => $tag);
   my $mp_text1 = $text1; # MetaPost 
   my $mp_text2 = $text2; # MetaPost
   if($mp_text1 =~ /IQR/) { # MetaPost
     $mp_text1 =~ s/1\.5\*IQR/\$1.5\\times IQR\$/; # MetaPost
     $mp_text2 =~ s/\-1\.5\*IQR/\$-1.5\\times IQR\$/; # MetaPost
     $mp_text1 =~ s/3\.0\*IQR/\$3.0\\times IQR\$/; # MetaPost
     $mp_text2 =~ s/\-3\.0\*IQR/\$-3.0\\times IQR\$/; # MetaPost
   } # MetaPost
   createAnnoTextMetaPost($xo_minus_gap, $y1_2,
                     {-text    => "$mp_text1",
                      -family  => $ftref->{-family},
                      -size    => $ftref->{-size},
                      -weight  => $ftref->{-weight},
                      -slant   => $ftref->{-slant},
                      -angle   => $ftref->{-rotation},
                      -anchor  => "e",
                      -justify => 'right', 
                      -fill    => $fontcolor});
   $canv->createText($xo_minus_gap, $y2_2,
                     -text    => "$text2",
                     -font    => $font,
                     -anchor  => "e",
                     -justify => 'right', 
                     -fill    => $fontcolor,
                     -tags    => $tag);   
   createAnnoTextMetaPost($xo_minus_gap, $y2_2,
                     {-text    => "$mp_text2",
                      -family  => $ftref->{-family},
                      -size    => $ftref->{-size},
                      -weight  => $ftref->{-weight},
                      -slant   => $ftref->{-slant},
                      -angle   => $ftref->{-rotation},
                      -anchor  => "e",
                      -justify => 'right', 
                      -fill    => $fontcolor});
   my $x = ($xo + $basewidth/TWO);
   my @dash = ();
   push(@dash, (-dash => $para{-dashstyle}) )
              if($para{-dashstyle} and
                 $para{-dashstyle} !~ /Solid/io);
      
   $canv->createLine($x,$y1_1, $x,$y1_2,
                     -fill  => $para{-linecolor},
                     -width => $para{-linewidth}, @dash,
                     -tag   => $tag);
   $canv->createLine($x,$y2_1, $x,$y2_2,
                     -fill  => $para{-linecolor},
                     -width => $para{-linewidth}, @dash,
                     -tag   => $tag);
   createLineMetaPost($x,$y1_1, $x,$y1_2,
                     {-fill  => $para{-linecolor},
                      -width => $para{-linewidth}, @dash});
   createLineMetaPost($x,$y2_1, $x,$y2_2,
                     {-fill  => $para{-linecolor},
                      -width => $para{-linewidth}, @dash});

   my %whisk = %{$para{-whiskers}};
   my $width = $whisk{-width}/TWO;
   return ($first_height + $final_height) unless($whisk{-doit});
   
   my ( @coords1, @coords2 );
   my ($x1, $x2) = ( $x-$width, $x+$width );
   @coords1 = ($x1, $y1_2, $x2, $y1_2);
   @coords2 = ($x1, $y2_2, $x2, $y2_2);
   my @args = ( -fill  => $whisk{-linecolor},
                -width => $whisk{-linewidth},
                -tag   => $tag );
   push(@args, (-dash => $whisk{-dashstyle}) )
              if($whisk{-dashstyle} and
                 $whisk{-dashstyle} !~ /Solid/io);                
   $canv->createLine( @coords1, @args );
   $canv->createLine( @coords2, @args );
   createLineMetaPost( @coords1, {@args} );
   createLineMetaPost( @coords2, {@args} );
   return ($first_height + $final_height);
}

sub _draw_sample_size {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($canv, $boxstyle, $is_reversed, $xo, $yo, $basewidth, $gap,
   $baseyoff, $height, $font, $fontcolor, $tag, $txftref) = @_;

   my %para = %{ $boxstyle->{-sample} };
    
   return 0 unless($para{-doit});
   
   my $text   = 62;
   my $orient = $boxstyle->{-orientation};
   
   my $ftref = $para{-font};
   &deleteFontCache(); # Perl 5.8.3 and Tk 804.027 error trapping
   my $samplefont  = $canv->fontCreate($tag."specialplotfont",
                      -family => $ftref->{-family},
                      -size   => ($ftref->{-size}*
                                  $::TKG2_ENV{-SCALING}*
                                  $::TKG2_CONFIG{-ZOOM}),
                      -weight => $ftref->{-weight},
                      -slant  => $ftref->{-slant} );
   
   my $angle = $ftref->{-rotation};
   
   my $numcommify = $para{-commify};
   my $numformat  = $para{-format};
   my $numdecimal = $para{-decimal};
   my $format;
   
   my $style  = $para{-location};
   my $offset = $para{-offset};
   
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
   
   $text =~ s/(.)/$1\n/g if($ftref->{-stackit});
   return 0 unless( defined $text );
   
   $text = "(".$text.")" if( $ftref->{-parenthesis}
                                      and
                             not $ftref->{-stackit} );
                            
   # Finished preparing the text string
   
   my $anchor;
   my $y;
   my ($opposite_y, $direction);
   my $ynbase = $yo + $baseyoff;
   if($style =~ /above/io) {
      $anchor = ($is_reversed) ? 'n' : 's';
      $y = (not $is_reversed) ? ($ynbase - $height - $offset) :
                                ($ynbase + $height + $offset) ;
      ($opposite_y, $direction) = ($is_reversed) ?
                                  ( ($ynbase - $height - $offset), -1) :
                                  ( ($ynbase + $height + $offset), +1) ;
   }
   else {
      $anchor = ($is_reversed) ? 's' : 'n';  
      $y = (     $is_reversed) ? ($ynbase - $height - $offset) :
                                 ($ynbase + $height + $offset) ;
      ($opposite_y, $direction) = ( not $is_reversed) ?
                                  ( ($ynbase - $height - $offset), -1) :
                                  ( ($ynbase + $height + $offset), +1) ;
   }
   # finally draw the text
   my $x = $xo + $basewidth / TWO;
   $canv->createText($x, $y,
                     -text   => $text,
                     -font   => $samplefont,
                     -anchor => $anchor, 
                     -fill   => $ftref->{-color},
                     -tags   => $tag);
   createAnnoTextMetaPost($x, $y,
                     {-text   => $text,
                      -family => $ftref->{-family},
                      -size   => $ftref->{-size},
                      -weight => $ftref->{-weight},
                      -slant  => $ftref->{-slant},
                      -angle  => $ftref->{-rotation},
                      -anchor => $anchor, 
                      -fill   => $ftref->{-color}});

   $canv->createText(($xo - $gap), $y,
                     -text    => "Sample size",
                     -font    => $font,
                     -anchor  => $anchor."e",
                     -justify => 'right', 
                     -fill    => $fontcolor,
                     -tags    => $tag);
  createAnnoTextMetaPost(($xo - $gap), $y,
                     {-text    => "Sample size",
                      -family  => $txftref->{-family},
                      -size    => $txftref->{-size},
                      -weight  => $txftref->{-weight},
                      -slant   => $txftref->{-slant},
                      -angle   => 0,
                      -anchor  => $anchor."e",
                      -justify => 'right', 
                      -fill    => $fontcolor});
  $canv->fontDelete($tag."specialplotfont");
  
 
   &_draw_data_and_outliers($canv, $boxstyle,
               $xo, $opposite_y, $basewidth, $gap, $direction,
               $font, $fontcolor, $tag, $txftref);
   
  return 1;
}

sub _draw_data_and_outliers {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($canv, $boxstyle,
       $xo, $y, $basewidth, $gap, $direction,
       $font, $fontcolor, $tag, $ftref) = @_;
   
   # anonymous subroutine to handle the point and text drawing
   my $_plot_it =
      sub {
         my ($canv, $text, $x_text, $x, $y,
             $font, $fontcolor, $tag, $style) = @_;
         my %style = %{ $style };
         my $para = { -symbol       => $style{-symbol},
                      -size         => $style{-size},
                      -angle        => $style{-angle},
                      -outlinecolor => $style{-outlinecolor},
                      -outlinewidth => $style{-outlinewidth},
                      -fillcolor    => $style{-fillcolor} };
         &_reallydrawpoints($canv, $x, $y, $tag, $para);
         $canv->createText(($xo - $gap), $y,
                        -text    => $text,
                        -font    => $font,
                        -anchor  => "e",
                        -justify => 'right',
                        -fill    => $fontcolor,
                        -tags    => $tag);
         createAnnoTextMetaPost(($xo - $gap), $y,
                        {-text    => $text,
                         -family  => $ftref->{-family},
                         -size    => $ftref->{-size},
                         -weight  => $ftref->{-weight},
                         -slant   => $ftref->{-slant},
                         -angle   => $ftref->{-rotation},
                         -anchor  => "e",
                         -justify => 'right',
                         -fill    => $fontcolor});
      };
   
   my $x = $xo + $basewidth/TWO; # the x center line in the explanation
   # offset controls the separation between the plotting of the
   # data point, the outlier (type1), and the far outlier (type2). 
   my $offset = $direction*$gap*3;
   
   # draw the example data point
   if($boxstyle->{-show_data}->{-doit}) {
      &$_plot_it($canv, "Data value", ($xo - $gap), $x, $y,
                 $font, $fontcolor, $tag, $boxstyle->{-show_data});
      $y += $offset;
   }
   
   # draw the type 1 outlier example
   if($boxstyle->{-type1_outliers}->{-doit}) {
      &$_plot_it($canv, "Outlier", ($xo - $gap), $x, $y,
                 $font, $fontcolor, $tag, $boxstyle->{-type1_outliers});
      $y += $offset;
   }
   
   # draw the type 2 outlier example
   if($boxstyle->{-type2_outliers}->{-doit}) {
      &$_plot_it($canv, "Far outlier", ($xo - $gap), $x, $y,
                 $font, $fontcolor, $tag, $boxstyle->{-type2_outliers});
      $y += $offset;
   }
   
   return 1;
}


sub _draw_symbology {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($canv,$locref, $x, $y, $tag) = @_;
   
   return 0 unless($locref->{-symbology}->{-doit});
   
   my %para = %{ $locref->{-symbology} };
   my $para = { -symbol       => $para{-symbol},
                -size         => $para{-size},
                -angle        => $para{-angle},
                -outlinecolor => $para{-outlinecolor},
                -outlinewidth => $para{-outlinewidth},
                -fillcolor    => $para{-fillcolor} }; 
   &_reallydrawpoints($canv, $x, $y, $tag, $para);
   return 1;
}

1;   
