package Tkg2::Draw::DrawLineStuff;

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
# $Date: 2007/09/11 02:19:19 $
# $Revision: 1.38 $

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter;
use Tkg2::Math::GraphTransform qw(transReal2CanvasGLOBALS
                                  transReal2CanvasGLOBALS_Xonly
                                  transReal2CanvasGLOBALS_Yonly 
                                  revAxis);
use Tkg2::Base qw(Message Show_Me_Internals);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createLineMetaPost
                                                createRectangleMetaPost
                                                createPolygonMetaPost);

@ISA = qw(Exporter);
@EXPORT = qw(drawBars drawLines drawOrigin);
@EXPORT_OK = qw(reallygenerateLines);

print $::SPLASH "=";

sub drawOrigin {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   &_reallydrawOrigin(@_,'-y');
   &_reallydrawOrigin(@_,'-y2');
}   

sub _reallydrawOrigin {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
      
   my ($self, $canv, $yax) = @_;
   return if($yax eq '-y2' and not $self->{$yax}->{-turned_on}); # DOUBLE Y
   
   my ($xorigin, $yorigin) = ( 0, 0);
   my $xref  = $self->{-x};
   my $yref  = $self->{$yax};
   my $xtype = $xref->{-type};
   my $ytype = $yref->{-type};
   $xorigin  = .50   if($xtype eq 'prob' or $xtype eq 'grv');
   $yorigin  = .50   if($ytype eq 'prob' or $ytype eq 'grv'); 
   $xorigin  = undef if($xtype eq 'log'  or $xref->{-discrete}->{-doit} );
   $yorigin  = undef if($ytype eq 'log'  or $yref->{-discrete}->{-doit} );
    
   if( defined $xorigin ) {
       $xorigin = undef unless(    $xorigin >= $xref->{-min}
                               and $xorigin <= $xref->{-max} );
   }
   if( defined $yorigin ) {
       $yorigin = undef unless(    $yorigin >= $yref->{-min}
                               and $yorigin <= $yref->{-max} );
   }

   my ($xmin, $ymin, $xmax, $ymax) = $self->getPlotLimits;
   my ($x, $y, @xdash, @ydash);
   $self->setGLOBALS($yax);
   if( defined $xorigin ) {
      $x = &transReal2CanvasGLOBALS($self,'X',$xtype, 0, $xorigin);
      $x = &revAxis($self,'-x',$x) if($xref->{-reverse});
      
      if($xref->{-origindoit}) {
          push(@xdash, (-dash => $xref->{-origindashstyle}) )
              if($xref->{-origindashstyle} and
                 $xref->{-origindashstyle} !~ /Solid/io);
          $canv->createLine($x,$ymin,  $x, $ymax,
                           -fill  => $xref->{-origincolor},
                           -width => $xref->{-originwidth},
                           @xdash,
                           -tags  => "$self".'origin');
          createLineMetaPost($x,$ymin,  $x, $ymax,
                             {-fill  => $xref->{-origincolor},
                              -width => $xref->{-originwidth},
                              @xdash});
      }
   } 
   if( defined $yorigin ) {
      $y = &transReal2CanvasGLOBALS($self,'Y',$ytype, 0, $yorigin);
      $y = &revAxis($self,'-y',$y) if($yref->{-reverse}); 
      push(@ydash, (-dash => $yref->{-origindashstyle}) )
              if($yref->{-origindashstyle} and
                 $yref->{-origindashstyle} !~ /Solid/io);
      if($yref->{-origindoit}) {
         $canv->createLine($xmin, $y, $xmax, $y,
                           -fill  => $yref->{-origincolor},
                           -width => $yref->{-originwidth},
                           @ydash,
                           -tags  => "$self".'origin');
         createLineMetaPost($xmin, $y, $xmax, $y,
                           {-fill  => $yref->{-origincolor},
                            -width => $yref->{-originwidth},
                            @ydash});
      }
   }
}


