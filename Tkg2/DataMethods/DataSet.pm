package Tkg2::DataMethods::DataSet;

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
# $Date: 2006/09/18 17:48:50 $
# $Revision: 1.49 $

use strict;
use Exporter;
use SelfLoader;

use vars qw(@ISA);
@ISA = qw(Exporter SelfLoader);

use Tkg2::DataMethods::Set::DataSetEditor  qw(DataSetEditor);
use Tkg2::DataMethods::Set::Statistics     qw(StatisticsEditor);
use Tkg2::DataMethods::Set::DrawDataEditor qw(DrawDataEditor);

use Tkg2::DataMethods::Set::DataLimits qw(setDataLimits);

use Tkg2::Plot::BoxPlot::BoxPlotStyle;

use Tkg2::Base qw(isNumber);

print $::SPLASH "=";


# configureDataLimits is used to provide a central method for revisioning
# the data limits from a single data set.  This method is called only from
# the tkg2.pl.  This method provides the resetting of datalimits during
# dynamic or runtime loading of data.
sub configureDataLimits {
   my ($self, $plot) = (shift, shift);
   my $deBUG = $::TKG2_CONFIG{-DEBUG};
   # preliminaries on the data
   my @DATA = @{ $self->{-DATA} }; # array of sub data arrays
   my $missingval = $self->{-file}->{-missingval};
   my $which_y_axis; # DOUBLE Y
   my $yax; # DOUBLE Y
 
   # really get to work
   foreach my $data (@DATA) {
      my @x;
      my @y;
      $which_y_axis = $data->{-attributes}->{-which_y_axis}; # DOUBLE Y
      $yax = ($which_y_axis == 2) ? '-y2' : '-y'; # DOUBLE Y
      foreach my $element ( @{ $data->{-data} } ) {
        my ($x, $y) = ( $element->[0], $element->[1] );
        # The test for $x eq "" and $y eq "" were added
        # for the 0.72-3 release because one read of the Comal
        # Springs data file was throwing a nmcp with "" on line 79
        # the sorting on Y.  I do not know why.
        push(@x, $x) unless(not defined $x     or
                            $x eq $missingval  or
                            $x eq 'missingval' or
                            $x eq "");
        push(@y, $y) unless(not defined $y     or
                            $y eq $missingval  or
                            $y eq 'missingval' or
                            $y eq "");
      }
      if(not $plot->{-x}->{-discrete}->{-doit}) {
         @x = sort { $a <=> $b } @x;
         &setDataLimits( $plot, '-x' , \@x , 0 );
      }
      if(not $plot->{$yax}->{-discrete}->{-doit}) {
         @y = sort { $a <=> $b } @y;
         &setDataLimits( $plot, $yax , \@y , 0 ); # DOUBLE Y
      }
   }
      
   if($deBUG) {
     print STDERR "%% DataSet::configureDataLimits for $self on $plot\n";
     my $xref = $plot->{-x};
     my $yref = $plot->{$yax};  # DOUBLE Y
     my $xmin = $xref->{-datamin};
     my $xmax = $xref->{-datamax};
     my $ymin = $yref->{-datamin};
     my $ymax = $yref->{-datamax};     
     
     print STDERR "%% X minimums\n";
     map { if( defined($xmin->{$_}) ) {
              print STDERR "%%   $_ => $xmin->{$_}\n";
           }
           else {
              print STDERR "%%   $_ => undef\n";
           }
         } keys %$xmin;
     print "%% X maximums\n";
     map { if( defined($xmax->{$_}) ) {
              print STDERR "%%   $_ => $xmax->{$_}\n";
           }
           else {
              print STDERR "%%   $_ => undef\n";
           }
         } keys %$xmax;
     print STDERR "%% Y$which_y_axis minimums\n"; # DOUBLE Y:
     map { if( defined($ymin->{$_}) ) {
              print STDERR "%%   $_ => $ymin->{$_}\n";
           }
           else {
              print STDERR "%%   $_ => undef\n";
           }
         } keys %$ymin;
     print STDERR "%% Y$which_y_axis maximums\n";  # DOUBLE Y:
     map { if( defined($ymax->{$_}) ) {
              print STDERR "%%   $_ => $ymax->{$_}\n";
           }
           else {
              print STDERR "%%   $_ => undef\n";
           }
         } keys %$ymax;   
   }
}


