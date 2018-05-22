package Tkg2::Plot::BoxPlot::Editor::BoxPlotEditor;

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
# $Date: 2002/08/07 18:31:31 $
# $Revision: 1.8 $

use strict;

use Exporter;
use vars qw(@ISA @EXPORT_OK $LAST_PAGE_VIEWED );     
      
@ISA       = qw(Exporter);
@EXPORT_OK = qw(SpecialPlotEditor checkConfiguration);

use Tkg2::Plot::BoxPlot::Editor::LocationTab  qw( _Location
                                                  _checkLocation     );
                                                  
use Tkg2::Plot::BoxPlot::Editor::CileTab      qw( _Ciles 
                                                  _checkCiles        );
                                                  
use Tkg2::Plot::BoxPlot::Editor::TailTab      qw( _Tails 
                                                  _checkTails        );
                                                  
use Tkg2::Plot::BoxPlot::Editor::SampleTab    qw( _Sample
                                                  _checkSample       );
                                                  
use Tkg2::Plot::BoxPlot::Editor::OutlierTab   qw( _Outliers 
                                                  _checkOutliers     );
                                                  
use Tkg2::Plot::BoxPlot::Editor::DetectTab    qw( _DetectLimits
                                                  _checkDetectLimits );

use Tkg2::Plot::BoxPlot::Editor::ShowDataTab  qw( _ShowData
                                                  _checkShowData     );
                                                  
use Tkg2::Plot::BoxPlot::Editor::ShowStatsTab qw( _ShowStats 
                                                  _checkShowStats    );

use Tkg2::Base qw(Show_Me_Internals);

print $::SPLASH "=";

$LAST_PAGE_VIEWED = 'Location';

sub SpecialPlotEditor {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($box, $page, $template, $dataset ) = @_;
   
   my $fontb = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my @tabs;
   my @tabnames = ( "Location",   "'ciles",       "Tails",
                    "Outliers",   "Sample\nSize", "Detection\nLimits",
                    "Show\nData", "Statis\n-tics" );

   my $nb = $page->NoteBook(
                 -font            => $fontb,
                 -dynamicgeometry => 1 )
                 ->pack(-expand => 1, -fill => 'both');
   foreach my $tab (@tabnames) {
      push(@tabs, $nb->add( $tab, -label => $tab,
                     -raisecmd => sub { $LAST_PAGE_VIEWED = $tab} )
          );
   }  
 
   $nb->raise($LAST_PAGE_VIEWED);
   
   my @args =  ( $box, $template );
   &_Location(     $tabs[0], @args );
   &_Ciles(        $tabs[1], @args );
   &_Tails(        $tabs[2], @args );
   &_Outliers(     $tabs[3], @args );
   &_Sample(       $tabs[4], @args );
   &_DetectLimits( $tabs[5], @args );
   &_ShowData(     $tabs[6], @args );
   &_ShowStats(    $tabs[7], @args, $dataset );
}


# checkConfiguration
# This sub is used to call each of the configuration checking subs for each
# tab on the NoteBook showing the special plot settings
sub checkConfiguration {
  &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
  
  my ($box, $pe) = @_;
  return 0 unless &_checkLocation(    $box, $pe );
  return 0 unless &_checkCiles(       $box, $pe );
  return 0 unless &_checkTails(       $box, $pe );
  return 0 unless &_checkSample(      $box, $pe );
  return 0 unless &_checkOutliers(    $box, $pe );
  return 0 unless &_checkDetectLimits($box, $pe );
  return 0 unless &_checkShowData(    $box, $pe );
  return 0 unless &_checkShowStats(   $box, $pe );
  return 1;
}

1;