sub _drawtheshading { 
   my ($self, $canv, $dataset, $parsed_lines) = ( shift, shift, shift, shift);
   my %attr = %{$dataset->{-attributes}->{-shade}};
   return 0 unless($attr{-doit});
   my $dir   = $attr{-shadedirection};
   
   my $which_y_axis = ($dataset->{-attributes}
                               ->{-which_y_axis} == 1) ? '-y' : '-y2';
   my $xref = $self->{-x};
   my $yref = $self->{$which_y_axis};
   
   my $xtype = $xref->{-type};
   my $ytype = $yref->{-type};
   
   my $origin   = undef;
   my $can_shade_to_origin = 0;
   if( $attr{-shade2origin} and $ytype eq 'linear'
             and
       ( $dir eq 'below' or $dir eq 'above' ) ) {
      $can_shade_to_origin = 1;
      $origin = &transReal2CanvasGLOBALS($self,'Y',$ytype, 0, 0);
      $origin = &revAxis($self,$which_y_axis,$origin)
                   if($yref->{-reverse});
   }
   elsif( $attr{-shade2origin} and $xtype eq 'linear'
                and
          ( $dir eq 'left' or $dir eq 'right' ) ) {
      $can_shade_to_origin = 1;
      $origin = &transReal2CanvasGLOBALS($self,'X',$xtype, 0, 0);
      $origin = &revAxis($self,'-x',$origin)
                   if($xref->{-reverse});   
   }
   
   my $tag   = "$self"."$dataset"."shade";
   my ($xmin, $ymin, $xmax, $ymax) = $self->getPlotLimits;
   
   my ($rxmn, $rymn, $rxmx, $rymx) = $self->getRealPlotLimits($which_y_axis);
  
   if($dir =~ /between/io) {
      my @args = ( $dataset->{-data},
                   $self,
                   $dataset->{-attributes}->{-which_y_axis}
                 );
      my $parse_data1 = &_parseData(@args,1);
      my $parse_data2 = &_parseData(@args,2);
      
      if(@$parse_data1 != @$parse_data2) {
         warn "WARNING: The dual parsing of data for the between shading ",
              "could not work because the array lengths of valid data blocks ",
              "were not equal.  This is likely because one or more of the ",
	      "data points are less than or equal to zero and the axis is ",
	      "log.  Basically there is nothing logical for Tkg2 to do ",
	      "to help the user out--although one might consider tagging ",
	      "the zero values as missing or substitute a greater than ",
	      "zero lower limit to the data.\n";
         return;
      }
      
      my @all_data;
      for(my $i=0; $i<=$#$parse_data1; $i++) {
         my $all_data = $parse_data1->[$i];
         
         #my @tmp1 = ();         
         #foreach my $pair (@{$all_data}) {
         #   my @pair = @$pair;
         #   print "BUG1: @pair\n";
         #   $pair[1] = $rymn if($pair[1] < $rymn);
         #   $pair[1] = $rymx if($pair[1] < $rymx);
         #   $pair[0] = $rxmn if($pair[0] < $rxmn);
         #   $pair[0] = $rxmx if($pair[0] < $rxmx);
         #   print "BUG2: @pair\n";
         #   push(@tmp1, [ @pair ]);
         #}
         
         my @tmp2 = ();
         foreach my $pair (reverse @{$parse_data2->[$i]}) {
            my @pair = @$pair;
            ($pair[2], $pair[1]) = ($pair[1], $pair[2]);
            $pair[2] = $rymn if($pair[2] < $rymn);
            $pair[2] = $rymx if($pair[2] > $rymx);
            $pair[1] = $rymn if($pair[1] < $rymn);
            $pair[1] = $rymx if($pair[1] > $rymx);
            $pair[0] = $rxmn if($pair[0] < $rxmn);
            $pair[0] = $rxmx if($pair[0] > $rxmx);
            push(@tmp2, [ @pair ]);
         }
         push(@$all_data, @tmp2);
      }

      my $stepit = $dataset->{-attributes}->{-lines}->{-stepit};
      
      $parsed_lines =
        &reallygenerateLines($self, $parse_data1, $stepit, $which_y_axis, 1);
   }
   
   
     # The following loop is only iterated once if there are no
     # missing values and twice if there is a single missing value, etc.
     foreach my $lines (@$parsed_lines) {
      
        my @lines = @$lines;
        next unless(@lines);

        my ($n, $n_1) = ( $#lines, ($#lines-1));
        my ($val0, $val1, $valn_1, $valn) =
                   ($lines[0], $lines[1], $lines[$n_1], $lines[$n]);
      
        my @tmp;
        if($dir eq 'below') {
           if($can_shade_to_origin and defined $origin) {
              @tmp = ($valn_1, $origin, $val0, $origin);
           }
           else {
              @tmp = ($valn_1, $ymax, $val0, $ymax);
           }
        }
        elsif($dir eq 'above') {
           if($can_shade_to_origin and defined $origin) {
              @tmp = ($valn_1, $origin, $val0, $origin);
           }
           else {
              @tmp = ($valn_1, $ymin, $val0, $ymin);
           }
        }
        elsif($dir eq 'right') {
           if($can_shade_to_origin and defined $origin) {
              @tmp = ($origin, $valn, $origin, $val1);
           }
           else {
              @tmp = ($xmax, $valn, $xmax, $val1);
           }
        }
        elsif($dir eq 'left') {
           if($can_shade_to_origin and defined $origin) {
              @tmp = ($origin, $valn, $origin, $val1);
           }
           else {
              @tmp = ($xmin, $valn, $xmin, $val1);
           }
        }
        elsif($dir =~ /shade/o) {
           # September 10, 2007: I don't recall what this was going to
           # do. In this spot with the original tkg2 development. Now
           # I am on to MetaPost, so I write this note.
        }
        else {
           warn " _drawtheshading: Invalid direction\n";
           return;
        }
      
        push(@lines, (@tmp, $val0, $val1));
      
        if(scalar(@lines) < 6) {
           my @call = caller;
           my $mess = "Tkg2/Draw/DrawLineStuff/_drawtheshading is about ".
                      "to call createPoly with less than 6 coordinates. ".
                      "You as the user have probably zoomed to far into ".
                      "an area that tkg2 can not create a polygon.\n".
                      "Perhaps this behavior is ok, and this message is".
                      "overkill--in other words, is this a bug or not?\n".
                      "CALLER: @call\n";
           &Message($::MW,'-generic',$mess);
           return;
        }
        else {
           # The possibility still exists that @lines is greater than 6 but
           # has undefined values in it.  Let us check the first 6 entries.
           foreach my $i (0..5) { return if(not defined $lines[$i] ); }
           $canv->createPolygon(@lines, -fill    => $attr{-fillcolor},
                                        -outline => undef,
                                        -tags    => [$tag, 'shade']);
           createPolygonMetaPost(@lines, {-fill     => $attr{-fillcolor},
                                          -outline  => undef,
                                          -shadedir => $dir});
        }
     } # end of the foreach loop
   
   $canv->idletasks unless($::CMDLINEOPTS{'batch'});
}


sub drawBars {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $canv) = ( shift, shift);
   my $dataclass = $self->{-dataclass};
   my ($dataset, $data);
   foreach $dataset (@$dataclass) {
      foreach $data ( @{ $dataset->{-DATA} } ) {
         next unless($data->{-attributes}->{-bars}->{-doit});
         &_drawBars($self, $canv, $data);
      }
   }
}


