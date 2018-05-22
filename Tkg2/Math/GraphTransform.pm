package Tkg2::Math::GraphTransform;

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
# $Date: 2010/11/09 21:23:14 $
# $Revision: 1.31 $

use strict;
use Tkg2::Base qw(log10 isInteger);
use vars qw(@ISA @EXPORT_OK);
            
use Exporter;
@ISA = qw(Exporter);

@EXPORT_OK = qw( setGLOBALS
                 transReal2CanvasGLOBALS
                 transReal2CanvasGLOBALS_Xonly
                 transReal2CanvasGLOBALS_Yonly
                 revAxis );

print $::SPLASH "=";

use constant logof10 => scalar log(10); 
sub mylog10 {
   my $n = shift;
   $_ = ($n <= 0) ? 'less than zero' : 'greater than zero';
   print $::MESSAGE "Tkg2::Math::GraphTransform::mylog10 $n is <= zero, logof10=".logof10."\n" if(/less/);
   ($n <= 0) ? undef : log($n)/logof10;
}

# setGlobals must be called in the same context and before transReal2CanvasGLOBALS
use vars qw($XMIN    $XMAX    $YMIN    $YMAX
            $logXMIN $logXMAX $logYMIN $logYMAX
            $zXMIN   $zXMAX   $zYMIN   $zYMAX
            $grvXMIN $grvXMAX $grvYMIN $grvYMAX
            $XLMAR   $YUMAR   $XPXL    $YPXL );

use constant EPS => scalar 10e-7; # an error threshold used for proper
                                  # range testing without worry about
                                  # round off
use constant ONE  => scalar 1;
use constant ZERO => scalar 0;

# The following constant is used for the the setGlobals subroutine
use constant S1PT05 => scalar 1.05;

# The following constants are used for faster probability handling
use constant SN1  => scalar  -1;
use constant S2   => scalar   2;
use constant SPT5 => scalar   0.5;
use constant S4   => scalar   4;
use constant S5   => scalar   5;
use constant S10  => scalar  10;
use constant S56  => scalar  56;
use constant S83  => scalar  83;
use constant S100 => scalar 100;
use constant S131 => scalar 131;
use constant S165 => scalar 165;
use constant S192 => scalar 192;
use constant S205 => scalar 205;
use constant S351 => scalar 351;
use constant S562 => scalar 562;
use constant S703 => scalar 703;

sub Perl5_8_BUG_Detective {
    my ($plot,$pkg,$filename,$line) = @_;
    my $xmin   = $plot->{-x}->{-min};
    my $ymin   = $plot->{-y}->{-min};
    my $y2min  = $plot->{-y2}->{-min};
    my $xmax   = $plot->{-x}->{-max};
    my $ymax   = $plot->{-y}->{-max};
    my $y2max  = $plot->{-y2}->{-max};
    my $xtype  = $plot->{-x}->{-type};
    my $ytype  = $plot->{-y}->{-type};
    my $y2type = $plot->{-y2}->{-type};
    print $::MESSAGE
          "$pkg  $filename  $line\n",
          "  xtype=$xtype | ytype=$ytype | y2type=$y2type |",
          " xmin=$xmin | xmax=$xmax | ymin=$ymin | ymax=$ymax |",
          " y2min=$y2min | y2max=$y2max\n";
}

sub setGLOBALS {
    my $plot = shift;
    #&Perl5_8_BUG_Detective($plot,caller); # comment out for more speed
    &reallySetGlobals($plot,@_);
}

