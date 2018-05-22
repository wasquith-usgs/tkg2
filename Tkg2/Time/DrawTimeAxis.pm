package Tkg2::Time::DrawTimeAxis;

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
# $Date: 2007/09/07 18:29:13 $
# $Revision: 1.42 $

use strict;

use Tkg2::Draw::DrawMethods qw( _xaxisLabel _yaxisLabel);

use Tkg2::Time::DrawTimeUtilities qw( _Years
                                      _Months
                                      _Hours
                                      _Minutes
                                      _Seconds
                                      _LabelYears
                                      _LabelMonths
                                      _LabelHours
                                      _LabelMinutes
                                      _LabelSeconds
                                      _dateLTGT
                                      _workupDayArray
                                      _LabelworkupDayArray
                                      _checkDoIts
                                      _get_beg_and_end_days
                                      _draw_ticks
                                      _draw_grid
                                      _draw_label_days
                                      _draw_label
                                      _get_the_label_format
                                      _MonthsToUse
                                      _DaysToUse
                                      _2DOW
                                      _get_midpoint_of_min_and_max
                                    );
                               
use Tkg2::Base qw(Show_Me_Internals @BaseDate deleteFontCache);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createLineMetaPost);

use Date::Calc qw(Day_of_Year);

use vars qw(@ISA @EXPORT_OK @ONE2TWELVE @ZERO2TWOTHREE @ZERO2FIVENINE);
@ONE2TWELVE    = (1..12);
@ZERO2TWOTHREE = (0..23);
@ZERO2FIVENINE = (0..59);

use Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(drawTimeAxis);

print $::SPLASH "=";