sub _drawBars {
   my ($self, $canv, $dataset) = (shift, shift, shift);
   my $tag = "$self"."$dataset->{-data}"."bars";
   return 0 unless($dataset->{-attributes}->{-bars}->{-doit}); 

   my $which_y_axis = $dataset->{-attributes}->{-which_y_axis}; # DOUBLE Y
   my $yax = ($which_y_axis == 2) ? '-y2' : '-y'; # DOUBLE Y

   my $attr = $dataset->{-attributes}->{-bars};
   my %attr = ( -doit         => $attr->{-doit},
                -direction    => $attr->{-direction},
                -barwidth     => $attr->{-barwidth},
                -outlinecolor => $attr->{-outlinecolor},
                -outlinewidth => $attr->{-outlinewidth},
                -fillcolor    => $attr->{-fillcolor} ); 
   
   my $xref      = $self->{-x};
   my $yref      = $self->{$yax};
   my $xtype     = $xref->{-type};
   my $ytype     = $yref->{-type};
   my $revx      = $xref->{-reverse};
   my $revy      = $yref->{-reverse};  
   my $xdiscrete = $xref->{-discrete}->{-doit};
   my $ydiscrete = $yref->{-discrete}->{-doit};       
   
   
   my @limits = $self->getPlotLimits;
   $self->setGLOBALS($yax);
   foreach my $pair ( @{ $dataset->{-data} } ) {
   
      my @vals = @{$pair};
      my ($unloadx, $unloady) = ($vals[0], $vals[1]);
      my $x = ($xdiscrete and ref($unloadx) eq 'ARRAY') ? $unloadx->[0] : $unloadx;
      my $y = ($ydiscrete and ref($unloady) eq 'ARRAY') ? $unloady->[0] : $unloady;
      
      next if($x eq 'missingval' or $y eq 'missingval');
      $x = &transReal2CanvasGLOBALS_Xonly($self, $xtype, 1, $x);
      next if(not defined $x);
      $y = &transReal2CanvasGLOBALS_Yonly($self, $ytype, 1, $y);
      next if(not defined $y );
      $x = &revAxis($self,'-x',$x) if($revx);
      $y = &revAxis($self,'-y',$y) if($revy);
      &_drawabar($canv,$x,$y,$tag,\%attr,\@limits);
   }
   $canv->idletasks unless($::CMDLINEOPTS{'batch'});
}



