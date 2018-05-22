#!/usr/bin/perl -w

=head1 LICENSE

 This Tkg2 program is authored by the enigmatic William H. Asquith.
     
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

## CVS STAMPS are present in every module and look like the following
# $Author: wasquith $
# $Date: 2002/01/06 14:12:20 $
# $Revision: 1.1 $

$ex    = "/usr/local/bin/tkg2";
$type  = "-mktemp=portrait";
@plots = qw( -mkplot=1.5x1x1.000x5.875
             -mkplot=1.5x1x5.375x1.50
           );
$com = "$ex $type @plots @ARGV";
print "Tkg2_PreMade, $0:\n   $com\n";
exec($com);
