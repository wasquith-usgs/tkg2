#!/usr/bin/perl -w
use strict;

use Date::Manip 5.39;
use Date::Calc qw(Delta_Days);
use constant S24 => scalar 24;
use constant S60 => scalar 60; 

use Getopt::Long;
my %OPTS = ();                 # Command line options
my @options = qw ( h );        # Valid command line options
&GetOptions(\%OPTS, @options); # Parse the command line options

&help if($OPTS{h}); # do help and exit


die "DIED: $0 requires exactly two date-time entries on the command line\n",
    "in order to compute an floating point days offset between them.\n",
    "Try --help for assistance.\n",
    unless(@ARGV == 2);

my ($d1,$d2) = @ARGV;

my ($offset,$message) = &ComputeDaysBetween($d1,$d2);

if(not $message) {
   print "OFFSET=$offset\n";
}
else {
   warn "DIED: $message\n";
}

exit;

#######################################################################
# SUBROUTINES
#######################################################################
sub ComputeDaysBetween {
   my ($date1, $date2) = @_;
   
   my ($c1, $c2) = (&DateandTime_to_Days($date1),
                    &DateandTime_to_Days($date2));
   
   my ($offset, $message) = (undef, 0);
   
   $message = &BadDate($date1), return ($offset, $message) if(not $c1);
   $message = &BadDate($date2), return ($offset, $message) if(not $c2);
   
   $offset = $c2 - $c1;
   return ($offset, $message);
}

sub BadDate {
   my ($date) = @_;
   return "'$date' does not parse as a valid date-time value.";
}


sub DateandTime_to_Days {
   my ($field) = @_;
   
   # Here is what the parsed data looks like as a regex
   # (\d{4})(\d{2})(\d{2})(\d{2}):(\d{2}):(\d{2})$/;
   my $format = "A4 A2 A2 A2 x A2 x A2"; # code for the unpack function
   # ParseDateString does not handle the '@' sign, so we will
   # strip it out.
   $field =~ s/(.+)@(.+)/$1 $2/ if($field =~ m/@/o);
   $field = &ParseDateString($field);
   return undef unless($field);
   
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = unpack( $format, $field );
   my $day   = &Delta_Days( 1900, 1, 1, $yyyy, $mm, $dd );
   my $days  = &dayhhmmss2days( $day, $hh, $min, $ss );
   return $days;
}

# dayhhmmss2days:
# convert a list of (days, hours, minutes, seconds) to 
# a real number days.frac
sub dayhhmmss2days {
   return ($_[0]+($_[1]+(($_[2]+($_[3]/S60))/S60))/S24);
}

sub help {
   print <<'HERE';

daysbetween.pl -- Compute days between two dates.
  by William H. Asquith

This utility, which is shipped with the tkg2 distribution, is a
quick to compute the floating point offset of the number of
days between two dates provided on the command line.

The offset can be useful in determining the date-time offset
for Tkg2 or other software.  For example, it is often
convenient to plot two hydrographs for different locations
on the same river in an over lapping fashion.  The daysbetween.pl
program could compute the offset between the flood peak times
and provide a better offset than just guessing.

Usage: daysbetween.pl <options> date1 date2

Options:
    -h             This help.

Examples:
    % daysbetween.pl now '1969-10-04'
    OFFSET=-11772.1038773148
    % daysbetween.pl now '1969 10 04'
    OFFSET=-11772.1039467593
    % daysbetween.pl 19691004 2001/05/05 
    OFFSET=11536
    % daysbetween.pl 2001/05/0514:30 '2002 10 04'
    OFFSET=516.395833333336
    % daysbetween.pl 2001/05/05@14:30 '10.04.2002@12:12'
    OFFSET=516.904166666667

HERE
;
exit;
}