1;

__DATA__

# Create a new dataset object
sub new { 
# $DATASET = Tkg2::DataMethods->createDataSet('Flowdata');
   my ($pkg, $name) = (shift, shift);
   my $self = { -setname  => $name,
                -username => "",
                -show_in_explanation => 1 };
   bless($self, $pkg);
   $self->{-DATA} = [ ]; 
   $self->_datadefaults();  # set some defaults for the data set
   return $self;
}

# Default parameters for a dataset
sub _datadefaults {
   my $self = shift;
   my %hr = ( -fileisRDB        => 0,
              -dataimported     => 0,
              -userelativepath  => 1,
              -fullfilename     => '',
              -relativefilename => '',
              -megacommand      => 0,
              -common_datetime  => "",
              -numskiplines     => 0,
              -datetime_offset  => 0,
              -numlabellines    => 1, 
              -numskiplines_afterlabel => 0,
              -numlinestoread   => "",
              -skiplineonmatch  => '^#',
              -invertskipline   => 0,
              -missingval       => '',
              -filedelimiter    => '\s+',
              -sortdoit         => 0,
              -sorttype         => 'numeric',
              -sortdir          => 'ascend',
              -ordinates_as1_column => 0,
              -columntypes      => "auto",
              -thresholds       => 0,
              -transform_data   => { -doit   => 0,
                                     -script => "",
                                     -command_line_args   => "" } );
   $self->{-file} = { %hr };  
}

sub _default_lines {
   my $hash;
   $hash = { -doit       => 1,
             -stepit     => 0,
             -linewidth  => '0.01i',
             -linecolor  => 'black',
             -dashstyle  => undef,
             -arrow1     => 10,
             -arrow2     => 17,
             -arrow3     => 8,
             -arrow      => 'none' };
   return $hash;
}


sub _default_points {
   my $hash;
   $hash = { -doit          => 1,
             -blankit       => 0,
             -blankcolor    => 'white',
             -symbol        => 'Circle',
             -size          => '0.056i',
             -angle         => 0,
             -outlinewidth  => '0.010i',
             -fillcolor     => 'white',
             -fillstyle     => undef,
             -dashstyle     => undef,
             -outlinecolor  => 'black',
             -num2skip      => 0,
	     -rugx          => { -doit      => 0,
	                         -bothaxis  => 1,
				 -linewidth => '0.005i',
				 -linecolor => 'black',
				 -size      => '0.1i',
				 -negate    => 0 },
	     -rugy          => { -doit      => 0,
	                         -bothaxis  => 1,
				 -linewidth => '0.005i',
				 -linecolor => 'black',
				 -size      => '0.1i',
				 -negate    => 0 }
	     };
   return $hash;
}


sub _default_text {
   my $hash;
   $hash = { -doit       => 1,
             -yoffset    => '0.056i',
             -justify    => 'left',
             -anchor     => 'center',
             -xoffset    => '0.02i',
             -numcommify => 0,           
             -numformat  => 'free',           
             -numdecimal => 0,
             -leaderline => { -doit          => 0,
                              -blankit       => 0,
                              -shuffleit     => 0,
                              -flip_lines_with_shuffle => 1,
                              -overlap_correction_doit => 0,
                              -blankcolor    => 'white',
                              -width         => '0.005i',
                              -dashstyle     => undef,
                              -color         => 'black',
                              -beginoffset   => '0.1i',
                              -endoffset     => '0.1i',
                              -lines         =>
                                 [ { -length => '0.4i',
                                     -angle  => '225' },
                                   { -length => '0.25i',
                                     -angle  => '180'  }
                                 ]
                            },
             -font    => { -family     => "Helvetica",
                           -size       => 8,
                           -weight     => 'normal',
                           -slant      => 'roman',
                           -color      => 'black',
                           -rotation   => 0,
                           -stackit    => 0,
                           -blankit    => 0,
                           -blankcolor => 'white',
                           -custom1    => undef,
                           -custom2    => undef  } };
   return $hash; 
}

