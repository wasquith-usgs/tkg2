package Tkg2::Time::TimeMethods;

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
# $Date: 2005/01/16 23:02:47 $
# $Revision: 1.57 $

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %TIME_CACHE $TIME_CACHE_FILE);
@ISA = qw(Exporter);
@EXPORT = qw( drawTimeAxis
              DecodeTkg2DateandTime
              RecodeTkg2DateandTime
              ConvertTime
              isTkg2Date
              String_2_TwoFields
              NOW_as_Days_and_String
              NOW_as_parsed_String
              TOMORROW_as_parsed_String
              YESTERDAY_as_parsed_String
              WEEKPLUS_as_parsed_String
              WEEKMINUS_as_parsed_String
              MONTHPLUS_as_parsed_String
              MONTHMINUS_as_parsed_String
              BEGINNING_OF_WATERYEAR_as_parsed_String
              ENDING_OF_WATERYEAR_as_parsed_String
              isLeapYear
              whatDayOfYear
              DateandTime2DayOfYear
              ConvertTimetoDOY);

@EXPORT_OK = qw(OpenTimeCache SaveTimeCache);

use Data::Dumper; # need for the time cache

use Date::Calc qw( Delta_Days
                   Add_Delta_Days
                   leap_year
                   Day_of_Year );
# Delta_Days
#      $Dd = &Delta_Days($year1,$month1,$day1, $year2,$month2,$day2);
#
#  Add_Delta_Days
#      ($year,$month,$day) = &Add_Delta_Days($year,$month,$day, $Dd);

use Date::Manip 5.39;  # import the &ParseDateString method

# draw the other time oriented tools in.
use Tkg2::Time::Utilities qw(  hhmmss2fracday 
                               dayhhmmss2days
                               parsedays
                               days2dayhhmmss
                               fracday2hhmmss );
                               
use Tkg2::Time::DrawTimeAxis qw(drawTimeAxis);

use Tkg2::Base qw(Show_Me_Internals @BaseDate isNumber OSisMSWindows);


########### BEGINNING OF TIME CACHING LOGIC #########################
# %TIME_CACHE is a time conversion caching mechanism.
# The keys are time fields as found by tkg2 during runtime and
# the values are the converted time to tkg2 'days'.  The longer
# a single tkg2 session is used the faster it will become as 
# presumably fewer and fewer new time fields will be experienced.

%TIME_CACHE      = ();
$TIME_CACHE_FILE = (&OSisMSWindows()) ? 
                   "Time/TimeCache/dumped_time_cache" :
                   "$::TKG2_ENV{-TKG2HOME}/Tkg2/Time/TimeCache/dumped_time_cache";

&Date_Init("TZ=GMT") if(&OSisMSWindows());

# THE TIME CACHING IS A HIGHLY WORKABLE OPTIMIZATION TECHNIQUE TO GREATLY!!!!
# SPEED DATETIME CONVERSTION TO TKG2 INTERNAL TIME REPRESENTATION.
# From Tkg2::DeskTop::Activities::ProcessOptions SaveTimeCache() is called.
# The arguments to TimeCach are ('retrieve'),('retrieve','view'),('ignore'), or
#   ('delete')
# With 'retrieve', tkg2 will make a single attempt to retrieve the
# storable_time_cache and bring the TIME_CACHE to life.  This hash can be viewed with
# the 'view' option, which is triggered by the --time_cache_view command line option.
# The command line option --time_cache_delete deletes the cache file. ('delete')
# The command line options --time_cache_ignore skips the retrieval process.
sub OpenTimeCache {
    &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
    my $type    = shift;
    my $cacherr = 0;
    if( $type eq 'retrieve' ) {
       $cacherr = &TimeCache_retrieve($TIME_CACHE_FILE);
       print $::BUG "TimeCache: Retrieved!\n" if(not $cacherr);
       my $view = (@_) ? shift() : 0;
       if($view eq 'view') { # if there is a second argument passed in, assume 'view'
          # The ability to view the cache could be very important under some circumstances.
          map { print STDERR "$_ translates to $TIME_CACHE{$_} days\n" }
               (sort keys %TIME_CACHE);
       }
    }
    elsif($type eq 'ignore') {
       1; # do nothing, make no retrieval!
    }
    elsif($type eq 'delete') {
       unlink($TIME_CACHE_FILE) or
         print STDERR "TimeCache: Could not unlink ",
                      "$TIME_CACHE_FILE because $!\n";   
    }  
    else { # logic should not reach here
       print $::BUG "TimeCache: Bad call on subroutine with ",
                    "$type as argument\n";
    }
    return $cacherr;
}