sub reallySetGlobals {
    my $plot  = shift;
    # the whichy permits the user to either specify that the regular y-axis will be
    # used or that the second y-axis (-y2) will be used.  If no argument is given
    # then the regular y-axis is used by default.
    my $whichy = (@_) ? shift() : '-y';
    my $double_y = $plot->{-y2}->{-turned_on};  # DOUBLE Y, is it turned on
    $whichy = "-y" unless($whichy eq '-y2' and $double_y); # DOUBLE Y

    my $xref   = $plot->{-x};
    my $yref   = $plot->{$whichy};
    
    my $xtype  = $xref->{-type};
    my $ytype  = $yref->{-type};
    
    # In the event that the min and max are the same, then scale the max
    # 5 percent larger than the min just to avoid division by zero errors
    # deeper in the subroutines.  Thus, the if( ($XMAX - $XMIN) == ZERO )
    # or if( ($YMAX - $YMIN) == ZERO ) will trap it for us
    $XMIN = $xref->{-min};
    $XMAX = $xref->{-max};
    $XMAX = S1PT05*$XMIN if( ($XMAX - $XMIN) == ZERO );

    $YMIN = $yref->{-min};
    $YMAX = $yref->{-max};
    $YMAX = S1PT05*$YMIN if( ($YMAX - $YMIN) == ZERO );
    
    # to increase performance the following are cached
    # transformations of the limits to log space
    $logXMIN = log10($XMIN); # undef is returned by log10
    $logXMAX = log10($XMAX); # if the value is less than 
                                               # or equal to zero
    $logYMIN = log10($YMIN); # since the function has the test
    $logYMAX = log10($YMAX); # there is not reason to repeat here
  
    # Fail safe error trappings
    # very minor loss of speed for the increase in verbose
    # warning.  wha added this after beginning to really test out
    # the --inst.  Normally the internals of tkg2 should trap all 
    # problems with undefined limits, but --inst allows unchecked
    # manipulation of tkg2 settings.
    if(      ( $xtype eq 'log' or $xtype eq 'log10' )
                              and
        ( not defined $logXMIN or not defined $logXMAX ) ) {
       $logXMIN = 'undef' if( not defined $logXMIN );
       $logXMAX = 'undef' if( not defined $logXMAX ); 
       my $str1 = "Tkg2: SERIOUS WARNING--GraphTransform::setGLOBALS x-axis type is\n".
                  "      log but can not take a base10 logarithm of one of the\n".
                  "      limits: logXMIN = '$logXMIN' and logXMAX = '$logXMAX'\n";
       my $str2 = "Tkg2: Warning Followup--XMIN=$XMIN log10 of this does not exist?\n".
                  "                        XMAX=$XMAX log10 of this does not exist?\n";
       my ($tmp_min, $tmp_max) = (log($XMIN),log($XMAX));
       my $str3 = "Tkg2: Warning Followup--Natural log of min = $tmp_min, ".
                  "Natural log of max = $tmp_max\n";
           ($tmp_min) = ($XMIN <= 0) ? "$XMIN is less than zero?" : log($XMIN)/log(10);  
           ($tmp_max) = ($XMAX <= 0) ? "$XMAX is less than zero?" : log($XMAX)/log(10);
       my $str4 = "Tkg2: Warning Followup--Second logging: $tmp_min, $tmp_max\n";
           ($tmp_min) = &mylog10($XMIN);
           ($tmp_max) = &mylog10($XMAX);
       my $str5 = "Tkg2: Warning Followup--MyLog10 $tmp_min, $tmp_max\n";
       print STDERR $str1; print $::MESSAGE $str1; 
       print STDERR $str2; print $::MESSAGE $str2;
       print STDERR $str3; print $::MESSAGE $str3;
       print STDERR $str4; print $::MESSAGE $str4;
       print STDERR $str5; print $::MESSAGE $str5;
    }
    if(      ( $ytype eq 'log' or $ytype eq 'log10' )
                              and
        ( not defined $logYMIN or not defined $logYMAX ) ) {
       $logYMIN = 'undef' if( not defined $logYMIN );
       $logYMAX = 'undef' if( not defined $logYMAX ); 
       my $str1 = "Tkg2: SERIOUS WARNING--GraphTransform::setGLOBALS y-axis type is\n".
                  "      log but can not take a base10 logarithm of one of the\n".
                  "      limits: logYMIN = '$logYMIN' and logYMAX = '$logYMAX'\n";  
       my $str2 = "Tkg2: Warning Followup--YMIN=$YMIN log10 of this does not exist?\n".
                  "                        YMAX=$YMAX log10 of this does not exist?\n";
       my ($tmp_min, $tmp_max) = (log($YMIN),log($YMAX));
       my $str3 = "Tkg2: Warning Followup--Natural log of min = $tmp_min, ".
                  "Natural log of max = $tmp_max\n";
           ($tmp_min) = ($YMIN <= ZERO) ? "$YMIN is less than zero?" : log($YMIN)/log(10);  
           ($tmp_max) = ($YMAX <= ZERO) ? "$YMAX is less than zero?" : log($YMAX)/log(10);
       my $str4 = "Tkg2: Warning Followup--Second logging: $tmp_min, $tmp_max\n";
           ($tmp_min) = &mylog10($YMIN);
           ($tmp_max) = &mylog10($YMAX);
       my $str5 = "Tkg2: Warning Followup--MyLog10 $tmp_min, $tmp_max\n";
       print STDERR $str1; print $::MESSAGE $str1;
       print STDERR $str2; print $::MESSAGE $str2;
       print STDERR $str3; print $::MESSAGE $str3;
       print STDERR $str4; print $::MESSAGE $str4;
       print STDERR $str5; print $::MESSAGE $str5;
    }

    
    # to increase performance the following are cached
    # transformations of the limits to normal deviates
    $zXMIN   = ($XMIN > ZERO and $XMIN < ONE) ? Prob2StdZ($XMIN) : undef;
    $zYMIN   = ($YMIN > ZERO and $YMIN < ONE) ? Prob2StdZ($YMIN) : undef;
    $zXMAX   = ($XMAX > ZERO and $XMAX < ONE) ? Prob2StdZ($XMAX) : undef;
    $zYMAX   = ($YMAX > ZERO and $YMAX < ONE) ? Prob2StdZ($YMAX) : undef;
    if( $xtype eq 'prob' and ( not defined $zXMIN or
                               not defined $zXMAX ) ) {
       $zXMIN = 'undef'    if( not defined $zXMIN );
       $zXMAX = 'undef'    if( not defined $zXMAX ); 
       print STDERR
       "Tkg2: SERIOUS WARNING--GraphTransform::setGLOBALS x-axis type\n",
       "      is probability but can not compute StdZ of one of the\n",
       "      limits: zXMIN = '$zXMIN' and zXMAX = '$zXMAX'\n";  
    }
    if( $ytype eq 'prob' and ( not defined $zYMIN or
                               not defined $zYMAX ) ) {
       $zYMIN = 'undef'    if( not defined $zYMIN );
       $zYMAX = 'undef'    if( not defined $zYMAX ); 
       print STDERR
       "Tkg2: SERIOUS WARNING--GraphTransform::setGLOBALS y-axis type\n",
       "      is probability but can not compute StdZ of one of the\n",
       "      limits: zYMIN = '$zYMIN' and zYMAX = '$zYMAX'\n";  
    }
    
    
        
    # to increase performance the following are cached
    # transformations of the limits to gumble deviates       
    $grvXMIN = ($XMIN > ZERO and $XMIN < ONE) ? Prob2grv( $XMIN) : undef;
    $grvYMIN = ($YMIN > ZERO and $YMIN < ONE) ? Prob2grv( $YMIN) : undef;
    $grvXMAX = ($XMAX > ZERO and $XMAX < ONE) ? Prob2grv( $XMAX) : undef;
    $grvYMAX = ($YMAX > ZERO and $YMAX < ONE) ? Prob2grv( $YMAX) : undef;
    if( $xtype eq 'grv' and ( not defined $grvXMIN or
                              not defined $grvXMAX ) ) {
       $grvXMIN = 'undef' if( not defined $grvXMIN );
       $grvXMAX = 'undef' if( not defined $grvXMAX ); 
       print STDERR
       "Tkg2: SERIOUS WARNING--GraphTransform::setGLOBALS x-axis type\n",
       "      is probability but can not compute GRV of one of the\n",
       "      limits: grvXMIN = '$grvXMIN' and grvXMAX = '$grvXMAX'\n";  
    }
    if( $ytype eq 'grv' and ( not defined $grvYMIN or
                              not defined $grvYMAX ) ) {
       $grvYMIN = 'undef' if( not defined $grvYMIN );
       $grvYMAX = 'undef' if( not defined $grvYMAX ); 
       print STDERR
       "Tkg2: SERIOUS WARNING--GraphTransform::setGLOBALS y-axis type\n",
       "      is Gumbel but can not compute GRV of one of the\n",
       "      limits: grvYMIN = '$grvYMIN' and grvYMAX = '$grvYMAX'\n";  
    }

    $XLMAR = $plot->{-xlmargin};
    $YUMAR = $plot->{-yumargin};
    $XPXL  = $plot->{-xpixels};
    $YPXL  = $plot->{-ypixels};
}



