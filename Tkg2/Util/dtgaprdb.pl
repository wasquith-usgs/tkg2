#!/usr/bin/perl -w
use strict;

## CVS STAMPS are present in every module and look like the following
# $Author: wasquith $
# $Date: 2002/03/11 22:13:13 $
# $Revision: 1.4 $

use lib qw(/usr/local); # file prefix to Tkg2 installation

use Date::Calc qw( Delta_Days
                   Add_Delta_Days
                   leap_year
                   Day_of_Year );

#  Delta_Days
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

# Workout what the command line options are and parse them.
use Getopt::Long;

my $VERSION = 1.1;
my %OPTS = ();
# these are the valid command line options
my @options = qw ( hrsabort=f
                   h=f
                   dayabort=f
                   d=f
                   minabort=f
                   
                   help
                   
                   missval=s
                   mv=s );
&GetOptions(\%OPTS, @options); # parse the command line options
my $OPT_STRING = "no options provided";
if(scalar(keys %OPTS)) {
   $OPT_STRING = "";
   map { $OPT_STRING .= "--"."$_=$OPTS{$_}  "; } sort keys %OPTS;
}

die "$0 Version $VERSION\n" if($OPTS{version});

# Work on the aliases
   $OPTS{dayabort} = $OPTS{d}  if(defined $OPTS{d});               
   $OPTS{hrsabort} = $OPTS{h}  if(defined $OPTS{h});
   $OPTS{missval}  = $OPTS{mv} if(defined $OPTS{mv});               


my $ABORT_LIMIT = ($OPTS{hrsabort}) ? $OPTS{hrsabort}/24    :
                  ($OPTS{dayabort}) ? $OPTS{dayabort}       :
                  ($OPTS{minabort}) ? $OPTS{minabort}/24/60 : 0;
   
my $MISSING_VALUE = (defined $OPTS{missval}) ? $OPTS{missval} : "";
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
&help, exit if($OPTS{help});

my ($input, $output) = @ARGV;
&gapDATE_TIME_inRDB(-input  => $input,
                    -output => $output,
                    -abort  => $ABORT_LIMIT,
                    -missing_value => $MISSING_VALUE );

# takes an rdb input file and 
# if and only if they both exist.  The file is duplicated if they
# are not
sub gapDATE_TIME_inRDB {
   use strict;
   my %ARGS = @_;
   
   my $abort_limit = $ARGS{-abort};  # must be in days at this point
   my $mval        = $ARGS{-missing_value};
   
   my $infile = $ARGS{-input}; 
      $infile = '/dev/stdin' if(not defined $infile   or
                                $infile =~ m/stdin/io or
                                not -e $infile);
   
   
   my $outfile = $ARGS{-output};
      $outfile = '/dev/stdout' if(not defined $outfile or
                                  $outfile =~ m/stdout/io);
   
   local *INFH; local *OUTFH;
   open(INFH, "<$infile" ) or return  "'$infile' not opened because $!";
   open(OUTFH,">$outfile") or return "'$outfile' not opened because $!";
   select((select(STDOUT),$|=1)[0]);  # autobuffering off
      
   my (@COLUMNS, @FORMAT, @LINE1, @LINE2, %DATA1, %DATA2);
   while(<INFH>) {
      if(/^#/o) {
         print OUTFH;
         next;
      }
      chomp;
      @COLUMNS = split(/\t/o,$_,-1);
      chomp($_=<INFH>);
      @FORMAT  = split(/\t/o,$_,-1);
      last;
   }   
   
   print OUTFH "#\n# **********\n",
               "# This file was potentially modified with fake missing\n",
               "# values by the $0 script.\n",
               "# The maximum time interval (abort limit) permitted was\n",
               "#    ABORT_LIMIT: $abort_limit days\n",
               "# The command line summary was\n",
               "#        CMDLINE: $OPT_STRING\n",
               "# ***********\n#\n";

   
   my $there_is_a_DATE_field = 0;
   my $date_string = "not specified";
   foreach my $column (@COLUMNS) {
      if($column =~ /DATE|TIME/io) {
         $there_is_a_DATE_field = 1; 
         $date_string = $column;
         last; # keeps us using the first date column only
      }
   }
   
   die "DIED: No date or time column was found, there is no reason ",
       "to process further.\n" unless($there_is_a_DATE_field);
   
   print OUTFH join("\t",@COLUMNS),"\n"; # output the column titles
   print OUTFH join("\t", @FORMAT),"\n"; # output the column formats
   
   my ($a, $b);
   while(1) {
      $a = <INFH> if(not defined $a); # not defined as we first enter the data 
      if(eof(INFH)) { print OUTFH $a; last; } # print the line if it is last
      $b = <INFH>;  # read the second line
      
      # Create two hashes that contain the splitted contents of
      # two consecutive lines of the RDD file.
      %DATA1 = ();                     %DATA2 = ();
      chomp($a);                       chomp($b);
      @LINE1 = split(/\t/o,$a,-1);     @LINE2 = split(/\t/o,$b,-1);
      @DATA1{@COLUMNS} = @LINE1;       @DATA2{@COLUMNS} = @LINE2;
      
      my $d1 = $DATA1{$date_string};  # Extract the string (normal
      my $d2 = $DATA2{$date_string};  # writing) representation of a date
      my $p1 = &DecodeDateandTime($d1); # Convert them to fractional days
      my $p2 = &DecodeDateandTime($d2); # since January 1, 1900.
      
      # These warning messages are important.
      die "DIED: $d1 did not parse as a date on the following line ",
          "@LINE1\n" if(not defined $p1);
      die "DIED: $d2 did not parse as a date on the following line ",
          "@LINE2\n" if(not defined $p2);
         
      &printLine(\@COLUMNS,\%DATA1);  # Always print the first line
         
      # If a gap is needed then do it.
      &gap_insertion(\@COLUMNS, $p1, $p2,
                     $abort_limit, $date_string, $mval)
             if($abort_limit > 0 and
                abs($p2 - $p1) > $abort_limit);

      $a = $b;  # The soon to be first line becomes the current old.
      if(eof(INFH)) { &printLine(\@COLUMNS,\%DATA2); last; }
   }
    
   close(INFH);  close(OUTFH);
}