sub _drawabar {
   my ($canv, $x, $y, $tag, $attr, $limits) = @_;
   my %attr = %{ $attr };
   return 0 unless($attr{-doit});
   my $dir      = $attr{-direction};
   my $barwidth = $canv->fpixels($attr{-barwidth});
   $barwidth /= 2;
   my ($xmin, $ymin, $xmax, $ymax) = @$limits;
   my (@ul, @lr);
   if($dir eq 'below' ) {
     ($ul[1], $lr[1]) = ( $y, $ymax); 
     $ul[0] = (($x-$barwidth) < $xmin) ? $xmin : ($x-$barwidth); 
     $lr[0] = (($x+$barwidth) > $xmax) ? $xmax : ($x+$barwidth);    
   }
   elsif($dir eq 'above') {
     ($ul[1], $lr[1]) = ( $ymin, $y);    
     $ul[0] = (($x-$barwidth) < $xmin) ? $xmin : ($x-$barwidth);
     $lr[0] = (($x+$barwidth) > $xmax) ? $xmax : ($x+$barwidth);
   }
   elsif($dir eq 'left') {
     ($ul[0], $lr[0]) = ( $xmin, $x); 
     $lr[1] = (($y-$barwidth) < $ymin) ? $ymin : ($y-$barwidth);
     $ul[1] = (($y+$barwidth) > $ymax) ? $ymax : ($y+$barwidth);
   }
   elsif($dir eq 'right') {
     ($ul[0], $lr[0]) = ( $x, $xmax);     
     $lr[1] = (($y-$barwidth) < $ymin) ? $ymin : ($y-$barwidth);
     $ul[1] = (($y+$barwidth) > $ymax) ? $ymax : ($y+$barwidth);
   }
   elsif($dir eq 'horz bar between') {
      warn " _drawthebars: horz bar between selected\n";
      return;
   }
   elsif($dir eq 'vert bar between') {
      warn " _drawthebars: vert bar between selected\n";
      return;
   }
   else {
      warn " _drawthebars: Invalid direction\n";
      return;
   }
   my $coord = [ (@ul, @lr) ];
   &_reallydrawabar($canv, $coord, -fill    => $attr{-fillcolor},
                                   -outline => $attr{-outlinecolor},
                                   -width   => $attr{-outlinewidth},
                                   -tags    => $tag);
}


sub _reallydrawabar {
   my ($canv, $coord) = ( shift, shift);
   $canv->createRectangle(@$coord, @_);
   createRectangleMetaPost(@$coord, {@_});
}


############### BEGINNING OF CORE LINE ALGORTHIMS #################################