sub revAxis {  # REVERSE COORDINATES BECAUSE AXIS IS REVERSED
   my ($self, $which, $v) = @_;
   if($which eq '-x') {
      my $xl = $self->{-xlmargin};
      my $xp = $self->{-xpixels};
      return ( ONE - ($v-$xl)/$xp )*$xp + $xl;
   }
   else {
      my $yu = $self->{-yumargin};
      my $yp = $self->{-ypixels};
      return ( ONE - ($v-$yu)/$yp )*$yp + $yu;
   }
}


sub transReal2CanvasGLOBALS {
   my ($self, $axis, $type, $islab_or_pt, $val) = @_;
   # my @call = caller(0);
   # $axis = which axis is involved
   # $self = XY Plot Object
   # $type = use method for a log (log10), prob (normal probability), or linear axis
   # $islab_or_pt = 1 for yes, 0 for no, returns undef if point outside plot
   # $val = the value in real world units to transform
   #my ($pkg, $filename, $line) = caller; # comment out to speed
   
   ($axis =~ m/x/oi) ?
      return &transReal2CanvasGLOBALS_Xonly($self,$type,$islab_or_pt,$val)
                     :
      return &transReal2CanvasGLOBALS_Yonly($self,$type,$islab_or_pt,$val);   
}

sub transReal2CanvasGLOBALS_Xonly {
   my ($self, $type, $islab_or_pt, $val) = @_;
   
   return undef unless(defined $val or $val ne ""); # Willard's special fix
      
   if($type =~ m/log/o ) {  # some prehandling of the offset is required before depatch to transforms
     my $offset = $self->{-x}->{-logoffset}; # extract the value of the offset from the object
     $offset = "$offset"; # IF THIS LINE IS UNCOMMENTED, BUGLESS BEHAVIOR ON PERL5.8.0 AND PERL5.8.1 IS SEEN
     $val   -=  $offset;  # apply the offset
     return undef if($val <= 0); # impossible log value
     # return undef if plotting labels and outside plot limits
     return undef if($islab_or_pt and ( $val < ($XMIN - EPS) or
                                        $val > ($XMAX + EPS)) );
     return Real2log2CanvX($val); # note above conditional repeated below
   }
   return undef if($islab_or_pt and ( $val < ($XMIN - EPS) or
                                      $val > ($XMAX + EPS)) );
   return Real2CanvX($val) if( $type eq 'time' or $type eq 'linear');
   # we already know that we have a prob or grv so we do not have to
   # test in the following conditional, but WHA wants to be able to
   # trap bad axis types just to be paranoid.
   return undef if( ($val <= 0 or $val >= 1 )
                               and 
             ( $type eq 'prob' or $type eq 'grv' ) );
   return Real2prob2CanvX($val) if( $type eq 'prob' );
   return Real2grv2CanvX($val)  if( $type eq 'grv'  );
   warn "transReal2Canvas--Was an X axis, but not log, log10, prob, grv, linear, time\n";
   return undef; 
}