exit;


##############################################################
# SUBROUTINES
##############################################################

sub gap_insertion {
   my ($cols, $date1, $date2, $abort_limit, $date_string, $mval) = @_;
   my @cols = @$cols;
   my $mid = &RecodeDateandTime(($date2+$date1)/2);
   my %quasidata = ();
   # note use of the global variable COLUMNS
   foreach my $key (@cols) {
      $quasidata{$key} = "$mval", next if($key ne $date_string);
      $quasidata{$key} = $mid;
   }
            
   # Print out the fake missing record line
   &printLine(\@cols,\%quasidata);
}

sub printLine {
   my ($cols, $hash) = @_;
   my @cols = @$cols;
   my %hash = %$hash;
   my @line = @hash{@cols};
   print OUTFH join("\t",@line),"\n";
}


sub help {
   print <<'HERE';

dtgaprdb.pl -- Date Time Gap RDB

  A utility to insert fake missing records based on
  defined jumps of time for RDB files.
               
  by William H. Asquith
  
dtgaprdb.pl takes an rdb file and if and only if there is a
column that case insensitively matches DATE or TIME, scans the
file and inserts fake missing values and a fake time stamp if
the interval between two consecutive date-time values is larger
than a user defined value.  This is a handy utility because Tkg2
does not know how to read file headers to determine whether or
not a file has a constant time step.  The fake missing values
line cause tkg2 to 'lift the pen' when drawing line points.

The program will terminate with a warning if no columns titles
matching any combination of DATE and TIME.  Also as a warning,
only the first column matching DATE or TIME is used as nearly all
'time series' files would (should) not have two or more date-time
columns.  A vast array of date-time value formats are possible,
but they must be combined in the same field as tkg2 requires this.

The options are of course optional, the infile and outfiles are
also optional.  If the infile is absent, standard input is read
instead, and if the outfile is absent, standard output is written
to.

Usage:  dtgaprdb.pl <options> <infile> <outfile>

Options:

   -dayabort=float   The maximum permissible time interval in days.
    
   -help             This help.
    
   -hrsabort=float   The maximum permissible time interval in hours.
    
   -minabort=float   The maximum permissible time interval in minutes.
    
   -missval=string   The missing value string to insert in all the
                        non-date fields. Defaults to an empty
                        string "".
   
  Note that all the *aborts default to 0 if not specified.  The
  following precedence is held if the abort options are duplicated, 
  which would be bad form anyway: hours, days, minutes.  The default
  abort limit is 0 unless specified solely by the options.  Parsing
  of the RDB header is not presently supported.

Option Aliases:

   -d=float          Same as -dayabort.  Although if -dayabort is
                         also present then the float with -dayabort
                         is used instead.
                         
   -h=float          Same as -hrsabort.  Although if -hrsabort is
                         also present then the float with -hrsabort
                         is used instead.
                         
   -mv=string        Same as -missval.  ALthough if -missval is also
                         present then the string with -missval is
                         used instead.

Examples:

  dtgaprdb.pl original.rdb > my_converted.rdb

  cat my.rdb | dtgaprdb.pl > my_converted.rdb

  dtgaprdb.pl original.rdb my_converted.rdb
  
  dtgaprdb.pl -missval=-- --hrs=2.5 in.rdb out.rdb
  
  dtgaprdb.pl -missval=-9999 --dayabort=1 in.rdb out.rdb

Note on the Date-Time Field Matching:
   /DATE|TIME/io is the Perl regular expression that is used to find the
      column title of the string field.  Thus the following are matched.
   DATE, TIME, DATE_TIME DTIME, DATET,
   date, time, date_time, . . . , my_date_column, time_date, . . .  

Note on the Inserted Date-Time Value:
   The mid-point of time between the two consecutive date-time values
   is used as the fake value for the inserted missing record.  For
   example, suppose 19390606 and 19390607@23:23 are two consecutive
   dates and that the abort limit is 1.5 days.  Then the inserted
   date value will be 1939060623:41:30.  This is illustrated in
   the following RDB file snippet.  The <t> denotes a tab character
   and there are no 'codes' in the file.
   
   datetime<t>value<t>code
   10d<t>12n<t>3s
   19390606<t>25<t>
   1939060623:41:30<t><t>
   19390607@23:23<t>16<t>
   
HERE
;
   exit;
}


