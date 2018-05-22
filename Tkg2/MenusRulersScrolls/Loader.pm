package Tkg2::MenusRulersScrolls::Loader;

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
# $Revision: 1.6 $

use strict;
use Exporter;
use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);

@EXPORT_OK = qw(TemplateFullMenus
                TemplateDisplayMenus
                Rulers
                buildScrollBars
                configureScrollBars);


use Tkg2::MenusRulersScrolls::Menus   qw(TemplateFullMenus TemplateDisplayMenus);
use Tkg2::MenusRulersScrolls::Rulers  qw(Rulers);
use Tkg2::MenusRulersScrolls::Scrolls qw(buildScrollBars configureScrollBars);

1;