# The actual retrieval mechanism, called by TimeCache('retrieve')
# or ('retrieve','view')
sub TimeCache_retrieve {
   my $file = $_[0];
   my $sub  = "TimeCache_retrieve:";
   return "Time cache does not exist at '$file'" unless(-e $file);
   my $cache;
   local $/ = undef;
   local *FH;
   open(FH, "<$file") or
      do {
           print STDERR "$sub $file not opened because $!\n";
           return $!;
         };
      if( flock(FH, 1) ) { # Shared lock for reading, lock removed when closed
         $cache = <FH>; # read the the entire file at once!
      }
   close(FH) or
      do {
           print STDERR "$sub $file not closed because $!\n";
           return $!;
         };
   return "Cache is not defined" if(not defined $cache);
   eval { eval $cache; };
   # if there was an eval error, which is loaded into $@ or the file did not contain
   # a hash, then just safely return.
   return $@ if($@);
   return "Cache is not a hash reference" if(ref($cache) ne 'HASH');  
      
   %TIME_CACHE = %$cache; # the TIME_CACHE has been brought to life!
   return 0;  # proper return
}


# Upon exiting of the Tkg2 package, tkg2 will make a single attempt to store away the
# TIME_CACHE for another day.  If problems ever arise with time conversions, it is suggested
# that the storable_time_cache file be deleted and tkg2 starts building it a new.
# The file can be deleted with the --time_cach_delete command line switch.
# The --time_cache_ignore command line switch WILL SKIP THIS OPERATION.
sub SaveTimeCache {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   return 0 if($::CMDLINEOPTS{'time_cache_nosave'});
 
   warn("Tkg2-Ignoring saving the time cache\n"), return 0 if($::CMDLINEOPTS{'time_cache_ignore'});
   
   # More research into the time cache saving on WINDOWS is needed.
   warn("Tkg2-NOTE: Running on Windows so time cache is not saved.\n"), return 0
       if(&OSisMSWindows());
      
   my $time_cache = $TIME_CACHE_FILE;
   
   # The file exists so see if it needs to be deleted because it is greater than 5MB.
   # Time cache file growth is unbounded without this check and delete, a risk for sure.
   if(-e $time_cache) {
      my $size = (stat $time_cache)[7]/1000; # check its size
      if( $size > 5000 ) { # the old time cache file is greater than 5MB, lets delete it.
         unlink($time_cache) or
            warn("TimeCache: Could not unlink $time_cache because $!\n");
      }
   }
   # Store the time_cache hash away, overwriting the existing file 
   # Note, that although > 5MB files are deleted, it is entirely possible that the about
   # to be stored %TIME_CACHE hash could be bigger than this.  I do not know how to a priori
   # test the size of a hash before storage.  Testing shows that it is highly unlikely that
   # a >5MB file will ever be created during a single Tkg2 session.
   
   
   # DUMP FIRST AND THEN WRITE
   $Data::Dumper::Indent = 0;  # most compact form
   # find out which Dump method is available on the currently
   # running installation of Perl, Dumpxs is faster by a lot.
   my $avail_dump = Data::Dumper->can('Dumpxs') ||  Data::Dumper->can('Dump');

   if(not $avail_dump) {
      print STDERR "Tkg2-Warn: TimeMethods::SaveTimeCache Could not dump\n";
      return 0;
   }
   my $stuff = Data::Dumper->$avail_dump([\%TIME_CACHE], [ qw($cache) ]);
   my $lock = 0;
   local *FH;
   open(FH,">$time_cache") or
      do {
           print STDERR "TimeCache $time_cache not opened because $!\n";
           return 0;
         };
     while( not flock(FH,2) ) {
        sleep(2);
        $lock++;
        if($lock == 4) {
           close(FH) or
              do { print STDERR "TimeCache $time_cache not ",
                                "closed because $!\n";
                   return 0;
                 };
        }
     } 
     print FH $stuff;
   close(FH) or 
      do {
           print STDERR "TimeCache $time_cache not closed because $!\n";
           return 0;
         };
   chmod(0666, $time_cache);
   my $size = (stat $time_cache)[7]/1000; # return the size of the stored file
   print $::BUG "TimeCache: $size kb file stored.\n" if(defined $size);
}

