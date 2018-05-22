package Tkg2::Plot::AxisConfiguration;

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
# $Date: 2003/10/14 20:46:04 $
# $Revision: 1.44 $

use strict;
use vars qw(@ISA @EXPORT_OK
            %STEP_TABLE     %RANGE_TABLE
            @PRETTY_LOG_MAX @PRETTY_LOG_MIN);

use Exporter;

@ISA = qw(Exporter);
@EXPORT_OK = qw(routeAutoLimits autoConfigurePlotLimits makeAxisSquare);  
 
use Tkg2::Base qw(Message log10 Show_Me_Internals repackit); 
use Tkg2::Time::TimeMethods;


print $::SPLASH "=";

use constant ZERO        => scalar  0   ;
use constant TEN         => scalar 10   ; 
use constant ONEANDTENTH => scalar  1.1 ;
use constant ONE         => scalar  1   ;
use constant TWO         => scalar  2   ;
use constant TENTH       => scalar  0.10; 
use constant MAGICRATIO  => scalar  0.05;

# range table holds pretty combinations of linear steps
#                   RANGE      STEP
%RANGE_TABLE = ( -lessthan2inch => [
                       0  => .25,
                       1  => .5,
                       2  => 1,
                       3  => 1,
                       5  => 1,
                       10 => 'END' ],
                 -default       => [
                       0  => 0.1,
                       1  => 0.2,
                       2  => 0.25,
                       3  => 0.5,
                       5  => 1,
                       10 => 'END' ],
               );

# Step table holds pretty combinations of minor step numbers
# depending upon how big the step was
#                   STEP     NUM-SUBINTERVALS                
%STEP_TABLE = ( -lessthan2inch => {
                        0.1  => 0,
                        0.2  => 0,  
                        0.25 => 0, 
                        0.5  => 0,
                        1    => 1 },
                -lessthan3inch => {
                        0.1  => 1,
                        0.2  => 2,  
                        0.25 => 3, 
                        0.5  => 3,
                        1    => 3 },
                -default       => {
                        0.1  => 4,
                        0.2  => 3,  
                        0.25 => 4, 
                        0.5  => 4,
                        1    => 4 } );

# contains the fraction of nice even log cycles
@PRETTY_LOG_MAX = ( 0, log10(1.5), log10( 2), log10( 3), log10(4),
                       log10(  6), log10( 8), log10(10) );
@PRETTY_LOG_MIN = ( 1, log10(.15), log10(.2), log10(.3), log10(.4),
                       log10(.6 ), log10(.8), log10( 1) );


# EXPORT_OK METHOD = routeAutoLimits
#   use'd by Plot2D.pm 
# routeAutoLimits is called from the methods in
# Tkg2::DataMethods::Class:LoadData and provides for 
# automatic configuration of axis limits based on the -auto*limit flags
# It is only through here that the 'center' option can be utilized
sub routeAutoLimits {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($plot,$axis)  = (shift, shift);
   # note that $axis is only potentially set by the Instructions.pm
   # module for operation on only specific axis values.  If $which_axis
   # is undef, which it usually will be, then all the axis will be 
   # autolimited.
   
   my %axis = (not defined $axis) ? qw(-x 1 -y 1 -y2 1) : %$axis;
   
   # decision tree for autoconfiguration of the axis limits based on the 
   # the actual cumulative data that has been read in to date on this plot
   
   # Route the x-axis through the autoConfigurePlotLimits
   if($axis{-x}) {
      my $xref  = $plot->{-x};
      my $mnref = \$xref->{-autominlimit};
      my $mxref = \$xref->{-automaxlimit};
      if($$mnref eq 'center' or $$mxref eq 'center') {
         $$mnref = $$mxref = 'center'; # use opportunity to insure each is 'center'
         &autoConfigurePlotLimits($plot,'-x','center');
      }
      else {
         SWITCHa: { # the above if could be part of switch, but code looks nicer
          &autoConfigurePlotLimits($plot,'-x'), last SWITCHa if($$mnref && $$mxref);
          &autoConfigurePlotLimits($plot,'-x','justmin'), last SWITCHa  if($$mnref);
          &autoConfigurePlotLimits($plot,'-x','justmax'), last SWITCHa  if($$mxref);
         }
      }
   }
   
   
   # Route the y-axis through the autoConfigurePlotLimits
   my @yaxis;
   push(@yaxis, '-y' ) if( $axis{-y}  );
   push(@yaxis, '-y2') if( $axis{-y2} );
   
   foreach my $yax (@yaxis) {
      my $yref  = $plot->{$yax};
      my $mnref = \$yref->{-autominlimit};
      my $mxref = \$yref->{-automaxlimit};
      if($$mnref eq 'center' or $$mxref eq 'center') {
         $$mnref = $$mxref = 'center'; # use opportunity to insure each is 'center'
         &autoConfigurePlotLimits($plot,$yax,'center');
      }
      else {
         SWITCHb: { # the above if could be part of switch, but code looks nicer
            &autoConfigurePlotLimits($plot,$yax), last SWITCHb if($$mnref && $$mxref);
            &autoConfigurePlotLimits($plot,$yax,'justmin'), last SWITCHb  if($$mnref);
            &autoConfigurePlotLimits($plot,$yax,'justmax'), last SWITCHb  if($$mxref);
         }
      }
   }
   # no auto configuration is performed when if the SWITCH does not catch
   
   # possibly make the axis square
   &makeAxisSquare($plot);
}   

