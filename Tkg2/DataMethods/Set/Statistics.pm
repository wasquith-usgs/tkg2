package Tkg2::DataMethods::Set::Statistics;

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
# $Date: 2002/08/07 18:39:30 $
# $Revision: 1.8 $

use strict;
use Tkg2::Help::Help;
use Tkg2::Base qw(Show_Me_Internals);

use Exporter;
use SelfLoader;

use vars qw(@ISA @EXPORT_OK $EDITOR);
@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw(StatisticsEditor);


print $::SPLASH "=";

__DATA__

sub StatisticsEditor {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($dataset, $canv, $plot, $template, $name) = @_;
   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   my $pw = $canv->parent;
   my $pe = $pw->Toplevel(-title => "Statistics for $name");
   $EDITOR = $pe;
   $pe->resizable(0,0);
   my $font = "Helvetica 10 bold";

   my ($px, $py) = (2, 2);   
   my $f_b = $pe->Frame(-relief => 'groove', -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
                     
   my $b_ok = $f_b->Button(-text => "OK",
                           -font => $font,
                           -borderwidth => 3,
                           -highlightthickness => 2,
                    -command => sub { $pe->destroy;
                                      $template->UpdateCanvas($canv); } )
                  ->pack(-side => 'left', -padx => $px, -pady => $py); 
   $b_ok->focus;
   my $b_cancel = $f_b->Button(-text => "Cancel", 
                               -font => $font,       
                    -command => sub { $pe->destroy; })
                      ->pack(-side => 'left', -padx => $px, -pady => $py);
                        
   my $b_help = $f_b->Button(-text => "Help",
                             -font => $font, 
                             -padx => 4, -pady => 4,
                             -command => sub { return; } )
                    ->pack(-side => 'left', -padx => $px, -pady => $py,);  
   
}