########### END OF TIME CACHING LOGIC #########################




###############################################################
# BEGIN SUBROUTINES ACTUALLY USED TO HANDLE TIME ISSUES

# Checking whether a string is a Tkg2Date
# See the DecodeTkg2DateandTime method for a bit more specific
# description.  
sub isTkg2Date {
   my $field = $_[0];
   my $return_val;
   if(exists $TIME_CACHE{$field}) { 
      $return_val = $TIME_CACHE{$field};
      return ($return_val == 0) ? '1' : $return_val;
   }
   $field =~ s/(.+)@(.+)/$1 $2/ if($field =~ m/@/o);
   $return_val = &ParseDateString($field); # returns false if it is a date
   return $return_val;
}

# DecodeTkg2DateandTime
# Takes either an array reference or a scalar value and converts
# it to the internal time representation of Tkg2.
# It first tries the time cache and if Tkg2 has seen that time
# before the the value in the time cache is used.
#
# If the time is not available in the time cache, then the method
# converts the value(s) to a ISO date using &ParseDateString from
# Date::Manip.  If this conversion can not be done, then the value
# is returned as undef.  If the conversion was done, then the 
# parsed date is converted to decimal days since 1/1/1900.
# 
# WHA had to request that a special feature be added to the Date::Manip
# function &ParseDateString.  If a date parses with the hours equalling
# 24:00:00 then the next day is returned at zero hundred hours.  Most
# date libraries use 23:59:59 as the end of the day and not 24:00:00.
# Several data bases or other sytems use 24:00:00 as a top of the day
# value, for plotting purposes the distinction is necessary but does
# not change the meaning of the data.
sub DecodeTkg2DateandTime {
   my ($field, $commondate, $datetime_offset) = @_;
   
   $datetime_offset ||= 0;
   
   # The commondate, if true is used in place of the actual date in
   # the data set (commondate provided by ConvertTime subroutine only)
   # This supports the ability to plot whole time series on the same
   # annual, monthly, daily, etc base.  Cool.  Since the common date
   # is only drawn from the ConvertTime subroutine, which only provides
   # an array, there is no need to look at commondate if it is not.
   
   
   # Here is what the parsed data looks like as a regex
   # (\d{4})(\d{2})(\d{2})(\d{2}):(\d{2}):(\d{2})$/;
   my $format = "A4 A2 A2 A2 x A2 x A2"; # code for the unpack function
   
   return &_Array_DecodeTkg2DateandTime($field, $commondate, $datetime_offset)
            if(ref($field) eq 'ARRAY');
   
   # just a single value is contained in field so convert it
   return $TIME_CACHE{$field} + $datetime_offset
              if(exists $TIME_CACHE{$field}); #DATETIME_OFFSET
   my $newfield = $field;
      $newfield =~ s/(.+)@(.+)/$1 $2/ if($newfield =~ m/@/o);
      $newfield = &ParseDateString($newfield);
   return undef unless($newfield);
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = unpack( $format, $newfield );
   my $day   = &Delta_Days( 1900, 1, 1, $yyyy, $mm, $dd );
   my $days  = &dayhhmmss2days( $day, $hh, $min, $ss );
   $TIME_CACHE{$field} = $days;
   return $days + $datetime_offset; #DATETIME_OFFSET
}

