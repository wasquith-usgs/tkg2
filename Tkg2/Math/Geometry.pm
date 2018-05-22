#!/usr/bin/perl
package Tkg2::Math::Geometry;

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
# $Date: 2001/06/16 13:08:29 $
# $Revision: 1.4 $

use strict;
use vars qw(@ISA @EXPORT_OK);
            
use Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw( line_intersect );

use Tkg2::Base qw(Show_Me_Internals);
    
use constant EPS => 1e-14;

# line_intersect( $x0, $y0, $x1, $y1, $x2, $y2, $x3, $y3 )
#    Returns true if the two lines defined by these points intersect.
#    In borderline cases, it relies on EPS to decide.
sub line_intersect {
    my ( $x0, $y0, $x1, $y1, $x2, $y2, $x3, $y3 ) = @_;

    my @box_a = &bounding_box( $x0, $y0, $x1, $y1 );
    my @box_b = &bounding_box( $x2, $y2, $x3, $y3 );

    # Unless the bounding boxes intersect, give up right now.
    return 0 unless &bounding_box_intersect( @box_a, @box_b );

    # If the signs of the two determinants (absolute values or lengths
    # of the cross products, actually) are different, the lines
    # intersect.

    my $dx10 = $x1 - $x0;
    my $dy10 = $y1 - $y0;
    my $det_a = ($x2 - $x0)*$dy10 - ($y2 - $y0)*$dx10;
    my $det_b = ($x3 - $x0)*$dy10 - ($y3 - $y0)*$dx10;
    #my $det_a = &determinant( $x2 - $x0, $y2 - $y0, $dx10, $dy10 );
    #my $det_b = &determinant( $x3 - $x0, $y3 - $y0, $dx10, $dy10 );
    return 1 if($det_a < 0 and $det_b > 0 or
                $det_a > 0 and $det_b < 0);

    if( abs( $det_a ) < EPS ) {
        # Both cross products are "zero", abs( $det_b ) < EPS
        return 1 if( ( abs( $det_b ) < EPS )
                             or
                     ( abs( $x3 - $x2 ) < EPS and
                       abs( $y3 - $y2 ) < EPS )
                   );
        # The other cross product is "zero" and
        # the other vector (from (x2,y2) to (x3,y3))
        # is also "zero".
        # ( abs( $x3 - $x2 ) < EPS and
        #   abs( $y3 - $y2 ) < EPS )
    }
    elsif( abs( $det_b < EPS ) ) {
        # The other cross product is "zero" and
        # the other vector is also "zero".
        return 1 if(abs( $dx10 ) < EPS and
                    abs( $dy10 ) < EPS);
    }
    return 0; # Default is no intersection.
}

# bounding_box(@p)
#   Return the bounding box of the points @p in 2 dimensions.
#   The bounding box is returned as a list.  The first 2 elements
#   are the minimum coordinates, the last 2 elements are the
#   maximum coordinates.
sub bounding_box {
    my ( $x0, $y0, $x1, $y1 ) = @_;

    # X coordinates
    # The first x is larger than the second, reverse'em
    ($x0, $x1) = ($x1, $x0) if($x0 > $x1);
    
    # Y coordinates
    # If the first y is larger than the second, reverse'em
    ($y0, $y1) = ($y1, $y0) if($y0 > $y1);
    return ( $x0,  $y0,  $x1,  $y1 );
}

# bounding_box_intersect(@a, @b)
#   Return true if the given bounding boxes @a and @b intersect
#   Used by line_intersection().
sub bounding_box_intersect {
    my ( $x0, $y0, $x1, $y1, $x2, $y2, $x3, $y3 ) = @_;
    return 0 if( ($x1+EPS) < $x2 ||
                 ($x3+EPS) < $x0 ||
                 ($y1+EPS) < $y2 ||
                 ($y3+EPS) < $y0 );
    return 1;
}

# determinant( $x0, $y0, $x1, $y1 )
#   Computes the determinant given the four elements of a matrix
#   as arguments.
#sub determinant { $_[0] * $_[3] - $_[1] * $_[2] }

1;
