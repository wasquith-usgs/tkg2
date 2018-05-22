package Tkg2::DeskTop::SelectScales;

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
# $Date: 2002/08/07 18:37:57 $
# $Revision: 1.9 $

use strict;
use Exporter;
use SelfLoader;
use vars     qw(@ISA @EXPORT_OK $SELECTPLOTSCALE);
@ISA       = qw(Exporter SelfLoader);
@EXPORT_OK = qw(SelectPlotScale);

use Tkg2::Base qw(Show_Me_Internals);

print $::SPLASH "=";

1;

__DATA__

# SelectPlotScale is a nifty widget that allows the user to select a
# plot on the canvas.  This was added because occassionally the accidental
# release of a mouse button can leave a plot on the canvas that is too small
# to reliably pick up again with the mouse to resize or delete. 
# The user can get to the Plot Editor via the button at the bottom of the
# dialog to manually resize the margins or they can delete via the Edit menu. 
sub SelectPlotScale {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ( $template, $canv) = ( shift, shift);
   my @plots = @{ $template->{-plots} }; # grab list of all plots on canvas
   return if(not @plots); # just return no plots are yet drawn on the screen
   $SELECTPLOTSCALE->destroy if( Tk::Exists($SELECTPLOTSCALE) );
   my $tw = $canv->parent;
   my $pe = $tw->Toplevel(-title => 'Tkg2 Select Plot');
   $SELECTPLOTSCALE = $pe;
   
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
      
   my ($px, $py) = ( 2, 2);
   my ($index, $n) = (0, scalar(@plots));
   $pe->Scale(-from         => 1,
              -to           => $n,
              -resolution   => 1,
              -orient       => 'horizontal',
              -label        => "Select one of $n plots",
              -font         => $fontb,
              -variable     => \$index,
              -tickinterval => 1,
              -showvalue    => 0,
              -command => sub { my $index = shift;
                                $index--;
                                $::DIALOG{-SELECTEDPLOT} = $plots[$index];
                                $::DIALOG{-SELECTEDPLOT}->highlightPlot($canv);
                              } )
      ->pack(-expand => 1, -fill => 'x');
   $pe->Label(-text => 'Plot number',
              -font => $fontb)->pack;

   
   my @p = (-side => 'left', -padx => $px, -pady => $py);
   my $f_b = $pe->Frame(-relief => 'groove', -borderwidth => 2)
                ->pack(-fill => 'x');
   my $b_ok = $f_b->Button(
                  -text        => 'OK',
                  -font        => $fontb,
                  -borderwidth => 3,
                  -command     => sub { $pe->destroy; } )
                  ->pack(@p);                  
   $b_ok->focus;
   $f_b->Button(-text    => "Cancel", 
                -font    => $fontb,
                -command => sub { $pe->destroy; })
       ->pack(@p);
   $f_b->Button(-text    => 'Plot Editor',
                -font    => $fontb,
                -command => sub { $::DIALOG{-SELECTEDPLOT}->PlotEditor($canv, $template); })
       ->pack(@p);
   $f_b->Button(-text    => "Help", 
                -font    => $fontb,
                -padx    => 4,
                -pady    => 4,
                -command => sub { return; } )
       ->pack(@p);
}

1;
