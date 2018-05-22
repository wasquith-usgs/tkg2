package Tkg2::Plot::BoxPlot::Editor::ShowStatsTab;

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
# $Date: 2006/09/15 15:42:24 $
# $Revision: 1.11 $

use strict;

use Exporter;
use vars qw(@ISA @EXPORT_OK);
            
@ISA       = qw(Exporter);

@EXPORT_OK = qw(_ShowStats  _checkShowStats);

use Tkg2::Base qw(isNumber Message Show_Me_Internals);

print $::SPLASH "=";


sub _ShowStats {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($pw, $box, $template, $dataset) = @_;
   my $dump = "";
   my @data_in_set = @{$dataset->{-DATA}};
   foreach my $data (@data_in_set) {
      foreach my $dataentry (@{$data->{-data}}) {
         my $title = (ref $dataentry->[0] eq 'ARRAY') ? 
                          $dataentry->[0]->[1] : $dataentry->[0];
         my $boxdata = $dataentry->[2];
         
         # error trapping here when no data was actually available
         # this can only(?) occur with no data dynamic loading
         if(not defined $boxdata) {
            $dump .= "$title\n NO DATA LOADED\n\n";
            next;
         }
         my $text = $boxdata->show(1,1);
         $dump .= "$title\n$text\n\n";
      }
   }
   my $font = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   
   $pw->Label(-text => "Dumped Box Plot Statistics",
              -font => $font)->pack();
   my $textwig = $pw->Scrolled("Text",
                  -wrap       => 'none',
                  -font       => $font,
                  -background => 'white',
                  -height     => 10,
                  -width      => 67 )->pack();
   $textwig->insert('end', $dump);
   $textwig->configure(-state => "disabled");
}

sub _checkShowStats {
   return 1;
}

1;
