package Tkg2::Time::DrawTimeUtilities;

=head1 LICENSE

 This Tkg2 module is authored by the enigmatic William H. Asquith.
     
 This program is absolutely free software; 

Author of this software makes no claim whatsoever about suitability,
reliability, editability or usability of this product. If you can use it,
you are in luck, if not, I should not be and can not be held responsible.
Furthermore, portions of this software (tkg2 and related modules) were
developed by the Author as anemployee of the U.S. Geological Survey
Water-Resources Division, neither the USGS, the Department of the
Interior, or other entities of the Federal Government make any claim
whatsoever about suitability, reliability, editability or usability
of this product.

=cut

# $Author: wasquith $
# $Date: 2007/09/10 02:25:59 $
# $Revision: 1.21 $

use strict;
use vars qw(@ISA @EXPORT_OK);
use Exporter;
@ISA       = qw(Exporter);
@EXPORT_OK = qw(_Years
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
                
use Tkg2::Math::GraphTransform qw(transReal2CanvasGLOBALS revAxis);

use Tkg2::Draw::Labels::DrawLabels qw( __blankit );

use Tkg2::Time::Utilities qw( hhmmss2fracday
                              dayhhmmss2days
                              fracday2hhmmss
                              parsedays );  

use Tkg2::Base qw(@BaseDate);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createLineMetaPost
                                                createAnnoTextMetaPost);

use Date::Calc qw( Delta_Days
                   Delta_DHMS
                   Add_Delta_DHMS
                   Add_Delta_Days
                   Days_in_Month
                   Day_of_Week
                   Day_of_Year);

use constant TWO => scalar 2; 


use vars qw( @MONTHS_S
             @MONTHS_C
             @MONTHS_CS
             @MONTHS_CPUBSTYLE
             @MONTHS_L );

@MONTHS_S  = qw( none J F M A M J J A S O N D );
@MONTHS_C  = qw( none Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
@MONTHS_CS =   ( 'none', "J\na\nn", "F\ne\nb", "M\na\nr", "A\np\nr",
                         "M\na\ny", "J\nu\nn", "J\nu\nl", "A\nu\ng",
                         "S\ne\np", "O\nc\nt", "N\no\nv", "D\ne\nc" );
# The following are more traditional publication style abbreviations for
# the months.  These are provided separately because the three character
# abbreviations are still readable and smaller.  Space can be at a premium
# at times on time series plots.  The . and t for Sept were added at tkg2
# version 0.61.
@MONTHS_CPUBSTYLE =
             qw( none Jan. Feb. Mar.  Apr. May  June
                      July Aug. Sept. Oct. Nov. Dec.);
                             
@MONTHS_L  = qw( none January February March April May June July
                      August September October November December );


use vars qw( @DOW_S @DOW_C @DOW_L @Days_to_Use);

@DOW_S = qw(Su M T W Th F Sa Su);
@DOW_C = qw(Sun Mon Tues Wed Thur Fri Sat Sun);
@DOW_L = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday Sunday);

print $::SPLASH "=";


############ ADVANCED TIME MANIPULATION UTILITIES ##########

sub _Years {
   my ($timeref, $y1, $y2, $labeldensity) = @_;
   my $yrevery = $timeref->{-yeartickevery};
   return ($y1..$y2) if($timeref->{-monthdoit});
   
   my @years;
   if($yrevery eq 'auto') { # then go ahead a try of guess at nice looking plots
      my $yrdiff = $y2 - $y1;
      if($labeldensity == 1) {
         $yrevery = ( $yrdiff <  10 ) ?  1 :
                    ( $yrdiff <  20 ) ?  2 :
                    ( $yrdiff <  40 ) ?  5 :
                    ( $yrdiff <  80 ) ? 10 : 20;
      }
      elsif($labeldensity == 2) {
         $yrevery = ( $yrdiff <  20 ) ?  1 :
                    ( $yrdiff <  40 ) ?  2 :
                    ( $yrdiff <  60 ) ?  5 :
                    ( $yrdiff <  80 ) ? 10 : 20;
      }
      elsif($labeldensity == 3) {
         $yrevery = ( $yrdiff <  40 ) ?  1 :
                    ( $yrdiff <  80 ) ?  2 :
                    ( $yrdiff < 100 ) ?  5 :
                    ( $yrdiff < 120 ) ? 10 : 20;
      }
      else {
         print STDERR "Tkg2--warning _Years labeldensity ",
                      "invalid with $labeldensity\n";
      }
      # the option 'none' is never automatically turned on for years
   }

   foreach my $i ($y1..$y2) {
      last if($yrevery eq 'none'); # @years remains empty
      YEAR: {
         push(@years, $i), last YEAR if($yrevery ==  1);
         push(@years, $i), last YEAR if($yrevery ==  2 and $i =~ /[02468]$/o);
         push(@years, $i), last YEAR if($yrevery ==  5 and $i =~ /[05]$/o);
         push(@years, $i), last YEAR if($yrevery == 10 and $i =~ /[0]$/o);
         push(@years, $i), last YEAR if($yrevery == 20 and $i =~ /[02468][0]$/o);
      }
   }
   return @years;
}

sub _LabelYears {
   my ($timeref, $y1, $y2, $labeldensity) = @_;
   my $yrevery = $timeref->{-yeartickevery};
   return ($y1..$y2) if($timeref->{-monthdoit});
   
   my @years;
   if($yrevery eq 'auto') { # then go ahead a try of guess at nice looking plots
      my $yrdiff = $y2 - $y1;
      if($labeldensity == 1) {
         $yrevery = ( $yrdiff <  10 ) ?  1 :
                    ( $yrdiff <  20 ) ?  2 :
                    ( $yrdiff <  40 ) ?  5 :
                    ( $yrdiff <  60 ) ? 10 : 20;
      }
      elsif($labeldensity == 2) {
         $yrevery = ( $yrdiff <  20 ) ?  1 :
                    ( $yrdiff <  40 ) ?  2 :
                    ( $yrdiff <  60 ) ?  5 :
                    ( $yrdiff <  80 ) ? 10 : 20;
      }
      elsif($labeldensity == 3) {
         $yrevery = ( $yrdiff <  40 ) ?  1 :
                    ( $yrdiff <  80 ) ?  2 :
                    ( $yrdiff < 100 ) ?  5 :
                    ( $yrdiff < 120 ) ? 10 : 20;
      }
      else {
         print STDERR "Tkg2--warning _LabelYears labeldensity ",
                      "invalid with $labeldensity\n";
      }
      # the option 'none' is never automatically turned on for years
   }

   foreach my $i ($y1..$y2) {
      last if($yrevery eq 'none'); # @years remains empty
      YEAR: {
         push(@years, $i), last YEAR if($yrevery ==  1);
         push(@years, $i), last YEAR if($yrevery ==  2 and $i =~ /[02468]$/o);
         push(@years, $i), last YEAR if($yrevery ==  5 and $i =~ /[05]$/o);
         push(@years, $i), last YEAR if($yrevery == 10 and $i =~ /[0]$/o);
         push(@years, $i), last YEAR if($yrevery == 20 and $i =~ /[02468][0]$/o);
      }
   }
   return @years;
}

