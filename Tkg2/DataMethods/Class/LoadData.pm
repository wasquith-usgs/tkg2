package Tkg2::DataMethods::Class::LoadData;

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
# $Date: 2004/09/21 19:09:57 $
# $Revision: 1.46 $

use strict;
use File::Basename;

use Tkg2::Base qw(isNumber Message Show_Me_Internals $benchit);
use Tkg2::Time::TimeMethods;

use Tkg2::DataMethods::DataSet;

use Tkg2::DataMethods::Class::RouteData2Script qw(RouteData2Script_Actually_Perform);

use Tkg2::DataMethods::Set::DataLimits qw(setDataLimits
                                          set_limits_on_first_data);

use Tkg2::Plot::BoxPlot::BoxPlotData qw(constructBoxPlotDataObject);

use Exporter;
use SelfLoader;

use vars qw(@ISA @EXPORT_OK @EXPORT);
@ISA = qw(Exporter SelfLoader);

@EXPORT_OK = qw(LoadDataSets LoadDataOnTheFly);

print $::SPLASH "=";


# RUNTIME LOADING OF DATA

sub LoadDataOnTheFly {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $dataset, $plot, $canv, $header, $data, $para) = @_;
   my $abscissa  = $dataset->{-DATA}->[0]->{-origabscissa};
   my $thirdord  = $dataset->{-DATA}->[0]->{-origthirdord};
   my $fourthord = $dataset->{-DATA}->[0]->{-origfourthord};
   my @ordinates;
     
   my $missval         = $para->{-missingval};
   
   # Backwards compatability, not really needed, but lets populate
   # the hash anyway.  The $para is also in $dataset->{-file} so this
   # is a poorly constructed call, but this works.  NEW FOR 0.61+
   $dataset->{-file}->{-common_datetime} = ""
                      if(not exists $dataset->{-file}->{-common_datetime});
   # Backwards compatability, not really needed, but lets populate
   # the hash anyway.  NEW FOR 0.71+
   $dataset->{-file}->{-datetime_offset} = "0"
                      if(not exists $dataset->{-file}->{-datetime_offset});
                      
   # Now extract the common datetime from the hash, 
   my $common_datetime  = $para->{-common_datetime};
   my $datetime_offset  = $para->{-datetime_offset};
   
   # Set up stuff for discrete axis work
   my $xref             = $plot->{-x};
   my $yref             = $plot->{-y};
   my $label_x_discrete = $xref->{-discrete}->{-labelhash};
   my $label_y_discrete = $yref->{-discrete}->{-labelhash};
  
   my $isSpecialPlot     = 0;
   my $special_plot_type = 'none';
   my $special_plot_attributes;
   my $plotstyle;
   my $which_y_axis; # DOUBLE Y
   my $yax; # DOUBLE Y
   foreach my $subset ( @{$dataset->{-DATA}} ) {
      my $attref               = $subset->{-attributes};
      $plotstyle               = $attref->{-plotstyle};
      $which_y_axis = $attref->{-which_y_axis}; # DOUBLE Y
      $yax = ($which_y_axis == 2) ? '-y2' : '-y'; # DOUBLE Y
      $special_plot_attributes = $attref->{-special_plot};
      if($special_plot_attributes) {
         SWITCH: {
            my $ref = ref $special_plot_attributes;
            $special_plot_type = 'box'  , last SWITCH if($ref =~ m/box/io  );
            $special_plot_type = 'stiff', last SWITCH if($ref =~ m/stiff/io);
         }
         $isSpecialPlot = ($special_plot_type ne 'none') ? 1 : 0;
      }
      push( @ordinates, $subset->{-origordinate} );
   }
   
   my $isAccumulation = ($plotstyle =~ /accumulation/io) ? 1 : 0;

   # Now determine whether additional splitting on the third or fourth data
   # fields is going to be necessary
   my $split3rd = ($thirdord                 and
                   $thirdord  =~ m/:string/o and
                   $plotstyle !~ m/text/io   ) ? 1 : 0;
   my $split4th = ($fourthord                and
                   $fourthord =~ m/:string/o ) ? 1 : 0;
   # the errors are limits variable provides important control as to
   # whether to +- the value(s) from the data point to to use the
   # values in lue of any knowledge of the data point
   my $errors_are_limits = ($plotstyle =~ m/error/io and
                            $plotstyle =~ m/limits/io) ? 1 : 0;

   my $ordinates_as1_column = $para->{-ordinates_as1_column};    # toggle a transformation
   my $routedata2script     = $para->{-transform_data}->{-doit}; # toggle a transformation
   my $megacommand          = $para->{-megacommand};             # need a megacommand logic built
   if($ordinates_as1_column) {
     my $ordinates;
     ($data, $ordinates) =
          &_ordinates_as1_column($data, $abscissa, \@ordinates, $thirdord, $fourthord, 'onthefly');
     @ordinates = @$ordinates;
   }
   elsif($routedata2script) {
       my ($statusOK, $newdata) = &RouteData2Script_Actually_Perform($para, $data, $abscissa, \@ordinates);
       if($statusOK eq 'OK') {
         $data = $newdata;
       }
       else {
         print $::VERBOSE " Tkg2-RouteData2Script_Actually_Perform: ",
                          "returned $statusOK\n     Going ahead and ",
                          "continuing as if no transform was desired\n";
       }
   }
   
   
   # Special instructions for building up data sets for box, stiff and any
   # future special plot types
   my $orientation        = 'not applicable';
   my $min_at_orientation = undef;
   my $max_at_orientation = undef;
   my $special_by_group   = 0;
   if($isSpecialPlot) {
      my $ordinates;
      my @bulkargs = ($data,
                       $abscissa,
                        \@ordinates,
                         $thirdord,
                          $special_plot_type,
                           $special_plot_attributes,
                            'onthefly',
                             $missval );
      ($data,
        $abscissa,
         $ordinates,
          $thirdord,
           undef,
            $orientation,
             $min_at_orientation,
              $max_at_orientation,
               $special_by_group ) = &_specialPlot_instructions(@bulkargs);
      @ordinates = @$ordinates; # need the actual array for this overall method
   }      
      
   # For PlotPos to actually do anything @ordinates will only contain
   # one element and not many as in other types of plots and plotstyle
   # will likely be wrong.
   &_PlottingPositions($data, $plotstyle, $abscissa, \@ordinates, $missval);
   
   &ConvertTime($self, $data, $abscissa, \@ordinates,
                $missval, $common_datetime, $datetime_offset);
   
   if( ref($data->{$abscissa}) ne 'ARRAY' ) { # Trap needed for user observed errors
     &_errorTrapForLoadDatas('abscissa',$abscissa);
     return;
   }
   # sort the read in data on the abscissa value if user wants
   &_sortRawData($data,$para,$abscissa);

   my @data_abscissa = @{ $data->{$abscissa} }; 
   
   # HANDLE SOME ABSCISSA BOOK KEEPING
   # usually the limits will already be valid, but if the data file has changed
   # since last save then we need to reconfigure
   if( $abscissa =~ /:number/o or $abscissa =~ /:(calc)?time/o ) {
      if($isSpecialPlot and $orientation eq 'horizontal') {
         &setDataLimits($plot,'-x',[$min_at_orientation, $max_at_orientation],0);
      }
      else {
         my @x;
         foreach (@data_abscissa) {
           push(@x,$_) unless(   not defined($_)
                              or $_ eq $para->{-missingval}
                              or not &isNumber($_) );  
         }
         @x = sort { $a <=> $b } @x;
         &setDataLimits($plot,'-x',\@x,0);
      }
      $xref->{-type} = 'time' if($abscissa =~ /:(calc)?time/o);
   }
   else { # turn discrete on if it isn't already
      $xref->{-discrete}->{-doit} = 'stack' if( not $xref->{-discrete}->{-doit} );
   } 
      
   foreach my $ordinatenumber (0..$#ordinates) {
      my $ordinate = $ordinates[$ordinatenumber];
      # turn discrete option on if is isn't already
      $yref->{-discrete}->{-doit} = 'stack'
            if( $ordinate =~ /:string/o and not $yref->{-discrete}->{-doit} );
   }
   
   my $do_x_discrete = $xref->{-discrete}->{-doit};  # hard wired discrete do it
   my $do_y_discrete = $yref->{-discrete}->{-doit};  # hard wired discrete do it
   
   foreach my $ordinatenumber (0..$#ordinates) {
      my @data = ();
      my $ordinate = $ordinates[$ordinatenumber];
      if( ref($data->{$ordinate}) ne 'ARRAY'  ) { # user observed error
          &_errorTrapForLoadDatas('ordinate',$ordinate);
          return;
      }
      my @data_ordinate = @{ $data->{$ordinate} };
      
      my @data_thirdord;
      if( defined $thirdord ) {
         if( ref($data->{$thirdord}) ne 'ARRAY' ) {
            &_errorTrapForLoadDatas('third ordinate',$thirdord);
            return;
         }
         @data_thirdord = @{ $data->{$thirdord}  };
      }
      
      my @data_fourthord;
      if( defined $fourthord ) {
         if( ref($data->{$fourthord}) ne 'ARRAY' ) {
            &_errorTrapForLoadDatas('fourth ordinate',$fourthord);
            return;
        }
        @data_fourthord = @{ $data->{$fourthord} };
      }
      
      my ($j, $nj) = ( 0, $#{$data->{$ordinate}} );
      
      $#data = $nj; # preallocate the array
      
      my $XY_checker =
         sub { my ($i, $x, $y) = @_;
               my ($newx, $newy);
               if($do_x_discrete) { # if the x-axis is discrete
                  if( exists( $label_x_discrete->{$x} ) ) { # has this discrete value been seen
                      $newx = $label_x_discrete->{$x};      # yep, so change $x to the count
                  }
                  else {  # no, we have not yet seen the discrete value in $x yet
                     $newx = keys(%$label_x_discrete) + 1; # set $x to count + 1
                     $label_x_discrete->{$x} = $newx; # load into axis label hash
                  }
               } 
               if($do_y_discrete) { # if the y-axis is discrete
                  if( exists( $label_y_discrete->{$y} ) ) { # has this discrete value been seen
                      $newy = $label_y_discrete->{$y};      # yep, so change $x to the count
                  }
                  else {  # no, we have not yet seen the discrete value in $y yet
                     $newy = keys(%$label_y_discrete) + 1; # set $y to count + 1
                     $label_y_discrete->{$y} = $newy; # load into axis label hash
                  }
               }
               my $returnx = ($do_x_discrete) ? [ $newx, $x ] : $x;
               my $returny = ($do_y_discrete) ? [ $newy, $y ] : $y;
               
               return ($returnx, $returny);
             };
      
      
      my $y_accumulator  = 0;
      my $r3_accumulator = 0;
      foreach my $i (0..$nj) {
         my ($rX, $rY, $r3, $r4 ) = ( $data_abscissa[$i], $data_ordinate[$i],
                                      $data_thirdord[$i], $data_fourthord[$i] ); # the raw values
         $rX = 'missingval' if( not defined $rX or $rX eq "" or $rX eq $missval );
         $rY = 'missingval' if( not defined $rY or $rY eq "" or $rY eq $missval );

         if( not defined $thirdord ) { # just add X and Y in dataset
            $data[$j] = [ $rX, $rY ], $j++, next if($rX eq 'missingval' or $rY eq 'missingval');
            my ($x, $y) = &$XY_checker($i, $rX, $data_ordinate[$i]);
            $y = $y_accumulator += $y if($isAccumulation);
            $data[$j] = [ $x, $y ];    # finally fill the data array
         }
         elsif( defined $thirdord and ($plotstyle =~ /text/io or $isSpecialPlot) ) {
            $r3 = "" if( not defined $r3 );
            
            $data[$j] = [ $rX, $rY, $r3 ], $j++, next if($rX eq 'missingval' or $rY eq 'missingval');
            
            # if the plot is Text and the Text value undef, replace with null string
            my ($x, $y) = &$XY_checker($i, $rX, $rY );
            $y = $y_accumulator += $y if($isAccumulation);
            $data[$j] = [ $x, $y, $r3 ];  # finally fill the data array
         }
         elsif( defined $thirdord and $plotstyle =~ m/Shade Between/o) {
            $r3 = "missingval" if( not defined $r3 or $r3 eq $missval );
            $data[$j] = [ $rX, $rY, $r3 ], $j++, next if($rX eq 'missingval' or
                                                         $rY eq 'missingval' or
                                                         $r3 eq 'missingval');
            
            my ($x,$y) = &$XY_checker($i, $rX, $rY);
            
            $y  =  $y_accumulator += $y  if($isAccumulation);
            $r3 = $r3_accumulator += $r3 if($r3 ne 'missingval' and $isAccumulation);
            
            $data[$j] = [ $x, $y, $r3 ];  # finally fill the data array
         }
         elsif( defined $thirdord and not defined $fourthord ) {
            
            $r3 = 'missingval' if( not defined $r3 or $r3 eq "" or $r3 eq $missval );
            my ($r3_1,$r3_2) = ($split3rd) ? split(/<=>/o,$r3,2) : ($r3,$r3);
            $r3_1 = 'missingval' if(not defined $r3_1 or
                                    $r3_1 eq $missval or
                                    not &isNumber($r3_1) );
            $r3_2 = 'missingval' if(not defined $r3_2 or
                                    $r3_2 eq $missval or
                                    not &isNumber($r3_2) );
 
            
            $data[$j] = [ $rX, $rY,
                           [$r3_1, $r3_2]
                        ], $j++, next if($rX eq 'missingval' or $rY eq 'missingval');
            
            my ($x, $y) = &$XY_checker($i, $rX, $rY );
            
            $data[$j] = ($errors_are_limits) ? 
                          [ $x, $y,
                            [ $r3_1,
                              $r3_2
                            ]
                          ]
                        :
                          [ $x, $y,
                            [ ( $rY + $r3_1 ),
                              ( $rY - $r3_2 )
                            ]
                          ]; 
         }
         else {
            
            $r3 = 'missingval' if( not defined $r3 or $r3 eq "" or $r3 eq $missval );
            $r4 = 'missingval' if( not defined $r4 or $r4 eq "" or $r4 eq $missval );

            my ($r3_1,$r3_2) = ($split3rd) ? split(/<=>/o,$r3,2) : ($r3,$r3);
            my ($r4_1,$r4_2) = ($split4th) ? split(/<=>/o,$r4,2) : ($r4,$r4);
            
            $r3_1 = 'missingval' if(not defined $r3_1 or
                                    $r3_1 eq $missval or
                                    not &isNumber($r3_1) );
            $r3_2 = 'missingval' if(not defined $r3_2 or
                                    $r3_2 eq $missval or
                                    not &isNumber($r3_2) );
            
            $r4_1 = 'missingval' if(not defined $r4_1 or
                                    $r4_1 eq $missval or
                                    not &isNumber($r4_1) );
            $r4_2 = 'missingval' if(not defined $r4_2 or
                                    $r4_2 eq $missval or
                                    not &isNumber($r4_2) );
            
            $data[$j] = [ $rX, $rY,
                           [$r3_1, $r3_2],
                           [$r4_1, $r4_2]
                        ], $j++, next if($rX eq 'missingval' or $rY eq 'missingval');
            
            my ($x, $y) = &$XY_checker($i, $rX, $rY );
            
            $data[$j] = ($errors_are_limits) ? 
                          [ $x, $y,
                            [ $r3_1,
                              $r3_2
                            ],
                            [ $r4_1, 
                              $r4_2
                            ] 
                          ]
                        :
                          [ $x, $y,
                            [ ( $rX + $r3_1 ),
                              ( $rX - $r3_2 )
                            ],
                            [ ( $rY + $r4_1 ),
                              ( $rY - $r4_2 )
                            ] 
                          ]; 
         }  
         $j++;  # j will hold the actual number of values loaded
      }
      
      $#data = ($j-1); # truncate the array for skipped data fields
      $dataset->addjustdata( [ @data ], $ordinatenumber );
      
      # HANDLE SOME ORDINATE BOOK KEEPING
      $yref->{-type} = 'time' if($ordinate =~ /:(calc)?time/o);
      
      next if( defined $fourthord and $ordinate eq $fourthord );
      if($do_y_discrete) { 
         my @y = (1, scalar( keys( %$label_y_discrete ) ) );
         &setDataLimits($plot, $yax, \@y, 1); # DOUBLE Y:
      } 
      else { # do all this if the y axis is just a continuous
       if($ordinate =~ /:(number|(calc)?time)/o) { # insure no call on :string
          if($isSpecialPlot and $orientation eq 'vertical') {
             # DOUBLE Y:
             &setDataLimits($plot,$yax,[$min_at_orientation, $max_at_orientation],0);
          }
          else {
            my @tmpdata;
            foreach my $k (0..$#data) {
               my $val = $data[$k]->[1];
               push(@tmpdata, $val) unless(   not defined $val
                                           or $val eq $para->{-missingval}
                                           or not &isNumber($val) );               
            }      
            my @y = sort { $a <=> $b } @tmpdata;
            &setDataLimits($plot, $yax, \@y, 0); # DOUBLE Y:
         }
       }
      }
      
      if($do_x_discrete) { # The X-axis needs updating again, because the number of
         # discrete groups can dynamically change after the data has been loaded.
         my @x = (1, scalar(keys( %$label_x_discrete )) );
         &setDataLimits($plot,'-x', \@x,1);
      }   

   }
  
   $plot->routeAutoLimits;
   
}



