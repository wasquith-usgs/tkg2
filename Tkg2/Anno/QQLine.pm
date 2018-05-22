package Tkg2::Anno::QQLine;

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
# $Date: 2007/09/10 02:19:40 $
# $Revision: 1.16 $

use strict;
use Tk;
use Exporter;
use SelfLoader;
use vars qw(@ISA $EDITOR);
@ISA = qw(Exporter SelfLoader);

$EDITOR = "";

# Recall that the reallygenerateLines subroutine performs the
# ray tracing calculations to derive the coordinates necessary to
# plot the line within a rectangular plot.
use Tkg2::Draw::DrawLineStuff qw(reallygenerateLines);

use Tkg2::Base qw(Show_Me_Internals Message);

use Tkg2::DeskTop::Rendering::RenderMetaPost qw(createAnnoLineMetaPost);

print $::SPLASH "=";

# QQLine is a totally self contained object-oriented interface to
# drawing one or two quantile-quantile lines on a given plot.

# Provides the object constructor and initial settings
sub new {
   my ($pkg, $name) = (shift, shift);
   my %a_line = ( -doit      => 0,
                  -linewidth => '0.015i',
                  -linecolor => 'black',
                  -dashstyle => undef );
   my $self = { -one2one    => { -y  => { %a_line },
                                 -y2 => { %a_line }
                               },
                -negone2one => { -y  => { %a_line },
                                 -y2 => { %a_line }
                               }
              };  # DOUBLE Y
   return bless $self, $pkg;
}


# draw
# just a dumb wrapper on _reallydraw so that both y-axis
# will be considered
sub draw {  # DOUBLE Y:
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   &_reallydraw(@_,'-y');
   &_reallydraw(@_,'-y2'); # DOUBLE Y
}

# _reallydraw
# draws the quantile quantile lines on the canvas
# provides a wrapper on reallygenerateLines and performs
# line style configuration.
sub _reallydraw {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($self, $canv, $plot, $yax) = @_; 
   
   return if($yax eq '-y2' and not $plot->{-y2}->{-turned_on});
   
   # retrieve the limits of the selected plot
   my ($xmin, $ymin, $xmax, $ymax) = $plot->getRealPlotLimits($yax);
   
   my $xref  = $plot->{-x};
   my $yref  = $plot->{$yax}; # DOUBLE Y
   
   my $xtype = $xref->{-type};
   my $ytype = $yref->{-type};

   # Is a one to one (up to the right) desired?
   my $qref = $self->{-one2one}->{$yax};
   if( $qref->{-doit} ) { # DOUBLE Y
      ($ymin, $ymax)   = ( $xmin, $xmax);  # to make a one to one line
      my $coords       = [ [$xmin, $ymin], [$xmax, $ymax] ];
      my $parsed_lines = &reallygenerateLines($plot, [ $coords ], 0, $yax );
      my @lines        = @{ $parsed_lines->[0] };  # there should ONLY be one array
      return unless(@lines == 4); # can not draw a line with other than 4 points
      
      $canv->createLine(@lines,
                        -fill  => $qref->{-linecolor},
                        -width => $qref->{-linewidth},
                        -tags  => "$plot");
      createAnnoLineMetaPost(@lines,{-fill  => $qref->{-linecolor},
                                     -width => $qref->{-linewidth},
                                     -linecap => "butt"});
   } 
   
   # Is a - one to one line (down to the right) desired?
   $qref = $self->{-negone2one}->{$yax};
   if( $qref->{-doit} ) { # DOUBLE Y
      ($ymax, $ymin)   = ( $xmin, $xmax);  # to make a one to one line
      my $coords       = [ [$xmin, $ymin], [$xmax, $ymax] ];
      my $parsed_lines = &reallygenerateLines($plot, [ $coords ], 0, $yax );
      my @lines        = @{ $parsed_lines->[0] };  # there should ONLY be one array
      return unless(@lines == 4); # can not draw a line with other than 4 points
      
      $canv->createLine(@lines,
                        -fill  => $qref->{-linecolor},
                        -width => $qref->{-linewidth},
                        -tags  => "$plot");
      createAnnoLineMetaPost(@lines,{-fill  => $qref->{-linecolor},
                                     -width => $qref->{-linewidth},
                                     -linecap => "butt"});
   }          
}

