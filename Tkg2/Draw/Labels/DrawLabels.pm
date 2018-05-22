package Tkg2::Draw::Labels::DrawLabels;

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
# $Date: 2002/08/07 18:36:31 $
# $Revision: 1.11 $

use strict;
                           
use Tkg2::Draw::Labels::DiscreteLabels qw(DiscreteLabels);
use Tkg2::Draw::Labels::LinearLabels   qw(LinearLabels  );
use Tkg2::Draw::Labels::LogLabels      qw(LogLabels     );
use Tkg2::Draw::Labels::ProbLabels     qw(ProbLabels    );

use Tkg2::Draw::Labels::LabelUtilities qw(__blankit);

use Tkg2::Base qw(Show_Me_Internals);

use Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA       = qw(Exporter);
@EXPORT_OK = qw(drawAxisLabels __blankit);

print $::SPLASH "=";

# drawAxisLabels is the method imported into a plots bless'ed namespace
# drawAxisLabels acts as a router to the actual axis drawing and labeling
# subroutines.  This is a very convenient wrapper because in time as other
# axis are added the all that is needed to change is the $type and add
# call to the new axis subroutine.  Hopefully this is a good design choice.
sub drawAxisLabels { 
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'}); # just tracking logic
   my ($self, $canv, $which) = @_;
   # notice that $which can lazily be code in the calling subroutine
   # x makes is for the -x axis and 2 makes it for the -y2 axis, otherwise
   # the -y axis is used, sort of as a default value.  Things will look
   # really funny to the user if the determination of $which doesn't pan
   # out, but it should be an easy bug to fix if it ever crops up.
   $which    = ($which =~ m/x/io) ? '-x'  :
               ($which =~ m/2/io) ? '-y2' : '-y';
   my $ref   = $self->{$which};  # reference to the axis hash
   my $type  = $ref->{-type};    # what type of axis is this
   
   my @args = ($self,$canv,$which);  # just to make the following code cleaner
   return &DiscreteLabels(@args)   if( $ref->{-discrete}->{-doit} );  
   return &LinearLabels(@args)     if( $type eq 'linear');
   return &LogLabels(@args)        if( $type eq 'log'   );
   return &ProbLabels(@args,$type) if( $type eq 'prob' or $type eq 'grv');
   # notice that the methods are inlined and called in decreasing order of
   # probable occurrance (except for the discrete axis which is not tracked)
   # by type because discrete is really a linear axis with different labeling

   # Hope that the following error never shows up
   warn "DrawLabels::drawAxisLabels called with invalid type\n"; 
}

1;
