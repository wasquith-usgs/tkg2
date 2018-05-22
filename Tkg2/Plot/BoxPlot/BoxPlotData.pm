package Tkg2::Plot::BoxPlot::BoxPlotData;

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
# $Date: 2004/06/09 18:52:32 $
# $Revision: 1.24 $

use strict;

use Tkg2::Math::CalcStatistics qw( calcStats ); 
use Tkg2::Base qw(Show_Me_Internals);

use Tkg2::Plot::BoxPlot::BoxPlotDraw qw( draw );

use Exporter;

use vars     qw(@ISA @EXPORT_OK @EXPORT @DataOrder);
@ISA       = qw(Exporter);
@EXPORT_OK = qw(constructBoxPlotDataObject);


print $::SPLASH "=";

@DataOrder = qw( -mean      -scale  -skew  -kurtosis
                 -median    -max    -min
                 -number_samples    -moment_calc_method 

                 -harmonic_mean    -geometric_mean  

                 -lower_tercile    -upper_tercile
                 -lower_quartile   -upper_quartile
                 -lower_pentacile  -upper_pentacile 
                 -lower_decile     -upper_decile
                 -lower_centacile  -upper_centacile  
                 
                 -type1_outliers  -type2_outliers
                 
                 -lower_detection_limit -lower_replace_value 
                 -upper_detection_limit -upper_replace_value
               
                 -DATA 
               );     

sub constructBoxPlotDataObject {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($dataref,
        $dn_lim, $dn_val,
        $up_lim, $up_val,
         $mom_method,
          $transformation,
           $missing_value_string ) = @_;
          
   my $box  = Tkg2::Plot::BoxPlot::BoxPlotData->new($dataref,
                                                    $missing_value_string);
              $box->setDetectionLimits($dn_lim, $dn_val, $up_lim, $up_val);
   my $mean = $box->computeBoxData($mom_method, $transformation);
   return ($mean, $box);
}



# Create a new BoxPlotData Object
sub new {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my $pkg     = shift;
   my $rawdata = shift() if(@_ and ref($_[0]) eq 'ARRAY');
   my $missing_value_string = shift;
   if(not defined $rawdata) {
      print STDERR "WARNING $pkg::new must have an array ref of the data ".
                   "as the second argument during box plot object construction\n".
                   "Apparently Tkg2 can not properly interpret the data file\n".
                   "that is being read in?\n";
   }
   my @cleaned_data;
   foreach (@$rawdata) {
     next if(not defined $_ or $_ eq "" or $_ eq $missing_value_string);
     push(@cleaned_data, $_);
   }
   my $box = {
               -number_samples        => 0,
               
               -DATA                  => [ @cleaned_data ],
               
               -mean                  => undef,
               -scale                 => undef,
               -skew                  => undef,
               -kurtosis              => undef,
               
               -lower_tercile         => undef,
               -upper_tercile         => undef,
               -lower_quartile        => undef,
               -upper_quartile        => undef,
               -lower_pentacile       => undef,
               -upper_pentacile       => undef,
               -lower_decile          => undef,
               -upper_decile          => undef,
               -lower_centacile       => undef,
               -upper_centacile       => undef,
               
               -median                => undef,
               -max                   => undef,
               -min                   => undef,
               
               -moment_calc_method    => undef,
               
               -harmonic_mean         => undef,
               -geometric_mean        => undef,
               
               -lower_detection_limit => undef,
               -lower_replace_value   => undef,
               -upper_detection_limit => undef,
               -upper_replace_value   => undef,
               
               -type1_outliers        => [ ],
               -type2_outliers        => [ ],             
               
          };
   bless($box, $pkg);
   return $box;
}

# setDetectionLimits
# This method should be called very soon after a box object construction. 
sub setDetectionLimits {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   return 0 unless(@_);
   # print "BOX: setDetectionLimits '@_'\n";
   my $box = shift;
   my ($dn_lim, $dn_val, $up_lim, $up_val) = ( shift, shift, shift, shift);
   
   if( defined $dn_lim ) {
      # the zero third argument is to insure that the data is not 10** up
      $box->setStat( -lower_detection_limit => $dn_lim, 0 );
      # use the actually limit in lue of the availability of a replacement value
      my $dn_val = (defined $dn_val) ? $dn_val : $dn_lim;
      $box->setStat(-lower_replace_value => $dn_val, 0 );
   }
   
   if( defined $up_lim ) {
      $box->setStat(-upper_detection_limit => $up_lim, 0 );
      my $up_val = (defined $up_val) ? $up_val : $up_lim;
      $box->setStat(-upper_replace_value => $up_val, 0 );
   }
} 
 

