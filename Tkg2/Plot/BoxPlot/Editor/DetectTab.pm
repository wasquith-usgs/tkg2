package Tkg2::Plot::BoxPlot::Editor::DetectTab;

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
# $Date: 2006/09/15 15:43:02 $
# $Revision: 1.10 $

use strict;

use Exporter;
use vars qw(@ISA @EXPORT_OK
            $UPPER_DETECT_WIDTH
            $LOWER_DETECT_WIDTH
           );
            
@ISA       = qw(Exporter);

@EXPORT_OK = qw(_DetectLimits _checkDetectLimits);

use Tkg2::Base qw(isNumber Message Show_Me_Internals);

print $::SPLASH "=";


sub _DetectLimits {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
      
   my ($pw, $box, $template) = @_;

   my $font  = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};

   my $dref = $box->{-detection_limits};
   my $lref = $dref->{-lower};
   my $uref = $dref->{-upper};
   
   $LOWER_DETECT_WIDTH = $template->pixel_to_inch($lref->{-width});
   $UPPER_DETECT_WIDTH = $template->pixel_to_inch($uref->{-width});
   
   my $l_linewidth  = $lref->{-linewidth};
   my $_l_linewidth = sub { $l_linewidth = shift;
                            $lref->{-linewidth} = $l_linewidth;
                          }; 
   my $u_linewidth  = $uref->{-linewidth};
   my $_u_linewidth = sub { $u_linewidth = shift;
                            $uref->{-linewidth} = $u_linewidth;
                          }; 
   my (@l_linewidth, @u_linewidth);
   foreach ( @{$::TKG2_CONFIG{-LINETHICKNESS}} ) {
      push(@l_linewidth, [ 'command' => $_,
                           -font     => $font,
                           -command  => [ $_l_linewidth, $_ ] ] );
      push(@u_linewidth, [ 'command' => $_,
                           -font     => $font,
                           -command  => [ $_u_linewidth, $_ ] ] );
   }  
                      
                      
                      
   my $l_pickedlinecolor   = $lref->{-linecolor};
   my $l_pickedlinecolorbg = $l_pickedlinecolor;
      $l_pickedlinecolor   = 'none'  if(not defined($l_pickedlinecolor)   );
      $l_pickedlinecolorbg = 'white' if(not defined($l_pickedlinecolorbg) ); 
      $l_pickedlinecolorbg = 'white' if( $l_pickedlinecolor eq 'black'    );  
   my $l_mb_linecolor;    
   my $_l_linecolor = sub { $l_pickedlinecolor = shift;
                            my $color   = $l_pickedlinecolor;
                            my $mbcolor = $l_pickedlinecolor;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $lref->{-linecolor} = $color;
                            $l_mb_linecolor->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                        };     
                        
   my $u_pickedlinecolor   = $uref->{-linecolor};
   my $u_pickedlinecolorbg = $u_pickedlinecolor;
      $u_pickedlinecolor   = 'none'  if(not defined($u_pickedlinecolor)   );
      $u_pickedlinecolorbg = 'white' if(not defined($u_pickedlinecolorbg) ); 
      $u_pickedlinecolorbg = 'white' if( $u_pickedlinecolor eq 'black'    );  
   my $u_mb_linecolor;    
   my $_u_linecolor = sub { $u_pickedlinecolor = shift;
                            my $color   = $u_pickedlinecolor;
                            my $mbcolor = $u_pickedlinecolor;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $uref->{-linecolor} = $color;
                            $u_mb_linecolor->configure(-background       => $mbcolor,
                                                       -activebackground => $mbcolor);
                        };     
   my (@l_linecolor, @u_linecolor);
   foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
      push(@l_linecolor, [ 'command' => $_,
                           -font     => $font,
                           -command  => [ \&$_l_linecolor, $_ ] ] );
      push(@u_linecolor, [ 'command' => $_,
                           -font     => $font,
                           -command  => [ \&$_u_linecolor, $_ ] ] );
   }                                          
      
   my $f_l_1 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   my $f_l_2 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   $f_l_1->Label(-text => "Lower Detection Limit",
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $f_l_2->Checkbutton(-text     => 'DoIt ',
                       -font     => $fontb,
                       -variable => \$lref->{-doit},
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   $f_l_2->Label(-text => '  Width',
                 -font => $fontb)
         ->pack(-side => 'left');
   $f_l_2->Entry(-textvariable => \$LOWER_DETECT_WIDTH,
                 -font         => $font,
                 -background   => 'white',
                 -width        => 12  )
         ->pack(-side => 'left');
   
   my $f_l_3 = $pw->Frame->pack(-side => 'top', -fill => 'x');  
   $f_l_3->Label(-text => 'Line Width',
                 -font => $fontb)
         ->pack(-side => 'left');        
   my $l_mb_linewidth = $f_l_3->Menubutton(
                              -textvariable => \$l_linewidth,
                              -font         => $fontb,
                              -width        => 6,
                              -indicator    => 1,
                              -relief       => 'ridge',
                              -menuitems    => [ @l_linewidth ],
                              -tearoff      => 0)
                              ->pack(-side => 'left', -fill => 'x'); 
   $f_l_3->Label(-text => '  Line Color',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $l_mb_linecolor = $f_l_3->Menubutton(
                         -textvariable => \$l_pickedlinecolor,
                         -font         => $fontb,
                         -width        => 12,
                         -indicator    => 1,
                         -relief       => 'ridge',
                         -tearoff      => 0,
                         -menuitems    => [ @l_linecolor ],
                         -background   => $l_pickedlinecolorbg,
                         -activebackground => $l_pickedlinecolorbg )
                         ->pack(-side => 'left');
        
        
                         
   my $f_u_1 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   my $f_u_2 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   $f_u_1->Label(-text => "\nUpper Detection Limit",
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $f_u_2->Checkbutton(-text     => 'DoIt ',
                       -font     => $fontb,
                       -variable => \$uref->{-doit},
                       -onvalue  => 1,
                       -offvalue => 0)
         ->pack(-side => 'left');
   $f_u_2->Label(-text => '  Width',
                 -font => $fontb)
         ->pack(-side => 'left');
   $f_u_2->Entry(-textvariable => \$UPPER_DETECT_WIDTH,
                 -font         => $font,
                 -background   => 'white',
                 -width        => 12  )
         ->pack(-side => 'left');
   
   my $f_u_3 = $pw->Frame->pack(-side => 'top', -fill => 'x');  
   $f_u_3->Label(-text => 'Line Width',
                 -font => $fontb)
         ->pack(-side => 'left');        
   my $u_mb_linewidth = $f_u_3->Menubutton(
                              -textvariable => \$u_linewidth,
                              -font         => $fontb,
                              -width        => 6,
                              -indicator    => 1,
                              -relief       => 'ridge',
                              -menuitems    => [ @u_linewidth ],
                              -tearoff      => 0)
                              ->pack(-side => 'left', -fill => 'x'); 
   $f_u_3->Label(-text => '  Line Color',
                 -font => $fontb)
         ->pack(-side => 'left'); 
   $u_mb_linecolor = $f_u_3->Menubutton(
                         -textvariable => \$u_pickedlinecolor,
                         -font         => $fontb,
                         -width        => 12,
                         -indicator    => 1,
                         -relief       => 'ridge',
                         -tearoff      => 0,
                         -menuitems    => [ @u_linecolor ],
                         -background   => $u_pickedlinecolorbg,
                         -activebackground => $u_pickedlinecolorbg )
                         ->pack(-side => 'left');                         

   my $f_bot = $pw->Frame->pack(-side => 'bottom', -fill => 'x');
   $f_bot->Label(-text => "   Boxplot explanation parameters are ".
                          "available in the SHOW DATA tab.   ",
                 -font => $fontb,
                 -relief => 'groove')
         ->pack(-side => 'bottom');                         
}


sub _checkDetectLimits {
   my ($box, $pe) = @_;
    
   my $dref = $box->{-detection_limit};
   my $lref = $dref->{-lower};
   my $uref = $dref->{-upper};
   
   my ($size) = $LOWER_DETECT_WIDTH =~ m/([0-9.]+)/;
   if( defined($size) and &isNumber($size) ) {
      $size .= "i";
      $LOWER_DETECT_WIDTH = $size;
      $lref->{-width} = $pe->fpixels($size);
   }
   else {
      my $mess = "Invalid symbol size for lower-detection limit width\n";
      &Message($pe,'-generic', $mess);
      return 0;
   }
   
   $size = undef;
   
   ($size) = $UPPER_DETECT_WIDTH =~ m/([0-9.]+)/;
   if( defined($size) and &isNumber($size) ) {
      $size .= "i";
      $UPPER_DETECT_WIDTH = $size;
      $uref->{-width} = $pe->fpixels($size);
   }
   else {
      my $mess = "Invalid symbol size for upper-detection limit width\n";
      &Message($pe,'-generic', $mess);
      return 0;
   }
   return 1;
}


1;
