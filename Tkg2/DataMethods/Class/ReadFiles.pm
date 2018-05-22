package Tkg2::DataMethods::Class::ReadFiles;

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
# $Date: 2008/01/28 17:59:00 $
# $Revision: 1.19 $

use strict;
use Tkg2::Base qw(Message strip_space isNumber);
use Tkg2::Time::TimeMethods;

use Tkg2::DataMethods::Class::ReadRDBFile qw(ReadRDBFile);
use Tkg2::DataMethods::Class::ReadDelimitedFile qw(ReadDelimitedFile);

use Tk;
use Exporter;

use vars qw(@ISA @EXPORT_OK $PATH_BREAKING_THRESHOLD);
@ISA = qw(Exporter);

@EXPORT_OK = qw(ReadRDBFile ReadDelimitedFile);


# PATH BREAKING WHA: 1/28/2008
$PATH_BREAKING_THRESHOLD = 17280; # 6 months of 15 minute data


print $::SPLASH "=";

1;
