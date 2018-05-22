package Tkg2::Math::CalcStatistics;

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
# $Date: 2002/08/07 18:33:58 $
# $Revision: 1.18 $

use strict;

use Exporter;
use SelfLoader;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw( calcStats
                 calcStats_Linear
                 calcStats_Log10
                 ProductMoments
                 LinearMoments
                 Median
                 generateOrderStatistics
                 getOrderStatistics
                 getLower_O_Stat
                 getUpper_O_Stat
                 HarmonicMean
                 GeometricMean
                 Mean
                 OrganicCorrelationLine
                 SolveMXplusB
                 computeCiles
               ); 

use constant ONE => scalar 1; 
use constant TWO => scalar 2; 

# using the bench marking module, wha has determined that this is the
# fastest construction for log10 calculations. 
use constant logof10 => scalar log(10); 
sub log10 { ($_[0] <= 0) ? undef : log($_[0])/logof10; }


__DATA__


sub calcStats_Linear { return &getStats(@_,'linear') }
sub calcStats_Log10  { return &getStats(@_,'log10' ) }

sub calcStats {
   my $dataref = shift;
   my $isLog10 = shift;
      $isLog10 = ($isLog10 =~ /log/o ) ? 1 : 0;
   my $stats = { };
   # Determine easy statistics from sorted data
   my @tmpdata = sort { $a <=> $b } @$dataref;
   
   # Now fill up a data array for actual calculations depending upon
   # the type of transformation desired.
   my @data;
   if($isLog10) {
      foreach (@tmpdata) {
         my $logdata = log10($_);
         next unless(defined $logdata);
         push(@data, $logdata);
      }
   }
   else {
      @data = @tmpdata
   }
   
   # Begin setting the easy statistics
   my $ns;
   $stats->{-number_samples} = $ns = scalar(@data);
   $stats->{-min}            = $data[0];
   $stats->{-max}            = $data[$#data];
   $stats->{-median}         = &Median($dataref); 
   $stats->{-harmonic_mean}  = &HarmonicMean(  $dataref );
   $stats->{-geometric_mean} = &GeometricMean( $dataref );

   if(not defined $stats->{-min} or not defined $stats->{-max}) {
     warn "Number of samples == $ns\n";
     print "@data\n";
     return $stats;
   }
 
   # Calculate the moment statistics
   # which moment calculation method is to be used.
   # Product Moments
   my $moments = &ProductMoments($dataref);
   my %moments = %$moments;  
   foreach (keys %moments) {
      $stats->{$_} = $moments{$_};
   }

   # L-Moments
      $moments = &LinearMoments($dataref,'nosort');
      %moments = %$moments;  
  
   foreach  (keys %moments) {
      if(not defined $stats->{-mean}) {
         # There is likely a data problem if the any of the moments
         # are not defined.  We will go ahead and load them 
         # like every thing is ok, but bypass the next conditional
         # in this loop to trap an undef variable warning message.
         $stats->{$_} = $moments{$_};
         next;
      }
      $stats->{$_} = $moments{$_};
      if($_ eq '-mean' and $stats->{-mean} != $moments{-mean} ) {
         print STDERR "getStats: SERIOUS WARNING Mean by product moments ".
                      "does not equal the mean by the L-moments\n".
                      "PMean = $stats->{-mean}\n".
                      "LMean = $stats->{-mean}\n";
      }
      
   }

  
   # do not use dataref, but use the guarenteed presorted @data
   &_actually_compute_order_statistics($stats, \@data); 

   return $stats;
}

sub _actually_compute_order_statistics {
   my ($stats, $dataref) = @_;
   my $ns = scalar(@$dataref);
   &_order_statistics_by_array_position($stats,$dataref,'nosort');
   return;
   
   # The following logic was commented out on July 16, 2002 by
   # William H. Asquith following the final discovery of inconsistent
   # O-stat derived ciles compared to array position.  The array
   # position now supports linear interpolation for the large
   # sample size (see 1000 in the conditional below) is not needed.
   # This new solution apparently is consistent with USGS 
   #   Branch of Systems Analysis Technical Memorandom 89.01
   #if($ns < 1000) {
   #   # ORDER STATISTICS
   #   #   By using order statistics to compute the quartiles and
   #   #   deciles of the distribution, the arbitrary selection of
   #   #   plotting positions and interpolation is not necessary.
   #   #
   #   # Compute order statistics using O-statistics to extract the 
   #   my $ostats = &generateOrderStatistics( $dataref, 'nosort');
   #   OSTATS: {
   #      last OSTATS unless($ns >= 2);
   #      $stats->{-lower_tercile}   = &getLower_O_Stat($ostats, 2 );
   #      $stats->{-upper_tercile}   = &getUpper_O_Stat($ostats, 2 );
   #  
   #      last OSTATS unless($ns >= 3);
   #      $stats->{-lower_quartile}  = &getLower_O_Stat($ostats, 3 );
   #      $stats->{-upper_quartile}  = &getUpper_O_Stat($ostats, 3 );
   # 
   #      last OSTATS unless($ns >= 4);
   #      $stats->{-lower_pentacile} = &getLower_O_Stat($ostats, 4 );
   #      $stats->{-upper_pentacile} = &getUpper_O_Stat($ostats, 4 );
   #
   #      last OSTATS unless($ns >= 9);
   #       $stats->{-lower_decile}    = &getLower_O_Stat($ostats, 9 );
   #      $stats->{-upper_decile}    = &getUpper_O_Stat($ostats, 9 );
   #
   #      last OSTATS unless($ns >= 99);
   #      $stats->{-lower_centacile} = &getLower_O_Stat($ostats, 99);
   #      $stats->{-upper_centacile} = &getUpper_O_Stat($ostats, 99);
   #   }
   #}
   #else {
   #   # revert to array order for calculation of order statistics
   #   # for large samples.
   #   &_order_statistics_by_array_position($stats,$dataref,'nosort');
   #}
}

sub _order_statistics_by_array_position {
   my ($stats, $dataref, $needsort) = ( shift, shift, shift);
   $needsort = ($needsort and $needsort eq 'nosort') ? 0 : 1;
   my @data = @$dataref;
   
   # User is responsible for calling with the proper
   # sorting switch.  The data array must be sorted
   # in ascending order.
   @data = sort { $a <=> $b } @data if($needsort);
   
   ($stats->{-lower_tercile},
    $stats->{-upper_tercile})  = &computeCiles(\@data,0,'tercile');
    
   ($stats->{-lower_quartile},
    $stats->{-upper_quartile})  = &computeCiles(\@data,0,'quartile'); 
   
   ($stats->{-lower_pentacile},
    $stats->{-upper_pentacile}) = &computeCiles(\@data,0,'pentacile');
   
   ($stats->{-lower_decile},   
    $stats->{-upper_decile})    = &computeCiles(\@data,0,'decile');
   
   ($stats->{-lower_centacile},
    $stats->{-upper_centacile}) = &computeCiles(\@data,0,'centacile');   
}


sub computeCiles {
  my ($dataref, $needsort, $ciletype) = @_;
  my @data = @$dataref;
   
  # User is responsible for calling with the proper
  # sorting switch.  The data array must be sorted
  # in ascending order.
  @data = sort { $a <=> $b } @data if($needsort);

  my $n  = scalar(@data); # length of the array
  my $n1 = $n+1;
  
  $ciletype ||= 'quartile'; # default
  
  my $cile = ($ciletype =~ /median/io)    ? 0.5  :
             ($ciletype =~ /tercile/io)   ? 1/3  :
             ($ciletype =~ /quartile/io)  ? 0.25 :
             ($ciletype =~ /pentacile/io) ? 0.2  :
             ($ciletype =~ /decile/io)    ? 0.1  :
             ($ciletype =~ /centacile/io) ? 0.01 : "not defined";
             
  if($ciletype eq "not defined") {
    warn "computeCiles: Cile type is not tercile, quartile, pentacile, ",
         "              decile, or centacile\n";
    return undef;
  }
  
  return undef if(($ciletype =~ /tercile/io   and $n <   3) or
                  ($ciletype =~ /quartile/io  and $n <   4) or
                  ($ciletype =~ /pentacile/io and $n <   5) or
                  ($ciletype =~ /decile/io    and $n <  10) or
                  ($ciletype =~ /centacile/io and $n < 100)    );
    
  my ($l,$h)     = ($n1*$cile,$n1*(1-$cile));
  my ($lo,$hi)   = (int($l), int($h));
  my ($lof,$hif) = ($l - $lo, $h - $hi);
  
  # there is an addition of -1 in the index because Perl is 0 first enter
  # array based
  my $lowcile  = $data[$lo-1] + $lof*($data[$lo] - $data[$lo-1]);
  my $highcile = $data[$hi-1] + $hif*($data[$hi] - $data[$hi-1]);
  
  return ($lowcile, $highcile);
}

# ORDER STATISTICS
# generateOrderStatistics
# Calculate the O-statistics.  Given a data array that can be
# presorted, call sub with false second parameter, or an unsorted
# array, call sub with true second parameter, this subroutine
# returns the O-statistic matrix.  The individual O-stat arrays
# are retrieved from the O-statistic matrix using retrieveOrderStatistics
# $ref = retrieveOrderStatistics(generateOrderStatistics(\@data),1);
# print "THE MEAN OF THE DATA = $ref->[0]\n";
#    The O-statistics are the expectations of the usual order statistics
sub generateOrderStatistics {
   my ($dataref, $needsort) = ( shift, shift);
   $needsort = ($needsort and $needsort eq 'nosort') ? 0 : 1;
   my @X = @$dataref;
   my @OX;  
   
   # User is responsible for calling with the proper
   # sorting switch.  The data array must be sorted
   # in ascending order.
   @X = sort { $a <=> $b } @X if($needsort);
   
   my $n = scalar(@X); # size of data   
   # Fill O-statistics array at order $n with the data
   $OX[$n] = [ @X ];  # create new anonymous array
   
   #  r        d
   #  _ |_3____2_____1__  TEST EXAMPLE
   #  0 | 1   5/3    3
   #  1 | 3  13/3
   #  2 | 5

   # COMPUTE THE O-STATISTICS OF ORDER (n-1) TO 0
   # (see equation 2.3 in Kaigh, W.D., and Driscoll, M.F., 1987,
   # The American Statistician, vol. 41, no. 1, pp. 25-32)
   foreach my $d (reverse (1..($n - ONE)) ) {
      foreach my $r (0..($d - ONE)) {
         my $d1 = $d + ONE;
         my $X1 = $OX[$d1][$r];
         my $X2 = $OX[$d1][$r + ONE];
         $OX[$d][$r] = ( (($d-$r) * $X1) + (($r+1) * $X2) ) / ($d+1);
      }
   }
   return \@OX;   
}

sub getLower_O_Stat { return &getOrderStatistics(@_,'lower') }
sub getUpper_O_Stat { return &getOrderStatistics(@_,'upper') }

sub getOrderStatistics {
   my ( $OXref, $order, $lowup) = @_;
   if($order < 1 or $order >= @$OXref) {
      #print STDERR "getOrderStatistics: Retrieval order '$order' ".
      #             "can not be less than 1 or greater than length of the O-statistics ".
      #             "array which is ",scalar(@$OXref),".\n";
      return undef;
   }
   elsif($lowup) {  # values should be either 'lower' or 'upper'
      return ( $lowup eq 'lower') ? $OXref->[$order]->[0] :
                                    $OXref->[$order]->[ $#{$OXref->[$order]} ];
   }
   else {         
      return $OXref->[$order];
   }
}
### END ORDER STATISTICS SECTION



sub HarmonicMean {
   my $dataref = shift;
   my $sum;
   my $count = scalar(@$dataref);
   return undef if($count == 0); # trap a no data condition
   
   foreach my $val (@$dataref) {
      my $tmp;
      eval { $tmp = ONE/$val }; 
      return undef if($@); # must have been a division by zero solution
      $sum += $tmp;
   }
   $sum /= $count;
   return ONE/$sum;
}


sub GeometricMean {
   my $dataref = shift;
   my $tmp = 1;
   map { $tmp *= $_ } @$dataref;
   my $count = scalar(@$dataref);
   # trap for roots of negative numbers and for no data at all
   return ($count == 0 or $tmp < 0) ? undef : ($tmp)**( ONE / $count);
}

# Compute median of an array reference.
sub Median {
   my @d = sort { $a <=> $b } @{ $_[0] };
   return undef unless(@d > TWO); # trap undef variable warning
   return (@d % TWO) ? $d[@d/TWO] : ($d[@d/TWO - ONE]+$d[@d/TWO])/TWO;
}

# Compute mean of an array reference.
sub Mean {
   my ($arrayref) = @_;
   my $result;
   map { $result += $_ } ( @$arrayref );
   return $result / @$arrayref;
}

sub LinearMoments { 
# DIRECT L-MOMENT CALCULATION 
# adopted from Q.J. Wang, Direct sample estimators of
# L-moments, Water Resour. Res., 32(12), 3617-3619
# and modified for T5 via email from Dr. Wang 
# 07/06/1998.  Routine ported from FORTRAN to Perl 10/04/1998
# Pass data array into routine and routine returns the L-moment array
#   @L_moment contains the mean, L-scale, Tau3, Tau4, and Tau5
  my ( $dataref, $needsort) = @_;
  $needsort = ($needsort and $needsort eq 'nosort') ? 0 : 1;
 
  my ( @L_moments) = ();
  my ( $n, $i, $iold );
  my ( $L1,$L2,$L3,$L4,$L5 );
  my ( $CL1,$CL2,$CL3,$CL4 );
  my ( $CR1,$CR2,$CR3,$CR4 );
  my ( $C1,$C2,$C3,$C4,$C5 );
  my(@X) = @$dataref;					              # dereference the passed scalar
  ($L1,$L2,$L3,$L4,$L5) = (0,0,0,0,0);  # initialized values which will show
  ($C1,$C2,$C3,$C4,$C5) = (0,0,0,0,0);  # an uninitialized value warning  
  ($CL1,$CL2,$CL3,$CL4) = (0,0,0,0);
  ($CR1,$CR2,$CR3,$CR4) = (0,0,0,0);
  $n = @X;								# determine length of array

  if(not $n) {
     print STDERR "CalcStatistics::LinearMoments--Yipes undefined data\n";
     return { -mean => undef, -l_scale => undef,
              -tau3 => undef, -tau4    => undef, -tau5 => undef };
  }
  
  # First need to detemine whether all the data values are identical
  my $firstval = $X[0];  # initialize the first value in array
  my $all_equal = 1;     # flag set to yes as an initial guess
  foreach my $val (@X) {	
     next if($val == $firstval); # if equal, go to next one
     $all_equal = 0;             # at least one is different, ok to continue
     last;
  }
  if($all_equal) {  # always compute the mean 
       return { -mean => &Mean($dataref), -l_scale => 0,
                -tau3 => undef, -tau4 => undef, -tau5 => undef };
  }
   
  # go ahead and sort the array 
  @X = sort { $a <=> $b } (@X) if($needsort);
  
  # Use the O-statistics subroutine to calculated whatever L-moments
  # that are possible with the given sample size.
  # This section needs further development--1/29/1999
  if($n < 5) {
     my $mean = &Mean($dataref);
     my ($lscale, $tau3, $tau4, $tau5);
     my $ostats = &generateOrderStatistics( \@X, 'nosort');
     CHECK: {
       my $o;
       my @o;
       last CHECK if($n == 1);
        $o = &getOrderStatistics($ostats,2);   @o = @$o;
        $lscale = 0.5*($o[1] - $o[0]);   
       
       last CHECK if($n == 2);
        $o = &getOrderStatistics($ostats,3);   @o = @$o;
        $tau3 = (1/3)*($o[2] - 2*$o[1] + $o[0]);
        $tau3 /= $lscale;
        
       last CHECK if($n == 3);
        $o = &getOrderStatistics($ostats,4);   @o = @$o;
        $tau4 = (1/4)*($o[3] - 3*$o[2] + 3*$o[1] - $o[0]);
        $tau4 /= $lscale;
        
       last CHECK if($n == 4);
        $o = &getOrderStatistics($ostats,5);   @o = @$o;
        $tau5 = (1/5)*($o[4] - 4*$o[3] + 6*$o[2]
                             - 4*$o[1] +   $o[0] );
        $tau5 /= $lscale;
     }
     my $moments = {
                     -mean    => $mean,
                     -l_scale => $lscale,
                     -tau3    => $tau3,
                     -tau4    => $tau4,
                     -tau5    => $tau5
                   };
     return $moments;
  }

  # Sample size is greater than 5 so proceed with first 5 L-moment calculation 
  foreach my $i (1..$n) {
    $CL1 = $i-1;
    $CL2 = $CL1 * ($i-1-1) / 2;
    $CL3 = $CL2 * ($i-1-2) / 3;
    $CL4 = $CL3 * ($i-1-3) / 4;
    $CR1 = $n-$i;
    $CR2 = $CR1 * ($n-$i-1) / 2;
    $CR3 = $CR2 * ($n-$i-2) / 3;
    $CR4 = $CR3 * ($n-$i-3) / 4;     
    $L1 += $X[$i-1];
    $L2 += $X[$i-1] * ($CL1 - $CR1);
    $L3 += $X[$i-1] * ($CL2 - 2*$CL1*$CR1 + $CR2);
    $L4 += $X[$i-1] * ($CL3 - 3*$CL2*$CR1 + 3*$CL1*$CR2 - $CR3);
    $L5 += $X[$i-1] * ($CL4 - 4*$CL3*$CR1 + 6*$CL2*$CR2
                            - 4*$CL1*$CR3 + $CR4);    
  }
  
  $C1 = $n;
  $C2 = $C1 * ($n-1) / 2;
  $C3 = $C2 * ($n-2) / 3;
  $C4 = $C3 * ($n-3) / 4;
  $C5 = $C4 * ($n-4) / 5;
  $L1 = $L1 / $C1;
  $L2 = $L2 / $C2 / 2;
  $L3 = $L3 / $C3 / 3;
  $L4 = $L4 / $C4 / 4;
  $L5 = $L5 / $C5 / 5;
  
  my $moments = {
                  -mean    => $L1,
                  -l_scale => $L2,
                  -tau3    => $L3 / $L2,
                  -tau4    => $L4 / $L2,
                  -tau5    => $L5 / $L2
                };
  return $moments;
}      
  


sub ProductMoments {
  my $dataref = shift;
  my @X = @$dataref;
  my $sumM;
  my $n = @X;
  if(not $n) {
     print STDERR "CalcStatistics::ProductMoments--Yipes undefined data\n";
     return {-mean=>undef, -std_dev=>undef, -skew=>undef, -kurt=>undef };
  }
  foreach my $v (@X) { $sumM += $v } 
  my $mean = $sumM/$n;
  
  my ($sumSTD, $sumSKW, $sumKUR) = (0, 0, 0);  
  foreach my $v (@X) {
    $sumSTD += ($v-$mean)**2;
    $sumSKW += ($v-$mean)**3;
    $sumKUR += ($v-$mean)**4;
  }
  
  my ($stdev,$skew,$kurt);
  CHECK: {
    last CHECK if($n == 1);
     $stdev = ($sumSTD/($n-1))**0.5;
    last CHECK if($n == 2 or $stdev == 0); # division by zero protection
     $skew = $n*($sumSKW)/(($n-1)*($n-2)*$stdev**3);
    last CHECK if($n == 3);
     $kurt = (($n*($n+1))/(($n-1)*($n-2)*($n-3)))*($sumKUR/($stdev**4));
     # $kurt = $kurt-(3*($n-1)**2)/(($n-2)*($n-3));  # for excesses kurt 
  }
  
  my $moments = {
                  -mean    => $mean,
                  -std_dev => $stdev,
                  -skew    => $skew,
                  -kurt    => $kurt
                }; 
  return $moments;
}


# Solve the well know equation for a line Y = m*X + b
sub SolveMXplusB { my ($m, $b, $x) = @_; return $m*$x + $b; }

# Compute the OrganicCorrelationLine
#  The slope is the ratio of the two standard deviations, but
#   we compute the standard deviation with L-moments and the
#   known multiplication by root of pi is not required.
#  The intersept is choosen such that the line passes through
#   the mean of the X and Y values.
#  The subroutine requires an array reference of the X values
#   and array reference of the Y values.
#  The returned list includes:
#    slope, intersept, meanXvalue, meanYvalue, XL-scale, YL-scale
sub OrganicCorrelationLine {
  my ($X, $Y) = @_;
  my $str = "DIED: OrganicCorrelationLine:";
  die "$str X array is undefined or has less than 2 elements\n"
          if(not defined $X or @$X < 2);
  die "$str Y array is undefined or has less than 2 elements\n"
          if(not defined $X or @$X < 2);
  die "$str Arrays lengths are different\n" if(@$X != @$Y);
  
  my $xlm = LinearMoments($X,'needs sorting');
  my $ylm = LinearMoments($Y,'needs sorting');
  my ($xm, $ym) = ($xlm->{-mean},    $ylm->{-mean}   );
  my ($xs, $ys) = ($xlm->{-l_scale}, $ylm->{-l_scale});
  
  return ('inf',undef) if($xs == 0); # trap division by zero
  
  my $m = $ys / $xs;    # slope
  my $b = $ym - $m*$xm; # intersept
  return ($m, $b, $xm, $ym, $xs, $ys);
}


1;
   
__END__

#!/usr/bin/perl -w
BEGIN { # to get the tkg2 path onto @INC
   use File::Basename;  # need the &dirname and &basename functions
   $::TKG2_ENV{-TKG2HOME} = &dirname($0);  # for Asquith development
   unshift(@INC, $::TKG2_ENV{-TKG2HOME});
}   

use Tkg2::Math::CalcStatistics qw( getStats );


my @x = ( -1, 4, 41, 23, 23, 65, 20, 3, 9, 10, 14);
my $s = &getStats(\@x);
map { print STDOUT "$_ => $s->{$_}\n" } sort keys %$s;

print STDOUT "Catagory  Value\n";
foreach (qw(-max
            -upper_decile
            -upper_pentacile
            -upper_quartile
            -upper_tercile
            -median
            -mean
            -geometric_mean
            -harmonic_mean
            -lower_tercile
            -lower_quartile
            -lower_pentacile
            -lower_decile
            -min ) ) {
   next unless(defined $s->{$_});
   print "$_   $s->{$_}\n";            
}
             