sub transReal2CanvasGLOBALS_Yonly {
   my ($self, $type, $islab_or_pt, $val) = @_;
  
   return undef if(not defined $val or $val eq ""); # Willard's special fix

   if($type =~ m/log/o ) {  # some prehandling of the offset is required before depatch to transforms
     my $offset = $self->{-y}->{-logoffset}; # extract the value of the offset from the object
     # the offset is now just a constant
     $offset = "$offset"; # IF THIS LINE IS UNCOMMENTED, BUGLESS BEHAVIOR ON PERL5.8.0 AND PERL5.8.1 IS SEEN
     #my $special_extraction_for_perl_bug_folks = 0; # UNCOMMENT THIS THIS ALONG WITH PREVIOUS TO REVERT
#                                                     # TO FULLY OPERATIONAL TKG2 FOR THE USERS
#     my $special_extraction_for_perl_bug_folks  = 0;#($val eq "7.000") ? 1 : 0;
#     if($special_extraction_for_perl_bug_folks) {
#       print  "# OUTPUT DEMONSTRATING STRANGE BEHAVIOR OF NUMBERS IN PERL5.8.0 AND PERL5.8.1\n";
#       print  "# A value (\$val) is passed into the subroutine\n";
#       print  "# An offset (\$offset) is to be subtracted from the \$val\n";
#       print  "# \$offset is passed into the subroutine via an object \$self\n";
#       print  "# \$offset is extracted via 'my \$offset = \$self->{-y}->{-logoffset};'\n";
#       print  "(1) Binary of  1.70  is                       ",unpack("b*",1.70),"\n";
#       print  "(2) Binary of \"1.70\" is                       ",unpack("b*","1.70"),"\n";
#       print  "(3) Binary of \$offset within the object (\$self) is ",unpack("b*",$offset),"\n";
#       print  "(4) OFFSET to Binary and Back: ",pack("b32",unpack("b*",$offset)),"\n";
#       my $b_val    = unpack("b*",$val);
#       my $b_offset = unpack("b*",$offset);
#       print  "(5) BEFORE SUBTRACTION OR NEGATED ADDITION\n";
#       print  "(6) \$val = $val  \$offset = $offset  (both values appear ok)\n";
#       print  "(7) \$val (no. and binary):    $val       $b_val\n";
#       print  "(8) \$offset (no. and binary): $offset    $b_offset\n";
#       printf "(9) printf (as floats): \$val = %f  \$offset = %f\n", $val, $offset;
#       print  "(10) Setting \$newval = \$val\n";
#       print  "(11) Subtracting $offset from $val via \$val-=\$offset\n";
#       print  "(12) Subtracting $offset from $val via \$yaval1-=\"\$offset\" (notice double quotes)\n";
#       print  "(13) Adding -1.000000000000000*\$offset to \$val to get \$yaval2 (yet another value 2)\n";
#       print  "(14) Adding -1.000000000000001*\$offset to \$val to get \$yaval3 (yet another value 3)\n";
#     }
#     if(&isInteger($val)) {
       #print "BUG: Value $val is an integer\n";
#     }
#     else {
       #print "BUG: Value $val is not an integer\n";
#     }
#     if(&isInteger($offset)) {
       #print "BUG: Offset $offset is an integer\n";
#     }
#     else {
       #print "BUG: Offset $offset is not an integer\n";
#     }
#     my $oldval = $val;
#     my $yaval1 = $val;
#     my $yaval2 = $val;
#     my $yaval3 = $val;
     $val      -= $offset;   # apply the offset
#     $yaval1   -= "$offset"; # THIS CREATES THE PROPER $VAL - $OFFSET VALUE EVERY TIME!!!!
#     $yaval2 += -1.000000000000000*$offset;  # experiment
#     $yaval3 += -1.000000000000001*$offset;  # experiment
#     if($val != $yaval1) {
#       print "ERROR: \$val=\$yaval1=",$oldval," and \$offset=",$offset,"   ",
#             "\$val-=\$offset ->  $val  \$yaval1-=\"\$offset\" -> $yaval1 !!\n";
#     }
#     if($special_extraction_for_perl_bug_folks) {
#       print  "(15) AFTER SUBTRACTION OR NEGATED ADDITION\n";
#       printf "(16) printf (as floats): \$val = %f  \$offset = %f\n", $val, $offset;
#       printf "(17) printf (as floats): \$yaval1 = %f\n", $yaval1;
#       printf "(18) printf (as floats): \$yaval2 = %f\n", $yaval2;
#       printf "(19) printf (as floats): \$yaval3 = %f\n", $yaval3;
#       my $b_val    = unpack("b*",$val);
#       my $b_offset = unpack("b*",$offset);
#       my $b_yaval1 = unpack("b*",$yaval1);
#       my $b_yaval2 = unpack("b*",$yaval2);
#       my $b_yaval3 = unpack("b*",$yaval3);
#       print "(20) \$val - \$offset = $val  Offset = $offset\n";
#       print "(21) \$offset (no. and binary): $offset   $b_offset\n";
#       print "(22) \$val (no. and binary):    $val   $b_val\n";
#       print "(23) \$yaval1 (no. and binary): $yaval1   $b_yaval1\n";
#       print "(24) \$yaval2 (no. and binary): $yaval2   $b_yaval2\n";
#       print "(25) \$yaval3 (no. and binary): $yaval3   $b_yaval3\n";
#       print "# Note that all vals should be the same\n";
#       print "------------------------------\n";
#     }
     return undef if($val <= 0); # impossible log value
     # return undef if plotting labels and outside plot limits
     return undef if($islab_or_pt and ( $val < ($YMIN - EPS) or
                                        $val > ($YMAX + EPS) ) );
     return Real2log2CanvY($val); # note above conditional repeated below
   }
   # return undef if plotting labels and outside plot limits
   return undef if($islab_or_pt and ( $val < ($YMIN - EPS) or
                                      $val > ($YMAX + EPS) ) );
                                      
   return Real2CanvY($val) if( $type eq 'linear' or $type eq 'time' );
   # we already know that we have a prob or grv so we do not have to
   # test in the following conditional, but WHA wants to be able to
   # trap bad axis types just to be paranoid.
   return undef if( ($val <= 0 or $val >= 1 )
                              and
             ( $type eq 'prob' or $type eq 'grv' ) );
   return Real2prob2CanvY($val) if( $type eq 'prob' );
   return Real2grv2CanvY($val)  if( $type eq 'grv'  );
   warn "transReal2Canvas--Was a Y axis, but not log, log10, prob, grv, linear, time\n";
   return undef;      
}

                 
# GENERIC TRANSFORMS PLOT TO CANVAS AND CANVAS TO PLOT
sub Plot2Canv  { return Plot2CanvX($_[0]), Plot2CanvY($_[1]); }
sub Plot2CanvX { return ( ($_[0]) + $XLMAR ); }
sub Plot2CanvY { return ( $YPXL + $YUMAR - ($_[0]) ); }

