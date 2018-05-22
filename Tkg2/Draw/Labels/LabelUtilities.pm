package Tkg2::Draw::Labels::LabelUtilities;

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
# $Date: 2007/09/10 02:25:58 $
# $Revision: 1.15 $

use strict;
use Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT_OK = qw( _drawTextonBottom 
                 _drawTextonTop
                 _drawTextonLeft
                 _drawTextonRight
                 _testLimits
                 _buildLabel
                 __blankit
               );
               
use Tkg2::Base qw(commify);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createAxisLabelsMetaPost);

print $::SPLASH "=";

# _buildLabel is the interface that takes a text string for an axis
# label element, stacks it, adds commas and acts as a wrapper on the
# __labelEquation subroutine that actually applies dynamic label
# transformation to the text element given a situation in which
# a label equation is none zero.  Called by _drawLinearLabels
# and _drawLogLabels
sub _buildLabel {
   my ($text, $labeleqn, $numcommify, $stackit) = @_;
   my ($text1, $text2) = ($labeleqn) ?
                          &__labelEquation($text,$labeleqn) : ($text, $text);
   if($numcommify) {
     $text1 = &commify($text1);
     $text2 = &commify($text2);
   } 
   
   if($stackit) { 
      $text1 =~ s/(.)/$1\n/g;
      $text2 =~ s/(.)/$1\n/g;
   }
   return ($text1, $text2);
}
   