sub _Array_DecodeTkg2DateandTime {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($field, $common_datetime, $datetime_offset) = @_;
   
   my $format = "A4 A2 A2 A2 x A2 x A2"; # code for the unpack function
   
   if(not $common_datetime) {
      foreach my $val (@$field) {
         $val = $TIME_CACHE{$val} + $datetime_offset,
                       next if(exists $TIME_CACHE{$val}); # DATETIME_OFFSET
         # the string has not been previously used (not it time cache)
         # now time to brute force conversion 
         my $newval = $val;
        
         # WHA has decided that an @ is acceptable in a time string,
         # but &ParseDateString does not handle the @ sign. 
         # We will just strip it away.
         $newval =~ s/(.+)@(.+)/$1 $2/ if($newval =~ m/@/o);
       
         $newval = &ParseDateString($newval);  # provided by Date::Manip
         $val = undef, next unless($newval);   # place undef into the array
        
         # unpack is used because $val is a fixed width string
         my ($yyyy, $mm, $dd, $hh, $min, $ss) = unpack($format, $newval);
         my $day  = &Delta_Days(1900, 1, 1, $yyyy, $mm, $dd);
         my $days = &dayhhmmss2days($day,$hh,$min,$ss); 
         
         $TIME_CACHE{$val} = $days;            # load into the time cache
         # the converted value is a number like 35001.50
         $val = $days + $datetime_offset; # DATETIME_OFFSET 
      }
   }
   else { # DO SOMETHING ABOUT CONVERTING TO A COMMON DATE
      print $::VERBOSE "      Common date-time base computations -- converting ",
                       "all date-times a $common_datetime base -- ";
      print $::VERBOSE "      Date-time offsetting with $datetime_offset\n";
      # Make sure that we have six components to work with
      my @components = split(/:/o, $common_datetime, 6);
      
      # Convert the components to zero if not defined or it is not a 
      # number.  This is a safety check agaist bad common datetime coming
      # from manual editing of a tkg2 file.
      my $firstcomponent = shift(@components); # first pull year away 
         $firstcomponent = 0 if(not defined $firstcomponent); # makeit defined
      my $is_wateryear = 0; # set to false initially
      if($firstcomponent =~ m/wy(\d{4})/io) { # if the common year has "wy"
         $firstcomponent = $1;   # then extract the four digit year and 
         $is_wateryear = 1;  # toggle the wateryear toggle to true
      }
      unshift(@components,$firstcomponent);  # place back onto the list
      foreach my $component (@components) { 
         $component = 0 if(not defined $component or
                           not &isNumber($component));
            # We use '-' as the missing string in the time component
            # entry from the dialog box, but internally (here), let us
            # allow any non-numeric to be treated a zero (missing).
      }
      my ($cy, $cm, $cd, $ch, $cmin, $cs) = @components;
      
      # test for a leap year if component year is defined 
      # remember that this is the common year and not the year
      # of individual data points
      my $leapyear  = ($cy) ? &leap_year($cy) : 0;
      
      foreach my $val (@$field) {   
         # Brute force conversion only, do not utilize the time cache
         # as we have in the similar time conversion algorithms.
         my $newval = $val;
        
         # WHA has decided that an @ is acceptable in a time string,
         # but &ParseDateString does not handle the @ sign. 
         # We will just strip it away.
         $newval =~ s/(.+)@(.+)/$1 $2/ if($newval =~ m/@/o);
       
         $newval = &ParseDateString($newval);  # provided by Date::Manip
         $val = undef, next unless($newval);   # place undef into the array
        
         # unpack is used because $val is a fixed width string
         my ($yyyy, $mm, $dd, $hh, $min, $ss) = unpack($format, $newval);
         #print "BUG: ($yyyy, $mm, $dd, $hh, $min, $ss)\n";
         if($is_wateryear and $cy) {
            # subtract one year from the component year if we are in the
            # months of october, november, or december
            $yyyy  = ($mm == 10 or $mm == 11 or $mm == 12) ? $cy-1 : $cy; 
         }
         else {
            $yyyy  = $cy   if($cy  ); 
         }
            $mm    = $cm   if($cm  );
            $dd    = $cd   if($cd  );
            $hh    = $ch   if($ch  );
            $cmin  = $cmin if($cmin);
            $ss    = $cs   if($cs  );
         
	 #print "BUG: ($yyyy, $mm, $dd, $hh, $min, $ss)\n";
	 # Things WILL hang if we try to go further and the year is
         # not a leap year and the month and day are 02 and 29.
	 # if cy is true, then we are common'ing to a year and we need to
	 # test for the leapyear etc--the addition of cy was not made until
	 # 01/14/2005 by WHA
         $val = undef, next if($cy and not $leapyear and
                               defined $mm   and $mm == 2 and
                               defined $dd   and $dd == 29);
         
	 my $day  = &Delta_Days(1900, 1, 1, $yyyy, $mm, $dd);
         my $days = &dayhhmmss2days($day,$hh,$min,$ss); 
         # Do not load into time cache when we are doing funky stuff
         # with time.
         $val = $days + $datetime_offset; # DATETIME_OFFSET
         # the converted value is a number like 35001.500
      }
      print $::VERBOSE "Done\n";
   }
   return $field;
}