# drawLines
# Is the interface to drawing lines for an entire Plot2D object
sub drawLines {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   # NO LINES IF EITHER AXIS IS DISCRETE!!
   my ($plot, $canv) = ( shift, shift);
   return if( (    $plot->{-x}->{-discrete}->{-doit}
               or  $plot->{-y}->{-discrete}->{-doit} )
                             and
              (    $plot->{-x}->{-discrete}->{-doit}
               or $plot->{-y2}->{-discrete}->{-doit} ) );
             
   my $dataclass = $plot->{-dataclass};
   my ($dataset, $data);
   foreach $dataset (@$dataclass) {
      foreach $data ( @{ $dataset->{-DATA} } ) {
         my $ref = $data->{-attributes}->{-lines};
         next unless($ref->{-doit});
	 
         # VERSION 1.01+ BACKWARDS COMPATABILITY
         $data->{-attributes}->{-lines}->{-arrow} = 'none'
                            if(not defined($ref->{-arrow}));
         $data->{-attributes}->{-lines}->{-arrow1} = 10
                            if(not defined($ref->{-arrow1}));
         $data->{-attributes}->{-lines}->{-arrow2} = 17
                            if(not defined($ref->{-arrow2}));
         $data->{-attributes}->{-lines}->{-arrow3} = 8
                            if(not defined($ref->{-arrow3}));
         # END BACKWARDS COMPATABILITY
	 
         # &_generateLines_with_DataSet is a wrapper on
         # &_parseData and a subsequent call on reallygeneratelines
         my $parsed_lines = &_generateLines_with_DataSet($plot, $data);
         next if( (not ref $parsed_lines and $parsed_lines == 1 ) 
                                   or
                      not @$parsed_lines );
         &_drawtheshading($plot, $canv, $data, $parsed_lines);
         &_drawthelines($plot, $canv, $data, $parsed_lines);
      }
   }
}

# _generateLines_with_DataSet
# called by drawLines
# returns a array containing arrays of arrays so that the issue of missing
# values can be properly dealt with.  The returned data structure is
# [ [ [ x1, y1 ], [ x2, y2 ] ],
#   [ [ a1, b1 ], [ a2, b2 ] ]
# ]
sub _generateLines_with_DataSet {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($plot, $dataset) = @_;
   return 0 unless($dataset->{-attributes}->{-lines}->{-doit});
   
   if(@{$dataset->{-data}} == 1) {
      $dataset->{-attributes}->{-points}->{-doit} = 1;
      return 1; # return 1 if the dataset has only one entry
      # which is not enough to plot a line
   }
   
   my $parse_data;
   my $which_y_axis = $dataset->{-attributes}->{-which_y_axis}; # DOUBLE Y
   
   if(not defined $dataset->{-parseData}) {
      # cache the parsed data -- DeleteLoadedData in Batch.pm deletes before
      # any saving of the tkg2 file
      my @args = ( $dataset->{-data},
                   $plot,
                   $which_y_axis
                 );
      $parse_data = &_parseData(@args);
      $dataset->{-parseData} = $parse_data;
   }
   else {
      $parse_data = $dataset->{-parseData};
   }
   
   my $yax = ($which_y_axis == 2) ? '-y2' : '-y'; # DOUBLE Y
   my $stepit = $dataset->{-attributes}->{-lines}->{-stepit};
   return &reallygenerateLines($plot, $parse_data, $stepit, $yax);
}


# _parseData
# called by _generateLines_with_DataSet
# The data for a plot is stored in an array of array pairs, plus some extra if
# the plot is a text plot or an error bar plot.  However, if there is missing
# data in the array, it is necessary to parse into blocks on lines that can be
# plotted by the lines.  Thus, the returned data looks like this:
# [ [ [x1,y1], [x2,y2] ],
#     [a1,b1], [a2,b2] ] ] etc.
sub _parseData {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
 
   my ($data, $plot, $which_y_axis, $data_column) = @_;
   $data_column ||= 1; # default to one, unless already defined
   
   my $xtype       = $plot->{-x}->{-type};
   my $x_logoffset = $plot->{-x}->{-logoffset};
   
   my $yax    = ($which_y_axis == 1) ? '-y' : '-y2';
   my $ytype  = $plot->{$yax}->{-type};
   my $y_logoffset = $plot->{$yax}->{-logoffset};
     
   my @parse_data = ();
   my @data       = @$data;
   my $n          = $#data;
   my $is_missing;
   my @temp_data = ();
   foreach my $pair (@data) {
      $is_missing = (   $pair->[0] eq 'missingval'
                     or $pair->[$data_column] eq 'missingval' ) ? 1 : 0;
      
      # Set to missing if the value of either x or y is inconsistent
      # with the axis type
      unless($is_missing) { # no need to work on further conditionals if missing
         # We apply the log offset on the values here to bi-pass the <= 0
         # condition.  We do not adjust the data at this point because
         # the Math::GraphTransform subroutines do this on the file.
         # Tkg2 stores the only the original data.
         $is_missing = 1 if( $xtype =~ m/log/io and
                             $pair->[0] - $x_logoffset <= 0 );
         $is_missing = 1 if( $ytype =~ m/log/io and
                             $pair->[$data_column] - $y_logoffset <= 0 );
      
         $is_missing = 1 if( $xtype =~ m/prob/io and
                           ($pair->[0] <= 0 or $pair->[0] >= 1) );
         $is_missing = 1 if( $ytype =~ m/prob/io and
                           ($pair->[$data_column] <= 0 or
                            $pair->[$data_column] >= 1) );
      }
      
      if(@temp_data and $is_missing) {
         push(@parse_data, [ @temp_data ]);
         @temp_data = ();
         next;
      }
      next if($is_missing);
      push(@temp_data, $pair); # print "BUG: ",@$pair,"\n";
   }
   push(@parse_data, [ @temp_data ]);
   
   return [ @parse_data ];
}


