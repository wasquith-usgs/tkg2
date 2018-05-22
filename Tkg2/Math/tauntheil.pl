#!/usr/bin/perl -w

=head1 LICENSE

 This program is authored by the enigmatic William H. Asquith.
     
 This program is absolutely free software; 

 Author of this software makes no claim whatsoever about suitability,
 reliability, editability or usability of this product. If you can use it,
 you are in luck, if not, I should not be and can not be held responsible.
 Furthermore, portions of this software were
 developed by the Author as an employee of the U.S. Geological Survey
 Water-Resources Division, neither the USGS, the Department of the
 Interior, or other entities of the Federal Government make any claim
 whatsoever about suitability, reliability, editability or usability
 of this product.

=cut

# $Author: wasquith $
# $Date: 2002/12/03 15:18:02 $
# $Revision: 1.7 $


use strict;
use vars qw(@X @Y $TAU $THEIL);

use Getopt::Long;
my ($logX,$logY,$echo,$noprompt,$paired) = &Flags(&ParseCommandLine());


if($paired) {
  print STDERR "\nPROGRAM: $0\n",
               "   by William H. Asquith, USGS, Austin, Texas\n",
               "  Enter paired data (X then Y):\n";
  while(1) { # infinite loop
    print STDERR "% " unless($noprompt); # Show user a prompt
    $_ = <STDIN>;  # Read from standard input
    last if(not defined $_);
    chomp; # remove the trailing \n
    print STDERR "  Echo: $_\n" if($echo);
    last if($_ eq "" or $_ =~ /^\s+$/o);
    s/^\s+//o; s/\s+$//o; # strip leading spaces and then trailing spaces
    s/,|\t/  /o;          # convert commas or tabs to spaces
    my ($x,$y) = split(/\s+/o, $_, 2);
    last if(not defined $x or
            not defined $y); # mandatory exit when either is not defined
  
    # now treat all non numbers as missing values                                            
    next if(not &isNumber($x) or not &isNumber($y));
    push(@X, ($logX) ? log10($x) : $x);
    push(@Y, ($logY) ? log10($y) : $y);
  }
}
else {
  print STDERR "\nPROGRAM: $0\n",
               "   by William H. Asquith, USGS, Austin, Texas\n",
               "  Time Series Values (X):\n";
  my $x = 0;
  while(1) { # infinite loop
    print STDERR "% " unless($noprompt); # Show user a prompt
    $_ = <STDIN>;  # Read from standard input
    last if(not defined $_);
    chomp; # remove the trailing \n
    print STDERR "  Echo: $_\n" if($echo);
    last if($_ eq "" or $_ =~ /^\s+$/o);
    s/^\s+//o; s/\s+$//o; # strip leading spaces and then trailing spaces
    s/,|\t/  /o;          # convert commas or tabs to spaces
    my $y = $_;
    last if(not defined $y); # mandatory exit when either is not defined
    $x++;
    # now treat all non numbers as missing values                                            
    next if(not &isNumber($y));
    push(@X, $x);
    push(@Y, ($logY) ? log10($y) : $y);
  }
}
print STDERR "  Status: Data has been read in with ",scalar(@X)," valid lines.\n";
die "DIED: Too few data points (n <= 3)\n" if(scalar(@X) <= 3);
$TAU   = &Kendalls_Tau(\@X,\@Y);
print STDERR "  Status: Kendalls_Tau completed\n";
$THEIL = &Theil_Line(\@X,\@Y);
print STDERR "  Status: Theil_Line completed\n";

print "KENDALL's TAU\n"; &phash($TAU);   # call to phash must be separate
print "THEIL LINE\n";    &phash($THEIL); #  .. ditto ..

############## SUBROUTINES ##################
sub ParseCommandLine {
  my %opts = ();
  my @options = qw (help logX logY echo noprompt paired); # these are the valid command line options
  &GetOptions(\%opts, @options); # parse the command line options
  &Help(), exit if($opts{help});
  return %opts;
}