sub _default_yerrorbar {
   my $hash;
   $hash = { -whiskerwidth => '0.05i',
             -width        => '0.005i',
             -color        => 'black',
             -dashstyle    => undef };
   return $hash;
}

sub _default_xerrorbar {
   my $hash;
   $hash = { -whiskerwidth => '0.05i',
             -width        => '0.005i',
             -color        => 'black',
             -dashstyle    => undef };
   return $hash;
}

sub _default_shade {
   my $hash;
   $hash = { -doit           => 0,
             -shade2origin   => 0,
             -fillcolor      => 'black',
             -fillstyle      => undef,
             -shadedirection => 'below' };
   return $hash;
}


sub _default_bars {
   my $hash;
   $hash = { -doit         => 0,
             -outlinecolor => 'black',
             -outlinewidth => '0.01i',
             -barwidth     => '0.1i',
             -fillcolor    => 'grey50',
             -fillstyle    => undef,
             -dashstyle    => undef,
             -direction    => 'below' };
   return $hash;
}

sub convertUnitsToPixels {
   my $self = shift;
   
   my $_convertit =
      sub { return (&isNumber($_[0])) ? $_[0] : $::MW->fpixels($_[0]) };
   
   
   my $data = $self->{-DATA}; # ref to the array containing each set
   foreach my $subset (@$data) {
      my $attr = $subset->{-attributes};
      # POINTS
      $attr->{-points}->{-size} = &$_convertit($attr->{-points}->{-size});
      $attr->{-points}->{-rugx}->{-size} = &$_convertit($attr->{-points}->{-rugx}->{-size});
      $attr->{-points}->{-rugy}->{-size} = &$_convertit($attr->{-points}->{-rugy}->{-size});
 
      # TEXT
      my $tref = $attr->{-text};
      $tref->{-xoffset} = &$_convertit($tref->{-xoffset});
      $tref->{-yoffset} = &$_convertit($tref->{-yoffset});  
        # Text leader lines
      my $ldref = $tref->{-leaderline};
      $ldref->{-beginoffset} = &$_convertit($ldref->{-beginoffset});
      $ldref->{-endoffset}   = &$_convertit($ldref->{-endoffset}); 
      foreach my $ld_line ( @{$ldref->{-lines}} ) {
         $ld_line->{-length} = &$_convertit($ld_line->{-length});
      }
      
   }
}