# _stepLines
# called by reallygenerateLines
# a reference to an array of 2 element arrays is passed in
# A forward look algorithms adds pseudo data points to form
# a stair-step.  The step length is equal to the x difference
# between the current point and the next point.  The last data
# point gets a step length equal to the previous length when
# _stepLines is called with stepit == 2
sub _stepLines {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($data, $stepit, $data_column) = @_;
   $data_column ||= 1; # default to one, unless already defined
   my @data    = @$data;
   
   my $n = $#data;
   return $data if(not @data or $n == 0); # only one data point, make no changes
   
   my @newdata = ();
     $#newdata = 2*($n); # preallocate the array as we know its size
   
   my $m = 0; # new total of points
   foreach my $i (0..($n-1)) { # loop until just before the last one
      $newdata[$m] = $data[$i];    # copy BOTH x and y, recall [x, y]
      $m++;
      $newdata[$m] = [ $data[$i+1]->[0], $data[$i]->[$data_column] ];
      $m++
   }
   $newdata[$m] = $data[$n]; # copy the last pair
   
   if($stepit == 2) {  # Last point
      $m++;
      my $xn1 = $data[$n-1]->[0];
      my ($xn2, $yn2) = ( $data[$n]->[0], $data[$n]->[$data_column] );
      $newdata[$m] = [ 2*$xn2-$xn1, $yn2 ] if(defined $xn1 and defined $xn2);
   }
   
   return [ @newdata ];
}