sub makeAxisSquare {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my $plot  = shift;
   my $xref  = $plot->{-x};
   my $yref  = $plot->{-y};
   my $y2ref = $plot->{-y2};
   
   # leave this sub unless a request for possibly squaring the axis is made
   return 0 unless($yref->{-make_axis_square} or $y2ref->{-make_axis_square});
   
   # even if a request has been made, it will not necessarily happen unless
   # both axis are of the same type and they are either linear or log
   
   # get the plot width and height in inches
   my ($width, $height) = $plot->getPlotWidthandHeight;
   map { s/i//o } ($width, $height);
   
   my $xmin  = $xref->{-min};
   my $xmax  = $xref->{-max};
   
   my $ymin  = $yref->{-min};
   my $ymax  = $yref->{-max};
   
   my $y2min = $y2ref->{-min};
   my $y2max = $y2ref->{-max};
   
   # These are the values that will possibly be changed and then
   # the y and y2 axis limits will be set to ymax2 or y2max2, respectively
   # at the end of the subroutine
   my $ymin2  = $ymin;
   my $ymax2  = $ymax;
   my $y2min2 = $y2min;
   my $y2max2 = $y2max;
   
   # anonymous subroutine to square up linear axis
   # this subroutine is used by y and y2 axis   
   my $_square_linear =
      sub {
         my ($xmin, $xmax, $ymin, $ymax, $width, $height) = @_;
         my $yMid  = ($ymax+$ymin) / TWO;
         my $const = ($height/$width) * ($xmax-$xmin) / TWO;
         my $ymin2 = $yMid - $const;
         my $ymax2 = $yMid + $const;
         my $xrate = ($xmax-$xmin  )  / $width;
         my $yrate = ($ymax2-$ymin2 ) / $height;
         print STDERR "_square_linear warning: xrate = $xrate; yrate = $yrate\n"
               if(abs($xrate - $yrate) > 10e-5);
         return ($ymin2, $ymax2);
      };
   
   # anonymous subroutine to square up log axis
   # this subroutine is used by y and y2 axis
   my $_square_log =
      sub {
         my ($xmin, $xmax, $ymin, $ymax, $width, $height) = @_;
         $xmin     = log10($xmin);
         $xmax     = log10($xmax);
         $ymin     = log10($ymin);
         $ymax     = log10($ymax);
         my $yMid  = ($ymax - $ymin) / TWO;
         my $const = ($height/$width) * ($xmax-$xmin) / TWO;
         my $ymin2 = $yMid - $const;
         my $ymax2 = $yMid + $const;
         my $xrate = ($xmax  - $xmin  ) / $width;
         my $yrate = ($ymax2 - $ymin2 ) / $height;
         print STDERR "_square_log warning: xrate = $xrate; yrate = $yrate\n"
               if(abs($xrate - $yrate) > 10e-5);
         return (TEN**$ymin2, TEN**$ymax2);
      };
   
   # Work on the first y axis
   if($yref->{-make_axis_square} and $xref->{-type} eq $yref->{-type} ) {
      my @args = ( $xmin, $xmax, $ymin, $ymax, $width, $height);
      if($xref->{-type} =~ m/linear/io) {
         ($ymin2, $ymax2) = &$_square_linear(@args);
      }
      elsif($xref->{-type} =~ m/log/io) {
         ($ymin2, $ymax2) = &$_square_log(@args);
      }
      elsif($xref->{-type} =~ m/prob/io) {
         # do nothing to square the axis, but reset the -make_axis_square
         # to false.  This is an attempt to be somewhat consistent with
         # other checkbuttons that turn themselve off when some thing
         # in appropriate is done.  That way if someone reports a self
         # toggling as a bug we will know what to do as opposed to the
         # button staying on and trying to track down way the axis
         # does not come out square
         $yref->{-make_axis_square} = 0;
      }
      else {
         print "makeAxisSquare: could not route axis type $xref->{-type}\n"; 
      }
   }
   
   # Work on the second y axis
   if($y2ref->{-turned_on} and
      $y2ref->{-make_axis_square} and $xref->{-type} eq $yref->{-type} ) {
      my @args = ( $xmin, $xmax, $y2min, $y2max, $width, $height );
      if($xref->{-type} =~ m/linear/io) {
         ($y2min2, $y2max2) = &$_square_linear(@args)
      }
      elsif($xref->{-type} =~ m/log/io) {
         ($ymin2, $ymax2) = &$_square_log(@args)
      }   
      elsif($xref->{-type} =~ m/prob/io) {
         # nothing to do, but to toggle false
         $y2ref->{-make_axis_square} = 0;
      }
      else {
         print "makeAxisSquare: could not route axis type $xref->{-type}\n"; 
      }
   }
   
   # finally possibly reset the axis limits
   $yref->{-min}  = $ymin2;
   $yref->{-max}  = $ymax2;
   $y2ref->{-min} = $y2min2;
   $y2ref->{-max} = $y2max2; 

   my $wh2compare = $height;  # since we're modifying the y axis, then
   # the width or height to compare is just height.

   # the new limits have been determined, but not nice looking step lengths
   # or the number of minor ticks
   # Y axis
   my ($step, $numminor) =
                     &_determine_step_and_numminor($ymin, $ymax2,$wh2compare);
   $yref->{-majorstep} = $step;
   $yref->{-numminor}  = $numminor;
   
   # Y2 axis
      ($step, $numminor) =
                     &_determine_step_and_numminor($y2min, $y2max2,$wh2compare);
   $y2ref->{-majorstep} = $step;
   $y2ref->{-numminor}  = $numminor;

   # recode the linear limits to time to force consistency
   $yref->{-time}->{-min}  = &RecodeTkg2DateandTime($ymin2);
   $yref->{-time}->{-max}  = &RecodeTkg2DateandTime($ymax2);
   $y2ref->{-time}->{-min} = &RecodeTkg2DateandTime($y2min2);
   $y2ref->{-time}->{-max} = &RecodeTkg2DateandTime($y2max2);
   
   return 1;
}


# EXPORT_OK METHOD = autoConfigurePlotLimits
#   use'd by Plot2D.pm   
# autoConfigurePlotLimits is called by routeAutoLimits and directly
# used in the ContinuousAxisEditor when axis types are changed.
# this method provides the major interface to the children methods
# that actually perform the configuration of 'nice' look axis limits and
# intervals.
sub autoConfigurePlotLimits {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($plot, $xoy) = ( shift, shift); # do not remove the shifting
   $xoy = ($xoy =~ /x/io ) ? '-x'  :
          ($xoy =~ /2/io ) ? '-y2' : '-y';
   my $aref  = $plot->{$xoy};
   my $type  = $aref->{-type}; 
   my $which = (@_) ? shift() : 1;
   
   
   my $mnref = $aref->{-datamin};
   my $mxref = $aref->{-datamax};
   my $mn  = (defined $mnref->{-whenlinear} ) ? $mnref->{-whenlinear} : 'undef';
   my $mx  = (defined $mxref->{-whenlinear} ) ? $mxref->{-whenlinear} : 'undef';
   my $mnl = (defined $mnref->{-whenlog}    ) ? $mnref->{-whenlog}    : 'undef';
   my $mxl = (defined $mxref->{-whenlog}    ) ? $mxref->{-whenlog}    : 'undef';
   my $mnp = (defined $mnref->{-whenprob}   ) ? $mnref->{-whenprob}   : 'undef';
   my $mxp = (defined $mxref->{-whenprob}   ) ? $mxref->{-whenprob}   : 'undef';
   print $::BUG "%% AxisConfiguration::autoConfigurePlotLimits for $xoy axis ",
                "using rule $which\n",
                "%%       Minimums (linear, log, prob)\n",
                "%%       $mn, $mnl, $mnp\n",
                "%%       Maximums (linear, log, prob)\n",
                "%%       $mx, $mxl, $mxp\n";
  
   # When data is imported these flags are already set, but if the user
   # modifies limits to "" in the ContinuousAxisEditor they need to 
   # be changed to reflect the user's last use so drawLabels will work
   if($which eq 'justmin') {
      $aref->{-autominlimit} = 1;
      $aref->{-automaxlimit} = 0;    
   }
   elsif($which eq 'justmax') {
      $aref->{-autominlimit} = 0;
      $aref->{-automaxlimit} = 1;   
   }
   elsif($which eq 'center') {
      $aref->{-autominlimit} = 'center';
      $aref->{-automaxlimit} = 'center';      
   }
   else { # which = 1 
      if($aref->{-autominlimit} ne 'center' or
         $aref->{-automaxlimit} ne 'center' ) {
         $aref->{-autominlimit} = 1;
         $aref->{-automaxlimit} = 1;  
      }
      else {
         $which = 'center';
      }
   }
   
   my $disref     = $aref->{-discrete};
   my $isDiscrete = $disref->{-doit};
   if($isDiscrete) { # if the axis is discrete then limits are easy
     # remember that we have two pseudo groups
     $aref->{-min} = 0;  # zero is always the first discrete group minus 1
     # the length of the values of the labelhash plus 1
     $aref->{-max} = scalar(keys( %{ $disref->{-labelhash} } )) + ONE;
   }
   else {
     SWITCH: {
      my @args = ($plot,$xoy,$which);
      &_autoConfigLinear(@args), last SWITCH if( $type eq 'linear'  );
      &_autoConfigTime(  @args), last SWITCH if( $type eq 'time'    );
      &_autoConfigLog(   @args), last SWITCH if( $type eq 'log'     );
      &_autoConfigProb(  @args), last SWITCH if( $type eq 'prob' or
                                                 $type eq 'grv'     );
      # just a good clean trap at the end of an exported method
      my $mess = "Invalid plot type $type in ".
                 "Tkg2::Plot::AxisConfiguration::autoConfigurePlotLimits\n"; 
      &Message($::MW,'-generic',$mess);
     }
   }
}

## LINEAR
## _autoConfigLinear
## Private subroutine for autoconfiguration of the limits for
## a Linear axis.  This is the third complete rework of the
## logical.  This time it seems to work, November 6, 1999.
# The new basis for the configuration is to:
#   1) determine range of data
#   2) determine a nice step interval for that range
#   3) determine a new min by stepping down or up from zero
#        until it is less than one step from the guessed min
#   4) determine a new max by stepping down or up from zero
#        until it is less than one step from the guessed max
sub _autoConfigLinear {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($plot, $xoy) = ( shift, shift); # do not remove the shifting
   my $which = (@_) ? shift() : 1;
         
   # find out how wide and how high the plot is so that 
   # we can make slight alteration to the step and range
   # tables for better looking plots
   my ($width, $height) = $plot->getPlotWidthandHeight;
   map { s/i$//o } ($width, $height);
   my $wh2compare = ($xoy =~ m/x/io) ? $width : $height;
   # width and height now are numbers so we can <=> using
   # the wh2compare variable because of axis dependency of
   # this subroutine

   ## BEGIN MAIN BODY OF SUBROUTINE 
   # my $magicratio = 0.05; now using a constant MAGICRATIO
   # the magic ratio provides a first guess beyond that data limits

   my $aref  = $plot->{$xoy};
   my $mnref = $aref->{-datamin};
   my $mxref = $aref->{-datamax};   
    
   if(not defined $mnref->{-whenlinear} or
      not defined $mxref->{-whenlinear} ) {
      #if($aref->{-discrete}->{-doit}) {
      #   my $mess = "WHOOPS about to have EMPTY PLOT WARNING, BUT".
      #              "AXIS IS DISCRETE.  Contact William Asquith.\n";
      #   &Message($::MW,'-generic',$mess);
      #}
      #my $mess = "Warning: Either the minimum or maximum limit ".
      #           "of the data is undefined for a linear axis. ".
      #           "Tkg2 is using default limits.";
      # &Message($::MW,'-generic',$mess); # DOUBLE Y:
      
      # setting here is just a rough patch, these values
      # are best left undef until data is actually read-in
      #$mnref->{-whenlinear} = -10;
      #$mxref->{-whenlinear} =  10;
      return;
   }
   # the following conditionals make use of a logic that looks like
   # int(minmax / step +- 1)*step to make the final estimate of the
   # minimum or maximum for an axis.  By dividing by the step and then
   # shifting either positive or negative by an addtion step length (1)
   # and then returning the integer multiplied back again by the step 
   # length, we have a limit that is exactly divisible by the step
   my ($min, $max, $step, $numminor, $range);
   if($which eq 'center') { # available through the routeAutoLimits method and
                            # a few hoops are jumped through the
                            # autoConfigurePlotLimits 
      $min                = $mnref->{-whenlinear};
      $max                = $mxref->{-whenlinear};
      $range              = $max - $min;
      $min               -= ( $range * MAGICRATIO );
      $max               += ( $range * MAGICRATIO );
      ($step, $numminor)  =
               &_determine_step_and_numminor($min, $max, $wh2compare);
      $min                = int($min/$step - 1)*$step;
      $max                = int($max/$step + 1)*$step;
      if($max > 0 and $min < 0) { # ok the limits sandwitch zero
      # when this happens, then the concept of centering the origin
      # in the plot actually makes sense
         my $up = $max - ZERO;
         my $dn = ZERO - $min;
         ($up > $dn) ? ($min = -$max ) : ( $max = -$min );
      }
   }   
   elsif($which eq 'justmin') {
      $min                = $mnref->{-whenlinear};
      $max                = $aref->{-max}; # max has been hard wired
      $range              = $max - $min;
      $min               -= ( $range * MAGICRATIO);
      ($step, $numminor)  =
               &_determine_step_and_numminor($min, $max, $wh2compare);
      $min                = int($min/$step - ONE)*$step;
   }
   elsif($which eq 'justmax') {
      $min                = $aref->{-min}; # min has been hard wired
      $max                = $mxref->{-whenlinear};
      $range              = $max - $min;
      $max               += ( $range * MAGICRATIO);
      ($step, $numminor)  =
               &_determine_step_and_numminor($min, $max, $wh2compare);
      $max                = int($max/$step + ONE)*$step;
   }
   else { # CONFIGURE BOTH
      $min                = $mnref->{-whenlinear};
      $max                = $mxref->{-whenlinear};
      $range              = $max - $min;
      $min               -= ( $range * MAGICRATIO );
      $max               += ( $range * MAGICRATIO );
      ($step, $numminor)  =
               &_determine_step_and_numminor($min, $max, $wh2compare);
      $min                = int($min/$step - ONE)*$step;
      $max                = int($max/$step + ONE)*$step;
   }
   
   $aref->{-majorstep} = $step;
   $aref->{-numminor}  = ($numminor) ? $numminor : 1; # set to one unless set
   $aref->{-min}       = $min;
   $aref->{-max}       = $max;  
   
   # recode the linear limits to time to force consistency
   $aref->{-time}->{-min} = &RecodeTkg2DateandTime($min);
   $aref->{-time}->{-max} = &RecodeTkg2DateandTime($max);
}




## TIME
## _autoConfigTime
## Private subroutine for autoconfiguration of the limits for
## a TimeSeries axis, very similar to a Linear
sub _autoConfigTime {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
      
   my ($plot, $xoy) = ( shift, shift); # do not remove the shifting
   my $which   = (@_) ? shift() : 1;
   
   my $aref    = $plot->{$xoy};   
   my $mnref   = $aref->{-datamin};
   my $mxref   = $aref->{-datamax};
   my $timeref = $aref->{-time};

   if(not defined $mnref->{-whenlinear} or
      not defined $mxref->{-whenlinear} ) {
      #my $mess = "Warning: Either the minimum or maximum limit ".
      #           "of the data is undefined for a time (linear) axis. ".
      #           "Tkg2 is using default limits.";
      # &Message($::MW,'-generic',$mess);  # DOUBLE Y:
      # setting here is just a rough patch, these values
      # are best left undef until data is actually read-in
      #$timeref->{-min}      = '1/1/1900';
      #$timeref->{-max}      = '1/1/2000';
      #my $daysmin           = &DecodeTkg2DateandTime('1/1/1900');
      #my $daysmax           = &DecodeTkg2DateandTime('1/1/2000');
      #$mnref->{-whenlinear} = $daysmin;
      #$mxref->{-whenlinear} = $daysmax;
      return;
   } 
    
   # The timeseries is easy to auto configure, because it has been
   # decided that the limits of a time series axis should be the
   # actual limits of the data. 
   my ($min, $max);
   if($which eq 'justmin') { # configure just the minimum limit
      $min = $mnref->{-whenlinear};
      $max = $aref->{-max};
   }
   elsif($which eq 'justmax') {  # configure just the maximum limit
      $min = $aref->{-min};
      $max = $mxref->{-whenlinear};
   }
   else { # configure both limits
      $min = $mnref->{-whenlinear};
      $max = $mxref->{-whenlinear};
   }
   $aref->{-min}    = $min;
   $aref->{-max}    = $max;
   
   #print $::BUG "Auto time in days: $min and $max\n";
   $min = &RecodeTkg2DateandTime($min);
   $max = &RecodeTkg2DateandTime($max);
   #print $::BUG "Auto time recoded: $min and $max\n";
   $timeref->{-min} = $min;
   $timeref->{-max} = $max;
}



sub _autoConfigLog {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
  
   my ($plot, $xoy) = ( shift, shift); # do not remove the shifting
   my $which = (@_) ? shift() : 1;

   my $aref  = $plot->{$xoy};
   my $mnref = $aref->{-datamin};
   my $mxref = $aref->{-datamax};
   if(not defined $mnref->{-whenlog} or
      not defined $mxref->{-whenlog} ) {
      #my $mess = "Warning: Either the minimum or maximum limit ".
      #           "of the data is undefined for a logarithmic axis. ".
      #           "Tkg2 is using default limits.";
      # &Message($::MW,'-generic',$mess);  # DOUBLE Y:
      # setting here is just a rough patch, these values
      # are best left undef until data is actually read-in                     
      #$mnref->{-whenlog} = 10;
      #$mxref->{-whenlog} = 100;
      return;
   }

   map { abs($_) } @PRETTY_LOG_MIN;
   my $_intfrac = sub { split(/\./o, shift(), -1); };
   
   my $_round = sub { my $passedarg = shift;
                      my ($int, $frac) = &$_intfrac($passedarg);
                      #print $::BUG "_round $int and $frac\n";
                      $int  = (defined($int) ) ? $int  : 0;
                      my $intsign = ($passedarg < 0) ? -1 : 1;
                      #print $::BUG "\$intsign $intsign\n";
                      $int =~ s/\-//o;
                      $frac = (defined $frac) ? $frac : 0;
                      $frac = ".".$frac;
                      return (wantarray) ? ( $int, $intsign, $frac ) : $int;
                    };
   
   my $_domin = sub { my $datamin = shift;
                      my $newmin  = log10($datamin) - TENTH;
                         $newmin  = $newmin; # PERL5.8 CORRECTION
                      # The quotations around newmin are used to force into
                      # a string context to keep .99999998 etc from growing
                      # A hack to keep rounding issues away.
                  
                      #print $::BUG "\$newmin $newmin\n";
                      my ($int, $intsign, $frac) = &$_round($newmin);
                      #print $::BUG "$int, $intsign, $frac\n";
                      foreach (reverse @PRETTY_LOG_MIN) {
                         next if($_ < $frac);
                         $frac = $_;
                         last;
                      }
                      #print $::BUG "computing min $intsign, $int, $frac\n";
                      # sometimes the auto configure does not work, thus try to fix
                      # by dividing $justmin by 10 until is does
                      $newmin  = TEN**($intsign*($int+$frac));
                      $newmin  = $newmin; # PERL5.8 CORRECTION
                      $newmin /= TEN, $newmin = $newmin
                           until($newmin < $datamin);  # PERL5.8 CORRECTION
                      return $newmin;
                    };
   my $_domax = sub { my $datamax = shift;
                      my $newmax  = log10($datamax) + TENTH;
                         $newmax  = $newmax; # PERL5.8 CORRECTION
                      # The quotations around newmax are used to force into
                      # a string context to keep .99999998 etc from growing
                      # A hack to keep rounding issues away.
               
                      
                      #print $::BUG "\$newmax $newmax\n";
                      my ($int, $intsign, $frac) = &$_round($newmax);
                      #print $::BUG "$int, $intsign, $frac\n";
                      foreach (@PRETTY_LOG_MAX) {
                         #print $::BUG "prettymax is $_ and fraction is $frac\n";
                         next if($_ < $frac);
                         $frac = $_; 
                         last;
                      }
                      #print $::BUG "computing max $intsign, $int, $frac\n";
                      
                      # sometimes the auto configure does not work, thus temp fix
                      # by multiplying by $newmax by 10 until it does
                      $newmax  = TEN**($intsign*($int+$frac));
                      $newmax  = $newmax; # PERL5.8 CORRECTION
                      $newmax *= TEN, $newmax = $newmax
                           until($newmax > $datamax); # PERL5.8 CORRECTION
                      return $newmax;
                    };               
                                        
   my $datamin = $mnref->{-whenlog};
   my $datamax = $mxref->{-whenlog};
   
   if($which eq 'justmin') {
      $aref->{-min} = &$_domin($datamin);
   }
   elsif($which eq 'justmax') {          
      $aref->{-max} = &$_domax($datamax);
   }
   else {
      $aref->{-min} = &$_domin($datamin);
      $aref->{-max} = &$_domax($datamax);
   }
   
   &_makeNice_LogTicks_and_Labels($plot,$xoy,$aref);
}


# This subroutine is supposed to trim back or actually reset the
# log cycles that receive major ticks, major labels, and minor ticks
# Because of the nonlinearity of a log scale, it is necessary to tweak
# the settings so the user/reader of a plot can adequately establish
# the values of ticking along an axis
sub _makeNice_LogTicks_and_Labels {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
      
   my ($plot, $xoy, $aref) = @_;
   # notice that aref argument is an axis reference -x or -y of plot


   # find out how wide and how high the plot is so that 
   # we can make slight alteration to the step and range
   # tables for better looking plots
   my ($width, $height) = $plot->getPlotWidthandHeight;
   map { s/i$//o } ($width, $height);
   my $wh2compare = ($xoy =~ m/x/io) ? $width : $height;
   # width and height now are numbers so we can <=> using
   # the wh2compare variable because of axis dependency of
   # this subroutine

   
   my $logmin = log10($aref->{-min}); # log10 from Base
   my $logmax = log10($aref->{-max});
   my $range = $logmax - $logmin;  # bascially number of log cycles between limits
   
   # these are the keys under the axis hash that need to be edited
   # -basemajor    -basemajortolabel     -baseminor
   my $basemajor        = [ @{$::TKG2_CONFIG{-LOG_BASE_MAJOR_TICKS}} ];
   my $basemajortolabel = [ @{$::TKG2_CONFIG{-LOG_BASE_MAJOR_LABEL}} ];
   my $baseminor        = [ @{$::TKG2_CONFIG{-LOG_BASE_MINOR_TICKS}} ];
   
   if($aref->{-usesimplelog}) {
      if($range >= 7) {
         $basemajor        = [ qw(1 5) ];
         $basemajortolabel = [ qw(1) ]; 
         $baseminor        = [ ]; 
      }
      elsif($range >= 5) {
         $basemajor        = [ qw(1 2 4 6 8) ];
         $basemajortolabel = [ qw(1) ]; 
         $baseminor        = [ ];
      }
      else {
         $basemajor        = [ qw(1 2 3 4 5 6 7 8 9) ];
         $basemajortolabel = [ qw(1) ]; 
         $baseminor        = [ ];   
      }
   }
   elsif($wh2compare < 2) {
      $basemajor        = [ qw(1 2 4 6 8) ];
      $basemajortolabel = [ qw(1) ]; 
      $baseminor        = [ ];
   }
   else {  
      if($range  <  1) { # mainly remove the 1.5 as a major tick
         $basemajor        = [ qw(1 2 3 4 5 6 7 8 9) ];
         $basemajortolabel = [ qw(1 2 3 4 5 6 7 8 9) ];
         push(@$baseminor, 1.5); # make 1.5 a minor tick
      }
      elsif($range >= 2 and $range < 5) {
         $basemajor        = [ qw(1 2 3 4 5 6 7 8 9) ];
         $basemajortolabel = [ qw(1 2 5) ];
         $baseminor        = [ ];   
      }
      elsif($range >= 5 and $range < 7) {
         $basemajor        = [ qw(1 2 4 6 8) ];
         $basemajortolabel = [ qw(1 4) ]; 
         $baseminor        = [ ];
      }
      elsif($range >= 7) {
        $basemajor        = [ qw(1 2 4 6 8) ];
        $basemajortolabel = [ qw(1) ]; 
        $baseminor        = [ ];
      }
   }
   # BACKWARDS COMPATABILITY
   $aref->{-usesimplelog} = 0 if(not defined $aref->{-usesimplelog});
   
   $aref->{-basemajor}        = $basemajor;  
   $aref->{-basemajortolabel} = $basemajortolabel;
   $aref->{-baseminor}        = $baseminor;
}


sub _autoConfigProb {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($plot, $xoy) = (shift, shift); # do not remove the shifting
   my $which = (@_) ? shift() : 1;
   
   my $aref  = $plot->{$xoy};
   my $mnref = $aref->{-datamin};
   my $mxref = $aref->{-datamax};
   
   my ($min, $max); 
   if(not defined $mnref->{-whenprob} or
      not defined $mxref->{-whenprob} ) {
      #my $mess = "Warning: Either the minimum or maximum limit ".
      #           "of the data is undefined for a probability axis. ".
      #           "Tkg2 is using default limits.";
      # &Message($::MW,'-generic', $mess);  # DOUBLE Y:
      # setting here is just a rough patch, these values
      # are best left undef until data is actually read-in
      #$mnref->{-whenprob} = 0.01;
      #$mxref->{-whenprob} = 0.999;
      return;
   }

   if($which eq 'justmin') {
      $min = $mnref->{-whenprob};
      my $newmin    =  $min*TENTH;
      $aref->{-min} = $newmin;  # PERL5.8 CORRECTION
   }
   elsif($which eq 'justmax') {
      $max = $mxref->{-whenprob};
      my $newmax    = ($max*ONEANDTENTH > ONE) ? $max : $max*ONEANDTENTH;   
      $aref->{-max} = $newmax;  # PERL5.8 CORRECTION     
   }
   else { # CONFIGURE BOTH
     $min = $mnref->{-whenprob};
     $max = $mxref->{-whenprob}; 
     my $newmin = $min*TENTH;
     my $newmax = ($max*ONEANDTENTH > ONE) ? $max : $max*ONEANDTENTH;
     $aref->{-min} = $newmin;  # PERL5.8 CORRECTION
     $aref->{-max} = $newmax;  # PERL5.8 CORRECTION
   }
   # would double quotes be just as good as repacking--hummmmmmm
   $aref->{-min} = &repackit($aref->{-min});  # PERL5.8 CORRECTION
   $aref->{-max} = &repackit($aref->{-max});  # PERL5.8 CORRECTION
}


# returns scientific notation for the argument
# $val = &_e(2,'100.42');  yields 1.0e+2
sub _e { sprintf("%0.".shift()."e", shift() ) };

# split an exponential number on the lowercase e
sub _split { split(/e/o, $_[0] ) };


sub _determine_step_and_numminor {
   my ($min, $max, $wh2compare) = @_;
   my ($step, $numminor);
   my $rng = $max - $min;
   return TENTH if($rng == 0 or $min eq $max);
            
   # Step table holds pretty combinations of minor step numbers
   # depending upon how big the step was
   #                    STEP     NUM-SUBINTERVALS
   my %step_table = ($wh2compare < 2 ) ?
                            %{$STEP_TABLE{-lessthan2inch}} :
                    ($wh2compare < 3 ) ?
                            %{$STEP_TABLE{-lessthan3inch}} :
                            %{$STEP_TABLE{-default}}       ;
                              
   # range table holds pretty combinations of linear steps
   #                   RANGE      STEP
   my @range_table = ($wh2compare < 2) ?
                            @{$RANGE_TABLE{-lessthan2inch}} :
                            @{$RANGE_TABLE{-default}}       ;

   print STDERR "_determine_step_and_numminor max < man" if($max < $min);
                  
   # Convert range to scientific notation
   $rng = &_e(2,$rng);
   my ($mant, $expon) = &_split( $rng );
   foreach my $i (0..($#range_table - ONE)) {
      if($mant > $range_table[$i] and
         $mant <= $range_table[$i+TWO] ) { # found it!
         $step     = $range_table[$i+ONE]*TEN**$expon;
         $numminor = $step_table{$range_table[$i+ONE]};
         print $::BUG "%%  Linear Axis step=$step, minor=$numminor\n";
         return ( $step, $numminor ); 
         # return a scaled step and the number of pretty minors  
      }
    }
    print STDERR "Could not find an appropriate step length ".
                 "in _determine_step_and_numminor";
    print STDERR "Mantissa = $mant; Expon = $expon\n";
    return (1,1);
}

1;