# RecodeTkg2DateandTime turns day.fraction to a yyyymmddhh:mm:ss format
# The base date for the beginning of the Tkg2 epoch is 01/01/1900.
# This is not a big deal because time before then takes on negative values.
sub RecodeTkg2DateandTime {
   #&Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my $days = $_[0];
   my ($day, $hh, $min, $ss) = &days2dayhhmmss( $days );
   my ($yyyy, $mm, $dd);
   $day-- if($day < 0 and ($hh or $min or $ss)); # NEGATIVE TIME BUG FIX
   eval {
          ($yyyy, $mm, $dd) = &Add_Delta_Days( @BaseDate, $day )
        };
   return undef if($@);
   $mm = sprintf("%2.2d",$mm);
   $dd = sprintf("%2.2d",$dd);
   return "$yyyy$mm$dd$hh:$min:$ss";
}
   


# ConvertTime is used to officially convert the data fields of 
# each dataset into internal tkg2 time, which is days.frac
sub ConvertTime {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
      
   my ($self, $data, $absc, $ords,
       $missing_value, $common_datetime, $datetime_offset) = @_;
   # self is the plot object
   # data is the dataset
   # absc is the abscissa name string
   # ords is the ordinates name strings
   
   # convert the abscissa only if it is in a time format
   my $val = $data->{$absc};     # will be undef if no data was actually 
   return if(not defined $val);  # read in, no need to check the ordinates?
   $data->{$absc} =
        &DecodeTkg2DateandTime($val,
                               $common_datetime,
                               $datetime_offset)
                    if($absc =~ /:time/o);
   # convert ordinates, actually only those that are in a time format
   foreach my $ord (@$ords) {
     $data->{$ord} =
          &DecodeTkg2DateandTime($data->{$ord},
                                 $common_datetime,
                                 $datetime_offset)
                    if($ord =~ /:time/o);
   }
   
   # If we have converted to a $common_datetime of any kind, we need to 
   # assume the time series was in ascending order and then 
   # inserted missing values at the points where time reverses on itself.
   # We do this so that line plots will not jump from right back to left
   # as the time is artificially reverved or actually reset.
   # This is a hugely CPU intensive operation!!!!!!!!!
   if($common_datetime) {
      print $::BUG "      Common date-time base computations -- working out ",
                       "when to lift the pen for line plotting -- ";
      my @columns = keys %$data;
      foreach my $column (@columns) {
         next if($column !~ /:time/o); # no need to do anything
         my @time_values = @{$data->{$column}};
         foreach my $i (1..$#time_values) {
            my ($x1,$x2) = ($data->{$column}->[$i-1], $data->{$column}->[$i]);
            next if(not defined $x1 or $x1 eq $missing_value or
                    not defined $x2 or $x2 eq $missing_value);
            map { splice(@{$data->{$_}}, $i, 0, undef) } @columns
                if($x2 < $x1); # all this to avoid code blocks {} which are
                               # slower than inlining the map and if statements
         }
      }
      print $::BUG "Done\n";
   }
}