sub add {
   # WORKING--I THINK THAT THAT SECOND ARGUMENT TO ADD SHOULD
   # BE THE SIZE OF THE CONTAINING DATACLASS
   my ($self, $data, $abscissa, $ordinate, $thirdord,
       $fourthord, $plotstyle, $which_y_axis,
       $special_plot_type, $orientation,
       $by_group, $special_instructions) = @_;
   my %para = ( -plotstyle    => $plotstyle,
                -lines        => &_default_lines(),
                -points       => &_default_points(),
                -text         => &_default_text(),
                -yerrorbar    => &_default_yerrorbar(),
                -xerrorbar    => &_default_xerrorbar(),
                -shade        => &_default_shade(),
                -bars         => &_default_bars(),
                -special_plot => undef,
                -which_y_axis => $which_y_axis,
              );
   
   STYLE: {
      $para{-lines}->{-doit}  = 0, last STYLE if($plotstyle eq 'Scatter');
      
      $para{-lines}->{-doit}  = 0, last STYLE if($plotstyle =~ m/Prob/o or                  
                                                 $plotstyle =~ /text/io);
                                                 
      $para{-points}->{-doit} = 0, last STYLE if($plotstyle eq 'X-Y Line');
      $para{-points}->{-doit} = 0, last STYLE
                                   if($plotstyle =~ /accumulation/io and
                                      $plotstyle !~ /shade between/io);
   
      if($plotstyle eq 'Shade') {
         $para{-points}->{-doit} = 0;
         $para{-shade}->{-doit}  = 1;
         $para{-lines}->{-doit}  = 1;
         last STYLE;
      }

      if($plotstyle eq 'Shade Between' or
         $plotstyle eq 'Shade Between Accumulation') {
         
         $para{-points}->{-doit} = 0;
         $para{-shade}->{-doit}  = 1;
         $para{-lines}->{-doit}  = 1;
         
         $para{-shade}->{-shadedirection} = 'shade between';
         
         last STYLE;
      }

      if($plotstyle eq 'Bar') {
         $para{-points}->{-doit} = 0;
         $para{-lines}->{-doit}  = 0;
         $para{-bars}->{-doit}   = 1;
         last STYLE;
      }
   }
   
   # in here would be the logical construction point for plots
   # such as piper diagrams or other.
   if($special_plot_type eq 'box') {
      $para{-points}->{-symbol} = 'Cross';
      my @args = ($orientation, $by_group, $special_instructions);
      $para{-special_plot} =
                    Tkg2::Plot::BoxPlot::BoxPlotStyle->new(@args);
   }
   
   my $arrayref = $self->{-DATA};
   &_configure_for_size_of_dataset(\%para, scalar(@$arrayref));       
                              
   push(@$arrayref, { -attributes    => { %para },
                      -origabscissa  => $abscissa,
                      -showabscissa  => $abscissa,
                      -origordinate  => $ordinate,
                      -showordinate  => "$ordinate"."_from_$self->{-file}->{-fullfilename}",
                      -origthirdord  => $thirdord,
                      -showthirdord  => $thirdord,
                      -origfourthord => $fourthord,
                      -showfourthord => $fourthord,
                      -show_in_explanation => 1,
                      -username      => "",
                      -data          => $data } );
   # -username is a hook for operation via an external instructions model
   # there is another -username on the parent dataset hash
   $self->{-DATA} = $arrayref;  # ok finally plug the data into its storage area
   $self->convertUnitsToPixels;
}



# _configure_for_size_of_dataset 
# This subroutine is used to dynamically alter the drawing styles for
# a given dataset.  It is currently limited to only configuring based
# on the size of a single dataset and knows nothing about the size
# of the containing data class.
sub _configure_for_size_of_dataset {
   my ($para, $size) = @_;
   
   # work on the point settings
   my $ptref = $para->{-points};
   if(0 < $size and $size <= 4) {
       # the result on zero is so that the default style is preserved
       $ptref->{-symbol} = ( $size == 0 ) ? $ptref->{-symbol} :
                           ( $size == 1 ) ? 'Square'   :
                           ( $size == 2 ) ? 'Triangle' :
                           ( $size == 3 ) ? 'Cross'    : 'Star';
   }
   elsif(5 < $size and $size <= 9) {
       $ptref->{-symbol} = ( $size == 5 ) ? $ptref->{-symbol} :
                           ( $size == 6 ) ? 'Square'   :
                           ( $size == 7 ) ? 'Triangle' :
                           ( $size == 8 ) ? 'Cross'    : 'Star'; 
      $ptref->{-fillcolor} = 'black'; 
   }
   else {
      # do nothing for now
   }
     
   # work on the line settings
   my @lnwidth = @{$::TKG2_CONFIG{-LINETHICKNESS}};
   my $lnref = $para->{-lines};
   if($size <= $#lnwidth) {
      # test for zero is so that the default style is preserved
      $lnref->{-linewidth} = $lnwidth[$size] unless($size == 0); 
   }
   
   # work on the bar and shade settings
   my @colors = @{$::TKG2_CONFIG{-COLORS}};
   $para->{-bars}->{-fillcolor}   = $colors[$size+1];
   $para->{-shades}->{-fillcolor} = $colors[$size+1];
   
   
   
}
####### END SUBROUTINE TO DYNAMICALLY ALTER THE DATASET DRAWING STYLES
  