sub _Months {
   my ($timeref, $range, $labeldensity) = @_;
   return (1..12) if($timeref->{-daydoit});
   
   my $monthevery = $timeref->{-monthtickevery};
   if($monthevery eq 'auto') {
      if($labeldensity == 1) {
         $monthevery = ( $range < 380*4*2  ) ? 1 :
                       ( $range < 380*6*2  ) ? 2 :
                       ( $range < 380*8*2  ) ? 3 :
                       ( $range < 380*10*2 ) ? 4 :
                       ( $range < 380*12*2 ) ? 6 : 'none';
      }
      elsif($labeldensity == 2) {
         $monthevery = ( $range < 380*6*2  ) ? 1 :
                       ( $range < 380*8*2  ) ? 2 :
                       ( $range < 380*10*2 ) ? 3 :
                       ( $range < 380*12*2 ) ? 4 :
                       ( $range < 380*14*2 ) ? 6 : 'none';
      }
      elsif($labeldensity == 3) {
         $monthevery = ( $range < 380*8*2  ) ? 1 :
                       ( $range < 380*10*2 ) ? 2 :
                       ( $range < 380*12*2 ) ? 3 :
                       ( $range < 380*14*2 ) ? 4 :
                       ( $range < 380*16*2 ) ? 6 : 'none';
      }
      else {
         print STDERR "Tkg2--warning _Months labeldensity ",
                      "invalid with $labeldensity\n";
      }
   }
   
   return (6) if($monthevery eq 'none');
   
   return ($monthevery == 1)      ? (1..12)         :
          ($monthevery == 2)      ? (2,4,6,8,10,12) : 
          ($monthevery == 3)      ? (3,6,9,12)      : 
          ($monthevery == 4)      ? (4,8,12)        :
                                    (6,12);
} 
  
sub _LabelMonths {
   my ($timeref, $range, $labeldensity) = @_;
   return (1..12) if($timeref->{-daydoit});
   
   my $monthevery = $timeref->{-monthtickevery};
   if($monthevery eq 'auto') {
      if($labeldensity == 1) {
         $monthevery = ( $range < 380*4 ) ? 1 :
                       ( $range < 380*6 ) ? 2 :
                       ( $range < 380*8 ) ? 3 :
                       ( $range < 380*10 ) ? 4 :
                       ( $range < 380*12 ) ? 6 : 'none';
      }
      elsif($labeldensity == 2) {
         $monthevery = ( $range < 380*6  ) ? 1 :
                       ( $range < 380*8  ) ? 2 :
                       ( $range < 380*10  ) ? 3 :
                       ( $range < 380*12  ) ? 4 :
                       ( $range < 380*14 ) ? 6 : 'none';
      }
      elsif($labeldensity == 3) {
         $monthevery = ( $range < 380*8  ) ? 1 :
                       ( $range < 380*10  ) ? 2 :
                       ( $range < 380*12  ) ? 3 :
                       ( $range < 380*14 ) ? 4 :
                       ( $range < 380*16 ) ? 6 : 'none';
      }
      else {
         print STDERR "Tkg2--warning _Months labeldensity ",
                      "invalid with $labeldensity\n";
      }
   }
   
   return (6) if($monthevery eq 'none');
   
   return ($monthevery == 1) ? (1..12)         :
          ($monthevery == 2) ? (2,4,6,8,10,12) : 
          ($monthevery == 3) ? (3,6,9,12)      : 
          ($monthevery == 4) ? (4,8,12)        :
                               (6,12);
} 

sub _Hours {   
   my ($timeref, $range, $labeldensity) = @_;  
   my $hourevery = $timeref->{-hourtickevery};
   return (0..23) if($timeref->{-minutedoit});
   
   my $c = 1/24;
   if ($hourevery eq 'auto') {
       if($labeldensity == 1) {
          $hourevery = ( $range < $c*12*2  ) ?  1 :
                       ( $range < $c*24*2  ) ?  2 :
                       ( $range < $c*36*2  ) ?  3 :
                       ( $range < $c*48*2  ) ?  4 : 
                       ( $range < $c*72*2  ) ?  6 :
                       ( $range < $c*144*2 ) ? 12 : 'none';
       }
       elsif($labeldensity == 2) {
          $hourevery = ( $range < $c*24*2  ) ?  1 :
                       ( $range < $c*48*2  ) ?  2 :
                       ( $range < $c*72*2  ) ?  3 :
                       ( $range < $c*96*2  ) ?  4 : 
                       ( $range < $c*144*2 ) ?  6 :
                       ( $range < $c*288*2 ) ? 12 : 'none';
       }
       elsif($labeldensity == 3) {
          $hourevery = ( $range < $c*36*2  ) ?  1 :
                       ( $range < $c*72*2  ) ?  2 :
                       ( $range < $c*108*2 ) ?  3 :
                       ( $range < $c*144*2 ) ?  4 : 
                       ( $range < $c*216*2 ) ?  6 :
                       ( $range < $c*432*2 ) ? 12 : 'none';
       }
       else {
          print STDERR "Tkg2-warning _Hours labeldensity ",
                      "invalid with $labeldensity\n";
       }
   }
   
   return (12) if($hourevery eq 'none');
   
   return ($hourevery == 1) ? (0..23 )                         :
          ($hourevery == 2) ? (0,2,4,6,8,10,12,14,16,18,20,22) :
          ($hourevery == 3) ? (0,3,6,9,12,15,18,21)            :
          ($hourevery == 4) ? (0, 4, 8, 12, 16, 20)            : 
          ($hourevery == 6) ? (0, 6, 12, 18)                   :
                              (0, 12);
}  

