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
# $Date: 2004/01/05 19:07:37 $
# $Revision: 1.1 $

use strict;

use Getopt::Long;
my %OPTS = (); # command line options
my @options = qw ( b=i d=s h s=s ); # these are the valid command line options
&GetOptions(\%OPTS, @options); # parse the command line options

&help if($OPTS{h}); # do help and exit

my $S  = ($OPTS{s}) ? uc($OPTS{s}) : "C";
my $DD = ($OPTS{d}) ? $OPTS{d} : '1'; # Specify various codes for the retrieval

use Sys::Hostname;  # import the hostname subroutine
die "UVgetpor.pl: ".&hostname()." does not appear to be an NWIS server.\n"
   unless($_ = `nwts2rdb 2>&1` and /Usage/o);
    # The nwts2rdb command returns the 'Usage' if it is available
    
my $station = shift(@ARGV);
die "UVgetpor.pl: Please provide valid USGS station name on the command line.\n"
   unless(&_is_a_station($station));
 
my $exe = "nwts2rdb -c -tuv -aUSGS -n$station -d$DD -s$S -b0 -e99999999999999";

print "# Retrieval command was $exe\n";
system("$exe");

# -------- SUBROUTINES 
sub _is_a_station { return 1 if(defined $_[0] and $_[0] =~ /^\d+$/) }

sub _2digits { return sprintf("%2.2d", $_[0]) }

sub help {
print <<'HERE';

UVgetpor.pl -- A wrapper on nwts2rdb for period of record unit-value retrievals.
  by William H. Asquith
  
The script is convenient for retrieving daily values starting from the first
wateryear of record through the last water year of record.  Warning the first
and last water years are probably not going to have complete record because of
starting date of the station and today--literally today's date--not being
September 30.

   Usage: UVgetpor.pl <options> station_number

   Options:
       -h             This help.

       -d=<string>    Data descriptor number (-d=1 default).
                      Leading zeros can be passed in.

       -s=<string>    Statistic code (-s=C).

HERE
;
   exit;
}
