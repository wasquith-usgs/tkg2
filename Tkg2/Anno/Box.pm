package Tkg2::Anno::Box;

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
# $Date: 2000/04/10 17:11:10 $
# $Revision: 1.4 $

sub new {
   use strict;
   my ($x, $y) = ( shift, shift);
   my $self = { -x1 => $x, -y1 => $y };
   return bless $self, shift;
}


1;