sub _LabelHours {   
   my ($timeref, $range, $labeldensity) = @_;  
   my $hourevery = $timeref->{-hourtickevery};
   return (0..23) if($timeref->{-minutedoit});
   
   my $c = 1/24;
   if ($hourevery eq 'auto') {
       if($labeldensity == 1) {
          $hourevery = ( $range < $c*12  ) ?  1 :
                       ( $range < $c*24  ) ?  2 :
                       ( $range < $c*36  ) ?  3 :
                       ( $range < $c*48  ) ?  4 : 
                       ( $range < $c*72  ) ?  6 :
                       ( $range < $c*144 ) ? 12 : 'none';
       }
       elsif($labeldensity == 2) {
          $hourevery = ( $range < $c*24  ) ?  1 :
                       ( $range < $c*48  ) ?  2 :
                       ( $range < $c*72  ) ?  3 :
                       ( $range < $c*96  ) ?  4 : 
                       ( $range < $c*144 ) ?  6 :
                       ( $range < $c*288 ) ? 12 : 'none';
       }
       elsif($labeldensity == 3) {
          $hourevery = ( $range <= $c*48  ) ?  1 :
                       ( $range <  $c*72  ) ?  2 :
                       ( $range <  $c*108 ) ?  3 :
                       ( $range <  $c*144 ) ?  4 : 
                       ( $range <  $c*216 ) ?  6 :
                       ( $range <  $c*432 ) ? 12 : 'none';
       }
       else {
          print STDERR "Tkg2-warning _LabelHours labeldensity ",
                      "invalid with $labeldensity\n";
       }
   }
   return (12) if($hourevery eq 'none');
   
   return ($hourevery == 1)      ? (0..23 )                         :
          ($hourevery == 2)      ? (0,2,4,6,8,10,12,14,16,18,20,22) :
          ($hourevery == 3)      ? (0,3,6,9,12,15,18,21)            :
          ($hourevery == 4)      ? (0, 4, 8, 12, 16, 20)            : 
          ($hourevery == 6)      ? (0, 6, 12, 18)                   :
                                   (0, 12);
}  

sub _Minutes {
   my ($timeref, $range, $labeldensity) = @_;
   return (0..59) if($timeref->{-seconddoit});   
   my $minevery = $timeref->{-minutetickevery};
   my $c = (1/24)*(1/60);
   if($minevery eq 'auto') {
      if($labeldensity == 1) {
         $minevery = ( $range < $c*30*2  )  ?  1 : 
                     ( $range < $c*60*2    )  ?  2 :
                     ( $range < $c*150*2   )  ?  5 :
                     ( $range < $c*300*2   )  ? 10 :
                     ( $range < $c*450*2   )  ? 15 :
                     ( $range < $c*900*2   )  ? 30 : 'none';
      }
      elsif($labeldensity == 2) {
         $minevery = ( $range < $c*60*2    )  ?  1 : 
                     ( $range < $c*150*2   )  ?  2 :
                     ( $range < $c*300*2   )  ?  5 :
                     ( $range < $c*450*2   )  ? 10 :
                     ( $range < $c*900*2   )  ? 15 :
                     ( $range < $c*1800*2  )  ? 30 : 'none';
      }
      elsif($labeldensity == 3) {
         $minevery = ( $range < $c*150*2   )  ?  1 : 
                     ( $range < $c*300*2   )  ?  2 :
                     ( $range < $c*450*2   )  ?  5 :
                     ( $range < $c*900*2   )  ? 10 :
                     ( $range < $c*1800*2  )  ? 15 :
                     ( $range < $c*4500*2  )  ? 30 : 'none';
      }
      else {
         print STDERR "Tkg2--warning _Minutes labeldensity ",
                      "invalid with $labeldensity\n";
      }  
   }
   
   return (30) if($minevery eq 'none');
   
   if($minevery == 2 or $minevery == 5) {
      my @mins;
      for(my $i=$minevery;$i<=59;$i += $minevery) { push(@mins, $i); }
      return @mins;
   }
   return ($minevery == 1)  ? (0..59)      :
          ($minevery == 10) ? (0,10,20,30,40,50) : 
          ($minevery == 15) ? (15, 30, 45) : (30);   
}

sub _LabelMinutes {
   my ($timeref, $range, $labeldensity) = @_;
   return (0..59) if($timeref->{-seconddoit});   
   my $minevery = $timeref->{-minutetickevery};
   my $c = (1/24)*(1/60);
   if($minevery eq 'auto') {
            if($labeldensity == 1) {
         $minevery = ( $range < $c*30    )  ?  1 : 
                     ( $range < $c*60    )  ?  2 :
                     ( $range < $c*150   )  ?  5 :
                     ( $range < $c*300   )  ? 10 :
                     ( $range < $c*450   )  ? 15 :
                     ( $range < $c*900   )  ? 30 : 'none';
      }
      elsif($labeldensity == 2) {
         $minevery = ( $range < $c*60    )  ?  1 : 
                     ( $range < $c*150   )  ?  2 :
                     ( $range < $c*300   )  ?  5 :
                     ( $range < $c*450   )  ? 10 :
                     ( $range < $c*900   )  ? 15 :
                     ( $range < $c*1800  )  ? 30 : 'none';
      }
      elsif($labeldensity == 3) {
         $minevery = ( $range < $c*150   )  ?  1 : 
                     ( $range < $c*300   )  ?  2 :
                     ( $range < $c*450   )  ?  5 :
                     ( $range < $c*900   )  ? 10 :
                     ( $range < $c*1800  )  ? 15 :
                     ( $range < $c*4500  )  ? 30 : 'none';
      }
      else {
         print STDERR "Tkg2--warning _LabelMinutes labeldensity ",
                      "invalid with $labeldensity\n";
      }  
   }
   
   return (30) if($minevery eq 'none');
   
   if($minevery == 2 or $minevery == 5) {
      my @mins;
      for(my $i=$minevery;$i<=59;$i += $minevery) { push(@mins, $i); }
      return @mins;
   }
   return ($minevery == 1)  ? (0..59)      :
          ($minevery == 10) ? (0,10,20,30,40,50) : 
          ($minevery == 15) ? (15, 30, 45) : (30);   
}