sub Canv2Plot  { return Canv2PlotX($_[0]), Canv2PlotY($_[1]); }
sub Canv2PlotX { return ($_[0]) - $XLMAR; }
sub Canv2PlotY { return $YPXL + $YUMAR - ($_[0]); } 


# LINEAR METHODS
sub Plot2Real  { return Plot2RealX($_[0]), Plot2RealY($_[1]); }
sub Plot2RealX { return $XMIN + ( ($_[0])/$XPXL ) * ($XMAX - $XMIN); }
sub Plot2RealY { return $YMIN + ( ($_[0])/$YPXL ) * ($YMAX - $YMIN); }

sub Real2Plot  { return Real2PlotX($_[0]), Real2PlotY($_[1]); }
sub Real2PlotX { return ( ( ($_[0])-$XMIN ) / ( $XMAX-$XMIN) ) * $XPXL; }
sub Real2PlotY { return ( ( ($_[0])-$YMIN ) / ( $YMAX-$YMIN) ) * $YPXL; }

sub Real2Canv  { return Plot2Canv(  Real2Plot($_[0],$_[1]) ); }
sub Real2CanvX { return Plot2CanvX( Real2PlotX($_[0]) );      }
sub Real2CanvY { return Plot2CanvY( Real2PlotY($_[0]) );      }

