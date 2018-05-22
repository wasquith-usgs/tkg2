package Tkg2::Anno::SelectAnno;

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
# $Date: 2002/08/07 18:41:28 $
# $Revision: 1.3 $

use strict;
use Exporter;
use SelfLoader;
use vars     qw(@ISA @EXPORT_OK $SELECTANNOEDITOR $ANNO);
@ISA       = qw(Exporter SelfLoader);
@EXPORT_OK = qw(SelectAnno);

use Tkg2::Base qw(Show_Me_Internals);

print $::SPLASH "=";

1;

__DATA__


sub SelectAnno { 
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ( $template, $canv, $type) = @_;
   my @anno = @{ $template->{$type} }; # grab list of all plots on canvas
   return if(not @anno); # just return no anno are yet drawn on the screen
   $SELECTANNOEDITOR->destroy if( Tk::Exists($SELECTANNOEDITOR) );
   my $tw = $canv->parent;
   my $pe = $tw->Toplevel(-title => 'Tkg2 Select Annotation');
   $SELECTANNOEDITOR = $pe;
   
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
      
   my ($px, $py) = ( 2, 2);
   my ($index, $n) = (0, scalar(@anno));
   $pe->Scale(-from         => 1,
              -to           => $n,
              -resolution   => 1,
              -orient       => 'horizontal',
              -label        => "Select one of $n anno",
              -font         => $fontb,
              -variable     => \$index,
              -tickinterval => 1,
              -showvalue    => 0,
              -command => sub { my $index = shift;
                                $index--;
                                $ANNO = $anno[$index];
                                $ANNO->highlightAnno($canv);
                              } )
      ->pack(-expand => 1, -fill => 'x');
   $pe->Label(-text => 'Anno number',
              -font => $fontb)->pack;

   
   my @p = (-side => 'left', -padx => $px, -pady => $py);
   my $f_b = $pe->Frame(-relief => 'groove', -borderwidth => 2)
                ->pack(-fill => 'x');
   my $b_ok = $f_b->Button(
                  -text        => 'OK',
                  -font        => $fontb,
                  -borderwidth => 3,
                  -command     => sub { $canv->delete('selectedanno');
                                        $pe->destroy; } )
                  ->pack(@p);                  
   $f_b->Button(-text    => "Cancel", 
                -font    => $fontb,
                -command => sub { $canv->delete('selectedanno');
                                  $pe->destroy; })
       ->pack(@p);
   $f_b->Button(-text    => 'Anno Editor',
                -font    => $fontb,
                -command => sub { $ANNO->AnnoEditor($canv, $template);
                                })
       ->pack(@p);
   $f_b->Button(-text    => "Help", 
                -font    => $fontb,
                -padx    => 4,
                -pady    => 4,
                -command => sub { return; } )
       ->pack(@p);
}

1;
