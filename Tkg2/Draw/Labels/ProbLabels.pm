 package Tkg2::Draw::Labels::ProbLabels;

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
# $Date: 2016/02/29 17:12:28 $
# $Revision: 1.36 $

use strict;

use Tkg2::Math::GraphTransform qw(transReal2CanvasGLOBALS revAxis);

use Tkg2::Base qw(Message commify Show_Me_Internals deleteFontCache);
use Tkg2::Draw::Labels::LabelUtilities qw( _drawTextonBottom 
                                           _drawTextonTop
                                           _drawTextonLeft
                                           _drawTextonRight
                                           _testLimits
                                          );
use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createLineMetaPost);

use Exporter;
use vars     qw(@ISA @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT_OK = qw(ProbLabels);


print $::SPLASH "=";

sub ProbLabels {  
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
    
   my ($self, $canv, $which, $type) = (shift, shift, shift, shift);  
   my ($xory, $i);
   my $double_y = $self->{-y2}->{-turned_on}; # DOUBLE Y
   return if($which eq '-y2' and not $double_y); # DOUBLE Y
   my $format = "";                   
   my (@majortick, @majorlabel, @minor);
   my ($x, $y);

   return unless(&_testLimits($self,$which));
   my ($xmin, $ymin, $xmax, $ymax) = $self->getPlotLimits;
   $self->setGLOBALS($which);  # DOUBLE Y
   my $ref = $self->{$which};
   my $rev         = $ref->{-reverse};
   my $location    = $ref->{-location};
   my $dblabel     = $ref->{-doublelabel};
   my $hidden      = $ref->{-hideit};
   my $blankit     = $ref->{-blankit};
   my $blankcolor  = $ref->{-blankcolor};
   my $automin     = $ref->{-autominlimit};
   my $automax     = $ref->{-automaxlimit};
   my $numoffset   = $ref->{-numoffset};
   my $numcommify  = $ref->{-numcommify};
   my $numformat   = $ref->{-numformat};
   my $numdecimal  = $ref->{-numdecimal};
   my ($min, $max) = ($ref->{-min}, $ref->{-max});
   my $basemajor   = $ref->{-basemajor};
   my $basemajortolabel = $ref->{-basemajortolabel};
   my $baseminor   = $ref->{-baseminor};
   my $specmajor   = $ref->{-major};
   my $specminor   = $ref->{-minor};
   my $tick        = $ref->{-ticklength};
   my $tickwidth   = $ref->{-tickwidth};
   my $spectickratio = $ref->{-spectickratio};
   my $tickratio = $ref->{-tickratio};
   
   # Backwards compatability for 0.50.3
   my $labelmin = (defined $ref->{-labelmin}) ? $ref->{-labelmin} : 1;
   my $labelmax = (defined $ref->{-labelmax}) ? $ref->{-labelmax} : 1;

   # Backwards compatability for 0.51.1
   my $min2beglab = (defined $ref->{-min_to_begin_labeling}) ?
                             $ref->{-min_to_begin_labeling}  : "";
   my $max2endlab = (defined $ref->{-max_to_end_labeling})   ? 
                             $ref->{-max_to_end_labeling}    : "";

   # Backwards compatability for 0.61
   my $tick2actualminmax = (defined $ref->{-tick_to_actual_min_and_max}) ?
                                    $ref->{-tick_to_actual_min_and_max} : 0;
  
   # Perl 5.10.1 bug fixes, we will see the paired application of 'eq'
   # instead of '==' in testing these actual values against real_xory in
   # 6 places in this file. WHA 10/06/2010
   my $actualmin = $min; # preserve the actual or original minimum
   my $actualmax = $max; # and maximum offsets so that we can tick
                         # properly if the label beginning and
                         # ending are specified.
   if(not $tick2actualminmax) {
      $min = $min2beglab if($min2beglab or $min2beglab eq 0);
      $max = $max2endlab if($max2endlab or $max2endlab eq 0);
   }
   my $gridminmax = 1 if($tick2actualminmax); # yes grid to the limits
   
   
   my $fref = $ref->{-numfont};
   my $stackit = $fref->{-stackit};
   &deleteFontCache(); # Perl 5.8.3 and Tk 804.027 error trapping
   my $numfont = $canv->fontCreate($self."$which"."numfont", 
            -family => $fref->{-family},
            -size   => ($fref->{-size}*
                        $::TKG2_ENV{-SCALING}*
                        $::TKG2_CONFIG{-ZOOM}),
            -weight => $fref->{-weight},
            -slant  => $fref->{-slant});
   my $numrotation = $fref->{-rotation};
   my $numcolor =  $ref->{-numfont}->{-color};
   my $linecolor = $self->{-bordercolor};
   
   my $gref = $ref->{-gridmajor};   
   my $majorgridlinedoit  = $gref->{-doit};
   my $majorgridlinewidth = $gref->{-linewidth};
   my $majorgridlinecolor = $gref->{-linecolor};
   my $majorgriddashstyle = $gref->{-dashstyle};
   my @majordash = (-dash => $majorgriddashstyle)
                  if($majorgriddashstyle and
                     $majorgriddashstyle !~ /Solid/io);
      
      $gref = $ref->{-gridminor};
   my $minorgridlinedoit  = $gref->{-doit};
   my $minorgridlinewidth = $gref->{-linewidth};
   my $minorgridlinecolor = $gref->{-linecolor};
   my $minorgriddashstyle = $gref->{-dashstyle};
   my @minordash = (-dash => $minorgriddashstyle)
                  if($minorgriddashstyle and
                     $minorgriddashstyle !~ /Solid/io);
         
   my $ri_style = $ref->{-probUSGStype};
   my @RI = qw(2 5 10 25 50 100 250 500);
   my @RI_as_prob = map { 1 - 1 / $_ } @RI;
  
   my $invertprob = $ref->{-invertprob};

   $basemajor        = [ @{$::TKG2_CONFIG{-PROB_BASE_MAJOR_TICKS}} ] 
                       if(not @$basemajor);
   $basemajortolabel = [ @{$::TKG2_CONFIG{-PROB_BASE_MAJOR_LABEL}} ]
                       if(not @$basemajortolabel);
   
   foreach my $base (@{$basemajor}) {
      next if($base < $min or $base > $max);
      push(@majortick, $base);
   }
   foreach my $base (@{$basemajortolabel}) {
      next if($base < $min or $base > $max);
      push(@majorlabel, ($base*100));
   } 
   foreach my $base (@{$baseminor}) {
      next if($base < $min or $base > $max);
      push(@minor, $base);  
   }
   
   # now make sure that the min and the maximum are going to be plotted
   unshift( @majorlabel, ($min*100) ) unless($majorlabel[0] eq ($min*100) or
                                             $majorlabel[0] == ($min*100) or
                                             not $labelmin);
   unshift( @majortick, $min)  unless($majortick[0] eq $min or
                                      $majortick[0] == $min);

   push( @majorlabel, ($max*100) )
          unless($majorlabel[$#majorlabel] eq ($max*100) or
                 $majorlabel[$#majorlabel] == ($max*100) or
                 not $labelmax);
   push( @majortick, $max)
          unless($majortick[$#majortick] eq $max or 
                 $majortick[$#majortick] == $max);
       
   unless($numformat eq 'free') {
      ($numformat eq 'sci') ? ($format = "%0.$numdecimal"."e") :
                              ($format = "%0.$numdecimal"."f") ;
   }
  
   my @lineattr = (-width => $tickwidth, -fill => $linecolor);
   # The inclusion of $which on the tag is to keep blanking from
   # conflicting with other axis labels--bug fix for 0.80.  
   my @textattr = ("$self"."$which", $numoffset, $numfont,
                            $numcolor, $blankit, $blankcolor, $numrotation, $fref);   


   # DATELINE: November 4, 2010
   # In the NWIS4.10/Perl5.10 BUG FIX identifiers, "proven fix" means that
   # the operation changes or fixes numerical behavior in GraphTransform.pm
   # The "inferred fix" means that WHA is guessing that this should be done
   # because of code similarity. It is not known why wrapping "" around the
   # values significantly changes how Perl will later handle numerical
   # computations in the realspace --> canvas space in GraphTransform.pm and
   # why the computation problem somehow involves integer axis limits (YMIN)
   # is proven and only for at least the arrays @majortick and @minortick.
   # This string casting is only proven to be needed in LinearLabels.pm, but
   # structurally similar adjustments are made in LogLabels.pm, ProbLabels.pm,
   # and DiscreteLabels.pm
   foreach (@majortick ) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix
   foreach (@minor     ) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix

   # DRAW THE MAJOR TICKS
   foreach my $i (0..$#majortick) {
      my $real_xory = $xory = $majortick[$i];
      next if($xory <= 0 or $xory >= 1);
      $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $xory);
      next if(not defined $xory);
      $xory = &revAxis($self, $which,$xory) if($rev);
      if($which eq '-x') {
         if($majorgridlinedoit) {
            if(($real_xory eq $actualmin or
                $real_xory eq $actualmax) and not $gridminmax) {
               # do nothing for now
            }
            else {
               my @lineattr = (-width => $majorgridlinewidth,
                               -fill  => $majorgridlinecolor,
                               @majordash);
               $canv->createLine($xory, $ymin, $xory, $ymax,@lineattr,
                                 -tags  => [ $self.'majorgrid' ]);
               createLineMetaPost($xory, $ymin, $xory, $ymax, {@lineattr});
            }
         }
         $canv->createLine($xory, $ymax,
                           $xory, $ymax-$tick, @lineattr);
         createLineMetaPost($xory, $ymax,
                            $xory, $ymax-$tick, {@lineattr});
         unless($ri_style) {
            $canv->createLine($xory, $ymin,
                              $xory, $ymin+$tick, @lineattr);
            createLineMetaPost($xory, $ymin,
                               $xory, $ymin+$tick, {@lineattr});
         }
      }
      elsif($which eq '-y') {
         if($majorgridlinedoit) {
            if(($real_xory eq $actualmin or
                $real_xory eq $actualmax) and not $gridminmax) {
               # do nothing for now
            }
            else {
               my @lineattr = (-width => $majorgridlinewidth,
                               -fill  => $majorgridlinecolor,
                               @majordash);
               $canv->createLine($xmin, $xory, $xmax, $xory, @lineattr,
                                 -tags  => [ $self.'majorgrid' ]);
               createLineMetaPost($xmin, $xory, $xmax, $xory, {@lineattr});
            }
         }
         $canv->createLine($xmin,         $xory,
                           $xmin + $tick, $xory, @lineattr);
         createLineMetaPost($xmin,         $xory,
                            $xmin + $tick, $xory, {@lineattr});
         unless($ri_style or $double_y) {
            $canv->createLine($xmax, $xory,
                              $xmax-$tick, $xory, @lineattr);
            createLineMetaPost($xmax, $xory,
                               $xmax-$tick, $xory, {@lineattr});
         }
      }     
      else {
         if($majorgridlinedoit) {
            if(($real_xory eq $actualmin or
                $real_xory eq $actualmax) and not $gridminmax) {
               # do nothing for now
            }
            else {
               my @lineattr = (-width => $majorgridlinewidth,
                               -fill  => $majorgridlinecolor,
                               @majordash);
               $canv->createLine($xmin, $xory, $xmax, $xory, @lineattr,
                                 -tags  => [ $self.'majorgrid' ]);
               createLineMetaPost($xmin, $xory, $xmax, $xory, {@lineattr});
            }
         }
         $canv->createLine($xmax, $xory,
                           $xmax-$tick, $xory, @lineattr);      
         createLineMetaPost($xmax, $xory,
                            $xmax-$tick, $xory, {@lineattr});
      }
      last if($i == $#majortick);
   }
   
   
   ## DRAW RECURRENCE INTERVAL STYLE RECURRENCE INTERVALS
   if($ri_style) {
      # If the RI style of probability axis is desired then override
      # and reset any changes to the location of the principal axis
      # labeling for good.
      $ref->{-location}    = ($which eq '-x') ? 'bottom' : 'left';
      $ref->{-doublelabel} = $dblabel = 0;  # turn double labeling off for good
      foreach my $i (0..$#RI) {
         $xory = $RI_as_prob[$i];
         next if($xory <= 0 or $xory >= 1);
         $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $xory); 
         next if(not defined $xory);
         $xory = &revAxis($self, $which,$xory) if($rev);           
         
          my $text = $RI[$i];            
          $text = &commify($text) if($numcommify);
          $text =~ s/(.)/$1\n/g   if($stackit);
          if($which eq '-x') {
            unless($hidden) {
              $canv->createText($xory, $ymin-$numoffset,
                                -text => "$text",
                                -font => $numfont,
                                -fill => $numcolor);
            }
            $canv->createLine($xory, $ymin,
                              $xory, $ymin+$tick, @lineattr);
            createLineMetaPost($xory, $ymin,
                               $xory, $ymin+$tick, {@lineattr});
         }
         elsif($which eq '-y') {
            unless($hidden) {
               $canv->createText($xmax+$numoffset, $xory,
                                 -text   => "$text",
                                 -anchor => 'w',
                                 -font   => $numfont,
                                 -fill   => $numcolor);
            }
            $canv->createLine($xmax, $xory,
                              $xmax-$tick, $xory, @lineattr);
            createLineMetaPost($xmax, $xory,
                               $xmax-$tick, $xory, {@lineattr});                  
         }   
         else { # DOUBLE Y
            # so if on the second y-axis and gsstyle then plot
            # the RIs on the left of the graph ($xmin) instead of
            # the right ($xmax) like is done in the above conditional
            unless($hidden) {
               $canv->createText($xmin-$numoffset, $xory,
                                 -text   => "$text",
                                 -anchor => 'w',
                                 -font   => $numfont,
                                 -fill   => $numcolor);
            }
            $canv->createLine($xmin, $xory,
                              $xmin+$tick, $xory, @lineattr);
            createLineMetaPost($xmin, $xory,
                               $xmin+$tick, $xory, {@lineattr});
         
         }
      }
   }



   # DRAW THE LABELS
   push(@majorlabel, ($min2beglab)) if($min2beglab ne "");
   push(@majorlabel, ($max2endlab)) if($max2endlab ne "");   
   foreach (@majorlabel) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix
   foreach my $i (0..$#majorlabel) {
     $xory  = $majorlabel[$i];
     $xory /= 100;
     next if($min2beglab ne "" and $xory < $min2beglab);
     next if($max2endlab ne "" and $xory > $max2endlab);
     next if($xory <= 0 or $xory >= 1);
     $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $xory); 
     next if(not defined $xory);
     $xory = &revAxis($self, $which, $xory) if($rev);
     my $text = $majorlabel[$i];   
     $text = 100 - $text if($invertprob);  
     $text = sprintf("%0.6g", $text);      
     $text = sprintf("$format", $text) unless($numformat eq 'free');
     $text = &commify($text) if($numcommify);
     $text =~ s/(.)/$1\n/g   if($stackit);
     unless($hidden) {
       if($which eq '-x') {
         if($dblabel) {
           &_drawTextonTop($canv,$xory,$ymin,$text,@textattr);
           &_drawTextonBottom($canv,$xory,$ymax,$text,@textattr);
         }
         elsif($location eq 'bottom') {
           &_drawTextonBottom($canv,$xory,$ymax,$text,@textattr);
         }
         elsif($location eq 'top') {
           &_drawTextonTop($canv,$xory,$ymin,$text,@textattr);
         }
         else {
           die "Bad location '$location' call on probability label\n";
         }              
       }
       elsif($which eq '-y') {
         if($dblabel and not $double_y) { # DOUBLE Y
           &_drawTextonLeft($canv,$xmin,$xory,$text,@textattr);
           &_drawTextonRight($canv,$xmax,$xory,$text,@textattr);
         }
         elsif($location eq 'left' or $double_y) { # DOUBLE Y
           &_drawTextonLeft($canv,$xmin,$xory,$text,@textattr);
         }
         elsif($location eq 'right' and not $double_y ) { # DOUBLE Y
           &_drawTextonRight($canv,$xmax,$xory,$text,@textattr);
         }
         else {
             die "Bad location '$location' call on probability label\n";
         }
       }
       else {  # DOUBLE Y
          &_drawTextonRight($canv,$xmax,$xory,$text,@textattr);
       }
     }   
   }


   # DRAW THE MINOR TICKS
   foreach my $i (0..$#minor) {
      my $xoryminor = $minor[$i];
      next if($xoryminor <= 0 or $xoryminor >= 1);
      $xoryminor = &transReal2CanvasGLOBALS($self, $which, $type, 1, $xoryminor);
      next if(not defined $xoryminor);
      $xoryminor = &revAxis($self, $which, $xoryminor) if($rev);
      if($which eq '-x') {
         if($minorgridlinedoit) {
            my @lineattr = (-width => $minorgridlinewidth,
                            -fill  => $minorgridlinecolor,
                            @minordash);
            $canv->createLine($xoryminor, $ymin, $xoryminor, $ymax, @lineattr,
                              -tags  => [ $self.'minorgrid' ]);
            createLineMetaPost($xoryminor, $ymin, $xoryminor, $ymax, {@lineattr});
         }
         unless($ri_style) { 
            $canv->createLine($xoryminor, $ymin,
                              $xoryminor, $ymin+($tick*$tickratio), @lineattr);
            createLineMetaPost($xoryminor, $ymin,
                               $xoryminor, $ymin+($tick*$tickratio), {@lineattr});
         }
         $canv->createLine($xoryminor, $ymax,
                           $xoryminor, $ymax-($tick*$tickratio), @lineattr);
         createLineMetaPost($xoryminor, $ymax,
                            $xoryminor, $ymax-($tick*$tickratio), {@lineattr});
      }
      elsif($which eq '-y') {
         if($minorgridlinedoit) {
            my @lineattr = (-width => $minorgridlinewidth,
                            -fill  => $minorgridlinecolor,
                            @minordash);
            $canv->createLine($xmin, $xoryminor,  $xmax, $xoryminor, @lineattr,
                              -tags => [ $self.'minorgrid' ]);
         }
         $canv->createLine($xmin, $xoryminor,
                           $xmin+($tick*$tickratio), $xoryminor, @lineattr);
         createLineMetaPost($xmin, $xoryminor,
                            $xmin+($tick*$tickratio), $xoryminor, {@lineattr});
         unless($ri_style or $double_y) { # DOUBLE Y
            $canv->createLine($xmax, $xoryminor,
                              $xmax-($tick*$tickratio), $xoryminor, @lineattr);
            createLineMetaPost($xmax, $xoryminor,
                               $xmax-($tick*$tickratio), $xoryminor, {@lineattr});
         }
      }
      else { # DOUBLE Y
         if($minorgridlinedoit) {
            my @lineattr = (-width => $minorgridlinewidth,
                            -fill  => $minorgridlinecolor,
                            @minordash);
            $canv->createLine($xmin, $xoryminor,  $xmax, $xoryminor, @lineattr,
                              -tags => [ $self.'minorgrid' ]);
            createLineMetaPost($xmin, $xoryminor,  $xmax, $xoryminor, {@lineattr});
         }
         $canv->createLine($xmax, $xoryminor,
                           $xmax-($tick*$tickratio), $xoryminor, @lineattr);
         createLineMetaPost($xmax, $xoryminor,
                            $xmax-($tick*$tickratio), $xoryminor, {@lineattr});
      }
   } # END DRAW THE MINOR TICKS



   # ADDITION AND SPECIAL MAJOR TICKS AND LABELING
   @majortick  = (ref $specmajor) ? @{$specmajor} : ();
   @majorlabel = (ref $specmajor) ? @{$specmajor} : ();
   foreach (@majorlabel) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix
   foreach (@majortick ) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix
   foreach my $i (0..$#majortick) {
       $xory = $majortick[$i]; 
       next if($xory <= 0 or $xory >= 1);
       $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $xory); 
       next if(not defined $xory);
       $xory = &revAxis($self, $which,$xory) if($rev);      
       $xory = &revAxis($self, $which,$xory) if($invertprob); 
       if($which eq '-x') {
          unless($ri_style) {
             $canv->createLine($xory, $ymin,
                               $xory, $ymin+($tick*$spectickratio), @lineattr);
             createLineMetaPost($xory, $ymin,
                                $xory, $ymin+($tick*$spectickratio), {@lineattr});
          }
          $canv->createLine($xory, $ymax,
                            $xory, $ymax - ($tick*$spectickratio), @lineattr);
          createLineMetaPost($xory, $ymax,
                             $xory, $ymax - ($tick*$spectickratio), {@lineattr});
       }
       elsif($which eq '-y') {
          $canv->createLine($xmin,                        $xory,
                            $xmin+($tick*$spectickratio), $xory, @lineattr);
          createLineMetaPost($xmin,                        $xory,
                             $xmin+($tick*$spectickratio), $xory, {@lineattr});
          unless($ri_style or $double_y) {  # DOUBLE Y  
             $canv->createLine($xmax, $xory,
                               $xmax-($tick*$spectickratio), $xory, @lineattr);
             createLineMetaPost($xmax, $xory,
                                $xmax-($tick*$spectickratio), $xory, {@lineattr});
          }
       }
       else { # DOUBLE Y
          $canv->createLine($xmax, $xory,
                            $xmax-($tick*$spectickratio), $xory, @lineattr);
          createLineMetaPost($xmax, $xory,
                             $xmax-($tick*$spectickratio), $xory, {@lineattr});
       }
       my $text = $majorlabel[$i];   
       $text = 100 - $text if($invertprob);        
       $text = sprintf("$format", $text) unless($numformat eq 'free');
       $text = &commify($text) if($numcommify);
       $text =~ s/(.)/$1\n/g   if($stackit);
       unless($hidden) { 
         if($which eq '-x') {
           if($dblabel) {
             &_drawTextonTop($canv,$xory,$ymin,$text,@textattr);
             &_drawTextonBottom($canv,$xory,$ymax,$text,@textattr);
           }
           elsif($location eq 'bottom') {
             &_drawTextonBottom($canv,$xory,$ymax,$text,@textattr);
           }
           elsif($location eq 'top') {
             &_drawTextonTop($canv,$xory,$ymin,$text,@textattr);
           }
           else {
             die "Bad location '$location' call on probability label\n";
           }              
         }
         elsif($which eq '-y') {
           if($dblabel and not $double_y) { # DOUBLE Y
             &_drawTextonLeft($canv,$xmin,$xory,$text,@textattr);
             &_drawTextonRight($canv,$xmax,$xory,$text,@textattr);
           }
           elsif($location eq 'left' or $double_y) { # DOUBLE Y
             &_drawTextonLeft($canv,$xmin,$xory,$text,@textattr);
           }
           elsif($location eq 'right' and not $double_y) { # DOUBLE Y
             &_drawTextonRight($canv,$xmax,$xory,$text,@textattr);
           }
           else {
             die "Bad location '$location' call on probability label\n";
           }
         } 
         else { # DOUBLE Y
            &_drawTextonRight($canv,$xmax,$xory,$text,@textattr);
         }                 
       }   
   }  # END EXTRA MAJOR TICK DRAWING AND LABELING 

   # ADDITION AND SPECIAL MINOR TICKS
   my @minortick  = (ref $specminor) ? @{$specminor} : ();
   foreach (@minortick) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix
   foreach my $i (0..$#minortick) {
       next if($xory <= 0 or $xory >= 1);
       $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $minortick[$i]); 
       next if(not defined $xory);
       $xory = &revAxis($self, $which, $xory) if($rev);      
       $xory = &revAxis($self, $which, $xory) if($invertprob); 
       if($which eq '-x') {
          unless($ri_style) {
             $canv->createLine($xory, $ymin,
                               $xory, $ymin+($tick*$tickratio/1.66), @lineattr);
             createLineMetaPost($xory, $ymin,
                                $xory, $ymin+($tick*$tickratio/1.66), {@lineattr});
          }
          $canv->createLine($xory, $ymax,
                            $xory, $ymax-($tick*$tickratio/1.66), @lineattr);
          createLineMetaPost($xory, $ymax,
                             $xory, $ymax-($tick*$tickratio/1.66), {@lineattr});
       }
       elsif($which eq '-y') {
          $canv->createLine($xmin, $xory,
                            $xmin + ($tick*$tickratio/1.66), $xory, @lineattr);
          createLineMetaPost($xmin, $xory,
                             $xmin + ($tick*$tickratio/1.66), $xory, {@lineattr});
          unless($ri_style or $double_y) { # DOUBLE Y
             $canv->createLine($xmax, $xory,
                               $xmax-($tick*$tickratio/1.66), $xory, @lineattr);
             createLineMetaPost($xmax, $xory,
                                $xmax-($tick*$tickratio/1.66), $xory, {@lineattr});
          }
       }
       else { # DOUBLE Y
            $canv->createLine($xmax, $xory,
                              $xmax-($tick*$tickratio/1.66), $xory, @lineattr);
            createLineMetaPost($xmax, $xory,
                               $xmax-($tick*$tickratio/1.66), $xory, {@lineattr});
       }

   }  # END EXTRA MAJOR TICK DRAWING AND LABELING 
   
   my @dash = ();
   push(@dash, (-dash => $self->{-borderdashstyle}) )
              if($self->{-borderdashstyle} and
                 $self->{-borderdashstyle} !~ /Solid/io);
   my @axisattr = ( -width => $self->{-borderwidth},
                    -fill  => $self->{-bordercolor}, @dash );
   if($which eq '-x') {
      $canv->createLine($xmin, $ymin, $xmax, $ymin, @axisattr,
                        -tags  => "$self"."xaxis");   
      $canv->createLine($xmin, $ymax, $xmax, $ymax, @axisattr,
                        -tags  => "$self"."xaxis");                        
      createLineMetaPost($xmin, $ymin, $xmax, $ymin, {@axisattr});
      createLineMetaPost($xmin, $ymax, $xmax, $ymax, {@axisattr});
   }
   elsif($which eq '-y') {  
      $canv->createLine($xmin, $ymin, $xmin, $ymax, @axisattr,
                        -tags  => "$self"."yaxis1");
      createLineMetaPost($xmin, $ymin, $xmin, $ymax, {@axisattr});
      unless($double_y) { # DOUBLE Y
         $canv->createLine($xmax, $ymin, $xmax, $ymax, @axisattr,
                           -tags  => "$self"."yaxis1");     
         createLineMetaPost($xmax, $ymin, $xmax, $ymax, {@axisattr});
      }
   }
   else { # DOUBLE Y 
     $canv->createLine($xmax, $ymin, $xmax, $ymax, @axisattr,
                       -tags  => "$self"."yaxis2");      
     createLineMetaPost($xmax, $ymin, $xmax, $ymax, {@axisattr});
   }
   $canv->fontDelete($self."$which"."numfont");
}

1;