sub Canv2Real  { return Plot2Real(  Canv2Plot($_[0],$_[1]) ); }
sub Canv2RealX { return Plot2RealX( Canv2PlotX($_[0]) ); }
sub Canv2RealY { return Plot2RealY( Canv2PlotY($_[0]) ); }



# LOG10 METHODS
sub logPlot2Real  { return logPlot2RealX($_[0]), logPlot2RealY($_[1]); }
sub logPlot2RealX { return S10**($logXMIN+($_[0]/$XPXL)*($logXMAX-$logXMIN));}
sub logPlot2RealY { return S10**($logYMIN+($_[0]/$YPXL)*($logYMAX-$logYMIN));}


sub Real2logPlot  { return Real2logPlotX($_[0]), Real2logPlotY($_[1]); }
sub Real2logPlotX { return ((log10($_[0])-$logXMIN)/($logXMAX-$logXMIN))*$XPXL;}
sub Real2logPlotY { return ((log10($_[0])-$logYMIN)/($logYMAX-$logYMIN))*$YPXL;}

sub Real2log2Canv  { return Plot2Canv( Real2logPlot($_[0],$_[1]) ); }
sub Real2log2CanvX { return Plot2CanvX( Real2logPlotX($_[0]) );     }
sub Real2log2CanvY { return Plot2CanvY( Real2logPlotY($_[0]) );     }