# String_2_TwoFields converts a time string
#   yyyymmddhh:mm:ss plus fractional seconds to
#   yyyy/mm/dd     and hh:mm:ss plus fractional seconds
sub String_2_TwoFields {
   my $str = shift;
   my ($y, $m, $d, $t) = $str =~ m/^(\d{4})(\d{2})(\d{2})(.+)$/o;
   return ("$y/$m/$d", $t);
}

sub NOW_as_Days_and_String {
   my $days   = &DecodeTkg2DateandTime(scalar localtime);
   my $string = &RecodeTkg2DateandTime($days);
   return ($days, $string);
}

sub NOW_as_parsed_String {
   my (undef, $string) = &NOW_as_Days_and_String();
   # Here is what the parsed data looks like as a regex
   # (\d{4})(\d{2})(\d{2})(\d{2}):(\d{2}):(\d{2})$/;
   my $format = "A4 A2 A2 A2 x A2 x A2"; # code for the unpack function
   my @values = unpack($format, $string);
   foreach (1..$#values) { # make sure that single digits have leading zero
      $values[$_] = sprintf("%2.2d", $values[$_]);
   }
   return @values; # (yyyy, mm, dd, hh, min, ss)
}

sub TOMORROW_as_parsed_String {
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String();
   ($yyyy, $mm, $dd) = &Add_Delta_Days( $yyyy, $mm, $dd, 1 );
   $mm = sprintf("%2.2d",$mm);
   $dd = sprintf("%2.2d",$dd);
   return ($yyyy, $mm, $dd, $hh, $min, $ss);
}

sub YESTERDAY_as_parsed_String {
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String();
   ($yyyy, $mm, $dd) = &Add_Delta_Days( $yyyy, $mm, $dd, -1 );
   $mm = sprintf("%2.2d",$mm);
   $dd = sprintf("%2.2d",$dd);
   return ($yyyy, $mm, $dd, $hh, $min, $ss);
}

sub WEEKPLUS_as_parsed_String {
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String();
   ($yyyy, $mm, $dd) = &Add_Delta_Days( $yyyy, $mm, $dd, 7 );
   $mm = sprintf("%2.2d",$mm);
   $dd = sprintf("%2.2d",$dd);
   return ($yyyy, $mm, $dd, $hh, $min, $ss);
}

sub WEEKMINUS_as_parsed_String {
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String();
   ($yyyy, $mm, $dd) = &Add_Delta_Days( $yyyy, $mm, $dd, -7 );
   $mm = sprintf("%2.2d",$mm);
   $dd = sprintf("%2.2d",$dd);
   return ($yyyy, $mm, $dd, $hh, $min, $ss);
}

sub MONTHPLUS_as_parsed_String {
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String();
   ($yyyy, $mm, $dd) = &Add_Delta_Days( $yyyy, $mm, $dd, 30 );
   $mm = sprintf("%2.2d",$mm);
   $dd = sprintf("%2.2d",$dd);
   return ($yyyy, $mm, $dd, $hh, $min, $ss);
}

sub MONTHMINUS_as_parsed_String {
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String();
   ($yyyy, $mm, $dd) = &Add_Delta_Days( $yyyy, $mm, $dd, -30 );
   $mm = sprintf("%2.2d",$mm);
   $dd = sprintf("%2.2d",$dd);
   return ($yyyy, $mm, $dd, $hh, $min, $ss);
}

