#!/usr/bin/perl -w
use strict;

use constant PI => 3.1415926;

die "Please provide the latitude (in degrees) and day of year\n"
  if(@ARGV != 2);

my ($lat, $doy) = @ARGV;

my $phi = $lat*PI/180;          # convert latitude to radians
my $So  = 1367;                 # Watts per square meter
my $theta_doy = 2*PI*$doy/365;  # day angle

# This call to the radiation function is to compute for the header
# the declination and the solar zenith as these are constants
# for the input provided.  We undef two of the returned values for
# safety.
my (undef,$declin,undef,$zenith) = &RadTOA($So,$phi,12,$theta_doy);

my ($rise,$set,$h0) = &SunRiseNSetTimes($phi,$theta_doy);

&PrintHeader($lat, $phi, $doy, $So, $theta_doy,
             $declin, $zenith, $rise, $set, $h0);

my (@Qtdaily, @Qtdaylight);
for(my $t_hrs=0; $t_hrs<=24; $t_hrs+=0.25) {
   $t_hrs = sprintf("%4.2f",$t_hrs); # building fixed width for output
   my ($Qt,$declin,$hrang,$zenith) = &RadTOA($So,$phi,$t_hrs,$theta_doy);
   $hrang =~ s/\s+$//; # strip trailing spaces
   print "$t_hrs        $Qt     $hrang\n";
   push(@Qtdaily, $Qt);
   push(@Qtdaylight, $Qt) if($Qt > 0);
}

my ($qday, $qlight) = (&mean(@Qtdaily), &mean(@Qtdaylight));
my $ratio   = sprintf("%5.2f",($qlight / $qday ));
    $qday   = sprintf("%5.2f",$qday);
    $qlight = sprintf("%5.2f",$qlight);
print "# Numerical Daily Mean Radiation    = $qday\n";
print "# Numerical Daylight Mean Radiation = $qlight\n";


exit; # optional in Perl 

######### SUBROUTINES ####################
sub RadTOA {
   my ($So,$phi,$t_hrs,$theta_doy) = @_;
   
   my $declin   = &declin($theta_doy);
   my $hrang    = &hrang($t_hrs);
   my $riseNset = &hrang_sunrise_set($phi,$declin);
   my $eccen    = &eccenF($theta_doy);
   my $zenith   = &zenith($phi,$declin,$hrang);
   my $radtoa   = $So*$eccen*cos($zenith);
      # If the sun is below the horizon, set radtoa to zero.
      $radtoa   = (abs($hrang) > $riseNset) ? 0 : $radtoa;
   foreach my $val ($radtoa, $declin, $hrang, $eccen, $zenith) {
      $val = pack("A6",$val); # val is an alias to the five elements
                              # we are fixing the width to 6 spaces
   }
   
   return ($radtoa, $declin, $hrang, $eccen, $zenith);
}

# Hour angle (converts argument in hours to radians)
sub hrang { return PI*($_[0] - 12)/12 }
sub hrang_sunrise_set {
   my ($phi,$del) = @_;
   return acos(-tan($phi)*tan($del));
}

# Compute the declination angle, given the day angle
sub declin { 0.4093*sin($_[0] - 1.405) }

# Compute the eccentricity factor (dmean / d)**2
sub eccenF { 1 + 0.033*cos($_[0]) }

# Compute the solar zenith angle from vertical
sub zenith {
   my ($phi, $del, $hr) = @_;
   my $tmp = sin($phi)*sin($del)+cos($phi)*cos($del)*cos($hr);
   return acos($tmp);
}

sub acos { atan2( sqrt(1 - $_[0] * $_[0]), $_[0] ) }
sub tan  { sin($_[0]) / cos($_[0]) } 

sub mean {
   my $sum = 0;
   foreach my $val (@_) { $sum += $val };
   return $sum / $#_;
}

