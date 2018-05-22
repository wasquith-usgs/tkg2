package Tkg2::DataMethods::ClassLoader;
use strict;

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
# $Date: 2000/05/31 12:52:14 $
# $Revision: 1.8 $

use Tkg2::Base;

use Exporter;

use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);

use Tkg2::DataMethods::Class::DataClassEditor         qw(DataClassEditor);
use Tkg2::DataMethods::Class::AddDataToPlot             qw(AddDataToPlot);
use Tkg2::DataMethods::Class::LoadDataIntoPlot       qw(LoadDataIntoPlot);
use Tkg2::DataMethods::Class::ReadFiles qw(ReadRDBFile ReadDelimitedFile);
use Tkg2::DataMethods::Class::LoadData  qw(LoadDataSets LoadDataOnTheFly);

@EXPORT = qw(DataClassEditor AddDataToPlot LoadDataIntoPlot 
             ReadRDBFile ReadDelimitedFile LoadDataSets LoadDataOnTheFly);


1;