sub Canv2log2Real  { return logPlot2Real( Canv2Plot($_[0],$_[1]) ); }
sub Canv2log2RealX { return logPlot2RealX( Canv2PlotX($_[0]) );     }
sub Canv2log2RealY { return logPlot2RealY( Canv2PlotY($_[0]) );     }


# PROBABILITY SCALE METHODS
sub probPlot2Real { return probPlot2RealX($_[0]), probPlot2RealY($_[1]); }
sub probPlot2RealX {
    return StdZ2Prob( $zXMIN + ( $_[0] / $XPXL ) *
                    ( $zXMAX - $zXMIN ) ); }
sub probPlot2RealY { 
    return StdZ2Prob( $zYMIN + ( $_[0] / $YPXL ) *
                    ( $zYMAX - $zYMIN ) ); }


sub Real2probPlot { return Real2probPlotX($_[0]), Real2probPlotY($_[1]); }
sub Real2probPlotX {
    return ( ( Prob2StdZ($_[0]) - $zXMIN ) /
             ( $zXMAX - $zXMIN ) )*$XPXL; }
sub Real2probPlotY {
    return ( ( Prob2StdZ($_[0]) - $zYMIN ) /
             ( $zYMAX - $zYMIN ) )*$YPXL; }

sub Real2prob2Canv  { return Plot2Canv(  Real2probPlot($_[0],$_[1]) ); }
sub Real2prob2CanvX { return Plot2CanvX( Real2probPlotX($_[0]) ); }
sub Real2prob2CanvY { return Plot2CanvY( Real2probPlotY($_[0]) ); }

sub Canv2prob2Real  { return probPlot2Real(  Canv2Plot($_[0],$_[1]) ); }
sub Canv2prob2RealX { return probPlot2RealX( Canv2PlotX($_[0]) ); }
sub Canv2prob2RealY { return probPlot2RealY( Canv2PlotY($_[0]) ); }


sub Prob2StdZ {
   # from Derenzo, S.E., Approximations for hand calculators using small
   # integer coefficients, Math. Computation, 31(137), pp. 214-225, 1977.
   my $F = $_[0];
   return undef if ($F < EPS or $F > (ONE - EPS) );
   # Limits of approximation
      
   my $y = ($F <= SPT5) ? -log(S2*$F) : -log( S2*(ONE-$F) );
   # NOTE log NOT log10
   
   my $top = ($y**S2) * ( (S4*$y+S100) * $y + S205 );
   my $bot = ( (S2*$y+S56) * $y + S192 )* $y + S131;
   my   $Z = SN1*sqrt($top/$bot);
   return ($F <= SPT5) ? $Z : -$Z;
}


sub StdZ2Prob {
   # from Derenzo, S.E., Approximations for hand calculators using small
   # integer coefficients, Math. Computation, 31(137), pp. 214-225, 1977.
   my $Z = $_[0];
   return undef if(abs($Z) > S5);
   return   SPT5 if($Z == ZERO);
   my $absZ = abs($Z);
   my $top  = (S83*$absZ+S351) * $absZ + S562;
   my $bot  = (S703/$absZ) + S165;
   my $F    = ONE - SPT5*exp(-( $top/$bot ) );
   return ($Z > ZERO) ? $F : ONE-$F;
}