sub _sortRawData {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($data, $para, $abscissa) = ( shift, shift, shift);
   return unless( $para->{-sortdoit} );
   my $sorttype = $para->{-sorttype};
   my $sortdir  = $para->{-sortdir};
   print $::VERBOSE " Tkg2-Sorting variable $abscissa by ",
                    "$sorttype as $sortdir"."ing.\n";
   my @abscissa = @{ $data->{$abscissa} };
      
   my @index = ( 0..$#abscissa );
   if($sorttype eq 'numeric') {
      if($sortdir eq 'ascend') {
          @index = sort { $abscissa[$a] <=> $abscissa[$b] } @index;
      }
      else {
          @index = sort { $abscissa[$b] <=> $abscissa[$a] } @index;
      }
   }
   else {
      if($sortdir eq 'ascend') {
          @index = sort { $abscissa[$a] cmp $abscissa[$b] } @index;
      }
      else {
          @index = sort { $abscissa[$b] cmp $abscissa[$a] } @index;
      }
   }
   foreach ( keys %$data) {
      my @array = @{$data->{$_}};
      @array = @array[@index];
      $data->{$_} = [ @array ];
   }
   return 1;
}



sub _PlottingPositions {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($data, $plotstyle, $abscissa, $ordinates, $missval) = ( shift, shift, shift, shift, shift);
   my @ordinates  = @$ordinates;
   unless(scalar(@ordinates) == 1) {
      ## warn "PlottingPositions called with more than one ordinate\n";
      return $data;
   }
   unless($plotstyle eq 'X-Probability' or $plotstyle eq 'Y-Probability') {
      ## warn "PlottingPositions called bad plotstyle $plotstyle\n";
      return $data;
   }
   
   my @core = ($plotstyle eq 'X-Probability') ? @{ $data->{$ordinates->[0]} } :
                                                @{ $data->{$abscissa} };                                              
   # Missing values are simply thrown away when dealing with plotting
   # position computation.  Not possibly to "lift the pen" and we
   # don't want bad plotting positions being computed.
   my @newcore = ();
   foreach (@core) {
      push(@newcore,$_) unless(not defined $_ or $_ eq "" or $_ eq $missval);
   }
   @core = sort { $a <=> $b } @newcore;
   
   my @pp;   
   my $coe = $::TKG2_CONFIG{-PLOTTING_POSITION_COEFFICIENT};  # Plotting Position
   foreach (0..$#core) {
      $pp[$_] = ($_-$coe) / ($#core+1-2*$coe);
   }
  
   if( $plotstyle eq 'X-Probability' ) {
      $data->{$abscissa}       = [ @pp ];
      $data->{$ordinates->[0]} = [ @core ];   
   }
   else {
      $data->{$abscissa}       = [ @core ];
      $data->{$ordinates->[0]} = [ @pp ];
      
   }
   return $data;
}

1;

__DATA__
  
sub LoadDataSets {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ( $self, $canv, $plot, $template,
         $data,
          $abscissa,
           $ordinates,
            $thirdord,
             $fourthord,
              $para,
               $plotpara,
                $special_instructions ) = @_;
   my $plotstyle = $plotpara->{-plotstyle};
   
   my $isAccumulation = ($plotstyle =~ /accumulation/io) ? 1 : 0;
    
   my $which_y_axis = $plotpara->{-which_y_axis}; # DOUBLE Y: 
   my $yax = ($which_y_axis == 2) ? '-y2' : '-y'; # DOUBLE Y: 
   my $combined_ordinate_name = undef;
   my $name;
   if(defined $para->{-fullfilename} ) {
      $name = &basename( $para->{-fullfilename} );
   }
   else {
      print STDERR "Tkg2: Warning basename() was ",
                   "going to be called with undef--",
                   "Tkg2/DataMethods/Class/LoadDataSets\n";
      return;
   }
   my $missval                = $para->{-missingval};
   my $common_datetime        = $para->{-common_datetime};
   my $datetime_offset        = $para->{-datetime_offset};
   my $ordinates_as1_column   = $para->{-ordinates_as1_column};     # toggle a transformation
   my $routedata2script       = $para->{-transform_data}->{-doit};  # toggle a transformation
   my $megacommand            = $para->{-megacommand};       # need a megacommand logic built
   
   
   # Now determine whether additional splitting on the third or fourth data
   # fields is going to be necessary
   my $split3rd = ($thirdord                 and
                   $thirdord  =~ m/:string/o and
                   $plotstyle !~ m/text/io   ) ? 1 : 0;
   my $split4th = ($fourthord                and
                   $fourthord =~ m/:string/o ) ? 1 : 0;
   my $errors_are_limits = ($plotstyle =~ m/error/io and
                            $plotstyle =~ m/limits/io) ? 1 : 0;
   
   if($ordinates_as1_column) {
      ($data, $ordinates) =
          &_ordinates_as1_column($data, $abscissa, $ordinates, $thirdord, $fourthord, 'notonthefly');
   }
   elsif($routedata2script) {
      my ($statusOK, $newdata) = &RouteData2Script_Actually_Perform($para, $data, $abscissa, $ordinates);
      if($statusOK eq 'OK') {
         $data = $newdata;
       }
       else {
         my $mess = " Tkg2-RouteData2Script_Actually_Perform: returned $statusOK\n".
                    " Going ahead and continuing as if no transform was desired\n";
         print $::BUG $mess;
       }
   }
   
   # Special instructions for building up data sets for box, stiff and any
   # future special plot types
   my $orientation        = 'not applicable';
   my $min_at_orientation = undef;
   my $max_at_orientation = undef;
   my $special_plot_type  = 'none';
   my $isSpecialPlot      = 0;
   my $special_by_group   = 0;
   if($plotstyle =~ m/box/io or $plotstyle =~ m/stiff/io) {
      $isSpecialPlot      = 1;
      $special_plot_type  = 'box' if($plotstyle =~ m/box/io);
      my @bulkargs = ($data,
                       $abscissa,
                        $ordinates,
                         $thirdord,
                          $plotstyle,
                           $special_instructions,
                            'notonthefly',
                             $missval );
      ($data,
        $abscissa,
         $ordinates,
          $thirdord,
           $combined_ordinate_name,
            $orientation,
             $min_at_orientation,
              $max_at_orientation,
               $special_by_group ) = &_specialPlot_instructions(@bulkargs);
      $plotstyle = 'Scatter';  # all special plots are Scatter type originally
   }           
 
   &_PlottingPositions($data, $plotstyle, $abscissa, $ordinates, $missval);
   
   # Set up stuff for discrete axis work
   my $xref             = $plot->{-x};
   my $yref             = $plot->{-y};
   my $label_x_discrete = $xref->{-discrete}->{-labelhash};
   my $label_y_discrete = $yref->{-discrete}->{-labelhash};

   # Finally construct the new data set object
   my $dataset = Tkg2::DataMethods::DataSet->new($name);
      $dataset->configDataSet_file(%$para);    
   
   &ConvertTime($self, $data, $abscissa, $ordinates,
                $missval, $common_datetime, $datetime_offset);
   
   my @data_abscissa = @{ $data->{$abscissa} };  # note that deref not needed in the lower loops
   
   # HANDLE SOME ABSCISSA BOOK KEEPING
   if($abscissa =~ /:number/o or $abscissa =~ /:(calc)?time/o) {
      if($isSpecialPlot and $orientation eq 'horizontal') {
         &setDataLimits($plot,'-x',[$min_at_orientation, $max_at_orientation],0);
      }
      else {
         my @x;
         foreach (@data_abscissa) {
           push(@x,$_) unless(   not defined $_ 
                              or $_ eq $para->{-missingval}
                              or not &isNumber($_) );
         } 
         @x = sort { $a <=> $b } @x;
         &setDataLimits($plot,'-x',\@x,0);
      }
      $xref->{-type} = 'time' if($abscissa =~ /:(calc)?time/o);
   }
   else {  # must turn the discrete option on, if not already set
      $xref->{-discrete}->{-doit} = 'stack' if( not $xref->{-discrete}->{-doit} );
   }
   
   &_sortRawData($data,$para,$abscissa);  # sort the read in data on the abscissa value if user wants
 
   foreach my $ordinate (@$ordinates) { # are any of the ordinates strings?
     # turn discrete option on, if not already set
     $yref->{-discrete}->{-doit} = 'stack'
             if( $ordinate =~ /:string/o and not $yref->{-discrete}->{-doit} ); 
   }

   my $do_x_discrete = $xref->{-discrete}->{-doit};  # hard wired discrete do it
   my $do_y_discrete = $yref->{-discrete}->{-doit};  # hard wired discrete do it
   
   foreach my $ordinate (@$ordinates) {
      if(not defined $data->{$ordinate} ) { # Willard Gibbons observation
         my ($verytemp) = $ordinate =~ m/(.+):.+/;
         print $::BUG "LOADING ERROR\n\n".
           "Though the data file was read in, tkg2 was unable to properly match ".
           "the requested ordinate '$ordinate' with a column in the file. ".
           "One known source of this problem is when a missing ".
           "data is flagged as '--', but the -missingval key had '' (null). ".
           "Thus, the data was converted to a string type.".
           " So tkg2 had loaded this instead '$verytemp:string'.";
           return;
      }
      my @data_ordinate  = @{ $data->{$ordinate}  };
      my @data_thirdord  = @{ $data->{$thirdord}  } if( defined $thirdord  );
      
      my @data_fourthord = @{ $data->{$fourthord} } if( defined $fourthord );
      
      my ($j, $nj) = ( 0, $#data_ordinate );
      my @data = ();
      $#data = $nj;
      
      my $XY_checker =
         sub { my ($i, $x, $y) = @_;
               my ($newx, $newy);
               # The x-axis is discrete
               if($do_x_discrete) {                      
                  if( exists( $label_x_discrete->{$x} ) ) { # has this discrete value been seen
                      $newx = $label_x_discrete->{$x};      # yep, so change $x to the count
                  }
                  else {  # no, we have not yet seen the discrete value in $x yet
                     $newx = keys(%$label_x_discrete) + 1;  # set $x to count + 1
                     $label_x_discrete->{$x} = $newx; # load into axis label hash
                  }
               } 
               
               # The y-axis is discrete
               if($do_y_discrete) { 
                  if( exists( $label_y_discrete->{$y} ) ) { # has this discrete value been seen
                      $newy = $label_y_discrete->{$y};      # yep, so change $x to the count
                  }
                  else {  # no, we have not yet seen the discrete value in $y yet
                     $newy = keys(%$label_y_discrete) + 1;         # set $y to count + 1
                     $label_y_discrete->{$y} = $newy; # load into axis label hash
                  }
               }
               
               my $returnx = ($do_x_discrete) ? [ $newx, $x ] : $x;
               my $returny = ($do_y_discrete) ? [ $newy, $y ] : $y;
               
               return ($returnx, $returny);
             };
      
      my $y_accumulator  = 0;
      my $r3_accumulator = 0;
      foreach my $i (0..$nj) {
         my ($rX, $rY, $r3, $r4 ) = ( $data_abscissa[$i], $data_ordinate[$i],
                                      $data_thirdord[$i], $data_fourthord[$i] ); # the raw values
         $rX = 'missingval' if( not defined $rX or $rX eq "" or $rX eq $missval );
         $rY = 'missingval' if( not defined $rY or $rY eq "" or $rY eq $missval );
         
         if(not defined $thirdord ) {  # just add X and Y in dataset
            $data[$j] = [ $rX, $rY ], $j++, next if($rX eq 'missingval' or $rY eq 'missingval');
            my ($x,$y) = &$XY_checker($i, $rX, $rY);
            $y = $y_accumulator += $y if($isAccumulation);
            $data[$j] = [ $x, $y ]; # finally fill the data array
         }
         elsif( defined $thirdord and ($plotstyle =~ m/text/io or $isSpecialPlot) ) {
            $r3 = "" if( not defined $r3 );
            
            $data[$j] = [ $rX, $rY, $r3 ], $j++, next if($rX eq 'missingval' or
                                                         $rY eq 'missingval');
            
            # if the plot is Text and the Text value undef, replace with null string
            my ($x,$y) = &$XY_checker($i, $rX, $rY);
            $y = $y_accumulator += $y if($isAccumulation);
            $data[$j] = [ $x, $y, $r3 ];  # finally fill the data array
         }
         elsif( defined $thirdord and $plotstyle =~ m/Shade Between/o) {
            $r3 = "missingval" if( not defined $r3 or $r3 eq $missval );
            
            $data[$j] = [ $rX, $rY, $r3 ], $j++, next if($rX eq 'missingval' or
                                                         $rY eq 'missingval' or
                                                         $r3 eq 'missingval');
            
            my ($x,$y) = &$XY_checker($i, $rX, $rY);
            
            $y  =  $y_accumulator += $y  if($isAccumulation);
            $r3 = $r3_accumulator += $r3 if($r3 ne 'missingval' and $isAccumulation);
            
            $data[$j] = [ $x, $y, $r3 ];  # finally fill the data array
         }
         elsif( defined $thirdord and not defined $fourthord ) {
            
            $r3 = 'missingval' if( not defined $r3 or $r3 eq "" or $r3 eq $missval );
            my ($r3_1,$r3_2) = ($split3rd) ? split(/<=>/o,$r3,2) : ($r3,$r3);
            $r3_1 = 'missingval' if(not defined $r3_1 or
                                    $r3_1 eq $missval or
                                    not &isNumber($r3_1) );
            $r3_2 = 'missingval' if(not defined $r3_2 or
                                    $r3_2 eq $missval or
                                    not &isNumber($r3_2) );
 
            
            $data[$j] = [ $rX, $rY,
                           [$r3_1, $r3_2]
                        ], $j++, next if($rX eq 'missingval' or $rY eq 'missingval');
            
            my ($x, $y) = &$XY_checker($i, $rX, $rY );
            
            $data[$j] = ($errors_are_limits) ? 
                          [ $x, $y,
                            [ $r3_1,
                              $r3_2
                            ]
                          ]
                        :
                          [ $x, $y,
                            [ ( $rY + $r3_1 ),
                              ( $rY - $r3_2 )
                            ]
                          ];   
         }
         else {
            
            $r3 = 'missingval' if( not defined $r3 or $r3 eq "" or $r3 eq $missval );
            $r4 = 'missingval' if( not defined $r4 or $r4 eq "" or $r4 eq $missval );

            my ($r3_1,$r3_2) = ($split3rd) ? split(/<=>/o,$r3,2) : ($r3,$r3);
            my ($r4_1,$r4_2) = ($split4th) ? split(/<=>/o,$r4,2) : ($r4,$r4);
            
            $r3_1 = 'missingval' if(not defined $r3_1 or
                                    $r3_1 eq $missval or
                                    not &isNumber($r3_1) );
            $r3_2 = 'missingval' if(not defined $r3_2 or
                                    $r3_2 eq $missval or
                                    not &isNumber($r3_2) );
            
            $r4_1 = 'missingval' if(not defined $r4_1 or
                                    $r4_1 eq $missval or
                                    not &isNumber($r4_1) );
            $r4_2 = 'missingval' if(not defined $r4_2 or
                                    $r4_2 eq $missval or
                                    not &isNumber($r4_2) );

            
            $data[$j] = [ $rX, $rY,
                           [$r3_1, $r3_2],
                           [$r4_1, $r4_2]
                        ], $j++, next if($rX eq 'missingval' or $rY eq 'missingval');
            
            my ($x, $y) = &$XY_checker($i, $rX, $rY );
           
            $data[$j] = ($errors_are_limits) ? 
                          [ $x, $y,
                            [ $r3_1,
                              $r3_2
                            ],
                            [ $r4_1, 
                              $r4_2
                            ] 
                          ]
                        :
                          [ $x, $y,
                            [ ( $rX + $r3_1 ),
                              ( $rX - $r3_2 )
                            ],
                            [ ( $rY + $r4_1 ),
                              ( $rY - $r4_2 )
                            ] 
                          ]; 
         }   
         $j++;
      } # END THE DATA LOOP
      
      $#data = ($j-1); # truncate the array for skipped data fields
      
      # here is the original, version 0.24 call before box plots
      #$dataset->add( [ @data ], $abscissa, $ordinate, $thirdord, $fourthord, $plotstyle );
      # here is the call after version 0.24 to handle box plots
      # 
      LOAD_DATA_INTO_DATASET_OBJECT: {
         my $new_ordinate = (defined $combined_ordinate_name) ? $combined_ordinate_name :
                                                                $ordinate               ;
         $dataset->add( [ @data ],
                        $abscissa,
                         $new_ordinate,
                          $thirdord,
                           $fourthord,
                            $plotstyle,
                             $which_y_axis,
                              $special_plot_type,
                               $orientation,
                                $special_by_group,
                                 $special_instructions); # DOUBLE Y:
      }
      
      # HANDLE SOME ORDINATE BOOK KEEPING
      $yref->{-type} = 'time' if($ordinate =~ /:(calc)?time/o);
      
      # HERE IS A PROBLEM, IF THE y ordinate is also the text ordinate
      # then the the following next causes a jump around setDataLimits
      #if( defined $thirdord and $ordinate eq $thirdord ) { # fixed on 11/4/99
      #  # thus we need the following test
      #  next if(    defined $yref->{-datamin}->{-whenlinear}
      #          and defined $yref->{-datamax}->{-whenlinear} );
      #}  
      # WHA commented out the above on 5/30/2000 because the y axis
      # was not being re-setDataLimits when another plot had already been
      # loaded.  Presumably the $ordinate =~ /:(number|time)/ test protects
      # against a bad call into the 
      
      
      next if( defined $fourthord and $ordinate eq $fourthord );
      
      if($do_y_discrete) { 
         my @y = (1, scalar( keys( %$label_y_discrete ) ) );
         &setDataLimits($plot,$yax,\@y,1);
      } 
      else { # do all this if the y axis is just a continuous\
         if( $ordinate =~ /:(number|(calc)?time)/o ) { # insure no call on :string
            if($isSpecialPlot and $orientation eq 'vertical') {
               &setDataLimits($plot,$yax,[$min_at_orientation, $max_at_orientation],0);
            }
            else {
               my @tmpdata;
               foreach my $k (0..$#data) {
                  my $val = $data[$k]->[1];
                  push(@tmpdata, $val) unless(   not defined $val 
                                              or $val eq $para->{-missingval}
                                              or not &isNumber($val)
                                             );               
               }
               my @y = sort { $a <=> $b } @tmpdata;
               &setDataLimits($plot,$yax,\@y,0);
            }
         }
      }
      
      if($do_x_discrete) { # The X-axis needs updating again, because the number of
         # discrete groups can dynamically change after the data has been loaded.
         my @x = (1, scalar(keys( %$label_x_discrete )) );
         &setDataLimits($plot,'-x', \@x,1);
      }    

   } # END THE ORDINATE LOOP
   $self->add($dataset);
   
   # set_limits_on_first_data provides a very special call on routeAutoLimits
   # if set_limits... returns false then we need to manually call
   # routeAutoLimits.  This is done to make code more parallel to LoadDataOnTheFly
   unless( &set_limits_on_first_data($self,$plot) ) {
      $plot->routeAutoLimits;
   }
   
   $template->UpdateCanvas($canv); # Update needed here but not in LoadDataOnTheFly
}




sub _errorTrapForLoadDatas {  # Willard Gibbons observation
     # ??? Only need to trap for LoadDataOnTheFly
   my ($absORord, $var) = (shift, shift);
   my ($verytemp) = $var =~ m/(.+):.+/;
   print $::BUG "DYNAMIC LOADING ERROR\n\n".
           "Though the data file was read in, tkg2 was unable to properly match ".
           "the requested an $absORord '$var' with a column in the file.\n\n".
           "Willard Gibbons found this when his data started showing up with missing ".
           "data flagged as '--', but the -missingval key had '' (null).\n\n".
           "Thus, the data was converted to a string type.".
           " So tkg2 had loaded this instead '$verytemp:string'.";
}







sub _ordinates_as1_column {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($data, $abscissa, $ordinates, $thirdord, $fourthord, $type) =
      (shift,     shift,      shift,     shift,      shift, shift);
   my @abscissa_data  = @{ $data->{$abscissa}  };
   my @third_data     = @{ $data->{$thirdord}  } if( defined $thirdord   );
   my @fourth_data    = @{ $data->{$fourthord} } if( defined $fourthord  );
   my @newabs_data    = ();
   my @neword_data    = ();
   my @newthird_data  = ();
   my @newfourth_data = ();
   my @ordinates      = ();
   my $combined_ordinate_name;
   if($type eq 'onthefly') { # sub called from LoadDataOnTheFly
       # in this case $ordinates should be an array reference with only
       # one entry, which will be a 'COLAS1' delimited string
       return ($data, $ordinates) if( @$ordinates > 1 ); # just safely ignore
       @ordinates = split(/COLAS1/o, $ordinates->[0]);
       print $::BUG "COLAS1: ordinates in file should be @ordinates\n"; 
   }
   else {
      @ordinates = @$ordinates;
   }
   
   # finish up the transformation
   foreach my $key (@ordinates) {
      $combined_ordinate_name .= $key."COLAS1";
      push(@newabs_data, @abscissa_data);
      push(@neword_data, @{ $data->{$key} } );
      push(@newthird_data,  @third_data)  if( defined $thirdord   );
      push(@newfourth_data, @fourth_data) if( defined $fourthord  );
   }
   $combined_ordinate_name =~ s/COLAS1$//o;  # strip trailing COLAS1
   
   map { delete($data->{$_}) } @ordinates; # delete the read in columns
   
   $data->{$abscissa}               = [ @newabs_data ];  # load in duplicated data
   $data->{$combined_ordinate_name} = [ @neword_data ];  # load in new data set 
   $data->{$thirdord}               = [ @third_data  ] if( defined $thirdord   );  # load in duplicated data
   $data->{$fourthord}              = [ @fourth_data ] if( defined $fourthord  );  # load in duplicated data
   
   return ($data, [ ($combined_ordinate_name) ] );  
}



#########################################################################################

# _specialPlot_instructions
# SPECIAL INSTRUCTIONS SAY FOR BOX PLOTS OR STIFF DIAGRAMS ETC
# Like the instance with RouteData2Script_Actually_Perform
# we will magically change the $data behind the scenes
sub _specialPlot_instructions {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   my ( $data,
         $abscissa,
          $ordinates,
           $thirdord,
            $plotstyle,
             $special_instructions,
              $loading_data_on_the_fly,
               $missing_value_string ) = @_;
              
   $loading_data_on_the_fly = ($loading_data_on_the_fly eq 'onthefly') ? 1 : 0;

   my ($min,$max);
   
   my $combined_ordinate_name = undef;
   
   my $orientation = ( $loading_data_on_the_fly ) ? $special_instructions->{-orientation} :
                     ( $plotstyle =~ m/hor/oi    ) ? 'horizontal' : 'vertical';
   my $by_group = 0;
   $by_group = $special_instructions->{-data_by_group} if($loading_data_on_the_fly);
   
   if($plotstyle =~ m/box/oi) {
      if($plotstyle =~ m/group/oi or $by_group) {
         $by_group = 1;
         my $ordinate = shift(@$ordinates);
         my @bulkargs = ( $data, $abscissa, $ordinate, $orientation,
                          $special_instructions, $loading_data_on_the_fly,
                          $missing_value_string );
         ( $data,
            $abscissa,
             $ordinates,
              $thirdord,
               $min, $max )  = &__massage_grouped_box_data(@bulkargs);
      }
      else {
         my @bulkargs = ( $data, $ordinates, $thirdord, $orientation,
                          $special_instructions, $loading_data_on_the_fly,
                          $missing_value_string );
         ( $data,
            $abscissa,
             $ordinates,
              $thirdord,
               $combined_ordinate_name,
                $min, $max ) = &__massage_box_data(@bulkargs);
      }  
   }
   elsif($plotstyle =~ m/stiff/oi) {
      print STDERR "STIFF: Stiff plots are not yet implemented\n";
   }
 
   if($::TKG2_CONFIG{-DEBUG}) {
      print $::BUG "BOX: CHECKING MAGICALLY CHANGED DATA\n";
      foreach my $key (keys %$data) {
         print $::BUG "BOX: $key\n";
         if( ref $data->{$key}->[0] ) { 
            foreach ( @{ $data->{$key} } ) { $_->show() }
         }
      }
   }
  
  
  return ( $data,
            $abscissa,
             $ordinates,
              $thirdord,
               $combined_ordinate_name,
                $orientation, $min, $max, $by_group ); 
} 


sub __massage_grouped_box_data {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($data, $abscissa, $ordinate, $orientation,
       $special_instructions, $loading_on_the_fly,
       $missing_value_string) = @_;              
   my ($min, $max);
   
   my $instructions = ($loading_on_the_fly) ?
                       $special_instructions->{-special_instructions} :
                       $special_instructions                          ;
 
   my $dn_lim = $instructions->{-lower_detection_limit };
   my $dn_val = $instructions->{-lower_replace_value   };
   my $up_lim = $instructions->{-upper_detection_limit };
   my $up_val = $instructions->{-upper_replace_value   };
   my $moment_method = $instructions->{-moment_calc_method };
   my $trans  = $instructions->{-transformation        };
   
   my $thirdord     = 'BOXOBJECT:box';
   my $grouped_data = {};
   my $newdata      = {};
   # First need to push each group of data together
   my $nd  = $#{ $data->{$abscissa} };
   foreach my $i (0..$nd) {
      my $group = $data->{$abscissa}->[$i];
      my $value = $data->{$ordinate}->[$i];
      push(@{ $grouped_data->{ $group } }, $value );
   }
   
   # Second, build up the data with the grouped data    
   foreach my $group ( sort keys %$grouped_data ) {
      my @bulkargs = ( $grouped_data->{$group},
                       $dn_lim, $dn_val,
                       $up_lim, $up_val,
                       $moment_method, $trans,
                       $missing_value_string ); 
      my ($mean, $box) = &constructBoxPlotDataObject(@bulkargs);
      
      my ($mg1, $mg2) = ($orientation eq 'vertical') ? ($mean, $group) : ($group, $mean);
      push( @{ $newdata->{$abscissa} }, $mg2 );
      push( @{ $newdata->{$ordinate} }, $mg1 );
      push( @{ $newdata->{$thirdord} }, $box );
      
      # print STDERR "\nBOX: SUMMARY OF GROUP '$group'\n";
      # $box->show;
      # print STDERR "BOX:CA END OF GROUP '$group' SUMMARY\n\n";
      
      $min = $box->getStat(-min) unless(defined $min);
      $max = $box->getStat(-max) unless(defined $max);
      
      $min = $box->getStat(-min) if(defined $box->{-min} and
                                     $min > $box->{-min} );
      $max = $box->getStat(-max) if(defined $box->{-max} and
                                     $max < $box->{-max} );
   }
   
   # insure only one ordinate column is remembered 
   # my @coords = ($orientation ne 'vertical') ? ( $abscissa, [ $ordinate ] ) :
   #                                             ( $ordinate, [ $abscissa ] ) ;
   return ($newdata, $abscissa, [ $ordinate ], $thirdord, $min, $max);
}


sub __massage_box_data {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($data, $ordinates, $thirdord, $orientation,
       $special_instructions, $loading_data_on_the_fly,
       $missing_value_string) = @_;
   my ($min, $max);
   
   my $instructions = ($loading_data_on_the_fly) ?
                       $special_instructions->{-special_instructions} :
                       $special_instructions                          ;
  
   my $dn_lim = $instructions->{-lower_detection_limit };
   my $dn_val = $instructions->{-lower_replace_value   };
   my $up_lim = $instructions->{-upper_detection_limit };
   my $up_val = $instructions->{-upper_replace_value   };
   my $moment_method = $instructions->{-moment_calc_method};
   my $trans  = $instructions->{-transformation        };
        
   my $combined_ordinate_name = "";
      
   my $abscissa    =    ($orientation eq 'vertical') ?
                     'ABSCISSA:string' : 'ABSCISSA:number';
   my $newordinate =    ($orientation eq 'vertical') ?
                     'ORDINATE:number' : 'ORDINATE:string';
   $thirdord       = 'BOXOBJECT:box';
       
   my $newdata = {};
   
   my @ordinates;
   if($loading_data_on_the_fly) {
       # in this case $ordinates should be an array reference with only
       # one entry, which will be a 'COLAS1' delimited string
        @ordinates = split(/COLAS1/o, $ordinates->[0]);
       print $::BUG "BOX-COLAS1: ordinates in file should be @ordinates\n"; 
   }
   else {
      @ordinates = @$ordinates;
   }
   
   foreach my $ordinate (@ordinates) {
      next unless($ordinate =~ /:number/o);  # quietly ignore nonnumbers
      $combined_ordinate_name .= $ordinate."COLAS1";
      my @bulkargs = ( $data->{$ordinate},
                       $dn_lim, $dn_val,
                       $up_lim, $up_val,
                       $moment_method, $trans,
                       $missing_value_string ); 
      
      my ($mean, $box)      = &constructBoxPlotDataObject(@bulkargs);
      my ($variable, $type) = split(/:/o, $ordinate );
      
      my ($mg1, $mg2) = ($orientation eq 'vertical') ? ($mean, $variable): ($variable, $mean);
      push( @{ $newdata->{$abscissa}    }, $mg2 );
      push( @{ $newdata->{$newordinate} }, $mg1 );
      push( @{ $newdata->{$thirdord}    }, $box );
      
      $min = $box->getStat(-min) unless(defined $min);
      $max = $box->getStat(-max) unless(defined $max);
      
      $min = $box->getStat(-min) if( defined $box->{-min} and
                                      $min > $box->{-min} );
      $max = $box->getStat(-max) if( defined $box->{-max} and
                                      $max < $box->{-max} );
      
   } # END ORDINATE LOOP
   $combined_ordinate_name =~ s/COLAS1$//o;  # strip trailing COLAS1
   return ( $newdata, $abscissa, [ $newordinate ], $thirdord,
            $combined_ordinate_name,
            $min, $max );
}

1;