sub BEGINNING_OF_WATERYEAR_as_parsed_String {
   my $day_offset = (@_) ? shift : 0;
   $day_offset ||= 0;
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String();
   $yyyy-- unless($mm >= 10); # decrement unless if Oct to Dec
   ($yyyy, $mm, $dd) = &Add_Delta_Days( $yyyy, 10, 01, $day_offset );
   $mm = sprintf("%2.2d", $mm);
   $dd = sprintf("%2.2d", $dd);
   return ($yyyy, $mm, $dd, "00", "00", "00");
}

sub ENDING_OF_WATERYEAR_as_parsed_String {
   my $day_offset = (@_) ? shift : 0;
   $day_offset ||= 0;
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = &NOW_as_parsed_String();
   $yyyy++ if($mm >= 10); # increase the ending year if Oct to Dec
   ($yyyy, $mm, $dd) = &Add_Delta_Days( $yyyy, 9, 30, $day_offset );
   $mm = sprintf("%2.2d", $mm);
   $dd = sprintf("%2.2d", $dd);
   return ($yyyy, $mm, $dd, "00", "00", "00");
}

# Used in the Time Axis Editor
sub isLeapYear {
   my $is = eval { &leap_year(@_) };
   return ($@)  ? 'badyr' :
          ($is) ? 'Yes'   : 'No';
}

# Used in the Time Axis Editor
sub whatDayOfYear {
   my $doy = eval { &Day_of_Year(@_); };
   return ($@) ? 'baddate' : $doy;
}


# Used by ConvertTimetoDOY, but is exported so it can be used
# by preprocessing software for tkg2 or other applications
sub DateandTime2DayOfYear {
   my ($field, $datetime_offset) = @_;
   
   $datetime_offset ||= 0;
   $datetime_offset = int($datetime_offset);

   # Here is what the parsed data looks like as a regex
   # (\d{4})(\d{2})(\d{2})(\d{2}):(\d{2}):(\d{2})$/;
   my $format = "A4 A2 A2 A2 x A2 x A2"; # code for the unpack function

   my $newfield = $field;
      $newfield =~ s/(.+)@(.+)/$1 $2/ if($newfield =~ m/@/o);
      $newfield = &ParseDateString($newfield);
   return undef unless($newfield);
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = unpack( $format, $newfield );
   ($yyyy, $mm, $dd)   = &Add_Delta_Days( $yyyy, $mm, $dd, $datetime_offset );
   my $doy = &Day_of_Year($yyyy, $mm, $dd);
   return $doy;
}

# ConvertTime is used to officially convert the data fields of 
# each dataset into integer days of that year.  This method is
# presently not used in Tkg2 (as of January 21, 2002).  This method is
# for internal use by Tkg2 and is analogous to the ConvertTime method
# elsewhere in this module.
sub ConvertTimetoDOY {
   print $::VERBOSE "  Converting the ':time' fields to equivalent day ",
                    "of the year.  CPU intensive as no caching is done.\n";
      
   my ($data, $absc, $ords,
       $missing_value, $datetime_offset) = @_;
   # self is the plot object
   # data is the dataset
   # absc is the abscissa name string
   # ords is the ordinates name strings
   
   # convert the abscissa only if it is in a time format
   my $field = $data->{$absc};     # will be undef if no data was actually 
   return if(not defined $field);  # read in, no need to check the ordinates?
   if($absc =~ /:time/o) {
      foreach my $val (@$field) {
         $val = &DateandTime2DayOfYear($val, $datetime_offset);
      }
   }
   
   # convert ordinates, actually only those that are in a time format
   foreach my $ord (@$ords) {
     next if($ord !~ /:time/o); # no need to process these data values
     my $field = $data->{$ord};
     foreach my $val (@$field) {
        $val = &DateandTime2DayOfYear($val, $datetime_offset);
     }
   }
   
}
1;
