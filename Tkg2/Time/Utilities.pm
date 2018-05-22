package Tkg2::Time::Utilities;

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
# $Date: 2001/08/17 12:28:04 $
# $Revision: 1.10 $

use strict;

use vars qw(@ISA @EXPORT_OK);
@ISA    = qw(Exporter);
@EXPORT_OK = qw(
                 hhmmss2fracday
                 dayhhmmss2days
                 parsedays
                 days2dayhhmmss
                 fracday2hhmmss
               );


use constant S24 => scalar 24;
use constant S60 => scalar 60; 


# The following 5 methods provide simple little utilities for manipulating
# the internal tkg2 time representation.  All of these utilities are exported
# by default since they are so often intermingled with on an other.  It would
# be slightly faster to inline the logic of these methods in side the calling
# subroutines but the logic is much cleaner to have these little functions
# abstracted out.

# hhmmss2fracday:
# convert a list of hours, minutes, and seconds to a 
# decimal fraction of a day, note that 24,00,00 converts to
# 1 (the next day).
sub hhmmss2fracday {
   return ($_[0]+(($_[1]+($_[2]/S60))/S60))/S24;
}

# dayhhmmss2days:
# convert a list of (days, hours, minutes, seconds) to 
# a real number days.frac
sub dayhhmmss2days {
   return ($_[0]+($_[1]+(($_[2]+($_[3]/S60))/S60))/S24);
}

# parsedays
# parse days.frac to ($days, $frac)
sub parsedays {
   my ($day, $frac) = $_[0] =~ m/([-+]?\d+)([.]\d+)?/; # is there a faster way?
   $day  = 0.0 unless( defined $day  );
   $frac = 0.0 unless( defined $frac );
   return ($day, $frac);
}

# days2dayhhmmss:
# convert days.frac to (days, hours, minutes, seconds)
sub days2dayhhmmss {
   my ($day, $fra) = &parsedays($_[0]);
   return ( $day, &fracday2hhmmss($fra) );
}

# fracday2hhmmss:
# convert .frac of day to (hours, minutes, seconds)
sub fracday2hhmmss {
   my $v = $_[0];
   $v *= S24;
   my $hr  = sprintf("%2.2d", int("$v") ); # can not remember, why ""
   $v = ($v-$hr)*S60;
   my $min = sprintf("%2.2d", int("$v") ); # but hard to test, just leave
   $v = ($v-$min)*S60;
   my $ss  = sprintf("%2.2d", int("$v") ); # as is
   return $hr, $min, $ss;
}

1;