# massageData_for_Detection_Limits
# takes the raw data, copies it, massages it for the
# optional presence of detection limits and finally
# returns a reference to the data. 
sub massageData_for_Detection_Limits {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($box, $dataref) = ( shift, shift); 
   my $dn_lim = $box->getStat( -lower_detection_limit );
   my $up_lim = $box->getStat( -upper_detection_limit );
   my $dn_val = $box->getStat( -lower_replace_value   );
   my $up_val = $box->getStat( -upper_replace_value   );
   
   return $dataref unless( defined($dn_lim) or defined($up_lim) );
   
   my @data = @$dataref;
   
   if(defined $dn_lim) {
      foreach (@data) { $_ = $dn_val if($_ < $dn_lim) }
   }
   if(defined $up_lim) {
      foreach (@data) { $_ = $up_val if($_ > $up_lim) }   
   }
   return [ @data ];
}

 
# computeBoxData
# Given a boxdata object, a one dimensional array reference, and the moment calculation
# method, this method build a single box data object.
sub computeBoxData {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   # do not remove the shift's
   my ( $box, $moment_calc_method, $transformation) = @_;
   
   $box->emptyBox();  # make sure that the box data model is clear
                      # it is unlikely to actually contain data, but
                      # because of the complexity of the box data
                      # model, it is best to clear it out as errors
                      # would be extremely difficult to detect.

   $box->setStat( -moment_calc_method => $moment_calc_method);
   
   my $dataref = $box->getStat(-DATA);
      $dataref = $box->massageData_for_Detection_Limits($dataref);
   my $isLog10         = ( $transformation eq 'log10' ) ? 1 : 0 ;
   my $statistics      = &calcStats($dataref,$transformation);
   
   my %stats           = %$statistics;
   
   my @stat_name  =  qw(-number_samples
                        -min
                        -max
                        -median
                        -harmonic_mean
                        -geometric_mean
                        -lower_tercile   -upper_tercile
                        -lower_quartile  -upper_quartile
                        -lower_pentacile -upper_pentacile
                        -lower_decile    -upper_decile );
   foreach (@stat_name) { $box->setStat($_ => $stats{$_}, $isLog10) }
   
   
   # Calculate the moment statistics
   # which moment calculation method is to be used.
   my $mean = $stats{-mean};
   $box->setStat( -mean => $mean, $isLog10 );
   if( $moment_calc_method eq 'product' ) {
      # product moments have the following keys
      # -std_dev, -skew, -kurtosis   
      $box->setStat( -scale    => $stats{-std_dev},  $isLog10 );
      $box->setStat( -skew     => $stats{-skew},     $isLog10 );
      $box->setStat( -kurtosis => $stats{-kurt},     $isLog10 );

   }
   else {
      # linear (l-moments) have the following keys
      #  -l_scale, -tau3, -tau3                                        
      $box->setStat( -scale    => $stats{-l_scale}, $isLog10 );
      $box->setStat( -skew     => $stats{-tau3},    $isLog10 );
      $box->setStat( -kurtosis => $stats{-tau4},    $isLog10 );
   }
  
  
  # OUTLIERS
  # Fill up the outlier arrays
  my $uQ = $box->getStat(-upper_quartile);
  my $lQ = $box->getStat(-lower_quartile);
  
  if(defined $uQ and defined $lQ) {
     my @type1;
     my @type2;
     my $iq_rng =  $uQ - $lQ;
     my $l15    = 1.5*$iq_rng;
     my $l3     =   3*$iq_rng;
     my $t2l    = $lQ - $l15;
     my $t2u    = $uQ + $l15;
     my $t3l    = $lQ - $l3;
     my $t3u    = $uQ + $l3;
     foreach my $val (@$dataref) {
        push(@type2, $val), next if( $val <= $t3l );
        push(@type2, $val), next if( $val >= $t3u );
        push(@type1, $val), next if( $val <= $t2l and $val > $t3l );
        push(@type1, $val), next if( $val >= $t2u and $val < $t3u );
     }
     @type1 = sort { $a <=> $b } @type1;
     @type2 = sort { $a <=> $b } @type2;
     # Insert the outlier arrays into the box data model
     $box->setStat( -type1_outliers => [ @type1 ], $isLog10 );
     $box->setStat( -type2_outliers => [ @type2 ], $isLog10 );
  }
  $box->show('nodata');
  return $mean; # return the mean value of the data
}  

 
# DATA ACCESSING METHODS 
# getStat, return a named statistic from the box object.
sub getStat {
   my ($box, $statname) = ( shift, shift );
   return ( exists $box->{$statname} ) ? $box->{$statname} :
                                         "'$statname' IS NOT A ".
                                         "VALID KEY FOR BOX DATA";
}


