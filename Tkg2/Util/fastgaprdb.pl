#!/usr/bin/perl -w
use strict;

## CVS STAMPS are present in every module and look like the following
# $Author: wasquith $
# $Date: 2006/09/15 20:00:23 $
# $Revision: 1.3 $

use Date::Calc qw(Delta_DHMS); # library for date math

use constant S60 => scalar 60; # setting some constants for speed increase
use constant S24 => scalar 24; # a value of 60 (for minutes) and 24 (for hours)

# Workout what the command line options are and parse them.
use Getopt::Long;

my $VERSION = 0;
my %OPTS    = ();
# these are the valid command line options
my @options = qw ( help step=f missval=s mv=s );
&GetOptions(\%OPTS, @options); # parse the command line options

die "$0 Version $VERSION\n" if($OPTS{version});

my $TIMESTEP_IN_MINUTES;
if(defined $OPTS{step}) {
  $TIMESTEP_IN_MINUTES = $OPTS{step};
}
else {
  die "DIED: Command line option --step=float for the time step in minutes is required!\n";
}

# Work on the alias for the missing value
$OPTS{missval}    = $OPTS{mv} if(defined $OPTS{mv});  
my $MISSING_VALUE = (defined $OPTS{missval}) ? $OPTS{missval} : "";

&help, exit if($OPTS{help});

############# AND AWAY WE GO ########################
my ($input, $output) = @ARGV;
$input  = '/dev/stdin'  if(not defined $input  or $input  =~ m/stdin/io);
$output = '/dev/stdout' if(not defined $output or $output =~ m/stdout/io);

open(IH, "<$input")  or die "DIED: $input not opened for input because $!\n";
open(OH, ">$output") or die "DIED: $output not opened for output because $!\n";

# FIRST READ/WRITE HEADER, LABEL LINE, AND THE FORMAT LINE
my (@labels);
while(<IH>) {
  if(/^#/o) { print OH; next; }
  print OH $_;
  @labels = split(/\t/o,$_);
  $_ = <IH>;
  print OH $_;
  last;
}
# THEN LOAD IN ALL THE DATA
my (%DATA, %line)  = ();
while(<IH>) {
  @line{@labels} = split(/\t/o,$_);
  $DATA{$line{DATETIME}} = { %line };
}
close(IH);


# DETERMINE THE NUMBER OF COLUMNS AND BUILD THE FAKE RECORD
my $numcol = scalar(@labels);
my $missing_record = "";
foreach (1..$numcol-1) { $missing_record .= "$MISSING_VALUE\t" }
$missing_record .= "$MISSING_VALUE";
############################################################


# LOOP THROUGH IN CHRONOLOGICAL ORDER AND WRITE RECORDS
# AND INSERT MISSING VALUES AS NEEDED
my @order = sort keys %DATA;
my ($today,$tomorrow, @line);
foreach my $i (0..$#order-1) {
  $today    = $order[$i];
  $tomorrow = $order[$i+1];

  %line = %{$DATA{$today}};
  @line = @line{@labels};
  print OH join("\t",(@line));

  my ($i_yy,$i_mm,$i_dd,$i_hh,$i_mn,$i_ss) = unpack("A4A2A2A2A2A2",$today);
  my ($t_yy,$t_mm,$t_dd,$t_hh,$t_mn,$t_ss) = unpack("A4A2A2A2A2A2",$tomorrow);
  
  my ($D_d, $Dh, $Dm, $Ds) = Delta_DHMS($i_yy,$i_mm,$i_dd,$i_hh,$i_mn,$i_ss,
                                        $t_yy,$t_mm,$t_dd,$t_hh,$t_mn,$t_ss);
  my $DeltaMIN = $D_d*S24*S60 + $Dh*S60 + $Dm + $Ds/S60;  
  print OH "$missing_record\n" if($DeltaMIN > $TIMESTEP_IN_MINUTES); # a missing value
}


# FINALLY WRITE THE LAST LINE IN THE DATA FILE
$today = $order[$#order];
%line  = %{$DATA{$today}};
@line  = @line{@labels};
print join("\t",(@line));
close(OH);

################################ SUBROUTINES ##################################
sub help {
   print <<'HERE';

fastgaprdb.pl -- Fast Date Time Gap RDB

  A utility to insert fake missing records based on
  defined jumps of time for RDB files.
               
  by William H. Asquith
  
fastgaprdb.pl takes an rdb file and if and only if there is a
column that matches DATETIME, scans the file and inserts a record
of the missing value string if the interval between two consecutive
date-time values is larger than a user defined value. This is a
handy utility because Tkg2 does not know how to read file headers
to determine whether or not a file has a constant time step.
The fake missing values line cause tkg2 to 'lift the pen' when
drawing line points.

This program is optimized for speed. If you want general gapping
gapping in an RDB file---consult the program dtgaprdb.pl instead.
The general nature of dtgaprdb.pl involves general parsing of
the DATETIME value. For the fastgaprdb.pl program the DATETIME
value follows this convention: YYYYMMDDHHMMSS.

Finally, if you have a data file that in fact has seen variable
time intervals, your mileage will vary.

The options are of course optional, the infile and outfiles are
also optional. If the infile is absent, standard input is read
instead, and if the outfile is absent, standard output is written
to.

Usage:  fastgaprdb.pl <options> <infile> <outfile>

Options:

   --help             This help.
   
   --missval=string   The missing value string to insert in all the
                        columns. Defaults to an empty string "".
			
   --version          The version of the program is printed and 
                        followed by an exit.

Option Aliases:
                         
   --mv=string        Same as -missval. Although if --missval is also
                         present then the string with --missval is
                         used instead.

Examples:

  fastgaprdb.pl original.rdb > my_converted.rdb

  cat my.rdb | fastgaprdb.pl > my_converted.rdb

  fastgaprdb.pl original.rdb my_converted.rdb
  
  fastgaprdb.pl -missval=-- in.rdb out.rdb
  
  fastgaprdb.pl -missval=-9999 in.rdb out.rdb
   
HERE
;
   exit;
}


