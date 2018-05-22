package Tkg2::Math::KendallsTau;

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
# $Revision: 1.5 $

use strict;
use vars qw(@ISA @EXPORT_OK);
use Exporter;
use SelfLoader;
@ISA = qw(Exporter SelfLoader);
@EXPORT_OK = qw(Kendalls_Tau Theil_Line phash);

1;

#__DATA__

# Module for calculation of Kendall's Tau and
#   the Theil Line and related statistics.

sub Kendalls_Tau { &_route_em('kendall', @_) }

# Route the Kendalls_Tau and Theil_Line calls
# Usage: $type = 'kendall' or 'theil';
#        _route_em($type, [ @X ], [ @Y ] );
#        _route_em($type, [ [ x1, y1 ],
#                           [ x2, y2 ], . . . ] );
#        _route_em($type, @X );
#        _route_em($type, \@X);
sub _route_em {
  my $type = shift;
  my (@a1, @a2, $a1ref, $a2ref);
  if(@_ == 2) {
    ($a1ref, $a2ref) = ( shift, shift);
    return ($type eq 'kendall') ?
                         &_kendallsTau($a1ref, $a2ref) :
                         &_theilLine(  $a1ref, $a2ref) ;
  }
  elsif(ref($_[0]) eq 'ARRAY') {
    $a1ref = shift;
    if(ref($a1ref) eq 'ARRAY' and 
       ref($a1ref->[0]) eq 'ARRAY') { 
      # if incoming is array is LoL
      foreach my $list (@{$a1ref}) { 
        # build two arrays from LoL 
        push(@a1, $list->[0]);  # X values
        push(@a2, $list->[1]);  # Y values
      }
      return ($type eq 'kendall') ? 
                           &_kendallsTau(\@a1, \@a2) :
                           &_theilLine(  \@a1, \@a2) ;
    }
    else {
       # Array order is switched so the array indices 
       # become the X variable and the passed in data 
       # becomes the Y variable
       my @a1 = (0..$#$a1ref);
       return ($type eq 'kendall') ?
                            &_kendallsTau(\@a1, $a1ref) :
                            &_theilLine(  \@a1, $a1ref) ;
    }
  }
  else {
     my @a2 = @_;
     # Array order is switched so the array indices 
     # become the X variable and the passed in data 
     # becomes the Y variable.
     my @a1 =  (0..$#a2);
     return ($type eq 'kendall') ?
                            &_kendallsTau(\@a1, \@a2) :
                            &_theilLine(  \@a1, \@a2) ;
  } 
}

# Kendalls Tau: uses &_errorFunction and &_varTau
# Usage: &_kendallsTau(\@X,\@Y);
sub _kendallsTau {
   my ($array1ref, $array2ref) = @_;
   my @X = @$array1ref;
   my @Y = @$array2ref;
   return undef unless(@X == @Y);
   my ($n, $S) = ( scalar(@X), 0 );
   my (%Xties, %Yties);  # Track ties in X and Y
   for(  my $j = 0; $j <= $n-2; $j++) {
      for(my $k = $j+1; $k <= $n-1; $k++) {
         my $a1= $X[$j] - $X[$k];
         my $a2= $Y[$j] - $Y[$k];
         my $aa = $a1 * $a2;
         if($aa != 0) { $S += ($aa > 0) ? 1 : -1; }

         # track each tied group and number of ties in it
         $Xties{ $X[$j] }++ if( $a1 == 0 ); 
         $Yties{ $X[$j] }++ if( $a2 == 0 );  
      }
   }
   # compute variance of tau
   my $vartau = 0; # since we divide by var tau, setting to zero
                   # will trigger exceptions--this is good.
   if($n > 2) { # there is an n-2 division in the correction
                # so we must trap division by zero
      $vartau = &_varTau($n,\%Xties,\%Yties);  
   }
   if($n <= 2 or $vartau <= 0) { # need to trap sqrt of negatives
      # negative can come from a large amount of ties
      # in the event of negative variance, use the 
      # uncorrected version.  As best that I can tell,
      # the _varTau subroutine is ok, but should be
      # checked again?
      $vartau = $n*($n-1)*(2*$n+5)/18;
   }
   my $tau;
   if($n >= 2) {
      $tau = 2*$S / ($n*($n-1)); 
   }
   else {
      $tau = 0;
   }
   
   if($vartau <= 0) { # must be from a n=1 sample size, set to 1
      warn "KendallsTau: variance of Tau is zero--whoops, bad data?\n";
      $vartau = 1;
   }
   # The +1 or -1 adjustment is made because tau
   # can only take on values in steps of two
   my $z = ( ($S > 0) ? $S-1 : $S+1 ) / sqrt($vartau);
   
   # The first prob2tail is really the upper tail of the null
   # distribution.
   my $prob2tail = 0.5 * &_errorFunction( abs($z)/1.4142136 );
      $prob2tail *= 2; # double the upper tail to get REAL two-tail
   my ($probgt, $problt);
   if ($tau > 0 ) {
      $probgt = $prob2tail / 2;
      $problt = 1-$probgt;
   }
   else {
      $problt = $prob2tail / 2;
      $probgt = 1-$problt;
   }
   
   my $taustddev = sqrt($vartau);
   
   # Clean up the decimals and round the p-values to zero if
   # they are incredible small
   my @f = ($tau, $probgt, $problt, $prob2tail, $taustddev, $z);
   foreach my $f (@f) { $f = &_f(4,$f) }
   ($tau, $probgt, $problt, $prob2tail, $taustddev, $z) = @f;
      @f = ($probgt, $problt, $prob2tail);
   foreach my $f (@f) { $f = "0.000" if($f < 0.0005) }
   ($probgt, $problt, $prob2tail) = @f; 
   
   return { tau              => $tau,
            pval_tau_gt_zero => $probgt,
            pval_tau_lt_zero => $problt,
            pval_tau_ne_zero => $prob2tail,
            kendalls_score   => $S,
            sample_size      => $n,
            tau_std_dev      => $taustddev,
            standard_Z       => $z };
}
      
# Error Function: Numerical Recipes in FORTRAN
sub _errorFunction {
   my $x = shift;
   my $z = abs($x);
   my $t = 1/(1+0.5*$z);
   my @c = qw( 1.26551223  1.00002368  0.37409196  
               0.09678418 -0.18628806  0.27886807
              -1.13520398  1.48851587 -0.82215223  
               0.17087277 );
   my $erfcc = $t;
   $erfcc *= exp(-$z*$z-$c[0]+
                    $t*($c[1]+
                    $t*($c[2]+
                    $t*($c[3]+
                    $t*($c[4]+
                    $t*($c[5]+
                    $t*($c[6]+
                    $t*($c[7]+
                    $t*($c[8]+
                    $t* $c[9])))))))));
   return ($x < 0) ? 2-$erfcc : $erfcc;
}

# Compute variance of Kendall's Tau, used by &_kendallTau
sub _varTau {
   my ($n, $xtiesref, $ytiesref) = @_;
   my ($xsum1, $xsum2, $xsum3) = ( 0, 0, 0);
   my ($ysum1, $ysum2, $ysum3) = ( 0, 0, 0);
   my %xties = %$xtiesref;
   my %yties = %$ytiesref;
   foreach (keys %xties) {
      my $m   = $xties{$_};
      my $mm1 = $m   * (   $m-1 );
      $xsum1 += $mm1 * ( 2*$m+5 );
      $xsum2 += $mm1 * (   $m-2 );
      $xsum3 += $mm1;
   }
   foreach (keys %yties) {
      my $m   = $yties{$_};
      my $mm1 = $m   * (   $m-1 );
      $ysum1 += $mm1 * ( 2*$m+5 );
      $ysum2 += $mm1 * (   $m-2 );
      $ysum3 += $mm1;      
   }    
   my $nn1 = $n*($n-1);
   my $term1 = ( $nn1*(2*$n+5) - $xsum1 - $ysum1 ) / 18;
   my $term2 = ( $xsum2*$ysum2 ) / ( 9*$nn1*($n-2) );
   my $term3 = ( $xsum3*$ysum3 ) / ( 2*$nn1 );
   return $term1 + $term2 + $term3;
}

sub Theil_Line { _route_em('theil', @_) }

# Theil Line: use &_median and &_mean
# Usage: &_theilLine(\@X,\@Y);  
sub _theilLine {
   my ($array1ref, $array2ref) = @_;
   my @X = @$array1ref;
   my @Y = @$array2ref;
   return undef unless(@X == @Y);
   my ($n, $sum, @slopes) = ( scalar(@X), 0, () );    
   for(   my $i = 0  ; $i <= $n-2; $i++) {
      for(my $j =$i+1; $j <= $n-1; $j++) {
         my $denom = ($X[$j]-$X[$i]);
         next if($denom == 0);
         push(@slopes, ($Y[$j]-$Y[$i]) / $denom );
      }
   }
   return undef unless(@slopes); # if all X equal
   @slopes = sort { $a <=> $b } @slopes;
   # compute theil line
   my $theilslope  = _median(\@slopes);
   my $x50         = _median($array1ref);
   my $y50         = _median($array2ref);
   my $theilinter  = $y50 - $x50 * $theilslope;    
   # compute average slope and intercept, just because
   my $aveslope    = _mean(\@slopes);
   my $x_mean      = _mean($array1ref);
   my $y_mean      = _mean($array2ref);
   my $aveinter    = $y_mean - $x_mean*$aveslope;
   
   return { theil_slope         => $theilslope,
            theil_intercept     => $theilinter,
            x_median            => $x50,
            y_median            => $y50,
            ave_slope           => $aveslope,
            ave_slope_intercept => $aveinter,
            x_mean              => $x_mean,
            y_mean              => $y_mean};
}

# Generic utility subroutines
# Pretty print a hash reference
sub phash {
  foreach ( sort keys %{$_[0]} ) {
     print " $_ => "._f(4,$_[0]->{$_})."\n";
  }
}

# Control number formating
sub _f { sprintf("%0.".$_[0]."g", $_[1] ); }

# Compute median of an array reference.
sub _median {
   my @d = sort { $a <=> $b } @{ $_[0] };
   return $d[0] unless(@d >= 2);
   return (@d % 2) ? $d[@d/2] : ($d[@d/2 - 1]+$d[@d/2])/2;
}

# Compute mean of an array reference.
sub _mean {
   my ($arrayref) = @_;
   my $result;
   map { $result += $_ } ( @$arrayref );
   return $result / @$arrayref;
}

__END__

=head1 TREND ANALYSIS WITH PERL

B<by William H. Asquith>

B<Submitted to The Perl Journal>

B<January 3, 2000>

=head2 Introduction

Trend analysis, the detection and evaluation of trends in data, is a critically important task for many analysts across a broad range of fields including: economics, mathematics, medicine, programming, and science.  Types of questions asked and answered by trend analysis include: are global temperatures increasing, decreasing, or staying the same, are whale populations increasing or decreasing, is the deficit decreasing, have cancer rates decreased since the introduction of a new drug, has the annual stream flow of the Mississippi changed this century, and most important, is Perl use increasing?  Questions such as these are all extremely important and their answers can have wide ranging economic, political, and social implications.  The Perl question is especially important socially, as well as economically.


It is not the goal of this article to answer the questions presented, but instead to present some statistical techniques for performing trend analysis, the Perl way.  The reader is assumed to have some familiarity with statistics in general and specifically hypothesis testing.  The Perl code and statistical analysis presented is straightforward, simple to apply, and easy to interpret by lay people and experts alike.


Though the above questions encompass a wide spectrum of human interests and concerns, they all one thing in common.  Each question at its core is problem of correlation or more specifically, correlation of a variable with time (temporal correlation).  Temporal correlation is best described by the question, "Does the variable C<@X> have a relation with time?".  In order properly assess temporal correlation and answer the question, the statistical significance of the relation between C<@X> and time needs determination.


By statistical significance, we mean a relation whose probability of occurrence by random chance alone is sufficiently small that we can conclude that the relation observed between C<@X> is likely not do to random chance but do to some other, often unknown, cause.  If a statistically significant relation exists, it is then necessary to make an estimate of the trend.  After all even if we are certain of increasing Perl use, it is more important that the rate of increase be large rather than small.


The term 'trend analysis' is most commonly used in the sense of detecting whether a variable is a linear or nonlinear function of time (C<@Y>).  Trend analysis is often synonymous with time-series analysis, but this association is too general.  Time-series analysis is a wide and complex field often involving harmonic or spectral analysis, auto correlation, and long- and short-memory stochastic processes as well as the statistical tools presented in this paper.  Time-series analysis is not discussed further.  In this paper, trend analysis is the detection and evaluation of I<monotonic> trends of a variable with time.  Specifically, a variable C<@X> has a monotonic trend with C<@Y> if on average the values of C<@X> are constant or always increasing (decreasing) as C<@Y> either increases (decreases).


The focus of this article is on some presently un-Perlized(?) statistical tools to perform trend analysis that is appropriate for data sets that meet any of the following conditions the data is non-normally distributed, the data contains anomalous data or outliers, the data is censored data that is below a detection limit, or the data as had processing/data entry errors.  To demonstrate the statistical tools some hypothetical data sets have been created and are used in the Examples section.


=head2 Correlation and Pearson's r

As discussed in the Introduction, at its roots trend analysis is a problem of correlation.  Correlation measures the strength of the association between C<@X> and C<@Y>.  Though C<@Y> represents time here, C<@Y> is certainly not limited to it.  Three types of correlation statistics or coefficients are commonly used and measure correlation direction by their sign, measure correlation strength by their magnitude.  The correlation statistics are Pearson's r (C<$r>), Spearman's rho (C<$rho>), and Kendall's tau (C<$tau>).  Each is useful for measuring the relation between C<@X> and C<@Y>.  In practice, however, the three correlation coefficients are not equally applicable.  Additionally, each has its own scale of measure; values of the three correlation coefficients are not directly comparable.  This is much like the situation with Celsius and Fahrenheit.  Each is measured on a different scale, while at the same time each measures temperature.


C<$r> is the most widely known and used correlation coefficient for reasons dealing with classical (normal) statistical theory and the ubiquitousness of least-squares linear regression.  C<$r> plays a prominent role in both.  C<$r> measures the I<linear> association between C<@X> and C<@Y>, and most important for our trend analysis examples here, C<$r> is I<not resistant> to outliers in the data.  C<$r> is computed from the actual values of the data points or from a linearizing transformation of the data such as C<foreach @X { $_ = log($_) }>.  C<$r**2>, or 'R-squared' is often used as a regression diagnostic because it is a measure of goodness-of-fit.  An assumption that the data is normally distributed is required for C<$r> to be a meaningful correlation measure.  C<$r> use in censored data sets is very difficult.  From I<Mastering Algorithms in Perl>, the C<$r> is computed in listing 1.


=head2 Listing 1

   # Pearson's r, uses &covariance and &mean
   #  Usage: $r = correlation(\@X, \@Y);
   sub correlation {
      my ($array1ref, $array2ref) = @_;
      my ($sum1, $sum2);
      my ($sum1_squared, $sum2_squared);
      foreach (@$arrayref1) { $sum1 += $_;
                              $sum1_squared += $_**2 }
      foreach (@$arrayref2) { $sum2 += $_;
                              $sum2_squared += $_**2 }
      return (@$arrayref1**2) *
              covariance($array1ref, $array2ref) /
              sqrt( ( (@$arrayref1 * $sum1_squared) -
                      ($sum1**2) ) *
                    ( (@$arrayref2 * $sum2_squared) -
                      ($sum2**2) ) );
   }

   sub covariance {
      my ($array1ref, $array2ref) = @_;
      my ($i, $result);
      for ($i = 0; $i < @$array1ref; $i++) {
         $result += $array1ref->[$i]*
                    $array2ref->[$i]
      }
      $result /= @$array1ref;
      $result -= mean($array1ref) *
                 mean($array2ref);
   }

   sub mean {
      my ($arrayref) = @_;
      my $result;
      foreach (@$arrayref) { $result += $_ };
      return $result / @$arrayref;
   }


=head2 Nonparametric Statistics

The correlation statistics, C<$rho> and C<$tau>, differ from C<$r> in that they are nonparametric statistics.  Nonparametric statistics measure correlation based on the ranks of the data and not the data values themselves.  Because they are rank based, they exhibit several beneficial mathematical characteristics, particularly in non-normal data sets that make them preferable to C<$r>.  Non-normally distributed data sets are quite common in many fields including biology, geology, hydrology, and other natural sciences and engineering disciplines.


Application of C<$r> in situations non-normal data can be inappropriate because the squares of the data are computed (see listing 1).  This means that data with exceptionally large values compared to the rest of the data have a disproportionate influence on the calculation of the variances (computed in listing 1 without a separate subroutine) and covariance.  Exceptionally large values are common in highly-skewed data sets.


Log transformations of C<@X> and(or) C<@Y> often are done to reduce data skewness, hence the influence of large values.  However, log transformations (base e or 10) increase the influence of extremely small values (values close to zero), which can cause other problems.  Additionally, log transformations are not possible if the data have zero values or if the data are censored.


Although widely used by statisticians and other specialized disciplines, nonparametric statistics remain the ugly sister of classical statistics.  Many of people are entirely unfamiliar with them.  Nonparametric statistics however are worthy of attention.  A review of most general statistical text books will show, the Chi-squared, F-, t-, and Z-tests, and linear regression (correlation), but make no mention of their nonparametric competitors.  In fact many major universities do not even offer specific courses in nonparametric statistics, and many people performing statistical analysis are likely have had no formal training with them, including us Perl programmers.


In general, nonparametric statistics, including C<$rho> and C<$tau>, require few assumptions about the population from which C<@X> and C<@Y> data were derived, such as the assumption in classical statistics that the underlying populations are normally distributed.  Nonparametric statistics are easier to apply, easy to understand, and applicable to problems inappropriate for classical statistics, including (C<$r>).


Nonparametric statistics are based on ranks of the data and not the actual values.  To the uninformed it appears as if information has been thrown out.  While this is partially true, studies have repeatedly shown nonparametric statistics to be nearly as good as their classical counterparts when the normality assumption holds and better and sometimes vastly superior when the normal assumption does not.  The remainder of this article will briefly describe C<$rho> and C<$tau>, provide Perl code to compute them, and finally show some application examples.


=head2 Spearman's rho

C<$rho> is a rank correlation coefficient.  In calculating C<$rho>, the differences between data values ranked further apart are given more weight.  C<$rho> is C<$r> calculated on the ranks and not the data values.  C<$rho> is not commonly used because the large sample approximations and exact values of significance (p-values) can be quite different for sample sizes less than about 20.  This is not the case with C<$tau>.  Large sample approximations are computed by subroutine and exact values by table lookup.  For the ranks of C<@X> (C<@Rx>) and the ranks of C<@Y> (C<@Ry>), C<$rho> is computed in list 2.
   

=head2 Listing 2
   
   # Abbreviated Spearman's Rho;
   # Usage: $rho = spearmans_rho(\@Rx,\@Ry);
   #   @Rx and @Ry contain the ranks of the data.
   #   Ties between the X's and the Y's have been assigned
   #   their average ranks before calling the subroutine.   
   sub spearmans_rho {
      my @rankarray1 = @$_[0];
      my @rankarray2 = @$_[1];
      my ($sum, $n) = (0, @$rankarray1);
      for(my $i = 0; $i <= $n-1; $i++) {
         $sum += $rankarray1[$i] *
                 $rankarray2[$i]
      }
      $rho  = $sum - $n*( ($n+1) / 2 )**2;
      $rho /= $n*( $n**2 - 1 ) / 12;
      return $rho;
   }


C<$rho> is rank based, but the products of the ranks are used.  This means that C<$rho> can be undesirable because the product of two large ranks have more influence on the resulting sum.  C<$rho> is not discussed further here, though some of the discussion for C<$tau> certainly is relavent to C<$rho> too.  It is left to the reader to further study and apply C<$rho>.


=head2 Kendall's tau

C<$tau> is rank based as well, but uses scoring in its calculation and is therefore remarkably resistant to the influences of outliers.  Other benefits of C<$tau> include its use in censored data (data below a reporting limit), it measures I<all> monotonic correlations (linear or nonlinear), and finally, C<$tau> is invariant to monotonic power transformations, such as log, of either one or both variables.  Thus C<$tau> for C<@X> and C<@Y> is equal for C<@logX> and C<@logY>.  C<$tau> will be lower in value compared to C<$r> for the same I<linear> relation.  For example, for linear relations having C<$r> greater than about 0.9, C<$tau> will be greater than about 0.7.  Finally, a very important characteristic of C<$tau> for processing speed, the large sample approximation of significance levels for <$tau> are nearly identical to the exact values.  No extensive table lookup usually is required.


C<$tau> is defined as:

   Tau = 2*Prob{ (Xi-Xj)(Yi-Yj) > 0} - 1


If the two variables are independent, that is the variables are not correlated, then the probability (Prob) that the product of the difference between any two data values (i and j) is greater than zero is 1/2.  Thus, half of the time the slope of a line between 1 and 2 would be positive and the other half of the time the slope would be negative.  If C<@X> and <@Y> are independent then C<$tau> = 0.  C<$tau> and its significance can be calculated with the KenTau module in listing 3.  The C<$tau> methods are C<&Kendalls_Tau>, C<&_kendallstau>, C<&_errorFunction>, and C<&_varTau>.  C<&Kendalls_Tau> is the public interface.  The C<&_route_em> method provides the up-front parsing of three input styles.  The C<Theil_Line> and associated methods are discussed later.


=head2 Listing 3, the KenTau Module

  LIST MODULE TO THE THEIL LINE

=head2 Theil Line

Now that we have coded a module for C<$tau>, which will determine, or more appropriately determine within allowable statistical error that a trend exists in the data, it is useful to also estimate a linear trend through the data.  The Theil line provides a nonparametric, and therefore outlier resistant, estimate of a linear relation in the data.  The Theil line is related to C<$tau> and is commonly used inconjunction with it.

The Theil line methods are included in the C<KenTau> module.  The Theil line is a linear line following the usual C<$Y=$m*$X+$b>, in which C<$m> is a slope estimate and C<$b> is the y-axis intercept.  The slope of the Theil line is computed as the median of all defined slopes calculated from the data and the intercept is calculated by passing the line using the Theil slope through the median C<@X> and median C<@Y>.  The p-value for the slope of the Theil line is the same as the p-value for C<$tau>.  Unlike least-squares linear regression, the Theil line does not require the normality of the residuals for significant levels to be valid, and it is not strongly influenced by outliers.  The following methods (C<&Theil_Line>, C<&_theilLine>, C<&_median>) are also part of the C<KenTau> module shown in listing 3 and C<&Theil_Line> is the public interface.  As before, the C<&_route_em> method shown in listing 3 provides the up-front parsing of three input styles.

=head2 Listing 4, continuing the KenTau module in listing 3
  
 LIST REMAINDER OF KenTau module

=head2 Examples (note to editor, run the Perl code to generate rest of section)

Application of the KenTau module is illustrated by the program in listing 5.  The program has three different examples that call the Kendalls_Tau and Theil_Line methods with different data arrangements.  

=head2 List 5, using the KenTau module

   package main;
   # make up some data
   # Two arrays of X data
   my @X  = qw(   9  190 2390  223  20  239
                361  400  340 1349 870);
   my @X2 = qw( 44.4  45.9  -41.9  53.3  0
               -44.1 -50.7  -45.2  -0.1 );

   my @T  = ( 1990..2000 );    # Years
   
   # time and data mixed together
   my @TX = ( [ 1900,   56 ], [ 1901,  19 ], [ 1902,  290 ],
              [ 1903,  223 ], [ 1904,  20 ], [ 1905, 99999],
              [ 1906,  361 ], [ 1907, 400 ], [ 1908,  340 ],
              [ 1909, 1349 ], [ 1910,  87 ] );
              
   print "EXAMPLE 1\n";
   phash( KenTau::Kendalls_Tau(\@T, \@X) );
   phash( KenTau::Theil_Line(\@T, \@X) );
   print "\n";
   
   print "EXAMPLE 2a\n";
   phash( KenTau::Kendalls_Tau(\@TX) );
   phash( KenTau::Theil_Line(\@TX) );
   print "\n";
   
   print "EXAMPLE 2b again with \$TX[5]->[1]=99\n";
   $TX[5]->[1] = 99;
   phash( KenTau::Kendalls_Tau(\@TX) );
   phash( KenTau::Theil_Line(\@TX) );   
   print "\n";
   
   print "EXAMPLE 3\n";
   phash( KenTau::Kendalls_Tau(\@X2) );
   phash( KenTau::Theil_Line(\@X2) );
   print "\n";
   
   # Generic utility subroutines
   # Pretty print a hash reference
   sub phash {
     foreach ( sort keys %{$_[0]} ) {
        print " $_ => "._f(4,$_[0]->{$_})."\n";
     }
   }
  
   # Control number formating, called by &phash
   sub _f { sprintf("%.".shift()."g", shift() ); }
   
   exit;
   __END__

NOW INSERT THE OUTPUT FROM THE PERL CODE BELOW

=cut

   package main;
   # make up some data
   # Two arrays of X data
   my @X  = qw(   9  190 2390  223  20  239
                361  400  340 1349 870);
   my @X2 = qw( 44.4  45.9  -41.9  53.3  0
               -44.1 -50.7  -45.2  -0.1 );

   my @T  = ( 1990..2000 );    # Years
   
   # time and data mixed together
   my @TX = ( [ 1900,   56 ], [ 1901,  19 ], [ 1902,  290 ],
              [ 1903,  223 ], [ 1904,  20 ], [ 1905, 99999],
              [ 1906,  361 ], [ 1907, 400 ], [ 1908,  340 ],
              [ 1909, 1349 ], [ 1910,  87 ] );
              
   print <<HERE1_1;

EXAMPLE 1
The \@X data is tested for correlation with the eleven years
contained in \@T.  Thus, $T[0] is paired with $X[0], $T[1]
is paired with $X[1], and so on.  Running the code for
example 1, we get:

HERE1_1
   
   print " Kendalls_Tau:\n";
   phash( KenTau::Kendalls_Tau(\@T, \@X) );
   print "and\n Theil_Line:\n";
   phash( KenTau::Theil_Line(\@T, \@X) );

   print <<HERE1_2;

Example 1 discussion:
A definitions of each of the hash keys is required.  For the
KenTau::Kendalls_Tau hash:
  kendalls_score   => The scoring for Kendall's Tau
  pval_tau_gt_zero => The p-value with the alternative
                      hypothesis that Tau is greater than
                      zero.
  pval_tau_lt_zero => The p-value with the alternative
                      hypothesis that Tau is less than zero.
  pval_tau_ne_zero => The p-value with the alternative
                      hypothesis that Tau is not equal to
                      zero.
  sample_size      => Size of passed in list.
  standard_Z       => The usual standard normal deviate of
                      tau.
  tau              => Kendall's Tau
  tau_std_dev      => Standard deviation of Tau.
For the KenTau::Theil_Line hash:
 ave_slope           => The average slope of all the
                        pair-wise slopes computed from the
                        data (not discussed in text).
 ave_slope_intercept => The y-intercept of the line defined
                        by the average slope all the
                        pair-wise slopes computed from the
                        data (not discussed in text).
 theil_intercept     => The y-intercept of the Theil line.
 theil_slope         => The slope of the Theil line.s

For this example, Kendall's tau is positive, which indicates an increasing trend of X with time.  The p-values are small for a positive trend (0.0146) here for the trend not equalling zero (0.0293).  Thus, we can conclude that there is a positive trend in time at a 0.015 significance level.
Significance levels less than 0.10 or 0.05 are commonly
used.
HERE1_2

   print <<HERE2_1;

EXAMPLE 2a
The \@TX list of lists (LoL) contains pairs of data.  This
data set has an enormous outlying value (99999) and even
without this value the range of the X variable remains large
(20 to 1349).  This is a situation in which the usual
correlation coefficient would be inappropriate.

HERE2_1
   
   print " Kendalls_Tau:\n";
   phash( KenTau::Kendalls_Tau(\@TX) );
   print "and\n Theil_Line:\n";
   phash( KenTau::Theil_Line(\@TX) );
     
   print <<HERE2_2;

Example 2a discussion:
Kendall's tau (0.346) is positive, which indicates an
increasing trend of X with time.  However, the p-value,
though small, is not small enough to strongly conclude that
trend in this data exists.

HERE2_2


   print <<HERE2_3;
   
EXAMPLE 2b
The robustness or stability of Tau is demonstrated when
99999 is changed to 99 and the analysis rerun.  Tau actually
increases to 0.418 and the p-value for an increasing trend
drops to 0.0434, which is small enough to conclude that a
trend exists.  The usual corrlation coefficient changes from about 4.02E-05 with the 99,999 data value to 0.25 with the
99 data value.  A percent change of about 622,000 percent
compared to the percent change of Tau of about 20 percent.

HERE2_3
   
   $TX[5]->[1]=99;
   print " Kendalls_Tau:\n";
   phash( KenTau::Kendalls_Tau(\@TX) );
   print "and\n Theil_Line:\n";
   phash( KenTau::Theil_Line(\@TX) );   
   
   print <<HERE3_1;

EXAMPLE 3
In the final test, a simple array of X data is used and the
index of the array elements provides a time representation.

HERE3_1
 
   print " Kendalls_Tau:\n";
   phash( KenTau::Kendalls_Tau(\@X2) );
   print "and\n Theil_Line:\n";
   phash( KenTau::Theil_Line(\@X2) );

   print <<HERE3_2;
   
Example 3 discussion:   
Kendall's tau (-0.444) is negative, which indicates a
decreasing trend of X with time.  Time here is the array
index.  The p-value is smaller than 0.05, so we can conclude
that a strong downward trend exists.  The Theil line, not
previously described in these examples, provides a linear
estimate of this downward trend.  The Theil slope is -8.64
per unit of time (one array index) and the intercept at time
zero is 34.46.  There are nine elements to this array; the
tenth element can be estimated using the Theil line as
(34.46-8.64*9) = -43.3, recall Perl's use of zero as the
first array index.

HERE3_2

   # Generic utility subroutines
   # Pretty print a hash
   sub phash {
     foreach ( sort keys %{$_[0]} ) {
        print " $_ => "._f(4,$_[0]->{$_})."\n";
     }
   }
  
   # Control number formating, called by &phash
   sub _f { sprintf("%.".shift()."g", shift() ); }
   
   exit;
   __END__
   
=head2 Conclusion

The example Perl script illustrates that Kendall's tau and the Theil line are easy to compute, use, and demonstrate that these statistics can be used for trend analysis in highly non-normally distributed data.  The KenTau module is very compact for its power and demonstrates how easily Perl can be used to statistical analysis without resorting to either an arcane statistics library or commercial software.  Finally, these statistics also can be used in general correlation analysis and not just trend analysis.

=head2 References

For interested readers the following references are valuable and highly recommended.  I<Nonparametric Statistical Methods> is a comprehensive and stand alone book on nonparametric statistics including Kendall's Tau and the Theil line and remains in print.  I<Numerical Recipes in FORTRAN> provided the foundation for several of the subroutines presented here.

Helsel, D.R., and Hirsch, R.M., 1995, Statistical Methods in Water Resources: Amsterdam, Elsevier, 529 p.

Hollander, M., and Wolfe, D.A., 1973, Nonparametric Statistical Methods: New York, John Wiley, 503 p.

Orwant, J. Hietaniemi, J. and MacDonald J., 1999, Mastering Algorithms with Perl: O'Reilly and Associates Inc., Sebastopol, CA, 684 p.

Press, W.H., Teukolsky, S.A., Vetterling, W.T., and Flannery, B.P., 1992, Numerical Recipes in FORTRAN: Cambridge University Press, 963 p.

=cut
