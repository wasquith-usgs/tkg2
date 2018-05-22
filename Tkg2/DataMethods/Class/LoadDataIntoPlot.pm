package Tkg2::DataMethods::Class::LoadDataIntoPlot;

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
# $Date: 2004/06/09 18:51:06 $
# $Revision: 1.22 $

use strict;
use Tkg2::Base qw(Message Show_Me_Internals isNumber getShortenedFileName);
use Tkg2::Help::Help;

use Tkg2::DataMethods::Class::LoadData qw(LoadDataSets);

use Exporter;
use SelfLoader;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw(LoadDataIntoPlot);

print $::SPLASH "=";

1;

__DATA__

sub LoadDataIntoPlot {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $canv, $plot, $template, $header, $data, $para, $plotpara, $linecount) = @_; 
   my $which_y_axis = ($plotpara->{-which_y_axis} == 2) ? 'second y-axis' : 'first y-axis'; # DOUBLE Y:
   # Is the plot going to be a box and what is its orientation
   my $BoxPlotOrient;
   my     $isBoxPlot = ($plotpara->{-plotstyle} =~ m/box/i  ) ?  1 : 0; 
   if($isBoxPlot) {
      $isBoxPlot     = ($plotpara->{-plotstyle} =~ m/group/i) ? 'by_group' : 'by_column' ;
      $BoxPlotOrient = ($plotpara->{-plotstyle} =~ m/vert/i ) ? 'vertical' : 'horizontal';
   }

   my ($abscissa, @ordinates, $entry, $lb_o, $thirdord, $fourthord,
       $lower_threshold, $upper_threshold);
   my $deBUG = $::TKG2_CONFIG{-DEBUG};
   
   my $font  = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};   
   my $fontb = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};  
   
   my $moment_calc_method = $::TKG2_CONFIG{-DEFAULT_BOXPLOT_MOMENT_CALC_METHOD};
   my $transformation     = $::TKG2_CONFIG{-DEFAULT_BOXPLOT_TRANSFORMATION_METHOD};  
   
   my $pw = $canv->parent;
   my $pe = $pw->Toplevel(
               -title => "Load Data into $which_y_axis ".
                         "$plotpara->{-plotstyle} Plot"); # DOUBLE Y:
   $pe->resizable(0,0);   
   
   my $f_1 = $pe->Frame->pack(-side => 'top', -fill => 'x');
   unless(defined($linecount)) { $pe->destroy; return; }
   
   my $file = ($para->{-userelativepath}) ? $para->{-relativefilename} : 
                                            $para->{-fullfilename}     ;
   
   my $headertext;

   my $shortfile = &getShortenedFileName($file,3);
      
   if($plotpara->{-plotstyle} eq 'X-Probability' or
      $plotpara->{-plotstyle} eq 'Y-Probability') {
      $headertext = "Select Variable to plot in a $plotpara->{-plotstyle} plot:\n\n".
                    "$shortfile with $linecount lines read\n\n".
                    "Variables (name:type)                     Plot Variable:";
   }
   elsif($isBoxPlot) {
      my $axis_name = ($BoxPlotOrient eq 'vertical') ? 'x-axis' : 'y-axis';   
      if($isBoxPlot eq 'by_group') {
         $headertext = "Select the $axis_name grouping variable and the ".
                       "analysis variables to plot:\n\n".
                       "$shortfile with $linecount lines read\n\n".
                    "Variables (name:type)                     Group Variable:";
      }
      else {
         $headertext = "Select the variable(s) to plot in $BoxPlotOrient boxes:\n\n".
                       "$shortfile with $linecount lines read\n\n".
                    "Variables (name:type)                     Plot Variable:";
      }
   }
   else {
      my $axis = ($plotpara->{-which_y_axis} == 2) ? 'y2' : 'y';   # DOUBLE Y:
      $axis = uc($axis);
      $headertext = "Select abscissa (X) and ordinate ($axis) from file:\n\n".
                    "$shortfile with $linecount lines read\n\n".
                    "Variables (name:type)                    Abscissa (X):";
   }
                    
   $f_1->Label(-text    => "$headertext",
               -font    => $fontb,
               -justify => 'left')
       ->pack(-side => 'left');
   my $f_5     = $pe->Frame->pack(-side => 'bottom', -fill => 'x');
   my $f_4     = $pe->Frame->pack(-side => 'bottom', -fill => 'x');
   my $f_2     = $pe->Frame->pack(-side => 'left',   -fill => 'x');
   
   my $f_3;
   if($plotpara->{-plotstyle} =~ /text|Shade Between/io or
      $plotpara->{-plotstyle} eq 'Y-Error Bar' or
      $plotpara->{-plotstyle} eq 'Y-Error Limits') {
       $f_3 = $f_4->Frame->pack(-side => 'top', -fill => 'x');
   } 
   
   my $f_3a;
   if($plotpara->{-plotstyle} eq 'X-Y Error Bar' or
      $plotpara->{-plotstyle} eq 'X-Y Error Limits') {
       $f_3  = $f_4->Frame->pack(-side => 'top', -fill => 'x');
       $f_3a = $f_4->Frame->pack(-side => 'top', -fill => 'x');   
   }
                               
   my $f_21 = $f_2->Frame->pack(-side => 'left', -fill => 'both');
   my $lb_a = $f_21->Scrolled("Listbox",
                              -scrollbars => 'se',
                              -font       => $font,
                              -selectmode => 'single',
                              -background => 'white',
                              -width      => 30,
                              -height     => 12)
                   ->pack(-side => 'top', -fill => 'both');
   $lb_a->insert('end', @{$header});
                                         
   my $f_23 = $f_2->Frame->pack(-side => 'right', -fill => 'both');
   my $f_22 = $f_2->Frame->pack(-side => 'left',  -fill => 'y'   );
   
   # ABSCISSA ARROW
   unless($isBoxPlot eq 'by_column') {
      $f_22->Button(-text    => '-->',
                    -font    => $fontb,
                    -command => sub {
                                     $entry->configure(-state => 'normal');
                                     my $index = $lb_a->curselection;
                                     unless(defined $index ) {
                                        &Message($pe,'-selfromlist');
                                        return;
                                     }
                                     $abscissa = $lb_a->get($index);
                                     $entry->update;
                                     $entry->configure(-state => 'disabled');
                                    } )
           ->pack(-side => 'top');
   }                   
   # ORDINATE ARROW -- Usually present
   unless($plotpara->{-plotstyle} eq 'X-Probability' or
          $plotpara->{-plotstyle} eq 'Y-Probability') {
      $f_22->Button(-text    => '-->',
                    -font    => $fontb,
                    -command => sub {
                                     my $index = $lb_a->curselection;
                                     unless(defined $index ) {
                                        &Message($pe,'-selfromlist');
                                        return;
                                     }
                                     # delete any prior elements if we
                                     # are loading in to a
                                     if($isBoxPlot eq 'by_group') {
                                        $lb_o->delete('0.0','end');
                                     }
                                     $lb_o->insert('end', $lb_a->get($index) );
                                    } )
           ->pack(-side => 'top', -pady => 16);
   }
   
   unless($isBoxPlot eq 'by_column') {
      $entry = $f_23->Entry(-textvariable => \$abscissa,
                            -font         => $font,
                            -background   => 'white',
                            -state        => 'disabled')
                    ->pack(-side => 'top', -fill => 'x');
   }             
         
   unless($plotpara->{-plotstyle} eq 'X-Probability' or
          $plotpara->{-plotstyle} eq 'Y-Probability' ) {                      
      my $f_231 = $f_23->Frame->pack(-side => 'top', -fill => 'both');
      $f_231->Label(-text   => "Ordinate Variables (Y's):",
                    -font   => $fontb,
                    -anchor => 'w')->pack(-side => 'top', -fill => 'x');
      my @dim = ($isBoxPlot eq 'by_group') ? ( -width => 30, -height => 1) :
                                             ( -width => 30 );
      $lb_o = $f_231->Scrolled("Listbox",
                               -font       => $font,
                               -scrollbars => 'e',
                               -selectmode => 'extended',
                               -background => 'white',
                               @dim)
                    ->pack(-side => 'top', -fill => 'both', -expand => 1 );
      $f_231->Button(-text    => 'Delete Selected Ordinate',
                     -font    => $fontb,
                     -command => sub {
                                      my $index = $lb_o->curselection;
                                      unless(defined $index ) {
                                         &Message($pe,'-selfromlist');
                                         return;
                                      }
                                      $lb_o->delete($index);
                                     } )
           ->pack(-side => 'bottom', -fill => 'x', -expand => 1);                
   }
   
   my ($entry2, $entry3);
   if($plotpara->{-plotstyle} =~ /text|Shade Between/io ) {
       $entry2 = $f_3->Entry(-textvariable => \$thirdord,
                             -font         => $font,
                             -background   => 'white',
                             -state        => 'disabled',
                             -width        => 33)
                     ->pack(-side => 'right', -fill => 'x');                      
       $f_3->Button(-text    => '-->',
                    -font    => $fontb,
                    -command => sub {
                                     my $index = $lb_a->curselection;
                                     unless(defined $index ) {
                                        &Message($pe,'-selfromlist');
                                        return;
                                     }
                                     $entry2->configure(-state => 'normal');
                                     $thirdord = $lb_a->get($index);
                                     $entry2->update;
                                     $entry2->configure(-state => 'disabled');
                                    } )
           ->pack(-side => 'right', -fill => 'x');
      if($plotpara->{-plotstyle} =~ /text/io) {
         $f_3->Label(-text => "Text to show",
                     -font => $fontb)
             ->pack(-side => 'right');
      }
      else {
         $f_3->Label(-text => "Values to shade between",
                     -font => $fontb)
             ->pack(-side => 'right');      
      }
   }
   elsif($plotpara->{-plotstyle} eq 'Y-Error Bar' or
         $plotpara->{-plotstyle} eq 'Y-Error Limits') {
       $entry2 = $f_3->Entry(-textvariable => \$thirdord,
                             -font         => $font,
                             -background   => 'white',
                             -state        => 'disabled',
                             -width        => 33)
                     ->pack(-side => 'right', -fill => 'x');       
       $f_3->Button(-text    => '-->',
                    -font    => $fontb,
                    -command => sub {
                                     my $index = $lb_a->curselection;
                                     unless(defined $index ) {
                                        &Message($pe,'-selfromlist');
                                        return;
                                     }
                                     $entry2->configure(-state => 'normal');
                                     $thirdord = $lb_a->get($index);
                                     $entry2->update;
                                     $entry2->configure(-state => 'disabled');
                                    } )
           ->pack(-side => 'right', -fill => 'x');
       my $text = ($plotpara->{-plotstyle} eq 'Y-Error Bar') ?
                   "Y-Error Bar" : "Y-Error Limits";
       $f_3->Label(-text => "$text",
                   -font => $fontb)
           ->pack(-side => 'right');
   }
   elsif($plotpara->{-plotstyle} eq 'X-Y Error Bar' or
         $plotpara->{-plotstyle} eq 'X-Y Error Limits') {
       $entry2 = $f_3->Entry(-textvariable => \$thirdord,
                             -font         => $font,
                             -background   => 'white',
                             -state        => 'disabled',
                             -width        => 33)
                     ->pack(-side => 'right', -fill => 'x');                      
       $f_3->Button(-text    => '-->',
                    -font    => $fontb,
                    -command => sub {
                                     my $index = $lb_a->curselection;
                                     unless(defined $index ) {
                                        &Message($pe,'-selfromlist'),
                                        return;
                                     }
                                     $entry2->configure(-state => 'normal');
                                     $thirdord = $lb_a->get($index);
                                     $entry2->update;
                                     $entry2->configure(-state => 'disabled');
                                    } )
           ->pack(-side => 'right', -fill => 'x');
           
       my $text = ($plotpara->{-plotstyle} eq 'X-Y Error Bar') ?
                   'X-Error Bar' : "X-Error Limits"; 
       $f_3->Label(-text => $text,
                   -font => $fontb)
           ->pack(-side => 'right');   
       $entry3 = $f_3a->Entry(-textvariable => \$fourthord,
                              -font         => $font,
                              -background   => 'white',
                              -state        => 'disabled',
                              -width        => 33)
                      ->pack(-side => 'right', -fill => 'x');                      
       $f_3a->Button(-text    => '-->',
                     -font    => $fontb,
                     -command => sub {
                                      my $index = $lb_a->curselection;
                                      unless(defined $index ) {
                                         &Message($pe,'-selfromlist');
                                         return;
                                      }
                                      $entry3->configure(-state => 'normal');
                                      $fourthord = $lb_a->get($index);
                                      $entry3->update;
                                      $entry3->configure(-state => 'disabled'); } )
            ->pack(-side => 'right', -fill => 'x');
       
       $text = ($plotpara->{-plotstyle} eq 'X-Y Error Bar') ?
                   'Y-Error Bar' : "Y-Error Limits";
       $f_3a->Label(-text => $text,
                    -font => $fontb)
            ->pack(-side => 'right'); 
   }  
   
   
   # BOXPLOT SPECIFIC FEATURES
   if($isBoxPlot) {
      my $f_lower_thres = $f_4->Frame->pack(-side => 'top', -fill => 'x');
      my $f_upper_thres = $f_4->Frame->pack(-side => 'top', -fill => 'x');
      my $f_moment      = $f_4->Frame->pack(-side => 'top', -fill => 'x');
      my $f_trans       = $f_4->Frame->pack(-side => 'top', -fill => 'x');
      
      #$f_lower_thres->Label(-text => "Lower Detection Limit:Replacement",
      #                      -font => $fontb)->pack(-side => 'left');
      #$f_upper_thres->Label(-text => "Upper Detection Limit:Replacement",
      #                      -font => $fontb)->pack(-side => 'left');
      #$f_lower_thres->Entry(-textvariable => \$lower_threshold,
      #                      -font         => $font,
      #                      -width        => 12,
      #                      -background   => 'white' )
      #              ->pack(-side => 'left', -fill => 'x');
      #$f_upper_thres->Entry(-textvariable => \$upper_threshold,
      #                      -font         => $font,
      #                      -width        => 12,
      #                      -background   => 'white' )
      #              ->pack(-side => 'left', -fill => 'x');
      #$f_lower_thres->Label(-text => "Leave entries blank for none",
      #                      -font => $fontb)
      #              ->pack(-side => 'left', -fill => 'x');
      #$f_upper_thres->Label(-text => ":Replacement is optional",
      #                      -font => $fontb)
      #              ->pack(-side => 'left', -fill => 'x');  
       
       
      $f_moment->Label(-text => 'Moment calculation method for the box  ',
                       -font => $fontb)
                ->pack(-side => 'left', -fill => 'x');
                        
      $f_moment->Radiobutton(-text     => 'Product ',
                             -font     => $fontb,
                             -variable => \$moment_calc_method,
                             -value    => 'product')
               ->pack(-side => 'left', -fill => 'x');  
      $f_moment->Radiobutton(-text     => 'L-moment',
                             -font     => $fontb,
                             -variable => \$moment_calc_method,
                             -value    => 'linear')
               ->pack(-side => 'left', -fill => 'x');  
               
      $f_trans->Label(-text => 'Type of data transformation for the box',
                      -font => $fontb)
              ->pack(-side => 'left', -fill => 'x');
                       
      $f_trans->Radiobutton(-text     => 'Linear  ',
                            -font     => $fontb,
                            -variable => \$transformation,
                            -value    => 'linear')
              ->pack(-side => 'left', -fill => 'x');  
      $f_trans->Radiobutton(-text     => 'Log10   ',
                            -font     => $fontb,
                            -variable => \$transformation,
                            -value    => 'log10 ')
              ->pack(-side => 'left', -fill => 'x');                        
   }
   
   my ($px, $py) = (2, 2); 
   my $f_b = $f_5->Frame(-relief      => 'groove',
                         -borderwidth => 2)
                 ->pack(-side => 'bottom', -fill => 'x');                      
   my $b_ok = $f_b->Button(
                  -text        => 'OK',
                  -font        => $fontb,
                  -borderwidth => 3,
                  -highlightthickness => 2,
                  -command     => sub {
             my %box_instruct;
             if($entry) {  # entry is undef if a single variable boxplot  
               $abscissa = ${$entry->cget(-textvariable)};
               if(not defined($abscissa) or $abscissa !~ /:/) {
                 my $mess = "Abscissa has not been defined";
                 &Message($pe,'-generic', $mess);
                 return;
               }
             }
             # Deal with things if we have a probability request
             # we are adding a false ordinate or abscissa with -nonexceedance tagged on
             # we will rely on LoadDataSets or LoadDataSetsontheFly to compute 
             # the probabilities.
             if($plotpara->{-plotstyle} eq 'X-Probability') {
                @ordinates = ();
                push(@ordinates, $abscissa);  # The abscissa will be on Y-axis
                $abscissa = $abscissa."-nonexceedance";
                #print "X-probability plot X=$abscissa and Y=@ordinates\n";
             }
             elsif($plotpara->{-plotstyle} eq 'Y-Probability') {
                @ordinates = ();
                push(@ordinates, $abscissa."-nonexceedance");
                #print "Y-probability plot X=$abscissa and Y=@ordinates\n";
             }
             else {  # Usually the ordinates need to be grabbed
                @ordinates = $lb_o->get(0, 'end');
             }
             
             if(not @ordinates) {
                my $mess = "Ordinates have not been defined";
                &Message($pe,'-generic',$mess);
                return;
             }
             
             
             if($isBoxPlot) {
                $box_instruct{-moment_calc_method} = $moment_calc_method;
                $box_instruct{-transformation    } = $transformation;
                $box_instruct{-lower_detection_limit} = undef;
                $box_instruct{-lower_replace_value}   = undef;
                $box_instruct{-upper_detection_limit} = undef;
                $box_instruct{-upper_replace_value}   = undef;
                if(defined $lower_threshold) {
                   my ($lim, $val) = split(/:/o, $lower_threshold, 2);
                   if(defined $lim) {
                      if(not &isNumber($lim)) {
                         my $mess = "Lower detection limit is not a number";
                         &Message($pe,'-generic',$mess);
                         return;
                      }
                      if(defined $val) {
                         if(not &isNumber($val)) {
                            my $mess = "Lower detection replacement value ".
                                       "is not a number";
                            &Message($pe,'-generic',$mess);
                            return;
                         }
                      }
                      else {
                         $val = $lim;
                      }
                   }
                   $box_instruct{-lower_detection_limit} = $lim;
                   $box_instruct{-lower_replace_value}   = $val;
                }
                
                if(defined $upper_threshold) {
                   my ($lim, $val) = split(/:/o, $upper_threshold, 2);
                   if(defined $lim) {
                      if(not &isNumber($lim)) {
                         my $mess = "Upper detection limit is not a number";
                         &Message($pe,'-generic',$mess);
                         return;
                      }
                      if(defined $val) {
                         if(not &isNumber($val)) {
                            my $mess = "Upper detection replacement value ".
                                       "is not a number";
                            &Message($pe,'-generic',$mess);
                            return;
                         }
                      }
                      else {
                         $val = $lim;
                      }
                   }
                   $box_instruct{-upper_detection_limit} = $lim;
                   $box_instruct{-upper_replace_value}   = $val;
                }
                # now check whether the lower is less than the upper
                if( defined $box_instruct{-lower_detection_limit} and
                    defined $box_instruct{-upper_detection_limit} ) {
                   if($box_instruct{-lower_detection_limit} >= 
                      $box_instruct{-upper_detection_limit} ) {
                      my $mess = "The lower detection limit is greater than ".
                                 "or equal to the upper detection limit.";
                      &Message($pe,'-generic',$mess);
                      return;         
                   }   
                }
                # and finally check that the replacement values are ok
                if( defined $box_instruct{-lower_replace_limit} and
                    defined $box_instruct{-upper_replace_limit} ) {
                   if($box_instruct{-lower_replace_limit} >= 
                      $box_instruct{-upper_replace_limit} ) {
                      my $mess = "The lower replacement value is greater ".
                                 "than or equal to the upper replacement ".
                                 "value limit.";
                      &Message($pe,'-generic',$mess);
                      return;         
                   }   
                }
             }
             
             $pe->destroy;
             $canv->Busy;
             my @c_p_t  = ($canv, $plot, $template);
             my @ldargs = ($data, $abscissa, \@ordinates, $thirdord, $fourthord, 
                           $para, $plotpara, \%box_instruct);
             $self->LoadDataSets(@c_p_t, @ldargs);
             $canv->Unbusy;
             } )
       ->pack(-side => 'left', -padx => $px, -pady => $py); 
                    
                                         
   $b_ok->focus;
   $f_b->Button(-text    => "Cancel", 
                -font    => $fontb,
                -command => sub { $pe->destroy; return; })
       ->pack(-side => 'left', -padx => $px, -pady => $py);
                        
   $f_b->Button(-text    => "Help", 
                -font    => $fontb,
                -padx    => 4,
                -pady    => 4,
                -command => sub { return; } )
       ->pack(-side => 'left', -padx => $px, -pady => $py,);     
}

1;