# reallygenerateLines
# called from QQLine.pm, ReferenceLines.pm, and _generateLines_with_DataSet this package
# This is an extremely complicated algorithm that basically performs ray tracing calculation
# to determine that pairs of points that need to be set aside for drawing lines on the
# canvas.
sub reallygenerateLines {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($self, $parse_data, $stepit, $yax, $data_column) = @_;
      $data_column ||= 1; # default to one, unless already defined
   
   my ($x1, $y1, $x2, $y2);
   
   my $xref  = $self->{-x};
   my $yref  = $self->{$yax};
   my $typex = $xref->{-type};
   my $typey = $yref->{-type};
   
   my ($px1, $px2, $py1, $py2);
   my ($xmin, $ymin, $xmax, $ymax) = $self->getPlotLimits;
   my $revx = $xref->{-reverse};
   my $revy = $yref->{-reverse};
   
   $self->setGLOBALS($yax);
   my @parsed_lines;
   foreach my $rawdata (@$parse_data) {
      # by essentially copying the original subdata to a new variable
      # we avoid the reference aliasing that foreach provides.  Basically,
      # if _stepLines returns orig_subdata to itself then the -parseData
      # cache is altered without us knowing it.  This used to be a serious
      # memory leak that WHA discovered by accident on 9/18/2000.  
      my $subdata = ($stepit) ? &_stepLines($rawdata,$stepit,$data_column)
                              : $rawdata;
   
      my @data = @$subdata;
      my $n    = scalar( @data );
      
      my @lines;
  
      # STARTING_POINT:
      my $i = 0;
      foreach $i (0..($n-1)) {
         $x1 = $data[$i]->[0];
         $y1 = $data[$i]->[$data_column];
         $x1 = &transReal2CanvasGLOBALS_Xonly($self,$typex, 0, $x1); 
         next if( not defined $x1 );
         $y1 = &transReal2CanvasGLOBALS_Yonly($self,$typey, 0, $y1);
         next if( not defined $y1 );
         $x1 = &revAxis($self,'-x',$x1) if($revx);
         $y1 = &revAxis($self,'-y',$y1) if($revy);
         last;
      }
      my $j = $i + 1;
   
      # LINES:
      while($j < $n) {
         $px1 = undef, next if( not defined $x1 or not defined $y1);
         $x2  = $data[$j]->[0];
         $y2  = $data[$j]->[$data_column];
         $x2  = &transReal2CanvasGLOBALS_Xonly($self,$typex, 0, $x2); 
         $px1 = undef, next if( not defined $x2 );
         $y2  = &transReal2CanvasGLOBALS_Yonly($self,$typey, 0, $y2);
         $px1 = undef, next if( not defined $y2 );
         
         $x2  = &revAxis($self,'-x',$x2) if($revx);
         $y2  = &revAxis($self,'-y',$y2) if($revy);
      
      # The following are bug catches, serious problems if these are tripped
      #print $::BUG "xmax is undefined\n" if(not defined $xmax );
      #print $::BUG "xmin is undefined\n" if(not defined $xmin );
      #print $::BUG "ymax is undefined\n" if(not defined $ymax );
      #print $::BUG "ymin is undefined\n" if(not defined $ymin );
      #print $::BUG "x1 is undefined\n"   if(not defined $x1   );
      #print $::BUG "x2 is undefined\n"   if(not defined $x2   );
      #print $::BUG "y1 is undefined\n"   if(not defined $y1   );
      #print $::BUG "y2 is undefined\n"   if(not defined $y2   );
     
         $px1 = undef, next if( ($x1 > $xmax and $x2 > $xmax) ||
                                ($x1 < $xmin and $x2 < $xmin) ||
                                ($y1 > $ymax and $y2 > $ymax) ||
                                ($y1 < $ymin and $y2 < $ymin) );
         # COORDINATES NOT INSIDE PLOT
         my $diff = ($x2-$x1); # Compute run once
         my $m = ($diff != 0) ? (($y2-$y1)/$diff) : 'inf';
      
         # DRAW IF VERTICAL
         if($m eq 'inf') {
            $px1 = $x1;
            $px2 = $x2;
            $py1 = $y1;
            $py2 = $y2;
            $py1 = $ymin if($py1 < $ymin);
            $py1 = $ymax if($py1 > $ymax);
            $py2 = $ymin if($py2 < $ymin);
            $py2 = $ymax if($py2 > $ymax);
            next;
         }
      
         # DRAW IF HORIZONTAL
         if($m == 0) {
            $px1 = $x1;
            $px2 = $x2;
            $py1 = $y1;
            $py2 = $y2;
            $px1 = $xmin if($px1 < $xmin);
            $px1 = $xmax if($px1 > $xmax);
            $px2 = $xmin if($px2 < $xmin);
            $px2 = $xmax if($px2 > $xmax);
            next;
         }
      
         my $b = $y1 - $m*$x1;   # Compute the intercept
      
         # BEGIN WORK ON POINT 1
         if($x1 < $xmin) {
            $px1 = $xmin;
            $py1 = $m*$px1+$b;
            if($py1 < $ymin) {
               $px1 = undef, next if($m < 0);
               $py1 = $ymin;
               $px1 = ($py1-$b)/$m;
               $px1 = undef, next if($px1 > $xmax);
            }
            elsif($py1 > $ymax) {
               $px1 = undef, next if($m > 0);
               $py1 = $ymax;
               $px1 = ($py1-$b)/$m;
               $px1 = undef, next if($px1 > $xmax);
            }
         }
         elsif($x1 > $xmax) {
            $px1 = $xmax;
            $py1 = $m*$px1+$b;
            if($py1 < $ymin) {
               $px1 = undef, next if($m < 0);
               $py1 = $ymin;
               $px1 = ($py1-$b)/$m;
               $px1 = undef, next if($px1 < $xmin);
            }
            elsif($py1 > $ymax) {
               $px1 = undef, next if($m > 0);
               $py1 = $ymin;
               $px1 = ($py1-$b)/$m;
               $px1 = undef, next if($px1 < $xmin); 
            }
         }
         else {
            if($y1 < $ymin) {
               $py1 = $ymin;
               $px1 = ($py1-$b)/$m;
               $px1 = undef, next if( ($px1 < $xmin) || ($px1 > $xmax) );
            }
            elsif($y1 > $ymax) {
               $py1 = $ymax;
               $px1 = ($py1-$b)/$m;
               $px1 = undef, next if( ($px1 < $xmin) || ($px1 > $xmax) );
            }
            else {
               $px1 = $x1;
               $py1 = $y1;
            } 
         } # END WORK ON POINT 1
      
         # BEGIN WORK ON POINT 2
         if($x2 < $xmin) {
            $px2 = $xmin;
            $py2 = $m*$px2+$b;
            if($py2 < $ymin) {
               $px2 = undef, next if($m < 0);
               $py2 = $ymin;
               $px2 = ($py2-$b)/$m;
               $px2 = undef, next if($px2 > $xmax);
            }
            elsif($py2 > $ymax) {
               $px2 = undef, next if($m > 0);
               $py2 = $ymax;
               $px2 = ($py2-$b)/$m;
               $px2 = undef, next if($px2 > $xmax);
            }
         }
         elsif($x2 > $xmax) {
            $px2 = $xmax;
            $py2 = $m*$px2+$b;
            if($py2 < $ymin) {
              $px2 = undef, next if($m > 0);
              $py2 = $ymin;
              $px2 = ($py2-$b)/$m;
              $px2 = undef, next if($px2 < $xmin);
            }
            elsif($py2 > $ymax) {
               $px2 = undef, next if($m < 0);
               $py2 = $ymin;
               $px2 = ($py2-$b)/$m;
               $px2 = undef, next if($px2 < $xmin);
            }
         }
         else {
            if($y2 < $ymin) {
               $py2 = $ymin;
               $px2 = ($py2-$b)/$m;
               $px2 = undef, next if( ($px2 < $xmin) || ($px2 > $xmax) );
            }
            elsif($y2 > $ymax) {
               $py2 = $ymax;
               $px2 = ($py2-$b)/$m;
               $px2 = undef, next if( ($px2 < $xmin) || ($px2 > $xmax) );
            }
            else {
               $px2 = $x2;
               $py2 = $y2;
            } 
         } # END WORK ON POINT 2
      }
      continue {
         push(@lines, ($px1, $py1, $px2, $py2))
                if(defined $px1 and defined $px2 );
         $j++;
         $x1 = $x2 if(defined $x2);
         $y1 = $y2 if(defined $y2);
         $px1 = $py1 = $px2 = $py2 = undef;
         # last statement is a debugging catch
      } 
   
      push(@parsed_lines, [ @lines ] );  # insert the next chuck of connected lines
   }
   return [ @parsed_lines ];   
}   



