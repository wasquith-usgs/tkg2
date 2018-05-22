package Tkg2::Draw::Labels::DiscreteLabels;

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
# $Revision: 1.25 $

use strict;

use Tkg2::Math::GraphTransform qw(transReal2CanvasGLOBALS revAxis);

use Tkg2::Base qw(Message Show_Me_Internals deleteFontCache);
use Tkg2::Draw::Labels::LabelUtilities qw( _drawTextonBottom 
                                           _drawTextonTop
                                           _drawTextonLeft
                                           _drawTextonRight
                                           _testLimits
                                         );

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createLineMetaPost);

use Exporter;
use SelfLoader;
use vars     qw(@ISA @EXPORT_OK);
@ISA       = qw(Exporter SelfLoader);
@EXPORT_OK = qw(DiscreteLabels);


print $::SPLASH "=";

1;
#__DATA__


sub DiscreteLabels {   
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $canv, $which) = (shift, shift, shift);  
   my $double_y = $self->{-y2}->{-turned_on};  # DOUBLE Y
   return if($which eq '-y2' and not $double_y); # DOUBLE Y

   my ($xory);
   my $type = 'linear';
   my (@majortick, @majorlabel);
   
   return unless(&_testLimits($self,$which));
   my ($xmin, $ymin, $xmax, $ymax) = $self->getPlotLimits;
   $self->setGLOBALS($which);  # DOUBLE Y
   my $ref          = $self->{$which};
   my $labelhash    = $ref->{-discrete}->{-labelhash};
   my $bracketgroup = ($ref->{-discrete}->{-bracketgroup}) ? 0 : 0.5;
   my %labelhash    = %$labelhash;
   my $location     = $ref->{-location};
   my $dblabel      = $ref->{-doublelabel};
   my $rev          = $ref->{-reverse};
   my $hidden       = $ref->{-hideit};
   my $blankit      = $ref->{-blankit};
   my $blankcolor   = $ref->{-blankcolor};
   my $numoffset    = $ref->{-numoffset};
   my $min          = $ref->{-min};
   my $max          = $ref->{-max};
   my $labskip      = $ref->{-labskip};
   my $tick         = $ref->{-ticklength};
   my $tickwidth    = $ref->{-tickwidth};
   
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

   # yes -bracketgroup 
   # =====|=====|=====|=====
   #     grp   dog   cat
   # no -bracketgroup
   # =====|=====|=====|=====
   #  grp   dog   cat
   # cool isn't it.  I stole the idea from a slide at a meeting
   # in Fort Collins, CO.
   foreach (keys %labelhash) {
      push(@majortick, $labelhash{$_} + $bracketgroup);
      push(@majorlabel, $_);
   }
   
   print STDERR "\@majortick and \@majorlabel are not same size\n"
            unless(@majortick == @majorlabel);
       
   my @index = sort { $majortick[$a] <=> $majortick[$b] } (0..$#majortick);   
   @majortick  = @majortick[@index];
   # we need to push the bracketgroup = 0.5 onto the tick array
   # so that at the 1st group a tick will sandwitch the label
   push(@majortick, $bracketgroup) if($bracketgroup);
   @majorlabel = @majorlabel[@index];   

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
   foreach (@majorlabel) { $_ = "$_"; } # NWIS4.10/Perl5.10 BUG FIX, inferred fix



   # DRAW THE MAJOR TICKS
   foreach my $i (0..$#majortick) {
      $xory = $majortick[$i];
      $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $xory);  
      next if(not defined $xory );
      $xory = &revAxis($self, $which, $xory) if($rev);   
          
      if($which eq '-x') {
         if($majorgridlinedoit and $i != 0 and $i != $#majortick) {
           my @lineattr = (-width => $majorgridlinewidth,
                           -fill  => $majorgridlinecolor,
                           @majordash); 
           $canv->createLine($xory, $ymin, $xory, $ymax, @lineattr,
                              -tags  => [ $self.'majorgrid' ]);
           createLineMetaPost($xory, $ymin, $xory, $ymax, {@lineattr});
         }
         $canv->createLine($xory, $ymin,
                           $xory, $ymin + $tick, @lineattr);
         $canv->createLine($xory, $ymax,
                           $xory, $ymax - $tick, @lineattr);
         createLineMetaPost($xory, $ymin,
                            $xory, $ymin + $tick, {@lineattr});
         createLineMetaPost($xory, $ymax,
                            $xory, $ymax - $tick, {@lineattr});
      }
      elsif($which eq '-y') {
         if($majorgridlinedoit and $i != 0 and $i != $#majortick) {
            my @lineattr = (-width => $majorgridlinewidth,
                            -fill  => $majorgridlinecolor,
                            @majordash);
            $canv->createLine($xmin, $xory, $xmax, $xory, @lineattr,
                              -tags  => [ $self.'majorgrid' ]);
         }
         $canv->createLine($xmin, $xory,
                           $xmin + $tick, $xory, @lineattr);
         createLineMetaPost($xmin, $xory,
                            $xmin + $tick, $xory, {@lineattr});
         unless($double_y) { # DOUBLE Y
            $canv->createLine($xmax, $xory,
                              $xmax - $tick, $xory, @lineattr);
            createLineMetaPost($xmax, $xory,
                               $xmax - $tick, $xory, {@lineattr});
         }
      }        
      else {  # DOUBLE Y
         if($majorgridlinedoit and $i != 0 and $i != $#majortick) {
            my @lineattr = (-width => $majorgridlinewidth,
                            -fill  => $majorgridlinecolor,
                            @majordash);
            $canv->createLine($xmin, $xory, $xmax, $xory, @lineattr,
                              -tags  => [ $self.'majorgrid' ]);
            createLineMetaPost($xmin, $xory, $xmax, $xory, {@lineattr});
         }
         $canv->createLine($xmax, $xory,
                           $xmax - $tick, $xory, @lineattr);
         createLineMetaPost($xmax, $xory,
                           $xmax - $tick, $xory, {@lineattr});
      }  
   }
   
   # DRAW THE DESIRED MAJOR LABELS
   for (my $i=0; $i <= $#majorlabel; $i += ($labskip+1) ) {
     next unless( defined $majorlabel[$i] );
     $xory = $majortick[$i] - $bracketgroup;
     $xory = &transReal2CanvasGLOBALS($self, $which, $type, 1, $xory); 
     next unless( defined $xory );
     $xory = &revAxis($self, $which, $xory) if($rev);         

     my $text = $majorlabel[$i];
     $text =~ s/^("|')//og;   # strip " or ' from start of string
     $text =~ s/("|')$//og;   # strip " or ' from end of string
     $text =~ s/(.)/$1\n/g if($stackit);
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
           die "Bad location '$location' call on discrete label\n";
         }              
       }
       elsif($which eq '-y') {
         if($dblabel and not $double_y) {
           &_drawTextonLeft($canv,$xmin,$xory,$text,@textattr);
           &_drawTextonRight($canv,$xmax,$xory,$text,@textattr);
         }
         elsif($location eq 'left' or $double_y) {
           &_drawTextonLeft($canv,$xmin,$xory,$text,@textattr);
         }
         elsif($location eq 'right' and not $double_y) {
           &_drawTextonRight($canv,$xmax,$xory,$text,@textattr);
         }
         else {
             die "Bad location '$location' call on discrete label\n";
         }
       }
       else { # DOUBLE Y
          &_drawTextonRight($canv,$xmax,$xory,$text,@textattr);
       }
     }   
   }
   
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
   else {
      $canv->createLine($xmax, $ymin, $xmax, $ymax, @axisattr,
                        -tags  => "$self"."yaxis2");
      createLineMetaPost($xmax, $ymin, $xmax, $ymax, {@axisattr});
   }
   $canv->fontDelete($self."$which"."numfont");
}

1;