sub _Seconds {
   my ($timeref, $range, $labeldensity) = @_;
   my $secevery = $timeref->{-secondtickevery};
   my $c = (1/24)*(1/60)*(1/60);
   if($secevery eq 'auto') {
      $secevery = ( $range < $c*90  )  ?  1 : 
                  ( $range < $c*180  )  ?  2 :
                  ( $range < $c*260  )  ?  5 :
                  ( $range < $c*540  )  ? 10 :
                  ( $range < $c*1080 )  ? 15 :
                  ( $range < $c*1620 )  ? 30 : 'none';  
   }
   return (30) if($secevery eq 'none');
   
   if($secevery == 2 or $secevery == 5) {
      my @secs;
      for(my $i=$secevery;$i<=59;$i += $secevery) { push(@secs, $i); }
      return @secs;
   }
   return ($secevery == 1)  ? (0..59)      :
          ($secevery == 10) ? (0,10,20,30,40,50) :
          ($secevery == 15) ? (15, 30, 45) : (30);   
}


sub _LabelSeconds {
   my ($timeref, $range, $labeldensity) = @_;
   my $secevery = $timeref->{-secondtickevery};
   my $c = (1/24)*(1/60)*(1/60);
   if($secevery eq 'auto') {
      $secevery = ( $range < $c*15  )  ?  1 : 
                  ( $range < $c*30  )  ?  2 :
                  ( $range < $c*60  )  ?  5 :
                  ( $range < $c*90  )  ? 10 :
                  ( $range < $c*180 )  ? 15 :
                  ( $range < $c*260 )  ? 30 : 'none';  
   }
   
   return (30) if($secevery eq 'none');
   
   if($secevery == 2 or $secevery == 5) {
      my @secs;
      for(my $i=$secevery;$i<=59;$i += $secevery) { push(@secs, $i); }
      return @secs;
   }
   return ($secevery == 1)  ? (0..59)      :
          ($secevery == 10) ? (0,10,20,30,40,50) :
          ($secevery == 15) ? (15, 30, 45) : (30);   
}

sub _dateLTGT {
   my ($mindays, $maxdays, $period, $yr, $mn, $dy, $h, $m, $s) = @_;
   my $per;
   $yr = 0 if not defined $yr;
   $mn = 1 if not defined $mn;
   $dy = 1 if not defined $dy;
   $h  = 0 if not defined $h;
   $m  = 0 if not defined $m;
   $s  = 0 if not defined $s;
   
   # Test the base date and see if it is outside the range of
   # interest.  
   my $days2;
   my $day  = &Delta_Days( 1900, 1, 1, $yr, $mn, $dy );
   my $days = &dayhhmmss2days( $day, $h, $m, $s );
   my $r1   = ( $days < $mindays ) ? 'lt' :
              ( $days > $maxdays ) ? 'gt' : 'bt';
   #print "BUG1: dateLTGT $mindays $maxdays $days ($yr $mn $dy $h $m $s) $r1\n";
   # Test the next date that the nested for loops will provide
   if($period eq 'month') {
      ($yr,$mn) = ($mn == 12) ? (++$yr, 1) : ($yr, ++$mn);
      $days2 = &Delta_Days(1900,1,1,$yr, $mn, $dy);
   }
   else {
      $days2 =
      ($period eq 'day') ?
         &dayhhmmss2days(
            &Delta_DHMS(1900,1,1,0,0,0,
               &Add_Delta_DHMS($yr, $mn, $dy, $h, $m, $s,
                  1, 0, 0, 0)))
      :
      ($period eq 'hour') ?
         &dayhhmmss2days(
            &Delta_DHMS(1900,1,1,0,0,0,
               &Add_Delta_DHMS($yr, $mn, $dy, $h, $m, $s,
                  0, 1, 0, 0)))
      :
      ($period eq 'min')  ?
         &dayhhmmss2days(
            &Delta_DHMS(1900,1,1,0,0,0,
               &Add_Delta_DHMS($yr, $mn, $dy, $h, $m, $s,
                  0, 0, 1, 0)))
      :
      ($period eq 'sec') ?
         &dayhhmmss2days(
            &Delta_DHMS(1900,1,1,0,0,0,
               &Add_Delta_DHMS($yr, $mn, $dy, $h, $m, $s,
                  0, 0, 0, 1)))
      :
      "dateLTGT  should not be here with period == $period\n";
      my $day  = &Delta_Days( 1900, 1, 1, $yr, $mn, $dy );
      my $days = &dayhhmmss2days( $day, $h, $m, $s );
   }
   
   my $r2 = ( $days2 < $mindays ) ? 'lt' :
            ( $days2 > $maxdays ) ? 'gt' : 'bt';
   #print "BUG2: dateLTGT $mindays $maxdays $days2 => $r2\n";
   my $ltgt = ( ($r1 eq 'lt' and $r2 eq 'lt') ||
                ($r1 eq 'gt' and $r2 eq 'gt') ) ? 1 : 0;
   #print "BUG3: dateLTGT: $r1 and $r2 is $ltgt\n";
   return $ltgt;
} 




sub _workupDayArray {
   my ($year, $month, $tickevery, $range, $labeldensity) = @_;
   my @days = ();
   my $lastday   = &Days_in_Month($year,$month);
   return ($lastday, @days) if($tickevery eq 'none');
   if($tickevery eq 'auto') {
      if($labeldensity == 1) {
         $tickevery = ( $range < 30*2  ) ?  1 :
                      ( $range < 60*2  ) ?  2 :
                      ( $range < 90*2  ) ?  3 :
                      ( $range < 120*2 ) ?  4 : 
                      ( $range < 240*2 ) ?  7 :
                      ( $range < 380*2 ) ? 14 : 'none';
      }
      elsif($labeldensity == 2) {
         $tickevery = ( $range < 60*2  ) ?  1 :
                      ( $range < 90*2  ) ?  2 :
                      ( $range < 120*2 ) ?  3 :
                      ( $range < 240*2 ) ?  4 : 
                      ( $range < 380*2 ) ?  7 :
                      ( $range < 580*2 ) ? 14 : 'none';
      }
      elsif($labeldensity == 3) {
         $tickevery = ( $range < 367    ) ?  1 :
                      ( $range < 240*2  ) ?  2 :
                      ( $range < 380*2  ) ?  3 :
                      ( $range < 580*2  ) ?  4 : 
                      ( $range < 700*2  ) ?  7 :
                      ( $range < 1160*2 ) ? 14 : 'none';
      }
      else {
         print STDERR "Tkg2--warning _workupDayArray labeldensity ",
                      "invalid with $labeldensity\n";
      }
   }

   return ($lastday, (15) ) if($tickevery eq 'none');

   if($tickevery == 1) {
      push(@days, (1 .. $lastday ) );
   }
   elsif($tickevery == 2 or $tickevery == 3 or $tickevery == 4) {
      for(my $i=$tickevery; $i <= $lastday; $i += $tickevery) { 
         push(@days, $i);
      }
   }    
   elsif($tickevery == 7) {
      push(@days, ( 7, 14, 21, 28 ) );
   }
   else {
      push(@days, ( 14, 28 ) );
   }

   return ($lastday, @days);

}  