# GUMBEL PROBABILITY SCALE METHODS
sub grvPlot2Real { return grvPlot2RealX($_[0]), grvPlot2RealY($_[1]); }
sub grvPlot2RealX {
    return grv2Prob( $grvXMIN + ( $_[0]/$XPXL ) *
                   ( $grvXMAX - $grvXMIN ) ); }
sub grvPlot2RealY {
    return grv2Prob( $grvYMIN + ( $_[0]/$YPXL ) *
                   ( $grvYMAX - $grvYMIN ) ); }

sub Real2grvPlot { return Real2grvPlotX($_[0]), Real2grvPlotY($_[1]); }
sub Real2grvPlotX {
    return ( ( Prob2grv($_[0]) - $grvXMIN ) / 
             ( $grvXMAX - $grvXMIN ) )*$XPXL; }
sub Real2grvPlotY {
    return ( ( Prob2grv($_[0]) - $grvYMIN ) /
             ( $grvYMAX - $grvYMIN ) )*$YPXL; }

sub Real2grv2Canv  { return Plot2Canv(  Real2grvPlot($_[0],$_[1]) ); }
sub Real2grv2CanvX { return Plot2CanvX( Real2grvPlotX($_[0]) );      }
sub Real2grv2CanvY { return Plot2CanvY( Real2grvPlotY($_[0]) );      }

sub Canv2grv2Real  { return grvPlot2Real( Canv2Plot($_[0],$_[1]) );  }
sub Canv2grv2RealX { return grvPlot2RealX( Canv2PlotX($_[0]) );      }
sub Canv2grv2RealY { return grvPlot2RealY( Canv2PlotY($_[0]) );      }

# Gumbel Reduced Variate to Cumulative Probability
sub grv2Prob { return ($_[0] <= ZERO) ? undef : exp(SN1*exp(SN1*$_[0])); }

# Cumulative Probability to Gumbel Reduced Variate
sub Prob2grv { return SN1*log(SN1*log($_[0])); }

1;

__END__
# PORTABLE METHOD TO GET CANVAS, PLOT, AND REAL WORLD UNITS
sub displayCoords {
   my ($plot, $canv, $typex, $typey, $yax) = @_;
   $plot->setGLOBALS($yax);
   my $e = $canv->XEvent;
   my ($canvx, $canvy) = ($e->x, $e->y); 
   my ($plotx, $ploty) = ( Canv2Plot($canvx, $canvy) );
   my ($x, $y);
   
   if($typex eq 'linear' or
      $typex eq 'time') { $x = Plot2RealX($plotx); }
    elsif($typex eq 'log' or
          $typex eq 'log10') { $x = logPlot2RealX($plotx); }
     elsif($typex eq 'prob') { $x = probPlot2RealX($plotx); }
      elsif($typex eq 'grv')  { $x = grvPlot2RealX($plotx); }
       else { warn "Bad type in displayCoords\n"; }
    
   if($typey eq 'linear' or
      $typey eq 'time') { $y = Plot2RealY($ploty); }
    elsif($typey eq 'log' or
          $typey eq 'log10') { $y = logPlot2RealY($ploty); }
     elsif($typey eq 'prob') { $y = probPlot2RealY($ploty); }
      elsif($typey eq 'grv')  { $y = grvPlot2RealY($ploty); }
       else { warn "Bad type in displayCoords\n"; }
   
   if ($x < $plot->{-xmin} or $x > $plot->{-xmax} or
       $y < $plot->{-ymin} or $y > $plot->{-ymax} ) {
      ($x, $y) = ('outside', 'outside'); }
   else {   
      ($x, $y) = (sprintf("%0.3g", $x),sprintf("%0.3g", $y)); }
   
   return ($canvx, $canvy, $plotx, $ploty, $x, $y);   
}


1;