sub SunRiseNSetTimes {
   my ($phi, $theta_doy) = @_;
   # Compute the rise and set of the sun times with accounting for
   # southern and norther hemispheres.
   # Hour angle
   my $rads = &hrang_sunrise_set($phi,&declin($theta_doy));
   
   my $rs = $rads*(12/PI);
   my ($rise,$set) = (12-$rs,12+$rs);
   
   $rise = sprintf("%5.2f",$rise); # 5 space 2 decimal format
   $set  = sprintf("%5.2f",$set);
   return ($rise, $set, $rads);
}


sub PrintHeader {
   my ($lat,$phi,$doy,$So,$theta_doy,$declin,
       $zenith,$rise,$set,$h0) = @_;
   # Print out a header
   print "# Radiation at Top of Atmosphere Program\n";
   print "#   by William H. Asquith\n";
   print "# Latitude       = $lat\n";
   print "# Day of year    = $doy of 365 (no leap year correction)\n";
   print "# Solar Constant = $So Watts per square meter\n";
   print "# Day of year angle  (radians) = ",sprintf("%5.2f",$theta_doy),"\n";
   print "# Declination angle  (radians) = $declin\n";
   print "# Solar Zenith angle (radians) = $zenith\n";
   print "# Hour angle of sunrise/set, h0 (radians) = ",
              sprintf("%7.5f",$h0),"\n";
   print "# Sunrise time = $rise hours\n";
   print "# Sunset  time = $set hours\n";
   
   my ($dailyrad, $daylightrad, $ratio) =
         &analytical_daily_and_sunrise_mean($So,$phi,$declin,$theta_doy,$h0);
   print "# Daily Mean Radiation    = $dailyrad\n";
   print "# Daylight Mean Radiation = $daylightrad\n";
   print "# Ratio of Daily to Daylight = $ratio (PI / h0)\n";
   
   print "# HRS_OF_DAY = Hours of the day (non-local time correction)\n";
   print "# RADTOA = Radiation at top of atmosphere in Watts per square meter\n";
   print "# HR_ANGLE = Hour angle of the sun.\n";

   # Print a label line--always good practice
   print "HRS_OF_DAY  RADTOA     HR_ANGLE\n";
}

sub analytical_daily_and_sunrise_mean {
   my ($So,$phi,$declin,$theta_doy,$h0) = @_;
   my $eccen = &eccenF($theta_doy);
   my $trig = $h0*sin($phi)*sin($declin)+cos($phi)*cos($declin)*sin($h0);
   my $qdailymean   = $So*$eccen*$trig;
   my $daylightmean = $qdailymean/$h0;
      $qdailymean  /= PI;
   my $ratio = $daylightmean / $qdailymean;
      $qdailymean   = sprintf("%5.2f",$qdailymean);
      $daylightmean = sprintf("%5.2f",$daylightmean);
   return ($qdailymean, $daylightmean, $ratio);
}

__END__
This constitutes the end of the program.  The following are some notes
and cut and paste programs to help me generate large figures.
#!/usr/bin/perl -w
@doy1 = qw(   1      32      60   
            91    121    152);
@doy2 = qw(182    213    244  
           274    305    335  );

@spec = qw(79  172  265  356);

my $file1 = "";
foreach my $doy (@doy1) {
   $file1 .= `radtoa.pl 30 $doy`;
   $file1 .= "--   --   --\n";
}
my $file2 = "";
foreach my $doy (@doy2) {
   $file2 .= `radtoa.pl 30 $doy`;
   $file2 .= "--   --   --\n";
}
my $file3 = "";
foreach my $doy (@spec) {
   $file3 .= `radtoa.pl 30 $doy`;
   $file3 .= "--   --   --\n";
}

open(FH,">rad1.out") or die "rad1.out not opened: $!\n";
print FH $file1;
open(FH,">rad2.out") or die "rad2.out not opened: $!\n";
print FH $file2;
open(FH,">rad3.out") or die "rad3.out not opened: $!\n";
print FH $file3;