sub Flags {
  my %opts = @_;
  my $logX = ($opts{logX}) ? 1 : 0;
  my $logY = ($opts{logY}) ? 1 : 0;
  my $echo = ($opts{echo}) ? 1 : 0;
  my $paired = ($opts{paired}) ? 1 : 0;
  my $noprompt = ($opts{noprompt}) ? 1 : 0;
  return ($logX,$logY,$echo,$noprompt,$paired);
}


use constant logof10 => scalar log(10); 
sub log10 { ($_[0] <= 0) ? undef : log($_[0])/logof10; }

# isNumber is another handy utility that tests whether the argument
# is a number or not.  This might not be the fastest or the most
# logical method by which to test whether a string is a number or
# not, but hey, it works and provides a constant interface throughout
# the program.  This is an area in which someone could do some really
# important research in terms of speeding up the read in the data
# process.
sub isNumber {
  if(not defined $_[0] ) {
     my @call = caller(1);
     map { $call[$_] = "" if(not defined $call[$_]) } (0..$#call);
     print STDERR "Tkg2::Base::isNumber(undef) as @call\n";
     return 0;
  }
  $_[0] =~ /^\s*[+-]?\d+\.?\d*\s*$/o                 || 
    $_[0] =~ /^\s*[+-]?\.\d+\s*$/o                   ||
      $_[0] =~ /^\s*[+-]?\d+\.?\d*[eE][+-]?\d+\s*$/o || 
        $_[0] =~ /^\s*[+-]?\.\d+[eE][+-]?\d+\s*$/o;
}


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




sub Help {
  my ($AUTHOR, $BUILDDATE, $VERSION) = &getCVSstamps();
  print <<HERE

NAME
  tauntheil.pl version $VERSION by $AUTHOR on $BUILDDATE

DESCRIPTION
  Kendall Tau and Theil Line Nonparametric Statistics Computation Program
  by William H. Asquith
  
DEPENDENCIES
  /usr/local/Tkg2/Math/KendallsTau.pm
  
USAGE
  tauntheil.pl [options] [input file]

OPTIONS
  
  -help      This help and then exit.
  -logX      Log10 transform the dependent variable or X values.
  -logY      Log10 transform the independent variable or Y values.
  -echo      Echo the input data stream.
  -noprompt  Hide the data entry prompt, %.
  -paired    The data is paired and not in a "time series"-like
             format.

NOTES
  

EXAMPLES
  % tauntheil.pl
  PROGRAM: ./tauntheil.pl
     by William H. Asquith, USGS, Austin, Texas
    Enter paired data (X then Y):
  % 1 59
  % 2 64
  % 3 63
  % 4 58
  %
    Status: Data has been read in with 4 valid lines.
    Status: Kendalls_Tau completed
    Status: Theil_Line completed
  KENDALLs TAU
   kendalls_score => -2
   pval_tau_gt_zero => 0.633
   pval_tau_lt_zero => 0.367
   pval_tau_ne_zero => 0.7341
   sample_size => 4
   standard_Z => -0.3397
   tau => -0.3333
   tau_std_dev => 2.944
  THEIL LINE
   ave_slope => -0.3889
   ave_slope_intercept => 61.97
   theil_intercept => 62.67
   theil_slope => -0.6667
   x_mean => 2.5
   x_median => 2.5
   y_mean => 61
   y_median => 61
    
HERE
}

sub getCVSstamps {
   my $df = "not known";
   my ($auth, $date, $ver) = ($df, $df, $df);
   while(<DATA>) {
      last if(/cvs(\s+)?end/io);
      $auth = $1, next if(/Author:\s+(.+)\s+\$/);
      $date = $1, next if(/Date:\s+(.+)\s+\$/);
      $ver  = $1, next if(/Revision:\s+(.+)\s+\$/);
      last if($auth ne $df and
              $date ne $df and
              $ver  ne $df);
   }
   return ($auth, $date, $ver);
}

__DATA__
# $Author: wasquith $
# $Date: 2002/12/03 15:18:02 $
# $Revision: 1.7 $
# CVSEND
