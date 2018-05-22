package Tkg2::EditGlobalVars;

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
# $Date: 2004/09/21 19:08:26 $
# $Revision: 1.6 $

use strict;
use vars qw(@ISA @EXPORT $EDITOR $NAMEIT);

use Tkg2::Base qw(Message isNumber Show_Me_Internals);

use Exporter;
use SelfLoader;

@ISA = qw(Exporter SelfLoader);
@EXPORT = qw(EditGlobalVariables); 
$EDITOR = "";

1;
__DATA__

sub EditGlobalVariables {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my ($pw, $template, $canv, $noPlottingCoe) = @_;

   my %Config;
   my @variables = qw( -PLOTTING_POSITION_COEFFICIENT
                       -ZOOM
                     );
 
   @Config{@variables} = @::TKG2_CONFIG{@variables};
   
   my $font    = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   
   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   my $pe = $pw->Toplevel(-title => 'Edit Some Global Variables');
   $EDITOR = $pe;
   
   my $text = "EDIT SOME GLOBAL VARIABLES\n".
              "Some global variables can be changed here.\n".
              "These variables are typically set by the\n".
              "command line or by the tkg2rc files.\n".
              "See the 'Tkg2rc File' under the 'Help' menu.\n".
              "The variables are safely changed at any time.\n".
              "The canvas is redrawn when APPLY is clicked.";
   $pe->Label(-text => $text,
              -font => $fontb,
              -justify => 'left',
              -anchor => 'w')
      ->pack( -fill =>'x');

   my $frame = $pe->Frame->pack(-side => 'top', -fill => 'x');   
   
   my $moretext = "";
   foreach my $var (@variables) {
      next if($noPlottingCoe and
              $var eq '-PLOTTING_POSITION_COEFFICIENT');
      $moretext = "(rescales fonts only)" if($var eq '-ZOOM');
      $frame->Label(-text => "Value for $var $moretext",
                    -font => $fontb)
            ->pack(-side => 'top', -anchor => 'w');     
      $frame->Entry(-textvariable => \$Config{$var},
                    -font         => $font,
                    -background   => 'white' )
            ->pack(-side => 'top', -fill => 'x');
      $moretext = "";
   }
   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
   $f_b->Button(-text        => 'Apply',
                -font        => $fontb,
                -command =>
                sub {
                my $message; # false initially
                
                if(not &isNumber($Config{-ZOOM}) or
                                 $Config{-ZOOM} <= 0 ) {
                   $message = "-ZOOM must be greater than zero.";
                   $Config{-ZOOM} = $::TKG2_CONFIG{-ZOOM};
                }
                
                my $ppc = '-PLOTTING_POSITION_COEFFICIENT';
                if(not &isNumber($Config{$ppc}) or
                                 $Config{$ppc} < 0 ) {
                   $message = "$ppc must be greater than zero.";
                   $Config{$ppc} = $::TKG2_CONFIG{$ppc};
                }
                # spit out the message to the user if present
                # and quietly return before the potentially diasterous
                # call to UpdateCanvas
                if($message) {
                   &Message($::MW,'-generic',$message);
                   return;
                }
                
                # finally loaded the new configuration into the global 
                # hash for good.
                map { $::TKG2_CONFIG{$_} = $Config{$_} } (@variables);
                
                $template->UpdateCanvas($canv);
                } )
                ->pack(-side => 'left');      
   $f_b->Button(-text        => 'Exit',
                -font        => $fontb,
                -command => sub { $pe->destroy; } )
                ->pack(-side => 'left');                  
}

1;
