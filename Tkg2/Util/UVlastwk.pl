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
# $Date: 2003/10/07 14:16:10 $
# $Revision: 1.8 $

use strict;
use Date::Calc qw( Add_Delta_Days );
use Date::Manip 5.39;  # import the &ParseDateString subroutine

use Getopt::Long;
my %OPTS = (); # command line options
my @options = qw ( h d=s s=s o=i ); # these are the valid command line options
&GetOptions(\%OPTS, @options); # parse the command line options

&help if($OPTS{h}); # help and exit

my $S      = ($OPTS{s}) ? uc($OPTS{s}) : "C";
# Specify various codes for the retrieval
my $DD     = ($OPTS{d}) ? $OPTS{d}     : 1;
# Set the offset multiplier on the week increment 
my $offset = ($OPTS{o}) ? $OPTS{o}+1   : 1;

use Sys::Hostname;  # import the &hostname subroutine
die "UVlastwk.pl: ".&hostname()." does not appear to be an NWIS server.\n"
   unless($_ = `nwts2rdb 2>&1` and /Usage/o);
    # The nwts2rdb command returns the 'Usage' if it is available
    
my $station = shift(@ARGV);
die "UVlastwk.pl: Please provide valid USGS station name on the command line.\n"
   unless(&_is_a_station($station)); 


# Determine the date range for the retrieval
my ($by, $bm, $bd) = &NOW_as_parsed_String();
my ($ey, $em, $ed) = &Add_Delta_Days($by, $bm, $bd, (-7*$offset));
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

UVlastwk.pl -- A wrapper on nwts2rdb for weekly unit-value retrievals.
  by William H. Asquith

This utility, which is shipped with the tkg2 distribution is a
handy tool for retrieving unit values from the NWIS data base in
rdb format for weekly intervals backwards from the present
time.  By default one week back is retrieved, but the -o
option can be used to add more previous weeks.

The utility uses the nwts2rdb command provided by an
NWIS host.  The -d option is a wrapper on the -d option
of the nwts2rdb command.  Likewise, so is the -s option
a wrapper on the -s option of the nwts2rdb command.
Consult the nwts2rdb man page for details.  UVlastwk.pl
reports the actual nwts2rdb command forked.

   Usage: UVlastwk.pl <options> station_number
          UVlastwk.pl 08167600
          UVlastwk.pl -d=19 08167600
          UVlastwk.pl -d=2 -s=E 08167600
          UVlastwk.pl -s=C -d=11 -o=2 08167000
          
   Options:
       -h This help.
          
       -d=<string>    Data descriptor number (-d=1 default).
                      Leading zeros can be passed in.
         
       -o=<integer>   Weekly offset multiplier (-o=1 default).
         
       -s=<string>    Statistic code (-s=C for computed or E for edited).

HERE
;
   exit;
}