# _drawtinelines
# The actual subroutine that draws onto the canvas
sub _drawthelines {
   my ($self, $canv, $dataset, $parsed_lines) = ( shift, shift, shift, shift);
   my $tag = ["$self"."$dataset->{-data}"."lines", "connectedline"];
   my $ref = $dataset->{-attributes}->{-lines};
   my $linewidth = $ref->{-linewidth};
   my $linecolor = $ref->{-linecolor};
   my $dashstyle = $ref->{-dashstyle};
   
   my @args = (-width      => $linewidth,
               -fill       => $linecolor,
               -arrow      => $ref->{-arrow},
               -arrowshape => [ $ref->{-arrow1},
                                $ref->{-arrow2},
                                $ref->{-arrow3} ]);
   push(@args, (-dash => $dashstyle))
              if($dashstyle and $dashstyle !~ /Solid/io);
   foreach my $lines (@$parsed_lines) {
      my @lines = @$lines;
      next unless(@lines);
      $canv->createLine( @lines, @args, -tag   => $tag ); 
      createLineMetaPost(@lines, {@args});
      # draw each pending chunk of non-missing data
      $canv->idletasks unless($::CMDLINEOPTS{'batch'});
   }
   $canv->idletasks unless($::CMDLINEOPTS{'batch'});
}


##################### END OF LINE ALGORITHMS ################################