# DecodeDateandTime
# Takes either an array reference or a scalar value and converts
# it to the internal time representation.
# It first tries the time cache and if we have seen that time
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
# A data base or other system might use 24:00:00 as a top of the day
# value, for plotting purposes the distinction is necessary but does
# not change the meaning of the data.
sub DecodeDateandTime {
   use strict;
   my ($field) = @_;
   
   # Here is what the parsed data looks like as a regex
   # (\d{4})(\d{2})(\d{2})(\d{2}):(\d{2}):(\d{2})$/;
   my $format = "A4 A2 A2 A2 x A2 x A2"; # code for the unpack function
   
   my $newfield = $field;
      $newfield =~ s/(.+)@(.+)/$1 $2/ if($newfield =~ m/@/o);
      $newfield = &ParseDateString($newfield);
   return undef unless($newfield);
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = unpack( $format, $newfield );
   my $day   = &Delta_Days( 1900, 1, 1, $yyyy, $mm, $dd );
   my $days  = &dayhhmmss2days( $day, $hh, $min, $ss );
   return $days;
}


# RecodeDateandTime turns day.fraction to a yyyymmddhh:mm:ss format
# The base date for the beginning of the epoch is 01/01/1900.
# This is not a big deal because time before then takes on negative values.
sub RecodeDateandTime {
   use strict;
   
   my $days = $_[0];
   my ($day, $hh, $min, $ss) = &days2dayhhmmss( $days );
   my ($yyyy, $mm, $dd);
   $day-- if($day < 0 and ($hh or $min or $ss)); # NEGATIVE TIME BUG FIX
   eval {
          ($yyyy, $mm, $dd) = &Add_Delta_Days( 1900, 1, 1, $day )
        };
   return undef if($@);
   $mm = sprintf("%2.2d",$mm);
   $dd = sprintf("%2.2d",$dd);
   $ss = sprintf("%2.2d",$ss);
   return "$yyyy$mm$dd$hh:$min:$ss";
}

1;

__DATA__
# This information includes the following fields:
#
#  site_id  ID (not included if only one station is shown)
#  datetime    date of measurement
#  value      discharge, in cubic-feet per-second
#
#
datetime	value	code
10d	12n	3s
19390601	36	
19390602	32	
19390603	32	
19390604	43	
19390605	41	
19390606	25	
19390607@23:23	16	
19390608@23:24	24	
19390610	20	