# An eval wrapper on the -labelequation value than performs substitution 
# for a variable $x, which is the passed in real-world data point,
# and returns original text or the transformed text
sub __labelEquation {
   my ($x, $labeleqn) = @_;
   my $X = $x; # we create an capital X so that if the user
      # entered a capital letter it ends up being treated as a lower
      # case x.  This is faster than performing a substitution on
      # the $labeleqn string.
      
   # one sided if a colon is first
   my $onesided = ($labeleqn =~ s/(.*);//) ? 1 : 0;
   my $text     = eval $labeleqn;
   if($@) {
      print $::BUG  "Error in eval'ing the label transform equation.\n";
      # by returning just the text that was passed in, we are assured
      # that tkg2 will not crash
      return ($x, $x);  # no change to the text
   }
   return ($onesided) ? ($x, $text) : ($text, $text);
}     

               
                 
# Subroutines to draw text along the x axis
# One for the bottom x axis and one for the top x axis
# _drawTextonBottom($canv,$x,$ymax,$numoffset,$text,$numfont,$numcolor);
sub _drawTextonBottom {
   my $ftref = pop(@_); # specific for MetaPost
   my ($canv, $x, $ymax, $text, $selfastag,
       $numoffset, $numfont, $numcolor,
       $blankit, $blankcolor, $numrotation ) = @_;
   my $y   = $ymax + $numoffset;
   my $tag = $selfastag.'axislabel';
   $canv->createText($x,$y,
                     -text   => $text,
                     -font   => $numfont,
                     -fill   => $numcolor,
                     -anchor => 'n',
                     -tags   => $tag );
   &__blankit($canv, $blankit, $blankcolor, $tag)
      if($blankit);
   createAxisLabelsMetaPost($x,$y-$numoffset,"bot",
                            {-offset => $numoffset,
                            -text   => $text,
                            -angle  => $numrotation,
                            -fill   => $numcolor,
                            -family  => $ftref->{-family},
                            -size    => $ftref->{-size},
                            -weight  => $ftref->{-weight},
                            -slant   => $ftref->{-slant},
                            -blankcolor => $blankcolor,
                            -blankit => $blankit});
}

# _drawTextonTop($canv,$x,$ymin,$numoffset,$text,$numfont,$numcolor);
sub _drawTextonTop {
   my $ftref = pop(@_); # specific for MetaPost
   my ($canv, $x, $ymin, $text, $selfastag,
       $numoffset, $numfont, $numcolor,
       $blankit, $blankcolor, $numrotation ) = @_;
   my $y   = $ymin - $numoffset;
   my $tag = $selfastag.'axislabel';
   $canv->createText($x,$y,
                     -text   => $text,
                     -font   => $numfont,
                     -fill   => $numcolor,
                     -anchor => 's',
                     -tags   => $tag );   
   &__blankit($canv, $blankit, $blankcolor, $tag)
      if($blankit);
   createAxisLabelsMetaPost($x,$y+$numoffset,"top",
                            {-offset => $numoffset,
                            -text   => $text,
                            -angle  => $numrotation,
                            -fill   => $numcolor, 
                            -family  => $ftref->{-family},
                            -size    => $ftref->{-size},
                            -weight  => $ftref->{-weight},
                            -slant   => $ftref->{-slant},
                            -blankcolor => $blankcolor,
                            -blankit => $blankit});
}

# Private subroutines to draw text along the y axis
# One for the left y axis and one for the right y axis
# _drawTextonLeft($canv,$xmin,$y,$numoffset,$text,$numfont,$numcolor);
sub _drawTextonLeft {
   my $ftref = pop(@_); # specific for MetaPost
   my ($canv, $xmin, $y, $text, $selfastag,
       $numoffset, $numfont, $numcolor,
       $blankit, $blankcolor, $numrotation ) = @_;
   my $x   = $xmin - $numoffset;
   my $tag = $selfastag.'axislabel';
   $canv->createText($x,$y,
                     -text   => $text,
                     -anchor => 'e',
                     -font   => $numfont,
                     -fill   => $numcolor,
                     -tags   => $tag );
   &__blankit($canv, $blankit, $blankcolor, $tag)
      if($blankit);
   createAxisLabelsMetaPost($x+$numoffset,$y,"lft",
                            {-offset => $numoffset,
                            -text   => $text,
                            -angle  => $numrotation,
                            -fill   => $numcolor,
                            -family  => $ftref->{-family},
                            -size    => $ftref->{-size},
                            -weight  => $ftref->{-weight},
                            -slant   => $ftref->{-slant},
                            -blankcolor => $blankcolor,
                            -blankit => $blankit});
}

# _drawTextonRight($canv,$xmax,$y,$numoffset,$text,$numfont,$numcolor);
sub _drawTextonRight {
   my $ftref = pop(@_); # specific for MetaPost
   my ($canv, $xmax, $y, $text, $selfastag,
       $numoffset, $numfont, $numcolor,
       $blankit, $blankcolor, $numrotation ) = @_;
   my $x   = $xmax + $numoffset;
   my $tag = $selfastag.'axislabel';
   $canv->createText($x,$y,
                     -text   => $text,
                     -anchor => 'w',
                     -font   => $numfont,
                     -fill   => $numcolor,
                     -tags   => $tag );
   &__blankit($canv, $blankit, $blankcolor, $tag)
      if($blankit);
   createAxisLabelsMetaPost($x-$numoffset,$y,"rt",
                            {-offset => $numoffset,
                            -text   => $text,
                            -angle  => $numrotation,
                            -fill   => $numcolor,
                            -family  => $ftref->{-family},
                            -size    => $ftref->{-size},
                            -weight  => $ftref->{-weight},
                            -slant   => $ftref->{-slant},
                            -blankcolor => $blankcolor,
                            -blankit => $blankit});
}

sub _testLimits {
   my ($self, $which) = ( shift, shift);
   my $ref = $self->{$which};
   unless(defined($ref->{-min})) {
      warn "Undefined graph minimum";
      return 0;
   }
   unless(defined($ref->{-max})) {
      warn "Undefined graph maximum";
      return 0;   
   }
   return 1;
}


# __blankit is a little sub that colors in behind a symbol or text object
# drawn on the screen.
sub __blankit {
   my ($canv, $blankit, $blankcolor, $tag) = @_;
   return unless($blankit);
   # the following is color check is just for safety, although at
   # this point paranoid is likely not needed, but o'well.
   $blankcolor = 'white' if( not defined $blankcolor );             
   my @coord = $canv->bbox($tag);

   return unless(@coord == 4); # return quietly for safety for tab problems
   $canv->createRectangle(@coord,
                          -outline => $blankcolor,
                          -fill    => $blankcolor,
                          -tags    => [ $tag."blankit" ]);

   # The newly created Rectangle requires being hidden behind the text                       
   $canv->raise($tag, $tag."blankit");  
   $canv->dtag($tag); # now delete the temporary tag to the canvas does
   # not get progressively filled up with the tag and then pretty soon
   # the entire portions of the canvas are blanked out
}



1;