sub _LabelworkupDayArray {
   my ($year, $month, $tickevery, $range, $labeldensity) = @_;
   my @days = ();
   my $lastday   = &Days_in_Month($year,$month);
   return ($lastday, @days) if($tickevery eq 'none');
   if($tickevery eq 'auto') {
      if($labeldensity == 1) {
         $tickevery = ( $range < 30  ) ?  1 :
                      ( $range < 60  ) ?  2 :
                      ( $range < 90  ) ?  3 :
                      ( $range < 120 ) ?  4 : 
                      ( $range < 240 ) ?  7 :
                      ( $range < 380 ) ? 14 : 'none';
      }
      elsif($labeldensity == 2) {
         $tickevery = ( $range < 60  ) ?  1 :
                      ( $range < 90  ) ?  2 :
                      ( $range < 120 ) ?  3 :
                      ( $range < 240 ) ?  4 : 
                      ( $range < 380 ) ?  7 :
                      ( $range < 580 ) ? 14 : 'none';
      }
      elsif($labeldensity == 3) {
         $tickevery = ( $range < 90   ) ?  1 :
                      ( $range < 120  ) ?  2 :
                      ( $range < 240  ) ?  3 :
                      ( $range < 380  ) ?  4 : 
                      ( $range < 580  ) ?  7 :
                      ( $range < 1160 ) ? 14 : 'none';
      }
      else {
         print STDERR "Tkg2--warning _LabelworkupDayArray labeldensity ",
                      "invalid with $labeldensity\n";
      }
   }

   return ($lastday, (15) ) if($tickevery eq 'none');

   if($tickevery == 1) {
      push(@days, (1 .. $lastday ) );
   }
   elsif($tickevery == 2 or $tickevery == 3 or $tickevery == 4) {
      for(my $i=$tickevery; $i <= $lastday; $i += $tickevery) {
         push(@days, $i);
      }
   }    
   elsif($tickevery == 7) {
      push(@days, ( 7, 14, 21, 28 ) );
   }
   else {
      push(@days, ( 14, 28 ) );
   }

   return ($lastday, @days);

}  

sub _checkDoIts {
   my ($timeref, $range, $labeldepth) = @_;   
   
   my $willbelevel = 1;
   $timeref->{-seconddoit} = ($range > (1/24)*.25 ) ? 0 : $willbelevel++;
   $timeref->{-minutedoit} = ($range >  .25       ) ? 0 : $willbelevel++;
   $timeref->{-hourdoit}   = ($range >  15        ) ? 0 : $willbelevel++;
   $timeref->{-daydoit}    = ($range >  367       ) ? 0 : $willbelevel++;
   $timeref->{-monthdoit}  = ($range > 4*365      ) ? 0 : $willbelevel++;
   $timeref->{-yeardoit}   = $willbelevel;
   
   # The test on the second is needed so that seconddoit will
   # never take on values greater than 1
   if($labeldepth >= 2 and $timeref->{-seconddoit} == 0) {
      $timeref->{-seconddoit}++ if($timeref->{-minutedoit});
      $timeref->{-minutedoit}++ if($timeref->{-hourdoit});
      $timeref->{-hourdoit}++   if($timeref->{-daydoit});
      $timeref->{-daydoit}++    if($timeref->{-monthdoit});
      $timeref->{-monthdoit}++;
      $timeref->{-yeardoit}++;
   }

   if($labeldepth >= 3 and $timeref->{-seconddoit} == 0) {
      $timeref->{-seconddoit}++ if($timeref->{-minutedoit});
      $timeref->{-minutedoit}++ if($timeref->{-hourdoit});
      $timeref->{-hourdoit}++   if($timeref->{-daydoit});
      $timeref->{-daydoit}++    if($timeref->{-monthdoit});
      $timeref->{-monthdoit}++;
      $timeref->{-yeardoit}++;
   }
   
   #print "_checkDoIts: range = $range\n",
   #             "Year   doit is $timeref->{-yeardoit}\n",
   #             "Month  doit is $timeref->{-monthdoit}\n",
   #             "Day    doit is $timeref->{-daydoit}\n",
   #             "Hour   doit is $timeref->{-hourdoit}\n",
   #             "Minute doit is $timeref->{-minutedoit}\n",
   #             "Second doit is $timeref->{-seconddoit}\n";
}   


sub __splitdays {
   my $days = shift;
   my ($day, $fracday)      = &parsedays($days);
   # because the since of sign is important for dates less than the
   # base date, we need to subtract one day away when a fraction
   # is present.  Hopefully this bug was fixed on 09/22/2000
   $day-- if($day < 0 and $fracday); # NEGATIVE TIME BUG FIX
   my ($yr,   $m,      $d)  = &Add_Delta_Days(@BaseDate, $day);
   my ($hr,  $min,    $sec) = &fracday2hhmmss($fracday);
   return ($yr, $m, $d, $hr, $min, $sec);
}


sub _get_midpoint_of_min_and_max {
   my ($mindays, $maxdays) = @_;
   my $middays = ($mindays + $maxdays) / 2;
   return &__splitdays($middays);
}
   
# Break the min and max days values into its unique component parts
sub _get_beg_and_end_days { 
   my ($mindays, $maxdays) = @_;           
   # Get the beginning and ending days                                                                                     
   my ($y1, $m1, $d1, $hr1, $min1, $sec1) = &__splitdays($mindays);
   
   my ($y2, $m2, $d2, $hr2, $min2, $sec2) = &__splitdays($maxdays);
   
   return ($y1, $m1, $d1, $hr1, $min1, $sec1,
           $y2, $m2, $d2, $hr2, $min2, $sec2);
}
############ END ADVANCED TIME MANIPULATION UTILITIES ##########