sub drawTimeAxis {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($plot, $canv, $xoy) = ( shift, shift, shift);  
   $xoy = ($xoy =~ /x/io) ? '-x'  :
          ($xoy =~ /2/io) ? '-y2' : '-y';      # DOUBLE Y
   my $double_y = $plot->{-y2}->{-turned_on};  # DOUBLE Y, is it turned on
   return if($xoy eq '-y2' and not $double_y); # DOUBLE Y

   my $aref = $plot->{$xoy}; # axis reference
   my $mindays = $aref->{-min};
   my $maxdays = $aref->{-max};
   return unless(defined $mindays and defined $maxdays);
   
   if($maxdays < $mindays) {
      print STDERR "Tkg2-Error, drawTimeAxis: axis maximum is less than ",
            "minimum.  Minimum = $mindays and Maximum = $maxdays.\n",
            "Tkg2 is going to reverse the sense on min and max for now as ",
            "this is logical action.  For assistance, please contact ",
            "wasquith\@usgs.gov with this error as it likely indicates either ",
            "a bug in the AxisConfiguration.pm or bad application of the ",
            "Instructions by the user.  The axis editors should show the ",
            "minimum and maximum time axis reversed.  Further correction ",
            "to this problem need to be done so wasquith has decided not ",
            "to patch this further in this code location.\n";
      ($mindays, $maxdays) = reverse($mindays, $maxdays);
      $aref->{-min} = $mindays;
      $aref->{-max} = $maxdays;
   }
   
   # It is important to store the basedate in each axis hash
   # because the tkg2 file, if data is imported, stores time
   # in integer days.  It is imported to know what the time
   # origin is.
   my $timeref = $aref->{-time}; # convenient reference to the doits
   $timeref->{-basedate} = [ @BaseDate ];

   # backwards compatability for version < 0.40
   $timeref->{-show_day_as_additional_string} =
      (exists $timeref->{-show_day_as_additional_string}) ?
              $timeref->{-show_day_as_additional_string} : 0;
   $timeref->{-show_day_of_year_instead} =
      (exists $timeref->{-show_day_of_year_instead}) ?
              $timeref->{-show_day_of_year_instead} : 0;
   
   # for <0.52
   $timeref->{-labeldensity} ||= 1;
   $timeref->{-labeldepth}   ||= 1;
   $timeref->{-labellevel1}    = 1 if(not defined $timeref->{-labellevel1});
   # end of backwards compatability

   my $location       = $aref->{-location};
   my $dblabel        = $aref->{-doublelabel};
   my $hidden         = $aref->{-hideit};
   my $blankit        = $aref->{-blankit};
   my $blankcolor     = $aref->{-blankcolor};
   my $showyr         = (defined $timeref->{-showyear} ) ?
                                 $timeref->{-showyear} : 1 ;
   my $basetextoffset = $aref->{-numoffset};
   my $baseticklength = $aref->{-ticklength};
   my $tickwidth      = $aref->{-tickwidth};
   my $tickratio      = $aref->{-tickratio};
   
   my $labeldensity   = $timeref->{-labeldensity};
   my $labeldepth     = $timeref->{-labeldepth};
   my $labellevel1    = (defined $timeref->{-labellevel1}) ?
                                 $timeref->{-labellevel1} : 1;
   
   
   my $ftref   = $aref->{-numfont};
   &deleteFontCache(); # Perl 5.8.3 and Tk 804.027 error trapping                 
   my $numfont = $canv->fontCreate($plot."$xoy"."numfont", 
                                   -family => $ftref->{-family},
                                   -size   => ($ftref->{-size}*
                                               $::TKG2_ENV{-SCALING}*
                                               $::TKG2_CONFIG{-ZOOM}),
                                   -weight => $ftref->{-weight},
                                   -slant  => $ftref->{-slant});
   my $numcolor  = $ftref->{-color};   
   my $linecolor = $plot->{-bordercolor};

   # Set the tick lengths for each of the labeling or ticking levels
   my $ticklength  = $baseticklength/$tickratio;
   my %ticklen = ( 1 => $ticklength*$tickratio,
                   2 => $ticklength,
                   3 => $ticklength/$tickratio,
                   4 => $ticklength/$tickratio,
                   5 => $ticklength/$tickratio,
                   6 => $ticklength/$tickratio );
   
 
   # Set the offsets for each of the labeling levels
   my $fontsize_in_inches = ($ftref->{-size}*
                             $::TKG2_ENV{-SCALING}*
                             $::TKG2_CONFIG{-ZOOM})/72;
   my $fontsize_in_pixels = $canv->fpixels($fontsize_in_inches."i");
   my %offsets = ( 1 => $basetextoffset,
                   2 => $basetextoffset+$fontsize_in_pixels*1.5,
                   3 => $basetextoffset+$fontsize_in_pixels*2.5,
                   4 => $basetextoffset+$fontsize_in_pixels*2.5,
                   5 => $basetextoffset+$fontsize_in_pixels*2.5,
                   6 => $basetextoffset+$fontsize_in_pixels*2.5 );
   if(not $labellevel1) {
      map { $offsets{$_} -= $basetextoffset+$fontsize_in_pixels }
                                                   keys %offsets;
   }
 
   my $mjref = $aref->{-gridmajor};  # grid major reference
   my $majorgridlinedoit  = $mjref->{-doit};
   my $majorgridlinewidth = $mjref->{-linewidth};
   my $majorgridlinecolor = $mjref->{-linecolor};
   my $majorgriddashstyle = $mjref->{-dashstyle};
   my @majordash = (-dash => $majorgriddashstyle)
                  if($majorgriddashstyle and
                     $majorgriddashstyle !~ /Solid/io);
                        
   # MINOR GRID CURRENTLY NOT RUNNING
   my $mnref = $aref->{-gridminor};
   my $minorgridlinedoit  = $mnref->{-doit};
   my $minorgridlinewidth = $mnref->{-linewidth};
   my $minorgridlinecolor = $mnref->{-linecolor};   
   my $minorgriddashstyle = $mnref->{-dashstyle};
   my @minordash = (-dash => $minorgriddashstyle)
                  if($minorgriddashstyle and
                     $minorgriddashstyle !~ /Solid/io);
   
   # Grab the usual things needed about the plot
   my ($xmin, $ymin, $xmax, $ymax) = $plot->getPlotLimits;
   $plot->setGLOBALS($xoy);

   
   my $lineattr    = [ -width => $tickwidth,
                       -fill  => $linecolor
                     ];

   my $majgridattr = [ -width => $majorgridlinewidth,
                       -fill  => $majorgridlinecolor,
                       @majordash,
                       -tags  => [ $plot.'majorgrid' ]
                     ];
   my $mingridattr = [ -width => $minorgridlinewidth,
                       -fill  => $minorgridlinecolor,
                       @minordash,
                       -tags  => [ $plot.'minorgrid' ]
                     ];

   my @_draw_ticks_args = ( $plot, $canv, $aref, $xoy, $location,
                            $xmin, $ymin, $xmax, $ymax,
                            $dblabel, $double_y,  $lineattr );

   my @_draw_grid_args  = ( $plot, $canv, $aref, $xoy,
                            $xmin, $ymin, $xmax, $ymax,
                            $majorgridlinedoit, $minorgridlinedoit,
                            $mingridattr, $majgridattr );        

   my $textattr = [ "$plot"."$xoy", $numfont,
                     $numcolor, $blankit, $blankcolor
                  ];

   my @_draw_label_days_args = ($plot, $canv, $xoy, $aref, $location,
                                $xmin, $ymin, $xmax, $ymax,
                                $dblabel, $double_y, $textattr);
   

   # Compute the time range between the min and maximum and 
   # then route the time hash into _checkDoIts as a means to
   # turn off requested doits if the range simply does not
   # permit it.  This provides for tremendous acceleration as
   # many deeply nest loops are avoid later on in the drawing
   # of the time axis.
   my $range = $maxdays - $mindays;
   &_checkDoIts($timeref, $range, $labeldepth);
   
   # do not permit showing the days with a string is the range is too big
   $timeref->{-show_day_as_additional_string} = 0 if($range > 15);
   
   
   # fill an array with the month style, January, Jan, or J that will
   # be shown on the axis.  The subroutine bases the months to use on the
   # range between the begining and ending day
   # There has been a conscious decision not to consider the labeldensity
   # for the strings
   my @months_touse = &_MonthsToUse($timeref,$range);
                      &_DaysToUse(  $timeref,$range);
   # Grab the edge of the time axis and store them in the begday and endday
   # hashes
   my ( $y1, $m1, $d1, $hr1, $min1, $sec1,
        $y2, $m2, $d2, $hr2, $min2, $sec2 ) =
                &_get_beg_and_end_days($mindays,$maxdays); 
   
   my %begday = ( -year   => $y1,
                  -month  => $m1,
                  -day    => $d1,
                  -hour   => $hr1,
                  -minute => $min1,
                  -second => $sec1 );
  
   my %endday = ( -year   => $y2,
                  -month  => $m2,
                  -day    => $d2,
                  -hour   => $hr2,
                  -minute => $min2,
                  -second => $sec2 );
   
   # Grab the middle of the time axis, in case it becomes necessary to 
   # place a 2nd or 3rd level label there                                 
   my ( $midyr, $midmon, $middy, $midhr, $midmin, $midsec ) =
                              &_get_midpoint_of_min_and_max($mindays,$maxdays);
  
   my %midday = ( -year   => $midyr,
                  -month  => $midmon,
                  -day    => $middy,
                  -hour   => $midhr,
                  -minute => $midmin,
                  -second => $midsec );
   # fritter the mid point away for later use
   
   # Commented area to check on the edges and the middle
   #print "Beginning Day\n";
   #map { print "$_ => $begday{$_}\n" } sort keys %begday;                    
   #print "\n";
   #print "Middle Day\n"; 
   #map { print "$_ => $midday{$_}\n" } sort keys %midday;                    
   #print "\n";
   #print "Ending Day\n";
   #map { print "$_ => $endday{$_}\n" } sort keys %endday;                    
   #print "\n";   
   # End of area to check on the edge and the middle    
   
   # DETERMINE PRETTY LOOKING INTERVALS OF THE VARIOUS TIME UNITS
   my @years   = &_Years(  $timeref, $y1, $y2, $labeldensity );
   my @months  = &_Months( $timeref, $range, $labeldensity   );
   # @days
   # there is nothing to do with days as the number of days changes from
   # month to month.  Thus the @days array to plot is built up again and again
   # in the logic inside the _workupDayArray subroutine
   my @hours   = &_Hours(   $timeref, $range, $labeldensity );
   my @minutes = &_Minutes( $timeref, $range, $labeldensity );
   my @seconds = &_Seconds( $timeref, $range, $labeldensity );
   # END DETERMINE PRETTY LOOKING INTERVALS OF THE VARIOUS TIME UNITS
   
   #print "BUG: @years\n@months\n@hours\n@minutes\n@seconds\n";
      
   # DETERMINE PRETTY LOOKING LABELING INTERVALS OF THE VARIOUS TIME UNITS
   my @labyears   = &_LabelYears(  $timeref, $y1, $y2, $labeldensity );
   my @labmonths  = &_LabelMonths( $timeref, $range, $labeldensity   );
   # @days
   # there is nothing to do with days as the number of days changes from
   # month to month.  Thus the @days array to plot is built up again and again
   # in the logic inside the _workupDayArray subroutine
   my @labhours   = &_LabelHours(   $timeref, $range, $labeldensity );
   my @labminutes = &_LabelMinutes( $timeref, $range, $labeldensity );
   my @labseconds = &_LabelSeconds( $timeref, $range, $labeldensity );
   
   # END DETERMINE PRETTY LOOKING LABELING INTERVALS OF THE VARIOUS TIME UNITS
   
   my $_axisLabels =
   sub {
      my ($years,$months,$hours,$minutes,$seconds,$range,$offsets,
          $begday, $midday, $endday) = @_;
      my %time     = %$timeref;
      my %begday   = %$begday;
      my %midday   = %$midday;
      my %endday   = %$endday;
      my %offsets  = %$offsets;
      my $labeldone;
      
      my %lev3labels;
      my %lev2labels;
      
      my @years   = @$years;
      my @months  = @$months;
      my @hours   = @$hours;
      my @minutes = @$minutes;
      my @seconds = @$seconds;
      
      # Given that the doits are now set, we derive a closure
      # that will provide an appropriate date/time string for
      # display when given a sequence of y,m,d,hr,min,sec,months_touse
      # The anonymous subroutine construction of Perl is extremely useful
      # for this situtation
      my $label3sub = &_get_the_label_format($timeref,$showyr,3);
      my $lev2done = 0;
      my $lev3done = 0;
      
      my $showDOW = $timeref->{-show_day_as_additional_string};
      my $showDOY = $timeref->{-show_day_of_year_instead};
      # YEARS
      if($time{-yeardoit}) { 
        foreach my $year ( @years ) {
          # if the other ticks and labels are not to be shown, then no
          # need to show the yearly tick on each side of the graph.  This is
          # visually more consistent with traditional 2-D charts.  Only need
          # to test whether months are going to be plotted if they are not
          # then no need to check other time periods
          my $side = ($time{-monthdoit} ) ? 'bothsides' : 'oneside';
          my @attime = ( [ $year, 6, 15 ], [ 0, 0,  0 ] );
          my $label  = ($time{-yeardoit} == 3) ?
                         &$label3sub(@{$attime[0]}, @{$attime[1]},
                                    @months_touse) : $year;
          $labeldone = &_draw_label( @attime, $label,
                        $offsets{$time{-yeardoit}},
                        @_draw_label_days_args )
                        if( $showyr and
                            ( ( $time{-yeardoit} == 1
                                         and
                                     $labellevel1 )   or
                                $time{-yeardoit} == 2 or
                                $time{-yeardoit} == 3 ) );
          $lev2done++, $lev2labels{$label}++
                       if($time{-yeardoit} == 2 and $labeldone);
          $lev3done++, $lev3labels{$label}++
                       if($time{-yeardoit} == 3 and $labeldone);  
      # MONTHS       
        if($time{-monthdoit}) {
          foreach my $month ( @months ) {
            next if( &_dateLTGT( $mindays, $maxdays, 'month',
                                 $year, $month ) );
            my @attime = ([ $year, $month, 15 ],
                          [     0,      0,  0 ]);
            my $label  = ($time{-monthdoit} == 3) ?
                         &$label3sub(@{$attime[0]}, @{$attime[1]},
                                    @months_touse) : $months_touse[$month];
            $labeldone = &_draw_label( @attime, $label,
                          $offsets{$time{-monthdoit}},
                          @_draw_label_days_args )
                          if( ( $time{-monthdoit} == 1
                                          and
                                      $labellevel1 )   or
                                $time{-monthdoit} == 2 or
                                $time{-monthdoit} == 3 );
            $lev2done++, $lev2labels{$label}++
                         if($time{-monthdoit} == 2 and $labeldone );
            $lev3done++, $lev3labels{$label}++
                         if($time{-monthdoit} == 3 and $labeldone );
      # DAYS
            if($time{-daydoit}) {
              my (undef, @days) = &_LabelworkupDayArray($year, $month,
                                                   $time{-daytickevery},
                                                   $range, $labeldensity);             
              foreach my $day ( @days ) {
                next if(&_dateLTGT( $mindays, $maxdays, 'day',
                                    $year, $month, $day) );
                my @attime = ([ $year, $month, $day ],
                              [    12,      0,    0 ]);
                              
                my $myday =  ($showDOY) ?
                             &Day_of_Year($year,$month,$day) : $day;
                
                my $label  = ($time{-daydoit} == 3) ?
                             &$label3sub(@{$attime[0]}, @{$attime[1]},
                                        @months_touse) :
                             ($showDOW) ?
                             "$myday-".&_2DOW($year,$month,$day) : $myday;
                $labeldone = &_draw_label( @attime, $label, 
                              $offsets{$time{-daydoit}},
                              @_draw_label_days_args )
                              if( ($time{-daydoit} == 1
                                            and
                                        $labellevel1 )  or
                                   $time{-daydoit} == 2 or
                                   $time{-daydoit} == 3 );
                $lev2done++, $lev2labels{$label}++
                             if($time{-daydoit} == 2 and $labeldone );
                $lev3done++, $lev3labels{$label}++
                             if($time{-daydoit} == 3 and $labeldone );
      # HOURS           
                if($time{-hourdoit}) {
                  foreach my $hour ( @hours ) {
                    next if( &_dateLTGT( $mindays, $maxdays, 'hour',
                                         $year, $month, $day,
                                         $hour ) );
                    my @attime = ([ $year,  $month, $day ],
                                  [ $hour,      29,   0  ]);                   
                    my $label  = ($time{-hourdoit} == 3) ?
                                  &$label3sub(@{$attime[0]}, @{$attime[1]},
                                             @months_touse) : $hour."H";
      
                    $labeldone = &_draw_label( @attime, $label,
                                  $offsets{$time{-hourdoit}},
                                  @_draw_label_days_args)
                                  if( ( $time{-hourdoit} == 1
                                                  and
                                              $labellevel1 )  or
                                        $time{-hourdoit} == 2 or
                                        $time{-hourdoit} == 3 );
                    $lev2done++, $lev2labels{$label}++
                                 if($time{-hourdoit} == 2 and $labeldone );
                    $lev3done++, $lev3labels{$label}++
                                 if($time{-hourdoit} == 3 and $labeldone );
      # MINUTES              
                    if($time{-minutedoit}) {
                      foreach my $minute ( @minutes ) { 
                        next if( &_dateLTGT( $mindays, $maxdays, 'min',
                                             $year, $month, $day,
                                             $hour, $minute ) );
                        my @attime = ([ $year,  $month, $day ],
                                      [ $hour, $minute,  29  ]);
                        $labeldone = &_draw_label( @attime, $minute."M",
                                      $offsets{$time{-minutedoit}},
                                      @_draw_label_days_args )
                                      if( ( $time{-minutedoit} == 1
                                                      and
                                                  $labellevel1 ) or
                                            $time{-minutedoit} == 2 );
                        $lev2done++, $lev2labels{$label}++
                                     if($time{-minutedoit} == 2 and $labeldone );
      # SECONDS                    
                        if($time{-seconddoit}) {
                          foreach my $second ( @seconds ) {
                            next if( &_dateLTGT( $mindays, $maxdays, 'sec',
                                                 $year, $month, $day, 
                                                 $hour, $minute, $second ) );
                            my @attime = ([ $year,  $month, $day ],
                                          [ $hour, $minute, $second ]);
                            $labeldone = &_draw_label( @attime, $second."S",
                                          $offsets{$time{-seconddoit}},
                                          @_draw_label_days_args )
                                          if( $time{-seconddoit} == 1
                                              and $labellevel1 );
                          } # End foreach second
                        } # End if second doit
                      
                      } # End foreach minute
                    } # End if minute doit
                   
                  } # End foreach hour
                } # End if hour doit
              
              } # End foreach day  
            } # End if day doit
          
          } # End foreach month
        } # End if month doit
        
        } # End foreach year
      } # End if year doit

      # print "_axisLabels: Foreach loops done\n";
      
      # Make sure that the level 3 type label is placed one or more
      # times along the axis.    
      my $whichdoit_is_level_2 = 0;
      my $whichdoit_is_level_3 = 0;
      foreach my $key ( qw(-yeardoit -monthdoit  -daydoit
                           -hourdoit -minutedoit -seconddoit) ) {
         $whichdoit_is_level_2 = $key if($time{$key} == 2);
         $whichdoit_is_level_3 = $key if($time{$key} == 3);
      }
      
      my @minattime = ( [ $begday{-year},
                          $begday{-month},
                          $begday{-day}    ],
                        [ $begday{-hour},
                          $begday{-minute},
                          $begday{-second} ] );
      
      my @midattime = ( [ $midday{-year},
                          $midday{-month},
                          $midday{-day}    ],
                        [ $midday{-hour},
                          $midday{-minute},
                          $midday{-second} ] );
      
      my @maxattime = ( [ $endday{-year},
                          $endday{-month},
                          $endday{-day}    ],
                        [ $endday{-hour},
                          $endday{-minute},
                          $endday{-second} ] );
     
      # Finally, make sure that the level 2 label drawn
      if(not $lev2done and $time{-yeardoit} > 1) {
         #print "_axisLabels: working on extra level 2 label\n";
         my $day = ($showDOY) ? &Day_of_Year($midday{-year}, 
                                             $midday{-month},
                                             $midday{-day}) : $midday{-day};
         my $label = ( $time{-minutedoit} == 2 ) ? $midday{-minute}."M" :
                     ( $time{-hourdoit}   == 2 ) ? $midday{-hour}."H"   :
                     ( $time{-daydoit}    == 2 and $showDOW) ? 
                     "$day-".&_2DOW($midday{-year},
                                    $midday{-month},
                                    $midday{-day})             :
                     ( $time{-daydoit}    == 2)  ? $day        :
                     ( $time{-monthdoit}  == 2 ) ? $midday{-month}      :
                     ( $time{-yeardoit}   == 2 and $showyr) ? $midday{-year} :
                     ( not $showyr ) ? "" : "LEVEL 2 is NOT done\n";
         
         $label = $months_touse[$label] if($time{-monthdoit} == 2);
         
         &_draw_label( @midattime, $label,
                       $offsets{$time{$whichdoit_is_level_2}},
                       @_draw_label_days_args ) unless($lev2labels{$label});
      }
      
      
      # Work on the final level three labeling  
      # simple return if further work is not needed because none of the
      # doits are at level 3 or greater
      return if(not $whichdoit_is_level_3);
      
      my $minlabel  = &$label3sub( @{$minattime[0]},
                                   @{$minattime[1]},
                                   @months_touse );
                                   
      my $midlabel  = &$label3sub( @{$midattime[0]},
                                   @{$midattime[1]},
                                   @months_touse );
                                   
      my $maxlabel  = &$label3sub( @{$maxattime[0]},
                                   @{$maxattime[1]},
                                   @months_touse );
      
      # a level three is possible by the doits, but a level 3 has not
      # been done
      if(not $lev3done) {
         if($minlabel eq $maxlabel) {
            &_draw_label( @midattime, $midlabel,
                          $offsets{$time{$whichdoit_is_level_3}},
                          @_draw_label_days_args );
         }
         else {
            my @args = @_draw_label_days_args;
            $args[$#args]->[5] = 'minedge';
            &_draw_label_days( $mindays, $minlabel,
                               $offsets{$time{$whichdoit_is_level_3}},
                               @_draw_label_days_args );
               
            $args[$#args]->[5] = 'maxedge';
            &_draw_label_days( $maxdays, $maxlabel,
                               $offsets{$time{$whichdoit_is_level_3}},
                               @_draw_label_days_args );
         }    
      }
  }; # End subroutine

  

     
   my $_drawGrid = sub {
      my ($y1, $y2, $months, $hours, $minutes, $seconds, $range) = @_;   
      my %time = %$timeref;

      my @months  = @$months;
      my @hours   = @$hours;
      my @minutes = @$minutes;
      my @seconds = @$seconds;
      
      # actually begin ticking
      foreach my $year ( $y1..$y2 ) {
      if($time{-yeardoit}) {
       my $majORmin = ($time{-monthdoit}) ? 'major' : 'minor';
       &_draw_grid(  [ $year, 1,  1 ], [ 0, 0, 0 ], $majORmin,
                     @_draw_grid_args );
      
       # WORK ON MONTHS 
       if($time{-monthdoit} ) {
          my $majORmin = ($time{-daydoit}) ? 'major' : 'minor';
          foreach my $month ( ($majORmin eq 'minor') ? @months : @ONE2TWELVE ) {
             next if(&_dateLTGT($mindays,$maxdays,'month',
                               $year,$month));
             my $do = ($month == 1) ? 'major' : $majORmin; # force major on
             &_draw_grid([ $year, $month,  1], [ 0, 0, 0 ], $do,
                         @_draw_grid_args);
             
             # WORK ON DAYS
             if($timeref->{-daydoit}) {
                my $majORmin = ($time{-hourdoit}) ? 'major' : 'minor';
                my ($lastday, @days) =
                         &_workupDayArray($year,$month,$time{-daytickevery},
                                          $range, $labeldensity);   
                foreach my $day ( ($majORmin eq 'minor') ? @days : (1..$lastday) ) {
                   next if(&_dateLTGT($mindays,$maxdays,'day',
                                     $year,$month,$day));
                   my $do = ($day == 1) ? 'major' : $majORmin;  # force major on
                   &_draw_grid([ $year, $month, $day ], [ 0, 0, 0 ], $do,
                               @_draw_grid_args);
                           
                   # WORK ON HOURS
                   if($time{-hourdoit}) {
                      my $majORmin = ($time{-minutedoit}) ? 'major' : 'minor';
                      foreach my $hour ( ($majORmin eq 'minor') ?
                                          @hours : @ZERO2TWOTHREE ) {
                         next if(&_dateLTGT($mindays,$maxdays,'hour',
                                           $year,$month,$day,
                                           $hour));
                         my $do = ($hour == 0) ? 'major' : $majORmin;  # force major on
                         &_draw_grid([ $year, $month, $day ], [ $hour, 0, 0 ],
                                     $do, @_draw_grid_args);
                         
                         # WORK ON MINUTES
                         if($time{-minutedoit}) {
                            my $majORmin = ($time{-seconddoit}) ? 'major' : 'minor';
                            foreach my $minute ( ($majORmin eq 'minor') ?
                                                  @minutes : @ZERO2FIVENINE ) {
                               next if(&_dateLTGT($mindays,$maxdays,'min',
                                                 $year,$month,$day,
                                                 $hour,$minute));
                               my $do = ($minute == 0) ? 'major' : $majORmin;  # force major on
                               &_draw_grid([ $year,  $month, $day ],
                                           [ $hour, $minute, 0 ], $do,
                                            @_draw_grid_args);
                                            
                               # WORK ON SECONDS
                               if($time{-seconddoit}) {
                                  foreach my $second ( @seconds ) {
                                     next if(&_dateLTGT($mindays,$maxdays,'sec',
                                                       $year,$month,$day,
                                                       $hour,$minute,$second));
                                     my $majORmin = ($second == 0 ) ? 'major' : 'minor';
                                     &_draw_grid( [ $year,  $month,    $day ],
                                                  [ $hour, $minute, $second ],
                                                  $majORmin, @_draw_grid_args );
                                  }
                               }                
                            }
                         }
                      }
                   }   
                }  
             }
          }
       }
    } } };
   

   my $_drawTicks = sub {
      my ($y1, $y2, $months, $hours, $minutes, $seconds, $range) = @_;
      my %time = %$timeref;
      my ($yr_ticklen, $mon_ticklen, $day_ticklen,
          $hr_ticklen, $min_ticklen, $sec_ticklen);
      
      my @months  = @$months;
      my @hours   = @$hours;
      my @minutes = @$minutes;
      my @seconds = @$seconds;
            
      # actually begin ticking
      foreach my $year ( $y1..$y2 ) {
      $yr_ticklen = $ticklen{$time{-yeardoit}};
      if($time{-yeardoit}) {
       # if the other ticks and labels are not to be shown, then no need to show
       # the yearly tick on each side of the graph.  This is visually more consistent
       # with traditional 2-D charts.  Only need to test whether months are going
       # to be plotted if they are not then no need to check other time periods
       my $side = ($time{-monthdoit} ) ? 'bothsides' : 'oneside';
       &_draw_ticks( [ $year, 1,  1 ], [ 0, 0, 0 ], $yr_ticklen, $side,
                     @_draw_ticks_args); 
      
       # WORK ON MONTHS 
       if($time{-monthdoit} ) {
          my $majORmin = ($time{-daydoit}) ? 'major' : 'minor';
          $mon_ticklen = $ticklen{$time{-monthdoit}};
          foreach my $month ( ($majORmin eq 'minor') ? @months : @ONE2TWELVE ) {
             next if(&_dateLTGT($mindays,$maxdays,'month',$year,$month));
             &_draw_ticks( [ $year, $month,  1], [ 0, 0, 0 ], $mon_ticklen,
                           'oneside', @_draw_ticks_args);
            
             # WORK ON DAYS
             if($time{-daydoit}) {
                my $majORmin = ($time{-hourdoit}) ? 'major' : 'minor';
                my ($lastday, @days) =
                          &_workupDayArray($year,$month,$time{-daytickevery},
                                           $range, $labeldensity);   
                $day_ticklen = $ticklen{$time{-daydoit}};
                foreach my $day ( ($majORmin eq 'minor') ? @days : (1..$lastday) ) {
                   next if(&_dateLTGT($mindays,$maxdays,'day',
                                     $year,$month,$day));
                   &_draw_ticks( [ $year, $month, $day ],
                                  [     0,      0,    0 ], $day_ticklen,
                                  'oneside', @_draw_ticks_args );
                         
                   # WORK ON HOURS
                   if($time{-hourdoit}) {
                      my $majORmin = ($time{-minutedoit}) ? 'major' : 'minor';
                      $hr_ticklen = $ticklen{$time{-hourdoit}};
                      foreach my $hour ( ($majORmin eq 'minor') ?
                                          @hours : @ZERO2TWOTHREE ) {
                         next if(&_dateLTGT($mindays,$maxdays,'hour',
                                           $year,$month,$day,
                                           $hour));
                         &_draw_ticks( [ $year, $month, $day ],
                                        [ $hour,      0,    0 ], $hr_ticklen,
                                         'oneside', @_draw_ticks_args);
                          
                         # WORK ON MINUTES
                         if($time{-minutedoit}) {
                            my $majORmin = ($time{-seconddoit}) ? 'major' : 'minor';
                            $min_ticklen = $ticklen{$time{-minutedoit}};
                               
                            foreach my $minute ( ($majORmin eq 'minor') ?
                                                  @minutes : @ZERO2FIVENINE ) {
                               next if(&_dateLTGT($mindays,$maxdays,'min',
                                                 $year,$month,$day,
                                                 $hour,$minute));
                               &_draw_ticks( [ $year,  $month, $day ],
                                              [ $hour, $minute,    0 ],
                                              $min_ticklen, 'oneside',
                                              @_draw_ticks_args);
                                              
                               # WORK ON SECONDS
                               if($time{-seconddoit}) {
                                  $sec_ticklen = $ticklen{$time{-seconddoit}};
                                  foreach my $second ( @seconds ) {
                                     next if(&_dateLTGT($mindays,$maxdays,'sec',
                                                       $year,$month,$day,
                                                      $hour,$minute,$second));
                                     &_draw_ticks( [ $year,  $month,    $day ],
                                                    [ $hour, $minute, $second ],
                                                    $sec_ticklen, 'oneside',
                                                    @_draw_ticks_args);
                                  }
                               }                
                            }
                         }
                      }
                   }   
                }  
             }
          }
       }
    } } };
   
   # return to actually doing stuff in this subroutine
   my @args = ( \@labmonths, \@labhours, \@labminutes, \@labseconds, $range );
   &$_axisLabels( \@labyears, @args, \%offsets, \%begday, \%midday, \%endday )
       if(not $hidden);
      @args = ( \@months, \@hours, \@minutes, \@seconds, $range );
   &$_drawGrid(  $y1, $y2, @args );
   &$_drawTicks( $y1, $y2, @args );
   
   # This redraws the axis, which insures that there will be lines
   # listening for the mouse to click on a get the axis editors.
   my @dash = ();
   push(@dash, (-dash => $plot->{-borderdashstyle}) )
              if($plot->{-borderdashstyle} and
                 $plot->{-borderdashstyle} !~ /Solid/io);
   my @axisattr = ( -width => $plot->{-borderwidth},
                    -fill  => $plot->{-bordercolor}, @dash );
   if($xoy eq '-x') {
      $canv->createLine($xmin, $ymin, $xmax, $ymin, @axisattr,
                        -tags  => "$plot"."xaxis");   
      $canv->createLine($xmin, $ymax, $xmax, $ymax, @axisattr,
                        -tags  => "$plot"."xaxis");      
      createLineMetaPost($xmin, $ymin, $xmax, $ymin, {@axisattr});                  
      createLineMetaPost($xmin, $ymax, $xmax, $ymax, {@axisattr});
   }
   elsif($xoy eq '-y') {                                  
      $canv->createLine($xmin, $ymin, $xmin, $ymax, @axisattr,
                        -tags  => "$plot"."yaxis1");
      createLineMetaPost($xmin, $ymin, $xmin, $ymax, {@axisattr});
      unless($double_y) {  # DOUBLE Y
         $canv->createLine($xmax, $ymin, $xmax, $ymax, @axisattr,
                           -tags  => "$plot"."yaxis1");  
         createLineMetaPost($xmax, $ymin, $xmax, $ymax, {@axisattr});   
      }
   }
   else { # DOUBLE Y
      $canv->createLine($xmax, $ymin, $xmax, $ymax, @axisattr,
                        -tags  => "$plot"."yaxis2");
      createLineMetaPost($xmax, $ymin, $xmax, $ymax, {@axisattr});
   }
   # As with all the canvas drawing sub, the fonts need to be deleted so that
   # they can be dynamically generated at each call of a subroutine
   $canv->fontDelete($plot."$xoy"."numfont");
   
   
   # Finally, draw the axis label (title) that DrawMethods used to do
   my $offset = $aref->{-laboffset} + $offsets{$timeref->{-yeardoit}};
   &_xaxisLabel($plot, $canv, $offset),        return 1 if($xoy eq '-x' );
   &_yaxisLabel($plot, $canv, '-y', $offset),  return 1 if($xoy eq '-y' );
   &_yaxisLabel($plot, $canv, '-y2', $offset), return 1 if($xoy eq '-y2');
}

1;
