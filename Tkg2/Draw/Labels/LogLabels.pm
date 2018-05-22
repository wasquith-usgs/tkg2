package Tkg2::Draw::Labels::LogLabels;

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
# $Date: 2016/02/29 17:12:27 $
# $Revision: 1.41 $

use strict;

use Tkg2::Math::GraphTransform qw(transReal2CanvasGLOBALS revAxis);

use Tkg2::Base qw(Message commify log10 Show_Me_Internals deleteFontCache);
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
@EXPORT_OK = qw(LogLabels);


print $::SPLASH "=";

sub LogLabels {   
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $canv, $which) = @_;  
   my $double_y = $self->{-y2}->{-turned_on};  # DOUBLE Y
   return if($which eq '-y2' and not $double_y); # DOUBLE Y
   my ($xory, $i, $text);
   my $format = "";                   
   my $type   = 'log';
   my (@majortick, @majorlabel, @minor);
   
   return unless(&_testLimits($self,$which));
   my ($xmin, $ymin, $xmax, $ymax) = $self->getPlotLimits;
   $self->setGLOBALS($which); # DOUBLE Y

   my $ref = $self->{$which};
   my $rev              = $ref->{-reverse};
   my $location         = $ref->{-location};   
   my $dblabel          = $ref->{-doublelabel};
   my $hidden           = $ref->{-hideit};
   my $blankit          = $ref->{-blankit};
   my $blankcolor       = $ref->{-blankcolor};
   my $automin          = $ref->{-autominlimit};
   my $automax          = $ref->{-automaxlimit};
   my $numoffset        = $ref->{-numoffset};
   my $numcommify       = $ref->{-numcommify};
   my $numformat        = $ref->{-numformat};
   my $numdecimal       = $ref->{-numdecimal};
   my $majorstep        = $ref->{-majorstep};
   my $min              = $ref->{-min};
   my $max              = $ref->{-max};
   my ($logmin, $logmax) = (log10($min), log10($max));
   my $labskip          = $ref->{-labskip};
   my $labeleqn         = $ref->{-labelequation};
   my $basemajor        = $ref->{-basemajor};
   my $basemajortolabel = $ref->{-basemajortolabel};
   my $baseminor        = $ref->{-baseminor};
   my $specmajor        = $ref->{-major};
   my $specminor        = $ref->{-minor};
   my $tick             = $ref->{-ticklength};
   my $tickwidth        = $ref->{-tickwidth};
   my $spectickratio    = $ref->{-spectickratio};
   my $tickratio        = $ref->{-tickratio};
   
   if($ref->{-usesimplelog}) {
     my $range = $logmax - $logmin;
     if($range >= 7) {
        $basemajor        = [ qw(1 5) ];
        $basemajortolabel = [ qw(1) ]; 
        $baseminor        = [ ]; 
     }
     elsif($range >= 5) {
        $basemajor        = [ qw(1 2 4 6 8) ];
        $basemajortolabel = [ qw(1) ]; 
        $baseminor        = [ ];
     }
     else {
        $basemajor        = [ qw(1 2 3 4 5 6 7 8 9) ];
        $basemajortolabel = [ qw(1) ]; 
        $baseminor        = [ ];   
     }
   }
   
   
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

   # PERL5.8 BUG FIX, wrap "" around $logrules to keep weird addition
   # and subtraction of the integer of the logoffset from randomly? occurring
   my $logoffset = $ref->{-logoffset};
      $logoffset = 0 unless( defined $logoffset); # backward compatability trap
      $logoffset = "$logoffset"; # PERL5.8 CORRECTION
   
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

      $gref = $ref->{-gridminor};   
   my $minorgridlinedoit  = $gref->{-doit};
   my $minorgridlinewidth = $gref->{-linewidth};
   my $minorgridlinecolor = $gref->{-linecolor};
   my $minorgriddashstyle = $gref->{-dashstyle};

   $basemajor        = [ @{$::TKG2_CONFIG{-LOG_BASE_MAJOR_TICKS}} ] 
                       if(not @$basemajor);
   $basemajortolabel = [ @{$::TKG2_CONFIG{-LOG_BASE_MAJOR_LABEL}} ]
                       if(not @$basemajortolabel);
   
   my $skip = 0;   
   my $tmpval;

   # Error trapping on Perl5.8 and greater?????  All sorts of hoops
   # in tkg2 have been created for previous trapping, but some 'bug'
   # has popped up in Perl5.8 distributions?
   if(not defined $logmin) {
       my $string = "Tkg2: SERIOUS WARNING--LogLabels: log of ".
                    "min $min does not exist--axis will be strange looking\n";
       print $::MESSAGE $string;  print STDERR $string;
   }
   if(not defined $logmax) {
       my $string = "Tkg2: SERIOUS WARNING--LogLabels: log of ".
                    "max $max does not exist--axis will be strange looking\n";
       print $::MESSAGE $string;  print STDERR $string;
   }

   if(defined $logmin and defined $logmax) { # fresh error trapping for Perl 5.8?
     my ($int_logmin, $int_logmax) = (int($logmin), int($logmax));
     foreach my $order (($int_logmin-1)..$int_logmax) {
        foreach my $base (@{$basemajor}) {
           my $majortick = (10**$order)*$base;
           next if($majortick < $min or $majortick > $max );
           $tmpval = $majortick;
           push(@majortick, $tmpval );
        }  
        foreach my $base (@{$basemajortolabel}) {
           my $majortick = (10**$order)*$base;
           next if($majortick < $min or $majortick > $max );
           $tmpval = $majortick;
           push(@majorlabel, $tmpval );
        } 
        foreach my $base (@{$baseminor}) {
           my $minortick = (10**$order)*$base;
           next if($minortick < $min  or $minortick > $max );
           $tmpval = $minortick;
           push(@minor, $tmpval );
        }              
     } 
   }

   # if the range is smaller than the basemajor steps etc.
   # then the label array is empty so a check on definition
   # is needed first BEFORE we have to figureout whether to 
   # add the axis limit to the axis.  However, when the range
   # is too small we still must force the limits on -- hence
   # the "else's" on the four conditionals below.
   if(defined $majorlabel[$#majorlabel]) {
     unless($majorlabel[$#majorlabel] eq $max or
            $majorlabel[$#majorlabel] == $max) {
        $tmpval = $max;
        push(@majorlabel, $tmpval ) if($labelmax);
     }
   }
   else {
       push(@majorlabel, $max ) if($labelmax);
   }

   if(defined $majortick[$#majortick]) {
     unless($majortick[$#majortick] eq $max or
            $majortick[$#majortick] == $max) {
        $tmpval = $max;
        push(@majortick,  $tmpval );   
     }
   }
   else {
        push(@majortick,  $max );
   }

   if(defined $majorlabel[0]) {
     unless($majorlabel[0] eq $min or
            $majorlabel[0] == $min) {
        $tmpval = $min;
        unshift(@majorlabel, $tmpval ) if($labelmin);     
     }
   }
   else {
        unshift(@majorlabel, $min ) if($labelmin);     
   }

   if(defined $majortick[0]) {
     unless($majortick[0] eq $min or
            $majortick[0] == $min) {
        $tmpval = $min;
        unshift(@majortick,  $tmpval );
     }
   }
   else {
        unshift(@majortick,  $min );
   }
   
   unless($numformat eq 'free') {
      FORMAT: {
         $format = "%0.$numdecimal"."e", last FORMAT if($numformat eq 'sci');
         $format = "%0.$numdecimal"."f", last FORMAT if($numformat eq 'fixed');
         $format = "%0.$numdecimal"."g", last FORMAT if($numformat eq 'sig');
      }
   }  
 
   my @lineattr = ( -width => $tickwidth, -fill => $linecolor );
   # The inclusion of $which on the tag is to keep blanking from
   # conflicting with other axis labels--bug fix for 0.80.  
   my @textattr = ( "$self"."$which", $numoffset, $numfont,
                             $numcolor, $blankit, $blankcolor, $numrotation, $fref );
   my $_drawTicks =
      sub { my ($xory, $realtick, $gridlinedoit,
                $gridlinewidth, $gridlinecolor, $griddashstyle,
                $index,$edge,$majORmin,$real_xory) = @_;
            my @dash = ( -dash => $griddashstyle ) 
                       if($griddashstyle and
                          $griddashstyle !~ /Solid/io);
            if($which eq '-x') {
               if($gridlinedoit) {
                  if(($real_xory eq $actualmin or
                      $real_xory eq $actualmax) and not $gridminmax) {
                     # do nothing for now
                  }
                  else {
                     my @lineattr = (-width => $gridlinewidth,
                                     -fill  => $gridlinecolor,
                                     @dash);
                     $canv->createLine($xory, $ymin, $xory, $ymax, @lineattr,
                                       -tags  => [ $majORmin ]);
                     createLineMetaPost($xory, $ymin, $xory, $ymax, {@lineattr});
                  }
               }
               $canv->createLine($xory, $ymin,
                                 $xory, $ymin + $realtick, @lineattr);
               $canv->createLine($xory, $ymax,
                                 $xory, $ymax - $realtick, @lineattr);
               createLineMetaPost($xory, $ymin,
                                 $xory, $ymin + $realtick, {@lineattr});
               createLineMetaPost($xory, $ymax,
                                  $xory, $ymax - $realtick, {@lineattr});
            }
            elsif($which eq '-y') {
               if($gridlinedoit) {
                  if(($real_xory eq $actualmin or
                      $real_xory eq $actualmax) and not $gridminmax) {
                     # do nothing for now
                  }
                  else {
                     my @lineattr = (-width => $gridlinewidth,
                                     -fill  => $gridlinecolor,
                                     @dash);
                     $canv->createLine($xmin, $xory, $xmax, $xory, @lineattr,
                                       -tags  => [ $majORmin ]);
                     createLineMetaPost($xmin, $xory, $xmax, $xory, {@lineattr});
                  }
               }
               $canv->createLine($xmin, $xory,
                                 $xmin + $realtick, $xory, @lineattr);
               createLineMetaPost($xmin, $xory,
                                  $xmin + $realtick, $xory, {@lineattr});
               unless($double_y) {  # DOUBLE Y
                  $canv->createLine($xmax, $xory,
                                    $xmax - $realtick, $xory, @lineattr);
                  createLineMetaPost($xmax, $xory,
                                     $xmax - $realtick, $xory, {@lineattr});
               }
            }
            else {  # DOUBLE Y
               if($gridlinedoit) {
                  if(($real_xory eq $actualmin or
                      $real_xory eq $actualmax) and not $gridminmax) {
                     # do nothing for now
                  }
                  else {
                      my @lineattr = (-width => $gridlinewidth,
                                      -fill  => $gridlinecolor,
                                      @dash);
                      $canv->createLine($xmin, $xory, $xmax, $xory, @lineattr,
                                        -tags  => [ $majORmin ]);
                      createLineMetaPost($xmin, $xory, $xmax, $xory, {@lineattr});
                  }
               }
               $canv->createLine($xmax, $xory,
                                 $xmax - $realtick, $xory, @lineattr);    
               createLineMetaPost($xmax, $xory,
                                  $xmax - $realtick, $xory, {@lineattr});
            }
          };
 
 
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
      my $real_xory = $xory  = $majortick[$i];
      next if($xory <= 0);
      my $test4even = log10($xory);
      my $iseven    = ($test4even eq int("$test4even") ) ? 1 : 0;
      my $realtick  = ($iseven) ? $tick + $tick*0.4 : $tick;
      $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $xory+$logoffset); 
      next if(not defined $xory);
      $xory = &revAxis($self, $which,$xory) if($rev);
      my $tmpwidth;
      if($iseven) {
         ($tmpwidth) = $majorgridlinewidth =~ m/(.+)i/o;
         $tmpwidth += 0.005;
         $tmpwidth .= "i";
      }
      else {
         $tmpwidth = $majorgridlinewidth;
      }     
      &$_drawTicks($xory, $realtick,
                   $majorgridlinedoit,  $tmpwidth,
                   $majorgridlinecolor, $majorgriddashstyle,
                   $i, $#majortick, "$self"."majorgrid", $real_xory);
   }
   
      
   # DRAW THE DESIRED MAJOR LABELS
   push(@majorlabel, ($min2beglab)) if($min2beglab ne "");
   push(@majorlabel, ($max2endlab)) if($max2endlab ne "");
   foreach (@majorlabel) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix
   foreach my $i (0..$#majorlabel) {
     my $xory  = $majorlabel[$i];
     next if($min2beglab ne "" and $xory < $min2beglab);
     next if($max2endlab ne "" and $xory > $max2endlab);
     next if($xory <= 0);
     $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $xory+$logoffset); 
     next if(not defined $xory);
     $xory = &revAxis($self, $which,$xory) if($rev);           

     $text  =  $majorlabel[$i]+$logoffset;
      
     $text = sprintf("$format", $text) unless($numformat eq 'free');
     my ($text1, $text2) = &_buildLabel($text, $labeleqn,
                                         $numcommify, $stackit);
 
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
           die "Bad location '$location' call on log label\n";
         }              
       }
       elsif($which eq '-y') {
         if($dblabel and not $double_y) { # DOUBLE Y
           &_drawTextonLeft($canv,$xmin,$xory,$text1,@textattr);
           &_drawTextonRight($canv,$xmax,$xory,$text2,@textattr);
         }
         elsif($location eq 'left' or $double_y) { # DOUBLE Y
           &_drawTextonLeft($canv,$xmin,$xory,$text1,@textattr);
         }
         elsif($location eq 'right' and not $double_y) { # DOUBLE Y
           &_drawTextonRight($canv,$xmax,$xory,$text1,@textattr);
         }
         else {
             die "Bad location '$location' call on log label\n";
         }
       }   
       else { # DOUBLE Y
          &_drawTextonRight($canv,$xmax,$xory,$text1,@textattr);
       }
     }
   }

   # DRAW THE DESIRED MINOR TICKS
   foreach my $i (0..$#minor) {
      my $real_xory = $minor[$i];
      my $xoryminor = $real_xory;
      
      next if($xoryminor <= 0);
      $xoryminor  = &transReal2CanvasGLOBALS($self, $which, $type,
                                                 1, $xoryminor+$logoffset); 
      next if(not defined $xoryminor);
      $xoryminor  = &revAxis($self, $which,$xoryminor) if($rev);      
      &$_drawTicks($xoryminor, ($tick*$tickratio),
                   $minorgridlinedoit,  $minorgridlinewidth,
                   $minorgridlinecolor, $minorgriddashstyle,
                   -1, 1, "$self"."minorgrid",$real_xory);
   } # END DRAW THE MINOR TICKS



   # ADDITION AND SPECIAL MAJOR TICKS AND LABELING
   @majortick  = (ref $specmajor) ? @{$specmajor} : () ;
   @majorlabel = (ref $specmajor) ? @{$specmajor} : () ;
   foreach (@majorlabel) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix
   foreach (@majortick ) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix
   foreach my $i (0..$#majortick) {
      my $real_xory = $majortick[$i]; 
      my $xory  = $real_xory; 
      my $text  = $xory + $logoffset;
      next if($xory <= 0);   
      $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $xory + $logoffset); 
      next if(not defined $xory);
      $xory = &revAxis($self, $which,$xory) if($rev);      
      &$_drawTicks($xory,($tick*$spectickratio),0,0,0,0,0,0,'none',$real_xory);
 
      $text = sprintf("$format", $text) unless($numformat eq 'free');
      my ($text1, $text2) = &_buildLabel($text, $labeleqn,
                                         $numcommify, $stackit);
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
              die "Bad location '$location' call on log label\n";
           }              
        }
        elsif($which eq '-y') {
           if($dblabel and not $double_y) { # DOUBLE Y
              &_drawTextonLeft($canv,$xmin,$xory,$text1,@textattr);
              &_drawTextonRight($canv,$xmax,$xory,$text2,@textattr);
           }
           elsif($location eq 'left' or $double_y) { # DOUBLE Y
              &_drawTextonLeft($canv,$xmin,$xory,$text1,@textattr);
           }
           elsif($location eq 'right' and not $double_y) { # DOUBLE Y
              &_drawTextonRight($canv,$xmax,$xory,$text1,@textattr);
           }
           else {
              die "Bad location '$location' call on log label\n";
           }
        } 
        else { # DOUBLE Y
           &_drawTextonRight($canv,$xmax,$xory,$text1,@textattr);
        }                 
     }   
   }  # END SPECIAL MAJOR TICK DRAWING AND LABELING 

   # ADDITION AND SPECIAL MINOR TICKS
   my @minortick = (ref $specminor) ? @{$specminor} : ();
   foreach (@minortick) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix
   foreach my $i (0..$#minortick) {
       my $real_xory = $minortick[$i];
       my $xory  = $real_xory;
       next if($xory <= 0);
       $xory = &transReal2CanvasGLOBALS($self, $which, $type,
                                            1, $minortick[$i]+$logoffset); 
       next if(not defined $xory);
       $xory = &revAxis($self, $which,$xory) if($rev);      
       &$_drawTicks($xory,($tick*$tickratio/1.66),0,0,0,0,0,0,'none',$real_xory);

   }  # END SPECIAL MINOR TICKS


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