# setStat, return success or failure on setting a box object.
sub setStat {
   my ($box, $statname, $value, $isLog10) = @_;
   if(not defined $isLog10 and ($statname ne '-moment_calc_method' ) ) {
      print STDERR "BoxPlotData.pm setStat needs to know what type ".
                   "of transformation to do\n";
      return 0;
   }
   if($isLog10 and defined $value) {
      # make the value to store undefined if the statistics were calculated
      # in logspace.  Remember that the box model must store values in 
      # real space so that the dynamic transformation between linear and
      # log scales can continue to work.  Shoot probability too, but
      # I certainly have not seen a box plot on a probability scale--very
      # interesting concept indeed.
      $value = ($statname ne '-scale')    ? undef :
               ($statname ne '-skew' )    ? undef :
               ($statname ne '-kurtosis') ? undef : 10**$value;
   }
   $box->{$statname} = $value, return 1 if( exists $box->{$statname} );
   return 0;  
}




# emptyBox, delete all data including the moment calculation method
sub emptyBox {
   my $box = shift;
   foreach my $key (keys %$box) {
      next if($key eq '-DATA'); # always want to preserve the raw data
      $box->{$key} = ( ref($box->{$key}) eq 'ARRAY' ) ? [ ] : undef;
   }
}

sub show {
   my ($box, $no_data, $as_single_string) = @_;
   
   return 0 if(not exists $::CMDLINEOPTS{'dumpboxes'}
                        and
               not $as_single_string);
   
   return "BoxPlotData.pm: Can not display the statistics as requested ".
          "because the keys of the box object are not equal to the length ".
          "of DataOrder array.\n" if(scalar(keys %$box) != scalar(@DataOrder));       
   if($as_single_string) {
      my $string = "BEGIN BOX DUMP: \n";
      # @DataOrder gives a more readable order of statistics
      foreach (@DataOrder) {  # foreach (sort keys %$box) {
         my $val = (defined $box->{$_}) ? $box->{$_} : 'undef';
         next if($_ eq '-DATA' and $no_data);
         if( ref $box->{$_} ) { 
            $string .= "       $_ => ";
            $string .= join(",", @{$box->{$_}} );
            $string .= "\n"; 
         }
         else {
            $string .= "       $_ => $val\n";
         }
      }
      $string .= "END BOX DUMP: \n";
      return $string;
   }
   else {
   
      if($::CMDLINEOPTS{'message'}) {
         print STDOUT "Statistics for $::CMDLINEOPTS{message}\n"; 
      }
      else {
         print STDOUT "BEGIN BOX DUMP: \n";
      }
      
      my $pad = "    ";
      # @DataOrder gives a more readable order of statistics
      foreach (@DataOrder) {  # foreach (sort keys %$box) { 
         my $key = &_prettyKey(substr($_,1));
         my $val = (defined $box->{$_}) ? $box->{$_} : 'not defined';
         next if($_ eq '-DATA' and $no_data);
         if( ref $box->{$_} ) { 
            print STDOUT $pad,"$key = ",join(", ", @{$box->{$_}} ),"\n"; 
         }
         else {
            $val = "Product moments were used." if($val eq 'product');
            print STDOUT $pad,(
                         (length $_ <=  9) ? pack( "A9", ucfirst $key) :
                         (length $_ <= 19) ? pack("A18", $key)         :
                                             pack("A21", $key)
                              )," = $val\n" ;
            if($key =~ m/min/io) { # Now compute the interquartile range
               my $iq1 = $box->{-lower_quartile}; # IQR is NOT contained
               my $iq2 = $box->{-upper_quartile}; # as a separate field in
                                                  # the box object.
               my $diff = (defined $iq1 and defined $iq2) ?
                                   ($iq2-$iq1) : 'not defined';
               print STDOUT
                    $pad,"IQR       = $diff\n".
                         "      (IQR calculated from the two quartiles)\n";
            }
         }
      }
      if($::CMDLINEOPTS{'message'}) {
         print STDOUT "\n";
      }
      else {
         print STDOUT "END BOX DUMP: \n" 
      }
      return 1;
   }
}

sub _prettyKey {
   my ($key) = @_;
   my @keys = split(/_/o, $key);
   $key = ucfirst( shift(@keys));
   map { $key .= " ".ucfirst($_) } @keys;
   return $key;   
}

1;