############ DRAWING OF TEXT ON THE AXIS #######################

# Private subroutines to draw text along the x axis
# One for the bottom x axis and one for the top x axis
# _drawTextonBottom($canv,$x,$ymax,$numoffset,$text,$numfont,$numcolor);
sub _drawTextonBottom {
   my ($canv, $x, $ymax, $text, 
       $numoffset,  $isrev, $aref, $plotastag, $numfont, $numcolor,
       $blankit, $blankcolor, $anchor) = @_;
   $anchor = 'n'  if(not defined $anchor);
   if($isrev) {
      if(    $anchor =~ /minedge/o) {
             $anchor = 'maxedge';
      }
      elsif( $anchor =~ /maxedge/o) {
             $anchor = 'minedge';
      } 
   }
   
   $anchor = 'nw' if($anchor eq 'minedge');
   $anchor = 'ne' if($anchor eq 'maxedge');
   
   my $ftref = $aref->{-numfont};

   my $y   = $ymax + $numoffset;
   my $tag = $plotastag.'axislabel';
   $canv->createText($x, $y,
                     -text   => $text,
                     -anchor => $anchor,
                     -font   => $numfont,
                     -fill   => $numcolor,
                     -tags   => $tag);
   createAnnoTextMetaPost($x,$y,{-text       => $text,
                                 -family     => $ftref->{-family},
                                 -size       => $ftref->{-size},
                                 -slant      => $ftref->{-slant},
                                 -weight     => $ftref->{-weight},
                                 -angle      => $ftref->{-rotation},
                                 -fill       => $ftref->{-color},
                                 -anchor     => $anchor,
                                 -blankit    => $blankit,
                                 -blankcolor => $blankcolor});
   &__blankit($canv, $blankit, $blankcolor, $tag) if($blankit);
}

# _drawTextonTop($canv,$x,$ymin,$numoffset,$text,$numfont,$numcolor);
sub _drawTextonTop {
   my ($canv, $x, $ymin, $text, 
       $numoffset,  $isrev, $aref, $plotastag, $numfont, $numcolor,
       $blankit, $blankcolor, $anchor) = @_;
   $anchor = 's' if(not defined $anchor);
   
   if($isrev) {
      if(    $anchor =~ /minedge/o) {
             $anchor = 'maxedge';
      }
      elsif( $anchor =~ /maxedge/o) {
             $anchor = 'minedge';
      } 
   }
   
   $anchor = 'sw' if($anchor eq 'minedge');
   $anchor = 'se' if($anchor eq 'maxedge');
   
   my $y   = $ymin - $numoffset;
   my $tag = $plotastag.'axislabel';
   $canv->createText($x, $y,
                     -text   => $text,
                     -anchor => $anchor,
                     -font   => $numfont,
                     -fill   => $numcolor,
                     -tags   => $tag);   
   createAnnoTextMetaPost($x,$y,{-text => $text});
   &__blankit($canv, $blankit, $blankcolor, $tag) if($blankit);
}

# Private subroutines to draw text along the y axis
# One for the left y axis and one for the right y axis
# _drawTextonLeft($canv,$xmin,$y,$numoffset,$text,$numfont,$numcolor);
sub _drawTextonLeft {
   my ($canv, $xmin, $y, $text,
       $numoffset,  $isrev, $aref, $plotastag, $numfont, $numcolor,
       $blankit, $blankcolor, $anchor) = @_;
   $anchor = 'e' if(not defined $anchor or $anchor =~ /edge/o);
   my $x   = $xmin - $numoffset;
   my $tag = $plotastag.'axislabel';
   $canv->createText($x,$y,
                     -text   => $text,
                     -anchor => $anchor,
                     -font   => $numfont,
                     -fill   => $numcolor,
                     -tags   => $tag);
   createAnnoTextMetaPost($x,$y,{-text => $text});
   &__blankit($canv, $blankit, $blankcolor, $tag) if($blankit);
}

# _drawTextonRight($canv,$xmax,$y,$numoffset,$text,$numfont,$numcolor);
sub _drawTextonRight {
   my ($canv, $xmax, $y, $text, 
       $numoffset, $isrev, $aref, $plotastag, $numfont, $numcolor,
       $blankit, $blankcolor, $anchor) = @_;
   $anchor = 'w' if(not defined $anchor or $anchor =~ /edge/o);
   my $x   = $xmax + $numoffset;
   my $tag = $plotastag.'axislabel';
   $canv->createText($x, $y,
                     -text   => $text,
                     -anchor => $anchor,
                     -font   => $numfont,
                     -fill   => $numcolor,
                     -tags   => $tag);
   createAnnoTextMetaPost($x,$y,{-text => $text});   
   &__blankit($canv, $blankit, $blankcolor, $tag) if($blankit);
}



sub _draw_label_days {
   # call as &(days, label, offset)
   my ($days, $label, $off) = splice(@_,0,3);
   my ($plot, $canv, $xoy, $aref, $location,
       $xmin, $ymin, $xmax, $ymax,
       $dblabel, $double_y, $textattr) = @_;
   my @textattr = @$textattr;
              
   my $XY = &transReal2CanvasGLOBALS($plot,$xoy, 'time', 1, $days);
   return 0 if(not defined $XY );
   my $isrev = $aref->{-reverse};
   $XY = &revAxis($plot,$xoy,$XY) if($aref->{-reverse});
   if($xoy eq '-x') {
      if($dblabel) {
         &_drawTextonTop($canv,$XY,$ymin,$label,$off,$isrev,$aref,@textattr);
         &_drawTextonBottom($canv,$XY,$ymax,$label,$off,$isrev,$aref,@textattr);
      }
      elsif($location eq 'bottom') {
         &_drawTextonBottom($canv,$XY,$ymax,$label,$off,$isrev,$aref,@textattr);
      }
      elsif($location eq 'top') {
         &_drawTextonTop($canv,$XY,$ymin,$label,$off,$isrev,$aref,@textattr);
      }
      else {
         die "Bad location '$location' call on time axis label\n";
      }     
   }
   elsif($xoy eq '-y') {
      if($dblabel and not $double_y) { # DOUBLE Y
         &_drawTextonLeft($canv,$xmin,$XY,$label,$off,$isrev,$aref,@textattr);
         &_drawTextonRight($canv,$xmax,$XY,$label,$off,$isrev,$aref,@textattr);
      }
      elsif($location eq 'left' or $double_y) { # DOUBLE Y
         &_drawTextonLeft($canv,$xmin,$XY,$label,$off,$isrev,$aref,@textattr);
      }
      elsif($location eq 'right' and not $double_y) {
         &_drawTextonRight($canv,$xmax,$XY,$label,$off,$isrev,$aref,@textattr);
      }
      else {
         die "Bad location '$location' call on time axis label\n";
      }
   }
   else { # DOUBLE Y
      &_drawTextonRight($canv,$xmax,$XY,$label,$off,$isrev,$aref,@textattr);
   }
   return 1;
}


