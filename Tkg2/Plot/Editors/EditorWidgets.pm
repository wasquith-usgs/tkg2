package Tkg2::Plot::Editors::EditorWidgets;

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
# $Date: 2002/08/07 18:25:31 $
# $Revision: 1.3 $

use strict;
use vars qw(@ISA @EXPORT_OK);

use Exporter;
use SelfLoader;

use Tkg2::Base qw(Message isNumber Show_Me_Internals);

@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw(AutoPlotLimitWidget); 

print $::SPLASH "=";

1;
__DATA__

# Specify auto plot limit configuration, additional data read in after modifying
# these selections will cause the limits to potentially change.  Each axis can be
# controlled via the ContinuousAxisEditor, which will usually be the prefered route.
sub AutoPlotLimitWidget {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($frame, $aref, $a_string) = @_;
   
   my $fontb   = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
  
   $frame->Label(-text => "Autoconfigure $a_string-Axis Limits: ",
                 -font => $fontb)
         ->pack(-side => 'left');               
   $frame->Checkbutton(-text     => 'Minimum  ',
                       -font     => $fontb,
                       -variable => \$aref->{-autominlimit},
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   $frame->Checkbutton(-text     => 'Maximum',
                       -font     => $fontb,
                       -variable => \$aref->{-automaxlimit},
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   my $centering = ($aref->{-autominlimit} eq 'center' or
                    $aref->{-automaxlimit} eq 'center' ) ? 'center' : 0;
   $frame->Checkbutton(-text     => 'Center?',
                       -font     => $fontb,
                       -variable => \$centering,
                       -onvalue  => 'center',
                       -offvalue => 0,
                       -command  => sub { my $mxref = \$aref->{-automaxlimit};
                                          my $mnref = \$aref->{-autominlimit};
                                            $$mxref = $$mnref =
                                            ($centering) ? 'center' : 1;
                                       } )
         ->pack(-side => 'left');                    
}

1;
