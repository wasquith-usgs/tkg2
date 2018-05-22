#!/usr/bin/perl -w 

=head1 LICENSE

 This Tkg2 Utility program is authored by the enigmatic William H. Asquith.
     
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
# $Date: 2002/08/26 19:44:43 $
# $Revision: 1.4 $

use strict;
use Date::Manip 5.39;  # import the &ParseDateString method

&Date_Init("TZ=GMT") if($^O =~ /MSWin/o);

my $date = 0;
if(@ARGV) {
  $date = join(" ",@ARGV);
}
else {
   print "Enter your date for parse testing: ";
   $date = <STDIN>; chomp($date);
}


my $parsed = &isDate($date);
if($parsed) {
  print "  Your test date '$date' parsed to '$parsed'\n";
}
else {
  print "  This date did NOT parse here, so won't in tkg2 either.\n";
}

# Checking whether a string is a Date.  Tkg2 will also permit use use of
# the @ sign as in 10/04/2001@12:45
sub isDate {
   my $field = $_[0];
   my $return_val;
   $field =~ s/(.+)@(.+)/$1 $2/ if($field =~ m/@/o);
   $return_val = &ParseDateString($field); # returns false if it is a date
   return $return_val;
}
