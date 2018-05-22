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
# $Date: 2002/08/07 18:26:57 $
# $Revision: 1.8 $

use strict;

use Date::Calc qw(Delta_Days);
use Date::Manip;

use Sys::Hostname;
my $HOSTNAME = &hostname;

use constant S24 => scalar 24;
use constant S60 => scalar 60;

use Text::Wrap qw($columns &wrap);
   $columns = 50;  # columns is actually a global variable for 
                   # the wrap module.  They did not use capital
                   # letters.
my $FILE = "/tmp/tkg2.log";
&performOutput(&processLogFile());
exit;


######################################
# SUBROUTINES
######################################
sub processLogFile {
   my %log;
   my @entries = qw(-tkg2 -version -date -user -options -files -message);
   my %users;
   my %files;
   my %time_series;
    
   open(FH, "<$FILE") or die "$FILE not opened because $!\n";
   
   # Read the first line and process
   $_ = <FH>;  chomp;
   
   my @line = split(/\|/o, $_, -1);
   my ($begin, $end) = ($line[2], $line[2]);
   
   @log{@entries} = @line;
   $users{$log{-user}}++;
   map { $files{$_}++; } split(/ /o,$log{-files});
   
   my ($yyyy, $mm, $dd) = &Date2YMDHMS($log{-date});
   $time_series{"$yyyy"."$mm"."$dd"}++;

   # now iterate through the entire file
   while(<FH>) {
      chomp;
      @line = split(/\|/o, $_, -1);
      @log{@entries} = @line; 
      $users{$log{-user}}++;
      $end = $line[2];
      map { $files{$_}++; } split(/ /o,$log{-files});
 
      my ($yyyy, $mm, $dd) = &Date2YMDHMS($log{-date});
      $time_series{"$yyyy"."$mm"."$dd"}++;
   }
   close(FH);
   return ($begin, $end, \%users, \%files, \%time_series);
}


sub performOutput {
   my ($begin, $end, $users, $files, $time) = @_;
   my %users = %$users;
   my %files = %$files;
   my %time  = %$time;

   my $days = sprintf("%4.3f", &totalDays($begin, $end));
   print "# TKG2 LOG FILE SUMMARY\n# $FILE summarized by $0\n",
         "# Hostname = $HOSTNAME\n";
   
   my $count = 0;
   foreach (sort keys %users) {
      $count += $users{$_};
      my $padded_user  = pack("A10",$_);
      my $padded_time  = sprintf("%4d", $users{$_});
         $padded_time .= ($padded_time == 1) ? "  time)" : " times)";
      print "#   $padded_user ($padded_time\n";
   }
   
   print "#*************************************************\n",
         "DATE\tCOUNT\nd\tn\n";
   map { my ($yyyy, $mm, $dd) = unpack("A4A2A2",$_);
         my $val = sprintf("%6d",$time{$_});
         print "$mm/$dd/$yyyy\t$val\n";
       } sort keys %time;
   
   # report on the number of users, the time frame, and the rate
   my ($rate_by_days, $rate_by_use ) = ( int( $count / int($days+1) ),
                                         int( $count / scalar(keys %time)));
   my ($no_users, $no_files) = ( scalar( keys %users ),
                                 scalar( keys %files ) );

   my $user_count_text = ($no_users == 1) ? 'user' : 'users';
   my $text = <<HERE
Beginning on $begin and ending on $end a total of $no_users 
unique $user_count_text have used tkg2 on the $HOSTNAME host.  This
corresponds to a grand total of $count executions, which
means that in $days days we are seeing a tkg2
execution rate of $rate_by_days times a day counting the days
that tkg2 was not used.  Whereas, the execution rate is $rate_by_use
times a day not counting non-usage days.  The users
viewed or processed approximately $no_files unique
tkg2 files.  The number of files likely seems small compared
to the execution rate or number of executions, but remember that
many of the NWIS-Tkg2 implementations use the same temporary file
names.
HERE
;

   $text =~ s/\s*\n/ /og;
   $text = &wrap("  ","",$text);
   map { print "# $_\n" } split(/\n/o,$text);
}

 
sub Date2YMDHMS {
   my ($date) = @_;
       $date  = &ParseDateString($date); # Provided by Date::Manip
   return undef unless($date);
   # Unpack is used because $val is a fixed width string
   return unpack("A4 A2 A2 A2 x A2 x A2", $date);
}


sub _days_since {
   my ($date) = @_;
   my ($yyyy, $mm, $dd, $hh, $min, $ss) = &Date2YMDHMS($date);        
   my $day  = &Delta_Days(1900, 1, 1, $yyyy, $mm, $dd);
   my $days = &dayhhmmss2days($day,$hh,$min,$ss);
   return $days;
}


# dayhhmmss2days:
# convert a list of (days, hours, minutes, seconds) to 
# a real number days.frac
sub dayhhmmss2days { return ($_[0]+($_[1]+(($_[2]+($_[3]/S60))/S60))/S24); }

sub totalDays { return (&_days_since($_[1]) - &_days_since($_[0])); }

1;
