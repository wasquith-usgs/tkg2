package Tkg2::DeskTop::Undo;

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
# $Revision: 1.11 $

use strict;

use Exporter;
use SelfLoader;
use vars     qw(@ISA @EXPORT_OK);
@ISA       = qw(Exporter SelfLoader);
@EXPORT_OK = qw(StoreUndo Undo RemoveUndo);
             
use Tkg2::Base qw(Show_Me_Internals);

print $::SPLASH "=";

1;
__DATA__

# Exported eventually to the $template package (main) so that
# the previous configuration of is stored by $template->StoreUndo
# @::UNDO in package main is the global variable holding anonymous 
# undo arrays for each template.             
sub StoreUndo {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   return 0 if($::CMDLINEOPTS{'noundo'});
   
   my $template = shift;
   my $clone = $template->DeepClone;  # need deep cloning
   # we are not able to clone anonymous subroutines, so
   # the next two lines provide that
   $clone->{-markrulerEv} = $template->{-markrulerEv};
   $clone->{-markrulerXY} = $template->{-markrulerXY};
   # restore the grid coordinates,  this is needed because
   # DeepClone gets rid of these for file saving purposes
   $clone->{-x_grid}      = $template->{-x_grid};
   $clone->{-y_grid}      = $template->{-y_grid};
   # -undonum is the permanent storage of which element
   # in @::UNDO holds the array of undos
   my $undonum = $template->{-undonum}; # grab the current template number
   
   # if there are 3 templates in storage, then pull the first on off
   shift(@{$::UNDO[$undonum]}) if(scalar(@{$::UNDO[$undonum]}) == 3);
   
   # push the current clone of the template onto the undo array.
   push( @{$::UNDO[$undonum]}, $clone);
}   


# Exported eventually to the $template package (main)
# This method provides the retrieval mechanism for replacing
# the current template with a stored away version in 
# @::UNDO
sub Undo {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   # $template->Undo(1); OR $template->Undo(2);
   my ($template, $element) = (shift, shift);
   my $which = $template->{-undonum}; # grab the current template number
   my $un    = scalar(@{$::UNDO[$which]}); # how many undos in storage
   
   my $undone;  # the undone template to return
   # if three templates have been stored away
   if($un == 3) {
      if($element == 1) {
         # undo'ing with Undo 1 level back
         $undone = $::UNDO[$which]->[1]; # the undo is second in array 
         # swap so that Undo 1 will work as a Redo
         $::UNDO[$which]->[1] = $::UNDO[$which]->[0];
      }
      elsif($element == 2) { # element is 2 so grab the first element
         $undone = $::UNDO[$which]->[0];
      }
      else { warn "bad Undo call number of $element\n"; }
   }
   
   # only two template have been stored away
   elsif($un == 2) { 
      $undone = ($element == 1) ? $::UNDO[$which]->[0] : $template;
   }
   
   # no undo available yet, return current template
   else { return $template; }
   
   return $undone;
}             

sub RemoveUndo {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my $template = shift;
   # remove the undo storage for the template
   splice(@::UNDO, $template->{-undonum}, 1); }

1;

__END__

Code documented by William H. Asquith November 3, 1999
