package Tkg2::Draw::Labels::LinearLabels;

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
# $Date: 2010/11/09 16:02:18 $
# $Revision: 1.38 $

use strict;

use Tkg2::Math::GraphTransform qw(transReal2CanvasGLOBALS revAxis);

use Tkg2::Base qw(Message commify Show_Me_Internals deleteFontCache);
use Tkg2::Draw::Labels::LabelUtilities qw( _drawTextonBottom 
                                           _drawTextonTop
                                           _drawTextonLeft
                                           _drawTextonRight
                                           _testLimits
                                           _buildLabel
                                         );

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createLineMetaPost);

use Exporter;
use vars     qw(@ISA @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT_OK = qw(LinearLabels);

print $::SPLASH "=";

#
# LINEAR LABELS
#
sub LinearLabels {   
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $canv, $which) = (shift, shift, shift);  
   my ($xory, $forwardxory, $i, $text);
   my $double_y = $self->{-y2}->{-turned_on};  # DOUBLE Y, is it turned on
   return if($which eq '-y2' and not $double_y); # DOUBLE Y
   
   my $type = 'linear';
   my $format = "";                   
   my (@majortick, @majorlabel, @minortick);
   my ($step, $minorstep);
   
   my $deBUG = $::TKG2_CONFIG{-DEBUG};
   
   return unless(&_testLimits($self,$which));
   my ($xmin, $ymin, $xmax, $ymax) = $self->getPlotLimits;
   $self->setGLOBALS($which);  # DOUBLE Y:
   my $ref           = $self->{$which};
   my $rev           = $ref->{-reverse};
   my $location      = $ref->{-location};
   my $dblabel       = $ref->{-doublelabel};
   my $hidden        = $ref->{-hideit};
   my $blankit       = $ref->{-blankit};
   my $blankcolor    = $ref->{-blankcolor};
   my $automin       = $ref->{-autominlimit};
   my $automax       = $ref->{-automaxlimit};
   my $numoffset     = $ref->{-numoffset};
   my $numcommify    = $ref->{-numcommify};
   my $numformat     = $ref->{-numformat};
   my $numdecimal    = $ref->{-numdecimal};
   my $majorstep     = $ref->{-majorstep};
   my $numminor      = $ref->{-numminor};
   my $min           = $ref->{-min};
   my $max           = $ref->{-max};
   my $labskip       = $ref->{-labskip};
   my $labeleqn      = $ref->{-labelequation};
   my $specmajor     = $ref->{-major};
   my $specminor     = $ref->{-minor};
   my $tick          = $ref->{-ticklength};
   my $tickwidth     = $ref->{-tickwidth};
   my $spectickratio = $ref->{-spectickratio};
   my $tickratio     = $ref->{-tickratio};
   
  
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
  
   my $fref    = $ref->{-numfont};
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
   my $numcolor  = $fref->{-color};
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
      
   # BUILD UP THE MAJOR AND MINOR TICK AND MAJOR LABEL ARRAYS
   # labels up from 0 until the max is passed
   # and then down from 0 until the minimum is passed
   # insures that 0 lies on a major tick
   my $tmpval = 0;
   my $skip   = $labskip;  
   my $minorinterval = $majorstep/($numminor+1);
   # if the minimum is greater than zero, then we can
   # will jump to just shy of the minimum, set the tmpval
   # and then begin the incrementing with the while loop
   if($min > 0) {
      $tmpval = (int($min/$majorstep)-2)*$majorstep;
   }
   while(1) {
      last if($tmpval > $max);
      if($tmpval > $min) {
         push(@majortick,  $tmpval);
         if($skip == $labskip) {
            push(@majorlabel, $tmpval);
            $skip = 0; 
         }
         else {
            $skip++;
         }
      }
      if($numminor > 0) { # buildup the minors
         foreach (1..$numminor) {
            my $tick = $tmpval+$_*$minorinterval;
            #print "NWISBUG: tick=$tick\n";
            push(@minortick, $tick) if($min < $tick and $tick < $max ); 
         }
      }
      $tmpval += $majorstep;
      # force into string context to keep .9999999 etc from growing
      #$tmpval  = "$tmpval"; # PERL5.8 CORRECTION
   }
   
   # if the tick and label arrays are defined then we can presumably
   # treate them by taking off values beyond our limits and pushing
   # the maximum values onto them
   # this can occur when the steplength is greater than the difference
   # between 0 and the maximum value
   pop(@majorlabel ) if( defined $majorlabel[$#majorlabel] and
                               ( $majorlabel[$#majorlabel] >= $max or
                                 $majorlabel[$#majorlabel] eq $max ) );
                           
   pop(@majortick  ) if( defined $majortick[$#majortick] and
                                 $majortick[$#majortick] > $max );
                                 
   # now only place the max on the end of the array if it isn't already there
   if(@majorlabel) {
      push(@majorlabel, $max) unless($majorlabel[$#majorlabel] eq $max or
                                     $majorlabel[$#majorlabel] == $max or
                                     not $labelmax );
   }
   else {
      push(@majorlabel, $max) if($labelmax);
   }
   
   if(@majortick) {
      push(@majortick,  $max) unless($majortick[$#majortick] eq $max or
                                     $majortick[$#majortick] == $max );
   }
   
   # down from 0
   $tmpval = 0;
   $skip   = $labskip;
   # if the maximum is less than zero, then we can
   # will jump to just above the maximum, set the tmpval
   # and then begin the incrementing with the while loop
   if($max < 0) {
      $tmpval = (int($max/$majorstep)+2)*$majorstep;
   }
   while(1) {
      last if($tmpval < $min);
      if($tmpval < $max) {
         unshift(@majortick,  $tmpval);
         if($skip == $labskip) {
            unshift(@majorlabel, $tmpval);
            $skip = 0; 
         }
         else {
            $skip++;
         }
      }
      if($numminor > 0) { # buildup the minors
         foreach (1..$numminor) {
            my $tick = $tmpval-$_*$minorinterval;
            unshift(@minortick, $tick) if($min < $tick and $tick < $max);
         }
      }
      $tmpval -= $majorstep;
      # force into string context to keep .9999999 etc from growing
      #$tmpval  = "$tmpval"; # PERL5.8 CORRECTION
   }
   
   
   shift(@majorlabel ) if( defined $majorlabel[0] and
                                 ( $majorlabel[0] <= $min or
                                   $majorlabel[0] eq $min ) );
                            
   shift(@majortick  ) if( defined $majortick[0]  and
                                   $majortick[0]  <   $min );
   # now only place the min on the end of the array if it isn't already there
   if(@majortick) {
      unshift(@majortick,  $min) unless( $majortick[0] eq $min or
                                         $majortick[0] == $min );
   }
   
   if(@majorlabel) {
      unshift(@majorlabel, $min) unless( $majorlabel[0] eq $min or
                                         $majorlabel[0] == $min or
                                         not $labelmin );
   }
   else {
      unshift(@majorlabel, $min) if(not $labelmin);
   }

   unless($numformat eq 'free') {
      FORMAT: {
         $format = "%0.$numdecimal"."e", last FORMAT if($numformat eq 'sci');
         $format = "%0.$numdecimal"."f", last FORMAT if($numformat eq 'fixed');
         $format = "%0.$numdecimal"."g", last FORMAT if($numformat eq 'sig');
      }
   }

   my @lineattr = (-width => $tickwidth, -fill => $linecolor);
   # The inclusion of $which on the tag is to keep blanking from
   # conflicting with other axis labels--bug fix for 0.80.  
   my @textattr = ("$self"."$which", $numoffset, $numfont, $numcolor,
                            $blankit, $blankcolor, $numrotation, $fref);
   # The $fref MUST BE popped off the end of the @_ in the _drawTexton????? functions   
   
   
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
   foreach (@majortick ) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, proven fix
   foreach (@minortick ) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, proven fix

   
   # DRAW THE MAJOR TICKS
   foreach my $i (0..$#majortick) {
      my $real_xory = $xory = $majortick[$i];
      $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $xory);  
      next if(not defined $xory);
      $xory = &revAxis($self, $which, $xory) if($rev);   
      if($which eq '-x') {
         if($majorgridlinedoit) {
            if(($real_xory eq $actualmin or
                $real_xory eq $actualmax) and not $gridminmax) {
               # do nothing for now
            }
            else {
               my @lineattr = (-width => $majorgridlinewidth,
                               -fill  => $majorgridlinecolor,
                               @majordash,
                               -tags  => ["$self"."majorgrid"]);
               $canv->createLine($xory, $ymin, $xory, $ymax, @lineattr);
               createLineMetaPost($xory, $ymin, $xory, $ymax, {@lineattr});
            }
         }
         $canv->createLine($xory, $ymin, $xory, $ymin + $tick, @lineattr);
         $canv->createLine($xory, $ymax, $xory, $ymax - $tick, @lineattr);
         createLineMetaPost($xory, $ymin, $xory, $ymin + $tick, {@lineattr});
         createLineMetaPost($xory, $ymax, $xory, $ymax - $tick, {@lineattr});
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
                               @majordash,
                               -tags  => ["$self"."majorgrid"]);
               $canv->createLine($xmin, $xory, $xmax, $xory, @lineattr);
               createLineMetaPost($xmin, $xory, $xmax, $xory, {@lineattr});
            }
         }
         $canv->createLine($xmin, $xory, $xmin + $tick, $xory, @lineattr);
         createLineMetaPost($xmin, $xory, $xmin + $tick, $xory, {@lineattr});
         unless($double_y) { # DOUBLE Y
            $canv->createLine($xmax, $xory, $xmax - $tick, $xory, @lineattr);
            createLineMetaPost($xmax, $xory, $xmax - $tick, $xory, {@lineattr});
         }
      }  
      else { # DOUBLE Y
         if($majorgridlinedoit) {
            if(($real_xory eq $actualmin or
                $real_xory eq $actualmax) and not $gridminmax) {
               # do nothing for now
            }
            else {
               my @lineattr = (-width => $majorgridlinewidth,
                               -fill  => $majorgridlinecolor,
                               @majordash,
                               -tags  => ["$self"."majorgrid"]);
               $canv->createLine($xmin, $xory, $xmax, $xory, @lineattr);
               createLineMetaPost($xmin, $xory, $xmax, $xory, {@lineattr});
            }
         }
         $canv->createLine($xmax, $xory, $xmax - $tick, $xory, @lineattr);
         createLineMetaPost($xmax, $xory, $xmax - $tick, $xory, {@lineattr});
      }  
      last if($i == $#majortick);
   }
   
   
   # DRAW THE MINOR TICKS
   foreach my $i (0..$#minortick) {   
      $xory = $minortick[$i];
      $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $xory);
      next if( not defined $xory);
      $xory = &revAxis($self, $which, $xory) if($rev);       
     
      if($which eq '-x') {
         if($minorgridlinedoit) {
            my @lineattr = (-width => $minorgridlinewidth,
                            -fill  => $minorgridlinecolor,
                            @minordash,
                            -tags  => ["$self"."minorgrid"]);
            $canv->createLine($xory, $ymin, $xory, $ymax, @lineattr);
            createLineMetaPost($xory, $ymin, $xory, $ymax, {@lineattr});
         }
         my $tmp = ($tick*$tickratio);
         $canv->createLine($xory, $ymin, $xory, $ymin + $tmp, @lineattr);
         $canv->createLine($xory, $ymax, $xory, $ymax - $tmp, @lineattr);
         createLineMetaPost($xory, $ymin, $xory, $ymin + $tmp, {@lineattr});
         createLineMetaPost($xory, $ymax, $xory, $ymax - $tmp, {@lineattr});
      }
      elsif($which eq '-y') {
         if($minorgridlinedoit) {
            my @lineattr = (-width => $minorgridlinewidth,
                            -fill  => $minorgridlinecolor,
                            @minordash,
                            -tags  => ["$self"."minorgrid"]);
            $canv->createLine($xmin, $xory,  $xmax, $xory, @lineattr);
            createLineMetaPost($xmin, $xory,  $xmax, $xory, {@lineattr});
         }
         my $tmp = $xmin + ($tick*$tickratio);
         $canv->createLine($xmin, $xory, $tmp, $xory, @lineattr);
         createLineMetaPost($xmin, $xory, $tmp, $xory, {@lineattr});
         unless($double_y) { # DOUBLE Y
            my $tmp = $xmax - ($tick*$tickratio);
            $canv->createLine($xmax, $xory, $tmp, $xory, @lineattr);
            createLineMetaPost($xmax, $xory, $tmp, $xory, {@lineattr});
         }
     }           
     else {  # DOUBLE Y
         if($minorgridlinedoit) {
            my @lineattr = (-width => $minorgridlinewidth,
                            -fill  => $minorgridlinecolor,
                            @minordash,
                            -tags  => ["$self"."minorgrid"]);
            $canv->createLine($xmin, $xory,  $xmax, $xory, @lineattr);
            createLineMetaPost($xmin, $xory,  $xmax, $xory, {@lineattr});
         }
         my $tmp = $xmax - ($tick*$tickratio);     
         $canv->createLine($xmax, $xory, $tmp, $xory, @lineattr);
         createLineMetaPost($xmax,$xory, $tmp,$xory, {@lineattr});
     }
   }
   
   
   
   # DRAW THE DESIRED MAJOR LABELS
   push(@majorlabel, ($min2beglab)) if($min2beglab ne "");
   push(@majorlabel, ($max2endlab)) if($max2endlab ne "");
   foreach (@majorlabel) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix
   my $those_that_are_plotted = {}; # Hash ref to hold unique values
   foreach my $i (0..$#majorlabel) {
     $xory = $majorlabel[$i];

     # BUG FIX ON DOUBLE PLACE OF LABELS, EASIER TO FIX
     # HERE THAN UP IN THE MORE COMPLEX LOGIC, FIX 2008/04/28--wha
     # BUG FIX AGAIN 2008/09/03--wha
     $those_that_are_plotted->{$xory}++;
     next if($those_that_are_plotted->{$xory} > 1);
     # Notice that we use the raw values as the key and do not use
     # the nature of the users formatting of the actual labels. This is
     # actually an apparent feature so after formating (rounding) on the
     # drawn labels one seens duplicates, but they are in different places
     # as dictated by the floating point representation of the number


     next if($min2beglab ne "" and $xory < $min2beglab);
     next if($max2endlab ne "" and $xory > $max2endlab);
     $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $xory); 
     next if(not defined $xory);
     $xory = &revAxis($self, $which, $xory) if($rev);              

     my $text = $majorlabel[$i];
     $text = sprintf("$format", $text) unless($numformat eq 'free');
     my ($text1, $text2) =
              &_buildLabel($text, $labeleqn, $numcommify, $stackit);
          
     unless($hidden) {
       if($which eq '-x') {
         if($dblabel) {
           &_drawTextonBottom($canv,$xory,$ymax,$text1,@textattr);
           &_drawTextonTop($canv,$xory,$ymin,$text2,@textattr);
         }
         elsif($location eq 'bottom') {
           &_drawTextonBottom($canv,$xory,$ymax,$text1,@textattr);
         }
         elsif($location eq 'top') {
           &_drawTextonTop($canv,$xory,$ymin,$text1,@textattr);
         }
         else {
           die "Bad location '$location' call on linear label\n";
         }              
       }
       elsif($which eq '-y') {
         if($dblabel and not $double_y) {
           &_drawTextonLeft($canv,$xmin,$xory,$text1,@textattr);
           &_drawTextonRight($canv,$xmax,$xory,$text2,@textattr);
         }
         elsif($location eq 'left' or $double_y) {
           &_drawTextonLeft($canv,$xmin,$xory,$text1,@textattr);
         }
         elsif($location eq 'right' and not $double_y) {
           &_drawTextonRight($canv,$xmax,$xory,$text1,@textattr);
         }
         else {
             die "Bad location '$location' call on linear label\n";
         }
       }
       else {  # DOUBLE Y
         # by executive decision, wha has desided that when a double y axis
         # is being used that the labeling can only go on the right side
         &_drawTextonRight($canv,$xmax,$xory,$text1,@textattr);       
       }
     }   
   }


   # ADDITION AND SPECIAL MAJOR TICKS AND LABELING
   @majortick  = (ref $specmajor) ? @{$specmajor} : () ;
   @majorlabel = (ref $specmajor) ? @{$specmajor} : () ;
   foreach (@majorlabel) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix
   foreach (@majortick ) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix
   foreach my $i (0..$#majortick) {
       $xory = $majortick[$i]; 
       $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $xory); 
       next if(not defined $xory);
       $xory = &revAxis($self, $which, $xory) if($rev);          
      
       if($which eq '-x') {
          my $tmp = ($tick*$spectickratio);
          $canv->createLine($xory, $ymin,
                            $xory, $ymin + $tmp, @lineattr);
          $canv->createLine($xory, $ymax,
                            $xory, $ymax - $tmp, @lineattr);
          createLineMetaPost($xory,$ymin, $xory,$ymin+$tmp, {@lineattr});
          createLineMetaPost($xory,$ymax, $xory,$ymax-$tmp, {@lineattr}); 
       }
       elsif($which eq '-y') {
          my $tmp = $xmin+($tick*$spectickratio);
          $canv->createLine($xmin, $xory, $tmp, $xory, @lineattr);
          createLineMetaPost($xmin,$xory, $tmp,$xory, {@lineattr});
          unless($double_y) {   # DOUBLE Y
             my $tmp = $xmax - ($tick*$spectickratio);
             $canv->createLine($xmax, $xory, $tmp,$xory, @lineattr);
             createLineMetaPost($xmax,$xory, $tmp,$xory, {@lineattr});
          }
       }
       else {   # DOUBLE Y
          my $tmp = $xmax - ($tick*$spectickratio);
          $canv->createLine($xmax, $xory, $tmp, $xory, @lineattr);
          createLineMetaPost($xmax,$xory, $tmp,$xory, {@lineattr});
       }

       my $text = $majorlabel[$i];
       $text = sprintf("$format", $text) unless($numformat eq 'free');
       my ($text1, $text2) =
                &_buildLabel($text, $labeleqn, $numcommify, $stackit);

       unless($hidden) { 
         if($which eq '-x') {
           if($dblabel) {
             &_drawTextonBottom($canv,$xory,$ymax,$text1,@textattr);
             &_drawTextonTop($canv,$xory,$ymin,$text2,@textattr);
           }
           elsif($location eq 'bottom') {
             &_drawTextonBottom($canv,$xory,$ymax,$text1,@textattr);
           }
           elsif($location eq 'top') {
             &_drawTextonTop($canv,$xory,$ymin,$text1,@textattr);
           }
           else {
             die "Bad location '$location' call on linear label\n";
           }               
         }
         elsif($which eq '-y') { 
           if($dblabel and not $double_y) {  # DOUBLE Y
             &_drawTextonLeft($canv,$xmin,$xory,$text1,@textattr);
             &_drawTextonRight($canv,$xmax,$xory,$text2,@textattr);
           }
           elsif($location eq 'left' or $double_y) {  # DOUBLE Y
             &_drawTextonLeft($canv,$xmin,$xory,$text1,@textattr);
           }
           elsif($location eq 'right' and not $double_y) { # DOUBLE Y
             &_drawTextonRight($canv,$xmax,$xory,$text1,@textattr);
           }
           else {
               die "Bad location '$location' call on linear label\n";
           }
         }
         else { # DOUBLE Y
            &_drawTextonRight($canv,$xmax,$xory,$text1,@textattr);
         }                 
      }   
   }  # END EXTRA MAJOR TICK DRAWING AND LABELING 

   # ADDITION AND SPECIAL MINOR TICKS
   @minortick  = (ref $specminor) ? @{$specminor} : () ;
   foreach (@minortick) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix
   foreach my $i (0..$#minortick) {
       $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $minortick[$i]); 
       next if(not defined $xory);
       $xory = &revAxis($self, $which, $xory) if($rev);      
      
       if($which eq '-x') {
          my $tmp = ($tick*$tickratio/1.66);
          $canv->createLine($xory, $ymin,
                            $xory, $ymin + $tmp, @lineattr);
          $canv->createLine($xory, $ymax,
                            $xory, $ymax - $tmp, @lineattr);
          createLineMetaPost($xory,$ymin, $xory,$ymin+$tmp, {@lineattr});
          createLineMetaPost($xory,$ymax, $xory,$ymax-$tmp, {@lineattr});
       }
       elsif($which eq '-y') {
          my $tmp = $xmin+($tick*$tickratio/1.66);
          $canv->createLine($xmin, $xory,
                            $tmp, $xory, @lineattr);
          createLineMetaPost($xmin,$xory, $tmp,$xory, {@lineattr});
          unless($double_y) { # DOUBLE Y
             my $tmp = $xmax - ($tick*$tickratio/1.66);
             $canv->createLine($xmax, $xory,
                               $tmp, $xory, @lineattr);
             createLineMetaPost($xmax,$xory, $tmp,$xory, {@lineattr});
          }
       }
       else {  # DOUBLE Y
          my $tmp = $xmax - ($tick*$tickratio/1.66);
          $canv->createLine($xmax, $xory,
                            $tmp, $xory, @lineattr);
          createLineMetaPost($xmax,$xory, $tmp,$xory, {@lineattr});
       }
   }  # END EXTRA MAJOR TICK DRAWING AND LABELING 

   my @dash = ();
   push(@dash, (-dash => $self->{-borderdashstyle}) )
              if($self->{-borderdashstyle} and
                 $self->{-borderdashstyle} !~ /Solid/io);
   my @axisattr = ( -width => $self->{-borderwidth},
                    -fill  => $self->{-bordercolor}, @dash);
                    
   if($which eq '-x') {
      $canv->createLine($xmin, $ymin, $xmax, $ymin, @axisattr,
                        -tags  => "$self"."xaxis");   
      $canv->createLine($xmin, $ymax, $xmax, $ymax, @axisattr,
                        -tags  => "$self"."xaxis");

      createLineMetaPost($xmin,$ymin, $xmax,$ymin, {@axisattr});
      createLineMetaPost($xmin,$ymax, $xmax,$ymax, {@axisattr});
   }
   elsif($which eq '-y') {  
      $canv->createLine($xmin, $ymin, $xmin, $ymax, @axisattr,
                        -tags  => "$self"."yaxis1");
      createLineMetaPost($xmin,$ymin,$xmin,$ymax, {@axisattr});
      unless($double_y) {
         $canv->createLine($xmax, $ymin, $xmax, $ymax, @axisattr,
                           -tags  => "$self"."yaxis1");
         createLineMetaPost($xmax,$ymin, $xmax,$ymax, {@axisattr});
      }     
   }
   else {  # DOUBLE Y
      $canv->createLine($xmax, $ymin, $xmax, $ymax, @axisattr,
                        -tags  => "$self"."yaxis2");   
      createLineMetaPost($xmax,$ymin, $xmax,$ymax, {@axisattr});
   }
   $canv->fontDelete($self."$which"."numfont");
} 

1;
