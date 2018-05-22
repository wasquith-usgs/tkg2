package Tkg2::Plot::BoxPlot::Editor::LocationTab;

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
# $Date: 2006/09/17 01:52:22 $
# $Revision: 1.12 $

use strict;

use Exporter;
use vars qw(@ISA @EXPORT_OK $LOCATION_WIDTH $LOCATION_SYMBOL_SIZE);
            
@ISA       = qw(Exporter);

@EXPORT_OK = qw( _Location _checkLocation);

use Tkg2::Base qw(isNumber Message Show_Me_Internals);

$LOCATION_WIDTH       = undef;
$LOCATION_SYMBOL_SIZE = undef;


print $::SPLASH "=";


sub _Location {
   &Show_Me_Internals(@_), if($::CMDLINEOPTS{'showme'});
   
   my ($pw, $box,$template) = @_;
   
   my $font  = $::TKG2_CONFIG{-DIALOG_FONTS}->{-medium};
   my $fontb = $::TKG2_CONFIG{-DIALOG_FONTS}->{-mediumB};
  
   my $lref = $box->{-location};
   my $sref = $lref->{-symbology};
   $LOCATION_WIDTH = $template->pixel_to_inch($lref->{-width});
   
   my $f_1 = $pw->Frame->pack(-side => 'top', -fill => 'x');
   $f_1->Checkbutton(-text     => 'DoIt ',
                     -font     => $fontb,
                     -variable => \$lref->{-doit},
                     -onvalue  => 1,
                     -offvalue => 0)
       ->pack(-side => 'left');
   
   $f_1->Label(-text => '  Style:',
               -font => $fontb)
       ->pack(-side => 'left');
   $f_1->Radiobutton(-text     => 'mean',
                     -font     => $fontb,
                     -variable => \$lref->{-showtype},
                     -value    => 'mean')
        ->pack(-side => 'left'); 
   $f_1->Radiobutton(-text     => 'median',
                     -font     => $fontb,
                     -variable => \$lref->{-showtype},
                     -value    => 'median')
       ->pack(-side => 'left');      
   
   $f_1->Label(-text => '  Location Width',
               -font => $fontb)
       ->pack(-side => 'left');
   $f_1->Entry(-textvariable => \$LOCATION_WIDTH,
               -font         => $font,
               -background   => 'white',
               -width        => 12  )
       ->pack(-side => 'left');
   
   
   my $linewidth  = $lref->{-linewidth};
   my $_linewidth = sub { $linewidth = shift;
                          $lref->{-linewidth} = $linewidth;
                        };   
                        
   my $ptoutlinewidth  = $sref->{-outlinewidth};                        
   my $_ptoutlinewidth = sub { $ptoutlinewidth = shift;
                               $sref->{-outlinewidth} = $ptoutlinewidth;
                             };
   my (@linewidth,@ptoutlinewidth);
   foreach ( @{$::TKG2_CONFIG{-LINETHICKNESS}} ) {
      push(@linewidth, [ 'command' => $_,
                         -font     => $font,  
                         -command  => [ $_linewidth, $_ ] ] );
      push(@ptoutlinewidth, [ 'command' => $_,
                              -font     => $font,
                              -command  => [ $_ptoutlinewidth, $_ ] ] );
   }
   
   
   my $f_2 = $pw->Frame->pack(-side => 'top', -fill => 'x');  
   $f_2->Label(-text => ' Width',
               -font => $fontb)
       ->pack(-side => 'left');        
   my $mb_linewidth = $f_2->Menubutton(
                          -textvariable => \$linewidth,
                          -font         => $fontb,
                          -width        => 6,
                          -indicator    => 1,
                          -relief       => 'ridge',
                          -menuitems    => [ @linewidth ],
                          -tearoff      => 0)
                          ->pack(-side => 'left', -fill => 'x'); 
   
   
   my $pickedlinecolor   = $lref->{-linecolor};
   my $pickedlinecolorbg = $pickedlinecolor;
      $pickedlinecolor   = 'none'  if(not defined($pickedlinecolor)   );
      $pickedlinecolorbg = 'white' if(not defined($pickedlinecolorbg) ); 
      $pickedlinecolorbg = 'white' if( $pickedlinecolor eq 'black'    );  
   my $mb_linecolor;    
   my $_linecolor = sub { $pickedlinecolor = shift;
                            my $color   = $pickedlinecolor;
                            my $mbcolor = $pickedlinecolor;
                            $color      =  undef  if($color   eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'none' );
                            $mbcolor    = 'white' if($mbcolor eq 'black');
                            $lref->{-linecolor} = $color;
                            $mb_linecolor->configure(-background       => $mbcolor,
                                                     -activebackground => $mbcolor);
                        };     
   
   my $pickedpointoutline   = $sref->{-outlinecolor};
   my $pickedpointoutlinebg = $pickedpointoutline;
      $pickedpointoutline   = 'none'  if(not defined($pickedpointoutline)   );
      $pickedpointoutlinebg = 'white' if(not defined($pickedpointoutlinebg) );
      $pickedpointoutlinebg = 'white' if( $pickedpointoutline eq 'black'    );         
   my $mb_pointoutline;
   my $_pointoutline = sub { $pickedpointoutline = shift;
                             my $color   = $pickedpointoutline;
                             my $mbcolor = $pickedpointoutline;
                             $color      =  undef  if($color   eq 'none' );
                             $mbcolor    = 'white' if($mbcolor eq 'none' );
                             $mbcolor    = 'white' if($mbcolor eq 'black');
                             $sref->{-outlinecolor} = $color;
                             $mb_pointoutline->configure(-background       => $mbcolor,
                                                         -activebackground => $mbcolor);
                           };
                           
   my $pickedpointfill   = $sref->{-fillcolor};
   my $pickedpointfillbg = $pickedpointfill;
      $pickedpointfill   = 'none'  if(not defined($pickedpointfill)   );
      $pickedpointfillbg = 'white' if(not defined($pickedpointfillbg) );
      $pickedpointfillbg = 'white' if( $pickedpointfill eq 'black'    ); 
   my $mb_pointfill;
   my $_pointfill = sub { $pickedpointfill = shift;
                          my $color   = $pickedpointfill;
                          my $mbcolor = $pickedpointfill;
                          $color      =  undef  if($color   eq 'none' );
                          $mbcolor    = 'white' if($mbcolor eq 'none' );
                          $mbcolor    = 'white' if($mbcolor eq 'black');
                          $sref->{-fillcolor} = $color;
                          $mb_pointfill->configure(-background       => $mbcolor,
                                                   -activebackground => $mbcolor);
                        };      
                        
   my (@linecolor, @pointoutline, @pointfill);
   foreach ( @{$::TKG2_CONFIG{-COLORS}} ) {
      push(@linecolor,  [ 'command' => $_,
                          -font     => $font,
                          -command  => [ \&$_linecolor,  $_ ] ] );
      push(@pointoutline, [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_pointoutline, $_ ] ] );
      push(@pointfill,    [ 'command' => $_,
                            -font     => $font,
                            -command  => [ \&$_pointfill,    $_ ] ] );
   }
        
   $f_2->Label(-text => ' Color',
               -font => $fontb)
       ->pack(-side => 'left'); 
   $mb_linecolor = $f_2->Menubutton(
                       -textvariable => \$pickedlinecolor,
                       -font         => $fontb,
                       -width        => 12,
                       -indicator    => 1,
                       -relief       => 'ridge',
                       -tearoff      => 0,
                       -menuitems    => [ @linecolor ],
                       -background   => $pickedlinecolorbg,
                       -activebackground => $pickedlinecolorbg )
                       ->pack(-side => 'left');
   
   # Symbology

   my @pointsymbol = (
                     [ 'command' => 'Circle',
                       -font     => $font,
      -command => sub { $sref->{-symbol} =    'Circle'} ],
      
                     [ 'command' => 'Square',
                       -font     => $font,
      -command => sub { $sref->{-symbol} =    'Square'} ],
      
                     [ 'command' => 'Triangle',
                       -font     => $font,
      -command => sub { $sref->{-symbol} =  'Triangle'} ],

                     [ 'command' => 'Arrow',
                       -font     => $font,
      -command => sub { $sref->{-symbol} =     'Arrow'} ],

                     [ 'command' => 'Phoenix',
                       -font     => $font,
      -command => sub { $sref->{-symbol} =   'Phoenix'} ],

                     [ 'command' => 'ThinBurst',
                       -font     => $font,
      -command => sub { $sref->{-symbol} =   'ThinBurst'} ],

                     [ 'command' => 'Burst',
                       -font     => $font,
      -command => sub { $sref->{-symbol} =       'Burst'} ],

                     [ 'command' => 'FatBurst',
                       -font     => $font,
      -command => sub { $sref->{-symbol} =    'FatBurst'} ],
      
                     [ 'command' => 'Cross',
                       -font     => $font,
      -command => sub { $sref->{-symbol} =     'Cross'} ],
      
                     [ 'command' => 'Star',
                       -font     => $font,
      -command => sub { $sref->{-symbol} =      'Star'} ],
      
                     [ 'command' => 'Horz Bar',
                       -font     => $font,
      -command => sub { $sref->{-symbol} = 'Horz Bar' } ],
      
                     [ 'command' => 'Vert Bar',
                       -font     => $font,
      -command => sub { $sref->{-symbol} = 'Vert Bar' } ] );
    

   
   
  $LOCATION_SYMBOL_SIZE = $template->pixel_to_inch($sref->{-size});

  my $f_3 = $pw->Frame->pack(-side => 'top', -fill => 'x'); 
  $f_3->Label(-text => "\nSymbology:",
              -font => $fontb)
      ->pack(-side => 'left');
  
  my $f_4 = $pw->Frame->pack(-side => 'top', -fill => 'x'); 
  $f_4->Checkbutton(-text     => 'DoIt ',
                     -font     => $fontb,
                     -variable => \$sref->{-doit},
                     -onvalue  => 1,
                     -offvalue => 0)
       ->pack(-side => 'left');
  $f_4->Menubutton(-textvariable => \$sref->{-symbol},
                     -font         => $fontb,
                     -width        => 8,
                     -indicator    => 1,
                     -relief       => 'ridge',
                     -tearoff      => 0,
                     -menuitems    => [ @pointsymbol ] )
        ->pack(-side => 'left');
        
               
   $f_4->Label(-text => ' Size',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $f_4->Entry(-textvariable => \$LOCATION_SYMBOL_SIZE,
                -font          => $font,
                -background   => 'white',
                -width        => 8  )
        ->pack(-side => 'left'); 
   $f_4->Label(-text => ' Edge',
               -font => $fontb)
        ->pack(-side => 'left'); 
   my $mb_ptoutlinewidth = $f_4->Menubutton(
                             -textvariable => \$ptoutlinewidth,
                             -font         => $fontb,
                             -width        => 6,
                             -indicator    => 1,
                             -relief       => 'ridge',
                             -menuitems    => [ @ptoutlinewidth ],
                             -tearoff      => 0)
                             ->pack(-side => 'left', -fill => 'x');      
   $f_4->Label(-text => ' Angle',
                -font => $fontb)
        ->pack(-side => 'left');
   $f_4->Entry(-textvariable => \$sref->{-angle},
                -font         => $font,
                -background   => 'white',
                -width        => 4 )
        ->pack(-side => 'left');
    
   my $f_41 = $pw->Frame->pack(-side => 'top', -fill => 'x');   
   $f_41->Label(-text => '   Edge Color',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $mb_pointoutline = $f_41->Menubutton(
                           -textvariable => \$pickedpointoutline,
                           -font         => $fontb,
                           -width        => 12,
                           -indicator    => 1,
                           -relief       => 'ridge',
                           -tearoff      => 0,
                           -menuitems    => [ @pointoutline ],
                           -background   => $pickedpointoutlinebg,
                           -activebackground => $pickedpointoutlinebg )
                           ->pack(-side => 'left');   
   $f_41->Label(-text => ' Fill',
                -font => $fontb)
        ->pack(-side => 'left'); 
   $mb_pointfill = $f_41->Menubutton(
                        -textvariable => \$pickedpointfill,
                        -font         => $fontb,
                        -width        => 12,
                        -indicator    => 1,
                        -relief       => 'ridge',
                        -tearoff      => 0,
                        -menuitems    => [ @pointfill ],
                        -background   => $pickedpointfillbg,
                        -activebackground => $pickedpointfillbg )
                        ->pack(-side => 'left');  
   
   my $f_bot = $pw->Frame->pack(-side => 'bottom', -fill => 'x');
   $f_bot->Label(-text => "   Boxplot explanation parameters are ".
                          "available in the SHOW DATA tab.   ",
                 -font => $fontb,
                 -relief => 'groove')
         ->pack(-side => 'bottom');
   
}


sub _checkLocation {
  my ($box, $pe) = @_;

  my $lref   = $box->{-location};
  my $sref   = $lref->{-symbology};
  
  my ($size) = $LOCATION_WIDTH =~ m/([0-9.]+)/; 
  if( defined($size) and &isNumber($size) ) {
     $size .= "i";
     $LOCATION_WIDTH = $size;
     $lref->{-width} = $pe->fpixels($size);
  }
  else {
     my $mess = "Invalid box width for boxplot-location\n";
     &Message($pe,'-generic', $mess);
     return 0;
  }
  
  $size = undef;
  
  ($size) = $LOCATION_SYMBOL_SIZE =~ m/([0-9.]+)/;
  if( defined($size) and &isNumber($size) ) {
     $size .= "i";
     $LOCATION_SYMBOL_SIZE = $size;
     $sref->{-size} = $pe->fpixels($size);
  }
  else {
     my $mess = "Invalid symbol size for boxplot-location-symbology\n";
     &Message($pe,'-generic', $mess);
     return 0;
  }
  
  return 1;
}

1;