sub _MonthsToUse {
   my ($timeref, $range) = @_;
   my @months_C = ($timeref->{-compact_months_in_publication_style}) ?
                          @MONTHS_CPUBSTYLE : @MONTHS_C;
   return @months_C if(not $timeref->{-monthdoit});
   return ($range > 1.5*365) ? @MONTHS_S :
          ($range >     240) ? @months_C : @MONTHS_L;
}

sub _DaysToUse {
   my ($timeref, $range) = @_;
   @Days_to_Use = ($range > 10) ? @DOW_S :
                  ($range >  5) ? @DOW_C : @DOW_L;
}

sub _2DOW {
   my ($y, $m, $d) = @_;
   my $dow = &Day_of_Week($y, $m, $d);
   return $Days_to_Use[$dow];
}

                   
sub _draw_label {
   # call as &([y,m,d],[h,m,s],label,offset)
   my ($ymd, $hms) = splice(@_,0,2); # DO NOT REMOVE shifts
   my $days  = &Delta_Days(@BaseDate, @$ymd);
      $days += &hhmmss2fracday(@$hms);
   #print "_draw_label @$ymd at @$hms\n";
   return &_draw_label_days($days, @_);
}


# _get_the_label_format returns an anonymous subroutine that is 
# responsible for much of the labeling on the time axis
# The anonymous subroutine is actually generated by either of the
# other two _get_the_label_format_*** subroutines that are called
# dependent upon the toggling of the day of the year variable
sub _get_the_label_format { 
   my ($timeref, $showyr, $level) = @_;
   my $showDOY = $timeref->{-show_day_of_year_instead};
   return ($showDOY) ?
     &_get_the_label_format_for_day_of_year($timeref,$showyr,$level)
         :
     &_get_the_label_format_day_of_month($timeref,$showyr,$level);
}

sub _get_the_label_format_for_day_of_year {
   my ($timeref, $showyr, $level) = @_;
   my %doits = %$timeref;
   my $showDOW = $doits{-show_day_as_additional_string};
   if($showyr) {
     if($doits{-hourdoit}  == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    my $doy1 = &Day_of_Year($y,$m,$d);
                    return ($showDOW) ?
                            "$doy1(".&_2DOW($y,$m,$d)."), $y @ $hr"."H" :
                            "$doy1, $y @ $hr"."H" ;
                  };      
     }
     elsif($doits{-daydoit} == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    my $doy2 = &Day_of_Year($y,$m,$d);
                    return ($showDOW) ?
                            "$doy2(".&_2DOW($y,$m,$d)."), $y" :
                            "$doy2, $y" ;
                  };      
     }
     elsif($doits{-monthdoit} == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    return "$months_touse[$m], $y";
                  };           
     }
     elsif($doits{-yeardoit} == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    return "$y";
                  };   
     }
     else {
       return sub { return "";
                  };
     }
   }
   else {
     if($doits{-hourdoit} == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    my $doy1 = &Day_of_Year($y,$m,$d);
                    return ($showDOW) ?
                            "$doy1(".&_2DOW($y,$m,$d).") @ $hr"."H" :
                            "$doy1 @ $hr"."H" ;
                  };      
     }
     elsif($doits{-daydoit} == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;                     my $doy = &Day_of_Year($y,$m,$d);
                    my $doy2 = &Day_of_Year($y,$m,$d);
                    return ($showDOW) ?
                            "$doy2(".&_2DOW($y,$m,$d).")" :
                            "$doy2";
                  };      
     }
     elsif($doits{-monthdoit} == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    return "$months_touse[$m]";
                  };           
     }
     elsif($doits{-yeardoit} == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    return "";
                  };   
     }
     else {
       return sub { return "";
                  };
     }
   }
}


sub _get_the_label_format_day_of_month {
   my ($timeref, $showyr, $level) = @_;
   my %doits = %$timeref;
   my $showDOW = $doits{-show_day_as_additional_string};
   if($showyr) {
     if($doits{-hourdoit}  == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    return ($showDOW) ?
                            "$months_touse[$m] $d(".&_2DOW($y,$m,$d)."), $y @ $hr"."H" :
                            "$months_touse[$m] $d, $y @ $hr"."H" ;
                  };      
     }
     elsif($doits{-daydoit} == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    return ($showDOW) ?
                            "$months_touse[$m] $d(".&_2DOW($y,$m,$d)."), $y" :
                            "$months_touse[$m] $d, $y" ;
                  };      
     }
     elsif($doits{-monthdoit} == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    return "$months_touse[$m], $y";
                  };           
     }
     elsif($doits{-yeardoit} == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    return "$y";
                  };   
     }
     else {
       return sub { return "";
                  };
     }
   }
   else {
     if($doits{-hourdoit} == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    return ($showDOW) ?
                            "$months_touse[$m] $d(".&_2DOW($y,$m,$d).") @ $hr"."H" :
                            "$months_touse[$m] $d @ $hr"."H" ;
                  };      
     }
     elsif($doits{-daydoit} == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    return ($showDOW) ?
                            "$months_touse[$m] $d(".&_2DOW($y,$m,$d).")" :
                            "$months_touse[$m] $d";
                  };      
     }
     elsif($doits{-monthdoit} == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    return "$months_touse[$m]";
                  };           
     }
     elsif($doits{-yeardoit} == $level) {
       return sub { my ($y, $m, $d, $hr, $min, $sec, @months_touse) = @_;
                    return ""; };   
     }
     else {
       return sub { return "";
                  };
     }
   }
}
############ END DRAWING OF TEXT ON THE AXIS #######################


