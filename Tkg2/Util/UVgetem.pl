#!/usr/bin/perl -w

=head1 LICENSE

 This Tkg2 helper program is authored by the enigmatic William H. Asquith.
     
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

## CVS STAMPS are present in every module and look like the following
# $Author: wasquith $
# $Date: 2004/08/05 13:34:19 $
# $Revision: 1.5 $

use strict;
use Date::Calc qw( Add_Delta_Days );
use Date::Manip 5.39;  # import the &ParseDateString subroutine

use Getopt::Long;
my %OPTS = (); # command line options
my @options = qw ( b=i d=s h s=s ); # these are the valid command line options
&GetOptions(\%OPTS, @options); # parse the command line options


&help if($OPTS{h}); # do help and exit

use Sys::Hostname;  # import the &hostname subroutine
die "UVgetem.pl: ".&hostname()." does not appear to be an NWIS server.\n"
   unless($_ = `nwts2rdb 2>&1` and /Usage/o);
    # The nwts2rdb command returns the 'Usage' if it is available
    
my $station = shift(@ARGV);
die "UVgetem.pl: Please provide valid USGS station name on the command line.\n"
   unless(&_is_a_station($station)); 

my $S  = ($OPTS{s}) ? uc($OPTS{s}) : "C";
my $DD = ($OPTS{d}) ? $OPTS{d} : 1; # Specify various codes for the retrieval
my $days_back  = ($OPTS{b}) ? $OPTS{b} : -7;
   $days_back *= -1 unless($days_back < 0);
 
# Determine the date range for the retrieval
my ($by, $bm, $bd) = &NOW_as_parsed_String();
my ($ey, $em, $ed) = &Add_Delta_Days($by, $bm, $bd, $days_back);
map { $_ = &_2digits($_) } ($em, $ed);

my $now = join "", ($by, $bm, $bd);
my $beg = join "", ($ey, $em, $ed);
my $exe = "nwts2rdb -c -tuv -aUSGS -n$station -d$DD -s$S -b$beg -e$now";

print "# Retrieval command was $exe\n";
system("$exe");

# -------- SUBROUTINES 
sub _is_a_station { return 1 if(defined $_[0] and $_[0] =~ /^\d+$/o) }

sub _2digits { return sprintf("%2.2d", $_[0]) }

sub NOW_as_parsed_String {
   my @values = unpack("A4 A2 A2 A2 x A2 x A2", &ParseDateString('now'));
   
   # Make sure that single digits have leading zero
   map { $values[$_] = &_2digits($values[$_]); } (1..$#values);
   
   return @values; # (yyyy, mm, dd, hh, min, ss)
}



sub help {
print <<'HERE';

UVgetem.pl -- A wrapper on nwts2rdb for unit-value retrievals.
  by William H. Asquith
  
The script is convenient for retrieving unit-values starting from right now
backwards in time a specified number of days.

   Usage: UVgetem.pl <options> station_number

   Options:
       -h             This help.
    
       -b=<integer>   How many days backwards from now to make the retrieval.
                      (-b=-7 default).  If the negative sign is omitted, it
                      will be added internally.
    
       -d=<string>    Data descriptor number (-d=1 default).
                      Leading zeros can be passed in.
 
       -s=<string>    Statistic code (-s=C for computed or E for edited).

HERE
;
   exit;
}
