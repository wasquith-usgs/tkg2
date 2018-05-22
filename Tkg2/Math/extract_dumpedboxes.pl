#!/usr/bin/perl -w
use strict;
my %data = ();
my ($key,$val);
my @order = qw(Mean Scale Skew Kurtosis Median Max Min IQR
               NumberSamples    MomentCalcMethod 
               HarmonicMean     GeometricMean
               LowerTercile     UpperTercile
               LowerQuartile    UpperQuartile
               LowerPentacile   UpperPentacile
               LowerDecile      UpperDecile
               LowerCentacile   UpperCentacile );
my @wanted = qw(NumberSamples  Mean  Median);
my $count = 0;
my $onbox = 0;
while(<>) {
  $count++, $onbox = 1 if(/BEGIN/);
  if(/END/) {
     $onbox = 0; 
     print join("   ", ($count,@data{@wanted})),"\n"; # use custom wanted keys
     next;
  }
  if($onbox) {
     chomp;
     ($key,$val) = split(/=/,$_);
     if(defined $key) {
        $key =~ s/^\s+//;
        $key =~ s/\s+$//; 
        $key =~ s/\s+//g;
        next if($key =~ /Outliers/);
     }
     if(defined $val) {
        $val =~ s/^\s+//;
        $val = "--" if($val =~ /not defined/ or $val eq "");
        $val = sprintf("%0.2f",$val)
               if($val ne "--" and $val !~ /used/); # custom formating
        $val = sprintf("%0.0d",$val) if($key eq "NumberSamples");
     }
     $data{$key} = $val;
  }
}