# configDataSet_file provides a simple interface to revise the -file
# parameters by passing a list of options
sub configDataSet_file {
   my $self = shift;
   if( wantarray ) {
      return %{ $self->{-file} }
   }
   elsif(scalar(@_) == 1) {
      return $self->{-file}->{shift()};
   }
   elsif(@_) {
      my %para = @_;
      foreach (keys %para) {
         # recursion on -transform_data is needed as this holds
         # another hash reference, this was a bug fix for 0.51
         # only showed up when two or more plots were being created
         # from the command line
         # myg2 --mktemp=8.5x11 --mkplot=1.5x2x1x6 --mkplot=1.5x3x5.5x2
         # extremely subtle and minor bug that I discovered while
         # writing the tutorial in Instructions.pod.
         if($_ eq '-transform_data') {
            foreach my $trans (keys %{$para{$_}}) {
               $self->{-file}->{-transform_data}->{$trans} =
                  $para{-transform_data}->{$trans};
            }
         }
         else {
            $self->{-file}->{$_} = $para{$_};
         }
      }
   }
   return 0;
}






sub addjustdata {
#  $DATASET->addjustdata( [ @data ], $index )
   my ($self, $data, $index) = ( shift, shift, shift);
   $self->{-DATA}->[$index]->{-data} = $data;
}

sub clearjustdata {
# $DATASET->clearjustdata($index);
   my ($self, $index) = (shift, shift);
   my $olddata = $self->{-DATA}->[$index]->{-data};
   my @data = ();
   $self->{-DATA}->[$index]->{-data} = [ @data ];
   return \@$olddata;
}

sub dropone {
  # $DATASET->dropDatafromSet(2);
   my ($self, $index) = (shift, shift);
   my $arrayref = $self->{-DATA};
   return undef if($index > $#$arrayref or $index < 0);
   splice(@$arrayref, $index, 1);
   $self->{-DATA} = $arrayref;
}

sub editone {
   my ($self, $index, $canv, $template, $plot) = ( shift, shift, shift, shift, shift);
   my $datainset = $self->{-DATA};
   my $data = $datainset->[$index];
   $self->DrawDataEditor($data, $canv, $template, $plot);
}

sub changeone {
   my ($self, $index, $data) = (shift, shift, shift);
   my $arrayref = $self->{-DATA};
   return undef if($index > $#$arrayref or $index < 0);
   $self->{-DATA}->[$index]->{-data} = $data;
}

sub raise {
  # $DATASET->raiseDatainSet(2);
   my ($self, $index) = (shift, shift);
   my $arrayref = $self->{-DATA};
   return undef if($index > $#$arrayref or $index < 0);
   unshift(@$arrayref, splice(@$arrayref, $index, 1) );
   $self->{-DATA} = $arrayref;
}

sub lower {
  # $DATASET->lowerDatainSet(2);
   my ($self, $index) = (shift, shift);
   my $arrayref = $self->{-DATA};
   return undef if($index > $#$arrayref or $index < 0);
   push(@$arrayref, splice(@$arrayref, $index, 1) );
   $self->{-DATA} = $arrayref;
}

sub getone {
  # $data = $DATASET->getDatainSet(2);
   my ($self, $index) = (shift, shift);
   my ($arrayref, $hash) = ($self->{-DATA}, undef);   
   return undef if($index > $#$arrayref or $index < 0);
   $hash = $arrayref->[$index];
   return $hash->{-data};
}

sub getall {
  # $data = $DATASET->getDatainSet;
   my $self = shift;
   my ($arrayref, @data) = ( $self->{-DATA}, () ); 
   foreach my $data (@$arrayref) {  
     push(@data, $data->{-data});  
   }
   return @data;
}

sub dropall {
   my $self = shift;
   $self->{-DATA} = [ ];
}



1;

