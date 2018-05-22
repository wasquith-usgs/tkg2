package Tkg2::DataMethods::Set::DataLimits;

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
# $Date: 2002/08/07 18:41:27 $
# $Revision: 1.22 $

use strict;

use Tkg2::Time::TimeMethods;
use Tkg2::Base qw(Show_Me_Internals);
use Exporter;

use vars qw(@ISA @EXPORT_OK);
@ISA = qw(Exporter);

@EXPORT_OK = qw(setDataLimits set_limits_on_first_data);

print $::SPLASH "=";

use constant  ONE   => scalar 1;
use constant ZERO   => scalar 0;
use constant S0d025 => scalar 0.025;
use constant S0d975 => scalar 0.975;
use constant S1d025 => scalar 1.025;
use constant S1d005 => scalar 1.005;

sub setDataLimits {
   # Sets plot-wide data maximum values w/o regard to the axis type
   # Should be called everytime data is added into a plot
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($plot, $xoy, $array_ref, $force_setting) = @_;
   my $ref = $plot->{$xoy};
   my $min = $ref->{-datamin};  # pointer to the data min 
   my $max = $ref->{-datamax};  # pointer to the data max 

   # force the setting of the linear limits by making undef   
   ($min->{-whenlinear},
    $max->{-whenlinear}) = (undef, undef) if($force_setting);
   
   my @data = @$array_ref;
   
   my ($b, $t); # Dane, thanks for discovering a bug here (now fixed).
   if(@data) {
      ($b, $t) = ($data[0], $data[$#data]);
      # the -whenlinear fields will always contain the overall data mins and maxes
      $min->{-whenlinear} = $b if(not defined $min->{-whenlinear} or
                                         $b < $min->{-whenlinear} );
      $max->{-whenlinear} = $t if(not defined $max->{-whenlinear} or
                                         $t > $max->{-whenlinear} );   
   }
   else {
      $min->{-whenlinear} = -10 if(not defined $min->{-whenlinear});
      $max->{-whenlinear} =  10 if(not defined $max->{-whenlinear});     
   }
   
         
   # SET ELIGIBLE LIMITS FOR LOG DATA
   if( $min->{-whenlinear} > ZERO and
       ( defined $min->{-whenlog} and
         $min->{-whenlinear} < $min->{-whenlog}
       ) ) { # if the $min is greater than zero then safe to set
      $min->{-whenlog} = $min->{-whenlinear};
   }
   else {
      foreach my $v (@data) { # find first eligible (>0) value
         next unless($v > ZERO);
         $min->{-whenlog} = $v, last
              if(not defined $min->{-whenlog} or
                        $v < $min->{-whenlog} );
      } 
   }
   
   
   if( $max->{-whenlinear} > ZERO and
       ( defined $max->{-whenlog} and
         $max->{-whenlinear} > $max->{-whenlog}
       ) ) { # if the $min is greater than zero then safe to set
      $max->{-whenlog} = $max->{-whenlinear};
   }
   else {
      # find first eligible (>0) value
      foreach my $v ( reverse @data ) { 
         next unless($v > ZERO);
         $max->{-whenlog} = $v, last
              if(not defined $max->{-whenlog} or
                        $v > $max->{-whenlog} );
      } 
   }
   
   
   # SET ELIGIBLE LIMITS FOR PROBABILITY DATA
   if(  $min->{-whenlinear} > ZERO and $min->{-whenlinear} < ONE
                                   and
       ( defined $min->{-whenprob} and
         $min->{-whenlinear} < $min->{-whenprob} )
     ) { # if the 0 < $min < 1 then safe to set
       $min->{-whenprob} = $min->{-whenlinear};
   }
   else {
      foreach my $v (@data) { # find first eligible value
         next unless( $v > ZERO and $v < ONE );
         $min->{-whenprob} = $v, last
              if(not defined $min->{-whenprob} or
                        $v < $min->{-whenprob} );
      } 
   }
   if(  $max->{-whenlinear} > ZERO and $max->{-whenlinear} < ONE
                                   and
       ( defined $max->{-whenprob} and
         $max->{-whenlinear} > $max->{-whenprob} )
     ) { # if the 0 < $max < 1 then safe to set
      $max->{-whenprob} = $max->{-whenlinear};
   }
   else {
      # find first eligible value, reverse!
      foreach my $v ( reverse @data ) { 
         next unless( $v > ZERO and $v < ONE );
         $max->{-whenprob} = $v, last
              if(not defined $max->{-whenprob} or
                        $v > $max->{-whenprob} );
      } 
   }
   
   
   # We need to have special provisions for the situations in which
   # the data limits are equal.  This yields funky looking axis limits
   # via the autoconfiguration.  If the data limits are equal then 
   # scale the limits up and down 2.5 percent.  The equal limit situation
   # usually occurs when only one data point is available or when
   # the restrictions on log or probability space reduce the data to one
   # value.
   if($min->{-whenlinear} == $max->{-whenlinear}) {
      if($min->{-whenlinear} >= 0) {
         $min->{-whenlinear} -= S0d025*$min->{-whenlinear};
         $max->{-whenlinear} += S0d025*$max->{-whenlinear};
      }
      else {
         $min->{-whenlinear} += S0d025*$min->{-whenlinear};
         $max->{-whenlinear} -= S0d025*$max->{-whenlinear};
      }
   }
   
   if(defined $min->{-whenlog} and defined $max->{-whenlog}) {
      if($min->{-whenlog} == $max->{-whenlog}) {
         my $minlog = $min->{-whenlog};
         my $maxlog = $max->{-whenlog};
      
         $min->{-whenlog} *= S0d975*$minlog;
         $min->{-whenlog}  = ONE if($min->{-whenlog} < ZERO);
       
         $max->{-whenlog} *= S1d025*$maxlog;
         $max->{-whenlog}  = 10  if($max->{-whenlog} < ZERO);
      }
   }
   
   if(defined $min->{-whenprob} and defined $max->{-whenprob}) {
      if($min->{-whenprob} == $max->{-whenprob}) {
         my $minprob = $min->{-whenprob};
         my $maxprob = $min->{-whenprob};
      
         $min->{-whenprob} *= S0d975*$minprob;
         $minprob = $min->{-whenprob};
         $min->{-whenprob}  = 0.001 if($minprob < ZERO or
                                       $minprob > ONE ); 
                                       
         $max->{-whenprob} *= S1d005*$maxprob;
         $maxprob = $min->{-whenprob};
         $max->{-whenprob}  = 0.999 if($maxprob < ZERO or
                                       $maxprob > ONE);
      }
   }
   # End of last ditch effort to get nice data limits
   print $::BUG "%% DataLimits::setDataLimits for $xoy axis\n",
                "%%   LINEAR $min->{-whenlinear} and $max->{-whenlinear}\n";

   print $::BUG "%%   LOG    $min->{-whenlog} and $max->{-whenlog}\n"
                   unless(not defined $min->{-whenlog} or
                          not defined $max->{-whenlog} );

   print $::BUG "%%   PROB   $min->{-whenprob} and $max->{-whenprob}\n"
                   unless(not defined $min->{-whenprob} or
                          not defined $max->{-whenprob} ); 
}   

# Regardless of whether the user is interested in autolimit determination
# or not, it is MANDATORY that things get auto configured the very first
# time that data is loaded into a plot via an interactive session.
# This subroutine is not called during run-time loading of data.
# This subroutine doesn't do anything if we are working on the second
# y axis, because the ONLY way to activate that axis is to load data
# into it so whatever benefit there is to the user's experience with
# tkg2 and this subroutine is not needed.
sub set_limits_on_first_data {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   # make a first guess as the plot limits and then restore auto settings
   # to those of the user subroutine should be called only when the dataclass
   # array is empty
   my ($self, $plot) = @_;   
   
   # the following if block is executed only once the very first time data
   # is loaded into or otherwise associated with a plot.  After that
   # this block is never needed.  When loading data on the fly, this issue
   # is not of any concern.

   return 0 unless(scalar(@$self) == ONE);
   return 0 if $plot->{-skip_axis_config_on_1st_data};

   my $xref = $plot->{-x};
   my $yref = $plot->{-y};
   my %x = ( -orig_min => $xref->{-autominlimit},
             -orig_max => $xref->{-automaxlimit} );
   my %y = ( -orig_min => $yref->{-autominlimit},
             -orig_max => $yref->{-automaxlimit} );
       
   # if the user went to the trouble to center the axis then
   # by all means lets follow up on it
   $xref->{-autominlimit} =
   $xref->{-automaxlimit} = 1 unless($xref->{-autominlimit} eq 'center' or
                                     $xref->{-automaxlimit} eq 'center');
                                   
   $yref->{-autominlimit} =
   $yref->{-automaxlimit} = 1 unless($yref->{-autominlimit} eq 'center' or
                                     $yref->{-automaxlimit} eq 'center');
       
   $plot->routeAutoLimits;
       
   # Now that we are back from the routeAutoLimit call, we can
   # restore the original settings back to each axis.
   # restoring the settings to the x axis
   $xref->{-autominlimit} = $x{-orig_min};
   $xref->{-automaxlimit} = $x{-orig_max};
   # restoring the settings to the y axis
   $yref->{-autominlimit} = $y{-orig_min};
   $yref->{-automaxlimit} = $y{-orig_max};
       
   return 1;
}  

1;