############ DRAWING OF TIME AXIS GRID #######################
sub _draw_grid {
   # call as &([y,m,d],[h,m,s],tick)
   my ($ymd, $hms, $majORmin) = splice(@_,0,3);
   my $days  = &Delta_Days(@BaseDate, @$ymd);
      $days += &hhmmss2fracday(@$hms);
   &__really_draw_grid($days, $majORmin,@_);
}

sub __really_draw_grid {
   my ($tmpday, $majORmin,
       $plot, $canv, $aref, $xoy,
       $xmin, $ymin, $xmax, $ymax,
       $majorgridlinedoit, $minorgridlinedoit, 
       $mingridattr, $majgridattr) = @_;
   my @mingridattr = @$mingridattr;
   my @majgridattr = @$majgridattr;
   my $XY = &transReal2CanvasGLOBALS($plot,$xoy, 'time', 1, $tmpday);
   return 0 if(not defined $XY ); 
   $XY = &revAxis($plot,$xoy,$XY) if($aref->{-reverse});
   if($xoy eq '-x') {
      if($majORmin eq 'major' and $majorgridlinedoit) {
        $canv->createLine($XY, $ymin, $XY, $ymax, @majgridattr);
        createLineMetaPost($XY, $ymin, $XY, $ymax, {@majgridattr});
      }
      if($majORmin eq 'minor' and $minorgridlinedoit) {
        $canv->createLine($XY, $ymin, $XY, $ymax, @mingridattr);
        createLineMetaPost($XY, $ymin, $XY, $ymax, {@mingridattr});
      }  
   }
   else {
      if($majORmin eq 'major'  and $majorgridlinedoit) {
        $canv->createLine($xmin, $XY, $xmax, $XY, @majgridattr);
        createLineMetaPost($xmin, $XY, $xmax, $XY, @majgridattr);
      }
      if($majORmin eq 'minor'  and $minorgridlinedoit) {
        $canv->createLine($xmin, $XY, $xmax, $XY, @mingridattr);
        createLineMetaPost($xmin, $XY, $xmax, $XY, @mingridattr);
      }
   }
}
############ END DRAWING OF TIME AXIS GRID #####################

############ DRAWING TICKS ON THE AXIS #######################

# &_draw_ticks([y,m,d],[h,m,s],tick,onbothsides,@draw_tick_args);
sub _draw_ticks {
   # call as &([y,m,d],[h,m,s],tick)
   my ($ymd, $hms, $tick, $onbothsides) = splice(@_,0,4);
   my $days = &Delta_Days(@BaseDate, @$ymd);
   $days += &hhmmss2fracday(@$hms);
   &__really_draw_ticks($days, $tick, $onbothsides, @_);
}

# $__really_draw_ticks -- the engine that draws ticks on the axis
sub __really_draw_ticks {
   my ($tmpday, $tick, $onbothsides,
       $plot, $canv, $aref, $xoy, $location,
       $xmin, $ymin, $xmax, $ymax,
       $dblabel, $double_y, $lineattr) = @_;
   my @lineattr = @$lineattr;
   my $XY = &transReal2CanvasGLOBALS($plot,$xoy, 'time', 1, $tmpday);
   return 0 if(not defined $XY );
            
   # two op-posite ticks are needed so that the side getting the 
   # labeling will have yearly divisions.
   my $op_tick1 = ($onbothsides eq 'bothsides') ? $tick : 0; 
   my $op_tick2 = ($dblabel) ? $op_tick1 : 0;
            
   $XY = &revAxis($plot,$xoy,$XY) if($aref->{-reverse});      
   if($xoy eq '-x') {
      if($location eq 'bottom') {
         # tick along the bottom
         $canv->createLine( $XY, $ymax + $op_tick1, $XY, $ymax - $tick,  @lineattr);
         createLineMetaPost($XY, $ymax + $op_tick1, $XY, $ymax - $tick, {@lineattr});
         # tick along the top                 
         $canv->createLine( $XY, $ymin - $op_tick2, $XY, $ymin + $tick,  @lineattr);
         createLineMetaPost($XY, $ymin - $op_tick2, $XY, $ymin + $tick, {@lineattr});
      }
      else {
         # tick along the bottom
         $canv->createLine( $XY, $ymax + $op_tick2, $XY, $ymax - $tick,  @lineattr);
         createLineMetaPost($XY, $ymax + $op_tick2, $XY, $ymax - $tick, {@lineattr});
         # tick along the top                 
         $canv->createLine( $XY, $ymin - $op_tick1, $XY, $ymin + $tick,  @lineattr);
         createLineMetaPost($XY, $ymin - $op_tick1, $XY, $ymin + $tick, {@lineattr});
      }
   }
   elsif($xoy eq '-y') {
      if($location eq 'left') {
         # tick along the left
         $canv->createLine( $xmin - $op_tick1, $XY, $xmin + $tick, $XY,  @lineattr);
         createLineMetaPost($xmin - $op_tick1, $XY, $xmin + $tick, $XY, {@lineattr});
         # tick along the right
         unless($double_y) {  # DOUBLE Y
            $canv->createLine( $xmax + $op_tick2, $XY, $xmax - $tick, $XY,  @lineattr);
            createLineMetaPost($xmax + $op_tick2, $XY, $xmax - $tick, $XY, {@lineattr});
         }
      }
      else {
         # tick along the left
         $canv->createLine( $xmin - $op_tick2, $XY, $xmin + $tick, $XY,  @lineattr);
         createLineMetaPost($xmin - $op_tick2, $XY, $xmin + $tick, $XY, {@lineattr});
         # tick along the right
         unless($double_y) { # DOUBLE Y
            $canv->createLine( $xmax + $op_tick1, $XY, $xmax - $tick, $XY,  @lineattr);
            createLineMetaPost($xmax + $op_tick1, $XY, $xmax - $tick, $XY, {@lineattr});
         }
      }
   }
   else { # DOUBLE Y 
      $canv->createLine( $xmax + $op_tick1, $XY, $xmax - $tick, $XY,  @lineattr);
      createLineMetaPost($xmax + $op_tick1, $XY, $xmax - $tick, $XY, {@lineattr});
   }
}   
############ END DRAWING TICKS ON THE AXIS #######################

1;