1;


__DATA__


# QQLineEditor
# The dialog that edits the quantile-quantile line configuration
# parameters.
sub QQLineEditor {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});

   my ($self, $plot, $canv, $template, $yax) = @_; 
   my $pw = $canv->parent;
  
   if($yax eq '-y2' and not $plot->{-y2}->{-turned_on}) {
      my $mess = "Warning: You are trying to edit quantile-".
                 "quantile lines for the second y axis, but ".
                 "that axis has not been activated by ".
                 "adding data to it.  Returning home.";
      &Message($pw, '-generic', $mess);
      return;
   }
   
   my $pref  = $self->{-one2one}->{$yax};
   my $nref  = $self->{-negone2one}->{$yax};
  
   my $font  = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
   my $fontb = $::TKG2_CONFIG{-DIALOG_FONTS}->{-largeB};
  
   my ($mb_UPcolor, $mb_UPwidth);
   my ($mb_DNcolor, $mb_DNwidth);
      
   my $pickedUPcolor   = $pref->{-linecolor};
   my $pickedUPcolorbg = $pickedUPcolor;
      $pickedUPcolor   = 'none'  if(not defined($pickedUPcolor)   );
      $pickedUPcolorbg = 'white' if(not defined($pickedUPcolorbg) );
      $pickedUPcolorbg = 'white' if( $pickedUPcolor eq 'black'    );

   my $_UPcolor = sub { $pickedUPcolor = shift;
                        my $color      = $pickedUPcolor;
                        my $mbcolor    = $pickedUPcolor;
                        $color         =  undef  if(   $color   eq 'none' );
                        $mbcolor       = 'white' if(   $mbcolor eq 'none'
                                                    or $mbcolor eq 'black');
                        $pref->{-linecolor} = $color;
                        $mb_UPcolor->configure(-background       => $mbcolor,
                                               -activebackground => $mbcolor);
                      };
  
   my $pickedDNcolor   = $nref->{-linecolor};
   my $pickedDNcolorbg = $pickedDNcolor;
      $pickedDNcolor   = 'none'  if(not defined $pickedDNcolor   );
      $pickedDNcolorbg = 'white' if(not defined $pickedDNcolorbg );
      $pickedDNcolorbg = 'white' if($pickedDNcolor eq 'black');

   my $_DNcolor = sub { $pickedDNcolor = shift;
                        my $color      = $pickedDNcolor;
                        my $mbcolor    = $pickedDNcolor;
                        $color         =  undef  if(   $color   eq 'none' );
                        $mbcolor       = 'white' if(   $mbcolor eq 'none'
                                                    or $mbcolor eq 'black');
                        $nref->{-linecolor} = $color;
                        $mb_DNcolor->configure(-background       => $mbcolor,
                                               -activebackground => $mbcolor);
                      };                                         
                                           
                                           

   my ( @UPcolors, @DNcolors ) = ( (), () );
   foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
      push(@UPcolors, [ 'command' => $_,
                        -command  => [ \&$_UPcolor, $_ ],
                        -font     => $font ] );
      push(@DNcolors, [ 'command' => $_,
                        -command  => [ \&$_DNcolor, $_ ],
                        -font     => $font ] );      
   } 
   
   
   my $UPwidth  = $pref->{-linewidth};
   my $_UPwidth = sub { $UPwidth            = shift;
                        $pref->{-linewidth} = $UPwidth;
                      };  
                         
   my $DNwidth  = $nref->{-linewidth};
   my $_DNwidth = sub { $DNwidth            = shift;
                        $nref->{-linewidth} = $DNwidth;
                      };
   my ( @DNwidth, @UPwidth ) = ( (), () );
   foreach ( @{$::TKG2_CONFIG{-LINETHICKNESS}} ) {
       push(@UPwidth, [ 'command' => $_,
                        -command  => [ $_UPwidth, $_ ],
                        -font     => $font ] );  
       push(@DNwidth, [ 'command' => $_,
                        -command  => [ $_DNwidth, $_ ],
                        -font     => $font ] );          
   }

   $EDITOR->destroy if( Tk::Exists($EDITOR) );
   my $which = ($yax eq '-y2') ? 'Second' : 'First';
   my $pe = $pw->Toplevel(-title => "QQ Line Editor for $which Y-Axis");
   $::DIALOG{-QQLINEEDITOR} = $pe;
   $pe->resizable(0,0);
   $pe->Label(-text => 'QUANTILE-QUANTILE LINE',
              -font => $fontb)
      ->pack( -fill =>'x');
        
   my $f_1 = $pe->Frame()->pack( -fill => 'x');
   $f_1->Label(-text => 'A  1/1 sloped line',
               -font => $font)
       ->pack(-side => 'left');
   $f_1->Checkbutton(-text     => 'DoIt ',
                     -font     => $font,
                     -variable =>  \$pref->{-doit},
                     -onvalue  => 1,
                     -offvalue => 0 )
       ->pack(-side => 'left');
   $f_1->Label(-text => 'Width', -font => $font)
       ->pack(-side => 'left');
   $mb_UPwidth = $f_1->Menubutton(
                     -textvariable => \$UPwidth,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -font         => $font,
                     -menuitems    => [ @UPwidth ],
                     -tearoff      => 0)
                     ->pack(-side => 'left', -fill => 'x');                 

   $f_1->Label(-text => '  Color', -font => $font)
        ->pack(-side => 'left');   
   $mb_UPcolor = $f_1->Menubutton(
                     -textvariable => \$pickedUPcolor,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -font         => $font,
                     -menuitems    => [ @UPcolors ],
                     -tearoff      => 0,
                     -background   => $pickedUPcolorbg,
                     -activebackground => $pickedUPcolorbg)
                     ->pack(-side => 'left');


   my $f_2 = $pe->Frame()->pack( -fill => 'x');
      $f_2->Label(-text => 'A -1/1 sloped line',
                  -font => $font,)->pack(-side => 'left');
      $f_2->Checkbutton(
          -text     => 'DoIt ',
          -variable => \$nref->{-doit},
          -onvalue  => 1,
          -offvalue => 0,
          -font     => $font )
          ->pack(-side => 'left');
   $f_2->Label(-text => 'Width',
               -font => $font)->pack(-side => 'left');
   $mb_DNwidth = $f_2->Menubutton(
                     -textvariable => \$DNwidth,
                     -indicator    => 1,
                     -font         => $font,
                     -relief       => 'ridge',
                     -menuitems    => [ @DNwidth ],
                     -tearoff      => 0)
                     ->pack(-side => 'left', -fill => 'x');                 

   $f_2->Label(-text => '  Color',
               -font => $font )
        ->pack(-side => 'left');   
   $mb_DNcolor = $f_2->Menubutton(
                     -textvariable => \$pickedDNcolor,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -font         => $font,
                     -menuitems    => [ @DNcolors ],
                     -tearoff      => 0,
                     -background   => $pickedDNcolorbg,
                     -activebackground => $pickedDNcolorbg)
                     ->pack(-side => 'left');

   my @p = qw(-side left -padx 2 -pady 2);
   my $f_b = $pe->Frame(-relief      => 'groove',
                        -borderwidth => 2)
                ->pack(-side => 'top', -fill => 'x', -expand => 'x');
   $f_b->Button(-text        => 'OK',
                -font        => $font,
                -borderwidth => 3,
                -highlightthickness => 2,
                -command => sub { $template->UpdateCanvas($canv);
                                  $pe->destroy;
                                } )
       ->pack(@p);                  

   $f_b->Button(-text    => "Cancel", 
                -font    => $font,
                -command => sub { $pe->destroy; } )
       ->pack(@p);
                        
   $f_b->Button(-text    => "Help", 
                -font    => $font,
                -padx    => 4,
                -pady    => 4,
                -command => sub { return; } )
       ->pack(@p);
}

1;
